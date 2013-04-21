//
//  SurgeryListViewCell.h
//  TRx
//
//  Created by Dwayne Flaherty on 4/18/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SurgeryListViewCell : UITableViewCell{
    @public
    
}
@property (strong, nonatomic) IBOutlet UILabel *fileName;
@property (strong, nonatomic) IBOutlet UIImageView *fileIcon;
@property (strong, nonatomic) IBOutlet UILabel *audioFileLength;
@property (strong, nonatomic) IBOutlet UIButton *playButton;


@end
