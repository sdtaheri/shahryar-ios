 //
//  PRARManager.m
//  PrometAR
//
// Created by Geoffroy Lesage on 10/07/13.
// Copyright (c) 2013 Promet Solutions Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "PRARManager.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

#import "LocationMath.h"

#import <AVFoundation/AVFoundation.h>

#import "ARRadar.h"
#import "ARController.h"
#import "ARSettings.h"

static NSString *const PRARMANAGER_ERROR_DOMAIN = @"PRARMANAGER_ERROR_DOMAIN";

@interface PRARManager()

@property (nonatomic) AVCaptureSession *cameraSession;
@property (nonatomic) BOOL shouldCreateRadarView;
@property (nonatomic) CADisplayLink *refreshTimer;
@property (nonatomic) CGSize arViewSize;

@property (nonatomic, strong) ARController *arController;

@end

@implementation PRARManager

#pragma mark - Life cycle

- (instancetype)initWithSize:(CGSize)size delegate:(id<PRARManagerDelegate>)delegate shouldCreateRadar:(BOOL)createRadar {
    self = [super init];
    if (self) {
        self.shouldCreateRadarView = createRadar;
        self.delegate = delegate;
        self.arViewSize = size;
        
        CGRect frame = CGRectMake(0, 0, OVERLAY_VIEW_WIDTH, size.height);
        self.arOverlaysContainerView = [[UIView alloc] initWithFrame:frame];
        
        self.arController = [[ARController alloc] init];
        
        [self startCamera];
    }
    return self;
}

- (void)dealloc {
    [self.cameraSession stopRunning];
    [self.refreshTimer invalidate];
}

- (void)startCamera {
    self.cameraSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
	if (videoDevice) {
		NSError *error;
		AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (!error) {
			if ([self.cameraSession canAddInput:videoIn]) {
                [self.cameraSession addInput:videoIn];
            } else {
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: @"Couldn't add video input",
                                           NSLocalizedFailureReasonErrorKey: @"Couldn't add video input"
                                           };
                NSError *error = [NSError errorWithDomain:PRARMANAGER_ERROR_DOMAIN
                                                     code:400
                                                 userInfo:userInfo];
                [self.delegate augmentedRealityManager:self didReportError:error];
            }
		} else {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: @"Couldn't create video input",
                                       NSLocalizedFailureReasonErrorKey: @"Couldn't add video input"
                                       };
            NSError *error = [NSError errorWithDomain:PRARMANAGER_ERROR_DOMAIN
                                                 code:400
                                             userInfo:userInfo];
            [self.delegate augmentedRealityManager:self didReportError:error];
        }
	} else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Couldn't create video capture device",
                                   NSLocalizedFailureReasonErrorKey: @"Couldn't create video capture device"
                                   };
        NSError *error = [NSError errorWithDomain:PRARMANAGER_ERROR_DOMAIN
                                             code:400
                                         userInfo:userInfo];
        [self.delegate augmentedRealityManager:self didReportError:error];
    }
    
    self.cameraLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.cameraSession];
    [self.cameraLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CGRect layerRect = CGRectMake(0, 0, self.arViewSize.width, self.arViewSize.height);
	[self.cameraLayer setBounds:layerRect];
	[self.cameraLayer setPosition:CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect))];
}

#pragma mark - AR Setup

- (void)reloadData {
    [[self.arOverlaysContainerView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (UIView *overlay in self.arController.overlayViews) {
        [self.arOverlaysContainerView addSubview:overlay];
    }
}

- (void)setupRadar {
    if (self.shouldCreateRadarView) {
        self.radarView = [[ARRadar alloc] initWithFrame:CGRectMake((self.arViewSize.width/2)-50,
                                                                   self.arViewSize.height-100,
                                                                   100,
                                                                   100)
                                              withSpots:[self.arController radarSpots]];
    }
}


#pragma mark - Refresh Of Overlay Positions

-(void)refreshPositionOfOverlay {
    CGRect newPos = [self.arController.locationMath getCurrentFramePosition];
    [self.radarView moveDots:[self.arController.locationMath getCurrentHeading]];
    
    CGRect newFrame = CGRectMake(newPos.origin.x,
                                 newPos.origin.y,
                                 OVERLAY_VIEW_WIDTH,
                                 self.arViewSize.height);
    
    [self.delegate augmentedRealityManager:self didUpdateARFrame:newFrame];
}

#pragma mark - AR controls

- (void)stopAR {
    [self.refreshTimer invalidate];
}

- (void)startARWithData:(NSArray*)arData forLocation:(CLLocationCoordinate2D)location {
    if (arData.count < 1) {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"No data",
                                   NSLocalizedFailureReasonErrorKey: @"No data to display in reality",
                                   NSLocalizedRecoverySuggestionErrorKey: @"have you set your data up?"
                                   };
        NSError *error = [NSError errorWithDomain:PRARMANAGER_ERROR_DOMAIN
                                             code:400
                                         userInfo:userInfo];
        [self.delegate augmentedRealityManager:self didReportError:error];
        return;
    }
    
    NSLog(@"Starting AR with %lu places", (unsigned long)arData.count);
    
    [self.arController.locationMath startTrackingWithLocation:location
                                                      andSize:self.arViewSize];
    
    self.arController.overlayViews = arData;
    self.arController.userCoordinate = location;
    [self.arController reloadData];
    [self reloadData];
    
    if (self.shouldCreateRadarView) {
        [self setupRadar];
    }
    [self.cameraSession startRunning];
    
    [self.delegate augmentedRealityManagerDidSetup:self];
    
    self.refreshTimer = [CADisplayLink displayLinkWithTarget:self
                                                    selector:@selector(refreshPositionOfOverlay)];
    [self.refreshTimer addToRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSDefaultRunLoopMode];
}

@end
