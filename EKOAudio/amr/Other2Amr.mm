//
//  Other2Amr.m
//  PetFone_EnterPrise_iPhone
//
//  Created by  apple on 11-10-13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "audiocodec.h"
#import "Other2Amr.h"

@interface Other2Amr()
{
    AMRNBEnc*       amrEncoder;
}

@end


@implementation Other2Amr
@synthesize sourcePath, destPath;

-(Other2Amr*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination {
    if (self = [super init]) {
        self.sourcePath = source;
        self.destPath = destination;
        
        amrEncoder = (AMRNBEnc*)createAudioEnc("amrnb");
        if (amrEncoder == NULL) {
            NSLog(@"null!");
            return nil;
        }
    }
    return self;
}
-(void)dealloc {
    self.sourcePath = nil;
    self.destPath = nil;
    
    destroyAudioEnc(amrEncoder);
    
    //[super dealloc];
}

-(BOOL)startTransfer {
    if (self.sourcePath == nil || self.destPath == nil)
        return NO;
    //开始转换
    FILE* inFile = fopen([self.sourcePath UTF8String], "rb");
	if (!inFile) {
        NSLog(@"源文件不存在 or 不可读 ");
		return NO;
	}
    
    //创建输出文件
    FILE* outFile = fopen([self.destPath UTF8String], "wb");
    fwrite("#!AMR\n", 1, 6, outFile);
    //每次转换的字节大小, 这里一般是320
    int framesize = 320;//amrEncoder->getEncFreameSize();
    while (YES) {
        uint8_t buffer[framesize];
        memset(buffer, 0, framesize);
        //Read the mode byte 
		size_t n = fread(buffer, framesize, 1, inFile);
		if (n <= 0)
			break;
        
		//Decode the packet 
		uint8_t outbuffer[500];
        memset(outbuffer, 0, 500);
        int encLength = amrEncoder->Enc(outbuffer,buffer,framesize);
        if (encLength) {
            fwrite(outbuffer, encLength, 1, outFile);
        }
    }
    
	fclose(inFile);
    fclose(outFile);
    NSLog(@"Convert successfully path=%@!!", self.destPath);
    return YES;
}

+(BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest{
    //每次转换的字节大小, 这里一般是320
    int framesize = 320;//amrEncoder->getEncFreameSize();
    AMRNBEnc *armEnc = (AMRNBEnc*)createAudioEnc("amrnb");
    NSUInteger loc = 0;
    
    while (YES) {
        uint8_t buffer[framesize];
        memset(buffer, 0, framesize);
        //Read the mode byte
        if (loc>=[src length]) {
            break;
        }else if(loc+framesize>[src length]){
            //超出最大长度了
            framesize = (int)(src.length-loc);
        }
    
        [src getBytes:buffer range:NSMakeRange(loc, framesize)];
        loc += framesize;
        
        //Decode the packet
        uint8_t outbuffer[500];
        memset(outbuffer, 0, 500);
        int encLength = armEnc->Enc(outbuffer,buffer,framesize);
        [dest appendBytes:outbuffer length:encLength];
        
        if (loc+framesize >= [src length]) {
            break;
        }
    }
    destroyAudioEnc(armEnc);
    
    return YES;
}
    
@end
