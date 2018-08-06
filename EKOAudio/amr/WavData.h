//
//  WavData.h
//  test-app
//
//  Created by  apple on 11-8-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdio.h>

typedef  struct  {
    
    char        fccID[4];
    int32_t      dwSize;
    char        fccType[4];
    
} WAVE_HEADER;

typedef  struct  {
    
    char        fccID[4];
    int32_t      dwSize;
    int16_t      wFormatTag;
    int16_t      wChannels;
    int32_t      dwSamplesPerSec;
    int32_t      dwAvgBytesPerSec;
    int16_t      wBlockAlign;
    int16_t      uiBitsPerSample;
    
}WAVE_FMT;

typedef  struct  {
    
    char        fccID[4];
    int32_t      dwSize;
    
}WAVE_DATA;

#define kWaveHeaderSize (sizeof(WAVE_HEADER) + sizeof(WAVE_FMT) + sizeof(WAVE_DATA))

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
