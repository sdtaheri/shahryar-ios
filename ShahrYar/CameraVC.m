//
//  CameraVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/3.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "CameraVC.h"
#import "AugmentedRealityController.h"
#import "MarkerView.h"

#import "Place.h"

@interface CameraVC ()

@property (nonatomic, strong) AugmentedRealityController *arController;
@property (nonatomic, strong) NSMutableArray *geoLocations;

@end

@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];

    if(!self.arController) {
        self.arController = [[AugmentedRealityController alloc] initWithViewController:self withDelgate:self];
    }
    
    [self.arController setMinimumScaleFactor:0.5];
    [self.arController setScaleViewsBasedOnDistance:YES];
    [self.arController setRotateViewsBasedOnPerspective:YES];
    [self.arController setDebugMode:NO];
    [self.arController setShowsRadar:YES];
    [self.arController setRadarRange:24000.0];
    [self.arController setOnlyShowItemsWithinRadarRange:NO];
    
    [self geoLocations];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"نقشه" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeftMargin multiplier:1.0 constant:0.0]];

}

- (void)dismiss:(UIButton *)sender {
    self.arController.delegate = nil;
    self.arController = nil;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

//- (void)generateGeoLocations {
//
//    [self setGeoLocations:[NSMutableArray arrayWithCapacity:self.locations.count]];
//    
//    for(Place *place in self.locations) {
//
//        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(place.latitude.floatValue, place.longitude.floatValue);
//        CLLocation *location = [[CLLocation alloc] initWithCoordinate:loc altitude:place.elevation.floatValue horizontalAccuracy:5 verticalAccuracy:1 timestamp:[NSDate date]];
//        ARGeoCoordinate *coordinate = [ARGeoCoordinate coordinateWithLocation:location locationTitle:place.title];
//
//        [coordinate calibrateUsingOrigin:self.userLocation.location];
//        
//        //more code later
//        
//
//        [self.arController addCoordinate:coordinate];
//        [self.geoLocations addObject:coordinate];
//    }
//}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)locationClicked:(ARGeoCoordinate *)coordinate{
    NSLog(@"Location Clicked: %@", coordinate);
}

- (void)didTapMarker:(ARGeoCoordinate *)coordinate {
    NSLog(@"Did Tap on Marker: %@", coordinate);
}

- (void)didUpdateHeading:(CLHeading *)newHeading {
//    NSLog(@"Updated to heading: %@",newHeading);
}

- (void)didUpdateLocation:(CLLocation *)newLocation {
//    NSLog(@"Updated to location: %@",newLocation);
}

- (void)didUpdateOrientation:(UIDeviceOrientation)orientation {
    NSLog(@"Updated to orientation: %ld",(long)orientation);
}

- (void)didFinishSnapshotGeneration:(UIImage *)image error:(NSError *)error {

}

- (NSMutableArray *)geoLocations{
    if (!_geoLocations) {
        NSMutableArray *locationArray = [[NSMutableArray alloc] init];
        ARGeoCoordinate *tempCoordinate;
        CLLocation *tempLocation;
        
        for (Place *place in self.locations) {
            tempLocation = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue) altitude:place.elevation.doubleValue horizontalAccuracy:1 verticalAccuracy:1 timestamp:[NSDate date]];
            
            tempCoordinate = [ARGeoCoordinate coordinateWithLocation:tempLocation locationTitle:place.title];
            [tempCoordinate calibrateUsingOrigin:self.userLocation.location];
            
            MarkerView *markerView = [[MarkerView alloc] initForCoordinate:tempCoordinate withDelgate:self allowsCallout:YES];
            [tempCoordinate setDisplayView:markerView];
            [self.arController addCoordinate:tempCoordinate];
            [locationArray addObject:tempCoordinate];
        }
        
        _geoLocations = locationArray;
    }
    return _geoLocations;
}

@end
