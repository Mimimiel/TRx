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
+(NSMutableDictionary *)getData:(NSDictionary *)tableNames{
    NSString *selectorValue, *selectorType, *patientId, *patientRecordId, *query;
    BOOL useSelector = 1;
    NSMutableDictionary *dictionary; 
    patientRecordId = [self localGetRecordId];
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
    for(NSString *key in dictionary){
        NSLog(@"%@", key);
    }
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


+(BOOL)localStoreEverything:(NSDictionary *)params {
    BOOL success;
    if ([[params objectForKey:@"viewName"] isEqualToString:@"historyViewController"]) {
        
        success = [self addPatientToLocal:params];
        if (!success) {
            return false;
        }
        success = [self addRecordToLocal:params];
        if (!success) {
            return false;
        }
        
    }
    
    return false;
}

+(BOOL)addRecordToLocal:(NSDictionary *)params {
    NSString *firstName     = [params objectForKey:@"FirstName"];
    NSString *middleName    = [params objectForKey:@"MiddleName"];
    NSString *lastName      = [params objectForKey:@"LastName"];
    NSString *birthday      = [params objectForKey:@"Birthday"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (FirstName, MiddleName, LastName) VALUES (?, ?, ?, ?)",
                   firstName, middleName, lastName, birthday];
    [db close];
    
    return retval;
}


+(BOOL)addPatientToLocal:(NSDictionary *)params {
    NSString *surgeryTypeId = [params objectForKey:@"SurgeryTypeId"];
    NSString *doctorId      = [params objectForKey:@"DoctorId"];
    NSString *isActive      = [params objectForKey:@"IsActive"];
    NSString *hasTimeout    = [params objectForKey:@"HasTimeout"];
    NSString *patientId     = [self localGetPatientId];
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO PatientRecord (SurgeryTypeId, DoctorId, isActive, hasTimeout, Pa) VALUES (?, ?, ?, ?)",
                   surgeryTypeId, doctorId, isActive, hasTimeout];
    [db close];
    
    return retval;
}




/*-------------------End Local Store Mega Method---------------------*/








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
        
    patientsArrayFromDB = [DBTalk getPatientList];
    if(patientsArrayFromDB == NULL){
        NSLog(@"DBTalk Couldn't return patients List");
        return NULL;
    }
    
    patients = [NSMutableArray array];
    
    for(NSDictionary *item in patientsArrayFromDB){
       //NSLog(@"%@", item);
        firstName = [item objectForKey:@"FirstName"];
        middleName = [item objectForKey:@"MiddleName"];
        lastName = [item objectForKey:@"LastName"];
        patientId = [item objectForKey:@"Id"];
        recordId = [item objectForKey:@"recordId"];
        birthday = [item objectForKey:@"birthday"];  //does this exist?
        complaint = [item objectForKey:@"SurgeryTypeId"];
        complaint = [AdminInformation getSurgeryNameById:complaint];
        imageId = [NSString stringWithFormat:@"%@n000", patientId];
        
        pictureURL = [DBTalk getThumbFromServer:imageId];
        
        Patient *obj = [[Patient alloc] initWithPatientId:patientId currentRecordId:recordId firstName:firstName MiddleName:middleName LastName:lastName birthday:birthday ChiefComplaint:complaint PhotoID:picture PhotoURL:pictureURL];
        
        obj.patientId = patientId;
        NSLog(@"%@", picture);
        NSLog(@"%@", imageId);
        [patients addObject:obj];
    }

    
    return patients; 
}


+(NSDictionary *)getDBObject:(NSDictionary *)params {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    NSString *query;
    NSDictionary *dbobj;
    query = [NSString stringWithFormat:@"SELECT a.Id, b.Id FROM PatientRecord as a JOIN Patient as b ON a.AppPatientId = b.AppId WHERE a.IsLive = 1"];
    
    FMResultSet *results = [db executeQuery:query];
    
    /*test to see if the query failed */
    if (!results) {
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    
    
    [results next];
    NSLog(@"got to patient record id");
    NSString *patientRecordId = [results stringForColumn:@"PatientRecordId"];
    NSLog(@"print stuff: %@", [[results resultDictionary] description]);
    [results next];
    NSLog(@"got to patient id");
    NSString *patientId = [results stringForColumn:@"PatientId"];
    NSLog(@"print stuff: %@", [[results resultDictionary] description]);
    [db close];
    
    if(patientId != nil && patientRecordId != nil){
        dbobj = @{@"tableNames" : [params objectForKey:@"tableNames"],
            @"patientRecordId" : patientRecordId,
            @"patientId" : patientId,
            @"location" : [params objectForKey:@"location"] };
    } else { return nil; }
    
    return dbobj;
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







