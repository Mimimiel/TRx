//
//  Question.m
//  TRx
//
//  Created by John Cotham on 4/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "Question.h"
#import "LocalTalk.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@implementation Question
static FMDatabase *db;
+ (void)initialize {
    db = [LocalTalk getDb];
}

/*---------------------------------------------------------------------------
 * Takes a questionId and returns appropriate English Label or NULL
 *---------------------------------------------------------------------------*/
+(NSString *)getEnglishLabel:(NSString *)questionId {
    return [self getLabel:questionId columnName:@"English"];
}

/*---------------------------------------------------------------------------
 * Takes a questionId and returns appropriate Spanish Label or NULL
 *---------------------------------------------------------------------------*/
+(NSString *)getTranslatedLabel:(NSString *)questionId {
    return [self getLabel:questionId columnName:@"Spanish"];
}

+(NSString *)getSpanishLabel:(NSString *)questionId {
    return [self getLabel:questionId columnName:@"Spanish"];
}

+(NSString *)getQuestionType:(NSString *)questionId {
    return [self getLabel:questionId columnName:@"QuestionType"];
}

/*---------------------------------------------------------------------------
 * Base method for getEnglishLabel and getSpanishLabel
 *---------------------------------------------------------------------------*/
+(NSString *)getLabel:(NSString *)questionId
           columnName:(NSString *)columnName {
    
    NSString *query = [[NSString alloc] initWithFormat:
                       @"SELECT %@ FROM Questions WHERE QuestionId = \"%@\"", columnName, questionId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if (!results) {
        NSLog(@"%@", [db lastErrorMessage]);;
        return nil;
    }
    [results next];
    NSString *retval = [results stringForColumnIndex:0];
    return retval;
}

/*---------------------------------------------------------------------------
 Summary:
 gets value stored with key QuestionId
 Returns:
 nil or NSString with value
 *---------------------------------------------------------------------------*/

+(NSString *)getValueForQuestionId:(NSString *)questionId {
    

    NSString *query = [NSString stringWithFormat:@"SELECT Value FROM Patient WHERE QuestionId = \"%@\"", questionId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if (!results) {
        NSLog(@"%@", [db lastErrorMessage]);;
        return nil;
    }
    [results next];
    NSString *retval = [results stringForColumnIndex:0];
    
    return retval;
}


@end
