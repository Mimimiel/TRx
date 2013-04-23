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
 * Packs Information into a dictionary for a listener to store into LocalTalk
 * Use: put this in the next button
 * This doesn't synch yet, but this is the form it will take.
 *---------------------------------------------------------------------------*/

//TODO actually make this work with the app
// --get unconfused about the different localGetApp Ids
//      --difference between PatientRecords' AppId and appPatientId?

+(void)storeQuestionAnswer:(NSString *)answer questionId:(NSString *)questionId{
    
    NSString *view = @"questionView";
    NSString *appPatientRecordId = [LocalTalk localGetPatientRecordAppId];
    
    NSDictionary *params = @{@"AppPatientRecordId": appPatientRecordId,
                             @"viewName":           view,
                             @"Value":              answer,
                             @"QuestionId":         questionId};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpressed" object:self userInfo:params];
    
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
                       @"SELECT %@ FROM Question WHERE Id = \"%@\"", columnName, questionId];
    
    FMResultSet *results = [db executeQuery:query];
    
    if (!results) {
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    [results next];
    NSString *retval = [results stringForColumnIndex:0];
    return retval;
}

/*---------------------------------------------------------------------------
 Summary:
    gets value stored for current patient with key QuestionId
 Returns:
    nil or NSString with value
 *---------------------------------------------------------------------------*/

+(NSString *)getValueForQuestionId:(NSString *)questionId {
    NSString *appPatientRecordId = [LocalTalk localGetPatientRecordAppId];
    
    NSString *query = [NSString stringWithFormat:@"SELECT Value FROM History WHERE AppPatientRecordId = %@ and QuestionId = \"%@\"", appPatientRecordId, questionId];
    
    
    FMResultSet *results = [db executeQuery:query];
    
    if (!results) {
        NSLog(@"%@", [db lastErrorMessage]);
        [Utility alertWithMessage:@"Unable to retrieve question answer"];
        return nil;
    }
    [results next];
    NSString *value = [results stringForColumnIndex:0];
    NSLog(@"%@", value);
    
    return value;
}




@end
