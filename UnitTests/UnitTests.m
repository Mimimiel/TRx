//
//  UnitTests.m
//  UnitTests
//
//  Created by John Cotham on 3/28/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "UnitTests.h"
#import "FMDatabase.h"
#import "Utility.h"


@implementation UnitTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

-(void)testAddPatientToLocal {
    NSDictionary *params = @{@"viewName"    : @"historyViewController",
                             @"FirstName"   : @"Jimmy",
                             @"MiddleName"  : @"Crack",
                             @"LastName"    : @"Corn",
                             @"Birthday"    : @"1818-08-08",
                             @"Data"        : @"FakeData",
                             @"SurgeryTypeId":@"1",
                             @"DoctorId"    : @"1",
                             @"HasTimeout"  : @"0",
                             @"IsLive"      : @"1",
                             @"IsCurrent"   : @"1"
                             };
    
    //Note: if no picture is taken,
    //can use [NSNull null]
    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    [db open];
    [db executeUpdate:@"DELETE FROM Patient"];
    [db close];
    [LocalTalk clearIsLiveFlags];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpressed" object:self userInfo:params];
    
    //[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
    
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    
    //    //try to wait for thread
    //    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 2LL * NSEC_PER_SEC);
    //    dispatch_after(timeout, dispatch_get_main_queue(), ^(void){
    //
    //    });
    
}

-(void)testSynchPatientAndRecordToServer {
    
}

/*-----------------------------------------------------------------------
 Class: DBTalk
 Method: loadDataintoSQLiteWithJSON
 TestSummary: load any set of data, passed as JSON, into the local
 database
 //TODO: write this test
 -----------------------------------------------------------------------*/
-(void)testLoadDataintoSQLiteWithJSON{
    /*
     LocalTalk addTableToLocal:@"Patient" withData:parsedData[@"Patient"]
     //(void)loadDataintoSQLiteWith:(id) JSON{
     NSDictionary *params = @{@"viewName"    : @"historyViewController",
     @"FirstName"   : @"Jimmy",
     @"MiddleName"  : @"Crack",
     @"LastName"    : @"Corn",
     @"Birthday"    : @"18180808",
     @"Data"        : @"FakeData",
     @"SurgeryTypeId":@"1",
     @"DoctorId"    : @"1",
     @"HasTimeout"  : @"0",
     @"IsLive"      : @"1",
     @"IsCurrent"   : @"1"
     };
     
     //Note: if no picture is taken,
     //can use [NSNull null]
     
     [[NSNotificationCenter defaultCenter] postNotificationName:@"nextpressed" object:self userInfo:params];
     
     //[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
     
     [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
     
     //    //try to wait for thread
     //    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 2LL * NSEC_PER_SEC);
     //    dispatch_after(timeout, dispatch_get_main_queue(), ^(void){
     //
     //    });
     */
    
}

/*-----------------------------------------------------------------------
 Class: LocalTalk
 Method: testAddToLocalTable withData
 TestSummary: load any set of data, passed as JSON, into the local
 database
 //TODO: write this test
 -----------------------------------------------------------------------*/
-(void)testAddToLocalTableWithData{
    BOOL success = TRUE;
    NSMutableArray *insertedIDs;
    NSString* tableName = @"Patient";
    NSDictionary *brandNewPatient = @{@"FirstName"   : @"Testy",
                                      @"MiddleName"  : @"Tester",
                                      @"LastName"    : @"McTesterson",
                                      @"Birthday"    : @"1989-10-10"
                                      };
    NSMutableArray *newPatients = [[NSMutableArray alloc] init];
    NSDictionary *serverPatient =   @{@"Id"           : @"10000",
                                    @"FirstName"    : @"SonOf",
                                    @"MiddleName"   : @"Tester",
                                    @"LastName"     : @"McTesterson",
                                    @"Birthday"     : @"2013-1-10",
                                    @"Created"      : @"2013-04-18 01:01:01",
                                    @"LastModified" : @"2013-04-18 02:02:02",
                                    @"LastSynced"   : @"2013-04-18 01:01:01",
                                    };
    
    [newPatients addObject:brandNewPatient];
    [newPatients addObject:serverPatient];
    
    insertedIDs = [LocalTalk addToLocalTable:tableName withData:newPatients];
    for(NSNumber* insertedID in insertedIDs){
        if(!insertedID){
            success = FALSE;
        }
    }
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



@end
