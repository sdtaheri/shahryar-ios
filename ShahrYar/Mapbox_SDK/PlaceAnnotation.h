//
//  PlaceAnnotation.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/16.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "RMAnnotation.h"
#import "Place.h"

@interface PlaceAnnotation : RMAnnotation

@property (nonatomic, weak) Place *place;

@end
