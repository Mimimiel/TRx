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
 Class: LocalTalk
 Method: setSQLiteTable withData
 Test Summary: insert and update rows into any table in the local database
    Patient
    PatientRecord
 -----------------------------------------------------------------------*/
-(void)testAddToLocalTableWithData{
    BOOL success = TRUE;
    NSMutableArray *affectedIDs;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSString *now;
    NSMutableArray *data = [[NSMutableArray alloc] init];
    NSDictionary *newPatient, *serverPatient, *newPRecord, *serverPRecord;
    
    //Initialize date to now
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    now = [dateFormatter stringFromDate:[NSDate date]];
    
    //INSERT two patients (one new, one from server)
    newPatient = @{@"FirstName"   : @"Testy",
                   @"MiddleName"  : @"Tester",
                   @"LastName"    : @"McTesterson",
                   @"Birthday"    : @"1989-10-10"
                   };
    
    serverPatient = @{@"Id"           : @"10000",
                      @"FirstName"    : @"SonOf",
                      @"MiddleName"   : @"Tester",
                      @"LastName"     : @"McTesterson",
                      @"Birthday"     : @"2013-1-10",
                      @"Created"      : @"2013-04-18 01:01:01",
                      @"LastModified" : @"2013-04-18 02:02:02",
                      @"LastSynced"   : now,
                      };
    
    
    [data addObject:newPatient];
    [data addObject:serverPatient];
    affectedIDs = [LocalTalk setSQLiteTable:@"Patient" withData:data];
    for(NSNumber* ID in affectedIDs){
        if(!ID){
            success = FALSE;
        }
    }
    
    //UPDATE two patients
    [data removeAllObjects];
    newPatient = @{@"AppId"       : [affectedIDs[0] stringValue],
                   @"FirstName"   : @"NewName"
                   };
    
    serverPatient = @{@"AppId"        : [affectedIDs[1] stringValue],
                      @"FirstName"    : @"NewName"
                      };
    [data addObject:newPatient];
    [data addObject:serverPatient];
    affectedIDs = [LocalTalk setSQLiteTable:@"Patient" withData:data];
    for(NSNumber* ID in affectedIDs){
        if(!ID){
            success = FALSE;
        }
    }
    
    //Insert two patient records (one for each patient)
    [data removeAllObjects];
    newPRecord  = @{@"AppPatientId"     : [affectedIDs[0] stringValue],
                    @"SurgeryTypeId"    : @"1",
                    @"DoctorId"         : @"1",
                    @"HasTimeout"       : @"0",
                    @"IsCurrent"        : @"1",
                    @"IsLive"           : @"0"
                    };
    
    serverPRecord = @{@"AppPatientId"     : [affectedIDs[1] stringValue],
                      @"SurgeryTypeId"    : @"2",
                      @"DoctorId"         : @"2",
                      @"HasTimeout"       : @"0",
                      @"IsCurrent"        : @"1",
                      @"IsLive"           : @"0",
                      @"Id"           : @"9999999",
                      @"Created"      : @"2013-04-18 01:01:01",
                      @"LastModified" : @"2013-04-18 02:02:02",
                      @"LastSynced"   : now,
                      };
    
    [data addObject:newPRecord];
    [data addObject:serverPRecord];
    affectedIDs = [LocalTalk setSQLiteTable:@"PatientRecord" withData:data];
    for(NSNumber* ID in affectedIDs){
        if(!ID){
            success = FALSE;
        }
    }

if(success){
    NSLog(@"Test Method: testAddToLocalTableWithData: was successful.");
}
else{
    NSLog(@"Test Method: testAddToLocalTableWithData: was successful.");
}
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



@end
