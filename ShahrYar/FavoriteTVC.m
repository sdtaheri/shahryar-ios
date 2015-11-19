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
#import "UIFontDescriptor+IranSans.h"

@interface FavoriteTVC () <UIViewControllerPreviewingDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteAllButton;
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
    
    if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        if (window.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)
        {
            [self registerForPreviewingWithDelegate:self sourceView:self.navigationController.view];
        }
    }
    
    self.tableView.estimatedRowHeight = 69.f;
    if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 15);
    }
    self.separatorColor = self.tableView.separatorColor;
    
    self.noItemLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle:UIFontTextStyleCaption1] size:0];

    
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
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"حذف همه" message:@"آیا مایل به حذف همهٔ اطلاعات این جدول هستید؟" preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak FavoriteTVC *weakSelf = self;
    
    [alert addAction:[UIAlertAction actionWithTitle:@"بله" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (self.selectionToggle.selectedSegmentIndex == TableTypeFavorites) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Favorites"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            weakSelf.favoritesID = nil;
            weakSelf.favoritesPlaces = nil;
            
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Recent Searches"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            weakSelf.recentSearchesID = nil;
            weakSelf.recentSearchesPlaces = nil;
            
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"خیر" style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger result = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesID.count : self.recentSearchesID.count;
    if (result == 0) {
        self.noItemLabel.hidden = NO;
        self.tableView.separatorColor = [UIColor clearColor];
        self.deleteAllButton.enabled = NO;
    } else {
        self.noItemLabel.hidden = YES;
        self.tableView.separatorColor = self.separatorColor;
        self.deleteAllButton.enabled = YES;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Favorite Cell"];
    
    Place *place = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesPlaces[indexPath.row] : self.recentSearchesPlaces[indexPath.row];
    
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
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

#pragma mark - 3D Touch methods

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[self.tableView convertPoint:location fromView:self.navigationController.view] ];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    if (cell) {
        previewingContext.sourceRect = cell.frame;
        DetailTVC *dtvc = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailTVC"];
        dtvc.place = self.selectionToggle.selectedSegmentIndex == TableTypeFavorites ? self.favoritesPlaces[indexPath.row] : self.recentSearchesPlaces[indexPath.row];

        return dtvc;
    }

    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    
    NSIndexPath *indexPath = [[self.tableView indexPathsForRowsInRect:previewingContext.sourceRect] lastObject];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"Detail From Favorites" sender:cell];
}


@end
