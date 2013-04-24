//
//  PQYesNo.h
//  TRx
//
//  Created by Mark Bellott on 4/24/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PQYesNo : UIButton{
    BOOL hasChanged;
}

@property(nonatomic,readwrite)BOOL hasChanged;

@end
