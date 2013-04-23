//
//  DynamicPhysicalViewController.m
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#define MAX_Y 50.0f
#define MID_Y 275.0f
#define MIN_Y 500.0f
#define MAIN_X 500.0f

#import "DynamicPhysicalViewController.h"

@interface DynamicPhysicalViewController ()

@end

@implementation DynamicPhysicalViewController

-(IBAction)backPressed:(id)sender{
    if(pageCount == 1){
        [self.navigationController popViewControllerAnimated:YES];
    }
    else{
        [self loadPreviousQuestion];
        pageCount--;
    }
}

-(IBAction)nextPressed:(id)sender{
    pageCount++;
    [self loadNextQuestion];
}

#pragma mark - Init Methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self initialSetup];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) initialSetup{
    pageCount = 1;
    availableSpace = MAX_Y - MIN_Y;
    
    mainQuestion = [[PQView alloc] init];
    
    previousPages = [[NSMutableArray alloc] init];
    answers = [[NSMutableArray alloc] init];
    
    qHelper = [[PQHelper alloc] init];
    
    [self loadNextQuestion];
}

#pragma mark - Question Handling Methods

-(void) loadNextQuestion{
    
    PQView *newMainQuestion = [[PQView alloc] init];
    
    if(pageCount != 1){
        [self dismissCurrentQuestion];
    }
}

-(void) loadPreviousQuestion{
    
}

-(void) dismissCurrentQuestion{
    [mainQuestion removeFromSuperview];
}






















@end
