//
//  MorePlacesTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/19.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "PlacesListTVC.h"
#import "DetailTVC.h"
#import "Mapbox.h"

@interface PlacesListTVC ()

@property (nonatomic, strong) NSMutableArray *places;

@end

@implementation PlacesListTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44.f;
    self.navigationController.view.layer.masksToBounds = YES;
    
    self.places = [NSMutableArray arrayWithCapacity:self.annotations.count];
    for (RMAnnotation *annotation in self.annotations) {
        [self.places addObject: annotation.userInfo];
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@ مورد",[formatter stringFromNumber:@(self.annotations.count)]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.annotations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Place Cell"];
    
    cell.textLabel.text = [self.places[indexPath.row] title];
    cell.detailTextLabel.text = @"سلام";
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Detail From List"]) {
        DetailTVC *dtvc = segue.destinationViewController;
        dtvc.navigationItem.leftBarButtonItem = nil;
        dtvc.navigationItem.leftItemsSupplementBackButton = YES;
        NSInteger row = [self.tableView indexPathForCell:(UITableViewCell *)sender].row;
        dtvc.place = self.places[row];
    }
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
