//
//  OrdersViewController.m
//  TRx
//
//  Created by Mark Bellott on 3/9/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "OrdersViewController.h"

@interface OrdersViewController ()


@end

@implementation OrdersViewController{
    NSArray *textViews;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    /*listeners for history view controller*/
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(updatedDataListener:) name:@"loadFromLocal" object:nil];
    
    NSArray *tables = @[@"Orders"];
    NSDictionary *params = @{@"tableNames" : tables,
                             @"location" : @"ordersViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabloaded" object:self userInfo:params];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    textViews = @[_ordersTextViewTl, _ordersTextViewTr, _ordersTextViewBl, _ordersTextViewBr];
    
     [_ordersTextViewTl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)]];
     [_ordersTextViewTr addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)]];
     [_ordersTextViewBl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)]];
     [_ordersTextViewBr addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapped:)]];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(outsideTapped)]];

}

-(void)updatedDataListener:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    if([[params objectForKey:@"location"] isEqualToString:@"ordersViewController"]){
        NSMutableDictionary *data = [LocalTalk getData:params];
        NSLog(@"The updated data listener's data in Order VC is: %@", data);
        //if something was returned successfully
        //which will happen every time except for the first time they ever click the orders tab for a patient load the orders into the text boxes
        if(data){
            NSMutableArray *ordersFiles = [[NSMutableArray alloc] init];
            for(NSString *key in data){
                if([key isEqualToString:@"Orders"]){
                    ordersFiles = [data objectForKey:key];
                }
            }
            for(NSDictionary *dict in ordersFiles){
                if([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"1"]){
                    _ordersTextViewTl.text = [dict objectForKey:@"Text"];
                } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"2"]){
                    _ordersTextViewBl.text = [dict objectForKey:@"Text"];

                } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"3"]){
                    _ordersTextViewTr.text = [dict objectForKey:@"Text"];

                } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"4"]){
                    _ordersTextViewBr.text = [dict objectForKey:@"Text"];
                }
            }
            
        }else {
            NSArray *tables = @[@"OrderTemplate"];
            NSDictionary *newParams = @{@"tableNames" : tables,
                                        @"location" : @"ordersViewController"};
            NSMutableDictionary *data = [LocalTalk getData:newParams];
            if(data){
                NSMutableArray *ordersFiles = [[NSMutableArray alloc] init];
                for(NSString *key in data){
                    if([key isEqualToString:@"OrderTemplate"]){
                        ordersFiles = [data objectForKey:key];
                    }
                }
                for(NSDictionary *dict in ordersFiles){
                    if([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"1"]){
                        _ordersTextViewTl.text = [dict objectForKey:@"Text"];
                    } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"2"]){
                        _ordersTextViewBl.text = [dict objectForKey:@"Text"];
                        
                    } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"3"]){
                        _ordersTextViewTr.text = [dict objectForKey:@"Text"];
                        
                    } else if ([[dict objectForKey:@"OrderTypeId"] isEqualToString:@"4"]){
                        _ordersTextViewBr.text = [dict objectForKey:@"Text"];
                    }
                }
            }
        }
        
    } else { NSLog(@"not in the right view controller"); }
    
}

- (void) textViewTapped:(UIGestureRecognizer *)recognizer {
    UITextView *textView = (UITextView *)recognizer.view;
    textView.editable = YES;
    [textView becomeFirstResponder];
}

- (void) outsideTapped {
    for (UITextView *tv in textViews) {
        [tv resignFirstResponder];
        tv.editable = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
