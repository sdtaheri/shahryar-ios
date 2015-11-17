//
//  CameraVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/3.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "CameraVC.h"
#import "RMAnnotation.h"
#import "AROverlayView.h"
#import "Group.h"
#import "DetailTVC.h"
#import "PlacesListTVC.h"
#import "UIFontDescriptor+IranSans.h"

@interface CameraVC ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *waitLabel;
@property (weak, nonatomic) UIVisualEffectView *errorLayer;

@property (nonatomic, strong) NSMutableArray *arData;
@property (nonatomic, strong) PRARManager *arManager;
@property (nonatomic) BOOL firstLaunch;

@end

#define MAX_DISTANCE 170
#define MAX_POINTS 50


@implementation CameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.waitLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];
    self.waitLabel.numberOfLines = 0;

    self.firstLaunch = YES;
    
    self.arManager = [[PRARManager alloc] initWithSize:[UIScreen mainScreen].bounds.size delegate:self shouldCreateRadar:YES];
    self.arManager.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.firstLaunch) {
        if (self.userLocation != nil) {
            [self.arManager startARWithData:self.arData forLocation:self.userLocation.coordinate];
        }
        self.firstLaunch = NO;
        [self configureUI];
    }
    
    self.waitLabel.hidden = YES;
    [self.spinner stopAnimating];
    
    if (self.userLocation == nil || self.arData.count == 0) {
        self.waitLabel.text = @"شما در محدوده نیستید یا نقطه‌ای برای نمایش وجود ندارد";
        if (self.userLocation == nil) {
            self.waitLabel.text = @"دستگاه قادر به یافتن موقعیت شما نیست";
        }
        self.waitLabel.hidden = NO;
        [self.view.subviews.lastObject setHidden:YES];
    }
    
    UIVisualEffectView *vev = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    vev.frame = self.view.bounds;
    vev.hidden = YES;
    [self.view addSubview:vev];
    vev.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];
    label.numberOfLines = 0;
    label.text = @"دستگاه را به حالت عمودی بچرخانید";
    label.textColor = [UIColor whiteColor];
    
    [vev.contentView addSubview:label];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [vev.contentView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:vev.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];

    UIImageView *rotate = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rotateDevice"]];
    rotate.translatesAutoresizingMaskIntoConstraints = NO;
    [vev.contentView addSubview:rotate];
    [vev.contentView addConstraint:[NSLayoutConstraint constraintWithItem:rotate attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:vev.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [vev.contentView addConstraint:[NSLayoutConstraint constraintWithItem:rotate attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:vev.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];

    [vev.contentView addConstraint:[NSLayoutConstraint constraintWithItem:rotate attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:label attribute:NSLayoutAttributeTop multiplier:1.0 constant:-16.0]];
    
    self.errorLayer = vev;
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(orientation) || orientation == UIDeviceOrientationPortraitUpsideDown) {
        self.errorLayer.hidden = NO;
        [self.view bringSubviewToFront:self.errorLayer];
        [self.view bringSubviewToFront:[self.view viewWithTag:150]];
        [self.view bringSubviewToFront:[self.view viewWithTag:151]];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    BOOL multitaskingMode = screenSize.width != size.width || screenSize.height != size.height;
    
    if (multitaskingMode && UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        self.errorLayer.hidden = YES;
        [self.arManager stopAR];
        [(CALayer*)(self.arManager.cameraLayer) removeFromSuperlayer];
        [self.arManager.arOverlaysContainerView removeFromSuperview];
        [(UIView *)self.arManager.radarView removeFromSuperview];
        self.arManager.delegate = nil;
        self.arManager.datasource = nil;
        self.arManager = nil;
        self.waitLabel.text = @"برای عملکرد دوربین از حالت مولتی تسکینگ خارج شوید";
        self.waitLabel.hidden = NO;
    } else {
        if (self.userLocation != nil) {
            
            [self.arManager stopAR];
            [(CALayer*)(self.arManager.cameraLayer) removeFromSuperlayer];
            [self.arManager.arOverlaysContainerView removeFromSuperview];
            [(UIView *)self.arManager.radarView removeFromSuperview];
            self.arManager.delegate = nil;
            self.arManager.datasource = nil;
            
            self.arManager = [[PRARManager alloc] initWithSize:size delegate:self shouldCreateRadar:YES];
            self.arManager.delegate = self;
            [self.arManager startARWithData:self.arData forLocation:self.userLocation.coordinate];
            
            [self.view bringSubviewToFront:[self.view viewWithTag:150]];
            [self.view bringSubviewToFront:[self.view viewWithTag:151]];
        }
        if (self.userLocation == nil || self.arData.count == 0) {
            self.waitLabel.text = @"شما در محدوده نیستید یا نقطه‌ای برای نمایش وجود ندارد";
            if (self.userLocation == nil) {
                self.waitLabel.text = @"دستگاه قادر به یافتن موقعیت شما نیست";
            }
            self.waitLabel.hidden = NO;
        } else {
            self.waitLabel.hidden = YES;
        }
        
        [self.view bringSubviewToFront:self.errorLayer];
        [self.view bringSubviewToFront:[self.view viewWithTag:150]];
        [self.view bringSubviewToFront:[self.view viewWithTag:151]];
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (UIDeviceOrientationIsLandscape(orientation) || orientation == UIDeviceOrientationPortraitUpsideDown) {
            self.errorLayer.hidden = NO;
        } else {
            self.errorLayer.hidden = YES;
        }
    }
}

- (void)configureUI {
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.tag = 150;
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    closeButton.tintColor = [UIColor colorWithWhite:1 alpha:0.9];
    [closeButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:closeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    
    
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeSystem];
    filterButton.tag = 151;
    [filterButton setImage:[UIImage imageNamed:@"filter_selected"] forState:UIControlStateNormal];
    filterButton.tintColor = [UIColor colorWithWhite:1 alpha:0.9];
    [filterButton addTarget:self action:@selector(dismissAndFilter:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:filterButton];
    filterButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:filterButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];

}

- (void)dealloc {
    [self.arManager stopAR];
    self.arManager.delegate = nil;
    self.arManager.datasource = nil;
    self.arManager = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
        
        for (Group *group in self.groups) {
        
            CLLocation *groupLocation = [[CLLocation alloc] initWithLatitude:group.latitude.floatValue longitude:group.longitude.floatValue];
            CLLocationDistance distance = [groupLocation distanceFromLocation:self.userLocation];
            
            if (CLLocationCoordinate2DIsValid(self.userLocation.coordinate) &&  distance < MAX_DISTANCE) {
                [temp addObject:@{@"Distance": @(distance), @"Group": group}];
            }
        }
        
        NSArray *distanceArray = [temp sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Distance" ascending:YES]]];

        if (distanceArray.count > MAX_POINTS) {
            distanceArray = [distanceArray subarrayWithRange:NSMakeRange(0, MAX_POINTS)];
        }
        for (NSDictionary *dic in distanceArray) {
            AROverlayView *item = [self createPointAtGroup:[dic objectForKey:@"Group"]];
            [_arData addObject:item];
        }
    }
    
    return _arData;
}

// Creates the Data for an AR Object at a given location
- (AROverlayView *)createPointAtGroup:(Group *)group
{
    
    AROverlayView *overlay = [[AROverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 60.0f)];
    overlay.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
    overlay.layer.cornerRadius = 7.f;
    overlay.group = group;
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
    if (group.places.count == 1) {
        label.text = [NSString stringWithFormat:@"%@", [group.places.anyObject title]];
    } else {
        NSString *title = group.title;
        if (!(title.length > 0)) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];
            label.text = [NSString stringWithFormat:@"%@ واحد صنفی",[formatter stringFromNumber:@(group.places.count)]];
        }
    }

    [overlay addSubview:label];
    
    return overlay;
}

- (void)overlayTouchedUpInside:(UITapGestureRecognizer *)sender {
    AROverlayView *view = (AROverlayView *)sender.view;
    Group *group = view.group;
    if (group.places.count == 1) {
        [self performSegueWithIdentifier:@"Show Details From Camera" sender:group.places.anyObject];
    } else if (group.places.count > 1) {
        [self performSegueWithIdentifier:@"Show List From Camera" sender:group];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    segue.destinationViewController.preferredContentSize = CGSizeMake(375.0, 500.0);
    
    if ([segue.identifier isEqualToString:@"Show Details From Camera"]) {
        DetailTVC *dtvc = [segue.destinationViewController childViewControllers][0];
        dtvc.place = sender;
    } else if ([segue.identifier isEqualToString:@"Show List From Camera"]) {
        PlacesListTVC *pltvc = [segue.destinationViewController childViewControllers][0];
        
        RMAnnotation *annotation = [RMAnnotation annotationWithMapView:nil coordinate:CLLocationCoordinate2DMake(0, 0) andTitle:nil];
        
        annotation.userInfo = sender;
        pltvc.annotations = @[annotation];
    }
}

@end
