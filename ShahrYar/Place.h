//
//  Place.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/18.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Type;

@interface Place : NSManagedObject

@property (nonatomic, retain) NSString * activities;
@property (nonatomic, retain) NSNumber * elevation;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * faxes;
@property (nonatomic, retain) NSString * imageLocalPath;
@property (nonatomic, retain) NSString * imageID;
@property (nonatomic, retain) NSString * lastVersion;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * logoLocalPath;
@property (nonatomic, retain) NSString * logoID;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * phones;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uniqueID;
@property (nonatomic, retain) NSString * webSite;
@property (nonatomic, retain) Type *category;

@end
