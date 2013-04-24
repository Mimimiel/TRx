//
//  DBTalk.h
//  TRx
//
//  Created by John Cotham on 2/24/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "AFJSONRequestOperation.h"
@interface DBTalk : NSObject

{
    NSString *host;
    NSString *portraitDir;
    NSString *dbPath;
    DBTalk *singleton;
    Reachability *internetReachable;
    
}

+(DBTalk *)getSingleton;

+(NSArray *)getPatientList;
+(NSArray *)getSurgeryList;
+(NSArray *)getDoctorList;
+(NSArray *)getOperationRecordTypesList;

+(UIImage *)getPortraitFromServer:(NSString *)fileName;
+(NSURL *)getThumbFromServer:(NSString *)fileName;
+(NSURL *)getProfileThumbURLFromServerForPatient:(NSString *)patientId andRecord:(NSString *)patientRecordId;
+(UIImage *)getProfilePictureFromServer:(NSString *)patientId;

+(NSString *)addProfilePicture:(UIImage *)picture
                     patientId:(NSString *)patientId;


+(NSString *)addPicture:(UIImage  *)picture
              patientId:(NSString *)patientId
      customPictureName:(NSString *)customPictureName
              isProfile:(NSString *)isProfile
              directory:(NSString *)directory;

+(BOOL)uploadPictureToServer:(UIImage *)picture
                    fileName:(NSString *)fileName
                   directory:(NSString *)directory;



+(BOOL)deletePatient: (NSString *)patientId;

+(NSString *)addRecord:(NSString *)patientId
         surgeryTypeId:(NSString *)surgeryTypeId
              doctorId:(NSString *)doctorId
              isActive:(NSString *)isActive
            hasTimeout:(NSString *)hasTimeout;

+(void)addRecoveryDataForRecord:(NSString *)recordId
                     recoveryId:(NSString *)recoveryId
                  bloodPressure:(NSString *)bloodPressure
                      heartRate:(NSString *)heartRate
                    respiratory:(NSString *)respiratory
                           sao2:(NSString *)sao2
                          o2via:(NSString *)o2via
                             ps:(NSString *)ps;


+(NSString *)addRecordData:(NSString *)recordId
                       key:(NSString *)key
                     value:(NSString *)value;

+(NSArray *)getRecordData:(NSString *)recordId;
+(NSArray *)getPatientMetaData:(NSString *)patientId;

+(NSDictionary *)getOperationRecordNames:(NSString *)recordId;
+(void)checkReachability;
+(BOOL)getConnectivity;
+(void)loadDataFromServer:(NSDictionary *)params;
-(void)pushLocalUnsyncedToServer;

+(NSString *)pictureInfoToDatabase:(NSDictionary *)params;

+(BOOL)uploadFileToServer:(id)file
                 fileType:(NSString *)fileType
                 fileName:(NSString *)fileName
                patientId:(NSString *)patientId;

@end
