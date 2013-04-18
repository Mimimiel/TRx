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

+ (BOOL)checkConnectivity {
    [DBTalk checkReachability];
    BOOL connectivity = [DBTalk getConnectivity];
    return connectivity;
}
/*Listener method that checks for connectivity to the server and if there is connectivity, calls loadDataFromServer to load data into SQLite*/
-(void)checkConnectionAndLoadFromServer:(NSNotification *)notification{
    
    //check for connectivity to the Server
    BOOL connectivity = [LocalTalk checkConnectivity];
    NSLog(@"Connectivity is: %d",connectivity);
    //get the parameters from the notifcation
    NSDictionary *params = [notification userInfo];
    
    //if there is connectivity call the loadDataFromServer:params method, if not, publish dataLoaded
    if(connectivity){
        [DBTalk loadDataFromServer:params];
    } else if(!connectivity){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:self userInfo:params];
        
    }
    
}

/*Method that takes a list of table names and then queries the SQLite database and returns an NSArray of NSDictionaries*/
//TODO: FIX THIS FUNCTION TO USE APP ID INSTEAD OF PATIENT RECORD ID
+(NSMutableDictionary *)getData:(NSDictionary *)params {
    NSString *selectorValue, *selectorType, *query, *localPatientId, *localPatientRecordId;
    BOOL useSelector = 1;
    NSMutableDictionary *dictionary;
    localPatientId = [self localGetPatientAppId];
    localPatientRecordId = [self localGetPatientRecordAppId];
    NSMutableArray *tableNames = [params objectForKey:@"tableNames"];
    //check for current patient, if none, return nil
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    
    for(NSString *table in tableNames){
        //check if it's Doctor, surgery type, or patient and if it is those have special keys
        //otherwise, use patient record id
        //to insert (if it doesn't exist or update if it does
        if([table isEqualToString:@"Patient"]){
            selectorValue = localPatientId;
            selectorType = @"AppId";
            useSelector = 1;
        } else if([table isEqualToString:@"PatientRecord"]){
            selectorValue = localPatientRecordId;
            selectorType = @"AppId";
            useSelector = 1;
        } else if([table isEqualToString:@"Doctor"] || [table isEqualToString:@"SurgeryType"]) {
            useSelector = 0;
        } else {
            selectorValue = localPatientRecordId;
            selectorType = @"AppId";
            useSelector = 1;
        }
        
        if(useSelector){
            query = [NSString stringWithFormat: @"SELECT * FROM  %@ WHERE %@ = %@", table, selectorType, selectorValue];
            NSLog(@"The query we're trying to use in useSelector is: %@", query);
        } else {
            query = [NSString stringWithFormat:@"SELECT * FROM %@", table];
            NSLog(@"The query we're trying to use in !useSelector is: %@", query);
        }
        FMResultSet *retval = [db executeQuery:query];
        
        if (!retval) {
            NSLog(@"The query in getData didn't return anything good :(");
            NSLog(@"%@", [db lastErrorMessage]);
            [Utility alertWithMessage:@"For some reason one of your tables didn't return data!"];
        } else {//turn return data into a dictionary and put it into an array.
            [retval next];
            NSDictionary *dict = [retval resultDictionary];
            [dictionary setObject:dict forKey:table];
        }
    }
    [db close];
    
    return dictionary;
    
}

+(BOOL)clearIsLiveFlags {
    //this will go to the database and set all the is live flags to 0
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    /*FIX THIS WILLIE YOURE WORKING HERE*/
    NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET IsLive = 0"];
    BOOL retval = [db executeUpdate:query];
    
    if (!retval) {
        NSLog(@"%@", [db lastErrorMessage]);
    }
    [db close];
    return retval;
}

//TODO: make this so it works with app id or patient record id
+(BOOL)setIsLive:(NSString *)patientIdentifier {
    [self clearIsLiveFlags];
    //if connection set live based on id
    //if no connection set live basedon appid
    //if no connection and no app id display alert
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    BOOL connectivity = [self checkConnectivity];
    if(connectivity){
        //NSString *appId = [self getAppIdFromPatientRecordId:patientRecordId];
        NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET IsLive = 1 WHERE Id = %@", patientIdentifier];
        BOOL retval = [db executeUpdate:query];
        if (!retval) {
            NSLog(@"Error updating isLive in PatientRecord's table");
            NSLog(@"%@", [db lastErrorMessage]);
        }
        NSLog(@"Set Active is returning: %d", retval);
        return retval;
    } else if (!connectivity){
        NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET IsLive = 1 WHERE AppId = %@", patientIdentifier];
        BOOL retval = [db executeUpdate:query];
        if (!retval) {
            NSLog(@"Error updating isLive in PatientRecord's table");
            NSLog(@"%@", [db lastErrorMessage]);
        }
        NSLog(@"Set Active is returning: %d", retval);
        return retval;
        
    }
    
    [db close];
    return 0;
}

+(NSString *)getAppIdFromPatientRecordId:(NSString *)patientRecordId {
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    /*get the app id associated with the patient record id*/
    NSString *query = [NSString stringWithFormat:@"SELECT AppId FROM PatientRecord WHERE Id = %@", patientRecordId];
    
    FMResultSet *result = [db executeQuery:query];
    [result next];
    NSString *appId = [result stringForColumnIndex:0];
    
    if (!result) {
        NSLog(@"Error updating isLive in PatientRecord's table");
        NSLog(@"%@", [db lastErrorMessage]);
    }
    
    [db close];
    NSLog(@"The app Id of the clicked cell is: %@", appId);
    return appId;
    
}
#pragma mark - Local Store Methods





/*-----------------Local Store Mega Method---------------------------*/

/*
 If it is the history view controller
 add patient and patient record
 add other data to
 */


-(BOOL)localStoreFromViewsToLocal:(NSNotification *)notification {
    
    
    NSDictionary *params = [notification userInfo];
    
    BOOL success;
    
    NSLog(@"In localStoreEverything");
    if ([[params objectForKey:@"viewName"] isEqualToString:@"historyViewController"]) {
        
        NSLog(@"attempting to add Patient to Local");
        success = [LocalTalk addNewPatientToLocal:params];
        if (!success) {
            [Utility alertWithMessage:@"Unable to add a patient."];
            return false;
        }
        NSLog(@"attempting to add Record to Local");
        success = [LocalTalk addPatientRecordToLocal:params];
        if (!success) {
            [Utility alertWithMessage:@"Unable to add patient record."];
            return false;
        }
    }
    NSLog(@"Exiting localStoreEverything");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataFromViewsStoredIntoLocal" object:self userInfo:nil];
    
    return true;
}

/*
 addPatient for historyViewController adding a new patient
 and for loading data into sqlite from server ?
 
 think about date created and date modified
 */
//TODO: addNewPatientToLocal: last modified and created neither stored in big nor little database
+(BOOL)addNewPatientToLocal:(NSDictionary *)params {
    NSString *firstName     = [params objectForKey:@"FirstName"];
    NSString *middleName    = [params objectForKey:@"MiddleName"];
    NSString *lastName      = [params objectForKey:@"LastName"];
    NSString *birthday      = [params objectForKey:@"Birthday"];

    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    [db open];
    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (FirstName, MiddleName, LastName, Birthday) VALUES (?, ?, ?, ?)", firstName, middleName, lastName, birthday];

    [db close];
    return retval;
}
/*
 Think about:  How / When do I add date created and last modified?
 */
//TODO: addNewPatientRecordToLocal: last modified and created neither stored in big nor little database
+(BOOL)addPatientRecordToLocal:(NSDictionary *)params {
    NSString *surgeryTypeId = [params objectForKey:@"SurgeryTypeId"];
    NSString *doctorId      = [params objectForKey:@"DoctorId"];
    NSString *hasTimeout    = [params objectForKey:@"HasTimeout"];
    NSString *isCurrent     = [params objectForKey:@"IsCurrent"];
    NSString *isLive        = [params objectForKey:@"IsLive"];
    NSString *Id            = [params objectForKey:@"Id"];
    BOOL retval;
    
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    
    NSString *AppPatientId = [self localGetAppPatientId];
    NSLog(@"PatientId: %@", AppPatientId);
    
    NSString *query;
    
    if (!Id) {
        query = [NSString stringWithFormat:@"INSERT INTO PatientRecord(SurgeryTypeId, DoctorId, HasTimeout, IsLive, IsCurrent, AppPatientId) VALUES (%@, %@, %@, %@, %@, %@)", surgeryTypeId, doctorId, hasTimeout, isLive, isCurrent, AppPatientId];
    }
    else {
        query = [NSString stringWithFormat:@"INSERT INTO PatientRecord(Id, SurgeryTypeId, DoctorId, HasTimeout, IsLive, IsCurrent, AppPatientId) VALUES (%@, %@, %@, %@, %@, %@, %@)", Id, surgeryTypeId, doctorId, hasTimeout, isLive, isCurrent, AppPatientId];
    }
    
    retval = [db executeUpdate:query]; 
    [db close];
    return retval;
}

//TODO: inserts vs updates?
//TODO: error handling
+(BOOL)addToLocalTable:(NSString *)tableName withData:(NSMutableArray *)tableData {
    BOOL retval;
    BOOL success;
    NSMutableString *sql;
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    
    //TODO: this could be more efficient
    
    retval = TRUE;
    for(NSDictionary* row in tableData){
        sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (%@) VALUES ('%@')",
               tableName,
               [[row allKeys] componentsJoinedByString:@", "],
               [[row allValues] componentsJoinedByString:@"', '"]];
    
        success = [db executeUpdate:sql];
        if(!success){
            retval = FALSE;
            //unsuccessful, error handling goes here
        }
    }
    
    //    NSString *firstName     = [params objectForKey:@"FirstName"];
    //    NSString *middleName    = [params objectForKey:@"MiddleName"];
    //    NSString *lastName      = [params objectForKey:@"LastName"];
    //    NSString *birthday      = [params objectForKey:@"Birthday"];
    //    NSLog(@"FirstName: %@ MiddleName: %@ LastName: %@ Birthday: %@", firstName, middleName, lastName, birthday);
    //    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    //
    //    [db open];
    //    BOOL retval = [db executeUpdate:@"INSERT INTO Patient (FirstName, MiddleName, LastName, Birthday) VALUES (?, ?, ?, ?)", firstName, middleName, lastName, birthday];
    //
    //    /*-----------error checking ---------*/
    //
    //    FMResultSet *result = [db executeQuery:@"Select * FROM Patient WHERE FirstName = ?", firstName];
    //    if (!result) {
    //        NSLog(@"failed to retrieve patient info");
    //        [db lastErrorMessage];
    //    }
    //    [result next];
    //    NSLog(@"retrieved data: %@", [result stringForColumn:@"FirstName"]);
    //
    //    /*-----------error checking ---------*/
    //
    //    [db close];
    
    return retval;
}


/*-------------------End Local Store Mega Method---------------------*/




/*-------------------Begin Local Database Accessor Methods---------------------*/

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
    return [self localGetId:query];
}
/*TODO: CHANGE THIS FUNCTIONS NAME */
+(NSString *)localGetAppPatientId {
    
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT MAX(rowid) FROM Patient"];
    return [self localGetId:query];
}

+(NSString *)localGetPatientRecordAppId {
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT AppId FROM PatientRecord WHERE IsLive = 1"];
    return [self localGetId:query];
}

+(NSString *)localGetPatientAppId {
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT AppPatientId FROM PatientRecord WHERE IsLive = 1"];
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
    return str;
}


/*---------------------------------------------------------------------------
 Summary:
 Helper methods for retrieving patientId and recordId from local database
 
 selectAllFromTable  -- Returns all the fields from the table in a dictionary
 tableUnsynced       -- Returns whether the table is synced or unsynced
 Details:
 
 Returns:
 
 TODO:  test that selectAllFromTable gets values and doesn't fail on nil
 test that tableUnsynced returns correct value for tables with one row
 -test that tableUnsynced returns correct value for tables with multiple rows
 select count(rowid) where unsynced if > 1
 *---------------------------------------------------------------------------*/

+(NSMutableArray *)selectAllFromTable:(NSString *)table {
    NSMutableArray *arrayOfKeysAndValues = [[NSMutableArray alloc] init];
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    FMResultSet *results;
    NSString *query;
    [db open];
    if ([table isEqualToString:@"PatientRecord"]) {
        query = [NSString stringWithFormat:@"Select * FROM %@ WHERE IsLive = 1", table];
        NSLog(@"%@", query);
        results = [db executeQuery:query];
    }
    else {
        query = [NSString stringWithFormat:@"SELECT a.* FROM %@ a, PatientRecord rec WHERE a.AppId = rec.AppPatientId and rec.IsLive = 1", table];
        NSLog(@"%@", query);
        results = [db executeQuery:query];
    }
    if (!results) {
        NSLog(@"failed to select all from tables: %@", [db lastErrorMessage]);
    }
    while ([results next]) {
        //NSLog(@"here");
        [arrayOfKeysAndValues addObject:[results resultDictionary]];
    }
    NSLog(@"In selectAllFromTable: %@", arrayOfKeysAndValues);
    [db close];
    return arrayOfKeysAndValues;
}

+(BOOL)tableUnsynced:(NSString *)table {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    FMResultSet *results;
    [db open];
    NSLog(@"Checking if %@ is Synced", table);
    NSString *query = [NSString stringWithFormat:@"SELECT count(AppId) FROM %@ WHERE LastModified > LastSynced", table];
    results = [db executeQuery:query];
    if (!results) {
        NSLog(@"%@",[db lastErrorMessage]);
        [Utility alertWithMessage:@"tableUnsynced failed"];
        NSLog(@"tableUnsynced failed for: %@", table);
        return false;
    }
    [results next];
    int count = [results intForColumnIndex:0];
    if (count > 0) {
        return true;
    }
    return false;
}


/*-------------------End Local Database Accessor Methods---------------------*/

/*-------------------Begin Local Database Mutator Methods---------------------*/

+(BOOL)insertValue:(NSString *)value intoColumn:(NSString *)column inLocalTable:(NSString *)table {
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES %@", table, column, value];
    BOOL result = [db executeUpdate:query];
    [db close];
    return result;
}


/*-------------------End Local Database Mutator Methods---------------------*/



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
    NSMutableArray *patients = [[NSMutableArray alloc] init];
    NSString *firstName, *lastName, *patientId, *imageId, *middleName, *recordId, *birthday, *complaint, *PatientRecordAppId;
    NSURL *pictureURL;
    UIImage *picture;
    //check for connectivity to the Server
    BOOL connectivity = [self checkConnectivity];
    NSLog(@"Connectivity in localGetPatientList is: %d",connectivity);
    
    if(connectivity){
        
        patientsArrayFromDB = [DBTalk getPatientList];
        
        for(NSDictionary *item in patientsArrayFromDB){
            //NSLog(@"%@", item);
            firstName   = [item objectForKey:@"FirstName"];
            middleName  = [item objectForKey:@"MiddleName"];
            lastName    = [item objectForKey:@"LastName"];
            patientId   = [item objectForKey:@"Id"];
            recordId    = [item objectForKey:@"recordId"];
            birthday    = [item objectForKey:@"Birthday"];  //does this exist?
            complaint   = [item objectForKey:@"SurgeryTypeId"];
            complaint   = [AdminInformation getSurgeryNameById:complaint];
            imageId     = [NSString stringWithFormat:@"%@n000", patientId];
            PatientRecordAppId = nil;
            pictureURL = [DBTalk getThumbFromServer:imageId];
            
            Patient *obj = [[Patient alloc] initWithPatientId:patientId currentRecordId:recordId patientRecordAppId:PatientRecordAppId firstName:firstName MiddleName:middleName LastName:lastName birthday:birthday ChiefComplaint:complaint PhotoID:picture PhotoURL:pictureURL];
            
            obj.patientId = patientId;
            NSLog(@"%@", picture);
            NSLog(@"%@", imageId);
            [patients addObject:obj];
        }
        
        return patients;
        
    } else if(!connectivity){
        //get patients from Local
        //when we return this list we return an app id as one of the deally bobs
        NSMutableArray *patientsArrayFromSQLite = [self localGetPatientListFromSQLite];
        for(NSDictionary *item in patientsArrayFromSQLite){
            //NSLog(@"%@", item);
            firstName   = [item objectForKey:@"FirstName"];
            middleName  = [item objectForKey:@"MiddleName"];
            lastName    = [item objectForKey:@"LastName"];
            patientId   = [item objectForKey:@"Id"];
            recordId    = [item objectForKey:@"RecordId"];
            PatientRecordAppId = [item objectForKey:@"PatientRecordAppId"];
            birthday    = [item objectForKey:@"Birthday"];  //does this exist?
            complaint   = [item objectForKey:@"Name"];
            imageId     = [NSString stringWithFormat:@"%@n000", patientId];
            pictureURL = [DBTalk getThumbFromServer:imageId];
            
            Patient *obj = [[Patient alloc] initWithPatientId:patientId currentRecordId:recordId patientRecordAppId:PatientRecordAppId firstName:firstName MiddleName:middleName LastName:lastName birthday:birthday ChiefComplaint:complaint PhotoID:picture PhotoURL:pictureURL];
            
            obj.patientId = patientId;
            NSLog(@"%@", picture);
            NSLog(@"%@", imageId);
            [patients addObject:obj];
        }
        return patients;
    }
    
    NSLog(@"Something is really broken so localGetPatientList returned NULL");
    return NULL;
    
}


+(NSMutableArray *)localGetPatientListFromSQLite {
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    NSString *query = [NSString stringWithFormat: @"SELECT a.Id, a.FirstName, a.MiddleName, a.LastName, a.Birthday, b.AppId as PatientRecordAppId, b.Id as RecordId, b.SurgeryTypeId, b.DoctorId, b.IsLive, b.IsCurrent, c.Name FROM patient as a JOIN patientRecord as b ON b.apppatientid = a.appid JOIN surgeryType as c on b.SurgeryTypeId = c.id"];
    
    FMResultSet *result = [db executeQuery:query];
    
    if (!result) {
        NSLog(@"The query in localGetPatientListFromSQLite didn't return anything good :(");
        NSLog(@"%@", [db lastErrorMessage]);
    }
    while([result next]){
        NSDictionary *dict = [result resultDictionary];
        [retval addObject:dict];
    }
    
    [db close];
    return retval;
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
    return false;
    
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


@end







