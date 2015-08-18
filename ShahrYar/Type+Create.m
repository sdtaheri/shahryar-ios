//
//  Type+Create.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/14.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Type+Create.h"

NSString* const Category_ID = @"CategoryId";
NSString* const Category_Description = @"CategoryDescription";

@implementation Type (Create)

+ (Type *)categoryWithDescription:(NSString *)summary uniqueID:(NSString *)uniqeID inManagedObjectContext:(NSManagedObjectContext *)context {

    Type *category = nil;
    
    if (uniqeID.length) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
        request.predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@", uniqeID];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || error || matches.count > 1) {
            //Handle Error
        } else if (matches.count == 0) {
            category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
            category.summary = summary;
            category.uniqueID = uniqeID;
        } else {
            category = matches.lastObject;
        }
    }
    
    return category;
}

@end
