//
//  AROverlayView.m
//  PRAR-Simple
//
//  Created by Cador Kevin on 14/08/14.
//  Copyright (c) 2014 GeoffroyLesage. All rights reserved.
//

#import "AROverlayView.h"

@implementation AROverlayView

- (CLLocationDistance)distanceFromLocation:(CLLocationCoordinate2D)coordinate {
    
    CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:self.group.latitude.floatValue
                                                            longitude:self.group.longitude.floatValue];
        
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                      longitude:coordinate.longitude];
    
    return [objectLocation distanceFromLocation:location];
}

@end
