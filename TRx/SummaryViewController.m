//
//  SummaryViewController.m
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "SummaryViewController.h"
#import "LocalTalk.h"
#import "DBTalk.h"

@interface SummaryViewController ()

@end

@implementation SummaryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
   
}

- (void)viewDidAppear:(BOOL)animated {
    /*listeners for history view controller*/
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(updatedDataListener:) name:@"loadFromLocal" object:nil];
    
    NSArray *tables = @[@"Patient"];
    NSDictionary *params = @{@"tableNames" : tables,
                             @"location" : @"summaryViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabloaded" object:self userInfo:params];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //FIXME This is crashing the app as no picture was loaded into LocalTalk
//    UIImage *image = [LocalTalk localGetPortrait];
//    if (image) {
//        [_patientPicture setImage:[LocalTalk localGetPortrait]];
//    }
    
    //TODO: MISCHAPICTURE
    NSURL *pictureURL = [NSURL fileURLWithPath:@"MISCHAPICTURE"];
    //NSURL *pictureURL = [DBTalk getProfileThumbURLFromServerForPatient:[LocalTalk localGetPatientId] andRecord:[LocalTalk localGetPatientRecordId]];
    NSData *imageData = [NSData dataWithContentsOfURL:pictureURL];
    UIImage *image = [UIImage imageWithData:imageData];
    if(image) {
        [_patientPicture setImage:image];
    }
    
    NSArray *tables = @[@"Patient"];
    NSDictionary *params = @{@"tableNames" : tables,@"location" : @"PACUViewController"};
    NSMutableArray *retval;
    NSMutableDictionary *data = [LocalTalk getData:params];
    for(NSString *key in data){
        if([key isEqualToString:@"Patient"]){
            retval = [data objectForKey:key];
        }
    }
    
    NSDictionary *dict = retval[0];
    
    NSString *name;
    NSString *lname;
    name = @"Name: ";
    name = [name stringByAppendingString:[dict objectForKey:@"FirstName"]];
    lname = [dict objectForKey:@"LastName"];
    name = [name stringByAppendingString:@" "];
    name = [name stringByAppendingString:lname];
    _pName.text = name;
    
    NSString *birthday;
    birthday = @"Birthday: ";
    birthday = [birthday stringByAppendingString:[dict objectForKey:@"Birthday"]];
    _pBirthday.text = birthday;
    
    NSString *surgery;
    surgery = @"Surgery: Cataracts";
    //surgery = [surgery stringByAppendingString:[dict objectForKey:@"Surgery"]];
    _pSurgery.text = surgery;
}

-(void)updatedDataListener:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    if([[params objectForKey:@"location"] isEqualToString:@"summaryViewController"]){
        NSMutableDictionary *data = [LocalTalk getData:params];
        NSLog(@"The updated data listener's data in Summary VC is: %@", data);
    } else { NSLog(@"not in the right view controller"); }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
