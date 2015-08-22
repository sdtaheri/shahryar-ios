//
//  FilterTVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterTVC : UIViewController

@property (weak, nonatomic) NSManagedObjectContext *context;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
