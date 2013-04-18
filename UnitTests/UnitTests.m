//
//  UnitTests.m
//  UnitTests
//
//  Created by John Cotham on 3/28/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "UnitTests.h"


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
    
}

-(void)testSynchPatientAndRecordToServer {
    
}



- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}



@end
