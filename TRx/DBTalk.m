//
//  DBTalk.m
//  TRx
//
//  Created by John Cotham on 2/24/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "DBTalk.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "NZURLConnection.h"
#import "Utility.h"
#import "LocalTalk.h"
#import <UIKit/UIKit.h>

@implementation DBTalk

static NSString *host = nil;
static NSString *imageDir = nil;
static NSString *dbPath = nil;
static BOOL connectivity = false;
static Reachability *internetReachable = nil;
static DBTalk *singleton;


+(void)initialize {
    
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addUpdatePatientRecord) name:@"patientAdded" object:nil];
    
    static BOOL initialized = false;
    if (!initialized)
    {
        host = @"http://www.teamecuadortrx.com/TRxTalk/index.php/";
        imageDir = @"http://teamecuadortrx.com/TRxTalk/Data/images/";
        dbPath = [Utility getDatabasePath];
        
        initialized = true;
        singleton = [[DBTalk alloc] init];
    }
}

+(DBTalk *)getSingleton {
    return singleton;
}

+(BOOL)getConnectivity {
    return connectivity;
}

+(void)checkReachability {
    NSLog(@"IN here checking reachability");
    internetReachable = [Reachability reachabilityWithHostname:@"www.teamecuadortrx.com"];
    NetworkStatus netStatus = [internetReachable currentReachabilityStatus];
    if(netStatus == ReachableViaWiFi){
        connectivity = (netStatus==ReachableViaWiFi);
    } else {
        connectivity = 0;
    }
}



-(void)pushLocalUnsyncedToServer {
    
    BOOL patientUnsynced    = [LocalTalk tableUnsynced:@"Patient"];
    BOOL recordUnsynced     = [LocalTalk tableUnsynced:@"PatientRecord"];
    NSString *patientId     = [LocalTalk localGetPatientId];
    NSString *recordId      = [LocalTalk localGetPatientRecordId];
    
    if (!patientId || patientUnsynced) {
        [DBTalk addUpdatePatient];            //needs to call addRecord in callback
    }
    else if ((patientId && !recordId) || recordUnsynced) {
        [DBTalk addUpdatePatientRecord];
    }
    
    //check if each record is unsynced
    //if unsynced,
    //get all records from table wherey last mod > last synced
    
    
    //FIXME this is going to push every time until everything is working and syncing
    //Find a work-around for short-term (only push on own tab?????)
    
    NSMutableArray *array = [LocalTalk localGetUnsyncedRecordsFromTable:@"OperationRecord"];
    
    //FIXME this is only getting the current patient's ID; I need Id for any unsynced image
    patientId     = [LocalTalk localGetPatientId];
    NSString *recordTypeId, *patientRecordId;
    if (array) {
        for (NSDictionary *dic in array) {
            recordTypeId = [NSString stringWithFormat:@"%@", dic[@"RecordTypeId"]];
            patientId = dic[@"PatientId"];
            patientRecordId = dic[@"PatientRecordId"];
            
            if (!patientId || !patientRecordId) {
                NSLog(@"Skipping sync picture");
                continue;
            }
            //need to get patient ID for each person
            //need to get picture for each person
            
            if([recordTypeId isEqualToString:@"3"]){
                NSLog(@"Attempting to add image for patientId: %@", patientId);
                [DBTalk uploadFileToServer:[LocalTalk localGetPortrait] fileType:@"image" fileName:dic[@"Name"] patientId:patientId];
                
                [DBTalk pictureInfoToDatabase:dic];
                
                //[DBTalk call Mischa's method'];
                
                //need to set synced on return
            }
        }
    }
    
    
    //check if image is unsynced and push if unsynced
    //calls uploadFileToServer() use "image" and later ?? getOperationTypeRecordName
    
    
    //check if recordId is null
    NSLog(@"Exiting DBTalk's pushLocalUnsyncedToServer");
}



#pragma mark - Add Methods

//TODO I cannot for the life of me figure out why this is breaking
//Patients are successfully added to the database, and their patientId
//is returned so that I can store it in LocalDatabase. All goes well until
//I try to store into the LocalDatabase. Then I get errors.
//
//I have tested the method on SQLiteManager, and it works
//When running in the app, it fails
//
+(void)addUpdatePatient {
    NSLog(@"Entering addUpdatePatient");
    NSMutableArray *patientTableValuesArray    = [LocalTalk selectAllFromTable:@"Patient"];
    NSDictionary *patientTableValues    = [patientTableValuesArray objectAtIndex:0];
    NSLog(@"%@", patientTableValues);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@add/patient", host]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSString *firstName     = [patientTableValues objectForKey:@"FirstName"];
    NSString *middleName    = [patientTableValues objectForKey:@"MiddleName"];
    NSString *lastName      = [patientTableValues objectForKey:@"LastName"];
    NSString *patientId     = [patientTableValues objectForKey:@"Id"];
    NSString *birthday      = [patientTableValues objectForKey:@"Birthday"];
    
    
    NSString *params = [NSString stringWithFormat:
                        @"FirstName=%@&LastName=%@&MiddleName=%@&Birthday=%@&Id=%@", firstName, lastName, middleName, birthday, patientId];
    NSLog(@"params: %@", params);
    //encode params later
    NSData *data = [params dataUsingEncoding:NSUTF8StringEncoding];
    [request addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%i", [data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    //[[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSError *err = nil;
    NSURLResponse *response = nil;
    
    //This really should be thrown off into its own thread
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (!responseData) {
        NSLog(@"Adding patient failed");
    }
    if (err) {
        NSLog(@"Error in request: %@", err);
    }
    NSError *jsonError;
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];
    if (jsonError) {
        NSLog(@"JsonError: %@", jsonError);
    }
    NSString *retval = [jsonDic objectForKey:@"@returnValue"];
    NSLog(@"retval: %@", retval);
    if ([retval isEqual:@"0"]) {
        NSString *dbErr = [jsonDic objectForKey:@"@error"];
        NSLog(@"Error from DB: %@", dbErr);
    }
    else {
        //successfully returned patient
        
        //        BOOL success = [LocalTalk insertPatientId:retval forFirstName:[jsonDic objectForKey:@"FirstName"]
        //                          lastName:[jsonDic objectForKey:@"LastName"] birthday:[jsonDic objectForKey:@"Birthday"]];
        NSMutableArray *array = [[NSMutableArray alloc] init];
        NSMutableArray *retArray = [[NSMutableArray alloc] init];
        NSString *appId = [LocalTalk localGetPatientAppId];
        NSDictionary *dic = @{@"AppId": appId,
                              @"Id": retval};
        array[0] = dic;
        retArray = [LocalTalk setSQLiteTable:@"Patient" withData:array];
        
        //successfully stored patient?
        if ([appId isEqualToString:[NSString stringWithFormat:@"%@", retArray[0]]]) {
            [DBTalk addUpdatePatientRecord];
        }
        
    }
    
    
    
    //
    //
    //    NSURL *url =  [[NSURL alloc] initWithString:host];
    //    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    //
    //    [httpClient postPath:@"add/patient" parameters:patientTableValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
    //        NSLog(@"AddPatient successful");
    //
    //
    //        NSError *jsonError;
    //        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&jsonError];
    //        NSDictionary *dic = jsonDic;
    //        NSString *retval = [dic objectForKey:@"@returnValue"];
    //        if ([retval isEqualToString:@"0"]) {
    //            NSString *err = [dic objectForKey:@"error"];
    //            [Utility alertWithMessage:err];
    //            NSLog(@"error getting addPatient retval: %@", err);
    //        }
    //        else {
    //            BOOL success = [LocalTalk insertPatientId:retval forFirstName:[dic objectForKey:@"FirstName"]
    //                                             lastName:[dic objectForKey:@"LastName"] birthday:[dic objectForKey:@"Birthday"]];
    //            if (!success) {
    //                NSLog(@"Error adding patientId: %@", retval);
    //            }
    //        }
    //        [DBTalk addUpdatePatientRecord];
    //
    //    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    //        NSLog(@"AddPatient failed");
    //        NSLog(@"AddPatient error: %@", error);
    //    }];
    NSLog(@"Exiting addUpdatePatient");
    return;
}

+(void)addUpdatePatientRecord {
    
    //if patientRecord is NULL or table is unsynched, sync else return
    NSLog(@"Entering addUpdatePatientRecord");
    
    NSArray *recordTableValuesArray     = [LocalTalk selectAllFromTable:@"PatientRecord"];
    NSMutableDictionary *recordTableValues     = [recordTableValuesArray objectAtIndex:0];
    [recordTableValues setValue:@"0" forKey:@"HasTimeout"];
    
    NSString *patientId = [LocalTalk localGetPatientId];
    if (!patientId) {
        [Utility alertWithMessage:@"Error adding PatientRecord: No PatientId in Local database"];
        NSLog(@"Error adding PatientRecord: No PatientId in Local database");
    }
    NSLog(@"Printing patinetId in addUpdatePatientRecord: %@", patientId);
    
    [recordTableValues setValue:patientId forKey:@"PatientId"];
    //NSLog(@"%@", recordTableValues);
    
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    [httpClient postPath:@"add/patientRecord" parameters:recordTableValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"AddRecord successful");
        
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        NSString *retval = [dic objectForKey:@"@returnValue"];
        if ([retval isEqualToString:@"0"]) {
            NSString *err = [dic objectForKey:@"error"];
            [Utility alertWithMessage:err];
        }
        else {
            BOOL inserted = [LocalTalk insertRecordId:retval];
            if (!inserted) {
                NSLog(@"RecordId not inserted into Local. RecordId: %@", retval);
            }
        }
        NSLog(@"%@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"patientAdded" object:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"AddRecord failed");
    }];
}



+(NSString *)addRecordData:(NSString *)recordId
                       key:(NSString *)key
                     value:(NSString *)value {
    
    
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            recordId, @"recordId",
                            key, @"key",
                            value, @"value", nil];
    
    [httpClient postPath:@"add/patientHistoryKeyValue" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Request successful");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed");
    }];
    
    return NULL;
}

+(void)addRecoveryDataForRecord:(NSString *)recordId
                     recoveryId:(NSString *)recoveryId
                  bloodPressure:(NSString *)bloodPressure
                      heartRate:(NSString *)heartRate
                    respiratory:(NSString *)respiratory
                           sao2:(NSString *)sao2
                          o2via:(NSString *)o2via
                             ps:(NSString *)ps   {
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            recordId,       @"recordId",
                            recoveryId,     @"recoveryId",
                            bloodPressure,  @"bloodPressure",
                            heartRate,      @"heartRate",
                            respiratory,    @"respiratory",
                            sao2,           @"sa02",
                            o2via,          @"o2via",
                            ps,             @"ps", nil];
    
    [httpClient postPath:@"add/recoveryData" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Request successful");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed");
    }];
}

/*---------------------------------------------------------------------------
 * adds profile picture to server and info to database
 * returns: NULL on failure. pictureId otherwise
 *---------------------------------------------------------------------------*/

+(NSString *)addProfilePicture:(UIImage *)picture
                     patientId:(NSString *)patientId {
    
    return [self addPicture:picture
                  patientId:patientId
          customPictureName:@"NULL"
                  isProfile:@"1"
                  directory:@"portraits"];
}

/*---------------------------------------------------------------------------
 * description: method adds picture to server and puts path in database
 * pictureId: NULL if adding picture. pictureId as string if updating
 * isProfile: @"0" -- not profile picture. or @"1" -- is profile picture
 * returns NULL on failure. pictureId otherwise
 *---------------------------------------------------------------------------*/
+(NSString *)addPicture:(UIImage  *)picture
              patientId:(NSString *)patientId
      customPictureName:(NSString *)customPictureName
              isProfile:(NSString *)isProfile
              directory:(NSString *)directory {
    
    NSString *pictureId = nil;
    NSString *fileName = [self getNewPictureName:patientId];
    BOOL added = [self uploadPictureToServer:picture fileName:fileName directory:directory];
    
    if (!added) {
        NSLog(@"Error adding picture");
        return nil;
    }
    
    // pictureId = [self addPictureInfoToDatabase:patientId fileName:fileName isProfile:isProfile];
    NSLog(@"value of pictureId: %@", pictureId);
    return pictureId;
}

#pragma mark - Delete Patient Methods
/*---------------------------------------------------------------------------
 * deletes specified patient and associated records. returns true on success
 *---------------------------------------------------------------------------*/
+(BOOL)deletePatient: (NSString *)patientId {
    NSString *encodedString = [NSString stringWithFormat:@"%@delete/deletePatient/%@", host, patientId];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        NSString *retval = [dic objectForKey:@"@returnValue"];
        if ([retval isEqualToString:@"0"]) {
            NSString *err = [dic objectForKey:@"error"];
            [Utility alertWithMessage:err];
            return false;
        }
        return true;
    }
    NSLog(@"Delete call didn't work: error in PHP");
    return false;
}

#pragma mark - Get Methods

/*---------------------------------------------------------------------------
 * description: queries database for a list of patients that have records  <-- assumption!
 * returns: An NSArray of dictionaries with keys: Id, MiddleName, FirstName, IsActive
 *---------------------------------------------------------------------------*/

+(NSArray *)getPatientList {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/patientList/", host];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        return jsonArray;
    }
    NSLog(@"getPatientList didn't work: error in PHP");
    return NULL;
    
}


/*---------------------------------------------------------------------------
 * description: gets picture from portrait folder on host
 * current host: teamecuadortrx.com/TRxTalk
 * fileName: "patientId" + "n" + "picNumber"
 * returns UIImage of specified jpeg
 *---------------------------------------------------------------------------*/

+(UIImage *)getPortraitFromServer:(NSString *)fileName {
    NSString *str = [NSString stringWithFormat:@"%@portraits/%@.jpeg", imageDir, fileName];
    NSURL *url = [NSURL URLWithString:str];
    UIImage *myImage = [UIImage imageWithData:
                        [NSData dataWithContentsOfURL:url]];
    return myImage;
}


/*---------------------------------------------------------------------------
 * description: gets picture url from thumb folder on host
 * current host: teamecuadortrx.com/TRxTalk
 * fileName: "patientId" + "n" + "picNumber"
 * returns NSURL of specified jpeg
 *---------------------------------------------------------------------------*/
+(NSURL *)getThumbFromServer:(NSString *)fileName {
    NSString *str = [NSString stringWithFormat:@"%@thumbs/%@.jpeg", imageDir, fileName];
    NSURL *url = [NSURL URLWithString:str];
    
    return url;
}


/*---------------------------------------------------------------------------
 * description: gets list of surgeries with their Id's
 * returns NSArray of dictionaries with keys: Name and Id
 *---------------------------------------------------------------------------*/
+(NSArray *)getSurgeryList {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/surgeryList/", host];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        return jsonArray;
    }
    NSLog(@"getSurgeryList didn't work: error in PHP");
    return NULL;
}

/*---------------------------------------------------------------------------
 * description: gets list of surgeries with their Id's
 * returns NSArray of the LastName of the doctor
 *---------------------------------------------------------------------------*/
+(NSArray *)getDoctorList {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/doctorList/", host];
    NSLog(@"%@", encodedString);
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        return jsonArray;
    }
    NSLog(@"getDoctorList didn't work: error in PHP");
    return NULL;
}

+(NSArray *)getOperationRecordTypesList {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/operationRecordTypesList/", host];
    NSLog(@"%@", encodedString);
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        return jsonArray;
    }
    NSLog(@"getDoctorList didn't work: error in PHP");
    return NULL;
}

/*---------------------------------------------------------------------------
 * Pass in a patient's recordId. Calls DB to get stored info
 * returns NSArray of Keys and values for each field
 *---------------------------------------------------------------------------*/
+(NSArray *)getRecordData:(NSString *)recordId {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/recordData/%@", host, recordId];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    NSLog(@"%@", encodedString);
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        return jsonArray;
    }
    NSLog(@"getRecordData didn't work: error in PHP");
    return NULL;
}


+(NSArray *)getPatientMetaData:(NSString *)patientId {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/patientMetaData/%@", host, patientId];
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        
        return jsonArray;
    }
    NSLog(@"getRecordData didn't work: error in PHP");
    return NULL;
}


/*---------------------------------------------------------------------------
 * description: queries database for current profile picture
 * returns UIImage of profile picture for specified patient
 *---------------------------------------------------------------------------*/
+(UIImage *)getProfilePictureFromServer:(NSString *)patientId {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/profileURL/%@", host, patientId];
    NSLog(@"encodedString: %@", encodedString);
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    NSString *fileName;
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        fileName = [dic objectForKey:@"Path"];
        
        return [self getPortraitFromServer:fileName];
    }
    NSLog(@"Error retrieving profile picture");
    return NULL;
}

#pragma mark - Picture Methods

/*---------------------------------------------------------------------------
 *
 *---------------------------------------------------------------------------*/
+(BOOL)uploadFileToServer:(id)file
                 fileType:(NSString *)fileType
                 fileName:(NSString *)fileName
                patientId:(NSString *)patientId {
    
    NSString *fNameWithSuffix;
    NSData *uploadData;
    if ([fileType isEqualToString:@"image"]) {
        UIImage *uploadFile = (UIImage *)file;
        fNameWithSuffix = [NSString stringWithFormat:@"%@.jpeg", fileName];
        uploadData = UIImageJPEGRepresentation(uploadFile, 1);
    }
    else {
        //audio file
        
    }
    /*Using AFNetworking. This works, but it seems to still block until picture is uploaded */
    /*all of a sudden much faster */
    /* --works quickly when I don't call addPictureInfoToDatabase */
    /* ----issue was initWithURL ----- need to refactor ----*/
    
    NSURL *url = [NSURL URLWithString:@"http://www.teamecuadortrx.com/TRxTalk/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    
    NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:patientId, @"patientId",
                         fileType, @"fileType", nil];
    
    
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"upload.php" parameters:dic constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:uploadData name:@"file" fileName:fNameWithSuffix mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [operation start];
    
    return true;
}


//NOTE custom Names are only for internal use. They get stored
//in the server but do not get used in the file structure.

+(void)uploadFileToServer:(id)file
               customName:(NSString *)customName
                 fileType:(NSString *)fileType
               forPatient:(NSString *)patientId {
    
    if ([fileType isEqualToString:@"image"]) {
        UIImage *image = [[UIImage alloc] initWithData:file];
        //[DBTalk uploadImageToServer:image fileName:customName forPatient:patientId];
    }
    else if ([fileType isEqualToString:@"audio"]) {
        
    }
    else {
        NSLog(@"No method for file of that type");
        [Utility alertWithMessage:@"No method for file of that type"];
    }
}



/*---------------------------------------------------------------------------
 * base method for addPicturePathToDatabase and updatePathToDatabase
 *
 *---------------------------------------------------------------------------*/

//FIXME sent picture info to database
+(NSString *)pictureInfoToDatabase:(NSDictionary *)params {
    
    
    
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    [httpClient postPath:@"add/picturePathToDatabase" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Picture path added successfully");
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        NSString *retval = [dic objectForKey:@"@returnValue"];
        if ([retval isEqualToString:@"0"]) {
            NSString *err = [dic objectForKey:@"error"];
            [Utility alertWithMessage:err];
            NSLog(@"error: %@", err);
            
        }
        else {
            //update sync
            NSLog(@"It really worked: %@", dic);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Picture path update failed");
    }];
    
    
    
    //    NSString *encodedString = [NSString stringWithFormat:@"%@add/picturePathToDatabase/%@/%@/%@/%@/%@", host,
    //                               picId, patientId, fileName, customName, isProfile];
    //    NSLog(@"picturePathURL: %@", encodedString);
    //
    //    /* THIS LINE IS THE PROBLEM */
    //    //NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    //
    //    /* Using Ziebart's code for kicks */
    //    [NZURLConnection getAsynchronousResponseFromURL:encodedString withTimeout:5 completionHandler:^(NSData *response, NSError *error, BOOL timedOut) {
    //        if (response) {
    //            NSLog(@"%@", response);
    //            NSError *jsonError;
    //            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&jsonError];
    //            NSDictionary *dic = jsonArray[0];
    //            NSString *retval = [dic objectForKey:@"@returnValue"];
    //            NSLog(@"addPicture returned %@", retval);
    //        }
    //        else {
    //            NSLog(@"AddPicturePathToDatabase not getting proper response");
    //        }
    //    }];
    //
    
    //NSLog(@"Error adding picturePath to Database");
    return NULL;
    
}
/*---------------------------------------------------------------------------
 * method concatenates patientId, the letter 'n', and the number of the
 * picture for the patient and returns a name.
 *---------------------------------------------------------------------------*/

+(NSString *) getNewPictureName:(NSString *)patientId {
    NSString *numPicsURL = [NSString stringWithFormat:@"%@get/numPictures/%@", host, patientId];
    NSLog(@"numPicsURL: %@", numPicsURL);
    NSData *numPicsData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:numPicsURL]];
    if (!numPicsData)
        NSLog(@"Error retrieving numPics in method getNewPictureName");
    NSError *jsonError;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:numPicsData options:kNilOptions error:&jsonError];
    NSDictionary *dic = jsonArray[0];
    int numPics = [[dic objectForKey:@"numPictures"] intValue];
    NSString *name;
    
    if (numPics < 10)
        name = [NSString stringWithFormat:@"%@n00%d",patientId, numPics];
    else if (numPics < 100)
        name = [NSString stringWithFormat:@"%@n0%d",patientId, numPics];
    else
        name = [NSString stringWithFormat:@"%@n%d",patientId, numPics];
    return name;
}

+(NSDictionary *)getOperationRecordNames:(NSString *)recordId {
    NSString *encodedString = [NSString stringWithFormat:@"%@get/operationRecord/%@", host, recordId];
    NSLog(@"encodedString: %@", encodedString);
    NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    if (data) {
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        
        return dic;
    }
    NSLog(@"Error retrieving operation record names");
    return NULL;
}

/*-----------------------------------------------------------------------
 Method: loadDataFromServer
 Returns:
 void
 it will pub "loadFromLocal" upon completion (rain or shine)
 Summary:
 Prepare the local database for whomeever needs it. In short--
 If connection, load data from the server into local
 If no connection, everyone the go ahead to use local
 //TODO: error handling
 -----------------------------------------------------------------------*/
+ (void)loadDataFromServer:(NSDictionary *)params {
    //With Connection:
    //Call php for [tables] for isLive patient record; this returns [{tablename:[{rows}]}, {tablename:[{rows}]}, etc]
    //Call setSQLiteTableWithData for all rows in all tables according to syncing method
    //Syncing method:
    //Check if SQLite has this id
    //If it doesn't, add server record and attach appropriately
    //If it does,
    //If sqlite lastmod < servermod, replace SQLite
    //If sqlite lastmod >= servermod, ignore
    //Pub "loadFromLocal"
    
    /*take tables and pass dictionary of patients info from local instead*/
    /*get patient and patientRecordId from local database if there isn't one, don't call it*/
    __block typeof(self) this = self;
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:host]];
    NSMutableURLRequest *request;
    NSString *patientRecordId = [LocalTalk localGetPatientRecordId];
    NSString *patientId = [LocalTalk localGetPatientId];
    NSDictionary *dbobj;
    
    //TODO: look at whether this should work even if no patientid and patientrecordid--i.e. for ordertemplate, surgery, etc default tables
    if(patientId != nil && patientRecordId != nil)
    {
        dbobj = @{@"tableNames": [params objectForKey:@"tableNames"],
                  @"patientId": patientId,
                  @"patientRecordId": patientRecordId,
                  @"location": [params objectForKey:@"location"]};
    }
    else
    {
        dbobj = nil;
    }
    
    if(dbobj != nil){
        //Call php for the necessary tables
        request = [httpClient requestWithMethod:@"POST" path:@"get/dataFromTables" parameters:dbobj];
        [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            
            [this loadDataintoSQLiteWith:JSON];
            
            //Local is now all set up, so pub
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:this userInfo:params];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            //Local can't be updated after all, so go ahead and pub
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:this userInfo:params];
        }];
        operation.JSONReadingOptions = NSJSONReadingMutableContainers;
        
        [operation start];
    } else {
        /*it's a new patient or something went wrong*/
        //TODO: LOCK DOWN OTHER TABS HERE BEFORE WE PUB
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:this userInfo:params];
    }
}

/***********************************************************************************************************
 Method: loadDataintoSQLite
 Objective: fill the local database with whatever is passed to it
 Returns: void
 Parameters:
 (id) JSON: the data to put into the local database,
 of the form array[0]->dictionary { tableName1 : {table data }, tableName2 : {table data} }
 //TODO: it would be really nice to just have an enum of table names
 //TODO: error handling
 //TODO: have John not pack this as an array of dictionaries of arrays of dictionaries but instead as a
 dictionary where keys are table names with arrays of row dictionaries
 ***********************************************************************************************************/
+(void)loadDataintoSQLiteWith:(id)tableData{
    /*UPDATE Table1 SET (...) WHERE Column1='SomeValue'
     IF @@ROWCOUNT=0
     INSERT INTO Table1 VALUES (...)*/
    
    //mischa: not sure if i agree...thinking
    //for each table if the ID exists in that table update the row, otherwise insert the data into that table.
    BOOL success = true;
    NSString *patientId;
    NSString *patientRecordId;
    NSString *patientRecordAppId;
    NSString *patientAppId;
    NSMutableArray *returnIDs = [[NSMutableArray alloc] init];
    NSMutableArray *json = [[NSMutableArray alloc] init];
    NSMutableDictionary *tables = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *tmp = [[NSMutableDictionary alloc] init];
    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
    
    [json addObjectsFromArray:tableData];
    for(NSDictionary *table in json){
        [tables addEntriesFromDictionary:table];
    }
    
    //check if it's Doctor, surgery type, or patient and if it is those have special keys
    //otherwise, use patient record id
    //to insert (if it doesn't exist or update if it does
    
    
    //TODO: inserts vs updates
    //Try to insert patient
    patientId = [LocalTalk localGetPatientId];
    patientAppId = [LocalTalk localGetPatientAppId];
    patientRecordAppId = [LocalTalk localGetPatientRecordAppId];
    patientRecordId = [LocalTalk localGetPatientRecordId];
    
    @try
    {
        
        //INSERT or UPDATE Patient
        if([tables objectForKey:@"Patient"] != nil){
            //TODO: don't really know if this check is necessary...seems like a good idea right now though
            if([tables[@"Patient"][0][@"Id"] isEqualToString:patientId] && patientAppId != nil && ![patientAppId isEqualToString:@"0"]){
                [tmp removeAllObjects];
                [tmpArray removeAllObjects];
                [tmp addEntriesFromDictionary:tables[@"Patient"][0]];
                tmp[@"AppId"] = patientAppId;
                [tmpArray addObject:tmp];
                returnIDs = [LocalTalk setSQLiteTable:@"Patient" withData:tmpArray];
            }
            else{
                returnIDs = [LocalTalk setSQLiteTable:@"Patient" withData:tables[@"Patient"]];
            }
            
            for(NSString *returnId in returnIDs){
                if([returnId integerValue] == 0){
                    success = false;
                    //TODO: upon failure, do what? (besides not trying to further add records etc)
                }
            }
        }
        
        //INSERT or UPDATE PatientRecord
        //TODO: really should be using a table name variable
        if(success && [tables objectForKey:@"PatientRecord"] != nil){
            //TODO: don't really know if this check is necessary...seems like a good idea right now though
            if([tables[@"PatientRecord"][0][@"Id"] isEqualToString:patientRecordId] && patientRecordAppId != nil && ![patientRecordAppId isEqualToString:@"0"]){
                [tmp removeAllObjects];
                [tmpArray removeAllObjects];
                [tmp addEntriesFromDictionary:tables[@"PatientRecord"][0]];
                tmp[@"AppId"] = patientRecordAppId;
                [tmpArray addObject:tmp];
                returnIDs = [LocalTalk setSQLiteTable:@"PatientRecord" withData:tmpArray];
            }
            else{
                returnIDs = [LocalTalk setSQLiteTable:@"PatientRecord" withData:tables[@"PatientRecord"]];
            }
            
            for(NSString *returnId in returnIDs){
                if([returnId integerValue] == 0){
                    success = false;
                    //TODO: upon failure, do what? (besides not trying to further add records etc)
                }
            }
        }
        
        //INSERT or UPDATE OperationRecord
        //TODO: really should be using a table name variable
        //TODO: there are probably some times we should instead update
        if(success && [tables objectForKey:@"OperationRecord"] != nil){
            [tmp removeAllObjects];
            [tmpArray removeAllObjects];
            for(NSDictionary *row in tables[@"OperationRecord"]){
                //TODO: for now this only works with type PICTURE, and it is hardcoded to boot
                if([row[@"RecordTypeId"] isEqualToString:@"3"]){
                    tmp = [[NSMutableDictionary alloc] init];
                    [tmp addEntriesFromDictionary:row];
                    [tmp removeObjectForKey:@"PatientRecordId"];
                    tmp[@"AppPatientRecordId"] = patientRecordAppId;
                    
                    //NSURL *url = [get];
                    /*
                    [NSURLRequest requestWithURL:[]] placeholderImage:NULL success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                        NSLog(@"success");
                        cell.patientPicture.image = image;
                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                        NSLog(@"fail");
                    }];
*/
                    
                    //tmp[@"Data"] = [DBTalk ];
                    [tmpArray addObject:tmp];
                }
            }
            returnIDs = [LocalTalk setSQLiteTable:@"OperationRecord" withData:tmpArray];
            for(NSString *returnId in returnIDs){
                if([returnId integerValue] == 0){
                    success = false;
                    //TODO: upon failure, do what? (besides not trying to further add records etc)
                }
            }
        }
    }
    
    @catch (NSException *e) {
        
    }
    //    for(NSString *tableName in parsedData){
    //
    //        if([tableName isEqualToString:@"Patient"]){
    //            success = [LocalTalk addTableToLocal:tableName withData:parsedData[tableName]];
    //        }
    //        else if([tableName isEqualToString:@"Doctor"] || [tableName isEqualToString:@"SurgeryType"]) {
    //
    //        }
    //        else {
    //            
    //        }
    
}
/*+(NSDictionary *)getValuesFromLocal:(NSDictionary *)dic {
 
 //find the current patient
 //iterate through dictionary for each key and table
 //Select ? from ? Where currentRecordId = Select recordId from Patient where current = 1
 
 //unpack and put into a dictionary to return
 
 }*/





@end
