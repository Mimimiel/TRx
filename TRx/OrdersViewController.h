//
//  OrdersViewController.h
//  TRx
//
//  Created by Mark Bellott on 3/9/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocalTalk.h"

@interface OrdersViewController : UIViewController

@property (nonatomic) IBOutlet UITextView *ordersTextViewTl;
@property (nonatomic) IBOutlet UITextView *ordersTextViewTr;
@property (nonatomic) IBOutlet UITextView *ordersTextViewBl;
@property (nonatomic) IBOutlet UITextView *ordersTextViewBr;
@end
