//
//  LocalTalk.m
//  TRx
//
//  Created by John Cotham on 3/10/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "LocalTalk.h"
#import "DBTalk.h"
#import "FMDatabase.h"
#import "Utility.h"
#import "SynchData.h"
#import "AdminInformation.h"

@implementation LocalTalk


static LocalTalk *singleton;
+(void)initialize{
    
    static BOOL initialized = false;
    if (!initialized)
    {
        initialized = true;
        singleton = [[LocalTalk alloc] init];
        
        
    }
}

+(LocalTalk *)getSingleton {
    return singleton;
}

-(void)loadListener{
    NSLog(@"look at how awesome I am"); 
}

/*Listener method that checks for connectivity to the server and if there is connectivity, calls loadDataFromServer to load data into SQLite*/ 
-(void)checkConnectionAndLoadFromServer:(NSNotification *)notification{
    
    //check for connectivity to the Server
    BOOL connectivity = [DBTalk getConnectivity];
    NSLog(@"Connectivity is: %d",connectivity);
    //get the parameters from the notifcation 
    NSDictionary *params = [notification userInfo];

    //if there is connectivity call the loadDataFromServer:params method, if not, publish dataLoaded
    if(connectivity){
        [DBTalk loadDataFromServer:params];
    } else if(!connectivity){
       [[NSNotificationCenter defaultCenter] postNotificationName:@"dataLoaded" object:self userInfo:params];

    }
    
}

/*Method that takes a list of table names and then queries the SQLite database and returns an NSArray of NSDictionaries*/ 
+(NSMutableDictionary *)getData:(NSDictionary *)tableNames {
    NSString *selectorValue, *selectorType, *patientId, *patientRecordId, *query;
    BOOL useSelector = 1;
    NSMutableDictionary *dictionary; 
    patientRecordId = [self localGetPatientRecordId];
    patientId = [self localGetPatientId];
    //check for current patient, if none, return nil
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open]; 
    
    for(NSString *table in tableNames){
        //check if it's Doctor, surgery type, or patient and if it is those have special keys
        //otherwise, use patient record id
        //to insert (if it doesn't exist or update if it does
        if([table isEqualToString:@"Patient"]){
            selectorValue = patientId;
            selectorType = @"Id";
            useSelector = 1; 
        } else if([table isEqualToString:@"PatientRecord"]){
            selectorValue = patientRecordId;
            selectorType = @"Id";
            useSelector = 1; 
        } else if([table isEqualToString:@"Doctor"] || [table isEqualToString:@"SurgeryType"]) {
            useSelector = 0;
        } else {
            selectorValue = patientRecordId;
            selectorType = @"PatientRecordId";
            useSelector = 1;
        }
        
        if(useSelector){
            query = [NSString stringWithFormat: @"SELECT * FROM  %@ WHERE %@ = %@", table, selectorType, selectorValue];
        } else {
            query = [NSString stringWithFormat:@"SELECT * FROM %@", table];
        }
        FMResultSet *retval = [db executeQuery:query];
        
        if (!retval) {
            NSLog(@"The query in getData didn't return anything good :(");
            NSLog(@"%@", [db lastErrorMessage]);
            [Utility alertWithMessage:@"For some reason one of your tables didn't return data!"];
        } else {//turn return data into a dictionary and put it into an array.
            [dictionary setObject:[retval resultDictionary] forKey:table];
        }
    }
    [db close];
    
    return dictionary;
    
}

+(BOOL)clearIsLiveFlags {
    //this will go to the database and set all the is live flags to 0
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET IsLive = 0"];

    BOOL retval = [db executeUpdate:query];
    if (!retval) {
        NSLog(@"Error updating isLive in PatientRecord's table");
        NSLog(@"%@", [db lastErrorMessage]);
    }
    [db close];
    return retval; 
}
#pragma mark - Local Store Methods





/*-----------------Local Store Mega Method---------------------------*/


-(BOOL)localStoreEverything:(NSNotification *)notification {

    
    NSDictionary *params = [notification userInfo];

    BOOL success;
    
    NSLog(@"In localStoreEverything");
    if ([[params objectForKey:@"viewName"] isEqualToString:@"historyViewController"]) {
        
        NSLog(@"attempting to add Patient to Local");
        success = [LocalTalk addPatientToLocal:params];
        if (!success) {
            [Utility alertWithMessage:@"Unable to add a patient."];
            return false;
        }
        NSLog(@"attempting to add Record to Local");
        success = [LocalTalk addRecordToLocal:params];
        if (!success) {
            [Utility alertWithMessage:@"Unable to add patient record."];
            return false;
        }
        
        
        
    }
    
    
    
    NSLog(@"Exiting localStoreEverything");
    return true;
}

+(BOOL)addPatientToLocal:(NSDictionary *)params {
    NSString *firstName     = [params objectForKey:@"FirstName"];
    NSString *middleName    = [params objectForKey:@"MiddleName"];
    NSString *lastName      = [params objectForKey:@"LastName"];
    NSString *birthday      = [params objectForKey:@"Birthday"];
    NSLog(@"FirstName: %@ MiddleName: %@ LastName: %@ Birthday: %@", firstName, middleName, lastName, birthday);
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (FirstName, MiddleName, LastName, Birthday) VALUES (?, ?, ?, ?)", firstName, middleName, lastName, birthday];
    
    /*-----------error checking ---------*/
    
    FMResultSet *result = [db executeQuery:@"Select * FROM Patient WHERE FirstName = ?", firstName];
    if (!result) {
        NSLog(@"failed to retrieve patient info");
    }
    [result next];
    NSLog(@"retrieved data: %@", [result stringForColumn:@"FirstName"]);
        
    /*-----------error checking ---------*/
    
    [db lastErrorMessage];
    
//    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (FirstName, MiddleName, LastName, Birthday) VALUES (\"?\", \"?\", \"?\", \"?\")", firstName, middleName, lastName, birthday];
    [db close];
    
    
    return retval;
}


+(BOOL)addRecordToLocal:(NSDictionary *)params {
    NSString *surgeryTypeId = [params objectForKey:@"SurgeryTypeId"];
    NSString *doctorId      = [params objectForKey:@"DoctorId"];
    NSString *isActive      = [params objectForKey:@"IsActive"];
    NSString *hasTimeout    = [params objectForKey:@"HasTimeout"];
    NSString *isCurrent     = [params objectForKey:@"IsCurrent"];
    NSString *isLive        = [params objectForKey:@"IsLive"];
    
    
    
    NSLog(@"SurgeryTypeId: %@, DocId: %@ IsActive: %@ HasTimeout %@ IsLive %@ IsCurrent %@",
            surgeryTypeId, doctorId,    isActive, hasTimeout, isLive, isCurrent);
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    
    NSString *AppPatientId         = [self localGetAppPatientId];
    NSLog(@"PatientId: %@", AppPatientId);
    
    BOOL retval = [db executeUpdate:@"INSERT INTO PatientRecord(SurgeryTypeId, DoctorId, HasTimeout, IsLive, IsCurrent, AppPatientId) VALUES (?, ?, ?, ?, ?, ?)", surgeryTypeId, doctorId, hasTimeout, isLive, isCurrent, AppPatientId];
    
    
    
    [db close];
    
    
    
    
    return retval;
}




/*-------------------End Local Store Mega Method---------------------*/



/*---------------------------------------------------------------------------
 Summary:
    Helper methods for retrieving patientId and recordId from local database
    GetPatientId        -- Returns the patientId used in server database
    GetPatientRecordId  -- Returns the recordId used in server database
    GetAppPatientId     -- Returns the patientId used in the local database
 -- 'AppId' in the Patient table
 Details:
    Methods wrap base method: localGetId
 Returns:
    nil - failure to communicate with database
    NSString of Id
 *---------------------------------------------------------------------------*/
+(NSString *)localGetPatientId {
    
    NSString *query;
    query = [NSString stringWithFormat:
             @"SELECT b.Id as Id FROM PatientRecord as a JOIN Patient as b ON a.AppPatientId = b.AppId WHERE a.IsLive = 1"];
    //query = @"SELECT Id FROM PatientRecord"
    query = @"SELECT pat.Id FROM PatientRecord rec, Patient pat WHERE rec.AppPatientId = pat.AppId AND rec.IsLive = 1";
    return [self localGetId:query];
}
+(NSString *)localGetPatientRecordId {
    
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT Id FROM PatientRecord WHERE IsLive = 1"];
    NSString *retval = [self localGetId:query];
    return retval;
}
+(NSString *)localGetAppPatientId {
    
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT MAX(rowid) FROM Patient"];
    return [self localGetId:query];
}

+(NSString *)localGetId:(NSString *)query {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    db.logsErrors = TRUE;
    [db open];
    
    FMResultSet *result = [db executeQuery:query];
    if([db hadError]){
         NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    /*test to see if the query failed */
    
    if (!result) {
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    NSLog(@"%@", [db lastErrorMessage]);
    [result next];
    
    NSString *str = [result stringForColumnIndex:0];
    
    /*-----------error checking ---------*/
    
//    //FMResultSet *result = [db executeQuery:@"Select * FROM PatientRecord", firstName];
//    if (!result) {
//        NSLog(@"failed to retrieve patient info");
//    }
//    [result next];
//    NSLog(@"retrieved data: %@", [result stringForColumn:@"FirstName"]);
    
    /*-----------error checking ---------*/
    
    [db close];
    NSLog(@"The string from local get Id is: %@", str);
    return str;
}




/*---------------------------------------------------------------------------
 Summary:
    Stores a temporary RecordId in the local database
 Details:
    New Patients are given temporary recordIds and patientIds
    until they are synched with the server
 Returns:
    true on success, false otherwise
 *---------------------------------------------------------------------------*/
+(BOOL)localStoreTempRecordId {
    return [self localStorePatientMetaData:@"recordId" value:@"tmpRecordId"];
}
+(BOOL)localStoreTempPatientId {
    return [self localStorePatientMetaData:@"patientId" value:@"tmpPatientId"];
}



/*---------------------------------------------------------------------------
 Summary:
    Store QuestionIds and values in the Patient database for the current patient
 Details:
 
 Returns:
    true on success, false otherwise
 *---------------------------------------------------------------------------*/
+(BOOL)localStoreValue:(NSString *)value forQuestionId:(NSString *)questionId {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (QuestionId, Value, Synched) VALUES (?, ?, 0)", questionId, value];
    [db close];
    
    return retval;
    
}

/*---------------------------------------------------------------------------
 Summary:
    Stores a portrait in the Images table of local database
 Details:
    Reduces size of image by 1/10 before storing. Not sure if I should do this here
 Returns:
    true on success, false otherwise
 *---------------------------------------------------------------------------*/
+(BOOL)localStorePortrait:(UIImage *)image {
    
    NSData *imageData = UIImageJPEGRepresentation(image, .1);    //should I be reducing size here?
    if (!imageData) {
        NSLog(@"Error in localStorePortrait converting UIImage to NSData object");
        return false;
    }
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT OR REPLACE INTO Images (imageType, imageBlob) VALUES (?,?)", @"portrait", imageData];
    [db close];
    
    return retval;
}

/*---------------------------------------------------------------------------
 Summary:
    Stores image data and filename to the Audio table of local database
 Details:
    File Names can be any unique string -- custom user names or just 
    (strings of) numbers to identify
 Returns:
    true on success, false otherwise
 TODO:
    does not sync with database yet.
 *---------------------------------------------------------------------------*/
+(BOOL)localStoreAudio:(NSData *)audioData fileName:(NSString *)fileName {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO Audio (Name, Data) VALUES (?, ?)", fileName, audioData];
    if (!retval) {
        NSLog(@"%@", [db lastErrorMessage]);
    }
    [db close];
    return retval;                                        
}

#pragma mark - Local Get Methods

 /*---------------------------------------------------------------------------
 Summary:
 gets patient list from dbtalk 
 Details:
  takes the patient list from DB talk and processes it into an array of 
  patient objects. 
 Returns:
 nil - failure to communicate with database
 NSArray of patients 
  
  TODO: Put the patient objects in the local database 
 *---------------------------------------------------------------------------*/
+(NSMutableArray *)localGetPatientList {
    
    NSArray *patientsArrayFromDB;
    NSMutableArray *patients;
    NSString *firstName, *lastName, *patientId, *imageId, *middleName, *recordId, *birthday, *complaint;
    NSURL *pictureURL;
    UIImage *picture; 
    //check for connectivity to the Server
    BOOL connectivity = [DBTalk getConnectivity];
    NSLog(@"Connectivity in localGetPatientList is: %d",connectivity);
    
    //if there is connectivity call the loadDataFromServer:params method, if not, publish dataLoaded
    //TODO: UPDATE THE LOCAL DATABASE WITH THE PATIENTS ARRAY WE GET FROM MYSQL
    if(connectivity){
        
        patientsArrayFromDB = [DBTalk getPatientList];
        
        if(patientsArrayFromDB == NULL){
            NSLog(@"DBTalk returned a NULL patients List even though there is a connection");
            return NULL;
        }
        patients = [NSMutableArray array];
        
        for(NSDictionary *item in patientsArrayFromDB){
            //NSLog(@"%@", item);
            firstName   = [item objectForKey:@"FirstName"];
            middleName  = [item objectForKey:@"MiddleName"];
            lastName    = [item objectForKey:@"LastName"];
            patientId   = [item objectForKey:@"Id"];
            recordId    = [item objectForKey:@"recordId"];
            birthday    = [item objectForKey:@"birthday"];  //does this exist?
            complaint   = [item objectForKey:@"SurgeryTypeId"];
            complaint   = [AdminInformation getSurgeryNameById:complaint];
            imageId     = [NSString stringWithFormat:@"%@n000", patientId];
            
            pictureURL = [DBTalk getThumbFromServer:imageId];
            
            Patient *obj = [[Patient alloc] initWithPatientId:patientId currentRecordId:recordId firstName:firstName MiddleName:middleName LastName:lastName birthday:birthday ChiefComplaint:complaint PhotoID:picture PhotoURL:pictureURL];
            
            obj.patientId = patientId;
            NSLog(@"%@", picture);
            NSLog(@"%@", imageId);
            [patients addObject:obj];
        }
        
        return patients;
        
    } else if(!connectivity){
        //get patients from Local
        NSLog(@"No connectivity to the MySQL database so localGetPatientList returned NULL");
        return NULL;
        
    }

    NSLog(@"Something is really broken so localGetPatientList returned NULL");
    return NULL; 
  
}








/*---------------------------------------------------------------------------
 Summary:
    Retrieves a portrait of current patient from the Images table of local database
 Details:
    
 Returns:
    nil - on failure to retrieve image
    UIImage of current patient otherwise
 *---------------------------------------------------------------------------*/
+(UIImage *)localGetPortrait {
   // NSString *query = [NSString stringWithFormat:@"SELECT imageBlob FROM Images WHERE imageType = \"portrait\""];
    NSString *query = [NSString stringWithFormat:@"Select * from Images"];
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:query];
    if (!results) {
        NSLog(@"Error retrieving image\n");
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    [results next];
    NSData *data = [results dataForColumnIndex:0];

    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        NSLog(@"In localGetPortrait: image is NULL");
        return nil;
    }
    
    [db close];

    return image;
}

+(NSData*)localGetAudio:(NSString *)fileName {
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    FMResultSet *results = [db executeQuery:@"SELECT Data FROM Audio WHERE Name = ?", fileName];
    
    if (!results) {
        NSLog(@"Error retrieving image\n");
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    [results next];
    NSData *data = [results dataForColumnIndex:0];
    
    [db close];
    
    return data;
}





#pragma mark - Clear Patient Data

/*---------------------------------------------------------------------------
 * clears local patient data. Needs to be called before new Patient data inserted
 * no retval
 *---------------------------------------------------------------------------*/
+(void)localClearPatientData {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    [db executeUpdate:@"DELETE FROM Images"];
    [db executeUpdate:@"DELETE FROM Patient"];
    [db executeUpdate:@"DELETE FROM PatientMetaData"];
    [db executeUpdate:@"DELETE FROM Audio"];
    [db close];
}


#pragma mark - Load Data from Server into Local

/*---------------------------------------------------------------------------
 Summary:
    clears local database and loads record data
 Details:
    clears Images, Patient and PatientMetaData
 Returns:
    true on success, false otherwise
 TODO:
    Might want to go ahead and add loadPortraitImage and 
    loadMetaData to this method
 *---------------------------------------------------------------------------*/

+(BOOL)clearLocalThenLoadPatientRecordIntoLocal:(NSString *)recordId {
    [LocalTalk localClearPatientData];
    return [LocalTalk loadPatientRecordIntoLocal:recordId];
}


/*---------------------------------------------------------------------------
 Summary:
    Loads all QuestionIds and values for a patient record and stores in local
 Details:
     
 Returns:
    true on success, false otherwise
 TODO:
    check whether DBTalk's getRecordData actually ever returns null
 *---------------------------------------------------------------------------*/

+(BOOL)loadPatientRecordIntoLocal:(NSString *)recordId {
    BOOL success;
    NSArray *dataArr = [DBTalk getRecordData:recordId];
    
    if (dataArr != NULL) {
        FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
        [db open];
        NSLog(@"%@", dataArr);
        for (NSDictionary *dic in dataArr) {
            NSString *questionId = [dic objectForKey:@"Key"];
            NSString *value = [dic objectForKey:@"Value"];
            
            success = [db executeUpdate:@"INSERT INTO Patient (QuestionId, Value, Synched) VALUES (?, ?, 1)", questionId, value];
            if (!success) {
                NSLog(@"Unable to add: %@", [db lastErrorMessage]);
                
            }
        }
        [db close];
        return true;
    }
    else {
        NSLog(@"Error retrieving patient record data");
        return false;
    }
}

/*---------------------------------------------------------------------------
 Summary:
    Retrieves portrait image from Server and stores in Local
 Details:
    Should make sure table is cleared before inserting new image
 Returns:
    true on success, false otherwise
 *---------------------------------------------------------------------------*/

+(BOOL)loadPortraitImageIntoLocal:(NSString *)patientId {
    UIImage *image = [DBTalk getPortraitFromServer:patientId];
    if (!image) {
        NSLog(@"Error loading Portrait Image");
        return false;
    }
    BOOL retval = [LocalTalk localStorePortrait:image];
    if (retval) {
        FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
        [db open];
        retval = [db executeUpdate:@"INSERT INTO Images (Synched) VALUES (1)"];
        [db close];
    }
    return retval;
}

+(BOOL)loadOperationRecordIntoLocal:(NSString *)recordId {
    [DBTalk getOperationRecordNames:recordId];
    //[LocalTalk ]
    /* Load into local talk */
    
}

#pragma mark - Helper methods


/*---------------------------------------------------------------------------
 Summary:
    Helper method for testing. Prints Patient data from localDatabase
 *---------------------------------------------------------------------------*/
+(void)printLocal {
    NSString *key, *value;
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM Patient"];
    while ([results next]) {
        key   = [results stringForColumn:@"QuestionId"];
        value = [results stringForColumn:@"Value"];
        NSLog(@"Key: %@  Value: %@", key, value);
    }
    
    [db close];
}

+(void)printAudio {
    NSString *name, *synced, *data;
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM Audio"];
    while ([results next]) {
        name   = [results stringForColumn:@"Name"];
        synced = [results stringForColumn:@"Synched"];
        data   = [results stringForColumn:@"Data"];
        NSLog(@"Name: %@  Synced: %@ Data: %@", name, synced, data);
    }
    [db close];
}

@end







