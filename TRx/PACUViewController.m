//
//  PACUViewController.m
//  TRx
//
//  Created by Mark Bellott on 3/9/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "PACUViewController.h"
#import "LocalTalk.h"
#import "AdminInformation.h"

@interface PACUViewController ()



@end

@implementation PACUViewController {
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    //get thumb 
    [super viewDidLoad];
    NSArray *tables = @[@"Patient"];
    NSDictionary *params = @{@"tableNames" : tables,
                             @"location" : @"PACUViewController"};
    NSMutableArray *retval;
    NSMutableDictionary *data = [LocalTalk getData:params];
    for(NSString *key in data){
        if([key isEqualToString:@"Patient"]){
            retval = [data objectForKey:key];
        }
    }
    NSDictionary *dict = retval[0];
    NSString *name = [dict objectForKey:@"FirstName"];
    NSString *lname = [dict objectForKey:@"LastName"];
    name = [name stringByAppendingString:@" "];
    name = [name stringByAppendingString:lname];
    patientName.text = name;
    patientSurgery.text = @"Cataracts";
    [_ordersTextViewBr addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)]];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(outsideTapped)]];
/*
	
    patientSurgery
    patientThumbnail */
    [self playVideo];
}
- (void) playVideo
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(movieFinishedCallback:) name:@"movieDone" object:nil];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MyMovie" ofType:@"mov"]];
    mplayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    mplayer.view.frame = self.view.bounds;
    [self.view addSubview:mplayer.view];
    mplayer.controlStyle = MPMovieControlStyleEmbedded;
    [mplayer.view setFrame:CGRectMake(175, 80, (self.view.frame.size.width)-200 , 375)];
    mplayer.scalingMode = MPMovieScalingModeAspectFit;
    mplayer.shouldAutoplay = NO;
    [mplayer prepareToPlay];
    
}
- (void) textViewTapped:(UIGestureRecognizer *)recognizer {
    _ordersTextViewBr.editable = YES;
    [_ordersTextViewBr becomeFirstResponder];
}

- (void) outsideTapped {
           _ordersTextViewBr.editable = NO;
        [_ordersTextViewBr resignFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
