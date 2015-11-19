//
//  ReportVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/11/19.
//  Copyright © 2015 Saeed Taheri. All rights reserved.
//

#import "ReportVC.h"
#import "DeviceInfo.h"
#import "UIFontDescriptor+IranSans.h"
#import "MBProgressHUD.h"

@interface ReportVC ()
@property (weak, nonatomic) IBOutlet UILabel *subject;
@property (weak, nonatomic) IBOutlet UILabel *locationName;
@property (weak, nonatomic) IBOutlet UILabel *locationID;
@property (weak, nonatomic) IBOutlet UILabel *device;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@property (weak, nonatomic) IBOutlet UILabel *subjectHeader;
@property (weak, nonatomic) IBOutlet UILabel *locationHeader;
@property (weak, nonatomic) IBOutlet UILabel *deviceHeader;
@property (weak, nonatomic) IBOutlet UILabel *textHeader;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locationBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locationTopConstraint;

@end

@implementation ReportVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"ارتباط";
    
    self.textView.layer.cornerRadius = 10.0;
    self.textView.clipsToBounds = YES;
    self.textView.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    
    self.subjectHeader.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    self.locationHeader.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    self.deviceHeader.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    self.textView.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    
    self.subject.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    self.locationName.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansFontDescriptorWithTextStyle: UIFontTextStyleBody] size: 0];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"ارسال" style:UIBarButtonItemStyleDone target:self action:@selector(submit:)];
    
    if ([self.reportType isEqualToString:@"General"]) {
        self.subject.text = @"ارتباط با ما";
        self.locationName.text = @"";
        self.locationID.text = @"";
        self.device.text = [NSString stringWithFormat:@"%@ - iOS %@",[DeviceInfo model], [UIDevice currentDevice].systemVersion];
        self.textView.text = @"";
        
        self.locationBottomConstraint.constant = 0;
        self.locationTopConstraint.constant = 0;
        
        self.locationHeader.text = @"";
    } else if ([self.reportType isEqualToString:@"Error"]) {
        self.subject.text = @"گزارش خطا";
        self.locationName.text = self.placeName;
        self.locationID.text = self.placeID;
        self.locationID.hidden = YES;
        self.device.text = @"";
        self.textView.text = @"";
        self.deviceHeader.text = @"";
        self.locationBottomConstraint.constant = 0;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardDidShow:(NSNotification *)note {
    
    NSDictionary *info = [note userInfo];
    CGFloat kbHeight = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    self.bottomConstraint.constant = kbHeight + 8.0;

    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];

}

- (void)keyboardWillHide:(NSNotification *)note {
    self.bottomConstraint.constant = 16.0;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)submit:(UIBarButtonItem *)sender {
    
    NSString* const baseURL = @"http://31.24.237.18:2243/api/";
    NSString* const setCommentMethod = @"SetComment";
    NSString* const APIKey = @"3234D74E-661E";
    
    if (self.textView.text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"توجه" message:@"پیام ارسالی خالی است" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"متوجه شدم" style:UIAlertActionStyleCancel handler:NULL]];
        [self presentViewController:alert animated:YES completion:NULL];
        
        return;
    }
    
    NSDictionary *methodArguments = @{
                                      @"ApiKey" : APIKey,
                                      @"Subject" : self.subject.text,
                                      @"Name": [self.locationName.text isEqualToString:@""] ? @"0" : self.locationName.text,
                                      @"LocationId": [self.locationID.text isEqualToString:@""] ? @"0" : self.locationID.text,
                                      @"Device": [self.device.text isEqualToString:@""] ? @"0" : [DeviceInfo model],
                                      @"Version": [self.device.text isEqualToString:@""] ? @"0" : [UIDevice currentDevice].systemVersion,
                                      @"Details": self.textView.text
                                      };
    
    NSString *stringURL = [NSString stringWithFormat:@"%@%@%@", baseURL, setCommentMethod, [self escapedParameters:methodArguments]];
    NSURL *url = [NSURL URLWithString:stringURL];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"در حال ارسال";
    hud.labelFont = [UIFont fontWithDescriptor:[UIFontDescriptor preferredIranSansBoldFontDescriptorWithTextStyle: UIFontTextStyleCaption1] size: 0];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error == nil) {
            id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
            if ([object isKindOfClass:[NSNumber class]]) {
                if ([(NSNumber *)object integerValue] == 0 || [(NSNumber *)object integerValue] == -1) {
                    NSLog(@"Error Submiting");
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"خطا" message:@"ارتباط با سرور برقرار نشد. لطفاً مجدداً سعی کنید" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"متوجه شدم" style:UIAlertActionStyleCancel handler:NULL]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                        [self presentViewController:alert animated:YES completion:NULL];
                    });

                } else {
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"متشکریم" message:@"پیام شما دریافت شد" preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"متوجه شدم" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self.navigationController popToRootViewControllerAnimated:YES];
                    }]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                        [self presentViewController:alert animated:YES completion:NULL];
                    });
                }
            }
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"خطا" message:@"ارتباط با سرور برقرار نشد. لطفاً مجدداً سعی کنید" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"متوجه شدم" style:UIAlertActionStyleCancel handler:NULL]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
                [self presentViewController:alert animated:YES completion:NULL];
            });
        }
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    
    [task resume];
}

- (IBAction)dismissKeyboard:(UISwipeGestureRecognizer *)sender {
    [self.textView resignFirstResponder];
}

- (NSString *)escapedParameters: (NSDictionary *)parameters {
    NSMutableArray *urlVars = [NSMutableArray array];
    
    for (NSString *key in parameters) {
        
        /* Make sure that it is a string value */
        NSString *stringValue = [NSString stringWithFormat:@"%@",parameters[key]];
        
        /* Escape it */
        NSString *escapedValue = [stringValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        /* Append it */
        [urlVars addObject:[NSString stringWithFormat:@"%@=%@",key,escapedValue]];
    }
    
    return [NSString stringWithFormat:@"%@%@",(urlVars.count > 0 ? @"?" : @""), [urlVars componentsJoinedByString:@"&"]];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
