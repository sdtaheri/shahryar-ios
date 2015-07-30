//
//  PlacesLoader.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlacesLoader : NSObject

typedef void (^SuccessHandler)(NSDictionary *responseDict);
typedef void (^ErrorHandler)(NSError *error);

+ (PlacesLoader *)sharedInstance;

- (void)loadPOIsWithSuccesHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler;

@end
