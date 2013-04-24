//
//  PQHelper.m
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "PQHelper.h"
@implementation pIndexHelper
@synthesize questionId, nextYes, nextNo;

-(id) initWithID:(NSString*)q NextYes:(NSInteger)ny NextNo:(NSInteger)nn{
    self = [super init];
    if(self){
        self.questionId = q;
        self.nextYes = ny;
        self.nextNo = nn;
    }
    return self;
}

-(void) setQuestionID:(NSString*)q NextYes:(NSInteger)ny NextNo:(NSInteger)nn{
    self.questionId = q;
    self.nextYes = ny;
    self.nextNo = nn;
}

@end

@implementation PQHelper

@synthesize currentIndex, nextIndex, questionKeys;

-(id)init{
    if(self = [super init]){
        currentIndex = 0;
        nextIndex = 0;
        [self initializeQuestionTracker];
        
    }
    return self;
}

-(void)initializeQuestionTracker{
    pIndexHelper *tmp;
    questionTracker = [[NSMutableArray alloc]init];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_BloodPressure" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_HeartRate" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_RestMin" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_OxSat" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_Temp" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_Height" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_Weight" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_AwakeOriented" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_Heent" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_HeentSelect" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_ChestCTAB" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_ChestRRR" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_ChestSym" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_ChestPulse" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_AbSoft" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_AbNT" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_AbND" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_AbBS" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[pIndexHelper alloc] initWithID:@"phys_Done" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
}

-(NSInteger) getNextType{
    pIndexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
    NSString *typeString = [Question getQuestionType:qKey.questionId];
    return [typeString integerValue];
    
}

-(NSString*) getQuestionId{
    return [[questionTracker objectAtIndex:currentIndex] questionId];
}

-(NSString*) getNextEnglishLabel{
    pIndexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
    return [Question getEnglishLabel:qKey.questionId];
}

-(NSString*) getNextTranslatedLabel{
    pIndexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
    return [Question getTranslatedLabel:qKey.questionId];
}

-(NSArray*) getEnglishChoices{
    
    NSString *choiceString = [Question getEnglishLabel:[[questionTracker objectAtIndex:(currentIndex +1)] questionId]];
    
    NSArray *a = [choiceString componentsSeparatedByString:@", "];
    
    return a;
}

-(NSArray*) getTransChoices{
    
    NSString *choiceString = [Question getTranslatedLabel:[[questionTracker objectAtIndex:(currentIndex +1)] questionId]];
    
    NSArray *a = [choiceString componentsSeparatedByString:@", "];
    
    return a;
}

-(void) updateCurrentIndexWithResponse:(NSMutableArray*)r QuestionType:(NSInteger)q{
    
    if(q == 1){
        
        if([[[questionTracker objectAtIndex:currentIndex] questionId] isEqualToString: @"preOp_HaveMedicalProblems"]){
            if([r containsObject:@"Infection"]){
                nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextYes];
            }
            else{
                nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextNo];
            }
        }
        else{
            if([[r objectAtIndex:0] isEqual: @"YES"]){
                nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextYes];
            }
            else if ([[r objectAtIndex:0] isEqual:@"NO"]){
                nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextNo];
            }
        }
        
    }
    else{
        if([[r objectAtIndex:0] isEqual: @"YES"]){
            nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextYes];
        }
        else if ([[r objectAtIndex:0] isEqual:@"NO"]){
            nextIndex = currentIndex + [[questionTracker objectAtIndex:currentIndex] nextNo];
        }
    }
    
    currentIndex = nextIndex;
    
}

@end
