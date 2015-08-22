//
//  FilterTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "FilterTVC.h"
#import "Type.h"
#import "NSManagedObjectContext+AsyncFetch.h"

@interface FilterTVC () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *categories;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectToggle;
@property (nonatomic) int selectedRowsCount;

@end

@implementation FilterTVC

- (void)setSelectedRowsCount:(int)selectedRowsCount {
    _selectedRowsCount = selectedRowsCount;
    if (self.categories) {
        if (selectedRowsCount == 0) {
            [self.selectToggle setTitle:@"انتخاب همه"];
        } else if (selectedRowsCount == self.categories.count) {
            [self.selectToggle setTitle:@"لغو انتخاب‌ها"];
        } else if (selectedRowsCount < (int)(self.categories.count / 2)) {
            [self.selectToggle setTitle:@"لغو انتخاب‌ها"];
        } else {
            [self.selectToggle setTitle:@"انتخاب همه"];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Category"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"summary" ascending:YES selector:@selector(localizedStandardCompare:)];
    [request setSortDescriptors:@[sortDescriptor]];
    
    [self.context executeFetchRequestAsync:request completion:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.categories = objects;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"selected.boolValue = YES"];
            self.selectedRowsCount = (int)[self.categories filteredArrayUsingPredicate:predicate].count;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
}
- (IBAction)selectToggleTouched:(UIBarButtonItem *)sender {
    
    if ([sender.title isEqualToString:@"انتخاب همه"]) {
        for (Type *category in self.categories) {
            category.selected = @(YES);
        }
        self.selectedRowsCount = (int)self.categories.count;
    } else {
        for (Type *category in self.categories) {
            category.selected = @(NO);
        }
        self.selectedRowsCount = 0;
    }
    
    [self.context performBlock:^{
        NSError *error;
        [self.context save:&error];
        if (error) {
            NSLog(@"Saving Category Selected State Failed");
        }
    }];

    [self.tableView reloadData];
}

- (void)dealloc {
    self.categories = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Category Cell" forIndexPath:indexPath];

    cell.accessoryType = [self.categories[indexPath.row] selected].boolValue ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@",[self.categories[indexPath.row] summary]];
    } else if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.textLabel.text = [NSString stringWithFormat:@"     %@",[self.categories[indexPath.row] summary]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    BOOL selected;
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        self.selectedRowsCount++;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.text = [NSString stringWithFormat:@"%@",[self.categories[indexPath.row] summary]];
        selected = YES;
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        self.selectedRowsCount--;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"     %@",[self.categories[indexPath.row] summary]];
        selected = NO;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [(Type *)self.categories[indexPath.row] setSelected:@(selected)];
    [self.context performBlock:^{
        NSError *error;
        [self.context save:&error];
        if (error) {
            NSLog(@"Saving Category Selected State Failed");
        }
    }];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];

    // Remove seperator inset
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    
    // Prevent the cell from inheriting the Table View's margin settings
    [cell setPreservesSuperviewLayoutMargins:NO];
    
    // Explictly set your cell's layout margins
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

@end
