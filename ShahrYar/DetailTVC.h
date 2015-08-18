//
//  DetailTVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/16.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Place.h"

@interface DetailTVC : UITableViewController

@property (nonatomic, weak) Place *place;

@end
