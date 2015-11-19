//
//  Place+Create.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/1.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "Place+Create.h"
#import "Type+Create.h"
#import "Group+Create.h"
#import "GeodeticUTMConverter.h"

NSString* const Place_Unique_ID = @"Id";
NSString* const Place_Title = @"Title";
NSString* const Place_Category_ID = @"CategoryId";
NSString* const Place_Category_Description = @"CategoryDescription";
NSString* const Place_Activities = @"Activities";
NSString* const Place_Email = @"Email";
NSString* const Place_Website = @"Website";
NSString* const Place_Faxes = @"Faxes";
NSString* const Place_Phones = @"Phones";
NSString* const Place_Address = @"Address";
NSString* const Place_Image_ID = @"PictureCode";
NSString* const Place_Logo_ID = @"LogoCode";
NSString* const Place_Easting = @"X";
NSString* const Place_Northing = @"Y";
NSString* const Place_Elevation = @"Z";
NSString* const Place_Last_Version = @"LastVersion";
NSString* const Place_Group_ID = @"GroupId";
NSString* const Place_Group_Name = @"Groupname";

@implementation Place (Create)

+ (Place *)placeWithInfo:(NSDictionary *)placeDictionary inManagedObjectContext:(NSManagedObjectContext *)context {
    
    Place *place = nil;
    
    NSString *unique = placeDictionary[Place_Unique_ID];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Place"];
    request.predicate = [NSPredicate predicateWithFormat:@"uniqueID = %@", unique];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || [matches count] > 1) {
        // Handle Error
    } else if ([matches count]) {
        [context deleteObject:[matches firstObject]];
        [context save:nil];
    }
    
    place = [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:context];
    
    place.activities = placeDictionary[Place_Activities];
    place.category = [Type categoryWithDescription:placeDictionary[Place_Category_Description] uniqueID:placeDictionary[Place_Category_ID] inManagedObjectContext:context];
    place.email = placeDictionary[Place_Email];
    place.faxes = placeDictionary[Place_Faxes];
    place.uniqueID = unique;
    place.lastVersion = placeDictionary[Place_Last_Version];
    place.logoID = placeDictionary[Place_Logo_ID];
    place.phones = placeDictionary[Place_Phones];
    place.imageID = placeDictionary[Place_Image_ID];
    place.title = placeDictionary[Place_Title];
    place.webSite = placeDictionary[Place_Website];
    place.address = placeDictionary[Place_Address];
    place.elevation = @([placeDictionary[Place_Elevation] doubleValue]);
    
    UTMCoordinates coordinates;
    coordinates.gridZone = 39;
    coordinates.hemisphere = kUTMHemisphereNorthern;
    coordinates.easting = [placeDictionary[Place_Easting] doubleValue];
    coordinates.northing = [placeDictionary[Place_Northing] doubleValue];
    
    CLLocationCoordinate2D location = [GeodeticUTMConverter UTMCoordinatesToLatitudeAndLongitude:coordinates];
    place.latitude = @(location.latitude);
    place.longitude = @(location.longitude);
    
    place.group = [Group groupWithUniqueID:placeDictionary[Place_Group_ID] name:placeDictionary[Place_Group_Name] latitude:place.latitude longitude:place.longitude inManagedObjectContext:context];
    
    return place;
}

+ (void)loadPlacesFromArray:(NSArray *)places intoManagedObjectContext:(NSManagedObjectContext *)context {
    for (NSDictionary *place in places) {
        [self placeWithInfo:place inManagedObjectContext:context];
    }
}


@end
