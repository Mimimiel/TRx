//
//  Patient.m
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "Patient.h"

@implementation Patient

//pretend change...

@synthesize firstName, middleName, lastName, chiefComplaint, photoID, patientId, currentRecordId, birthday, patientRecordAppId;

-(id)initWithFirstName:(NSString *)fn MiddleName:(NSString*) mn LastName:(NSString*)ln ChiefComplaint:(NSString *)c PhotoID:(UIImage*)p{
    self.firstName = fn;
    self.middleName = mn;
    self.lastName = ln;
    self.chiefComplaint = c;
    self.photoID = p;
    
    return  self;
}

-(id)initWithPatientId:(NSString *)patId currentRecordId:(NSString *)currRecordId
patientRecordAppId:(NSString *)PatientRecordAppId firstName:(NSString *)fn MiddleName:(NSString*) mn LastName:(NSString*)ln
              birthday:(NSString *)bDay ChiefComplaint:(NSString *)c PhotoID:(UIImage*)p PhotoURL:(NSURL *)photoURL {
    
    self = [self initWithFirstName:fn MiddleName:mn LastName:ln ChiefComplaint:c PhotoID:p];
    self.birthday = bDay;
    self.patientId = patId;
    self.currentRecordId = currRecordId;
    self.photoURL = photoURL;
    self.patientRecordAppId = PatientRecordAppId;
    
    return  self;
}

@end
