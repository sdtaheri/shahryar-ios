//
//  MorePlacesTVC.m
//  ShahrYar
//
//  Created by Saeed Taheri on 2015/8/19.
//  Copyright (c) 2015 Saeed Taheri. All rights reserved.
//

#import "PlacesListTVC.h"
#import "DetailTVC.h"
#import "Mapbox.h"

@interface PlacesListTVC ()

@property (nonatomic, strong) NSArray *places;
@property (nonatomic, strong) NSArray *sortedByDistancePlacesDictionary;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@property (nonatomic, strong) NSArray *sectionKeys;
@property (nonatomic, strong) NSDictionary *alphabetizedPlaceTitles;

@end

@implementation PlacesListTVC

typedef NS_ENUM(NSInteger, SortType) {
    SortTypeAlphabet = 0,
    SortTypeCategories = 1,
    SortTypeDistance = 2
};


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"فهرست";
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"fa_IR"];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.tableView.estimatedRowHeight = 44.f;
    self.navigationController.view.layer.masksToBounds = YES;
    
    [self initializeData];
}

- (void)initializeData {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.annotations.count];
    for (RMAnnotation *annotation in self.annotations) {
        [temp addObject: annotation.userInfo];
    }
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
    self.places = [temp sortedArrayUsingDescriptors:@[descriptor]];
    
    if (self.userLocation) {
        temp = [NSMutableArray arrayWithCapacity:self.places.count];
        for (Place *place in self.places) {
            [temp addObject:@{@"Place": place, @"Distance": @([self.userLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:place.latitude.doubleValue longitude:place.longitude.doubleValue]]) }];
        }
        descriptor = [NSSortDescriptor sortDescriptorWithKey:@"Distance" ascending:YES];
        self.sortedByDistancePlacesDictionary = [temp sortedArrayUsingDescriptors:@[descriptor]];
    } else {
        [self.segmentedControl removeSegmentAtIndex:SortTypeDistance animated:YES];
    }
    
    NSMutableArray *letters = [NSMutableArray array];
    NSMutableDictionary *sectionedWords = [NSMutableDictionary dictionary];
    NSArray *strings = [self.places valueForKey:@"title"];
    NSString *currentLetter = nil;
    NSArray *sectionTitles = @[@"الف", @"ب", @"پ", @"ت", @"ث", @"ج", @"چ", @"ح", @"خ", @"د", @"ذ", @"ر", @"ز", @"ژ", @"س", @"ش", @"ص", @"ض", @"ط", @"ظ", @"ع", @"غ", @"ف", @"ق", @"ک", @"گ", @"ل", @"م", @"ن", @"و", @"ه", @"ی"];
    for (NSString *string in strings) {
        if (string.length > 0) {
            NSString *letter = [string substringToIndex:1];
            if ([letter isEqualToString:@"ا"] || [letter isEqualToString:@"آ"] || [letter isEqualToString:@"أ"] || [letter isEqualToString:@"إ"]) {
                letter = @"الف";
            } else if ([letter isEqualToString:@"ک"] || [letter isEqualToString:@"ك"]) {
                letter = @"ک";
            } else if ([letter isEqualToString:@"و"] || [letter isEqualToString:@"ؤ"]) {
                letter = @"و";
            } else if ([sectionTitles containsObject:letter]) {
                letter = letter;
            } else {
                letter = @"#";
            }
            if (![letter isEqualToString:currentLetter]) {
                [letters addObject:letter];
                currentLetter = letter;
            }
            
            if ([sectionedWords objectForKey:letter]) {
                [[sectionedWords objectForKey:letter] addObject:string];
            } else {
                [sectionedWords setObject:[NSMutableArray array] forKey:letter];
                [[sectionedWords objectForKey:letter] addObject:string];
            }
        }
    }
    self.sectionKeys = [NSArray arrayWithArray:letters];
    self.alphabetizedPlaceTitles = sectionedWords;
    
}

- (IBAction)segmentValueChanged:(UISegmentedControl *)sender {
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys.count;
            break;
        case SortTypeCategories: {
            return [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.uniqueID"] count];
            break;
        }
        case SortTypeDistance:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet: {
            NSArray *temp = [self.alphabetizedPlaceTitles objectForKey:self.sectionKeys[section]];
            if (temp) {
                return temp.count;
            } else {
                return 0;
            }
            break;
        }
        case SortTypeCategories: {
            
            NSArray *sortedCategoryTitles = [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.summary"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            
            for (int i = 0; i < sortedCategoryTitles.count; i++) {
                if (i == section) {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.summary = %@", sortedCategoryTitles[i]];
                    return [self.places filteredArrayUsingPredicate:predicate].count;
                }
            }
            break;
        }
        case SortTypeDistance:
            return self.annotations.count;
            break;
        default:
            return 0;
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Place Cell"];
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            cell.textLabel.text = [self.alphabetizedPlaceTitles objectForKey:self.sectionKeys[indexPath.section]][indexPath.row];
            break;
        case SortTypeCategories: {
            NSArray *sortedCategoryTitles = [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.summary"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.summary = %@", sortedCategoryTitles[indexPath.section]];
            NSArray *resultsArray = [self.places filteredArrayUsingPredicate:predicate];
            resultsArray = [resultsArray valueForKeyPath:@"title"];
            
            cell.textLabel.text = [resultsArray sortedArrayUsingSelector:@selector(localizedStandardCompare:)][indexPath.row];
            break;
        }
        case SortTypeDistance: {
            NSString *title = [[self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Place"] title];
            NSString *subtitle = [self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Distance"];
            if (subtitle.doubleValue >= 1000) {
                self.numberFormatter.maximumFractionDigits = 1;
                subtitle = [NSString stringWithFormat:@"%@ کیلومتر", [self.numberFormatter stringFromNumber:@([subtitle doubleValue] / 1000.0)]];
            } else {
                self.numberFormatter.maximumFractionDigits = 0;
                subtitle = [NSString stringWithFormat:@"%@ متر", [self.numberFormatter stringFromNumber:@([subtitle doubleValue])]];
            }
            
            NSDictionary *attrs = @{
                                    NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:14.0],
                                    NSForegroundColorAttributeName:[UIColor blackColor]
                                    };
            NSDictionary *subAttrs = @{
                                       NSFontAttributeName:[UIFont fontWithName:@"IRANSans-Light" size:13.0],
                                       NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                       };
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, subtitle] attributes:attrs];
            
            NSRange range = NSMakeRange(title.length + 1, subtitle.length);
            [attrStr setAttributes:subAttrs range:range];
            
            cell.textLabel.attributedText = attrStr;
            break;
        }
            
        default:
            cell.textLabel.text = @"Error";
            break;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    cell.backgroundColor = [UIColor clearColor];
    cell.backgroundView = nil;

    // Remove seperator inset
    [cell setSeparatorInset:UIEdgeInsetsMake(0, 0, 0, 15)];
    
    // Prevent the cell from inheriting the Table View's margin settings
    [cell setPreservesSuperviewLayoutMargins:NO];
    
    // Explictly set your cell's layout margins
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
    headerView.textLabel.font = [UIFont fontWithName:@"IRANSans-Medium" size:14];
    headerView.textLabel.textAlignment = NSTextAlignmentRight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys;
            break;
        default:
            return nil;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case SortTypeAlphabet:
            return self.sectionKeys[section];
            break;
        case SortTypeCategories: {
            
            NSArray *sortedCategoryTitles = [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.summary"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
            
            return sortedCategoryTitles[MIN(section, sortedCategoryTitles.count - 1)];
            break;
        }
        case SortTypeDistance:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Detail From List"]) {
        DetailTVC *dtvc = segue.destinationViewController;
        dtvc.navigationItem.leftBarButtonItem = nil;
        dtvc.navigationItem.leftItemsSupplementBackButton = YES;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender];
        switch (self.segmentedControl.selectedSegmentIndex) {
            
            case SortTypeAlphabet: {
                NSInteger rowNumber = 0;
                for (NSInteger i = 0; i < indexPath.section; i++) {
                    rowNumber += [self.tableView numberOfRowsInSection:i];
                }
                rowNumber += indexPath.row;
                dtvc.place = self.places[rowNumber];
                break;
            }
            
            case SortTypeCategories: {
                NSArray *sortedCategoryTitles = [[self.places valueForKeyPath:@"@distinctUnionOfObjects.category.summary"] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category.summary = %@", sortedCategoryTitles[indexPath.section]];
                NSArray *resultsArray = [self.places filteredArrayUsingPredicate:predicate];
                
                NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)];
                resultsArray = [resultsArray sortedArrayUsingDescriptors:@[descriptor]];
                
                dtvc.place = resultsArray[indexPath.row];

                break;
            }
                
            case SortTypeDistance: {
                dtvc.place = [self.sortedByDistancePlacesDictionary[indexPath.row] objectForKey:@"Place"];
                break;
            }
            default:
                break;
        }
    }
}

- (IBAction)dismiss:(UIBarButtonItem *)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
