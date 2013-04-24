//
//  PQYesNo.m
//  TRx
//
//  Created by Mark Bellott on 4/24/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "PQYesNo.h"

@implementation PQYesNo

@synthesize hasChanged;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setBackgroundColor:[UIColor whiteColor]];
        [self.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20]];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        hasChanged = NO;
    }
    return self;
}

@end
