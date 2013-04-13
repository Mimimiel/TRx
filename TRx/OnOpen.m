//
//  OnOpen.m
//  TRx
//
//  Created by John Cotham on 4/13/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "OnOpen.h"

@implementation OnOpen

+(void)WireNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserverForName:@"" object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"Here we are");
    }];
    
}

@end
