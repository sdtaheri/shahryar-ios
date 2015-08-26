//
//  MorePlacesTVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/19.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MainVC.h"

@interface PlacesListTVC : UITableViewController

@property (nonatomic, strong) NSArray *annotations;
@property (nonatomic, strong) CLLocation *userLocation;
@property (nonatomic, weak) MainVC *mainVC;

@end
