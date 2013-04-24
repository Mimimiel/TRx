//
//  DynamicPhysicalViewController.h
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Question.h"
#import "PQHelper.h"
#import "PQView.h"

@interface DynamicPhysicalViewController : UIViewController<UITextFieldDelegate>{
    
    float availableSpace, oMainViewPos, oTransViewPos;
    NSInteger pageCount;
    NSString *mainQuestionText;
    
    PQHelper *qHelper;
    
    PQView *mainQuestion;
    
    //Arrays of Questions for main storage
    NSMutableArray *currentPage;
    NSMutableArray *previousPages;
    NSMutableArray *answers;
    
    NSString *answerString;
    
    IBOutlet UIButton *backButton, *nextButton;
}

//IBActions
-(IBAction)backPressed:(id)sender;
-(IBAction)nextPressed:(id)sender;

@end
