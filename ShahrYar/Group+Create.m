//
//  Group+Create.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/9/9.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Group+Create.h"

@implementation Group (Create)

+ (Group *)groupWithUniqueID:(NSString *)uniqueID name:(NSString *)title latitude:(NSNumber *)latitude longitude:(NSNumber *)longitude inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Group *group = nil;
    
    if (uniqueID.length) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Group"];
        request.predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@", uniqueID];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || matches.count > 1) {
            //Handle Error
        } else if (matches.count == 0) {
            group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
            group.uniqueID = uniqueID;
            group.latitude = latitude;
            group.longitude = longitude;
            group.title = title;
        } else {
            group = matches.lastObject;
        }
    }
    
    return group;
}

@end
