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
- (void)newRecording {
    
    _playButton.enabled = NO;
    
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"-yyyy-MM-dd_'at'_HH-mm-ss"];
    now = [NSDate date];
    NSString *created = [formatter stringFromDate:now];
    NSString *appPatientRecordId = [LocalTalk localGetPatientRecordAppId];
    fileName = [appPatientRecordId stringByAppendingString:created]; //figure this out
    
    NSString *audioFilePath = [NSString stringWithFormat:@"%@/%@.caf", docsDir, fileName];
    
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

-(void)viewWillAppear:(BOOL)animated {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(updatedDataListener:) name:@"loadFromLocal" object:nil];
    
    NSArray *tables = @[@"OperationRecord"];
    NSDictionary *params = @{@"tableNames" : tables,
                             @"location" : @"surgeryViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tabloaded" object:self userInfo:params];
    
}

-(void)viewDidAppear:(BOOL)animated{
    //  fileNameText.text = now;
    /*listeners for history view controller*/
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [filesTable setDataSource:self];
    _playButton.enabled = NO;
    
	// Do any additional setup after loading the view.
}
-(void)updatedDataListener:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    if([[params objectForKey:@"location"] isEqualToString:@"surgeryViewController"]){
        NSMutableDictionary *data = [LocalTalk getData:params];
        files = data;
        for(NSString *key in files){
            if([key isEqualToString:@"OperationRecord"]){
                audioCellsArray = [files objectForKey:key];
            }
        }
        //NSLog(@"The updated data listener's data in Surgery VC is: %@", data);
        
        
    } else { NSLog(@"not in the right view controller");}
    [filesTable reloadData];
    
}

#pragma mark - audio recording button methods
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

- (IBAction)saveRecord:(id)sender{
    [_audioRecorder stop];
    NSError *error;
    NSData *audioData = [NSData dataWithContentsOfFile:[soundFileURL path] options: 0 error:&error];
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
                                     @"Name"               : fileName,
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
}

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

#pragma mark - user camera method
- (void) useCamera:(id)sender{
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *imagePicker =
        [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        //imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
        _newMedia = YES;
    }
}


#pragma mark - UIImagePickerControllerDelegate
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



#pragma mark - table view data source
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
    // Further changes such as text color whatever ...
    
    //
    /*  NSString *fn = [[patients objectAtIndex:row] firstName];
     NSString *mn = [[patients objectAtIndex:row] middleName];
     NSString *ln = [[patients objectAtIndex:row] lastName];
     NSString *name = [NSString stringWithFormat: @"%@ %@ %@", fn, mn, ln];
     cell.patientName.text = name;
     cell.chiefComplaint.text = (NSString*)[[patients objectAtIndex:row] chiefComplaint];
     cell.patientPicture.image = [[patients objectAtIndex:row] photoID];*/
    //cell.patientPicture.image = [UIImage imageNamed:_carImages[row]];
    
    return cell;
    
    
    // for(NSString *key in files){
    //  NSString *fileType = [[files objectForKey:key] fileTypeId];
    
    /*  if() {
     SessionCellClass *cell = nil;
     cell = (SessionCellClass *)[tableView dequeueReusableCellWithIdentifier:sessionCellID];
     if( !cell ) {
     //  do something to create a new instance of cell
     //  either alloc/initWithStyle or load via UINib
     }
     //  populate the cell with session model
     return cell;
     
     else {
     InfoCellClass *cell = nil;
     cell = (InfoCellClass *)[tableView dequeueReusableCellWithIdentifier:infoCellID];
     if( !cell ) {
     //  do something to create a new instance of info cell
     //  either alloc/initWithStyle or load via UINib
     // ...
     
     //  get the model object:
     myObject *person = [[self people] objectAtIndex:indexPath.row - 1];
     
     //  populate the cell with that model object
     //  ...
     return cell;
     }
     }*/
    /* static NSString *CellIdentifier = @"patientListCell";
     PatientListViewCell *cell = [tableView
     dequeueReusableCellWithIdentifier:CellIdentifier
     forIndexPath:indexPath];
     
     // Configure the cell...
     
     int row = [indexPath row];
     NSString *fn = [[patients objectAtIndex:row] firstName];
     NSString *mn = [[patients objectAtIndex:row] middleName];
     NSString *ln = [[patients objectAtIndex:row] lastName];
     NSString *name = [NSString stringWithFormat: @"%@ %@ %@", fn, mn, ln];
     cell.patientName.text = name;
     cell.chiefComplaint.text = (NSString*)[[patients objectAtIndex:row] chiefComplaint];
     cell.patientPicture.image = [[patients objectAtIndex:row] photoID];
     //cell.patientPicture.image = [UIImage imageNamed:_carImages[row]];
     
     return cell;*/
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





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
