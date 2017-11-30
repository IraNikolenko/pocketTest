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
    NSString *commands = nil;
    int prevEnd = 0;
    if(segIter && segIter!=nil){
    ps_seg_frames((segIter), &out_sf, &out_ef);
    char const * word = ps_seg_word(segIter);
        NSString *phonem = [NSString stringWithUTF8String:word];
    NSLog(@"word: %s  start: %d    end: %d", word, out_sf, out_ef);
        if([phonem isEqualToString:@"AA"] || [phonem isEqualToString:@"AH"] || [phonem isEqualToString:@"EH"] || [phonem isEqualToString:@"ER"] ||[phonem isEqualToString:@"EY"] || [phonem isEqualToString:@"AW"] || [phonem isEqualToString:@"AE"] || [phonem isEqualToString:@"AY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndTime:out_ef andLetter:@"A"]];
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"AO"] || [phonem isEqualToString:@"OW"] || [phonem isEqualToString:@"OY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndTime:out_ef andLetter:@"O"]];
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"UH"] || [phonem isEqualToString:@"UW"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndTime:out_ef andLetter:@"U"]];
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"IH"] || [phonem isEqualToString:@"IY"]) {
            commands = [NSString stringWithFormat:@"%@ %@", commands, [self newCommandWithPrevEnd:prevEnd andStartFrame:out_sf andEndTime:out_ef andLetter:@"E"]];
            prevEnd = out_ef;
        } else if ([phonem isEqualToString:@"P"] || [phonem isEqualToString:@"B"] || [phonem isEqualToString:@"M"] || [phonem isEqualToString:@"F"]) {
            commands = [NSString stringWithFormat:@"%@ %@%d ", commands, @"close ", (out_sf + (out_ef-out_sf)/2)];
        } else if ([phonem isEqualToString:@"SIL"]) {
            commands = [NSString stringWithFormat:@"%@ %@%d ", commands, @"close ", (out_sf)];
            commands = [NSString stringWithFormat:@"%@ %@%d ", commands, @"close ", (out_ef)];
            prevEnd = out_ef;
        }
        
    [self getSeg:ps_seg_next(segIter)];
    } else {
        commands = [NSString stringWithFormat:@"%@ %@%d ", commands, @"close ", (out_ef + 5)];
        return;
    }
}

-(NSString*) newCommandWithPrevEnd:(int) prevEnd andStartFrame:(int) start andEndTime:(int) end andLetter:(NSString*) letter{
    NSString *command = @"";
    int pause = 10;
    double koef = 1000/frameRate;
    
    if((start-prevEnd)*koef>600) {
//        command += "close " + (int) (prevEnd * koef + pause) + " ";
//        command += "close " + (int) (start * koef - pause) + " ";
    }
    command = [NSString stringWithFormat:@"%@ %@ %f %@", command, letter, (start*koef), @"0.6"];
    if((start-end)*koef<100)
        command = [NSString stringWithFormat:@"%@ %@ %f %@", command, letter, ((start+(end-start)/2)*koef), @"1"];
    else {
        command = [NSString stringWithFormat:@"%@ %@ %f %@", command, letter, (start * koef + 20), @"1"];
        command = [NSString stringWithFormat:@"%@ %@ %f %@", command, letter, (end * koef - 20), @"1"];
    }
    command = [NSString stringWithFormat:@"%@ %@ %f %@", command, letter, (end * koef - 20), @"0.8"];
    
    return command;
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

@end
