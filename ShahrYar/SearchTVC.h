//
//  SearchTVC.h
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/2.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTVC : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) NSArray *places;
@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSArray *recentIDSearches; //of Place ID
@property (strong, nonatomic) NSArray *recentPlaceSearches; // of Place

@end
