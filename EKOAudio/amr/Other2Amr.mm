//
//  Other2Amr.m
//  PetFone_EnterPrise_iPhone
//
//  Created by  apple on 11-10-13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "audiocodec.h"
#import "Other2Amr.h"
#import "WavData.h"

typedef struct
{
    char chChunkID[4];
    int nChunkSize;
}XCHUNKHEADER;

typedef struct
{
    short nFormatTag;
    short nChannels;
    int nSamplesPerSec;
    int nAvgBytesPerSec;
    short nBlockAlign;
    short nBitsPerSample;
}WAVEFORMAT;

typedef struct
{
    short nFormatTag;
    short nChannels;
    int nSamplesPerSec;
    int nAvgBytesPerSec;
    short nBlockAlign;
    short nBitsPerSample;
    short nExSize;
}WAVEFORMATX;

typedef struct
{
    char chRiffID[4];
    int nRiffSize;
    char chRiffFormat[4];
}RIFFHEADER;

typedef struct
{
    char chFmtID[4];
    int nFmtSize;
    WAVEFORMAT wf;
}FMTBLOCK;

int WAVFileDataIndex(NSData *srcData)
{
    RIFFHEADER riff;
    FMTBLOCK fmt;
    XCHUNKHEADER chunk;
    WAVEFORMATX wfx;
    int bDataBlock = 0;
    
    if (srcData.length < 0x1000) {
        return 44;
    }
    
    char *src = (char*)srcData.bytes;
    // 1. 读RIFF头
    memcpy(&riff, src, sizeof(RIFFHEADER));
    src += sizeof(RIFFHEADER);
    
    // 2. 读FMT块 - 如果 fmt.nFmtSize>16 说明需要还有一个附属大小没有读
    memcpy(&chunk, src, sizeof(XCHUNKHEADER));
    src += sizeof(XCHUNKHEADER);
    if ( chunk.nChunkSize > 16 )
    {
        memcpy(&wfx, src, sizeof(WAVEFORMATX));
        src += sizeof(WAVEFORMATX);
    }
    else
    {
        memcpy(fmt.chFmtID, chunk.chChunkID, 4);
        fmt.nFmtSize = chunk.nChunkSize;
        memcpy(&fmt.wf, src, sizeof(WAVEFORMAT));
        src += sizeof(WAVEFORMAT);
    }
    
    // 3.转到data块 - 有些还有fact块等。
    while(!bDataBlock)
    {
        memcpy(&chunk, src, sizeof(XCHUNKHEADER));
        src += sizeof(XCHUNKHEADER);
        if ( !memcmp(chunk.chChunkID, "data", 4) )
        {
            bDataBlock = 1;
            break;
        }
        // 因为这个不是data块,就跳过块数据
        src += chunk.nChunkSize;
    }
    int ret =  int(src - (char*)srcData.bytes);
    return ret;
}

void SkipToPCMAudioData(FILE* fpwave)
{
    RIFFHEADER riff;
    FMTBLOCK fmt;
    XCHUNKHEADER chunk;
    WAVEFORMATX wfx;
    int bDataBlock = 0;
    
    // 1. 读RIFF头
    fread(&riff, 1, sizeof(RIFFHEADER), fpwave);
    
    // 2. 读FMT块 - 如果 fmt.nFmtSize>16 说明需要还有一个附属大小没有读
    fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    if ( chunk.nChunkSize > 16 )
    {
        fread(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    }
    else
    {
        memcpy(fmt.chFmtID, chunk.chChunkID, 4);
        fmt.nFmtSize = chunk.nChunkSize;
        fread(&fmt.wf, 1, sizeof(WAVEFORMAT), fpwave);
    }
    
    // 3.转到data块 - 有些还有fact块等。
    while(!bDataBlock)
    {
        fread(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
        if ( !memcmp(chunk.chChunkID, "data", 4) )
        {
            bDataBlock = 1;
            break;
        }
        // 因为这个不是data块,就跳过块数据
        fseek(fpwave, chunk.nChunkSize, SEEK_CUR);
    }
}

@interface Other2Amr()
{
    AMRNBEnc*       _amrEncoder;
}

@end


@implementation Other2Amr
@synthesize sourcePath, destPath;

-(Other2Amr*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination {
    if (self = [super init]) {
        self.sourcePath = source;
        self.destPath = destination;
        
        _amrEncoder = (AMRNBEnc*)createAudioEnc("amrnb");
        if (_amrEncoder == NULL) {
            NSLog(@"null!");
            return nil;
        }
    }
    return self;
}

- (instancetype)init{
    if (self = [super init]) {
        _amrEncoder = (AMRNBEnc*)createAudioEnc("amrnb");
        if (_amrEncoder == NULL) {
            NSLog(@"null!");
            return nil;
        }
    }
    
    return self;
}


-(void)dealloc {
    self.sourcePath = nil;
    self.destPath = nil;
    
    destroyAudioEnc(_amrEncoder);
    
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
    int framesize = [[self class] frameSize];//amrEncoder->getEncFreameSize();
    
    SkipToPCMAudioData(inFile);//跳过WAV文件数据部分
    
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
        int encLength = _amrEncoder->Enc(outbuffer,buffer,framesize);
        if (encLength) {
            fwrite(outbuffer, encLength, 1, outFile);
        }
    }
    
	fclose(inFile);
    fclose(outFile);
    NSLog(@"Convert successfully path=%@!!", self.destPath);
    return YES;
}

+ (int)frameSize{
    return 320;
}

+(BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest{
    //每次转换的字节大小, 这里一般是320
    int framesize = [self frameSize];//amrEncoder->getEncFreameSize();
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
        
        if (loc+framesize > [src length]) {
            break;
        }
    }
    destroyAudioEnc(armEnc);
    
    return YES;
}

- (BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest{
    //每次转换的字节大小, 这里一般是320
    int framesize = [[self class] frameSize];//amrEncoder->getEncFreameSize();
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
        int encLength = _amrEncoder->Enc(outbuffer,buffer,framesize);
        [dest appendBytes:outbuffer length:encLength];
        
        if (loc+framesize > [src length]) {
            break;
        }
    }
    
    return YES;
}
    
@end
