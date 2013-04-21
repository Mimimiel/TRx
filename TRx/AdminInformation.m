//
//  AdminInformation.m
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "AdminInformation.h"
#import "DBTalk.h"
#import "LocalTalk.h"

@implementation AdminInformation 

static NSArray *surgeryList; 
static NSArray *doctorList;
static NSArray *operationsList;


+ (void)initialize {
    surgeryList = [DBTalk getSurgeryList];
    doctorList = [DBTalk getDoctorList];
    operationsList = [DBTalk getOperationRecordTypesList];
}
//TODO:ERROR CHECKING
//these methods are called in app delegate 

+(NSMutableArray *)getOperationRecordTypeNames
{
    NSMutableArray *operationRecordNamesList = [[NSMutableArray alloc] initWithArray:operationsList copyItems:YES];
    [LocalTalk setSQLiteTable:@"RecordType" withData:operationRecordNamesList];
    return operationRecordNamesList;

}

+(NSString *)getOperationRecordTypeNameById:(NSString *)recordId {
    if (operationsList != NULL) {
        for (NSDictionary *dic in operationsList) {
            NSString *tmp = [dic objectForKey:@"Id"];
            if([recordId isEqualToString:tmp]){
                return [dic objectForKey:@"Name"];
            }
        }
    }
    else {
        NSLog(@"Error retrieving surgeryNamesList");
        return NULL;
    }
    return NULL;
}

+(NSString *)getOperationRecordTypeIdByName:(NSString *)operationRecordTypeName{
    if (operationsList != NULL) {
        for (NSDictionary *dic in operationsList) {
            NSString *tmp = [dic objectForKey:@"Name"];
            if([operationRecordTypeName isEqualToString:tmp]){
                return [dic objectForKey:@"Id"];
            }
        }
    }
    else {
        
        NSLog(@"Error retrieving surgeryNamesList");
        return [LocalTalk getOperationRecordTypeIdByNameFromSQLite:operationRecordTypeName];
    }
    return NULL;
    
}
+(NSMutableArray *)getDoctorNames
{
    NSMutableArray *doctorNamesList = [[NSMutableArray alloc] initWithArray:doctorList copyItems:YES];
    [LocalTalk setSQLiteTable:@"Doctor" withData:doctorNamesList];
    return doctorNamesList;
    
    NSArray *check = [LocalTalk setSQLiteTable:@"Doctor" withData:doctorNamesList];
    if(check){
        return doctorNamesList;
    }
    else {
        NSLog(@"Error retrieving doctorNamesList");
        return NULL;
    }
}

+(NSMutableArray *)getSurgeryNames
{
    NSMutableArray *surgeryNamesList = [[NSMutableArray alloc] initWithArray:surgeryList copyItems:YES];
    [LocalTalk setSQLiteTable:@"SurgeryType" withData:surgeryNamesList];
    return surgeryNamesList;
 
}

+(NSString *)getSurgeryNameById:(NSString *)complaintId {
    if (surgeryList != NULL) {
        for (NSDictionary *dic in surgeryList) {
            NSString *tmp = [dic objectForKey:@"Id"];
            if([complaintId isEqualToString:tmp]){
                return [dic objectForKey:@"Name"];
            }
        }
    }
    else {
        NSLog(@"Error retrieving surgeryNamesList");
        return NULL;
    }
    return NULL; 
}

+(NSString *)getSurgeryIdByName:(NSString *)complaintName{
    if (surgeryList != NULL) {
        for (NSDictionary *dic in surgeryList) {
            NSString *tmp = [dic objectForKey:@"Name"]; 
            if([complaintName isEqualToString:tmp]){
                return [dic objectForKey:@"Id"];
            }
        }
    }
    else {
        NSLog(@"Error retrieving surgeryNamesList");
        return NULL;
    }
    return NULL;

}

@end
