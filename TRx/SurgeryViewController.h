//
//  SurgeryViewController.h
//  TRx
//
//  Created by Dwayne Flaherty on 3/12/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SurgeryViewController : UIViewController <UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    IBOutlet UITableView *filesTable;
    NSURL *soundFileURL;
    NSDate *now;
    BOOL isPaused;
    IBOutlet UITextField *fileNameText;
    NSMutableDictionary *files;
    NSMutableArray *audioCellsArray;
    UIButton *tmp;
    MPMoviePlayerController *player;
    IBOutlet UIView *videoView;

}
@property BOOL newMedia;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioPlayer *audioPlayerForButton;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *saveRecording;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (nonatomic, readwrite) NSNumber *recordCount;
- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)saveRecord:(id)sender;
- (IBAction)useCamera:(id)sender;
- (IBAction)useSelectedFile:(id)sender;

+(SurgeryViewController*)sharedSurgeryViewController;
@end
