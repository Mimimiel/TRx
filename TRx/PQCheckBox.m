//
//  PQCheckBox.m
//  TRx
//
//  Created by Mark Bellott on 4/24/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "PQCheckBox.h"

@implementation PQCheckBox

@synthesize toggleCount, optionLabel, arrayIndex;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        toggleCount = 0;
        arrayIndex = 0;
        
        self.frame = CGRectMake(0, 0, 20, 20);
        [self setBackgroundColor:[UIColor whiteColor]];
        
    }
    return self;
}

-(void) setArrayIndex:(NSInteger)a{
    arrayIndex = a;
}

-(void) checkPressed{
    if(toggleCount == 0){
        self.backgroundColor = [UIColor blueColor];
        toggleCount++;
    }
    else{
        self.backgroundColor = [UIColor whiteColor];
        toggleCount--;
    }
}

@end

