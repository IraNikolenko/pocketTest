//
//  ViewController.m
//  PocketsphinxTest
//
//  Created by Ira on 16.11.17.
//  Copyright © 2017 IraNikolenko. All rights reserved.
//

#import "ViewController.h"
#include "PocketsphinxDecoder.h"

@interface ViewController (){
    NSURL *recordedAudioURL;
    AVAudioRecorder *userAudioRecorder;
    AVAudioPlayer *_audioPlayer;
    PocketsphinxDecoder *decoder;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    decoder = [[PocketsphinxDecoder alloc] init];
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
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:[err localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    //prepare to record
    [userAudioRecorder setDelegate:self];
    [userAudioRecorder prepareToRecord];
    userAudioRecorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Audio input hardware not available" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    [userAudioRecorder record];

}

- (IBAction)stop:(id)sender {
    [userAudioRecorder stop];
    [decoder getSegmentList:[recordedAudioURL path]];
    
}


- (IBAction)playAudio:(id)sender {
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:recordedAudioURL error:nil];
    [_audioPlayer play];
}

@end
