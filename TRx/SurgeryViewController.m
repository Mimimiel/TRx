//
//  SurgeryViewController.m
//  TRx
//
//  Created by Dwayne Flaherty on 3/12/13.
//  Copyright (c) 2013 Team Ecuador. All rights reserved.
//

#import "SurgeryViewController.h"
#import "SurgeryListViewCell.h"
#import "localtalk.h"
#import "AdminInformation.h"
#import "Base64.h"

@interface SurgeryViewController ()

@end

@implementation SurgeryViewController

/*Create a singleton of the SurgeryViewController */ 
+(SurgeryViewController*)sharedSurgeryViewController{
    static SurgeryViewController *singleton;
    static BOOL initialized = false;
    if (!initialized)
    {
        initialized = true;
        singleton = [[SurgeryViewController alloc] init];
    }
    return singleton;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - viewwill/did and data listener methods
/*In the view will appear we wire up the updatedDataListenerMethod to listen to loadFromLocal and we post 
 that the tab is loading so to go get our data from the relevant (listed) tables */ 
-(void)viewWillAppear:(BOOL)animated {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(updatedDataListener:) name:@"loadFromLocal" object:nil];
    
    NSArray *tables = @[@"OperationRecord"];
    NSDictionary *params = @{@"tableNames" : tables,
                             @"location" : @"surgeryViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabloaded" object:self userInfo:params];
    
}
/*view did appear method.. */
-(void)viewDidAppear:(BOOL)animated{
    
}

/*view did load method, take care of a couple of delegate assignments and some button usage*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    [filesTable setDataSource:self];
    _playButton.enabled = NO;
    fileNameText.delegate = self;
    //[self playVideo];
    // Do any additional setup after loading the view.
}

/*The listener for when new data is available and should be pulled down*/ 
-(void)updatedDataListener:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    if([[params objectForKey:@"location"] isEqualToString:@"surgeryViewController"]){
        NSMutableDictionary *data = [LocalTalk getData:params];
        files = data;
        for(NSString *key in files){
            if([key isEqualToString:@"OperationRecord"]){
                audioCellsArray = [files objectForKey:key];
                [filesTable reloadData];
            }
        }
    } else { NSLog(@"not in the right view controller");}
   
}

#pragma mark - UITextField delegate methods 

/*Delegate method for the UITextField for file names */ 
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [fileNameText resignFirstResponder];
}

#pragma mark - video display methods 

- (void) playVideo
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(movieFinishedCallback:) name:@"movieDone" object:nil];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MyMovie" ofType:@"mov"]];
    mplayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    mplayer.view.frame = self.view.bounds;
    [self.view addSubview:mplayer.view];
    mplayer.controlStyle = MPMovieControlStyleEmbedded;
    [mplayer.view setFrame:CGRectMake(370, 30, (self.view.frame.size.width)-400 , 300)];
    mplayer.scalingMode = MPMovieScalingModeAspectFit;
    mplayer.shouldAutoplay = NO;
    [mplayer prepareToPlay];

}

// The call back
- (void) movieFinishedCallback:(NSNotification*) aNotification {
   
  //  MPMoviePlayerController *player = [aNotification object];
    /*[[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:MPMoviePlayerPlaybackDidFinishNotification
     object:player];*/
    
    //player.initialPlaybackTime = -1;
    //[player pause];
   // [player stop];
    
    //[player.view removeFromSuperview];
    
    // call autorelease the analyzer says call too many times
    // call release the analyzer says incorrect decrement
}




#pragma mark - audio recording methods

/*called when a new recording is being made, does all the initialization for file names etc */ 
- (void)newRecording {
    
    _playButton.enabled = NO;
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    if([fileNameText.text isEqualToString:@""]){
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"-yyyy-MM-dd_'at'_HH-mm-ss"];
        now = [NSDate date];
        NSString *created = [formatter stringFromDate:now];
        NSString *appPatientRecordId = [LocalTalk localGetPatientRecordAppId];
        fileNameText.text = [appPatientRecordId stringByAppendingString:created]; //figure this out
    }
    NSString *audioFilePath = [NSString stringWithFormat:@"%@/%@.caf", docsDir, fileNameText.text];
    
    soundFileURL = [NSURL fileURLWithPath:audioFilePath];
    
    NSDictionary *recordSettings = [NSDictionary
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin],
                                    AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16],
                                    AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2],
                                    AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0],
                                    AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    
    _audioRecorder = [[AVAudioRecorder alloc]
                      initWithURL:soundFileURL
                      settings:recordSettings
                      error:&error];
    
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [_audioRecorder prepareToRecord];
    }
}

/*IBAction for when the record audio button is pressed, allows for the audio to 
 be paused mid recording 
 //TODO: change the buttons appearance when clicked 
 */
- (IBAction)recordAudio:(id)sender {
    
    /*if not recording */
    if (!_audioRecorder.recording)
    {
        if(isPaused){ //start recording again
            _playButton.enabled = NO;
            isPaused = NO;
            /*IMPLEMENT: call method to change button to pause button*/
            [_audioRecorder record];
        } else {
            //initialize a new file and start recording
            [self newRecording];
            /*IMPLEMENT: call method to change button to pause button*/
            [_audioRecorder record];
        }
        /*if it is recording just pause it*/
    } else if(_audioRecorder.recording) {
        /*IMPLEMENT: call method to change the button to record*/
        isPaused = YES;
        [_audioRecorder pause];
    }
}

//Play audio you just recorded with this button 
- (IBAction)playAudio:(id)sender {
    if (!_audioRecorder.recording)
    {
        _recordButton.enabled = NO;
        
        NSError *error;
        
        _audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:_audioRecorder.url
                        error:&error];
        
        _audioPlayer.delegate = self;
        
        if (error)
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        else
            [_audioPlayer play];
    }
}

//save audio that you have just recorded with this button
//this inserts the file straight into sqlite with the setSQLite table method
- (IBAction)saveRecord:(id)sender{
    [_audioRecorder stop];
    NSError *error;
    NSData *audioData = [NSData dataWithContentsOfFile:[soundFileURL path] options:0 error:&error];
    NSString *audioDataAsText = [Base64 encode:audioData];
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        NSMutableArray *insertArray = [[NSMutableArray alloc]init];
        NSString *recordTypeId = [AdminInformation getOperationRecordTypeIdByName:@"Audio"];
        NSString *appPatientRecordId = [LocalTalk localGetPatientRecordAppId];
        //NSString *path = [NSNull null];
        NSDictionary *dictionary = @{@"AppPatientRecordId" : appPatientRecordId,
                                     @"RecordTypeId"       : recordTypeId,
                                     @"Name"               : fileNameText.text,
                                     @"Path"               : [NSNull null],
                                     @"Data"               : audioDataAsText,
                                     @"IsProfile"          : @"0" };
        [insertArray addObject:dictionary];
        NSMutableArray *retval = [LocalTalk setSQLiteTable:@"OperationRecord" withData:insertArray];
        for(NSString *key in retval){
            if(key == 0){
                NSLog(@"Mischa's shit did not work sorry bro");
            }
        }
        
    }
    _playButton.enabled = YES;
    [fileNameText insertText:@""];
}

#pragma mark - audio recording delegate methods

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if(player == _audioPlayer) {
        _recordButton.enabled = YES;
    }
    else if (player == _audioPlayerForButton){
        [tmp setTitle:@"Play" forState:UIControlStateNormal];
        [tmp setBackgroundColor:[UIColor greenColor]];
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}



#pragma mark - camera methods
- (void) useCamera:(id)sender{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
        _newMedia = YES;
    }
}


#pragma mark - camera delegate methods
/*
 -(void)imagePickerController:(UIImagePickerController *)picker
 didFinishPickingMediaWithInfo:(NSDictionary *)info{
 
 [self dismissViewControllerAnimated:YES completion:nil];
 
 //Store the image for the patient
 
 // photoID = finalImage;
 // newPatient.photoID = finalImage;
 
 //Display the final image
 //_imageView.image = finalImage;
 
 }*/



#pragma mark - table view data source methods 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return audioCellsArray.count;
}
- (NSString *)getDurationLabelString:(AVAudioPlayer *)audioPlayer {
    NSTimeInterval theTimeInterval = audioPlayer.duration;
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Create the NSDates
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:theTimeInterval sinceDate:date1];
    // Get conversion to hours, minutes, seconds
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:date1  toDate:date2  options:0];
    NSLog(@"%02d:%02d:%02d", [breakdownInfo hour], [breakdownInfo minute], [breakdownInfo second]);
    NSString *length = [NSString stringWithFormat:@"%02d:%02d:%02d", [breakdownInfo hour], [breakdownInfo minute], [breakdownInfo second]];
    return length;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *audioCellID = @"audioCellId";
    //static NSString *pictureCellID = @"pictureID";
    
    SurgeryListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:audioCellID forIndexPath:indexPath];
    int row = [indexPath row];
    NSDictionary *audioFileInformation = [audioCellsArray objectAtIndex:row];
    NSString *fileNameFromDb = [audioFileInformation objectForKey:@"Name"];
    cell.fileName.text = fileNameFromDb;
    cell.playButton.tag = [indexPath row];
    [cell.playButton setBackgroundColor:[UIColor greenColor]];
    NSLog(@"%d", cell.playButton.tag);
    
    NSString *selectedAudioFileAsString = [audioFileInformation objectForKey:@"Data"];
    NSData *selectedAudioFile = [Base64 decode:selectedAudioFileAsString];
    NSError *error;
    _audioPlayerForButton = [[AVAudioPlayer alloc] initWithData:selectedAudioFile error:&error];
    
    NSString *length = [self getDurationLabelString:_audioPlayerForButton];
    cell.audioFileLength.text = length;
        
    return cell;
    
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

/*this method is activated when you click the play button on any
 of the files in the table cells */

- (IBAction)useSelectedFile:(id)sender {
    tmp = (UIButton*)sender;
    
    if ([_audioPlayerForButton isPlaying]){
        [_audioPlayerForButton pause];
        [tmp setTitle:@"Play" forState:UIControlStateNormal];
        [tmp setBackgroundColor:[UIColor greenColor]];
    } else {
        [_audioPlayerForButton stop];
        //  _audioPlayerForButton = nil;
        int tag = tmp.tag;
        NSLog(@"%d", tag);
        NSDictionary *audioFileInformation = [audioCellsArray objectAtIndex:tag];
        NSString *selectedAudioFileAsString = [audioFileInformation objectForKey:@"Data"];
        NSData *selectedAudioFile = [Base64 decode:selectedAudioFileAsString];
        NSError *error;
        _audioPlayerForButton = [[AVAudioPlayer alloc] initWithData:selectedAudioFile error:&error];
        _audioPlayerForButton.delegate = self;
        if (error)
            NSLog(@"Error: %@",
                  [error localizedDescription]);
        else { [_audioPlayerForButton play];
            [tmp setTitle:@"Pause" forState:UIControlStateNormal];
            [tmp setBackgroundColor:[UIColor redColor]];
        }
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
