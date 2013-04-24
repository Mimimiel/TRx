//
//  LocalTalk.m
//  TRx
//
//  Created by John Cotham on 3/10/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "LocalTalk.h"
#import "DBTalk.h"
#import "Base64.h"

#import "Utility.h"
#import "SynchData.h"
#import "AdminInformation.h"

@implementation LocalTalk


static LocalTalk *singleton;
static FMDatabase *db;
static FMDatabaseQueue *queue;
+(void)initialize{
    
    static BOOL initialized = false;
    if (!initialized)
    {
        initialized = true;
        singleton = [[LocalTalk alloc] init];
        db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
        [db open];
        queue = [FMDatabaseQueue databaseQueueWithPath:[Utility getDatabasePath]];
    }
}

+(LocalTalk *)getSingleton {
    return singleton;
}
+(FMDatabase *)getDb {
    return db;
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
+(NSMutableDictionary *)getData:(NSDictionary *)params {
    NSLog(@"----------I'm inside getData-------------");
    NSString *selectorValue, *selectorType, *query, *localPatientId, *localPatientRecordId;
    NSDictionary *dict;
    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
    BOOL useSelector = 1;
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    localPatientId = [self localGetPatientAppId];
    localPatientRecordId = [self localGetPatientRecordAppId];
    NSMutableArray *tableNames = [params objectForKey:@"tableNames"];
    //check for current patient, if none, return nil
    
    
    for(NSString *table in tableNames){
        //check if it's Doctor, surgery type, or patient and if it is those have special keys
        //otherwise, use patient record id
        //to insert (if it doesn't exist or update if it does
        NSLog(@"table: %@", table);
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
            selectorType = @"AppPatientRecordId";
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
            while([retval next]){
                dict = [retval resultDictionary];
                [tmpArray addObject:dict];
            }
            [dictionary setObject:tmpArray forKey:table];
        }
    }
    
    NSLog(@"----------I'm leaving get data------------");
    return dictionary;
    
}

+(BOOL)clearIsLiveFlags {
    //this will go to the database and set all the is live flags to 0
    
    
    /*FIX THIS WILLIE YOURE WORKING HERE*/
    NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET IsLive = 0"];
    BOOL retval = [db executeUpdate:query];
    
    if (!retval) {
        NSLog(@"%@", [db lastErrorMessage]);
    }
    return retval;
}

//TODO: make this so it works with app id or patient record id
+(BOOL)setIsLive:(NSString *)patientIdentifier {
    [self clearIsLiveFlags];
    //if connection set live based on id
    //if no connection set live basedon appid
    //if no connection and no app id display alert
    
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
    
    return 0;
}

+(NSString *)getAppIdFromPatientRecordId:(NSString *)patientRecordId {
    
    /*get the app id associated with the patient record id*/
    NSString *query = [NSString stringWithFormat:@"SELECT AppId FROM PatientRecord WHERE Id = %@", patientRecordId];
    
    FMResultSet *result = [db executeQuery:query];
    [result next];
    NSString *appId = [result stringForColumnIndex:0];
    
    if (!result) {
        NSLog(@"Error updating isLive in PatientRecord's table");
        NSLog(@"%@", [db lastErrorMessage]);
    }
    
    NSLog(@"The app Id of the clicked cell is: %@", appId);
    return appId;
    
}
#pragma mark - Local Store Methods



+(BOOL)storeMutableArrayFromAdmin:(NSMutableArray *)adminArray  inTable:(NSString *)tableName{
    
    /*get the app id associated with the patient record id*/
    for (NSInteger i = 1; i < adminArray.count; i++){
        NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ (Id, Name) VALUES (%d,%@)",tableName, i, [adminArray objectAtIndex:i]];
        NSLog(@"%@", query);
        FMResultSet *result = [db executeQuery:query];
        [result next];
        NSString *appId = [result stringForColumnIndex:0];
        
        if (!result) {
            NSLog(@"Error updating isLive in PatientRecord's table");
            NSLog(@"%@", [db lastErrorMessage]);
        }
        
    }
    
    //NSLog(@"The app Id of the clicked cell is: %@", appId);
    return 0;
}


/*-----------------Local Store Mega Method---------------------------*/


-(BOOL)localStoreFromViewsToLocal:(NSNotification *)notification {
    
    
    NSDictionary *params = [notification userInfo];
    NSMutableArray* paramsArray, *returnArray;
    NSMutableDictionary *mutableParams;
    NSArray *fields;
    paramsArray = [[NSMutableArray alloc] init];
    NSLog(@"In localStoreEverything");
    if ([[params objectForKey:@"viewName"] isEqualToString:@"historyViewController"]) {
        
        NSLog(@"attempting to add Patient to Local");
        /*
         * Add a patient
         */
        fields = [NSArray arrayWithObjects:@"FirstName", @"MiddleName", @"LastName", @"Birthday", nil];
        paramsArray = [Utility repackDictionaryForSetSQLiteTable:params keyList:fields];
        returnArray = [LocalTalk setSQLiteTable:@"Patient" withData:paramsArray];
        
        if (!returnArray || [[[returnArray objectAtIndex:0] stringValue] isEqualToString:@"0"]) {
            [Utility alertWithMessage:@"Unable to add a patient."];
            NSLog(@"Unable to add a patient");
            return false;
        }
        /*
         * Add a record, packing AppPatientId back into params
         */
        
        mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
        [mutableParams setObject:[returnArray objectAtIndex:0] forKey:@"AppPatientId"];
        
        fields = [NSArray arrayWithObjects:@"SurgeryTypeId", @"DoctorId", @"HasTimeout", @"IsCurrent", @"IsLive", @"Id", @"AppPatientId", nil];
        paramsArray = [Utility repackDictionaryForSetSQLiteTable:mutableParams keyList:fields];
        
        
        NSLog(@"attempting to add Record to Local");
        returnArray = [LocalTalk setSQLiteTable:@"PatientRecord" withData:paramsArray];
        if (!returnArray) {
            [Utility alertWithMessage:@"Unable to add patient record."];
            NSLog(@"Unable to add patient record");
            return false;
        }
        
        /*
         * Insert Image into Local Database
         */
        NSMutableDictionary *imageDic = [[NSMutableDictionary alloc] init];
        
        //encode image as text
        
        
        //use date as image name and path
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *now = [dateFormatter stringFromDate:[NSDate date]];
        
        imageDic[@"Name"]               = now;
        imageDic[@"Path"]               = now;
        imageDic[@"IsProfile"]          = @"1";
        imageDic[@"Data"]               = params[@"Data"];
        imageDic[@"AppPatientRecordId"] = [returnArray objectAtIndex:0];
        imageDic[@"RecordTypeId"]       = [AdminInformation getOperationRecordTypeIdByName:@"Picture"];
        
        paramsArray[0] = imageDic;
        
        
        returnArray = [LocalTalk setSQLiteTable:@"OperationRecord" withData:paramsArray];
        if (!returnArray) {
            [Utility alertWithMessage:@"Unable to add image to OperationRecords"];
            NSLog(@"Unable to add image to OperationRecords");
        }
    }
    else if ([[params objectForKey:@"viewName"] isEqualToString:@"summaryViewController"]) {
        
        //load patient data from the server
        
    }
    else if ([[params objectForKey:@"viewName"] isEqualToString:@"questionView"]) {
        /*
         * add question to sqlite. 
         */
        
        //check for AppId and pass if not nil
        NSString *query = [NSString stringWithFormat:@"SELECT AppId FROM History WHERE QuestionId = \"%@\" AND AppPatientRecordId = %@", params[@"QuestionId"], params[@"AppPatientRecordId"]];
        
        FMResultSet *results = [db executeQuery:query];
        if (!results) {
            NSLog(@"The query %@ didn't return anything good :(", query);
            NSLog(@"%@", [db lastErrorMessage]);
            //[Utility alertWithMessage:@"Error retrieving question's AppId"];
            return false;
        }
        [results next];
        NSString *appId = [NSString stringWithFormat:@"%d", [results intForColumnIndex:0]];
        if (!appId) {
            appId = @"0";
        }
        mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
        mutableParams[@"AppId"] = appId;
        
        fields = [NSArray arrayWithObjects:@"QuestionId", @"Value", @"AppId", @"AppPatientRecordId", nil];
        
        [paramsArray removeAllObjects];
        paramsArray  = [Utility repackDictionaryForSetSQLiteTable:mutableParams keyList:fields];
        NSLog(@"%@", paramsArray);
        returnArray = [LocalTalk setSQLiteTable:@"History" withData:paramsArray];
        if (!returnArray) {
            [Utility alertWithMessage:@"Error setting question"];
        }
    }
    
    NSLog(@"Exiting localStoreEverything");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataFromViewsStoredIntoLocal" object:self userInfo:nil];
    
    return true;
}

/*-----------------------------------------------------------------------
 Methods are helpers for LocalStoreFromViewsToLocal
 -
 -
 -
 ------------------------------------------------------------------------*/




/*----------------End Helpers for LocalStoreFromViewsToLocal-------------*/



/*-----------------------------------------------------------------------
 Method: setSQLiteTable withData
 Returns:
    NSMutableArray where each index holds the primary key for each row
    tableName: name of the table you want to insert or update
    tableData: data you want to insert/update
        each index in the array is a row to insert/update into the table
        each row can look like whatever (i.e. don't have to be identical)
 Summary: insert or update rows into any table in the local database
 each row can look like whatever (i.e. don't have to be identical)
 Summary: insert rows into some table in the local database
 //TODO: inserts vs updates? i.e. should this also handle updates
 //TODO: error handling
 -----------------------------------------------------------------------*/
+(NSMutableArray*)setSQLiteTable:(NSString *)tableName withData:(NSMutableArray *)tableData {
    BOOL success;
    NSMutableArray* returnIDs = [[NSMutableArray alloc] init];
    NSMutableArray* updateSQL = [[NSMutableArray alloc] init];
    NSMutableArray* insertSQL = [[NSMutableArray alloc] init];
    NSInteger affectedID;
    NSMutableString* appID;
    NSMutableString *sql;
    BOOL defaultFlag = FALSE;
    NSArray* defaults = @[@"Doctor", @"SurgeryType", @"RecordType"];
    FMResultSet *exists;
    
    //TODO: clean up this logic somewhat
    
    //Slightly different logic for default/admin type tables
    if([defaults containsObject:tableName]){
        defaultFlag = TRUE;
    }
    
    for(NSDictionary* row in tableData){
        affectedID = 0;
        success = FALSE;
        [updateSQL removeAllObjects];
        appID = row[@"AppId"];
        
        if(appID != nil && ![appID isEqualToString:@""] && ![appID isEqualToString:@"0"]){
            //UPDATE non-default table
            for(NSString* key in row){
                if(![key isEqualToString:@"AppId"]){
                    sql = [NSMutableString stringWithFormat: @"%@ = '%@'", key, row[key]];
                    [updateSQL addObject:sql];
                }
            }
            
            sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ WHERE AppId = '%@'",
                   tableName,
                   [updateSQL componentsJoinedByString:@", "],
                   appID];
                
            success = [db executeUpdate:sql];
            if(success){
                affectedID = [appID integerValue];
            }
        }
        else{
            if(defaultFlag){
                //go ahead and try to UPDATE default table, it's alright if it fails
                sql = [NSMutableString stringWithFormat:@"SELECT EXISTS(SELECT 1 FROM %@ WHERE Id = '%@' LIMIT 1);", tableName, row[@"Id"]];
                exists = [db executeQuery:sql];
                [exists next];
                if([[exists stringForColumnIndex:0] isEqualToString:@"1"]){
                    for(NSString* key in row){
                        if(![key isEqualToString:@"Id"]){
                            sql = [NSMutableString stringWithFormat: @"%@ = '%@'", key, row[key]];
                            [updateSQL addObject:sql];
                        }
                    }
                    
                    sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ WHERE Id = '%@'",
                           tableName,
                           [updateSQL componentsJoinedByString:@", "],
                           row[@"Id"]];
                    
                    success = [db executeUpdate:sql];
                    if(success){
                        affectedID = [row[@"Id"] integerValue];
                    }
                }
            }
            
            if(!success){
                //INSERT
                [updateSQL removeAllObjects];
                [insertSQL removeAllObjects];
                
                for(NSString* key in row){
                    if(![key isEqualToString:@"AppId"]){
                        sql = [NSMutableString stringWithFormat: @"%@", key];
                        [insertSQL addObject:sql];
                        
                        sql = [NSMutableString stringWithFormat: @"%@", row[key] ];
                        [updateSQL addObject:sql];
                    }
                }
                
                sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ (%@) VALUES ('%@')",
                       tableName,
                       [insertSQL componentsJoinedByString:@", "],
                       [updateSQL componentsJoinedByString:@"', '"]];
            
                success = [db executeUpdate:sql];
                if(success){
                    affectedID = [db lastInsertRowId];
                }
            }
        }
        
        [returnIDs addObject:[NSNumber numberWithInteger:affectedID]];
    }
    
    if([tableName isEqualToString:@"Doctor"]){
        sql = [NSMutableString stringWithFormat: @"SELECT * FROM Doctor WHERE FirstName = 'David'"];
        FMResultSet *retval = [db executeQuery:sql];
        [retval next];
        NSLog([NSString stringWithFormat:@"%@", [retval stringForColumn:@"FirstName"]]);
    }
    return returnIDs;
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
    //Get Patient.Id (patient server identifier) from Local for the IsLive PatientRecord
    NSString *query;
    query = [NSString stringWithFormat:
             @"SELECT b.Id as Id FROM PatientRecord as a JOIN Patient as b ON a.AppPatientId = b.AppId WHERE a.IsLive = 1"];
    //query = @"SELECT Id FROM PatientRecord"
    //query = @"SELECT pat.Id FROM PatientRecord rec, Patient pat WHERE rec.AppPatientId = pat.AppId AND rec.IsLive = 1";
    return [self localGetId:query];
}
+(NSString *)localGetPatientRecordId {
    //Get PatientRecord.Id (patient record server identifier) for the IsLive PatientRecord
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT Id FROM PatientRecord WHERE IsLive = 1"];
    return [self localGetId:query];
}
/*TODO: CHANGE THIS FUNCTIONS NAME */
+(NSString *)localGetAppPatientId {
    //Get Patient.AppId (patient local identifier) for the most recently inserted Patient
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT MAX(rowid) FROM Patient"];
    return [self localGetId:query];
}

+(NSString *)localGetPatientRecordAppId {
    //Get PatientRecord.AppId (patient record local identifier) for the IsLive PatientRecord
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT AppId FROM PatientRecord WHERE IsLive = 1"];
    return [self localGetId:query];
}

+(NSString *)localGetPatientAppId {
    //Get PatientRecord.AppPatientId (patient local identifier) for the IsLive PatientRecord
    NSString *query;
    query = [NSString stringWithFormat:@"SELECT AppPatientId FROM PatientRecord WHERE IsLive = 1"];
    return [self localGetId:query];
}

+(NSString *)localGetId:(NSString *)query {
    
    db.logsErrors = TRUE;
    
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
    
    FMResultSet *results;
    NSString *query;
    
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
    return arrayOfKeysAndValues;
}

+(BOOL)tableUnsynced:(NSString *)table {
    
    FMResultSet *results;
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
//TODO: Will not work for PatientRecord ?? Need another query

+(BOOL)insertValue:(NSString *)value intoColumn:(NSString *)column inLocalTable:(NSString *)table {
    
    NSString *query = [NSString stringWithFormat:@"INSERT INTO %@ a, PatientRecord rec (a.%@) VALUES %@ WHERE a.AppId = rec.AppId and IsLive = 1", table, column, value];
    NSLog(@"InsertValue query: %@", query);
    
    
    BOOL result = [db executeUpdate:query];
    return result;
}

//FIXME: This is the method that fails


+(BOOL)insertPatientId:(NSString *)patientId
          forFirstName:(NSString *)firstName
              lastName:(NSString *)lastName
              birthday:(NSString *)birthday {
    
    

        NSString *query = [NSString stringWithFormat:@"UPDATE Patient SET Id = %@ WHERE FirstName = \"%@\" and LastName = \"%@\" and Birthday = \"%@\"", patientId, firstName, lastName, birthday];
        
        NSLog(@"QUERY: %@", query);
        
        BOOL result = [db executeUpdate:query];
        [db lastErrorMessage];
        



    
    //    NSString *testquery = [NSString stringWithFormat:@"SELECT * FROM Patient WHERE FirstName = \"%@\" and LastName = \"%@\" and Birthday = \"%@\"", firstName, lastName, birthday];
    //    NSLog(@"printing testquery: %@", testquery);
    //    NSLog(@"ATTEMPTING TO INSERT PATIENT ID: %@", patientId);
    //    FMResultSet *results = [db executeQuery:testquery];
    //    if (!results) {
    //        NSLog(@"db error!! : %@", [db lastErrorMessage]);
    //    }
    //    while ([results next]) {
    //        NSLog(@"COUNT OF ROWS (SHOULD BE 1): %@,", [results stringForColumn:@"Id"]);
    //    }
    
    
    //NSLog(@"Result of inserting patientId: %@  %d query: %@", patientId, result, query);
    
    return result;
}
//FIXME: INSERT_RECORD_ID this doesn't work

+(BOOL) insertRecordId:(NSString *)recordId {
    NSString *patientId = [LocalTalk localGetPatientId];
    //could search for isLive
    NSString *query = [NSString stringWithFormat:@"UPDATE PatientRecord SET Id = \"%@\" WHERE AppPatientId = \"%@\"", recordId, patientId];
    
    NSLog(@"QUERY: %@", query);
    
    return [db executeUpdate:query];
    
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
    
    return [db executeUpdate:@"INSERT INTO Patient (QuestionId, Value, Synched) VALUES (?, ?, 0)", questionId, value];
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
    
    BOOL retval = [db executeUpdate:@"INSERT OR REPLACE INTO Images (imageType, imageBlob) VALUES (?,?)", @"portrait", imageData];
    
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
+(BOOL)localStoreAudio:(NSData *)audioData withAppPatientRecordId:(NSString *)appPatientRecordId andRecordTypeId:(NSString *)recordTypeId andfileName:(NSString *)fileName andPath:(NSString *)pathToAudio {
    
    BOOL isProfile = 0;
    BOOL retval = [db executeUpdate:@"INSERT INTO OperationRecord (AppPatientRecordId, RecordTypeId, Name, Path, IsProfile, Created, LastModified, LastSynced, Data) VALUES (?, ?, ?, ?, ?, ?, ?)", appPatientRecordId, recordTypeId, fileName, pathToAudio, isProfile, audioData];
    
    if (!retval) {
        NSLog(@"%@", [db lastErrorMessage]);
    }
    return retval;
}

#pragma mark - Local Get Methods
+(NSString *)getOperationRecordTypeIdByNameFromSQLite:operationRecordTypeName{

    NSString *query = [NSString stringWithFormat: @"SELECT Id FROM RecordType WHERE Name = '%@'", operationRecordTypeName];
    NSLog(@"%@", query);
    FMResultSet *result = [db executeQuery:query];
    [result next];
    
    if (!result) {
        NSLog(@"The query in localGetPatientListFromSQLite didn't return anything good :(");
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    NSString *retval = [result stringForColumnIndex:0];
    
    return retval;
}

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
    
    return retval;
}

+(NSMutableDictionary *)localGetOperationRecordInfoByName:(NSString *)name {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM OperationRecord WHERE Name = \"%@\"", name];
    NSDictionary *dict;
    FMResultSet *results = [db executeQuery:query];
    if (!results) {
        NSLog(@"The query in localGetPatientListFromSQLite didn't return anything good :(");
        NSLog(@"%@", [db lastErrorMessage]);
    }
    while([results next]){
        dict = [results resultDictionary];
    }
    
    NSMutableDictionary *retDic = [[NSMutableDictionary alloc] initWithDictionary:dict];
    
    return retDic;
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

    
    NSString *query = [NSString stringWithFormat:@"Select op.Data from OperationRecord op JOIN PatientRecord pr ON op.AppPatientRecordId = pr.AppId WHERE pr.IsLive = 1"];
    
    FMResultSet *results = [db executeQuery:query];
    if (!results) {
        NSLog(@"Error retrieving image\n");
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    [results next];
    NSString *dataStr = [results stringForColumnIndex:0];
    NSData *data = [Base64 decode:dataStr];
    
    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        NSLog(@"In localGetPortrait: image is NULL");
        return nil;
    }
    return image;
}


+(NSData*)localGetAudio:(NSString *)fileName {
    
    FMResultSet *results = [db executeQuery:@"SELECT Data FROM Audio WHERE Name = ?", fileName];
    
    if (!results) {
        NSLog(@"Error retrieving image\n");
        NSLog(@"%@", [db lastErrorMessage]);
        return nil;
    }
    [results next];
    NSData *data = [results dataForColumnIndex:0];
    return data;
}





#pragma mark - Clear Patient Data

/*---------------------------------------------------------------------------
 * clears local patient data. Needs to be called before new Patient data inserted
 * no retval
 *---------------------------------------------------------------------------*/
+(void)localClearPatientData {
    [db executeUpdate:@"DELETE FROM Images"];
    [db executeUpdate:@"DELETE FROM Patient"];
    [db executeUpdate:@"DELETE FROM PatientMetaData"];
    [db executeUpdate:@"DELETE FROM Audio"];
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
        NSLog(@"%@", dataArr);
        for (NSDictionary *dic in dataArr) {
            NSString *questionId = [dic objectForKey:@"Key"];
            NSString *value = [dic objectForKey:@"Value"];
            
            success = [db executeUpdate:@"INSERT INTO Patient (QuestionId, Value, Synched) VALUES (?, ?, 1)", questionId, value];
            if (!success) {
                NSLog(@"Unable to add: %@", [db lastErrorMessage]);
                
            }
        }
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
        retval = [db executeUpdate:@"INSERT INTO Images (Synched) VALUES (1)"];
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


+(NSMutableArray *)localGetUnsyncedRecordsFromTable:(NSString *)table {
    NSString *query;
    if (![table isEqualToString:@"Patient"] && ![table isEqualToString:@"PatientRecord"]) {
        query = [NSString stringWithFormat:@"Select t.*, p.Id AS PatientId, r.Id AS PatientRecordId FROM %@ t, Patient p, PatientRecord r WHERE t.LastModified > t.LastSynced and t.AppPatientRecordId = r.AppId and r.AppPatientId = p.AppId", table];
    }
    else {
        query = [NSString stringWithFormat:@"Select * FROM %@ WHERE LastModified > LastSynced", table];
    }
    NSMutableArray *array = [[NSMutableArray alloc] init];
    FMResultSet *results = [db executeQuery:query];
    if (!results) {
        //errors
    }
    while ([results next]) {
        [array addObject:[results resultDictionary]];
        
    }
    return array;
}


/*---------------------------------------------------------------------------
 Summary:
 Helper method for testing. Prints Patient data from localDatabase
 *---------------------------------------------------------------------------*/
+(void)printLocal {
    NSString *key, *value;
    
    FMResultSet *results = [db executeQuery:@"SELECT * FROM Patient"];
    while ([results next]) {
        key   = [results stringForColumn:@"QuestionId"];
        value = [results stringForColumn:@"Value"];
        NSLog(@"Key: %@  Value: %@", key, value);
    }
}


@end







