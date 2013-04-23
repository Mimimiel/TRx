//
//  DynamicPhysicalViewController.h
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PQHelper.h"
#import "PQView.h"

@interface DynamicPhysicalViewController : UIViewController{
    
    NSInteger pageCount;
    float availableSpace;
    
    PQHelper *qHelper;
    PQView *mainQuestion;
    
    NSMutableArray *previousPages;
    NSMutableArray *answers;
    
    IBOutlet UIButton *nextButton, *backButtonl;
}

-(IBAction)backPressed:(id)sender;
-(IBAction)nextPressed:(id)sender;

@end
