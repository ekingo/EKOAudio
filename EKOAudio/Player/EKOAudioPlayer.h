//
//  EKOAudioPlayer.h
//  EKOAudio
//
//  Created by hujin on 2018/7/25.
//  Copyright © 2018 XTC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EKOAudioPlayerFinishBlock)(BOOL flag);

@interface EKOAudioPlayer : NSObject

- (instancetype)initWithAudioFile:(NSString *)path;

@property (nonatomic, copy) EKOAudioPlayerFinishBlock finishBlock;

- (BOOL)play;
- (void)stop;

- (BOOL)isPlaying;

@end
