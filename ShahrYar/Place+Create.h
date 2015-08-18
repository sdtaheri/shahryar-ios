//
//  Place+Create.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/1.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Place.h"

@interface Place (Create)

+ (Place *)placeWithInfo:(NSDictionary *)placeDictionary
  inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)loadPlacesFromArray:(NSArray *)places // of NSDictionary
   intoManagedObjectContext:(NSManagedObjectContext *)context;

@end
