//
//  FilterTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "FilterTVC.h"
#import "Type.h"
#import <CoreData/CoreData.h>

@interface FilterTVC ()

@property (nonatomic, strong) NSArray *categories;

@end

@implementation FilterTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Category"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"summary" ascending:YES selector:@selector(localizedStandardCompare:)];
    [request setSortDescriptors:@[sortDescriptor]];
    
    NSError *error;
    self.categories = [self.context executeFetchRequest:request error:&error];
    [self.tableView reloadData];
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
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.text = [NSString stringWithFormat:@"%@",[self.categories[indexPath.row] summary]];
        selected = YES;
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
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
    
    cell.contentView.backgroundColor = [UIColor clearColor];

    // Remove seperator inset
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    
    // Prevent the cell from inheriting the Table View's margin settings
    [cell setPreservesSuperviewLayoutMargins:NO];
    
    // Explictly set your cell's layout margins
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

@end
