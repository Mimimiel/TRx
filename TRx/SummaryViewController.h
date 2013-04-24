//
//  SummaryViewController.h
//  TRx
//
//  Created by Mark Bellott on 3/7/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SummaryViewController : UIViewController

@property(strong, nonatomic) IBOutlet UIImageView *patientPicture;
@property(strong, nonatomic) IBOutlet UILabel *pName;
@property(strong, nonatomic) IBOutlet UILabel *pGender;
@property(strong, nonatomic) IBOutlet UILabel *pBirthday;
@property(strong, nonatomic) IBOutlet UILabel *pSurgery;

@end
