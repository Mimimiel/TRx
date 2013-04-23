//
//  HQView.m
//  TRx
//
//  Created by Mark Bellott on 4/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "HQView.h"

#define FONT_SIZE 20

#define Y_PADDING 20.0f
#define YES_PADDING 25.0f
#define NO_PADDING 250.0f

#define MAX_Y 50.0f
#define MID_Y 256.f
#define MIN_Y 500.0f
#define ENG_X 50.0f
#define TRANS_X 550.0f
#define SELECT_OFFSET 50.0f

#define CONST_WIDTH 425.0f
#define SELECT_WIDTH 375.0f

@implementation HQView

@synthesize questionIndex, hasAnswer, isEnglish, shouldBranch, questionLabel, type, textEntryField, otherTextField, yesNoSelector, yesButton, noButton, previousTextEntry, answerString, checkBoxes, connectedView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.frame = CGRectMake(0, 0, CONST_WIDTH, 100);
        
        questionIndex = -1;
        
        hasAnswer = NO;
        isEnglish = YES;
        shouldBranch = NO;
        
        totalHeight = 0;
        responseHeight = 0;
        
        response = [[NSMutableArray alloc]init];
        checkBoxes = [[NSMutableArray alloc]init];
        questionUnion = [[NSMutableArray alloc]init];
        
        questionLabel = [[HQLabel alloc] init];
        [questionLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:FONT_SIZE]];
        [questionLabel setTextColor:[UIColor blackColor]];
        [questionUnion addObject:questionLabel];
        [self addSubview:questionLabel];
        
        
    }
    return self;
}

-(void) setQuestionLabelText:(NSString *)text{
    questionLabel.text = text;
}

-(void) buildQuestionOfType:(NSInteger)t withHelper:(HQHelper*)h{
    questionIndex = h.currentIndex;
    
    if(t==0){
        type = YES_NO;
        [self buildYesNo];
    }
    else if(t==1){
        type = SELECTION_QUESTION;
        if(isEnglish){
            [self buildSelectionWithChoices:[h getEnglishChoices]];
        }
        else{
            [self buildSelectionWithChoices:[h getTransChoices]];
        }
    }
    else if(t==2){
        type = SELECTION_CHOICES;
    }
    else if(t==3){
        type = TEXT_ENTRY;
        [self buildTextEntry];
    }
    else if(t==4){
        type = TEXT_SELECTION;
        [self buildTextSelection];
    }
    else{
        NSLog(@"Error: Invalid Question Type Encountered.");
    }
    
    questionId = [h getQuestionId];
    //[self restorePreviousAnswers];
}

-(void) checkHasAnswer{
    if(type == TEXT_ENTRY){
        if(textEntryField.text.length > 0){
            hasAnswer = YES;
        }
        else{
            hasAnswer = NO;
        }
    }
    else if(type == YES_NO){
        if(yesButton.selected || noButton.selected){
            hasAnswer = YES;
        }
        else{
            hasAnswer = NO;
        }
    }
    else if(type == SELECTION_QUESTION){
        BOOL checked = NO;
        for(HQCheckBox *cb in checkBoxes){
            if(cb.selected){
                checked = YES;
            }
        }
        if(checked){
            hasAnswer = YES;
        }
        else if(otherTextField.text.length > 0){
            hasAnswer = YES;
        }
        else{
            hasAnswer = YES;
        }
    }
}

#pragma mark - Yes No Methods

-(void) buildYesNo{
    
    yesButton = [[HQYesNo alloc]initWithFrame:CGRectMake(questionLabel.frame.origin.x + YES_PADDING, questionLabel.frame.origin.y + Y_PADDING + questionLabel.frame.size.height, 125, 75)];
    noButton = [[HQYesNo alloc]initWithFrame:CGRectMake(questionLabel.frame.origin.x + NO_PADDING, questionLabel.frame.origin.y + Y_PADDING + questionLabel.frame.size.height, 125, 75)];
    if(isEnglish)   [yesButton setTitle:@"Yes" forState:UIControlStateNormal];
    else            [yesButton setTitle:@"Si" forState:UIControlStateNormal];
    [noButton setTitle:@"No" forState:UIControlStateNormal];
    [yesButton addTarget:self action:@selector(yesPressed) forControlEvents:UIControlEventTouchDown];
    [noButton addTarget:self action:@selector(noPressed) forControlEvents:UIControlEventTouchDown];
    
    responseHeight = yesButton.frame.size.height;
    [response addObject:noButton];
    [response addObject:yesButton];
    
    [self addSubview:yesButton];
    [self addSubview:noButton];
    [self adjustFrame];
}

-(void) yesPressed{
    
    if(!yesButton.selected){
        
        [noButton setSelected:NO];
        [noButton setBackgroundColor:[UIColor whiteColor]];
        [yesButton setSelected:YES];
        [yesButton setBackgroundColor:[UIColor grayColor]];
        
        [connectedView.noButton setSelected:NO];
        [connectedView.noButton setBackgroundColor:[UIColor whiteColor]];
        [connectedView.yesButton setSelected:YES];
        [connectedView.yesButton setBackgroundColor:[UIColor grayColor]];
        
    }
    
}

-(void) noPressed{
    
    if(!noButton.selected){
        
        [yesButton setSelected:NO];
        [yesButton setBackgroundColor:[UIColor whiteColor]];
        [noButton setSelected:YES];
        [noButton setBackgroundColor:[UIColor grayColor]];
        
        [connectedView.yesButton setSelected:NO];
        [connectedView.yesButton setBackgroundColor:[UIColor whiteColor]];
        [connectedView.noButton setSelected:YES];
        [connectedView.noButton setBackgroundColor:[UIColor grayColor]];
    }
}

-(void) buildSingleSelection{
    
}

#pragma mark - Multiple Selection Methods

-(void) buildSelectionWithChoices:(NSArray *)choices{
    
    NSInteger count = 0;
    NSMutableArray *tmpButtons = [[NSMutableArray alloc] init];
    NSRegularExpression *otherRegex = [[NSRegularExpression alloc] initWithPattern:@"\\b(o)(t)(h)(e)(r)\\b.*"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    for(NSString *s in choices){
        HQLabel *tmp = [[HQLabel alloc]init];
        HQLabel *lastLabel = [[HQLabel alloc]init];
        HQCheckBox *box = [HQCheckBox buttonWithType:UIButtonTypeCustom];
        HQCheckBox *lastBox = [HQCheckBox buttonWithType:UIButtonTypeCustom];
        otherTextField = [[HQTextField alloc] init];
        
        tmp.constrainedWidth = 375;
        [tmp setText:s];
        
        NSUInteger countMatches = [otherRegex numberOfMatchesInString:s
                                                              options:0 range:NSMakeRange(0, [s length])];
        
        if(countMatches == 0){
            if(count == 0){
                tmp.frame = CGRectMake(questionLabel.frame.origin.x + SELECT_OFFSET, questionLabel.frame.origin.y + questionLabel.frame.size.height + Y_PADDING, tmp.frame.size.width, tmp.frame.size.height);
                box.frame = CGRectMake(questionLabel.frame.origin.x, questionLabel.frame.origin.y + questionLabel.frame.size.height + Y_PADDING, 30, 30);
            }
            else{
                lastLabel = [response lastObject];
                lastBox = [tmpButtons lastObject];
                tmp.frame = CGRectMake(lastLabel.frame.origin.x, lastLabel.frame.origin.y + lastLabel.frame.size.height + Y_PADDING, tmp.frame.size.width, tmp.frame.size.height);
                box.frame = CGRectMake(lastBox.frame.origin.x, lastLabel.frame.origin.y + lastLabel.frame.size.height + Y_PADDING, 30, 30);
            }
            
            [box setArrayIndex:count];
            box.optionLabel = s;
            
            responseHeight += (tmp.frame.size.height + Y_PADDING);
            
            [response addObject: tmp];
            [checkBoxes addObject:box];
            [tmpButtons addObject:box];
            [questionUnion addObject:tmp];
            [questionUnion addObject:box];
            
            [box addTarget:self action:@selector(checkPressed:) forControlEvents:UIControlEventTouchDown];
            
            [self addSubview:tmp];
            [self addSubview:box];
        }
        else{
            lastLabel = [response lastObject];
            tmp.frame = CGRectMake(self.frame.origin.x, lastLabel.frame.origin.y + lastLabel.frame.size.height + Y_PADDING, tmp.frame.size.width, tmp.frame.size.height);
            otherTextField.frame = CGRectMake(tmp.frame.origin.x + 75, lastLabel.frame.origin.y + lastLabel.frame.size.height + Y_PADDING, 250, 30);
            otherTextField.borderStyle = UITextBorderStyleBezel;
            otherTextField.keyboardType = UIKeyboardTypeDefault;
            otherTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            [otherTextField setFont:[UIFont fontWithName:@"HelveticaNeue" size:FONT_SIZE]];
            
            responseHeight += (tmp.frame.size.height + Y_PADDING);
            
            [response addObject:tmp];
            
            [self addSubview:tmp];
            [self addSubview:otherTextField];
        }
        count++;
    }
    
    [self adjustFrame];
    
}

-(void) checkPressed:(id)sender{
    HQCheckBox *cb = (HQCheckBox*)sender;
    
    if(cb.selected){
        [cb setSelected:NO];
        [cb setBackgroundColor:[UIColor whiteColor]];
        
        [[connectedView.checkBoxes objectAtIndex:cb.arrayIndex] setSelected:NO];
        [[connectedView.checkBoxes objectAtIndex:cb.arrayIndex] setBackgroundColor:[UIColor whiteColor]];
        
    }
    else{
        [cb setSelected:YES];
        [cb setBackgroundColor:[UIColor blackColor]];
        
        [[connectedView.checkBoxes objectAtIndex:cb.arrayIndex] setSelected:YES];
        [[connectedView.checkBoxes objectAtIndex:cb.arrayIndex] setBackgroundColor:[UIColor blackColor]];
    }
}


-(void) buildTextEntry{
    
    textEntryField = [[HQTextField alloc] init];
    textEntryField.borderStyle = UITextBorderStyleBezel;
    textEntryField.keyboardType = UIKeyboardTypeDefault;
    textEntryField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    previousTextEntry = textEntryField.text;
    
    [textEntryField setFont:[UIFont fontWithName:@"HelveticaNeue" size:FONT_SIZE]];
    textEntryField.frame = CGRectMake(questionLabel.frame.origin.x, questionLabel.frame.origin.y + questionLabel.frame.size.height + Y_PADDING, CONST_WIDTH, 30);
    
    responseHeight = textEntryField.frame.size.height + Y_PADDING;
    
    [response addObject:textEntryField];
    [questionUnion addObject:textEntryField];
    
    [self addSubview:textEntryField];
    
    [self adjustFrame];
    
}

-(void) buildTextSelection{
    
}

-(void) restorePreviousAnswers{
    
    answerString = @"YES, AIDS, Bronchitis";
    //answerString = [Question getValueForQuestionId:questionId];
    NSArray *answers = [answerString componentsSeparatedByString:@", "];
    
    if(type == TEXT_ENTRY){
        if([answers containsObject:@"YES"] && [answers count] > 1){
            textEntryField.text = [answers objectAtIndex:1];
            connectedView.textEntryField.text = [answers objectAtIndex:1];
        }
    }
    else if (type == YES_NO){
        if([answers containsObject:@"YES"]){
            [self yesPressed];
        }
        else if ([answers containsObject:@"NO"]){
            [self noPressed];
        }
    }
    else if(type == SELECTION_QUESTION){
        for(HQCheckBox *cb in checkBoxes){
            if([answers containsObject:cb.optionLabel]){
                [self checkPressed:cb];
            }
        }
        if(![[[checkBoxes lastObject] optionLabel] isEqual:[answers lastObject]]){
            otherTextField.text = [answers lastObject];
            connectedView.otherTextField.text = [answers lastObject];
        }
    }
}

-(void) adjustFrame{
    float tmpHeight = 0;
    
    tmpHeight += questionLabel.frame.size.height;
    tmpHeight += responseHeight;
    
    [self setFrame:CGRectMake(questionLabel.frame.origin.x, questionLabel.frame.origin.y, CONST_WIDTH, tmpHeight)];
    
    totalHeight += tmpHeight;
    
}

@end
