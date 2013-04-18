//
//  SummaryViewController.m
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "SummaryViewController.h"
#import "LocalTalk.h"
@interface SummaryViewController ()

@end

@implementation SummaryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    [_patientPicture setImage:[LocalTalk localGetPortrait]];
    
}

-(void)updatedDataListener:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    if([[params objectForKey:@"location"] isEqualToString:@"summaryViewController"]){
        NSMutableDictionary *data = [LocalTalk getData:params];
        NSLog(@"The updated data listener's data in Summary VC is: %@", data);
    } else { NSLog(@"not in the right view controller");}
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
