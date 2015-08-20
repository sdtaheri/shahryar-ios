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

#import "DetailTVC.h"
#import "CameraVC.h"
#import "SearchTVC.h"
#import "FilterTVC.h"
#import "PlacesListTVC.h"

#import "Mapbox.h"
#import "PlacesLoader.h"

@interface MainVC () <CLLocationManagerDelegate, RMMapViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet MKButton *launchCameraButton;
@property (weak, nonatomic) IBOutlet MKButton *showCurrentLocationButton;

@property (nonatomic) BOOL firstLaunch;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) SearchTVC *searchTVC;

@property (weak, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) NSUserDefaults *userDefaults;

@property (strong, nonatomic) NSArray *locations;

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
    _locations = locations;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapView removeAllAnnotations];
        for (Place *place in _locations) {
            RMAnnotation *annotation = [[RMAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue) andTitle:place.title];
            annotation.userInfo = place;
            [self.mapView addAnnotation:annotation];
        }
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
                _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
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
        
        [[PlacesLoader sharedInstance] placesInDatabase:self.managedObjectContext completion:^(NSArray *output, NSError *error) {
            self.locations = output;
        }];
    }];

    
    [self initializeSearchBar];
    
    [self configureUI];
    
    RMMBTilesSource *offlineSource = [[RMMBTilesSource alloc] initWithTileSetResource:@"tehran" ofType:@"mbtiles"];
    self.mapView = [[RMMapView alloc] initWithFrame:CGRectZero andTilesource:offlineSource];
    self.mapView.hideAttribution = YES;
    self.mapView.showLogoBug = NO;
    self.mapView.delegate = self;

    self.mapView.minZoom = 11;
    self.mapView.maxZoom = 18;
    self.mapView.adjustTilesForRetinaDisplay = YES;
    self.mapView.clusteringEnabled = YES;
    self.mapView.clusterAreaSize = CGSizeMake(50, 50);
    
    [self.mapView setConstraintsSouthWest:CLLocationCoordinate2DMake(35.472219, 51.065355)
                                northEast:CLLocationCoordinate2DMake(35.905874, 51.606794)];
    
    self.mapView.showsUserLocation = YES;
    
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.mapView atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.firstLaunch) {
        [self.mapView zoomWithLatitudeLongitudeBoundsSouthWest:CLLocationCoordinate2DMake(35.698025, 51.386077) northEast:CLLocationCoordinate2DMake(35.705901, 51.412213) animated:YES];
        self.firstLaunch = NO;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.searchController.searchBar sizeToFit];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Launch Camera"]) {
        CameraVC *cvc = segue.destinationViewController;
        cvc.userLocation = (MKUserLocation *)self.mapView.userLocation;
        cvc.locations = self.locations;
        
    } else if ([segue.identifier isEqualToString:@"Detail Segue"]) {
        DetailTVC *dtvc = [segue.destinationViewController childViewControllers][0];
        dtvc.place = [self.mapView.selectedAnnotation userInfo];
        
        [(UINavigationController *)segue.destinationViewController popoverPresentationController].sourceRect = CGRectMake(self.mapView.selectedAnnotation.absolutePosition.x, self.mapView.selectedAnnotation.absolutePosition.y, 1, 1);
    } else if ([segue.identifier isEqualToString:@"Filter Segue"]) {
        FilterTVC *ftvc = segue.destinationViewController;
        ftvc.context = self.managedObjectContext;
        ftvc.popoverPresentationController.delegate = self;
        ftvc.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width - 60, 10, 40, 40);
    } else if ([segue.identifier isEqualToString:@"More Places List"]) {
        PlacesListTVC *tvvc = [segue.destinationViewController childViewControllers][0];
        tvvc.annotations = sender;
        [segue.destinationViewController setTransitioningDelegate: self];
        [segue.destinationViewController setModalPresentationStyle: UIModalPresentationCustom];
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
        *rect = CGRectMake(self.view.frame.size.width - 60, 10, 40, 40);
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
    self.transition.bubbleColor = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? [UIColor clearColor] : [UIColor whiteColor];
    
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
    self.launchCameraButton.layer.shadowRadius = 3.5;
    self.launchCameraButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.launchCameraButton.layer.shadowOffset = CGSizeMake(1.0, 5.5);
    
    self.showCurrentLocationButton.layer.shadowOpacity = 0.75;
    self.showCurrentLocationButton.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.launchCameraButton.bounds].CGPath;
    self.showCurrentLocationButton.layer.shadowRadius = 3.5;
    self.showCurrentLocationButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.showCurrentLocationButton.layer.shadowOffset = CGSizeMake(1.0, 5.5);
}

- (void)initializeSearchBar {
    
    self.searchTVC = [[SearchTVC alloc] initWithStyle:UITableViewStyleGrouped];
    [self.searchTVC.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Search Cell"];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchTVC];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self.searchTVC;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    UIWindow *window = [(AppDelegate *)[UIApplication sharedApplication].delegate window];
    if (window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && window.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        self.searchController.modalPresentationStyle = UIModalPresentationPopover;
    }
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    
    self.navigationItem.titleView = self.searchController.searchBar;
    
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.placeholder = @"جستجو";
    
    self.searchController.searchBar.showsBookmarkButton = YES;
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"filter"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
    [self.searchController.searchBar setImage:[UIImage imageNamed:@"filter_selected"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateHighlighted];

    
    self.shouldToggleStatusBarOnTap = YES;
}

- (IBAction)showCurrentLocation:(MKButton *)sender {
    [self.locationManager startUpdatingLocation];
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
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            [self.locationManager startUpdatingLocation];
            break;
    }

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *lastLocation = [locations lastObject];
    
    CLLocationAccuracy accuracy = [lastLocation horizontalAccuracy];
    NSLog(@"Received Location %@ with accuracy %f meters", lastLocation, accuracy);
    
    if (accuracy < Radius_Accuracy) {
        //To Implement: Zoom to region
        
        [self.mapView setCenterCoordinate:lastLocation.coordinate animated:YES];
        
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed Location with %@", error);
}

#pragma mark MapView Delegate

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
    
    if (annotation.isUserLocationAnnotation) {
        return nil;
    }
    
    RMMapLayer *layer;
    
    
    if (!annotation.isClusterAnnotation) {

        RMMarker *pin = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin"] anchorPoint:CGPointMake(0.25, 0.897)];
        pin.canShowCallout = YES;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
        
        if ([annotation.userInfo logoID].length > 0) {
            [pin setLeftCalloutAccessoryView:imageView];
        } else if ([annotation.userInfo imageID].length > 0) {
            [pin setLeftCalloutAccessoryView:imageView];
        }
        
        [pin setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
        
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
        CGRect labelSize = [clusterLabelContent boundingRectWithSize:
                            ((RMMarker *)layer).label.frame.size
                                                             options:NSStringDrawingUsesLineFragmentOrigin attributes:@{
                                                                                                                        NSFontAttributeName:[UIFont systemFontOfSize:15] }
                                                             context:nil];
        
        UIFont *labelFont = [UIFont fontWithName:@"IRANSans-Medium" size:14];
        
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

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    if (annotation.isClusterAnnotation) {
        
        self.selectedClusterAnnotationRect = annotation.layer.frame;
        [self performSegueWithIdentifier:@"More Places List" sender:annotation.clusteredAnnotations];
        
    }
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

- (void)tapOnCalloutAccessoryControl:(UIControl *)control forAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map {
    
    if ([control isKindOfClass:[UIButton class]]) {
        [self performSegueWithIdentifier:@"Detail Segue" sender:control];
    }
}

- (void)mapView:(RMMapView *)mapView didSelectAnnotation:(RMAnnotation *)annotation {
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    NSString *baseURL;
    NSString *imageId;

    RMMarker *pin = (RMMarker *)annotation.layer;

    if (!annotation.isClusterAnnotation) {
        if ([(UIImageView *)pin.leftCalloutAccessoryView image] == nil) {
            if ([annotation.userInfo logoID].length > 0) {
                baseURL = @"http://31.24.237.18:2243/images/DBLogos";
                imageId = [annotation.userInfo logoID];
            } else if ([annotation.userInfo imageID].length > 0) {
                baseURL = @"http://31.24.237.18:2243/images/DBPictures";
                imageId = [annotation.userInfo imageID];
            }
            
            if (baseURL != nil) {
                NSString *imageURLString = [NSString stringWithFormat:@"%@%@/%@.jpg",baseURL,screenScale == 3 ? @"45" : @"35",imageId];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                
                NSURLSession *session = [NSURLSession sharedSession];
                NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:imageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    if (!error) {
                        NSData *imageData = [NSData dataWithContentsOfURL:location];
                        
                        UIImage *image = [UIImage imageWithData:imageData];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [(UIImageView *)pin.leftCalloutAccessoryView setImage:image];
                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        });
                    }
                }];
                [task resume];
            }
        }
    }
    
    self.shouldToggleStatusBarOnTap = NO;
}

- (void)mapView:(RMMapView *)mapView didDeselectAnnotation:(RMAnnotation *)annotation {
    self.shouldToggleStatusBarOnTap = NO;
}

#pragma mark - Search View

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {
    [self performSegueWithIdentifier:@"Filter Segue" sender:nil];
}

@end
