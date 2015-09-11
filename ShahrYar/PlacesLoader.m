//
//  PlacesLoader.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "PlacesLoader.h"
#import "NSManagedObjectContext+AsyncFetch.h"

NSString* const baseURL = @"http://31.24.237.18:2243/api/";
NSString* const checkversionMethod = @"GetVersion";
NSString* const readDataMethod = @"ReadData";
NSString* const APIKey = @"3234D74E-661E";

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

- (void)checkLatestVersionWithSuccessHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler {

    [self setSuccessHandler:handler];
    [self setErrorHandler:errorHandler];

    NSDictionary *methodArguments = @{
                                      @"ApiKey" : APIKey,
                                      };
    
    NSString *stringURL = [NSString stringWithFormat:@"%@%@%@", baseURL, checkversionMethod, [self escapedParameters:methodArguments]];
    NSURL *url = [NSURL URLWithString:stringURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:YES];
    request.timeoutInterval = 3.0;
    [request setHTTPMethod:@"GET"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            if (self.errorHandler) {
                self.errorHandler(error);
            }
        } else {
            
            id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if (self.successHandler) {
                self.successHandler(object);
            }
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    
    [task resume];
    
}

- (void)loadPOIsWithSuccesHandler:(SuccessHandler)handler errorHandler:(ErrorHandler)errorHandler {
    
    self.responseData = nil;
    [self setSuccessHandler:handler];
    [self setErrorHandler:errorHandler];
    
    NSString *myVersion = [[NSUserDefaults standardUserDefaults] objectForKey: Saved_Version];
    if (myVersion == nil) {
        myVersion = @"0";
    }
    
    NSDictionary *methodArguments = @{
                                      @"ApiKey" : APIKey,
                                      @"myVersion" : myVersion
                                      };
    
    NSString *stringURL = [NSString stringWithFormat:@"%@%@%@", baseURL, readDataMethod, [self escapedParameters:methodArguments]];
    NSURL *url = [NSURL URLWithString:stringURL];
    
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

- (void)placesInDatabase: (NSManagedObjectContext *)context completion:(void (^)(NSArray *output, NSError *error))completion {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Place"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.selected.boolValue = YES"];
    request.predicate = predicate;
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    [context executeFetchRequestAsync:request completion:^(NSArray *objects, NSError *error) {
        completion(objects, error);
    }];
}


/* Helper function: Given a dictionary of parameters, convert to a string for a url */
- (NSString *)escapedParameters: (NSDictionary *)parameters {
    NSMutableArray *urlVars = [NSMutableArray array];
    
    for (NSString *key in parameters) {

        /* Make sure that it is a string value */
        NSString *stringValue = [NSString stringWithFormat:@"%@",parameters[key]];
        
        /* Escape it */
        NSString *escapedValue = [stringValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        /* Append it */
        [urlVars addObject:[NSString stringWithFormat:@"%@=%@",key,escapedValue]];
    }
    
    return [NSString stringWithFormat:@"%@%@",(urlVars.count > 0 ? @"?" : @""), [urlVars componentsJoinedByString:@"&"]];
}



@end
