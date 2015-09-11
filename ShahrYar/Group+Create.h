//
//  Group+Create.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/9/9.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Group.h"

@interface Group (Create)

+ (Group *)groupWithUniqueID:(NSString *)uniqueID name:(NSString *)title latitude:(NSNumber *)latitude longitude:(NSNumber *)longitude inManagedObjectContext:(NSManagedObjectContext *)context;

@end
