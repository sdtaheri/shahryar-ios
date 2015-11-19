//
//  AppDelegate.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "AppDelegate.h"
#import "MainVC.h"
#import "FavoriteTVC.h"
#import "UIFontDescriptor+IranSans.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#define ImageCacheLimit 30

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        NSError *error = nil;
        //Create one
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            NSURL *url = [NSURL fileURLWithPath:appSupportDir];
            if (![url setResourceValue:@YES
                                forKey:NSURLIsExcludedFromBackupKey
                                 error:&error])
            {
                NSLog(@"Error excluding %@ from backup %@", url.lastPathComponent, error.localizedDescription);
            }
            else {
                NSLog(@"Yay!");
            }
        }
    } else {
        NSError *error;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appSupportDir error:&error];
        while (contents.count > ImageCacheLimit) {

            // sort by creation date
            NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[contents count]];
            for(NSString* file in contents) {
                NSString* filePath = [appSupportDir stringByAppendingPathComponent:file];
                NSDictionary* properties = [[NSFileManager defaultManager]
                                            attributesOfItemAtPath:filePath
                                            error:&error];
                NSDate* modDate = [properties objectForKey:NSFileModificationDate];
                
                if(error == nil)
                {
                    [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   file, @"path",
                                                   modDate, @"lastModDate",
                                                   nil]];
                }
            }
            
            // sort using a block
            // order inverted as we want latest date first
            NSMutableArray *sortedFiles = [[[filesAndProperties sortedArrayUsingComparator:
                                    ^(id path1, id path2)
                                    {
                                        // compare
                                        NSComparisonResult comp = [[path1 objectForKey:@"lastModDate"] compare:
                                                                   [path2 objectForKey:@"lastModDate"]];
                                        return comp;
                                    }] valueForKey:@"path"] mutableCopy];
            if (sortedFiles.count > 0) {
                NSString *oldestFilePath = sortedFiles.firstObject;
                
                NSError *deleteError;
                [[NSFileManager defaultManager] removeItemAtPath:[appSupportDir stringByAppendingPathComponent:oldestFilePath] error:&deleteError];
                if (deleteError) {
                    break;
                }
                
                [sortedFiles removeObjectAtIndex:0];
            }
            
            contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appSupportDir error:&error];
        }
    }
    
    [self setFonts];
    
    return YES;
}

- (void)setFonts {

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentRight;
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{ NSParagraphStyleAttributeName: paragraphStyle}];
    
    UIBarButtonItem *cancelButton = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
    [cancelButton setTitle:@"انصراف"];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{
                                                                                                 NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle:UIFontTextStyleCaption2] size:0],
                                                                                                 }];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle:UIFontTextStyleSubheadline] size:0]
                                                           }];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle:UIFontTextStyleCaption1] size:0]} forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle:UIFontTextStyleFootnote] size:0]} forState:UIControlStateNormal];
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [self saveContext];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    
    MainVC *viewController = self.window.rootViewController.childViewControllers[0];
    [viewController dismissViewControllerAnimated:NO completion:^{
    }];
    
    if ([shortcutItem.type containsString:@"AR"]) {
        [viewController performSegueWithIdentifier:@"Launch Camera" sender:nil];
    } else if ([shortcutItem.type containsString:@"Search"]) {
        
        if (viewController.searchController == nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveLocationsSetSearchNotification:)
                                                         name:@"LocationsSet"
                                                       object:nil];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [viewController.searchController.searchBar becomeFirstResponder];
            });
        }
        
    } else if ([shortcutItem.type containsString:@"Favorites"]) {

        if (viewController.searchController == nil) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveLocationsSetFavNotification:)
                                                         name:@"LocationsSet"
                                                       object:nil];
        } else {
            UINavigationController *nc = [viewController.storyboard instantiateViewControllerWithIdentifier:@"FavoriteNC"];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [nc setPreferredContentSize:CGSizeMake(375.0, 500.0)];
            
            FavoriteTVC *ftvc = nc.childViewControllers[0];

            [viewController.searchTVC viewWillAppear:NO];
            
            ftvc.allPlaces = viewController.searchTVC.allPlaces;
            ftvc.searchTVC = viewController.searchTVC;
            
            [viewController presentViewController:nc animated:YES completion:NULL];
        }
    }
    
    completionHandler(YES);
}

- (void)receiveLocationsSetSearchNotification: (NSNotification *)note {
    if ([note.name isEqualToString:@"LocationsSet"]) {
        MainVC *viewController = self.window.rootViewController.childViewControllers[0];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationsSet" object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [viewController.searchController.searchBar becomeFirstResponder];
        });
    }
}

- (void)receiveLocationsSetFavNotification: (NSNotification *)note {
    if ([note.name isEqualToString:@"LocationsSet"]) {
        MainVC *viewController = self.window.rootViewController.childViewControllers[0];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationsSet" object:nil];

        UINavigationController *nc = [viewController.storyboard instantiateViewControllerWithIdentifier:@"FavoriteNC"];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [nc setPreferredContentSize:CGSizeMake(375.0, 500.0)];
        
        FavoriteTVC *ftvc = nc.childViewControllers[0];
        [viewController.searchTVC viewWillAppear:NO];
        
        ftvc.allPlaces = viewController.searchTVC.allPlaces;
        ftvc.searchTVC = viewController.searchTVC;
        
        [viewController presentViewController:nc animated:YES completion:NULL];
    }
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.saeedtaheri.ShahrYar" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ShahrYar" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ShahrYar.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        
        // Replace this with code to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
