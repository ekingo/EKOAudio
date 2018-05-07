//
//  EKOAudioServiceImpl.m
//  EKOAudio
//
//  Created by hujin on 2018/4/27.
//  Copyright © 2018 XTC. All rights reserved.
//

#import "EKOAudioServiceImpl.h"

#import "Other2Amr.h"
#import "Amr2Wav.h"

#import "EKOOpusKit.h"

@interface EKOAudioServiceImpl()

@property (nonatomic, assign) EKOAudioFormat audioFormat;

@property (nonatomic, strong) id<EKOAudioProtocol> audioKit;

@end

@implementation EKOAudioServiceImpl

- (void)dealloc{
    if (_audioKit) {
        [_audioKit destroyKit];
    }
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.audioFormat = EKOAudioFormatAmr;
    }
    
    return self;
}

- (instancetype)initWithFormat:(EKOAudioFormat)format{
    self = [super init];
    if (self) {
        self.audioFormat = format;
    }
    
    return self;
}

- (void)setAudioFormat:(EKOAudioFormat)audioFormat{
    if (_audioFormat != audioFormat) {
        if (_audioKit) {
            [_audioKit destroyKit];
            
            _audioKit = nil;
        }
        
        _audioFormat = audioFormat;
    }
}

- (BOOL)transferWavAudio:(NSString *)source toFile:(NSString *)destFile {
    BOOL result = NO;
    do{
        if (self.audioFormat == EKOAudioFormatAmr) {
            //amr
            Other2Amr *otherAmr = [[Other2Amr alloc] initWithSourceAndDest:source dest:destFile];
            
            result = [otherAmr startTransfer];
            break;
        }
        
        NSData *destData = [self.audioKit encodePCM:[NSData dataWithContentsOfFile:source]];
        if (destData) {
            result = [destData writeToFile:destFile atomically:YES];
        }
        
    }while(0);
    
    return result;
}

- (BOOL)transferWavData:(NSData *)wavData toDest:(NSMutableData *)destData {
    BOOL result = NO;
    do{
        if (self.audioFormat == EKOAudioFormatAmr) {
            //amr
            result = [Other2Amr transferData:wavData destData:destData];
            
            break;
        }
        
        NSData *audioData = [self.audioKit encodePCM:wavData];
        if (audioData) {
            destData = [NSMutableData dataWithData:audioData];
            result = YES;
        }
    }while(0);
    return result;
}

- (BOOL)transferToWavAudio:(NSString *)destFile fromFile:(NSString *)source {
    BOOL result = NO;
    
    if (self.audioFormat == EKOAudioFormatAmr) {
        Amr2Wav *amrWav = [[Amr2Wav alloc] initWithSourceAndDest:source dest:destFile];
        
        result = [amrWav startTransfer];
    }else{
        NSData *destData = [self.audioKit decodeAudioData:[NSData dataWithContentsOfFile:source]];
        if (destData) {
            result = [destData writeToFile:destFile atomically:YES];
        }
    }
    
    return result;
}

#pragma mark - getters and setters
- (id<EKOAudioProtocol>)audioKit{
    if (!_audioKit) {
        if (self.audioFormat == EKOAudioFormatOpus) {
            _audioKit = [[EKOOpusKit alloc] init];
            
            [_audioKit initKit];
        }
    }
    
    return _audioKit;
}

@end
