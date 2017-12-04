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
NSString *commands = @"";

@implementation PocketsphinxDecoder

/*
private File wav;

*/

- (id) init {
    return [self initWithConfigFile:[[NSBundle mainBundle] pathForResource:@"pocketsphinx" ofType:@"conf" ]];
}

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

-(NSString *)getSeg:(ps_seg_t*) segIter{
    int out_sf;
    int out_ef;
    int prevEnd = 0;
    if(segIter && segIter!=nil){
    ps_seg_frames((segIter), &out_sf, &out_ef);
    char const * word = ps_seg_word(segIter);
        NSString *phonem = [NSString stringWithUTF8String:word];
    
        if([phonem isEqualToString:@"AA"] || [phonem isEqualToString:@"AH"] || [phonem isEqualToString:@"EH"] || [phonem isEqualToString:@"ER"] ||[phonem isEqualToString:@"EY"] || [phonem isEqualToString:@"AW"] || [phonem isEqualToString:@"AE"] || [phonem isEqualToString:@"AY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndFrame:out_ef andLetter:@"A"]];
            NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"AO"] || [phonem isEqualToString:@"OW"] || [phonem isEqualToString:@"OY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndFrame:out_ef andLetter:@"O"]];
            NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"UH"] || [phonem isEqualToString:@"UW"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndFrame:out_ef andLetter:@"U"]];
            NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"IH"] || [phonem isEqualToString:@"IY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndFrame:out_ef andLetter:@"I"]];
            NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"P"] || [phonem isEqualToString:@"B"] || [phonem isEqualToString:@"M"] || [phonem isEqualToString:@"F"]) {
            commands = [NSString stringWithFormat:@"%@ %@ %d ", commands, @"empty", (out_sf + (out_ef-out_sf)/2)];
        } else if ([phonem isEqualToString:@"SIL"]) {
            int interval = (out_ef - out_sf) * 10;
            commands = [NSString stringWithFormat:@"%@ %@ %d", commands, @"empty", interval];
            NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
            prevEnd = out_ef;
        }
    [self getSeg:ps_seg_next(segIter)];
    } else {
        commands = [NSString stringWithFormat:@"%@ %@ %d ", commands, @"empty ", 5];
        return commands;
    }
    return commands;
}

-(NSString*) newCommandWithPrevEnd:(int) prevEnd andStartFrame:(int) start andEndFrame:(int) end andLetter:(NSString*) letter{
    NSString *mouthCommand = @"mouth";
    NSString *emptyCommand = @"empty";
    NSString *resultString = nil;
    double koef = 10;
    
    int interval = (end - start) * koef;
    if(interval <= 60) {
        resultString = [NSString stringWithFormat:@"%@ %@", emptyCommand, @"0"];
    } else if (interval > 70 && interval < 150) {
        int partTime = interval/2;
        resultString = [NSString stringWithFormat:@"%@%@ %@ %d %@ %@ %@%@ %@ %d", mouthCommand, letter, @"1", partTime, emptyCommand, @"0", mouthCommand, letter, @"-1", partTime];
    } else {
        int residual = interval - 150;
        int partTime = 75;
        resultString = [NSString stringWithFormat:@"%@%@ %@ %d %@ %d %@%@ %@ %d", mouthCommand, letter, @"1", partTime, emptyCommand, residual, mouthCommand, letter, @"-1", partTime];
    }
    
    return resultString;
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

- (void) getSegmentList:(NSString *)url{
    
    [self setConfigString:[[NSBundle mainBundle] pathForResource:@"cmu07a"
                                                             ofType:@"dic"
                                                        inDirectory:@"lm/en_US"]
                      forKey:@"-dict"];
    
    [self setConfigString:[[NSBundle mainBundle] pathForResource:@"wsj0vp.5000"
                                                             ofType:@"DMP"
                                                        inDirectory:@"lm/en_US"]
                      forKey:@"-lm"];
    
    [self setConfigString:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"hmm/hub4wsj_sc_8k"]
                      forKey:@"-hmm"];
    
    [self setAllPhoneFileWithName:@"phone" andPath:[[NSBundle mainBundle] pathForResource:@"en-phone" ofType:@"dmp" inDirectory:@"lm/en_US"]];
    
    [self setSearchWithName:@"phone"];
    
    FILE * pFile;
    pFile = fopen ("brian.wav" , "r");
    
    NSInputStream *stream = nil;
    NSMutableData *audioData = nil;
    
    @try {
        audioData = [NSMutableData dataWithContentsOfFile:url];
        stream = [[NSInputStream alloc] initWithData:audioData];
    } @catch (NSError *error) {
        NSLog(@"Error: %@ from: %@",error.description, NSStringFromSelector(_cmd));
    }
    
    [self startDecode];
    
    long l = 4096;
    char bytes[sizeof(long)];
    memcpy(bytes,&l,sizeof(l));
    
    @try {
        
        int i = [self processRawWithData:[audioData bytes] andSize:[audioData length]/2 andSearch:0 andFullUtt:0];
        NSLog(@"shjdgfksjdhf %d", i);
        
        
    } @catch (NSException *exception) {
        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
    }
    [self stopDecode];
    
    @try {
        [stream close];
        [self printDebug];
        _resultString = [self getSegments];
    } @catch (NSException *exception) {
        NSLog(@"Error: %@ from: %@", exception.description, NSStringFromSelector(_cmd));
    }
}

@end
