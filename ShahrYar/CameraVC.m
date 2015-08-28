//
//  CameraVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/3.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "CameraVC.h"
#import "AROverlayView.h"
#import "Place.h"
#import "DetailTVC.h"
#import "UIFontDescriptor+IranSans.h"

@interface CameraVC ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *waitLabel;

@property (nonatomic, strong) NSMutableArray *arData;
@property (nonatomic, strong) PRARManager *arManager;
@property (nonatomic) BOOL firstLaunch;

@end

#define MAX_DISTANCE 150
#define MAX_POINTS 50


@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.waitLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];

    self.firstLaunch = YES;
    
    CGFloat minimum = MIN(self.view.frame.size.width, self.view.frame.size.height);
    CGFloat maximum = MAX(self.view.frame.size.width, self.view.frame.size.height);
    
    self.arManager = [[PRARManager alloc] initWithSize:CGSizeMake(minimum,maximum) delegate:self shouldCreateRadar:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.firstLaunch) {
        [self.arManager startARWithData:self.arData forLocation:self.userLocation.coordinate];
        self.firstLaunch = NO;
        [self configureUI];
    }
    
    self.waitLabel.hidden = YES;
    [self.spinner stopAnimating];
    
    if (self.arData.count == 0) {
        self.waitLabel.text = @"نقطه‌ای برای نمایش وجود ندارد";
        self.waitLabel.hidden = NO;
        [self.view.subviews.lastObject setHidden:YES];
    }
}

- (void)configureUI {
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    closeButton.tintColor = [UIColor colorWithWhite:1 alpha:0.9];
    [closeButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    
    
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [filterButton setImage:[UIImage imageNamed:@"filter_selected"] forState:UIControlStateNormal];
    filterButton.tintColor = [UIColor colorWithWhite:1 alpha:0.9];
    [filterButton addTarget:self action:@selector(dismissAndFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:filterButton];
    filterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];

}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)dealloc {
    [self.arManager stopAR];
    self.arManager.delegate = nil;
    self.arManager = nil;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (void)dismiss:(UIButton *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dismissAndFilter:(UIButton *)sender {
    __weak MainVC *weakMainVC = self.mainVC;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [weakMainVC performSegueWithIdentifier:@"Filter Segue" sender:nil];
    }];
}

#pragma mark AR Delegate

- (void)augmentedRealityManagerDidSetup:(PRARManager *)arManager {
    [self.view.layer addSublayer:(CALayer*)arManager.cameraLayer];
    [self.view addSubview:arManager.arOverlaysContainerView];
    
    [self.view bringSubviewToFront:arManager.arOverlaysContainerView];
    
    if (arManager.radarView) {
        [self.view addSubview:(UIView*)arManager.radarView];
    }
}

- (void)augmentedRealityManager:(PRARManager *)arManager didUpdateARFrame:(CGRect)frame {
    [arManager.arOverlaysContainerView setFrame:frame];
}

- (void)augmentedRealityManager:(PRARManager *)arManager didReportError:(NSError *)error {

}

- (NSArray *)arData {

    if (!_arData) {
        _arData = [NSMutableArray array];
        NSMutableArray *temp = [NSMutableArray array];
        for (Place *place in self.locations) {
            CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:place.latitude.floatValue longitude:place.longitude.floatValue];
            CLLocationDistance distance = [placeLocation distanceFromLocation:self.userLocation.location];
            
            if (CLLocationCoordinate2DIsValid(self.userLocation.coordinate) &&  distance < MAX_DISTANCE) {
                [temp addObject:@{@"Distance": @(distance), @"Place": place}];
            }
        }
        
        NSArray *distanceArray = [temp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Distance" ascending:YES]]];

        if (distanceArray.count > MAX_POINTS) {
            distanceArray = [distanceArray subarrayWithRange:NSMakeRange(0, MAX_POINTS)];
        }
        for (NSDictionary *dic in distanceArray) {
            AROverlayView *item = [self createPointAtPlace:[dic objectForKey:@"Place"]];
            [_arData addObject:item];
        }
    }
    
    return _arData;
}

// Creates the Data for an AR Object at a given location
- (AROverlayView *)createPointAtPlace:(Place *)place
{
    
    AROverlayView *overlay = [[AROverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 60.0f)];
    overlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    overlay.layer.cornerRadius = 7.f;
    overlay.place = place;
    overlay.clipsToBounds = YES;
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTouchedUpInside:)];
    [overlay addGestureRecognizer:tgr];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectInset(overlay.bounds, 10, 5)];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentRight;
    [label setMinimumScaleFactor:0.8];
    label.adjustsFontSizeToFitWidth = YES;
    label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];
    label.clipsToBounds = YES;
    label.numberOfLines = 0;
    label.text = [NSString stringWithFormat:@"%@", place.title];

    [overlay addSubview:label];
    
    return overlay;
}

- (void)overlayTouchedUpInside:(UITapGestureRecognizer *)sender {
    AROverlayView *view = (AROverlayView *)sender.view;
    [self performSegueWithIdentifier:@"Show Details From Camera" sender:view.place];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Details From Camera"]) {
        DetailTVC *dtvc = [segue.destinationViewController childViewControllers][0];
        dtvc.place = sender;
    }
}


@end
