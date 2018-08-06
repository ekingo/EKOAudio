//
//  EKOAudioRecorder.m
//  EKOAudio
//
//  Created by hujin on 2018/5/23.
//  Copyright © 2018 XTC. All rights reserved.
//

#import "EKOAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <EKOUtil/EKOWeakProxy.h>
#import <EKOLogger/EKOLogger.h>

#define kRecorderDirectory [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]stringByAppendingPathComponent:@"swtmp"]

#define WAVE_UPDATE_FREQUENCY   0.05

@interface EKOAudioRecorder()<AVAudioRecorderDelegate>

@property (nonatomic, assign) CGFloat recordTime;
@property (nonatomic, assign) BOOL cancelRecording;

@property (nonatomic, strong) void (^encodeErrorRecordingBlock)(EKOAudioRecorder *recorder,NSError *error);

@property (nonatomic, strong,readonly) AVAudioRecorder* audioRecorder;
@property (nonatomic, strong,readonly) NSString *recorderingPath;
@property (nonatomic, assign,readonly) BOOL deletedRecording;

@property (nonatomic, strong) NSTimer *updateTimer;

- (NSDictionary *)recordingSettings;
+ (NSString *)stringWithUUID;
//- (void)startReceivedRecordingCallBackTimer;

@end


@implementation EKOAudioRecorder

- (id)initWithFinishRecordingBlock:(EKOFinishRecordingBlock)finishRecordingBlock
         encodeErrorRecordingBlock:(void (^)(EKOAudioRecorder *recorder,NSError *error))encodeErrorRecordingBlock
            receivedRecordingBlock:(void (^)(EKOAudioRecorder *recorder,float peakPower,float averagePower,float currentTime))receivedRecordingBlock {
    
    self = [super init];
    if (self) {
        [self initTimer];
        _finishRecordingBlock= finishRecordingBlock;
        _encodeErrorRecordingBlock= encodeErrorRecordingBlock;
        self.receiveRecordingPeakBlock= receivedRecordingBlock;
    }
    return self;
}

- (void)dealloc{
    [self stopTimer];
    [self cleanAllBlocks];
}


- (void)cleanAllBlocks{
    
    _finishRecordingBlock= nil;
    _encodeErrorRecordingBlock= nil;
    _cancelRecordingBlock = nil;
    _receiveRecordingPeakBlock= nil;
    _receiveRecordingBlock = nil;
    _audioRecorder.delegate = nil;
    _audioRecorder = nil;
    
    NSLog(@"dealloc audio recording");
}


- (void)initTimer{
    dispatch_block_t block = ^{
        self.updateTimer = [NSTimer timerWithTimeInterval:WAVE_UPDATE_FREQUENCY target:[[EKOWeakProxy alloc] initWithTarget:self] selector:@selector(updateMeters) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.updateTimer forMode:NSRunLoopCommonModes];
        [self.updateTimer setFireDate:[NSDate distantFuture]];
    };
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)startTimer{
    _recordTime = 0;
    dispatch_block_t block = ^{
        [self.updateTimer setFireDate:[NSDate distantPast]];
    };
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
    
}

- (void)pauseTimer{
    if (self.updateTimer == nil) return;
    dispatch_block_t block = ^{
        [self.updateTimer setFireDate:[NSDate distantFuture]];
    };
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
}

- (void)stopTimer{
    if (self.updateTimer == nil) return;
    _recordTime = 0.0f;
    dispatch_block_t block = ^{
        [self.updateTimer setFireDate:[NSDate distantFuture]];
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    };
    if ([NSThread isMainThread]) {
        block();
    }else{
        dispatch_async(dispatch_get_main_queue(), block);
    }
    
}



- (BOOL)startRecord{
    return [self startRecordForDuration:0];
}
- (BOOL)startRecordForDuration: (NSTimeInterval) duration
{
    BOOL bRes = NO;
    NSError * err = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory :AVAudioSessionCategoryRecord/*AVAudioSessionCategoryPlayAndRecord*/ error:&err];
    
    NSLog(@"Catagory:%@",audioSession.category);
    
    if(err){
        EKOLogDebug(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return bRes;
    }
    
    [audioSession setActive:YES error:&err];
    
    if(err){
        EKOLogDebug(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return bRes;
    }
    
    NSString *saveFolder = kRecorderDirectory;
    
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
                          [NSString stringWithFormat:@"%@.wav",[[self class] stringWithUUID]]]; //aac
    //NSLog(@"fullpath:%@",fullPath);
    
    //更改音量
    UInt32 audioRoute = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRoute), &audioRoute);
    
    NSURL * url = [NSURL fileURLWithPath:fullPath];
    
    err = nil;
    
    NSData * audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    
    if(audioData){
        //NSFileManager *fm = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:[url path] error:&err];
    }
    
    err = nil;
    
    //    if(self.audioRecorder){
    //        [self.audioRecorder stop];
    //        _audioRecorder = nil;
    //    }
    
    NSDictionary *recordingSettings = [self recordingSettings];
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url
                                                 settings:recordingSettings
                                                    error:&err];
    
    if(!_audioRecorder){
        EKOLogFatal(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return bRes;
    }
    
    [_audioRecorder setDelegate:self];
    [_audioRecorder prepareToRecord];
    _audioRecorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSession.inputAvailable;
    if (! audioHWAvailable) {
        EKOLogFatal(@"Audio Recorder warning:Audio input hardware not available");
        return bRes;
    }
    
    _recorderingPath = fullPath;
    _deletedRecording = NO;
    //[self startReceivedRecordingCallBackTimer];
    
    //限制录音最大可录长度
    [_audioRecorder recordForDuration:(NSTimeInterval) (kAudioRecordTimeMax + 2)];
    self.cancelRecording = NO;
    [self startTimer];
    return YES;
}

#pragma mark - Timer Update

- (void)updateMeters {
    
    _recordTime += WAVE_UPDATE_FREQUENCY;
    
    /*  发送updateMeters消息来刷新平均和峰值功率。
     *  此计数是以对数刻度计量的，-160表示完全安静，
     *  0表示最大输入值
     */
    
    if (_audioRecorder) {
        [_audioRecorder updateMeters];
    }
    
    if (self.receiveRecordingPeakBlock) {
        double ALPHA = 0.03;
        float peakPower = [_audioRecorder peakPowerForChannel:0];
        double peakPowerForChannel = pow(10, (ALPHA * peakPower));
        NSLog(@"peak:%f",peakPowerForChannel);
        float averagePower = pow(10, (ALPHA * peakPower));
        float currentTime = _audioRecorder.currentTime;
        self.receiveRecordingPeakBlock(self,peakPowerForChannel,averagePower,currentTime);
    }
    
    if (self.receiveRecordingBlock) {
        self.receiveRecordingBlock(self,self.recordTime);
    }
}

#pragma mark - Helper Function

- (void)stopRecord{
    [self pauseTimer];
    if (_audioRecorder.recording) {
        [_audioRecorder stop];
    }
}

- (void)stopAndDeleteRecord{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cancelled];
    });
}

- (void)stopAndDeleteAllRecords{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pauseTimer];
        if (_audioRecorder.recording) {
            [_audioRecorder stop];
        }
        if (!_deletedRecording) {
            _deletedRecording = [_audioRecorder deleteRecording];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:kRecorderDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:kRecorderDirectory
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }
    });
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"Audio finished");
    [self pauseTimer];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (_finishRecordingBlock) {
        _finishRecordingBlock(self,(self.cancelRecording==YES?NO:flag),_recordTime);
    }
}
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    [self pauseTimer];
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (_encodeErrorRecordingBlock) {
        _encodeErrorRecordingBlock(self,error);
    }
    if (_cancelRecordingBlock) {
        _cancelRecordingBlock();
    }
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    NSLog(@"录音被打断");
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    [self pauseTimer];
    if (_finishRecordingBlock) {
        _finishRecordingBlock(self,(self.cancelRecording==YES?NO:YES),_recordTime);
    }
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    NSLog(@"录音被打断结束了");
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    if (flags == AVAudioSessionInterruptionOptionShouldResume){
        NSLog(@"Resuming the recording...");
        [recorder record];
    }
}

- (void)audioRecorderReceivedRecordingCallBack:(NSTimer*)timer{
    if (self.receiveRecordingPeakBlock) {
        if (_audioRecorder.recording) {
            [_audioRecorder updateMeters];
            double ALPHA = 0.01;
            float peakPower = pow(10, (ALPHA * [_audioRecorder peakPowerForChannel:0]));
            float averagePower = pow(10, (ALPHA * [_audioRecorder averagePowerForChannel:0]));
            float currentTime = _audioRecorder.currentTime;
            self.receiveRecordingPeakBlock(self,peakPower,averagePower,currentTime);
        }
    }
}

#pragma mark - Private methods

-(NSDictionary *)recordingSettings{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
            [NSNumber numberWithInt:8000],AVSampleRateKey, //采样率 8000 or 16000
            [NSNumber numberWithInt:1], AVNumberOfChannelsKey,//通道的数目 1 or 2
            [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey, //采样位数 默认 16
            [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey, //大端还是小端 是内存的组织方式
            [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,nil]; //采样信号是整数还是浮点数
    
#if  TARGET_IPHONE_SIMULATOR
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
            [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
            [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
            [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
            [NSNumber numberWithInt:AVAudioQualityMax],AVEncoderAudioQualityKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey, nil];
    
#else
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
            [NSNumber numberWithFloat:8000.0], AVSampleRateKey,
            [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
            [NSNumber numberWithInt:8], AVLinearPCMBitDepthKey,
            [NSNumber numberWithInt:96], AVEncoderBitRateKey,
            [NSNumber numberWithInt:AVAudioQualityLow],AVEncoderAudioQualityKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey, nil];
    //24000.0  1 8 96
#endif
}

+(NSString*) stringWithUUID
{
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    NSString* uuidString = [NSString stringWithString:(__bridge NSString*)strRef];
    CFRelease(strRef);
    CFRelease(uuidObj);
    return uuidString;
}

- (void)cancelled {
    self.cancelRecording = YES;
    
    [self pauseTimer];
    if (self.audioRecorder.isRecording) {
        [self.audioRecorder stop];
        [self.audioRecorder deleteRecording];
    }
    
    if (self.cancelRecordingBlock) {
        self.cancelRecordingBlock();
    }
}

-(NSString*)getFullPath{
    return self.recorderingPath;
}

- (BOOL)isRecording{
    if (self.audioRecorder) {
        return self.audioRecorder.isRecording;
    }
    return NO;
}

- (CGFloat)getRecordTime{
    return _recordTime;
}

- (CGFloat)recordTime{
    return _recordTime;
}

@end
