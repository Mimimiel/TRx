//
//  AdminInformation.h
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdminInformation : NSObject

{

}

+(NSMutableArray *)getDoctorNames;
+(NSMutableArray *)getSurgeryNames;
+(NSMutableArray *)getOperationRecordTypeNames;
+(NSString *) getSurgeryNameById:(NSString *)complaintId;
+(NSString *) getSurgeryIdByName:(NSString *)complaintName;
+(NSString *)getOperationRecordTypeNameById:(NSString *)recordId;
+(NSString *)getOperationRecordTypeIdByName:(NSString *)operationRecordTypeName;



@end
