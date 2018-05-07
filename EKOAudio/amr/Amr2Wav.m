//
//  Amr2Wav.m
//  PetFone_EnterPrise_iPhone
//
//  Created by  apple on 11-8-10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Amr2Wav.h"
#import <stdio.h>

const int sizes[] = { 12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0 };

@implementation Amr2Wav
@synthesize sourcePath, destPath;

-(Amr2Wav*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination {
    if (self = [super init]) {
        self.sourcePath = source;
        self.destPath = destination;
    }
    return self;
}
-(void)dealloc {
//    [self.sourcePath release];
//    [self.destPath release];
    
    //[super dealloc];
}

-(BOOL)startTransfer {
    if (self.sourcePath == nil || self.destPath == nil){
        NSLog(@"sourceFile or destFile is nil");
        return NO;
    }
    //开始转换
    FILE* in = fopen([self.sourcePath UTF8String], "rb");
	if (!in) {
        NSLog(@"open file :%@ failed",self.sourcePath);
		return NO;
	}
	char header[6];
	unsigned long n = fread(header, 1, 6, in);
	if (n != 6 || memcmp(header, "#!AMR\n", 6)) {
        NSLog(@"Bad header of AMR file!!");
        fclose(in);
		return NO;
	}
    WavData* wav = [[WavData alloc] initTestWav:[self.destPath UTF8String] sample:8000 bits:16 channels:1];
    void* amr = Decoder_Interface_init();
    while (true) {
		uint8_t buffer[500];
		 //Read the mode byte 
		n = fread(buffer, 1, 1, in);
		if (n <= 0)
			break;
        //Find the packet size 
		int size = sizes[(buffer[0] >> 3) & 0x0f];
		if (size <= 0)
			break;
		n = fread(buffer + 1, 1, size, in);
		if (n != size)
			break;
        
		//Decode the packet 
		int16_t outbuffer[160];
		Decoder_Interface_Decode(amr, buffer, outbuffer, 0);
        
		//Convert to little endian and write to wav 
		uint8_t littleendian[320];
		uint8_t* ptr = littleendian;
		for (int i = 0; i < 160; i++) {
			*ptr++ = (outbuffer[i] >> 0) & 0xff;
			*ptr++ = (outbuffer[i] >> 8) & 0xff;
		}
		[wav writeData:littleendian length:320];
	}
	fclose(in);
	Decoder_Interface_exit(amr);
    //[wav release];
    NSLog(@"Convert successfully path=%@!!", self.destPath);
    return YES;
}


@end
