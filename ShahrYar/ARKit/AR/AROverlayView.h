//
//  AROverlayView.h
//  PRAR-Simple
//
//  Created by Cador Kevin on 14/08/14.
//  Copyright (c) 2014 GeoffroyLesage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"

#import <CoreLocation/CoreLocation.h>

@interface AROverlayView : UIView

@property (nonatomic, weak) Group *group;
@property (nonatomic) int vertice;

- (CLLocationDistance)distanceFromLocation:(CLLocationCoordinate2D)coordinate;

@end
