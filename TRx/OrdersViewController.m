//
//  OrdersViewController.m
//  TRx
//
//  Created by Mark Bellott on 3/9/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "OrdersViewController.h"

@interface OrdersViewController ()
@property (nonatomic) IBOutlet UITextView *ordersTextViewTl;
@property (nonatomic) IBOutlet UITextView *ordersTextViewTr;
@property (nonatomic) IBOutlet UITextView *ordersTextViewBl;
@property (nonatomic) IBOutlet UITextView *ordersTextViewBr;

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
