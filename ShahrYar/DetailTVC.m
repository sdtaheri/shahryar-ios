//
//  DetailTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/16.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "DetailTVC.h"
#import "DDetailCell.h"
#import "Type.h"
#import "Mapbox.h"

@interface DetailTVC () <MFMailComposeViewControllerDelegate, RMMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *placeImageView;
@property (weak, nonatomic) IBOutlet UIView *footerMapView;
@property (strong, nonatomic) NSMutableArray *tableDatasource;

@end

static const NSString *Image_Base_URL = @"http://31.24.237.18:2243/images/DBPictures/";
static const NSString *Logo_Base_URL = @"http://31.24.237.18:2243/images/DBLogos45/";

@implementation DetailTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.placeImageView.clipsToBounds = YES;
    
    [self configureDatasource];
    
    if (self.place.imageID.length > 0 && !self.place.imageLocalPath) {
        NSString *imageURLString = [NSString stringWithFormat:@"%@%@.jpg",Image_Base_URL,self.place.imageID];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:imageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSData *imageData = [NSData dataWithContentsOfURL:location];
                
                NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

                NSURL *url = [NSURL fileURLWithPath:appSupportDir];
                
                NSString *fileName = [NSString stringWithFormat:@"Image%@.dat",self.place.imageID];
                NSURL * finalURL = [url URLByAppendingPathComponent:fileName];
                
                if ([imageData writeToURL:finalURL atomically:YES]) {
                    self.place.imageLocalPath = finalURL.path;
                    [self.place.managedObjectContext performBlock:^{
                        [self.place.managedObjectContext save:NULL];
                    }];
                } else {
                    NSLog(@"Error Saving Image to Disk");
                }

                UIImage *image = [UIImage imageWithData:imageData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.placeImageView.image = image;
                    self.placeImageView.alpha = 0;
                    self.placeImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, MIN(image.size.height * self.view.frame.size.width / image.size.width, 210));

                    [UIView animateWithDuration:0.3 animations:^{
                        self.placeImageView.alpha = 1;
                    }];

                    [self.tableView reloadData];
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                });
            }
        }];
        [task resume];
    } else if (self.place.imageLocalPath) {
        NSData *imageData = [NSData dataWithContentsOfFile:self.place.imageLocalPath];
        UIImage *image = [UIImage imageWithData:imageData];
        
        if (imageData) {
            self.placeImageView.image = image;
            self.placeImageView.alpha = 0;
            self.placeImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, MIN(image.size.height * self.view.frame.size.width / image.size.width, 210));
            
            [UIView animateWithDuration:0.3 animations:^{
                self.placeImageView.alpha = 1;
            }];
            
            [self.tableView reloadData];
        }
        
    } else {
        self.placeImageView.frame = CGRectZero;
    }
    
    RMMBTilesSource *offlineSource = [[RMMBTilesSource alloc] initWithTileSetResource:@"tehran" ofType:@"mbtiles"];
    RMMapView *mapView = [[RMMapView alloc] initWithFrame:CGRectZero andTilesource:offlineSource];
    mapView.hideAttribution = YES;
    mapView.showLogoBug = NO;
    mapView.delegate = self;
    
    mapView.minZoom = 13;
    mapView.maxZoom = 18;
    mapView.adjustTilesForRetinaDisplay = YES;
    
    mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.footerMapView insertSubview:mapView atIndex:0];
    [self.footerMapView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(mapView)]];
    [self.footerMapView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mapView]|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:NSDictionaryOfVariableBindings(mapView)]];
    
    UIBarButtonItem *loveButton;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"Love_%@",self.place.uniqueID];
    
    if (![userDefaults objectForKey: key]) {
        loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love"] landscapeImagePhone:[UIImage imageNamed:@"love_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
    } else {
        loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love_selected"] landscapeImagePhone:[UIImage imageNamed:@"love_selected_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
    }
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePlace:)];
    
    self.navigationItem.rightBarButtonItems = @[shareButton, loveButton];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    RMMapView *mapView = self.footerMapView.subviews[0];
    mapView.centerCoordinate = CLLocationCoordinate2DMake(self.place.latitude.floatValue, self.place.longitude.floatValue);
    
    [mapView removeAllAnnotations];
    [mapView addAnnotation:[RMAnnotation annotationWithMapView:mapView coordinate:mapView.centerCoordinate andTitle:self.place.title]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    if (self.placeImageView.image) {
        self.placeImageView.frame = CGRectMake(0, 0, size.width, MIN(self.placeImageView.image.size.height * size.width / self.placeImageView.image.size.width, 210));
    }
    
}
- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 100;
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    [(UITableViewHeaderFooterView *)view contentView].backgroundColor = [UIColor whiteColor];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 16.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return section == 0 ? self.tableDatasource.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell Normal" forIndexPath:indexPath];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (indexPath.section == 0 && indexPath.row != 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell Detail" forIndexPath:indexPath];
    }
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = self.place.title;
                cell.textLabel.textColor = [UIColor blackColor];
                
                UIFontDescriptor *userHeadLineFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
                CGFloat userHeadLineFontSize = [userHeadLineFont pointSize];
                cell.textLabel.font = [UIFont fontWithName:@"IRANSans-Medium" size:userHeadLineFontSize - 2];
                
                if (self.place.logoID.length > 0 && !self.place.logoLocalPath) {
                    
                    NSString *logoURLString = [NSString stringWithFormat:@"%@%@.jpg",Logo_Base_URL,self.place.logoID];
                    
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:logoURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                        if (!error) {
                            NSData *imageData = [NSData dataWithContentsOfURL:location];
                            
                            NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];

                            NSURL *url = [NSURL fileURLWithPath:appSupportDir];
                            
                            NSString *fileName = [NSString stringWithFormat:@"Logo%@.dat",self.place.logoID];
                            NSURL * finalURL = [url URLByAppendingPathComponent:fileName];
                            
                            if ([imageData writeToURL:finalURL atomically:YES]) {
                                self.place.logoLocalPath = finalURL.path;
                                [self.place.managedObjectContext performBlock:^{
                                    [self.place.managedObjectContext save:NULL];
                                }];
                            } else {
                                NSLog(@"Error Saving Image to Disk");
                            }

                            UIImage *image = [UIImage imageWithData: imageData];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.imageView.image = image;
                            });
                        }
                    }];
                    [task resume];
                } else if (self.place.logoLocalPath) {
                    NSData *imageData = [NSData dataWithContentsOfFile: self.place.logoLocalPath];
                    UIImage *image = [UIImage imageWithData:imageData];
                    
                    cell.imageView.image = image;
                } else {
                    cell.imageView.image = nil;
                }
                
                return cell;
                break;
            }
                
            default: {
                DDetailCell *detailCell = (DDetailCell *)cell;
                detailCell.label.text = [self.tableDatasource[indexPath.row] allKeys][0];
                detailCell.labelDetail.text = [self.tableDatasource[indexPath.row] allValues][0];
                
                if ([detailCell.label.text isEqualToString:@"شمارهٔ تماس"]) {
                    [detailCell.labelButton setImage:[UIImage imageNamed:@"call"] forState:UIControlStateNormal];
                    [detailCell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [detailCell.labelButton addTarget:self action:@selector(callNumber:) forControlEvents:UIControlEventTouchUpInside];
                    
                } else if ([detailCell.label.text isEqualToString:@"وب سایت"]) {
                    [detailCell.labelButton setImage:[UIImage imageNamed:@"safari"] forState:UIControlStateNormal];
                    [detailCell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [detailCell.labelButton addTarget:self action:@selector(openWebsite:) forControlEvents:UIControlEventTouchUpInside];
                } else if ([detailCell.label.text isEqualToString:@"ایمیل"]) {
                    [detailCell.labelButton setImage:[UIImage imageNamed:@"email"] forState:UIControlStateNormal];
                    [detailCell.labelButton removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                    [detailCell.labelButton addTarget:self action:@selector(sendEmail:) forControlEvents:UIControlEventTouchUpInside];
                } else {
                    [[(DDetailCell *)cell labelButton] setImage:nil forState:UIControlStateNormal];
                    [[(DDetailCell *)cell labelButton] removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
                }
                
                return cell;
                break;
            }
        }
    } else if (indexPath.section == 1) {
        cell.textLabel.textColor = self.view.tintColor;
        UIFontDescriptor *userBodyFont = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        CGFloat userBodyFontSize = [userBodyFont pointSize];
        cell.textLabel.font = [UIFont fontWithName:@"IRANSans-Light" size:userBodyFontSize - 3];

        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"ارتباط با ما";
            break;
            default:
                break;
        }
    }
    
    return cell;
}

- (void)configureDatasource {
    self.tableDatasource = [NSMutableArray array];
    
    [self.tableDatasource addObject:@{@"عنوان": self.place.title}];
    
    if (self.place.activities.length > 0) {
        [self.tableDatasource addObject:@{@"شرح فعالیت": self.place.activities}];
    }
    
    [self.tableDatasource addObject:@{@"دسته‌بندی": self.place.category.summary}];
    
    if (self.place.phones.length > 0) {
        self.place.phones = [self.place.phones stringByReplacingOccurrencesOfString:@"-" withString:@"\n"];
        [self.tableDatasource addObject:@{@"شمارهٔ تماس": self.place.phones}];
    }
    
    if (self.place.faxes.length > 0) {
        self.place.faxes = [self.place.faxes stringByReplacingOccurrencesOfString:@"-" withString:@"\n"];
        [self.tableDatasource addObject:@{@"نمابر": self.place.faxes}];
    }

    if (self.place.webSite.length > 0) {
        [self.tableDatasource addObject:@{@"وب سایت": self.place.webSite}];
    }

    if (self.place.email.length > 0) {
        [self.tableDatasource addObject:@{@"ایمیل": self.place.email}];
    }
    
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
        
    // Prevent the cell from inheriting the Table View's margin settings
    [cell setPreservesSuperviewLayoutMargins:NO];
    
    // Explictly set your cell's layout margins
    [cell setLayoutMargins:UIEdgeInsetsZero];
}


#pragma mark - Helper Methods

- (void)sharePlace: (UIBarButtonItem *)sender {
    
    NSString *coordinates = [NSString stringWithFormat:@"http://maps.apple.com/maps?q=%f,%f",  self.place.latitude.floatValue, self.place.longitude.floatValue];

    NSMutableArray *activities = [NSMutableArray array];
    
    for (NSDictionary *dic in self.tableDatasource) {
        [activities addObject:dic.allValues.lastObject];
    }
    [activities addObject:[NSURL URLWithString:coordinates]];
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:activities applicationActivities:nil];
    
    [self presentViewController:avc animated:YES completion:NULL];
}

- (void)lovePlace: (UIBarButtonItem *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"Love_%@",self.place.uniqueID];
    
    if ([userDefaults objectForKey: key]) {
        [userDefaults removeObjectForKey:key];
        
        UIBarButtonItem *loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love"] landscapeImagePhone:[UIImage imageNamed:@"love_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
        
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], loveButton];
    } else {
        [userDefaults setBool:YES forKey:key];
        
        UIBarButtonItem *loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love_selected"] landscapeImagePhone:[UIImage imageNamed:@"love_selected_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];

        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], loveButton];
    }
    
}

- (void)openWebsite: (UIButton *)sender {

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",self.place.webSite]]];
}

- (void)callNumber: (UIButton *)sender {
    NSArray *numbersToCall = [self.place.phones componentsSeparatedByString:@"\n"];
    NSMutableArray *correctNumbersToCall = [numbersToCall mutableCopy];
    
    for (int i = 0; i < numbersToCall.count; i++) {
        NSString *number = numbersToCall[i];
        if (![number hasPrefix:@"0"]){
            correctNumbersToCall[i] = [NSString stringWithFormat:@"021 %@",number];
        } else {
            correctNumbersToCall[i] = [NSString stringWithFormat:@"%@ %@",[number substringToIndex:4],[number substringFromIndex:4]];
        }
    }
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"تماس با:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *number in correctNumbersToCall) {
        [ac addAction:[UIAlertAction actionWithTitle:number style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSString *phoneNumber = [@"tel://" stringByAppendingString:[number stringByReplacingOccurrencesOfString:@" " withString:@""]];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"انصراف" style:UIAlertActionStyleCancel handler:NULL]];
    
    [self presentViewController:ac animated:YES completion:NULL];
}

- (void)sendEmail:(UIButton *)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
        mail.mailComposeDelegate = self;
        [mail setToRecipients:@[self.place.email]];
        
        [self presentViewController:mail animated:YES completion:NULL];
    
    } else {
        NSLog(@"This device cannot send email");
    }
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation {
    if (annotation.isUserLocationAnnotation) {
        return nil;
    }
    
    RMMarker *pin = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:@"pin"] anchorPoint:CGPointMake(0.25, 0.897)];
    pin.canShowCallout = YES;
    
    CABasicAnimation *hover = [CABasicAnimation animationWithKeyPath:@"position"];
    hover.additive = YES;
    hover.fromValue = [NSValue valueWithCGPoint:CGPointZero];
    hover.toValue = [NSValue valueWithCGPoint:CGPointMake(0.0, -15.0)];
    hover.autoreverses = YES;
    hover.duration = 0.3;
    hover.repeatCount = 1;
    hover.timingFunction = [CAMediaTimingFunction functionWithName:
                            kCAMediaTimingFunctionEaseInEaseOut];
    [pin addAnimation:hover forKey:@"myHoverAnimation"];
    
    return pin;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
