//
//  EKOAudioService.h
//  EKOAudio
//
//  Created by hujin on 2018/4/27.
//  Copyright © 2018 XTC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,EKOAudioFormat) {
    EKOAudioFormatNone,
    EKOAudioFormatAmr,
    EKOAudioFormatOpus,
};

@protocol EKOAudioService <NSObject>

/**
 初始化

 @param format 语音格式
 @return id
 */
- (instancetype)initWithFormat:(EKOAudioFormat)format;


/**
 更改语音格式【统一管理】

 @param format EKOAudioFormat
 */
- (void)setAudioFormat:(EKOAudioFormat)format;

/**
 转换wav语音数据流到相应格式的文件

 @param source wav文件
 @param destFile 目标文件
 @return YES/NO
 */
- (BOOL)transferWavAudio:(NSString *)source toFile:(NSString *)destFile;

/**
 转换wav二进制数据流

 @param wavData wav数据
 @param destData 目标二进制数据
 @return YES/NO
 */
- (BOOL)transferWavData:(NSData *)wavData toDest:(NSMutableData *)destData;

/**
 从其他数据格式转换成wav

 @param destFile 转成wav的路径
 @param source 原始语音文件
 @return YES/NO
 */
- (BOOL)transferToWavAudio:(NSString *)destFile fromFile:(NSString *)source;

@end
