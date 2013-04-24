//
//  PQHelper.h
//  TRx
//
//  Created by Mark Bellott on 4/23/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Question.h"

@interface pIndexHelper : NSObject{
    NSString *questionId;
    NSInteger nextYes;
    NSInteger nextNo;
}

@property(nonatomic, retain) NSString *questionId;
@property(nonatomic, readwrite) NSInteger nextYes;
@property(nonatomic, readwrite) NSInteger nextNo;

@end

@interface PQHelper : NSObject{
    
    NSInteger currentIndex;
    NSInteger nextInedex;
    
    NSMutableArray *questionKeys;
    NSMutableArray *questionTracker;
}

@property(nonatomic, readwrite) NSInteger currentIndex;
@property(nonatomic, readwrite) NSInteger nextIndex;
@property(nonatomic, retain) NSMutableArray *questionKeys;

-(void) initializeQuestionTracker;
-(NSInteger) getNextType;
-(NSString*) getQuestionId;
-(NSString*) getNextEnglishLabel;
-(NSString*) getNextTranslatedLabel;
-(NSArray*) getEnglishChoices;
-(NSArray*) getTransChoices;
-(void) updateCurrentIndexWithResponse:(NSMutableArray*)r QuestionType:(NSInteger)q;


@end
