//
//  EKOAudioQueue.m
//  EKOAudio
//
//  Created by hujin on 2018/7/16.
//  Copyright © 2018 XTC. All rights reserved.
//

#import "EKOAudioQueue.h"

#import <EKOUtil/EKODevice.h>
#import <EKOUtil/EKOUtil.h>

#define kAQRecorderDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]stringByAppendingPathComponent:@"swtmp"]

@interface EKOAudioQueue()

@property (nonatomic, copy) NSString *audioFilePath;

@property (nonatomic, copy) EKODelayedBlockHandler delayBlock;

- (void)processAudioBuffer:(AudioQueueBufferRef)inBuffer packets:(UInt32)inNumPackets packetDesc:(const AudioStreamPacketDescription *)inPacketDesc;

@end

static void handleAudioInputBuffer (void                                *aqData,
                               AudioQueueRef                       inAQ,
                               AudioQueueBufferRef                 inBuffer,
                               const AudioTimeStamp                *inStartTime,
                               UInt32                              inNumPackets,
                               const AudioStreamPacketDescription  *inPacketDesc
                               ){
    EKOAudioQueue *audioQueue = (__bridge EKOAudioQueue *)aqData;
    
    //EKOAQRecorderState *recorderState = (EKOAQRecorderState *)aqData;
    
    [audioQueue processAudioBuffer:inBuffer packets:inNumPackets packetDesc:inPacketDesc];
}

void DeriveBufferSize (AudioQueueRef audioQueue,AudioStreamBasicDescription *ASBDescription, Float64 seconds,UInt32                       *outBufferSize) {
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = (*ASBDescription).mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue,kAudioQueueProperty_MaximumOutputPacketSize,&maxPacketSize,&maxVBRPacketSize);
    }
    
    Float64 numBytesForTime =
    (*ASBDescription).mSampleRate * maxPacketSize * seconds;
    *outBufferSize = numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize;
}

@implementation EKOAudioQueue

- (void)dealloc{
    //[super dealloc];
    
    if (self.delayBlock) {
        eko_cancel_delayed_block(self.delayBlock);
        self.delayBlock = nil;
    }
}

- (instancetype)initWithRecordingBlock:(EKOAQRecordingBlock)recordingBlock finishBlock:(EKOAQFinishBlock)finishBlock cancelBlock:(EKOAQCancelBlock)cancelBlock{
    self = [super init];
    if (self) {
        self.cancelBlock = cancelBlock;
        self.finishBlock = finishBlock;
        self.recordingBlock = recordingBlock;
    }
    
    return self;
}

- (void)startRecord{
    [self startRecordWithDuration:0];
}

- (void)startRecordWithDuration:(NSTimeInterval)duration{
    
    [self setRecordFormat];
    
    AudioFileTypeID fileType= kAudioFileWAVEType;
    
    AudioQueueNewInput (&_recorderState.mDataFormat,handleAudioInputBuffer,/*&_recorderState*/(__bridge void *)self,NULL,kCFRunLoopCommonModes,0,&_recorderState.mQueue);
    
    UInt32 dataFormatSize = sizeof (_recorderState.mDataFormat);
    AudioQueueGetProperty (_recorderState.mQueue,kAudioQueueProperty_StreamDescription,&_recorderState.mDataFormat,&dataFormatSize);
    
    self.audioFilePath = [self saveAudioFilePath];
    NSURL *audioFile = [NSURL fileURLWithPath:self.audioFilePath];
    
    //CFURLRef audioFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("output.wav"), kCFURLPOSIXPathStyle, false);
    
    CFURLRef audioFileURL = CFBridgingRetain(audioFile);
    
    AudioFileCreateWithURL(audioFileURL,fileType, &_recorderState.mDataFormat, kAudioFileFlags_EraseFile, &_recorderState.mAudioFile);
    
    DeriveBufferSize(_recorderState.mQueue, &_recorderState.mDataFormat, kAQBufferDurationSeconds,  &_recorderState.bufferByteSize);
    
    for (int i = 0; i < kAQNumberBuffers; ++i) {
        AudioQueueAllocateBuffer(_recorderState.mQueue,_recorderState.bufferByteSize,&_recorderState.mBuffers[i]);
        AudioQueueEnqueueBuffer (_recorderState.mQueue,_recorderState.mBuffers[i], 0, NULL);
    }
    
    // enable metering
    UInt32 enableMetering = YES;
    /*OSStatus status = */AudioQueueSetProperty(_recorderState.mQueue, kAudioQueueProperty_EnableLevelMetering, &enableMetering,sizeof(enableMetering));
    
    [self updatePeakMeters];
    
    _recorderState.mCurrentPacket = 0;
    _recorderState.mIsRunning = true;
    AudioQueueStart (_recorderState.mQueue,NULL);
    
    CFRelease(audioFileURL);
    
    if (duration>0) {
        ekoweakify(self);
        self.delayBlock = eko_perform_block_after_delay(duration, ^{
            ekostrongify(self);
            if (self.recorderState.mIsRunning) {
                [self stopRecord];
            }
        });
    }
}

- (void)stopRecord{
    if (_recorderState.mIsRunning) {
        AudioQueueFlush(_recorderState.mQueue);
        
        AudioQueueStop ( _recorderState.mQueue,true);
        _recorderState.mIsRunning = false;
        AudioQueueDispose (_recorderState.mQueue, true);
        AudioFileClose (_recorderState.mAudioFile);
    }
    
    if (self.delayBlock) {
        eko_cancel_delayed_block(self.delayBlock);
        self.delayBlock = nil;
    }
    
    if (self.finishBlock) {
        self.finishBlock(self, self.audioFilePath, [self totalFileDuration]);
    }
}

- (void)cancelRecord{
    if (_recorderState.mIsRunning) {
        _recorderState.mIsRunning = false;
        
        AudioQueueStop ( _recorderState.mQueue,true);
        AudioQueueDispose (_recorderState.mQueue, true);
        AudioFileClose (_recorderState.mAudioFile);
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath error:nil];
    
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
}

- (BOOL)isRecording{
    return self.recorderState.mIsRunning;
}

- (CGFloat)averagePower{
    AudioQueueLevelMeterState state[1];
    UInt32  statesize = sizeof(state);
    OSStatus status;
    status = AudioQueueGetProperty(_recorderState.mQueue, kAudioQueueProperty_CurrentLevelMeter, &state, &statesize);
    if (status){
        return 0.0f;
    }
    
    return state[0].mAveragePower;
}

- (CGFloat)peakPower{
    AudioQueueLevelMeterState state[1];
    UInt32  statesize = sizeof(state);
    OSStatus status;
    status = AudioQueueGetProperty(_recorderState.mQueue, kAudioQueueProperty_CurrentLevelMeter, &state, &statesize);
    if (status) {
        return 0.0f;
    }
    
    return state[0].mPeakPower;
}

#pragma mark - public methods
- (void)processAudioBuffer:(AudioQueueBufferRef)inBuffer packets:(UInt32)inNumPackets packetDesc:(const AudioStreamPacketDescription *)inPacketDesc{
    
    EKOAQRecorderState *pRecorderState = &_recorderState;
    
    if(inNumPackets == 0 && pRecorderState->mDataFormat.mBytesPerPacket!=0) {
        inNumPackets = inBuffer->mAudioDataByteSize / pRecorderState->mDataFormat.mBytesPerPacket;
    }
    
    if (AudioFileWritePackets (pRecorderState->mAudioFile,false,inBuffer->mAudioDataByteSize,inPacketDesc,pRecorderState->mCurrentPacket,&inNumPackets, inBuffer->mAudioData) == noErr) {
        pRecorderState->mCurrentPacket += inNumPackets;
    }
    if (pRecorderState->mIsRunning == 0)
        return;
    
    AudioQueueEnqueueBuffer(pRecorderState->mQueue,inBuffer,0,NULL);
    
    if (self.recordingBlock) {
        self.recordingBlock(self, [NSData dataWithBytes:inBuffer->mAudioData length:inBuffer->mAudioDataByteSize], [self totalRecordDuration]);
    }
}

#pragma mark - private methods
- (void)updatePeakMeters{
    if (self.peakMeterBlock) {
        if (self.recorderState.mIsRunning) {
            self.peakMeterBlock(self, [self peakPower], [self averagePower], [self totalRecordDuration]);
        }
        
        ekoweakify(self);
        eko_perform_block_after_delay(0.5, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                ekostrongify(self);
                [self updatePeakMeters];
            });
        });
    }
}

#pragma mark - setters & getters

- (void)setRecordFormat{
    // 设置录音格式
    memset(&_recorderState, 0, sizeof(EKOAQRecorderState));
    
    _recorderState.mDataFormat.mFormatID         = kAudioFormatLinearPCM;
    _recorderState.mDataFormat.mSampleRate       = 8000;
    _recorderState.mDataFormat.mChannelsPerFrame = 1;
    _recorderState.mDataFormat.mBitsPerChannel   = 16;
    _recorderState.mDataFormat.mBytesPerPacket   = _recorderState.mDataFormat.mBytesPerFrame =  _recorderState.mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    _recorderState.mDataFormat.mFramesPerPacket  = 1;
    _recorderState.mDataFormat.mFormatFlags = /*kLinearPCMFormatFlagIsBigEndian |*/ kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
}

- (NSString *)saveAudioFilePath{
    NSString *saveFolder = kAQRecorderDir;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:saveFolder] == NO) {
        [fileManager createDirectoryAtPath:saveFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    if (self.saveFolderPrefix) {
        saveFolder = [saveFolder stringByAppendingPathComponent:self.saveFolderPrefix];
        if ([fileManager fileExistsAtPath:saveFolder] == NO) {
            [fileManager createDirectoryAtPath:saveFolder withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    NSString *fullPath = [saveFolder stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@.wav",[EKODevice createUUID]]];
    
    return fullPath;
}

- (CGFloat)totalRecordDuration{

    CGFloat duration = _recorderState.mCurrentPacket*_recorderState.mDataFormat.mFramesPerPacket/_recorderState.mDataFormat.mSampleRate;
    
    return duration;
}

- (CGFloat)totalFileDuration{
    UInt64 nPackets;
    UInt32 propsize = sizeof(nPackets);
    
    AudioFileGetProperty(self.recorderState.mAudioFile, kAudioFilePropertyAudioDataPacketCount, &propsize, &nPackets);
    
    CGFloat duration = (nPackets * _recorderState.mDataFormat.mFramesPerPacket) / _recorderState.mDataFormat.mSampleRate;
    
    return duration;
}

@end
