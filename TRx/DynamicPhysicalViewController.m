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
#define MAIN_X 250.0f

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
    
    if(pageCount != 1){
        [mainQuestion checkHasAnswer];
        
        if(!mainQuestion.hasAnswer && mainQuestion.type != SELECTION_QUESTION){
            UIAlertView *provideAnswer = [[UIAlertView alloc] initWithTitle:@"Wait!" message:@"Please provide an answer before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [provideAnswer show];
            return;
        }
        
        [previousPages addObject:mainQuestion];
        [self findAnswers];
        [qHelper updateCurrentIndexWithResponse:answers QuestionType:mainQuestion.type];
    }
    
    PQView *newMainQuestion = [[PQView alloc] init];
    
    if(pageCount != 1){
        [self dismissCurrentQuestion];
    }
    
    newMainQuestion.type = [qHelper getNextType];
    [newMainQuestion setQuestionLabelText:[qHelper getNextEnglishLabel]];
    
    [newMainQuestion buildQuestionOfType:newMainQuestion.type withHelper:qHelper];
    [self setPositionForMainQuestion:newMainQuestion];
    
    if([[qHelper getQuestionId] isEqualToString:@"preOp_Done"]){
        nextButton.enabled = NO;
        [nextButton setHidden:YES];
    }
    
    if(newMainQuestion.type == TEXT_ENTRY){
        newMainQuestion.textEntryField.delegate = self;
    }
    else if (newMainQuestion.type == SELECTION_QUESTION){
        newMainQuestion.otherTextField.delegate = self;
    }
    
    [newMainQuestion restorePreviousAnswers];
    
    mainQuestion = newMainQuestion;
    
    [self.view addSubview:mainQuestion];
    
    [answers removeAllObjects];
}

-(void) loadPreviousQuestion{
    if(pageCount == 1){
        return;
    }
    
    [self dismissCurrentQuestion];
    
    mainQuestion = [previousPages lastObject];
    [previousPages removeLastObject];
    [self.view addSubview:mainQuestion];
    
    qHelper.currentIndex = mainQuestion.questionIndex;
}

-(void) dismissCurrentQuestion{
    [mainQuestion removeFromSuperview];
}

-(void) setPositionForMainQuestion:(PQView *)q{
    float yPos = MID_Y - (q.frame.size.height/2);
    q.frame = CGRectMake(MAIN_X, yPos, q.frame.size.width, q.frame.size.height);
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(mainQuestion.type == TEXT_ENTRY){
        [mainQuestion.textEntryField resignFirstResponder];
    }
    else if(mainQuestion.type == SELECTION_QUESTION){
        [mainQuestion.otherTextField resignFirstResponder];
    }
}

-(void) textFieldDidBeginEditing:(UITextField *)textField{
    float textYPos = 250, moveDist = 0.0, mPos, tPos;
    
    mPos = mainQuestion.frame.origin.y + mainQuestion.frame.size.height;
    
    oMainViewPos = mainQuestion.frame.origin.y;
    
    if(mPos > 350){
        moveDist = textYPos - mainQuestion.frame.origin.y;
        mainQuestion.frame = CGRectMake(mainQuestion.frame.origin.x, mainQuestion.frame.origin.y - moveDist,
                                        mainQuestion.frame.size.width, mainQuestion.frame.size.height);
    }
}

-(void) textFieldDidEndEditing:(UITextField *)textField{
    
    mainQuestion.frame = CGRectMake(mainQuestion.frame.origin.x, oMainViewPos,
                                    mainQuestion.frame.size.width, mainQuestion.frame.size.height);
    
}

-(void) findAnswers{
    [answers removeAllObjects];
    
    if(mainQuestion.type == TEXT_ENTRY){
        [answers addObject:@"YES"];
        [answers addObject:mainQuestion.textEntryField.text];
    }
    
    else if (mainQuestion.type == YES_NO){
        if(mainQuestion.yesButton.selected){
            [answers addObject:@"YES"];
        }
        else{
            [answers addObject:@"NO"];
        }
    }
    
    else if (mainQuestion.type == SELECTION_QUESTION){
        NSInteger counter = 0;;
        NSMutableArray *holder = [[NSMutableArray alloc] init];
        
        for(PQCheckBox *cb in mainQuestion.checkBoxes){
            if(cb.selected){
                [holder addObject:cb.optionLabel];
                counter++;
            }
        }
        
        if((counter == 0) && (mainQuestion.otherTextField.text.length == 0)){
            [answers addObject:@"NO"];
        }
        else{
            [answers addObject:@"YES"];
            
            for(NSString *s in holder){
                [answers addObject:s];
            }
            if(mainQuestion.otherTextField.text.length > 0){
                [answers addObject:mainQuestion.otherTextField.text];
            }
        }
    }
    
    answerString = [answers componentsJoinedByString:@", "];
    mainQuestion.answerString = answerString;
    [Question storeQuestionAnswer:answerString questionId:[qHelper getQuestionId]];
}

@end