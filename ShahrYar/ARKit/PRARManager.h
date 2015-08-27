//
//  PRARManager.h
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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ARControllerView.h"

@class ARRadar;
@class ARController;
@class AVCaptureVideoPreviewLayer;


@protocol PRARManagerDelegate;
@protocol PRARManagerDatasource;


@interface PRARManager : NSObject

@property (nonatomic) AVCaptureVideoPreviewLayer *cameraLayer;
@property (nonatomic) ARRadar *radarView;
@property (nonatomic) ARControllerView *arOverlaysContainerView;

@property (weak, nonatomic) id<PRARManagerDelegate> delegate;
@property (weak, nonatomic) id<PRARManagerDatasource> datasource;

- (id)initWithSize:(CGSize)size
          delegate:(id<PRARManagerDelegate>)delegate
 shouldCreateRadar:(BOOL)createRadar;

- (void)startARWithData:(NSArray*)arData forLocation:(CLLocationCoordinate2D)location;
- (void)stopAR;

@end


@protocol PRARManagerDelegate <NSObject>

- (void)augmentedRealityManagerDidSetup:(PRARManager*)arManager;
- (void)augmentedRealityManager:(PRARManager*)arManager didUpdateARFrame:(CGRect)frame;
- (void)augmentedRealityManager:(PRARManager*)arManager didReportError:(NSError*)error;

@end

@protocol PRARManagerDatasource <NSObject>

- (void)augmentedRealityManager:(PRARManager*)arManager userLocation:(CLLocationCoordinate2D)location;
- (void)augmentedRealityManager:(PRARManager*)arManager data:(NSArray*)data;
- (void)augmentedRealityManager:(PRARManager*)arManager viewForIndexPath:(NSIndexPath*)indexPath;

@end
