//
//  WavData.h
//  test-app
//
//  Created by  apple on 11-8-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdio.h>

@interface WavData : NSObject {
    
    
	FILE *wav;
	int dataLength;
    
	int sampleRate;
	int bitsPerSample;
	int channels;
}

-(WavData*)initTestWav:(const char*)filename sample:(int)SampleRate bits:(int)BitsPerSample channels:(int)Channels;

-(void)writeData:(const unsigned char*)data length:(int)length;

-(void)writeString:(const char*)str;

-(void)writeInt32:(int)value;
-(void)writeInt16:(int)value;

-(void)writeHeader:(int)length;

@end
