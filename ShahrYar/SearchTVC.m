//
//  SearchTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/2.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "SearchTVC.h"
#import "AppDelegate.h"
#import "NSManagedObjectContext+AsyncFetch.h"
#import "Place.h"
#import "Type.h"

@interface SearchTVC () <UIPopoverPresentationControllerDelegate>

@property (weak, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (strong, nonatomic) NSArray *filteredList;

@end

@implementation SearchTVC

- (void)setFilteredList:(NSArray *)filteredList {

    _filteredList = filteredList;
    [self.tableView reloadData];
    
    self.searchController.preferredContentSize = CGSizeMake(375.0, self.tableView.contentSize.height);
}

- (NSFetchRequest *)searchFetchRequest
{
    if (!_searchFetchRequest) {
        _searchFetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Place" inManagedObjectContext:self.managedObjectContext];
        [_searchFetchRequest setEntity:entity];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
        [_searchFetchRequest setSortDescriptors:sortDescriptors];
    }
    
    return _searchFetchRequest;
}

- (void)searchForText:(NSString *)searchText
{
    if (self.managedObjectContext)
    {
        NSString *predicateFormat = @"%K CONTAINS[cd] %@ && category.selected.boolValue = YES";
        NSString *searchAttribute = @"title";
        searchText = [searchText stringByReplacingOccurrencesOfString:@"ي" withString:@"ی"];
        searchText = [searchText stringByReplacingOccurrencesOfString:@"ك" withString:@"ک"];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
        [self.searchFetchRequest setPredicate:predicate];
        
        [self.managedObjectContext executeFetchRequestAsync:self.searchFetchRequest completion:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.filteredList = objects;
            }
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.estimatedRowHeight = 69.f;
    
    UIVisualEffectView *vev = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    self.tableView.backgroundView = vev;
}

- (void)didReceiveMemoryWarning
{
    self.searchFetchRequest = nil;
    [super didReceiveMemoryWarning];
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        searchController.searchResultsController.view.hidden = NO;
        self.searchController = searchController;
        self.searchController.popoverPresentationController.delegate = self;
        self.searchController.searchBar.placeholder = @"جستجو";
    });
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.searchController.searchBar.placeholder = @"جستجو، علاقه‌مندی‌ها";
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view {

    (*rect).size.width = (*view).frame.size.width;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchString = searchController.searchBar.text;
    [self searchForText:searchString];
    searchController.searchResultsController.view.hidden = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL shouldShowFavoriteRow = self.searchController.searchBar.text.length > 0 ? NO : YES;
    return shouldShowFavoriteRow ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.numberOfSections == 2) {
        if (section == 0) {
            return 1;
        } else if (section == 1) {
            return self.filteredList.count;
        }
    } else if (tableView.numberOfSections == 1) {
        return self.filteredList.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Search Cell" forIndexPath:indexPath];
    
    if (tableView.numberOfSections == 2) {
        if (indexPath.section == 0) {
            cell.textLabel.text = @"علاقه‌مندی‌ها";
            cell.imageView.image = [UIImage imageNamed:@"love"];
            cell.imageView.tintColor = [UIColor blackColor];
        } else if (indexPath.section == 1) {
            
            Place *place = self.filteredList[indexPath.row];
            
            NSString *title = place.title;
            NSString *subtitle = place.category.summary;
            
            NSDictionary *attrs = @{
                                    NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:14.0],
                                    NSForegroundColorAttributeName:[UIColor blackColor]
                                    };
            NSDictionary *subAttrs = @{
                                       NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:13.0],
                                       NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                       };
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle] attributes:attrs];
            
            NSRange range = NSMakeRange(title.length + 1, subtitle.length);
            [attrStr setAttributes:subAttrs range:range];
            
            cell.imageView.image = nil;
            cell.textLabel.attributedText = attrStr;
        }
    } else if (tableView.numberOfSections == 1) {
        Place *place = self.filteredList[indexPath.row];
        
        NSString *title = place.title;
        NSString *subtitle = place.category.summary;
        
        NSDictionary *attrs = @{
                                NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:14.0],
                                NSForegroundColorAttributeName:[UIColor blackColor]
                                };
        NSDictionary *subAttrs = @{
                                   NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:13.0],
                                   NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                   };
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle] attributes:attrs];
        
        NSRange range = NSMakeRange(title.length + 1, subtitle.length);
        [attrStr setAttributes:subAttrs range:range];
        
        cell.imageView.image = nil;
        cell.textLabel.attributedText = attrStr;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView.numberOfSections == 2 && indexPath.section == 0) {
        
        UINavigationController *nc = [self.presentingViewController.storyboard instantiateViewControllerWithIdentifier:@"FavoriteNC"];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.presentingViewController presentViewController:nc animated:YES completion:NULL];
        
    } else {
        if ([self.presentingViewController isKindOfClass:[UINavigationController class]]) {
            [[self.presentingViewController childViewControllers][0] performSegueWithIdentifier:@"Detail Segue From Search" sender:self.filteredList[indexPath.row]];
        } else {
            [self.presentingViewController performSegueWithIdentifier:@"Detail Segue From Search" sender:self.filteredList[indexPath.row]];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = nil;
    
    cell.textLabel.font = [UIFont fontWithName:@"IRANSans-Light" size:14];
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    cell.textLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}



@end
