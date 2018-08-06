//
//  EKOAudioQueue.h
//  EKOAudio
//
//  Created by hujin on 2018/7/16.
//  Copyright © 2018 XTC. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>

static const int kAQNumberBuffers = 3;
static const int kAQBufferDurationSeconds = 0.5; //每次的音频输入队列缓存区所保存的是多少秒的数据

typedef struct EKOAQRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kAQNumberBuffers];
    AudioFileID                  mAudioFile;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;
} EKOAQRecorderState;

@class EKOAudioQueue;

typedef void(^EKOAQRecordingBlock)(EKOAudioQueue *audioQueue,NSData *buffer,CGFloat recordTime);
typedef void(^EKOAQFinishBlock)(EKOAudioQueue *audioQueue,NSString *destFilePath,CGFloat recordTime);
typedef void(^EKOAQCancelBlock)(EKOAudioQueue *audioQueue);
typedef void(^EKOAQPeakMeterBlock)(EKOAudioQueue *audioQueue,float peakPower,float averagePower,float currentTime);

@interface EKOAudioQueue : NSObject

@property (nonatomic, copy) NSString *saveFolderPrefix; //语音需要保存到路径

@property (nonatomic, copy) EKOAQRecordingBlock recordingBlock;
@property (nonatomic, copy) EKOAQFinishBlock finishBlock;
@property (nonatomic, copy) EKOAQCancelBlock cancelBlock;
@property (nonatomic, copy) EKOAQPeakMeterBlock peakMeterBlock;

- (instancetype)initWithRecordingBlock:(EKOAQRecordingBlock)recordingBlock
                           finishBlock:(EKOAQFinishBlock)finishBlock
                           cancelBlock:(EKOAQCancelBlock)cancelBlock;
                        //peakMeterBlock:(EKOAQPeakMeterBlock)

@property (nonatomic, assign) EKOAQRecorderState recorderState;

- (void)startRecord;

- (void)startRecordWithDuration:(NSTimeInterval)duration;

- (void)stopRecord;

- (void)cancelRecord;

- (BOOL)isRecording;

@end
