//
//  PlacesLoader.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "PlacesLoader.h"

NSString* const apiURL = @"http://www.yahoo.com";
NSString* const apiKey = @"";

@interface PlacesLoader()

@property (nonatomic, strong) SuccessHandler successHandler;
@property (nonatomic, strong) ErrorHandler errorHandler;
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation PlacesLoader

+ (PlacesLoader *)sharedInstance {
    static PlacesLoader *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[PlacesLoader alloc] init];
    });
    
    return instance;
}

- (void)loadPOIsWithSuccesHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler {
    
    self.responseData = nil;
    [self setSuccessHandler:handler];
    [self setErrorHandler:errorHandler];
    
    NSURL *url = [NSURL URLWithString:apiURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:YES];
    [request setHTTPMethod:@"GET"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (self.errorHandler) {
                self.errorHandler(error);
            }
        } else {
            if (!self.responseData) {
                self.responseData = [NSMutableData dataWithData:data];
            } else {
                [self.responseData appendData:data];
            }
            
            id object = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:nil];
            if (self.successHandler) {
                self.successHandler(object);
            }
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    
    [task resume];
    
}

@end
