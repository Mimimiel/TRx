//
//  HistoryViewController.h
//  TRx
//
//  Created by Mark Bellott on 3/9/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Patient.h"
#import "PatientListViewController.h"
#import "Utility.h"

@interface HistoryViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate>{
    
    Patient *newPatient;

    NSString *firstName, *middleName, *lastName;
    NSString *pComplaint, *pBirthday;
    UIImage *photoID;
    
    IBOutlet UITextField *firstNameText;
    IBOutlet UITextField *middleNameText;
    IBOutlet UITextField *lastNameText;
    IBOutlet UIButton *next;
    IBOutlet UIPickerView *complaintPicker;
    IBOutlet UIDatePicker *birthdayPicker;
    
    PatientListViewController *p;
}

@property (nonatomic, strong) NSMutableArray *complaintsArray;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIPickerView *complaintPicker;
@property (nonatomic, retain) IBOutlet UIDatePicker *birthdayPicker;

-(IBAction)nextView:(id)sender;
-(IBAction)useCamera:(id)sender;
-(IBAction)addPatient:(id)sender;

-(void) storeNames;
-(void)updatedDataListener:(NSNotification *)notification;
@end