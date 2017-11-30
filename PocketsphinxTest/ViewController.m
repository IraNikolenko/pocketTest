//
//  ViewController.m
//  PocketsphinxTest
//
//  Created by Ira on 16.11.17.
//  Copyright © 2017 IraNikolenko. All rights reserved.
//

#import "ViewController.h"
#include "PocketsphinxDecoder.h"
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController (){
    NSURL *recordedAudioURL;
    AVAudioRecorder *userAudioRecorder;
    AVAudioPlayer *_audioPlayer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self getSegmentList];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)listenStart:(id)sender {
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               [NSString stringWithFormat:@"%@.wav", [NSUUID UUID].UUIDString],
                               nil];
    recordedAudioURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSLog(@"Recording File Path dir: %@", recordedAudioURL);
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];

    
    // initiate recorder
//    NSError *error;
//    userAudioRecorder = [[AVAudioRecorder alloc] initWithURL:recordedAudioURL settings:recordSetting error:&error];
//    userAudioRecorder.delegate = self;
//    if (error)
//    {
//        NSLog(@"*********************");
//        NSLog(@"Error in initializing: %@", [error localizedDescription]);
//        NSLog(@"*********************");
//    } else {
//        [userAudioRecorder record];
//    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    
    err = nil;
    userAudioRecorder = [[ AVAudioRecorder alloc] initWithURL:recordedAudioURL settings:recordSetting error:&err];
    if(!userAudioRecorder){
        NSLog(@"recorder: %@ %ld %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: [err localizedDescription]
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //prepare to record
    [userAudioRecorder setDelegate:self];
    [userAudioRecorder prepareToRecord];
    userAudioRecorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available"
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    
    // start recording
    [userAudioRecorder record];

}

- (IBAction)stop:(id)sender {
    [userAudioRecorder stop];
    [self getSegmentList:[userAudioRecorder url]];
    
}

- (void) getSegmentList:(NSURL *)url{
    //    Assets assets = null;
    //    File assetsDir = null;
    
    PocketsphinxDecoder *decoder = [[PocketsphinxDecoder alloc] initWithConfigFile:[[NSBundle mainBundle] pathForResource:@"pocketsphinx" ofType:@"conf" ]];
    [decoder setConfigString:[[NSBundle mainBundle] pathForResource:@"cmu07a"
                                                             ofType:@"dic"
                                                        inDirectory:@"lm/en_US"]
                      forKey:@"-dict"];
    
    [decoder setConfigString:[[NSBundle mainBundle] pathForResource:@"wsj0vp.5000"
                                                             ofType:@"DMP"
                                                        inDirectory:@"lm/en_US"]
                      forKey:@"-lm"];
    
    [decoder setConfigString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"hmm/hub4wsj_sc_8k"]
                      forKey:@"-hmm"];
    
    [decoder setAllPhoneFileWithName:@"phone" andPath:[[NSBundle mainBundle] pathForResource:@"en-phone" ofType:@"dmp" inDirectory:@"lm/en_US"]];
    
    [decoder setSearchWithName:@"phone"];
    
    FILE * pFile;
    pFile = fopen ("brian.wav" , "r");
    
    NSInputStream *stream = nil;
    NSMutableData *audioData = nil;
    
    //                    File sdCard = Environment.getExternalStorageDirectory();
    //                    File dir = new File (sdCard.getAbsolutePath() + "/Halogram");
    //                    File wav = new File(dir,"testAlla.wav");
    //    NSLog(@"File path: ", wav.getAbsolutePath());
    
    NSString *filePath = [recordedAudioURL path];
    
    @try {
        audioData = [NSMutableData dataWithContentsOfFile:filePath];
        stream = [[NSInputStream alloc] initWithData:audioData];
        //        stream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    } @catch (NSError *error) {
        NSLog(@"Error: %@ from: %@",error.description, NSStringFromSelector(_cmd));
    }
    
    [decoder startDecode];
    
    long l = 4096;
    char bytes[sizeof(long)];
    memcpy(bytes,&l,sizeof(l));
    uint8_t buf[4096];
    
    @try {
        NSInteger nbytes;
        //        uint8_t *data = (uint8_t *)[audioData bytes];
        //        while ((nbytes = [stream read:buf maxLength:l])>=0) {
        //
        //            NSUInteger audioLength = [audioData length];
        //
        //            Byte *byteData = (Byte*)malloc(audioLength);
        //            memcpy(byteData, [audioData bytes], audioLength);
        //
        //            short *shortData = (short*)malloc(audioLength/2);
        //
        //            for (int i=0; i<audioLength; i++){
        //                shortData[i] = byteData[i];
        //            };
        //
        //
        //
        //            [decoder processRawWithData:shortData andSize:nbytes/2 andSearch:0 andFullUtt:0];
        //        }
        //        int16 *data = (int16 *)[audioData bytes];
        
        
        int i = [decoder processRawWithData:[audioData bytes] andSize:[audioData length]/2 andSearch:0 andFullUtt:0];
        NSLog(@"shjdgfksjdhf %d", i);
        
        
    } @catch (NSException *exception) {
        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
    }
    [decoder stopDecode];
    
    @try {
        [stream close];
        [decoder printDebug];
        [decoder getSegments];
//        NSString * res = [decoder getSegments];
//        NSLog(@"Recognititon result: %@ ", res);
        //        [self printDebug];
    } @catch (NSException *exception) {
        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
    }
    
    //    return decoder.seg();
}
- (IBAction)playAudio:(id)sender {
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedAudioURL error:nil];
    [_audioPlayer play];
}

@end
