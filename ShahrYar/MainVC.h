//
//  ViewController.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTVC.h"

@interface MainVC : UIViewController

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) SearchTVC *searchTVC;

@end

