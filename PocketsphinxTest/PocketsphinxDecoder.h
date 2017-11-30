//
//  PocketsphinxDecoder.h
//  PocketsphinxTest
//
//  Created by Ira on 16.11.17.
//  Copyright © 2017 IraNikolenko. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "pocketsphinx.h"
//#include "ps_search.h"

@interface PocketsphinxDecoder : NSObject {
    ps_decoder_t *_ps;
    
    cmd_ln_t *_config;
}

- (id) initWithConfigFile:(NSString*)config;
- (void) setConfigString:(NSString*)str forKey:(NSString*)key;
- (void) setConfigInt:(int)iValue       forKey:(NSString*)key;
- (void) setConfigFloat:(float)fValue   forKey:(NSString*)key;
- (NSString *)getSegments;
- (void) stopDecode;
- (void) startDecode;
- (void) setAllPhoneFileWithName:(NSString *)name andPath:(NSString *)path;
- (void) setSearchWithName:(NSString *)name;
- (int) processRawWithData:(const int16 *)data andSize:(size_t)size andSearch:(int)search andFullUtt:(int)fullUtt ;
//- (void) getSegmentList;
- (void) printDebug;

@property NSString* resultString;
@property (nonatomic, copy) NSString* configFile;
- (ps_decoder_t*) ps;
- (cmd_ln_t*) config;

@end
