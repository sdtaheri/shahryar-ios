//
//  FavoriteTVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/25.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTVC.h"

@interface FavoriteTVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *allPlaces;
@property (weak, nonatomic) SearchTVC *searchTVC;

@end
