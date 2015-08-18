//
//  Type.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Place;

@interface Type : NSManagedObject

@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSSet *places;
@end

@interface Type (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSSet *)values;
- (void)removePlaces:(NSSet *)values;

@end
