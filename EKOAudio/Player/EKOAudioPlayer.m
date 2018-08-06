//
//  EKOAudioPlayer.m
//  EKOAudio
//
//  Created by hujin on 2018/7/25.
//  Copyright © 2018 XTC. All rights reserved.
//

#import "EKOAudioPlayer.h"

#import <AVFoundation/AVFoundation.h>
#import <EKORouter/EKORouter.h>
#import <EKOUtil/EKODevice.h>

#import "EKOAudioService.h"

@interface EKOAudioPlayer()<AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, copy) NSString *audioPath;

@property (nonatomic, copy) NSString *audioWavPath; //转换后播放的路径

@property (nonatomic, strong) id<EKOAudioService> audioService;

@end

@implementation EKOAudioPlayer

- (instancetype)initWithAudioFile:(NSString *)path{
    if (self = [super init]) {
        self.audioPath = path;
    }
    
    return self;
}

- (BOOL)play{
    BOOL result = NO;
    do{
        if (!self.audioPath) {
            break;
        }
        if (!self.audioWavPath) {
            EKOAudioFormat fmt = [self audioFormat];
            if (fmt == EKOAudioFormatWav) {
                self.audioWavPath = self.audioPath;
            }else{
                NSString *temp = [NSHomeDirectory() stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"Documents/%@.wav",[EKODevice createUUID]]];
                if ([self.audioService transferToWavAudio:temp fromFile:self.audioPath]) {
                    self.audioWavPath = temp;
                }
            }
        }
        
        if (!self.audioWavPath) {
            break;
        }
        
        NSError *err;
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:self.audioWavPath] error:&err];
        _audioPlayer.delegate = self;
        
        _audioPlayer.volume = 1.0f;
        
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
        result = YES;
    }while(0);
    
    return result;
}

- (void)stop{
    if (_audioPlayer) {
        [self.audioPlayer stop];
        
        _audioPlayer = nil;
    }
}

- (BOOL)isPlaying{
    if (_audioPlayer) {
        return [self.audioPlayer isPlaying];
    }else{
        return NO;
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    if (self.finishBlock) {
        self.finishBlock(NO);
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if (self.finishBlock) {
        self.finishBlock(flag);
    }
}

#pragma mark - private methods
- (EKOAudioFormat)audioFormat{
    EKOAudioFormat fmt = EKOAudioFormatNone;
    if (self.audioPath) {
        //TODO
        NSString *ext = [[self.audioPath pathExtension] lowercaseString];
        if ([ext isEqualToString:@"amr"]) {
            fmt = EKOAudioFormatAmr;
        }else if([ext isEqualToString:@"opus"]){
            fmt = EKOAudioFormatOpus;
        }else if([ext isEqualToString:@"wav"]){
            fmt = EKOAudioFormatWav;
        }
    }
    
    return fmt;
}

- (id<EKOAudioService>)audioService{
    if (!_audioService) {
        _audioService = [[EKORouter sharedRouter] createService:@protocol(EKOAudioService)];
    }
    
    return _audioService;
}

@end
