//
//  ViewController.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/7/29.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "MainVC.h"
#import "Mapbox.h"
#import "PlacesLoader.h"

@interface MainVC () <CLLocationManagerDelegate, RMMapViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;

@property (strong, nonatomic) RMMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;

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
    
    [[PlacesLoader sharedInstance] loadPOIsWithSuccesHandler:^(NSDictionary *responseDict) {
        
        NSLog(@"Loading Places Successful");
        
        
    } errorHandler:^(NSError *error) {
        NSLog(@"Error In Loading Places: %@", error);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self fixInfoButton];
    
    RMMBTilesSource *offlineSource = [[RMMBTilesSource alloc] initWithTileSetResource:@"tehran" ofType:@"mbtiles"];
    self.mapView = [[RMMapView alloc] initWithFrame:CGRectZero andTilesource:offlineSource];
    self.mapView.hideAttribution = YES;
    self.mapView.showLogoBug = NO;

    self.mapView.minZoom = 11;
    self.mapView.maxZoom = 18;
    self.mapView.adjustTilesForRetinaDisplay = YES;
    
    self.mapView.zoom = 14;

    [self.mapView setConstraintsSouthWest:CLLocationCoordinate2DMake(35.472219, 51.065355)
                                northEast:CLLocationCoordinate2DMake(35.905874, 51.606794)];
    
    self.mapView.showsUserLocation = YES;
    
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:self.mapView atIndex:0];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(_mapView)]];
    
    
    [self.locationManager startUpdatingLocation];
}

#pragma mark Helper Methods

- (void)fixInfoButton {
    [self.infoButton setTitle:@""];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [button addTarget:self action:@selector(showMoreInfo:) forControlEvents:UIControlEventTouchUpInside];
    self.infoButton.customView = button;
}

- (void)showMoreInfo:(UIButton *)sender {
    NSLog(@"More Info Button Was Touched");
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
        
        self.mapView.centerCoordinate = lastLocation.coordinate;
        [manager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Failed Location with %@", error);
    
    self.mapView.centerCoordinate = [[CLLocation alloc] initWithLatitude:Latitude_Default longitude:Longitude_Default].coordinate;
}

#pragma mark MapView Delegate


@end
