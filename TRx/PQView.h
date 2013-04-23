//
//  PQView.h
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PQLabel.h"
#import "PQTextField.h"
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
@property(nonatomic, retain) NSString *previousTextEntry;
@property(nonatomic, retain) NSString *answerString;
@property(nonatomic, retain) NSMutableArray *checkBoxes;

@end
