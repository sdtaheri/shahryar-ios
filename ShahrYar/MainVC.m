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

#import "Mapbox.h"
#import "PlacesLoader.h"
#import "PlaceAnnotation.h"

@interface MainVC () <CLLocationManagerDelegate, RMMapViewDelegate, UISearchResultsUpdating, UISearchBarDelegate>

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
    
    [self.mapView removeAllAnnotations];
    
    for (Place *place in _locations) {
        PlaceAnnotation *annotation = [[PlaceAnnotation alloc] initWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue) andTitle:place.title];
        annotation.place = place;
        [self.mapView addAnnotation:annotation];
    }
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

- (void)awakeFromNib {
    [super awakeFromNib];
    
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
                    
                    weakSelf.locations = [[PlacesLoader sharedInstance] allPlacesInDatabase:weakSelf.managedObjectContext];
                    [weakSelf.userDefaults setObject:version forKey:Saved_Version];
                    [weakSelf.userDefaults synchronize];
                }];
                
            } errorHandler:^(NSError *error) {
                NSLog(@"Error In Loading Places: %@", error);
            }];
            
        } else {
            NSLog(@"No Change in Database");
            self.locations = [[PlacesLoader sharedInstance] allPlacesInDatabase:self.managedObjectContext];
        }

    } errorHandler:^(NSError *error) {
        NSLog(@"Error In Checking Latest Version Number: %@", error);
        
        self.locations = [[PlacesLoader sharedInstance] allPlacesInDatabase:self.managedObjectContext];
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
        dtvc.place = [(PlaceAnnotation *)self.mapView.selectedAnnotation place];
        
        [(UINavigationController *)segue.destinationViewController popoverPresentationController].sourceRect = CGRectMake(self.mapView.selectedAnnotation.absolutePosition.x, self.mapView.selectedAnnotation.absolutePosition.y, 1, 1);
    }
}

- (BOOL)prefersStatusBarHidden {
    NavigationController *nc = (NavigationController *)self.navigationController;
    return nc.shouldHideStatusBar;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
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
    self.searchController.searchBar.showsSearchResultsButton = YES;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.placeholder = @"جستجو";
    
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
    
    RMMarker *pin = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin"] anchorPoint:CGPointMake(0.25, 0.897)];
    pin.canShowCallout = YES;
    
    PlaceAnnotation *placeAnnotation = (PlaceAnnotation *)annotation;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 31, 31)];
    
    if (placeAnnotation.place.logoID.length > 0) {
        [pin setLeftCalloutAccessoryView:imageView];
    } else if (placeAnnotation.place.imageID.length > 0) {
        [pin setLeftCalloutAccessoryView:imageView];
    }
    
    [pin setRightCalloutAccessoryView:[UIButton buttonWithType:UIButtonTypeDetailDisclosure]];
    
    return pin;
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

    PlaceAnnotation *placeAnnotation = (PlaceAnnotation *)annotation;
    RMMarker *pin = (RMMarker *)annotation.layer;

    if ([(UIImageView *)pin.leftCalloutAccessoryView image] == nil) {
        if (placeAnnotation.place.logoID.length > 0) {
            baseURL = @"http://31.24.237.18:2243/images/DBLogos";
            imageId = placeAnnotation.place.logoID;
        } else if (placeAnnotation.place.imageID.length > 0) {
            baseURL = @"http://31.24.237.18:2243/images/DBPictures";
            imageId = placeAnnotation.place.imageID;
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
    
    self.shouldToggleStatusBarOnTap = NO;
}

- (void)mapView:(RMMapView *)mapView didDeselectAnnotation:(RMAnnotation *)annotation {
    self.shouldToggleStatusBarOnTap = NO;
}

#pragma mark - Search View

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
}

@end
