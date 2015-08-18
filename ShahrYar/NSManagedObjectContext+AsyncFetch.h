//
//  NSManagedObjectContext+AsyncFetch.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (AsyncFetch)

- (void)executeFetchRequestAsync:(NSFetchRequest *)request completion:(void (^)(NSArray *objects, NSError *error))completion;

@end
