//
//  LocalTalk.h
//  TRx
//
//  Created by John Cotham on 3/10/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocalTalk : NSObject

/*Will uncomment methods as they are implemented 
 ***Add or let me know if you have something you want implemented ***/
{
    LocalTalk *singleton;
}
+(LocalTalk *)getSingleton;
+(BOOL)clearIsLiveFlags;


/* Store @"tempId" locally before actual values loaded from DB
 * Used so that app will work without server access */

+(BOOL)addPatientToLocal:(NSDictionary *)params;
+(BOOL)addRecordToLocal:(NSDictionary *)params;



+(BOOL)localStoreTempPatientId;
+(BOOL)localStoreTempRecordId;
+(BOOL)localStoreValue:(NSString *)value forQuestionId:(NSString *)questionId;
+(BOOL)localStorePatientMetaData:(NSString *)key
                           value:(NSString *)value;
+(BOOL)localStoreAudio:(NSData *)audioData withAppPatientRecordId:(NSString *)appPatientRecordId andRecordTypeId:(NSString *)recordTypeId andfileName:(NSString *)fileName andPath:(NSString *)pathToAudio;

+(BOOL)localStorePortrait:(UIImage *)image;

#pragma mark -- Accessor Methods for Local

+(NSArray *)selectAllFromTable:(NSString *)table;
+(BOOL)tableUnsynced:(NSString *)table;

+(NSString *)localGetOperationRecordTypeId; 

#pragma mark -- Mutator Methods for Local


+(BOOL)insertValue:(NSString *)value intoColumn:(NSString *)column inLocalTable:(NSString *)table;



+(NSMutableArray *)localGetPatientList;
+(NSString *)localGetPatient:(NSString *)key;
+(UIImage *)localGetPortrait;
+(id)localGetAudio:(NSString *)fileName;

+(NSString *)localGetPatientId;
+(NSString *)localGetPatientRecordId;
+(NSString *)localGetPatientRecordAppId;


+(BOOL)loadPortraitImageIntoLocal:(NSString *)patientId;
+(BOOL)loadPatientRecordIntoLocal:(NSString *)recordId;


+(void)localClearPatientData;


+(BOOL)clearLocalThenLoadPatientRecordIntoLocal:(NSString *)recordId;


+(void)checkConnectionAndLoadFromServer:(NSNotification *)notification;
+(NSMutableDictionary *)getData:(NSDictionary *)tableNames;
+(BOOL)setIsLive:(NSString *)patientIdentifier;
+(BOOL)checkConnectivity;
+(BOOL)storeMutableArrayFromAdmin:(NSMutableArray *)adminArray  inTable:(NSString *)tableName;



@end
