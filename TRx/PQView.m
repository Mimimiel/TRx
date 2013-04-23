//
//  PQView.m
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "PQView.h"

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

@implementation PQView

@synthesize questionIndex, hasAnswer, shouldBranch, questionLabel, type, textEntryField, otherTextField, previousTextEntry, answerString, checkBoxes;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = CGRectMake(0, 0, CONST_WIDTH, 100);
        
        questionIndex = -1;
        
        hasAnswer = NO;
        shouldBranch = NO;
        
        totalHeight = 0;
        responseHeight = 0;
        
        response = [[NSMutableArray alloc]init];
        checkBoxes = [[NSMutableArray alloc]init];
        questionUnion = [[NSMutableArray alloc]init];
        
        questionLabel = [[PQLabel alloc] init];
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

@end
