//
//  EKOAudioRecorder.h
//  EKOAudio
//
//  Created by hujin on 2018/5/23.
//  Copyright © 2018 XTC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//录音最大时间
#define kAudioRecordTimeMax     14.0

@class EKOAudioRecorder;

typedef void(^EKOFinishRecordingBlock)(EKOAudioRecorder *recorder,BOOL success,float recordTime);
typedef void(^EKOCancelRecordingBlock)(void);
typedef void(^EKOReceiveRecordingBlock)(EKOAudioRecorder *recorder,float recordTime);
typedef void(^EKOReceiveRecordingPeakBlock)(EKOAudioRecorder *recorder,float peakPower,float averagePower,float currentTime);

@interface EKOAudioRecorder : NSObject

@property (nonatomic, copy) NSString *saveFolderPrefix; //语音需要保存到路径

@property (nonatomic, copy) EKOFinishRecordingBlock finishRecordingBlock;
@property (nonatomic, copy) EKOCancelRecordingBlock    cancelRecordingBlock;
@property (nonatomic, copy) EKOReceiveRecordingBlock receiveRecordingBlock;
@property (nonatomic, copy) EKOReceiveRecordingPeakBlock receiveRecordingPeakBlock;

- (id)initWithFinishRecordingBlock:(EKOFinishRecordingBlock)finishRecordingBlock
         encodeErrorRecordingBlock:(void (^)(EKOAudioRecorder *recorder,NSError *error))encodeErrorRecordingBlock
            receivedRecordingBlock:(EKOReceiveRecordingPeakBlock)receivedRecordingBlock;

- (BOOL)startRecord;
- (BOOL)startRecordForDuration: (NSTimeInterval) duration;
- (void)cancelled;

- (void)stopRecord;
- (void)stopAndDeleteRecord;
- (void)stopAndDeleteAllRecords;

- (void)cleanAllBlocks;

- (NSString*)getFullPath;

- (BOOL)isRecording;

- (CGFloat)getRecordTime;

@end
