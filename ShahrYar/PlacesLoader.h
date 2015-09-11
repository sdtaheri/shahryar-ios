//
//  PlacesLoader.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* const Saved_Version = @"Current Version";

@interface PlacesLoader : NSObject

typedef void (^SuccessHandler)(id response);
typedef void (^ErrorHandler)(NSError *error);

+ (PlacesLoader *)sharedInstance;

- (void)checkLatestVersionWithSuccessHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler;

- (void)loadPOIsWithSuccesHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler;

- (void)placesInDatabase: (NSManagedObjectContext *)context completion:(void (^)(NSArray *output, NSError *error))completion;

@end
