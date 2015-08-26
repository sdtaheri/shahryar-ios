//
//  FavoriteTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/25.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "FavoriteTVC.h"
#import "Place.h"
#import "Type.h"
#import "DetailTVC.h"

@interface FavoriteTVC ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *selectionToggle;
@property (strong, nonatomic) NSArray *favoritesID;
@property (strong, nonatomic) NSArray *recentSearchesID;

@property (strong, nonatomic) NSArray *favoritesPlaces;
@property (strong, nonatomic) NSArray *recentSearchesPlaces;

@property (weak, nonatomic) IBOutlet UILabel *noItemLabel;
@property (strong, nonatomic) UIColor *separatorColor;

@end

@implementation FavoriteTVC

typedef NS_ENUM(NSInteger, TableType) {
    TableTypeFavorites = 1,
    TableTypeRecent = 0,
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    self.tableView.estimatedRowHeight = 69.f;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 15);
    self.separatorColor = self.tableView.separatorColor;
    
    self.favoritesID = [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"];
    self.recentSearchesID = [[NSUserDefaults standardUserDefaults] objectForKey:@"Recent Searches"];
    
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.favoritesID.count];
    for (NSString *uniqueID in self.favoritesID) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueID == %@", uniqueID];
        [temp addObject:[[self.allPlaces filteredArrayUsingPredicate:predicate] lastObject]];
    }
    if (temp.count > 0) {
        self.favoritesPlaces = [temp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCompare:)]]];
    }
    
    temp = [NSMutableArray arrayWithCapacity:self.recentSearchesID.count];
    for (NSString *uniqueID in self.recentSearchesID) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueID == %@", uniqueID];
        [temp addObject:[[self.allPlaces filteredArrayUsingPredicate:predicate] lastObject]];
    }
    if (temp.count > 0) {
        self.recentSearchesPlaces = [temp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCompare:)]]];
    }

    self.navigationItem.title = [self.selectionToggle titleForSegmentAtIndex:self.selectionToggle.selectedSegmentIndex];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadTableView: (NSNotification *)note {
    
    self.favoritesID = [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"];
    
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.favoritesID.count];
    for (NSString *uniqueID in self.favoritesID) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uniqueID == %@", uniqueID];
        [temp addObject:[[self.allPlaces filteredArrayUsingPredicate:predicate] lastObject]];
    }
    if (temp.count > 0) {
        self.favoritesPlaces = [temp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedCompare:)]]];
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)selectionToggled:(UISegmentedControl *)sender {
    self.navigationItem.title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    [self.tableView reloadData];
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    
    __weak SearchTVC *capturedSTVC = self.searchTVC;
    [self dismissViewControllerAnimated:YES completion:^{
        [capturedSTVC viewWillAppear:NO];
        
        [capturedSTVC.tableView reloadData];
    }];
}

- (IBAction)deleteAll:(UIBarButtonItem *)sender {
    
    if (self.selectionToggle.selectedSegmentIndex == TableTypeFavorites) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Favorites"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.favoritesID = nil;
        self.favoritesPlaces = nil;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Recent Searches"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.recentSearchesID = nil;
        self.recentSearchesPlaces = nil;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger result = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesID.count : self.recentSearchesID.count;
    if (result == 0) {
        self.noItemLabel.hidden = NO;
        self.tableView.separatorColor = [UIColor clearColor];
    } else {
        self.noItemLabel.hidden = YES;
        self.tableView.separatorColor = self.separatorColor;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Favorite Cell"];
    
    Place *place = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesPlaces[indexPath.row] : self.recentSearchesPlaces[indexPath.row];
    
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];

}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"حذف";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.selectionToggle.selectedSegmentIndex == TableTypeFavorites) {
        NSMutableArray *temp = [self.favoritesPlaces mutableCopy];
        [temp removeObjectAtIndex:indexPath.row];
        self.favoritesPlaces = temp;
        
        temp = [self.favoritesID mutableCopy];
        [temp removeObjectAtIndex:indexPath.row];
        self.favoritesID = temp;
        
        [[NSUserDefaults standardUserDefaults] setObject:self.favoritesID forKey:@"Favorites"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSMutableArray *temp = [self.recentSearchesPlaces mutableCopy];
        [temp removeObjectAtIndex:indexPath.row];
        self.recentSearchesPlaces = temp;
        
        temp = [self.recentSearchesID mutableCopy];
        [temp removeObjectAtIndex:indexPath.row];
        self.recentSearchesID = temp;
        
        [[NSUserDefaults standardUserDefaults] setObject:self.recentSearchesID forKey:@"Recent Searches"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Detail From Favorites"]) {
        DetailTVC *dtvc = segue.destinationViewController;
        dtvc.navigationItem.leftBarButtonItem = nil;
        dtvc.navigationItem.leftItemsSupplementBackButton = YES;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        dtvc.place = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesPlaces[indexPath.row] : self.recentSearchesPlaces[indexPath.row];
    }
}

@end
