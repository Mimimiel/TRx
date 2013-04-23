//
//  HQView.h
//  TRx
//
//  Created by Mark Bellott on 4/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HQCheckBox.h"
#import "HQHelper.h"
#import "HQLabel.h"
#import "HQSelector.h"
#import "HQTextField.h"
#import "HQYesNo.h"
#import "HQHelper.h"

typedef enum{
    YES_NO,
    SELECTION_QUESTION,
    SELECTION_CHOICES,
    TEXT_ENTRY,
    TEXT_SELECTION
}qType;

@interface HQView : UIView <UITextFieldDelegate>{
    
    BOOL hasAnswer, isEnglish, shouldBranch;
    
    NSInteger questionIndex;
    
    float totalHeight;
    float responseHeight;
    
    NSString *previousTextEntry;
    NSString *answerString;
    
    
    qType type;
    HQLabel *questionLabel;
    HQSelector *yesNoSelector;
    HQYesNo *yesButton;
    HQYesNo *noButton;
    HQTextField *textEntryField;
    HQTextField *otherTextField;
    
    NSMutableArray *response;
    NSMutableArray *checkBoxes;
    NSMutableArray *questionUnion;
    
    HQView *connectedView;
}

@property(nonatomic, readwrite) NSInteger questionIndex;
@property(nonatomic, readwrite) BOOL hasAnswer;
@property(nonatomic, readwrite) BOOL isEnglish;
@property(nonatomic, readwrite) BOOL shouldBranch;
@property(nonatomic, readwrite) qType type;
@property(nonatomic, readwrite) HQLabel* questionLabel;
@property(nonatomic, retain) HQTextField *textEntryField;
@property(nonatomic, retain) HQTextField *otherTextField;
@property(nonatomic, retain) HQSelector *yesNoSelector;
@property(nonatomic, retain) HQYesNo *yesButton;
@property(nonatomic, retain) HQYesNo *noButton;
@property(nonatomic, retain) NSString *previousTextEntry;
@property(nonatomic, retain) NSString *answerString;
@property(nonatomic, retain) NSMutableArray *checkBoxes;
@property(nonatomic, retain) HQView *connectedView;

-(void) checkHasAnswer;
-(void) setQuestionLabelText:(NSString *)text;
-(void) buildQuestionOfType:(NSInteger)t withHelper:(HQHelper*)h;
-(void) buildYesNo;
-(void) buildSingleSelection;
-(void) buildSelectionWithChoices:(NSArray*)choices;
-(void) buildTextEntry;
-(void) restorePreviousAnswers;
-(void) adjustFrame;

@end