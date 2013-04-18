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
    internetReachable = [Reachability reachabilityForLocalWiFi];
    NetworkStatus netStatus = [internetReachable currentReachabilityStatus];
    connectivity = (netStatus==ReachableViaWiFi);
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

    //check if recordId is null
    NSLog(@"Exiting DBTalk's pushLocalUnsyncedToServer");
}



#pragma mark - Add Methods


+(void)addUpdatePatient {
    NSLog(@"Entering addUpdatePatient");
    NSArray *patientTableValuesArray    = [LocalTalk selectAllFromTable:@"Patient"];
    NSDictionary *patientTableValues    = [patientTableValuesArray objectAtIndex:0];
    NSLog(@"%@", patientTableValues);
    
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    [httpClient postPath:@"add/patient" parameters:patientTableValues success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"AddPatient successful");
        
        
        NSError *jsonError;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&jsonError];
        NSDictionary *dic = jsonArray[0];
        NSString *retval = [dic objectForKey:@"@returnValue"];
        if ([retval isEqualToString:@"0"]) {
            NSString *err = [dic objectForKey:@"error"];
            [Utility alertWithMessage:err];
        }
        else {
            [LocalTalk insertValue:retval intoColumn:@"Id" inLocalTable:@"Patient"];
        }
        [DBTalk addUpdatePatientRecord];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"AddPatient failed");
    }];
    
}

+(void)addUpdatePatientRecord {
    //if patientRecord is NULL or table is unsynched, sync else return
    NSLog(@"Entering addUpdatePatientRecord");
    
    NSArray *recordTableValuesArray     = [LocalTalk selectAllFromTable:@"PatientRecord"];
    NSMutableDictionary *recordTableValues     = [recordTableValuesArray objectAtIndex:0];
    [recordTableValues setValue:@"0" forKey:@"HasTimeout"];
    
    NSString *patientId = [LocalTalk localGetPatientId];
    NSLog(@"Printing patinetId in addUpdatePatientRecord: %@", patientId);
    
    [recordTableValues setValue:patientId forKey:@"PatientId"];
    NSLog(@"%@", recordTableValues);
    
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
            [LocalTalk insertValue:retval intoColumn:@"Id" inLocalTable:@"PatientRecord"];
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
    
    pictureId = [self addPictureInfoToDatabase:patientId fileName:fileName isProfile:isProfile];
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
+(BOOL)uploadPictureToServer:(UIImage *)picture
                    fileName:(NSString *)fileName
                   directory:(NSString *)directory {
    
    NSString *fNameWithSuffix = [NSString stringWithFormat:@"%@.jpeg", fileName];
    
    /*Using AFNetworking. This works, but it seems to still block until picture is uploaded */
    /*all of a sudden much faster */
    /* --works quickly when I don't call addPictureInfoToDatabase */
    /* ----issue was initWithURL ----- need to refactor ----*/
    
    NSURL *url = [NSURL URLWithString:@"http://www.teamecuadortrx.com/TRxTalk/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSData *imageData = UIImageJPEGRepresentation(picture, 0.03);
    
    NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:directory, @"directory", nil];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"upload.php" parameters:dic constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:imageData name:@"file" fileName:fNameWithSuffix mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    [operation start];
    
    return true;
}

/*---------------------------------------------------------------------------
 * Updates a picture path in the database. Need to pass in a pictureId
 *
 *---------------------------------------------------------------------------*/

+(NSString *)updatePictureInfoInDatabase:(NSString *)pictureId
                               patientId:(NSString *)patientId
                                 newPath:(NSString *)newPath
                              customName:(NSString *)customName
                               isProfile:(NSString *)isProfile {
    return [self pictureInfoToDatabase:pictureId patientId:patientId fileName:newPath
                            customName:customName isProfile:isProfile];
}
/*---------------------------------------------------------------------------
 * Adds a picture path to the database. Path is just a filename right now
 *
 *---------------------------------------------------------------------------*/

+(NSString *)addPictureInfoToDatabase:(NSString *)patientId
                             fileName:(NSString *)fileName
                            isProfile:(NSString *)isProfile {
    return [self pictureInfoToDatabase:@"NULL" patientId:patientId fileName:fileName
                            customName:fileName isProfile:isProfile];
}


/*---------------------------------------------------------------------------
 * base method for addPicturePathToDatabase and updatePathToDatabase
 *
 *---------------------------------------------------------------------------*/
+(NSString *)pictureInfoToDatabase:(NSString *)picId
                         patientId:(NSString *)patientId
                          fileName:(NSString *)fileName
                        customName:(NSString *)customName
                         isProfile:(NSString *)isProfile {
    
    NSString *encodedString = [NSString stringWithFormat:@"%@add/picturePathToDatabase/%@/%@/%@/%@/%@", host,
                               picId, patientId, fileName, customName, isProfile];
    NSLog(@"picturePathURL: %@", encodedString);
    
    /* THIS LINE IS THE PROBLEM */
    //NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:encodedString]];
    
    /* Using Ziebart's code for kicks */
    [NZURLConnection getAsynchronousResponseFromURL:encodedString withTimeout:5 completionHandler:^(NSData *response, NSError *error, BOOL timedOut) {
        if (response) {
            NSLog(@"%@", response);
            NSError *jsonError;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:&jsonError];
            NSDictionary *dic = jsonArray[0];
            NSString *retval = [dic objectForKey:@"@returnValue"];
            NSLog(@"addPicture returned %@", retval);
        }
        else {
            NSLog(@"AddPicturePathToDatabase not getting proper response");
        }
    }];
    
    
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


+ (void)loadDataFromServer:(NSDictionary *)params {
    __block typeof(self) this = self;
    NSURL *url = [NSURL URLWithString:host];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    /*take tables and pass dictionary of patients info from local instead*/
    /*get patient and patientRecordId from local database if there isn't one, don't call it*/
    NSDictionary *dbobj;
    NSString *patientRecordId = [LocalTalk localGetPatientRecordId];
    NSString *patientId = [LocalTalk localGetPatientId];
    NSLog(@"the Patient Id is: %@ and the P-Record Id is: %@", patientId, patientRecordId);
    
    if(patientId != nil && patientRecordId != nil){
        dbobj = @{@"tableNames" : [params objectForKey:@"tableNames"],
                  @"patientRecordId" : patientRecordId,
                  @"patientId" : patientId,
                  @"location" : [params objectForKey:@"location"] };
    } else { dbobj = nil; }
    
    if(dbobj != nil){
        NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"get/dataFromTables" parameters:dbobj];
        [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
        AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
            NSLog(@"This was the response: %@", response);
            [self loadDataintoSQLite:JSON];
              [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:self userInfo:params];
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
            NSLog(@"Request Failure Because %@",[error userInfo]);
              [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:self userInfo:params];
        }];
        
        [operation start];
    } else {
        /*it's a new patient or something went wrong*/
        //TODO: LOCK DOWN OTHER TABS HERE BEFORE WE PUB

        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadFromLocal" object:self userInfo:params];
        NSLog(@"poop: %@", params);
    }
}

/*gets a JSON object that is an array[0]->dictionary { tableName1 : {table data }, tableName2 : {table data} } */

+ (void)loadDataintoSQLite:(id) JSON {
    /*UPDATE Table1 SET (...) WHERE Column1='SomeValue'
     IF @@ROWCOUNT=0
     INSERT INTO Table1 VALUES (...)*/
    
    //for each table if the ID exists in that table update the row, otherwise insert the data into that table.
    NSError *error=nil;
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:JSON options:kNilOptions error:&error];
    for(NSString *key in parsedData){
        NSLog(@"%@", key);
    }
    
    for(NSString *table in parsedData){
        //check if it's Doctor, surgery type, or patient and if it is those have special keys
        //otherwise, use patient record id
        //to insert (if it doesn't exist or update if it does
        if([table isEqualToString:@"Patient"]){
            
        } else if([table isEqualToString:@"Doctor"] || [table isEqualToString:@"SurgeryType"]) {
            
        }
        else {
            
        }
        
        
    }
}
/*+(NSDictionary *)getValuesFromLocal:(NSDictionary *)dic {
 
 //find the current patient
 //iterate through dictionary for each key and table
 //Select ? from ? Where currentRecordId = Select recordId from Patient where current = 1
 
 //unpack and put into a dictionary to return
 
 }*/





@end
