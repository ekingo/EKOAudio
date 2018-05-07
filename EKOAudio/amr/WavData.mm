//
//  TestWav.m
//  test-app
//
//  Created by  apple on 11-8-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "WavData.h"


@implementation WavData

-(WavData*)initTestWav:(const char*)filename sample:(int)SampleRate bits:(int)BitsPerSample channels:(int)Channels {
    if (self = [super init]) {
        wav = fopen(filename, "wb");
        if (wav == NULL)
            return nil;
        dataLength = 0;
        sampleRate = SampleRate;
        bitsPerSample = BitsPerSample;
        channels = Channels;
        
        [self writeHeader:dataLength];
    }
    return self;
}

-(void)dealloc {
    if (wav == NULL)
		return;
	fseek(wav, 0, SEEK_SET);
	[self writeHeader:dataLength];
	fclose(wav);
    
    //[super dealloc];
}

-(void)writeData:(const unsigned char*)data length:(int)length {
    if (wav == NULL)
		return;
	fwrite(data, length, 1, wav);
	dataLength += length;
}

-(void)writeString:(const char*)str {
    fputc(str[0], wav);
	fputc(str[1], wav);
	fputc(str[2], wav);
	fputc(str[3], wav);
}

-(void)writeInt32:(int)value {
    fputc((value >>  0) & 0xff, wav);
	fputc((value >>  8) & 0xff, wav);
	fputc((value >> 16) & 0xff, wav);
	fputc((value >> 24) & 0xff, wav);
}
-(void)writeInt16:(int)value {
    fputc((value >> 0) & 0xff, wav);
	fputc((value >> 8) & 0xff, wav);
}

-(void)writeHeader:(int)length {
    [self writeString:"RIFF"];
	[self writeInt32:(4 + 8 + 16 + 8 + length)];
	[self writeString:"WAVE"];
    
	[self writeString:"fmt "];
	[self writeInt32:16];
    
	int bytesPerFrame = bitsPerSample/8*channels;
	int bytesPerSec = bytesPerFrame*sampleRate;
	[self writeInt16:1];             // Format
	[self writeInt16:channels];      // Channels
	[self writeInt32:sampleRate];    // Samplerate
	[self writeInt32:bytesPerSec];   // Bytes per sec
	[self writeInt16:bytesPerFrame]; // Bytes per frame
	[self writeInt16:bitsPerSample]; // Bits per sample
    
	[self writeString:"data"];
	[self writeInt32:length];
}


@end
