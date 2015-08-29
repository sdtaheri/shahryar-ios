//
//  DetailTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/16.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

@import AddressBook;
@import MessageUI;

#import "GeodeticUTMConverter.h"
#import "DetailTVC.h"
#import "DDetailCell.h"
#import "Type.h"
#import "Mapbox.h"
#import "DeviceInfo.h"
#import "UIFontDescriptor+IranSans.h"

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
    
    self.navigationItem.title = @"";
    
    [self configureDatasource];
    
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *imageURLString = [NSString stringWithFormat:@"%@%@.jpg",Image_Base_URL,self.place.imageID];
    
    NSString *fileName = [NSString stringWithFormat:@"Image%@.dat",self.place.imageID];
    NSURL * finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];

    if ((self.place.imageID.length > 0 && !self.place.imageLocalPath) || (self.place.imageLocalPath && ![[NSFileManager defaultManager] fileExistsAtPath:finalURL.path])) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:imageURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSData *imageData = [NSData dataWithContentsOfURL:location];
                
                if ([imageData writeToURL:finalURL atomically:YES]) {
                    self.place.imageLocalPath = fileName;
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
        NSString *fileName = self.place.imageLocalPath;
        NSURL *finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];

        NSData *imageData = [NSData dataWithContentsOfFile:finalURL.path];
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
    
    NSArray *favorites = [userDefaults objectForKey:@"Favorites"];
    BOOL selected = NO;
    if (favorites) {
        if ([favorites containsObject:self.place.uniqueID]) {
            selected = YES;
        }
    }
    
    if (!selected) {
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
    [mapView setZoom:15 animated:YES];
    
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

    return section == 0 ? self.tableDatasource.count : 2;
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
                
                cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleSubheadline] size: 0];
                
                NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
                
                NSString *fileName = [NSString stringWithFormat:@"Logo%@.dat",self.place.logoID];
                NSURL * finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];

                
                if ((self.place.logoID.length > 0 && !self.place.logoLocalPath) || (self.place.logoLocalPath && ![[NSFileManager defaultManager] fileExistsAtPath:finalURL.path])) {
                    
                    NSString *logoURLString = [NSString stringWithFormat:@"%@%@.jpg",Logo_Base_URL,self.place.logoID];
                    
                    NSURLSession *session = [NSURLSession sharedSession];
                    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:logoURLString] completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                        if (!error) {
                            NSData *imageData = [NSData dataWithContentsOfURL:location];
                            
                            if ([imageData writeToURL:finalURL atomically:YES]) {
                                self.place.logoLocalPath = fileName;
                                [self.place.managedObjectContext performBlock:^{
                                    [self.place.managedObjectContext save:NULL];
                                }];
                            } else {
                                NSLog(@"Error Saving Image to Disk");
                            }

                            UIImage *image = [UIImage imageWithData: imageData];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                cell.imageView.image = image;
                                [cell setNeedsLayout];
                            });
                        }
                    }];
                    [task resume];
                } else if (self.place.logoLocalPath) {
                    NSString *fileName = self.place.logoLocalPath;
                    NSURL *finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];

                    NSData *imageData = [NSData dataWithContentsOfFile: finalURL.path];
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
        cell.textLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];

        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"اضافه کردن به مخاطبین";
            break;
            case 1:
                cell.textLabel.text = @"ارتباط با ما";
            break;
            default:
                break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        
        switch (indexPath.row) {
            case 0:
                [self addToAddressBook: self.place];
                break;
            case 1:
                if ([MFMailComposeViewController canSendMail]) {
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ارتباط با ما" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
                    
                    NSString *deviceModel = [DeviceInfo model];
                    NSString *OSVersion = [[UIDevice currentDevice] systemVersion];
                    
                    void (^alertAction)(UIAlertAction *action);
                    alertAction = ^ (UIAlertAction *action) {
                        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
                        mail.mailComposeDelegate = self;
                        [mail setSubject:action.title];
                        
                        NSString *messageBody = [NSString stringWithFormat:@"<br><br><br><p>Device: <b>%@</b><br>iOS Version: <b>%@</b></p>",deviceModel,OSVersion] ;
                        if ([action.title isEqualToString:@"گزارش وجود ایراد"]) {
                            messageBody = [NSString stringWithFormat:@"<br><br><br><p align=\"right\" dir=\"rtl\">نام: <b>%@</b><br>کد محل: <b>%@</b></p><p>Device: <b>%@</b><br>iOS Version: <b>%@</b></p>",self.place.title, self.place.uniqueID, deviceModel,OSVersion];
                        }
                        
                        [mail setMessageBody:messageBody isHTML:YES];
                        [mail setToRecipients:@[@"info@zibasazi.ir"]];
                        
                        [self presentViewController:mail animated:YES completion:NULL];
                    };
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"گزارش وجود ایراد" style:UIAlertActionStyleDefault handler:alertAction]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"انتقاد و پیشنهاد" style:UIAlertActionStyleDefault handler:alertAction]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"انصراف" style:UIAlertActionStyleCancel handler:NULL]];
                    
                    [self presentViewController:alert animated:YES completion:NULL];
                    
                } else {
                    NSLog(@"This device cannot send email");
                }
            break;
            default:
                break;
        }
    }
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
    
    UTMCoordinates utmCoordinates = [GeodeticUTMConverter latitudeAndLongitudeToUTMCoordinates:CLLocationCoordinate2DMake(self.place.latitude.floatValue, self.place.longitude.floatValue)];
    
    NSString *coordinates = [NSString stringWithFormat:@"http://map.tehran.ir/?lat=%f&lon=%f&zoom=6",  utmCoordinates.northing, utmCoordinates.easting];

    NSMutableArray *activities = [NSMutableArray array];
    
    for (NSDictionary *dic in self.tableDatasource) {
        [activities addObject:dic.allValues.lastObject];
    }
    [activities addObject:[NSURL URLWithString:coordinates]];
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:activities applicationActivities:nil];
    avc.popoverPresentationController.barButtonItem = sender;
    
    [self presentViewController:avc animated:YES completion:NULL];
}

- (void)lovePlace: (UIBarButtonItem *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *favorites = [[userDefaults objectForKey:@"Favorites"] mutableCopy];

    if (favorites) {
        if ([favorites containsObject:self.place.uniqueID]) {
            [favorites removeObject:self.place.uniqueID];
            
            UIBarButtonItem *loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love"] landscapeImagePhone:[UIImage imageNamed:@"love_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
            
            self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], loveButton];
        } else {
            [favorites addObject:self.place.uniqueID];
            
            UIBarButtonItem *loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love_selected"] landscapeImagePhone:[UIImage imageNamed:@"love_selected_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
            
            self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], loveButton];
        }
    } else {
        favorites = [NSMutableArray array];
        [favorites addObject:self.place.uniqueID];
        
        UIBarButtonItem *loveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"love_selected"] landscapeImagePhone:[UIImage imageNamed:@"love_selected_landscape"] style:UIBarButtonItemStylePlain target:self action:@selector(lovePlace:)];
        
        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItems[0], loveButton];
    }
    
    [userDefaults setObject:[favorites copy] forKey:@"Favorites"];
    [userDefaults synchronize];
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

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)addToAddressBook:(Place *)place {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
        ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){

        [self showContactsAccessError];
        
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){

        [self savePlaceToAddressBook: place];
    } else { //ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined
        
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            if (!granted){

                [self showContactsAccessError];
                return;
            }

            [self savePlaceToAddressBook: place];
        });
        NSLog(@"Not determined Contacts Access");
    }
}

- (void)savePlaceToAddressBook:(Place *)place {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
        ABRecordRef contact = ABPersonCreate();
        
        ABRecordSetValue(contact, kABPersonOrganizationProperty, (__bridge CFStringRef)place.title, nil);
        ABRecordSetValue(contact, kABPersonDepartmentProperty, (__bridge CFStringRef)place.category.summary, nil);
        if (place.activities.length > 0) {
            ABRecordSetValue(contact, kABPersonNoteProperty, (__bridge CFStringRef)place.activities, nil);
        }
        if (place.email.length > 0) {
            ABRecordSetValue(contact, kABPersonEmailProperty, (__bridge CFStringRef)place.email, nil);
        }
        if (place.webSite.length > 0) {
            ABMutableMultiValueRef multiURL = ABMultiValueCreateMutable(kABPersonURLProperty);
            ABMultiValueAddValueAndLabel(multiURL, (__bridge CFStringRef)place.webSite, (CFStringRef)@"homepage", NULL);
            ABRecordSetValue(contact, kABPersonURLProperty, multiURL,nil);
            CFRelease(multiURL);
        }
        if (place.phones.length > 0) {
            NSMutableArray *phonesArray = [[place.phones componentsSeparatedByString:@"\n"] mutableCopy];
            NSArray *temp = phonesArray;
            for (int i = 0; i < temp.count; i++) {
                NSString *item = temp[i];
                if ([[item substringToIndex:1] isEqualToString:@"0"]) {
                    phonesArray[i] = [item stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"+98"];
                } else {
                    phonesArray[i] = [NSString stringWithFormat:@"+9821%@",item];
                }
            }
            
            ABMutableMultiValueRef phoneNumbers = ABMultiValueCreateMutable(kABMultiStringPropertyType);
            
            for (NSString *item in phonesArray) {
                
                if ([[item substringToIndex:5] isEqualToString:@"+9821"]) {
                    ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)item, kABPersonPhoneMainLabel, NULL);
                } else {
                    ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)item, kABPersonPhoneMobileLabel, NULL);
                }
                
            }
            
            
            if (place.faxes.length > 0) {
                NSMutableArray *faxesArray = [[place.faxes componentsSeparatedByString:@"\n"] mutableCopy];
                NSArray *temp = faxesArray;
                for (int i = 0; i < temp.count; i++) {
                    NSString *item = temp[i];
                    if ([[item substringToIndex:1] isEqualToString:@"0"]) {
                        faxesArray[i] = [item stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"+98"];
                    } else {
                        faxesArray[i] = [NSString stringWithFormat:@"+9821%@",item];
                    }
                }
                
                for (NSString *item in faxesArray) {
                    
                    if ([[item substringToIndex:5] isEqualToString:@"+9821"]) {
                        ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)item, kABPersonPhoneWorkFAXLabel, NULL);
                    } else {
                        ABMultiValueAddValueAndLabel(phoneNumbers, (__bridge CFStringRef)item, kABPersonPhoneMobileLabel, NULL);
                    }
                    
                }
            }
            
            ABRecordSetValue(contact, kABPersonPhoneProperty, phoneNumbers, nil);
        }
        
        if (self.place.logoLocalPath) {
            NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
            
            NSString *fileName = self.place.logoLocalPath;
            NSURL *finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];
            
            NSData *imageData = [NSData dataWithContentsOfFile: finalURL.path];
            
            ABPersonSetImageData(contact, (__bridge CFDataRef)imageData, nil);
        } else if (self.place.imageLocalPath) {
            NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
            
            NSString *fileName = self.place.imageLocalPath;
            NSURL *finalURL = [[NSURL fileURLWithPath:appSupportDir] URLByAppendingPathComponent:fileName];
            
            NSData *imageData = [NSData dataWithContentsOfFile:finalURL.path];
            ABPersonSetImageData(contact, (__bridge CFDataRef)imageData, nil);
        }
        
        
        NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
        for (id record in allContacts){
            ABRecordRef thisContact = (__bridge ABRecordRef)record;
            if (CFStringCompare(ABRecordCopyCompositeName(thisContact),
                                ABRecordCopyCompositeName(contact), 0) == kCFCompareEqualTo){
                
                NSMutableSet *thisContactPhoneNumbers = [[NSMutableSet alloc] init];
                ABMultiValueRef multiPhones = ABRecordCopyValue(thisContact, kABPersonPhoneProperty);
                
                for(CFIndex i=0; i<ABMultiValueGetCount(multiPhones); i++) {
                    @autoreleasepool {
                        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
                        NSString *phoneNumber = CFBridgingRelease(phoneNumberRef);
                        if (phoneNumber != nil)[thisContactPhoneNumbers addObject:phoneNumber];
                    }
                }
                
                if (multiPhones != NULL) {
                    CFRelease(multiPhones);
                }
                
                
                NSMutableSet *madeContactPhoneNumbers = [[NSMutableSet alloc] init];
                ABMultiValueRef madeMultiPhones = ABRecordCopyValue(contact, kABPersonPhoneProperty);
                
                for(CFIndex i=0; i<ABMultiValueGetCount(madeMultiPhones); i++) {
                    @autoreleasepool {
                        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(madeMultiPhones, i);
                        NSString *phoneNumber = CFBridgingRelease(phoneNumberRef);
                        if (phoneNumber != nil)[madeContactPhoneNumbers addObject:phoneNumber];
                    }
                }
                
                if (madeMultiPhones != NULL) {
                    CFRelease(madeMultiPhones);
                }
                
                if ([madeContactPhoneNumbers isEqualToSet:thisContactPhoneNumbers]) {
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"خطا" message:@"این مخاطب قبلاً اضافه شده است" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"متوجه شدم" style:UIAlertActionStyleCancel handler:NULL]];
                    [self presentViewController:alert animated:YES completion:NULL];
                    
                    return;
                }
            }
        }
        
        ABAddressBookAddRecord(addressBookRef, contact, nil);
        ABAddressBookSave(addressBookRef, nil);
    });
    
}

- (void)showContactsAccessError {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"خطای دسترسی به مخاطبین" message:@"اجازهٔ دسترسی به مخاطبین صادر نشده است. به تنظیمات مراجعه کنید" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"تنظیمات" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"بعداً" style:UIAlertActionStyleDefault handler:NULL]];

    [self presentViewController:alert animated:YES completion:NULL];
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

@end
