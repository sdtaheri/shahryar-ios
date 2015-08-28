//
//  CameraVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/3.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PRARManager.h"
#import "MainVC.h"

@interface CameraVC : UIViewController <PRARManagerDelegate>

@property (nonatomic, weak) MainVC *mainVC;
@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) CLLocation *userLocation;

@end
