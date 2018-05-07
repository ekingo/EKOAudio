//
//  EKOAudioProtocol.h
//  EKOAudio
//
//  Created by hujin on 2018/4/28.
//  Copyright © 2018 XTC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EKOAudioProtocol <NSObject>

@required

- (void)initKit;

- (NSData *)encodePCM:(NSData *)pcmData;

- (NSData *)decodeAudioData:(NSData *)data;

- (void)destroyKit;

@end
