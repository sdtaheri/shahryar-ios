//
//  ViewController.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "AppDelegate.h"
#import "NavigationController.h"
#import "ShahrYar-Swift.h"
#import "MainVC.h"
#import "Place+Create.h"
#import "Type.h"
#import "Group.h"
#import "UIFontDescriptor+IranSans.h"

#import "DetailTVC.h"
#import "CameraVC.h"
#import "SearchTVC.h"
#import "FilterTVC.h"
#import "SearchTVC.h"
#import "PlacesListTVC.h"

#import "MBProgressHUD.h"

#import "Mapbox.h"
#import "PlacesLoader.h"

@interface MainVC () <CLLocationManagerDelegate, RMMapViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet MKButton *launchCameraButton;
@property (weak, nonatomic) IBOutlet MKButton *showCurrentLocationButton;

@property (nonatomic) BOOL firstLaunch;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) SearchTVC *searchTVC;

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@property (strong, nonatomic) NSArray *locations;
@property (strong, nonatomic) NSArray *groups;

@property (strong, nonatomic) RMMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) BubbleTransition *transition;
@property (nonatomic) CGRect selectedClusterAnnotationRect;

@property (nonatomic) BOOL shouldToggleStatusBarOnTap;

@end

NSString* const Location_Access_Error_Title = @"خطای دسترسی";
NSString* const Location_Access_Error_Message = @"اجازهٔ دسترسی به موقعیت مکانی صادر نشده است. به تنظیمات مراجعه کنید";
NSString* const Settings_Button_Title = @"تنظیمات";
NSString* const Later_Button_Title = @"بعداً";
double const Radius_Accuracy = 70.0;
CLLocationDegrees const Latitude_Default = 35.74;
CLLocationDegrees const Longitude_Default = 51.3;


@implementation MainVC

#pragma mark Properties

- (void)setLocations:(NSArray *)locations {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"در حال بارگذاری";
    hud.labelFont = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];
    
    _locations = locations;
    self.searchTVC.places = locations;
    
    self.groups = [self.locations valueForKeyPath:@"@distinctUnionOfObjects.group"];
}

- (void)setGroups:(NSArray *)groups {
    _groups = groups;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapView removeAllAnnotations];
        for (Group *group in _groups) {
            RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake(group.latitude.doubleValue, group.longitude.doubleValue) andTitle:group.title];
            if (group.places.count > 1) {
                annotation.userInfo = group;
            } else {
                annotation.userInfo = group.places.anyObject;
                annotation.title = [group.places.anyObject title];
            }
            [self.mapView addAnnotation:annotation];
        }
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
    });
}

- (BubbleTransition *)transition {
    if (!_transition) {
        _transition = [[BubbleTransition alloc] init];
    }
    return _transition;
}

- (NSUserDefaults *)userDefaults {
    
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    
    return _userDefaults;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        
        switch ([CLLocationManager authorizationStatus]) {
            
            case kCLAuthorizationStatusNotDetermined:
                [_locationManager requestWhenInUseAuthorization];
                break;
                
            case kCLAuthorizationStatusRestricted:
            case kCLAuthorizationStatusDenied: {
                //Show Alert

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:Location_Access_Error_Title message:Location_Access_Error_Message preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:Settings_Button_Title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    
                    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    [[UIApplication sharedApplication] openURL:appSettings];

                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:Later_Button_Title style:UIAlertActionStyleCancel handler:nil]];
                break;
            }
                
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusAuthorizedAlways:
                //Everything is fine

                _locationManager.delegate = self;
                _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                break;
        }
    }
    
    return _locationManager;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    [[PlacesLoader sharedInstance] checkLatestVersionWithSuccessHandler:^(id response) {
        
        NSString *version = [NSString stringWithFormat:@"%@",response];
        
        if (![version isEqualToString:[self.userDefaults objectForKey:Saved_Version]]) {
            
            [[PlacesLoader sharedInstance] loadPOIsWithSuccesHandler:^(NSArray *responseArray) {
                
                __weak MainVC *weakSelf = self;
                [self.managedObjectContext performBlock:^{
                    [Place loadPlacesFromArray:responseArray intoManagedObjectContext:weakSelf.managedObjectContext];
                    NSError *saveError;
                    [weakSelf.managedObjectContext save:&saveError];
                    if (saveError) {
                        NSLog(@"Saving Database Failed with Error: %@", saveError);
                    } else {
                        NSLog(@"Saving Database Successful");
                    }
                    
                    [[PlacesLoader sharedInstance] placesInDatabase:weakSelf.managedObjectContext completion:^(NSArray *output, NSError *error) {
                        weakSelf.locations = output;
                    }];
                    
                    [weakSelf.userDefaults setObject:version forKey:Saved_Version];
                    [weakSelf.userDefaults synchronize];
                }];
                
            } errorHandler:^(NSError *error) {
                NSLog(@"Error In Loading Places: %@", error);
            }];
            
        } else {
            NSLog(@"No Change in Database");
            [[PlacesLoader sharedInstance] placesInDatabase:self.managedObjectContext completion:^(NSArray *output, NSError *error) {
                self.locations = output;
            }];
        }
        
    } errorHandler:^(NSError *error) {
        NSLog(@"Error In Checking Latest Version Number: %@", error);
        
        if ([self.userDefaults objectForKey:Saved_Version] == nil) {
            __weak MainVC *weakSelf = self;
            [self.managedObjectContext performBlock:^{
                
                NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DataV1" ofType:@"json"];
                
                NSError *error;
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error];
                NSArray *array = [object objectForKey:@"Data"];
                
                [Place loadPlacesFromArray:array intoManagedObjectContext:weakSelf.managedObjectContext];
                NSError *saveError;
                [weakSelf.managedObjectContext save:&saveError];
                if (saveError) {
                    NSLog(@"Saving Local Database Failed with Error: %@", saveError);
                } else {
                    NSLog(@"Saving Local Database Successful");
                }
                
                [[PlacesLoader sharedInstance] placesInDatabase:weakSelf.managedObjectContext completion:^(NSArray *output, NSError *error) {
                    weakSelf.locations = output;
                }];
                
                [weakSelf.userDefaults setObject:@"0.5" forKey:Saved_Version];
                [weakSelf.userDefaults synchronize];
            }];
        } else {
            [[PlacesLoader sharedInstance] placesInDatabase:self.managedObjectContext completion:^(NSArray *output, NSError *error) {
                self.locations = output;
            }];
        }
    }];

    
    [self initializeSearchBar];
    
    [self configureUI];
    
    RMMBTilesSource *offlineSourceMain = [[RMMBTilesSource alloc] initWithTileSetResource:@"main" ofType:@"mbtiles"];
    
    self.mapView = [[RMMapView alloc] initWithFrame:CGRectZero andTilesource:offlineSourceMain];

    self.mapView.hideAttribution = YES;
    self.mapView.showLogoBug = NO;
    self.mapView.delegate = self;

    self.mapView.minZoom = 11;
    self.mapView.maxZoom = 19;
    self.mapView.adjustTilesForRetinaDisplay = YES;
    self.mapView.clusteringEnabled = YES;
    self.mapView.clusterAreaSize = CGSizeMake(150, 150);
    
    [self.mapView setConstraintsSouthWest:CLLocationCoordinate2DMake(35.682363841599184, 51.37689990336)
                                northEast:CLLocationCoordinate2DMake(35.71828194736938, 51.421293384466445)];
    
    self.mapView.showsUserLocation = YES;
    
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.mapView atIndex:0];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_mapView]|" options:NSLayoutFormatDirectionRightToLeft metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    
    [self.locationManager startUpdatingLocation];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.firstLaunch) {
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(35.70191216162083, 51.40026917813411) animated:YES];
        [self.mapView setZoom:14 atCoordinate:CLLocationCoordinate2DMake(35.70191216162083, 51.40026917813411) animated:YES];
        self.firstLaunch = NO;
        
        if (self.mapView.isUserLocationVisible) {
            if (CLLocationCoordinate2DIsValid(self.mapView.userLocation.coordinate)) {
                [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
            }
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.searchController.searchBar sizeToFit];


    switch (self.mapView.userTrackingMode) {
        case RMUserTrackingModeFollowWithHeading:
            [self.mapView setUserTrackingMode:RMUserTrackingModeFollow animated:YES];
            break;
        default:
            break;
    }
    
    if (CLLocationCoordinate2DIsValid(self.mapView.userLocation.coordinate)) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Launch Camera"]) {
        CameraVC *cvc = segue.destinationViewController;
        cvc.userLocation = self.mapView.userLocation.location;
        cvc.mainVC = self;
        cvc.groups = self.groups;
        
    } else if ([segue.identifier isEqualToString:@"Detail Segue"]) {
        DetailTVC *dtvc = [segue.destinationViewController childViewControllers][0];
        dtvc.place = [self.mapView.selectedAnnotation userInfo];
        [(UINavigationController *)segue.destinationViewController popoverPresentationController].sourceRect = CGRectMake(self.mapView.selectedAnnotation.absolutePosition.x, self.mapView.selectedAnnotation.absolutePosition.y, 1, 1);
        
    } else if ([segue.identifier isEqualToString:@"Detail Segue From Search"]) {
        [segue.destinationViewController setPreferredContentSize:CGSizeMake(375.0, 500.0)];
        DetailTVC *dtvc = [segue.destinationViewController childViewControllers][0];
        dtvc.place = sender;
        if (self.searchController.popoverPresentationController && self.searchController.popoverPresentationController.permittedArrowDirections != UIPopoverArrowDirectionUnknown) {
            [self.searchController dismissViewControllerAnimated:YES completion:^{
                self.searchController.searchBar.text = @"";
            }];
        }
        
    } else if ([segue.identifier isEqualToString:@"Filter Segue"]) {
        FilterTVC *ftvc = segue.destinationViewController;
        ftvc.context = self.managedObjectContext;
        ftvc.popoverPresentationController.delegate = self;
        if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
            ftvc.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width - 60, 10, 40, 40);
        } else {
            ftvc.popoverPresentationController.sourceRect = CGRectMake(20, 10, 40, 40);
        }
    } else if ([segue.identifier isEqualToString:@"More Places List"]) {
        PlacesListTVC *tvvc = [segue.destinationViewController childViewControllers][0];
        tvvc.mainVC = self;
        tvvc.annotations = sender;
        tvvc.userLocation = self.mapView.userLocation.location;
        
        if ([sender isKindOfClass:[Group class]]) {
            [segue.destinationViewController setModalPresentationStyle: UIModalPresentationFormSheet];
            segue.destinationViewController.preferredContentSize = CGSizeMake(375.0, 500.0);
            RMAnnotation *annotation = [RMAnnotation annotationWithMapView:nil coordinate:CLLocationCoordinate2DMake(0, 0) andTitle:nil];
            annotation.userInfo = sender;
            tvvc.annotations = @[annotation];
        } else {
            tvvc.annotations = sender;
            [segue.destinationViewController setTransitioningDelegate: self];
            [segue.destinationViewController setModalPresentationStyle: UIModalPresentationCustom];
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    NavigationController *nc = (NavigationController *)self.navigationController;
    return nc.shouldHideStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    if ([[presented childViewControllers][0] isKindOfClass:[PlacesListTVC class]]) {
        return [[CustomPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    } else {
        return [[UIPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationOverFullScreen; // required, otherwise delegate method below is never called.
}

- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {

    UIBarButtonItem *bbi = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismissFilterPopover:)];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
    
    UIVisualEffectView *vev = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    vev.translatesAutoresizingMaskIntoConstraints = NO;
    [nc.view insertSubview:vev atIndex:0];

    [nc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[vev]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(vev)]];
    [nc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[vev]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(vev)]];
    
    nc.topViewController.navigationItem.leftBarButtonItem = bbi;
    nc.topViewController.navigationItem.title = @"دسته‌بندی‌ها";
    return nc;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView *__autoreleasing *)view {
    if ([popoverPresentationController.presentedViewController isKindOfClass:[FilterTVC class]]) {
        if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
            *rect = CGRectMake(self.view.frame.size.width - 60, 10, 40, 40);
        } else {
            *rect = CGRectMake(20, 10, 40, 40);
        }
    }
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
    if ([popoverPresentationController.presentedViewController isKindOfClass:[FilterTVC class]]) {
        [[PlacesLoader sharedInstance] placesInDatabase:self.managedObjectContext completion:^(NSArray *output, NSError *error) {
            self.locations = output;
        }];
    }
}

- (void)dismissFilterPopover: (UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [[PlacesLoader sharedInstance] placesInDatabase:self.managedObjectContext completion:^(NSArray *output, NSError *error) {
            self.locations = output;
        }];
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {

    self.transition.transitionMode = BubbleTransitionModePresent;
    
    CGPoint midPoint = CGPointMake(self.selectedClusterAnnotationRect.origin.x + (self.selectedClusterAnnotationRect.size.width / 2), self.selectedClusterAnnotationRect.origin.y + (self.selectedClusterAnnotationRect.size.height / 2));

    self.transition.startingPoint = midPoint;
    self.transition.bubbleColor = (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular || self.traitCollection.displayScale == 3) ?  [UIColor clearColor] : [UIColor whiteColor];
    
    return self.transition;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.transition.transitionMode = BubbleTransitionModeDismiss;
    CGPoint midPoint = CGPointMake(self.selectedClusterAnnotationRect.origin.x + (self.selectedClusterAnnotationRect.size.width / 2), self.selectedClusterAnnotationRect.origin.y + (self.selectedClusterAnnotationRect.size.height / 2));
    
    self.transition.startingPoint = midPoint;
    self.transition.bubbleColor = [UIColor whiteColor];
    
    return self.transition;
}

#pragma mark Helper Methods

- (void)configureUI {
    self.firstLaunch = YES;
    
    self.launchCameraButton.layer.shadowOpacity = 0.75;
    self.launchCameraButton.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.launchCameraButton.bounds].CGPath;
    self.launchCameraButton.layer.shadowRadius = 2.5;
    self.launchCameraButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.launchCameraButton.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    
    self.showCurrentLocationButton.layer.shadowOpacity = 0.75;
    self.showCurrentLocationButton.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.launchCameraButton.bounds].CGPath;
    self.showCurrentLocationButton.layer.shadowRadius = 2.5;
    self.showCurrentLocationButton.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.showCurrentLocationButton.layer.shadowOffset = CGSizeMake(1.0, 2.0);
}

- (void)initializeSearchBar {
    
    self.searchTVC = [[SearchTVC alloc] initWithStyle:UITableViewStylePlain];
    [self.searchTVC.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Search Cell"];
    self.searchTVC.managedObjectContext = self.managedObjectContext;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchTVC];
    self.searchController.searchResultsUpdater = self.searchTVC;
    self.searchController.delegate = self.searchTVC;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    UIWindow *window = [(AppDelegate *)[UIApplication sharedApplication].delegate window];
    if (window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && window.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        self.searchController.modalPresentationStyle = UIModalPresentationPopover;
    }
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    
    self.navigationItem.titleView = self.searchController.searchBar;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"جستجو، علاقه‌مندی‌ها";
    [self.searchController.searchBar sizeToFit];
    
    self.searchController.searchBar.showsBookmarkButton = YES;
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"filter"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"filter_selected"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateHighlighted];

    
    self.shouldToggleStatusBarOnTap = YES;
}

- (IBAction)showCurrentLocation:(MKButton *)sender {
    
    switch (self.mapView.userTrackingMode) {
        case RMUserTrackingModeNone:
            [self.mapView setUserTrackingMode:RMUserTrackingModeFollow animated:YES];
            break;
            
        case RMUserTrackingModeFollow:
            [self.mapView setUserTrackingMode:RMUserTrackingModeFollowWithHeading animated:YES];
            break;
        
        case RMUserTrackingModeFollowWithHeading:
            [self.mapView setUserTrackingMode:RMUserTrackingModeFollow animated:YES];
            break;
    }
    
    if (CLLocationCoordinate2DIsValid(self.mapView.userLocation.coordinate)) {
        [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
    }
}


#pragma mark CoreLocation Delegates

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
            
        case kCLAuthorizationStatusNotDetermined:
            [_locationManager requestWhenInUseAuthorization];
            break;
            
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied: {
            //Show Alert
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:Location_Access_Error_Title message:Location_Access_Error_Message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:Settings_Button_Title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:appSettings];
                
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:Later_Button_Title style:UIAlertActionStyleCancel handler:nil]];
            break;
        }
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            //Everything is fine
            
            self.locationManager.delegate = self;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            if (CLLocationCoordinate2DIsValid(self.mapView.userLocation.coordinate)) {
                [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
            }
            break;
    }

}

#pragma mark MapView Delegate

- (void)mapViewRegionDidChange:(RMMapView *)mapView {
    if (mapView.zoom > mapView.maxZoom - 2) {
        mapView.clusteringEnabled = NO;
    } else {
        mapView.clusteringEnabled = YES;
    }
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
    
    if (annotation.isUserLocationAnnotation) {
        return nil;
    }
    
    RMMapLayer *layer;
    
    
    if (!annotation.isClusterAnnotation) {

        RMMarker *pin = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin"] anchorPoint:CGPointMake(0.25, 0.897)];
        pin.canShowCallout = YES;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
        
        if ([annotation.userInfo isKindOfClass:[Place class]]) {
            if ([annotation.userInfo logoID].length > 0) {
                [pin setRightCalloutAccessoryView:imageView];
            } else if ([annotation.userInfo imageID].length > 0) {
                [pin setRightCalloutAccessoryView:imageView];
            }
        } else if ([annotation.userInfo isKindOfClass:[Group class]]) {
            annotation.title = [annotation.userInfo title];
            if (!(annotation.title.length > 0)) {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];
                
                NSInteger count = 0;
                Place *containingPlace;
                for (Place *place in [annotation.userInfo places]) {
                    if (place.category.selected.boolValue) {
                        count++;
                        containingPlace = place;
                    }
                }
                
                if (count == 0) {
                    return nil;
                } else if (count == 1) {
                    annotation.userInfo = containingPlace;
                    annotation.title = containingPlace.title;
                } else {
                    pin = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"groupPin"] anchorPoint:CGPointMake(0.25, 0.897)];
                    pin.canShowCallout = YES;
                    NSString *clusterLabelContent = [formatter stringFromNumber:@(count)];
                    annotation.title = [NSString stringWithFormat:@"%@ واحد صنفی",clusterLabelContent];
                }
                
            }
        }
        
        [pin setLeftCalloutAccessoryView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"UITableNext"]]];
        pin.leftCalloutAccessoryView.tintColor = [UIColor lightGrayColor];
        
        layer = pin;
    } else {
        // set the circle image for the cluster
        layer = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"circle.png"]];
        
        layer.opacity = 0.75;
        
        // change the size of the circle depending on the cluster's size
        if ([annotation.clusteredAnnotations count] < 20) {
            layer.bounds = CGRectMake(0, 0, 50, 50);
        } else if ([annotation.clusteredAnnotations count] < 50) {
            layer.bounds = CGRectMake(0, 0, 60, 60);
        } else if ([annotation.clusteredAnnotations count] < 100) {
            layer.bounds = CGRectMake(0, 0, 70, 70);
        } else {
            layer.bounds = CGRectMake(0, 0, 80, 80);
        }
        
        // define label content
        NSNumber *clusterLabelCount = @([annotation.clusteredAnnotations count]);
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];

        NSString *clusterLabelContent = [formatter stringFromNumber:clusterLabelCount];
        
        // calculate its size
        UIFont *labelFont = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleSubheadline] size: 0];

        CGRect labelSize = [clusterLabelContent boundingRectWithSize:
                            ((RMMarker *)layer).label.frame.size
                                                             options:NSStringDrawingUsesLineFragmentOrigin attributes:@{
                                                                                                                        NSFontAttributeName:labelFont }
                                                             context:nil];
        
        
        [(RMMarker *)layer setTextForegroundColor:[UIColor whiteColor]];
        
        // get the layer's size
        CGSize layerSize = layer.frame.size;
        
        // calculate its position
        CGPoint position = CGPointMake((layerSize.width - (labelSize.size.width + 4)) / 2,
                                       (layerSize.height - (labelSize.size.height + 4)) / 2);
        
        // set it all at once
        [(RMMarker *)layer changeLabelUsingText: clusterLabelContent position:position
                                           font:labelFont foregroundColor:[UIColor whiteColor]
                                backgroundColor:[UIColor clearColor]];
    }
    
    return layer;
}

- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point {
    if (self.shouldToggleStatusBarOnTap) {
        NavigationController *nc = (NavigationController *)self.navigationController;
        UIWindow *window = [(AppDelegate *)[UIApplication sharedApplication].delegate window];
        
        if (window.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) {
            nc.shouldHideStatusBar = !nc.shouldHideStatusBar;
        }
        
        if (!nc.navigationBarHidden) {
            [UIView animateWithDuration:0.35 animations:^{
                self.showCurrentLocationButton.transform = CGAffineTransformTranslate(self.showCurrentLocationButton.transform, -2*self.showCurrentLocationButton.frame.size.width, 0);
                
                self.launchCameraButton.transform = CGAffineTransformTranslate(self.launchCameraButton.transform, -2*self.launchCameraButton.frame.size.width, 0);
            }];
        } else {
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.35 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                
                self.showCurrentLocationButton.transform = CGAffineTransformIdentity;
                
                self.launchCameraButton.transform = CGAffineTransformIdentity;
                
            } completion:NULL];
        }
        
        [nc setNavigationBarHidden:!nc.navigationBarHidden animated:YES];
    }
    self.shouldToggleStatusBarOnTap = YES;
}

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    if (annotation.isClusterAnnotation) {
        
        self.selectedClusterAnnotationRect = annotation.layer.frame;
        [self performSegueWithIdentifier:@"More Places List" sender:annotation.clusteredAnnotations];
        
    }
}

- (void)tapOnCalloutforAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    if ([annotation.userInfo isKindOfClass:[Place class]]) {
        [self performSegueWithIdentifier:@"Detail Segue" sender:nil];
    } else if ([annotation.userInfo isKindOfClass:[Group class]]) {
        [self performSegueWithIdentifier:@"More Places List" sender:annotation.userInfo];
    }
}

- (void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation {
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    NSString *baseURL;
    NSString *imageId;

    RMMarker *pin = (RMMarker *)annotation.layer;

    if (!annotation.isClusterAnnotation) {
        if ([annotation.userInfo isKindOfClass:[Place class]]) {
            if ([(UIImageView *)pin.rightCalloutAccessoryView image] == nil) {
                if ([annotation.userInfo logoID].length > 0) {
                    baseURL = @"http://31.24.237.18:2243/images/DBLogos";
                    imageId = [annotation.userInfo logoID];
                } else if ([annotation.userInfo imageID].length > 0) {
                    baseURL = @"http://31.24.237.18:2243/images/DBPictures";
                    imageId = [annotation.userInfo imageID];
                }
                
                if (baseURL != nil) {
                    NSString *imageURLString = [NSString stringWithFormat:@"%@%d/%@.jpg",baseURL,(int)(screenScale * 30),imageId];
                    
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                    
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:imageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                        if (!error) {
                            NSData *imageData = [NSData dataWithContentsOfURL:location];
                            
                            UIImage *image = [UIImage imageWithData:imageData];
                            if (image == nil) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    pin.rightCalloutAccessoryView.frame = CGRectZero;
                                    pin.rightCalloutAccessoryView = nil;
                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                });
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [(UIImageView *)pin.rightCalloutAccessoryView setImage:image];
                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                });
                            }
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                pin.rightCalloutAccessoryView.frame = CGRectZero;
                                pin.rightCalloutAccessoryView = nil;
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                            });
                        }
                    }];
                    [task resume];
                }
            }
        }
    }
    
    self.shouldToggleStatusBarOnTap = NO;
}

- (void)mapView:(RMMapView *)mapView didDeselectAnnotation:(RMAnnotation *)annotation {
    self.shouldToggleStatusBarOnTap = NO;
}

#pragma mark - Search View

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    [self performSegueWithIdentifier:@"Filter Segue" sender:nil];
}

@end
