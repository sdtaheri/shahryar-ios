//
//  SearchTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/2.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "NSManagedObjectContext+AsyncFetch.h"
#import "SearchTVC.h"
#import "AppDelegate.h"
#import "Place.h"
#import "Type.h"
#import "FavoriteTVC.h"
#import "UIFontDescriptor+IranSans.h"

@interface SearchTVC ()

@property (weak, nonatomic) UISearchController *searchController;

@property (strong, nonatomic) NSArray *allPlaces;
@property (strong, nonatomic) NSFetchRequest *fetchRequest;
@property (strong, nonatomic) NSArray *filteredListAfterSearch;

@end

@implementation SearchTVC

- (NSFetchRequest *)fetchRequest {
    if (!_fetchRequest) {
        _fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Place"];
        _fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCompare:)]];
        _fetchRequest.predicate = nil;
    }
    return _fetchRequest;
}

- (void)setFilteredListAfterSearch:(NSArray *)filteredListAfterSearch {

    _filteredListAfterSearch = filteredListAfterSearch;
    [self.tableView reloadData];
    
    self.searchController.preferredContentSize = CGSizeMake(375.0, self.tableView.contentSize.height);
}

- (void)searchForText:(NSString *)searchText
{
    NSString *predicateFormat = @"%K CONTAINS[cd] %@";
    NSString *searchAttribute = @"title";
    searchText = [searchText stringByReplacingOccurrencesOfString:@"ي" withString:@"ی"];
    searchText = [searchText stringByReplacingOccurrencesOfString:@"ك" withString:@"ک"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
    
    self.filteredListAfterSearch = [self.places filteredArrayUsingPredicate:predicate];
}

- (void)setRecentPlaceSearches:(NSArray *)recentPlaceSearches {
    _recentPlaceSearches = recentPlaceSearches;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.estimatedRowHeight = 69.f;
    if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 15);
    }
    
    UIVisualEffectView *vev = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    self.tableView.backgroundView = vev;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSError *error;
    self.allPlaces = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];

    self.recentIDSearches = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recent Searches"];
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.recentIDSearches.count];
    for (NSString *uniqueID in self.recentIDSearches) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@",uniqueID];
        NSArray *results = [self.allPlaces filteredArrayUsingPredicate:predicate];
        if (results.count == 1) {
            [temp addObject: results.lastObject];
        }
    }
    self.recentPlaceSearches = temp;
    
    self.searchController.preferredContentSize = CGSizeMake(375.0, self.tableView.contentSize.height);
}

- (void)didReceiveMemoryWarning
{
    self.fetchRequest = nil;
    [super didReceiveMemoryWarning];
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        searchController.searchResultsController.view.hidden = NO;
        self.searchController = searchController;
        self.searchController.searchBar.placeholder = @"جستجو، علاقه‌مندی‌ها";
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchController.searchBar resignFirstResponder];
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
            return self.recentIDSearches.count;
        }
    } else if (tableView.numberOfSections == 1) {
        return self.filteredListAfterSearch.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Search Cell" forIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;

    if (tableView.numberOfSections == 2) {
        if (indexPath.section == 0) {
            cell.textLabel.text = @"علاقه‌مندی‌ها";
            cell.imageView.image = [UIImage imageNamed:@"love_selected"];
            cell.imageView.tintColor = [UIColor blackColor];
            cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
        } else if (indexPath.section == 1) {
            
            Place *place = self.recentPlaceSearches[self.recentPlaceSearches.count - 1 - indexPath.row];
            
            NSString *title = place.title;
            NSString *subtitle = place.category.summary;
            
            NSDictionary *attrs = @{
                                    NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0],
                                    NSForegroundColorAttributeName:[UIColor blackColor]
                                    };
            NSDictionary *subAttrs = @{
                                       NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0],
                                       NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                       };
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle] attributes:attrs];
            
            NSRange range = NSMakeRange(title.length + 1, subtitle.length);
            [attrStr setAttributes:subAttrs range:range];
            
            cell.imageView.image = [UIImage imageNamed:@"search"];
            cell.imageView.tintColor = [UIColor darkGrayColor];
            cell.textLabel.attributedText = attrStr;
        }
    } else if (tableView.numberOfSections == 1) {
        Place *place = self.filteredListAfterSearch[indexPath.row];
        
        NSString *title = place.title;
        NSString *subtitle = place.category.summary;
        
        NSDictionary *attrs = @{
                                NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0],
                                NSForegroundColorAttributeName:[UIColor blackColor]
                                };
        NSDictionary *subAttrs = @{
                                   NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0],
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
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (tableView.numberOfSections == 2 && indexPath.section == 0) {
        
        UINavigationController *nc = [self.presentingViewController.storyboard instantiateViewControllerWithIdentifier:@"FavoriteNC"];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [nc setPreferredContentSize:CGSizeMake(375.0, 500.0)];

        FavoriteTVC *ftvc = nc.childViewControllers[0];
        ftvc.allPlaces = self.allPlaces;
        ftvc.searchTVC = self;
        
        if ([self.presentingViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *mainNC = (UINavigationController *)self.presentingViewController;
            [self.searchController dismissViewControllerAnimated:YES completion:^{
                [mainNC presentViewController:nc animated:YES completion:NULL];
            }];
        } else {
            [self.presentingViewController presentViewController:nc animated:YES completion:NULL];
        }
        
        
    } else if (tableView.numberOfSections == 2 && indexPath.section == 1) {
        if ([self.presentingViewController isKindOfClass:[UINavigationController class]]) {
            [[self.presentingViewController childViewControllers][0] performSegueWithIdentifier:@"Detail Segue From Search" sender:self.recentPlaceSearches[self.recentPlaceSearches.count - 1 - indexPath.row]];
        } else {
            [self.presentingViewController performSegueWithIdentifier:@"Detail Segue From Search" sender:self.recentPlaceSearches[self.recentPlaceSearches.count - 1 - indexPath.row]];
        }
    } else {
        if ([self.presentingViewController isKindOfClass:[UINavigationController class]]) {
            [[self.presentingViewController childViewControllers][0] performSegueWithIdentifier:@"Detail Segue From Search" sender:self.filteredListAfterSearch[indexPath.row]];
        } else {
            [self.presentingViewController performSegueWithIdentifier:@"Detail Segue From Search" sender:self.filteredListAfterSearch[indexPath.row]];
        }
        
        NSArray *recentSearches = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recent Searches"];
        if (recentSearches) {
            NSMutableArray *temp = [recentSearches mutableCopy];
            while (temp.count >= 20) {
                [temp removeObjectAtIndex:0];
            }
            if (![temp containsObject:[self.filteredListAfterSearch[indexPath.row] uniqueID]]) {
                [temp addObject:[self.filteredListAfterSearch[indexPath.row] uniqueID]];
            }
            [[NSUserDefaults standardUserDefaults] setObject:[temp copy] forKey:@"Recent Searches"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        } else {
            NSArray *temp = @[[self.filteredListAfterSearch[indexPath.row] uniqueID]];
            [[NSUserDefaults standardUserDefaults] setObject:[temp copy] forKey:@"Recent Searches"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = nil;
    
    cell.textLabel.textAlignment = NSTextAlignmentRight;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
        // Remove seperator inset
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
        
        // Prevent the cell from inheriting the Table View's margin settings
        [cell setPreservesSuperviewLayoutMargins:NO];
        
        // Explictly set your cell's layout margins
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}



@end
