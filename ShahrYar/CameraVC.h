//
//  CameraVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/3.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARKit.h"

@interface CameraVC : UIViewController <ARDelegate, ARLocationDelegate, ARMarkerDelegate>

@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) MKUserLocation *userLocation;

@end
