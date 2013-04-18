//
//  Patient.h
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface Patient : NSObject{
   
    NSString *firstName, *middleName, *lastName;
    NSString *birthday;
    NSString *chiefComplaint;
    UIImage *photoID;
}

@property(nonatomic,retain) NSString *firstName;
@property(nonatomic,retain) NSString *middleName;
@property(nonatomic,retain) NSString *lastName;
@property(nonatomic,readwrite) NSString *birthday;
@property(nonatomic, readwrite) NSString *chiefComplaint;
@property(nonatomic, readwrite) NSString *patientId;
@property(nonatomic, readwrite) NSString *currentRecordId;
@property(nonatomic, readwrite) NSString *patientRecordAppId;
@property(nonatomic, retain) UIImage *photoID;
@property(nonatomic, retain) NSURL *photoURL;

-(id)initWithFirstName:(NSString *)fn MiddleName:(NSString*) mn LastName:(NSString*)ln ChiefComplaint:(NSString *)c PhotoID:(UIImage*)p;

-(id)initWithPatientId:(NSString *)patId currentRecordId:(NSString *)currRecordId
    patientRecordAppId:(NSString *)PatientRecordAppId firstName:(NSString *)fn MiddleName:(NSString*) mn LastName:(NSString*)ln
birthday:(NSString *)bDay ChiefComplaint:(NSString *)c PhotoID:(UIImage*)p PhotoURL:(NSURL*)photoURL;
@end
