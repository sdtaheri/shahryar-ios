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

@interface CameraVC : UIViewController <PRARManagerDelegate>

@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) MKUserLocation *userLocation;

@end
