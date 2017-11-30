//
//  PocketsphinxDecoder.m
//  PocketsphinxTest
//
//  Created by Ira on 16.11.17.
//  Copyright © 2017 IraNikolenko. All rights reserved.
//

#import "PocketsphinxDecoder.h"

static const arg_t vk_args_def[] = {
    POCKETSPHINX_OPTIONS,
    /* Argument file. */
    { "-argfile",
        ARG_STRING,
        NULL,
        "Argument file giving extra arguments." },
    { "-adcdev", ARG_STRING, NULL, "Name of audio device to use for input." },
    CMDLN_EMPTY_OPTION
};

int frameRate = 100;
int rv;

@implementation PocketsphinxDecoder

/*
private File wav;

*/

- (id) initWithConfigFile:(NSString*)config {
    self = [super init];
    if (self) {
        _configFile = config;
        _ps = nil;
        _config = nil;
    }
    return self;
}

- (cmd_ln_t*) config {
    if (_config) { return _config; }
    
    _config = cmd_ln_parse_file_r(NULL, vk_args_def, [self.configFile UTF8String], TRUE);
    
    return _config;
}

- (void) setConfigString:(NSString*)str forKey:(NSString*)key {
    cmd_ln_set_str_r([self config], [key UTF8String], [str UTF8String]);
}

- (void) setConfigInt:(int)iValue forKey:(NSString*)key {
    cmd_ln_set_int_r([self config], [key UTF8String], iValue);
}

- (void) setConfigFloat:(float)fValue forKey:(NSString*)key {
    cmd_ln_set_float_r([self config], [key UTF8String], fValue);
}

- (void) setAllPhoneFileWithName:(NSString *)name andPath:(NSString *)path{
    ps_set_allphone_file(self.ps, [name UTF8String], [path UTF8String]);
}

- (void) setSearchWithName:(NSString *)name{
    ps_set_search(self.ps, [name UTF8String]);
}

- (int) processRawWithData:(const int16 *)data andSize:(size_t)size andSearch:(int)search andFullUtt:(int)fullUtt {
    int i = ps_process_raw(self.ps, data, size, search, fullUtt);
    return i;
}

- (ps_decoder_t*) ps {
    if (_ps) { return _ps; }
    
    _ps = ps_init([self config]);
    
    return _ps;
}

- (void) startDecode {
    rv = ps_start_utt([self ps]);
    NSLog(@"rv(ps_START_utt): %d", rv);
}
- (void) stopDecode {
    rv = ps_end_utt([self ps]);
    NSLog(@"rv(ps_END_utt): %d", rv);
}

- (NSString *)getSegments{
    
    [self getSeg:ps_seg_iter(self.ps)];
    
    return @"jkfdhf";
}

-(void)getSeg:(ps_seg_t*) segIter{
    int out_sf;
    int out_ef;
    if(segIter && segIter!=nil){
    ps_seg_frames((segIter), &out_sf, &out_ef);
    char const * word = ps_seg_word(segIter);
    NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
    [self getSeg:ps_seg_next(segIter)];
    } else {
        return;
    }
}

- (void) printDebug {
    int32 score;
    
    
    const char* hyp = ps_get_hyp([self ps], &score);
    NSLog(@"M=%s", hyp);
}

- (void) dealloc {
    // Are we leaking _config?
    if (_ps) {
        ps_free(_ps);
    }
}

//- (void) getSegmentList {
////    Assets assets = null;
//    //    File assetsDir = null;
//
//    PocketsphinxDecoder *decoder = [[PocketsphinxDecoder alloc] initWithConfigFile:[[NSBundle mainBundle] pathForResource:@"pocketsphinx" ofType:@"conf" ]];
//    [decoder setConfigString:[[NSBundle mainBundle] pathForResource:@"cmu07a"
//                                                             ofType:@"dic"
//                                                        inDirectory:@"lm/en_US"]
//                      forKey:@"-dict"];
//
//    [decoder setConfigString:[[NSBundle mainBundle] pathForResource:@"wsj0vp.5000"
//                                                             ofType:@"DMP"
//                                                        inDirectory:@"lm/en_US"]
//                      forKey:@"-lm"];
//
//    [decoder setConfigString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"hmm/hub4wsj_sc_8k"]
//                      forKey:@"-hmm"];
//
//    [decoder setAllPhoneFileWithName:@"phone" andPath:[[NSBundle mainBundle] pathForResource:@"en-phone" ofType:@"dmp" inDirectory:@"lm/en_US"]];
//
//    [decoder setSearchWithName:@"phone"];
//
//    NSInputStream *stream = nil;
//    NSMutableData *audioData = nil;
//
////                    File sdCard = Environment.getExternalStorageDirectory();
////                    File dir = new File (sdCard.getAbsolutePath() + "/Halogram");
////                    File wav = new File(dir,"testAlla.wav");
////    NSLog(@"File path: ", wav.getAbsolutePath());
//
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"brian" ofType:@"wav"];
//
//    @try {
//        audioData = [NSMutableData dataWithContentsOfFile:filePath];
//        stream = [[NSInputStream alloc] initWithData:audioData];
////        stream = [[NSInputStream alloc] initWithFileAtPath:filePath];
//    } @catch (NSError *error) {
//        NSLog(@"Error: %@ from: %@",error.description, NSStringFromSelector(_cmd));
//    }
//
//    [decoder startDecode];
//
//    long l = 4096;
//    char bytes[sizeof(long)];
//    memcpy(bytes,&l,sizeof(l));
//    uint8_t buf[4096];
//
//    @try {
//        NSInteger nbytes;
////        uint8_t *data = (uint8_t *)[audioData bytes];
////        while ((nbytes = [stream read:buf maxLength:l])>=0) {
////
////            NSUInteger audioLength = [audioData length];
////
////            Byte *byteData = (Byte*)malloc(audioLength);
////            memcpy(byteData, [audioData bytes], audioLength);
////
////            short *shortData = (short*)malloc(audioLength/2);
////
////            for (int i=0; i<audioLength; i++){
////                shortData[i] = byteData[i];
////            };
////
////
////
////            [decoder processRawWithData:shortData andSize:nbytes/2 andSearch:0 andFullUtt:0];
////        }
////        int16 *data = (int16 *)[audioData bytes];
//
//        [decoder processRawWithData:[audioData bytes] andSize:[audioData length]/2 andSearch:0 andFullUtt:0];
//        NSLog(@"%ld", (long)nbytes);
//    } @catch (NSException *exception) {
//        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
//    }
//    [decoder stopDecode];
//
//    @try {
//        [stream close];
//        NSString * res = [self getSegments];
//        NSLog(@"Recognititon result: %@ ", res);
////        [self printDebug];
//    } @catch (NSException *exception) {
//        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
//    }
//
////    return decoder.seg();
//}

@end
