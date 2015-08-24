//
//  FavoriteTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/25.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "FavoriteTVC.h"

@interface FavoriteTVC ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *selectionToggle;

@end

@implementation FavoriteTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = [self.selectionToggle titleForSegmentAtIndex:self.selectionToggle.selectedSegmentIndex];
}

- (IBAction)selectionToggled:(UISegmentedControl *)sender {
    self.navigationItem.title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Favorite Cell"];
    
    return cell;
}

@end
