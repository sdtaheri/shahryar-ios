//
//  AROverlayView.m
//  PRAR-Simple
//
//  Created by Cador Kevin on 14/08/14.
//  Copyright (c) 2014 GeoffroyLesage. All rights reserved.
//

#import "AROverlayView.h"

@implementation AROverlayView

-(CLLocationDistance)distanceFromLocation:(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coordinates = CLLocationCoordinate2DMake(self.place.latitude.floatValue, self.place.longitude.floatValue);
    CLLocation *objectLocation = [[CLLocation alloc] initWithLatitude:coordinates.latitude
                                                             longitude:coordinates.longitude];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                      longitude:coordinate.longitude];
    
    return [objectLocation distanceFromLocation:location];
}

@end
