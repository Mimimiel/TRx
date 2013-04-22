//
//  HQHelper.m
//  TRx
//
//  Created by Mark Bellott on 4/5/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "HQHelper.h"

@implementation indexHelper
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

@implementation HQHelper

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
    indexHelper *tmp;
    questionTracker = [[NSMutableArray alloc]init];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HowLong" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_PreventWorking" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_GettingWorse" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HaveMedicalProblems" NextYes:2 NextNo:4];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_MedicalProblemsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HaveInfections" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_InfectionsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_BeenHospital" NextYes:1 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HospitalFor" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_EyeProblems" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HearingProblems" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HeartburnSwallowing" NextYes:1 NextNo:1];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HeartProblems" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_HeartProblemsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_LungProblems" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_LungProblemsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_GiProblems" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_GiProblemsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_NeurologicProblems" NextYes:2 NextNo:2];
    [questionTracker addObject:tmp];
    
    tmp = [[indexHelper alloc] initWithID:@"preOp_NeurologicProblemsLike" NextYes:0 NextNo:0];
    [questionTracker addObject:tmp];
}

-(NSInteger) getNextType{
    indexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
    NSString *typeString = [Question getQuestionType:qKey.questionId];
    return [typeString integerValue];
}

-(NSString*) getNextEnglishLabel{
    indexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
    return [Question getEnglishLabel:qKey.questionId];
}

-(NSString*) getNextTranslatedLabel{
    indexHelper* qKey = [questionTracker objectAtIndex:currentIndex];
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
