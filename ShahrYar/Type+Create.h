//
//  Type+Create.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/14.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Type.h"

@interface Type (Create)

+ (Type *)categoryWithDescription:(NSString *)summary uniqueID:(NSString *)uniqeID inManagedObjectContext:(NSManagedObjectContext *)context;

@end
