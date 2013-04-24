//
//  PQView.h
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PQCheckBox.h"
#import "PQLabel.h"
#import "PQTextField.h"
#import "PQYesNo.h"
#import "PQHelper.h"

typedef enum{
    YES_NO,
    SELECTION_QUESTION,
    SELECTION_CHOICES,
    TEXT_ENTRY,
    TEXT_SELECTION
}qType;

@interface PQView : UIView<UITextFieldDelegate>{
    
    BOOL hasAnswer, shouldBranch;
    
    NSInteger questionIndex;
    
    float totalHeight;
    float responseHeight;
    
    NSString *questionId;
    NSString *previousTextEntry;
    NSString *answerString;
    
    
    qType type;
    PQLabel *questionLabel;
    PQYesNo *yesButton;
    PQYesNo *noButton;
    PQTextField *textEntryField;
    PQTextField *otherTextField;
    
    NSMutableArray *response;
    NSMutableArray *checkBoxes;
    NSMutableArray *questionUnion;
}

@property(nonatomic, readwrite) NSInteger questionIndex;
@property(nonatomic, readwrite) BOOL hasAnswer;
@property(nonatomic, readwrite) BOOL shouldBranch;
@property(nonatomic, readwrite) qType type;
@property(nonatomic, readwrite) PQLabel* questionLabel;
@property(nonatomic, retain) PQTextField *textEntryField;
@property(nonatomic, retain) PQTextField *otherTextField;
@property(nonatomic, retain) PQYesNo *yesButton;
@property(nonatomic, retain) PQYesNo *noButton;
@property(nonatomic, retain) NSString *previousTextEntry;
@property(nonatomic, retain) NSString *answerString;
@property(nonatomic, retain) NSMutableArray *checkBoxes;

-(void) checkHasAnswer;
-(void) setQuestionLabelText:(NSString *)text;
-(void) buildQuestionOfType:(NSInteger)t withHelper:(PQHelper*)h;
-(void) buildYesNo;
-(void) buildSingleSelection;
-(void) buildSelectionWithChoices:(NSArray*)choices;
-(void) buildTextEntry;
-(void) restorePreviousAnswers;
-(void) adjustFrame;

@end
