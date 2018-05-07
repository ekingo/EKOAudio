//
//  EKOOpusKit.m
//  EKOAudio
//
//  Created by hujin on 2018/4/28.
//  Copyright © 2018 XTC. All rights reserved.
//

#import "EKOOpusKit.h"

#import <opus/opus.h>

#define WB_FRAME_SIZE 160

#define kDefaultSampleRate 8000

@interface EKOOpusKit(){
    OpusEncoder *enc;
    OpusDecoder *dec;
    int opus_num;
    int pcm_num;
    unsigned char opus_data_encoder[40];
}

@end

@implementation EKOOpusKit

- (NSData *)decodeAudioData:(NSData *)data {
    NSInteger len = [data length];
    NSLog(@"数据长度===%ld",(long)len);
    
    Byte *byteData = (Byte*)malloc(len);
    
    memcpy(byteData, [data bytes], len);
    
    short decodedBuffer[1024];
    
    int nDecodedByte = sizeof(short) * [self decode:byteData length:len output:decodedBuffer];
    NSLog(@"返回的长度＝＝%d",nDecodedByte);
    NSData* PCMData = [NSData dataWithBytes:(Byte *)decodedBuffer length:nDecodedByte];
    return PCMData;
}

- (void)destroyKit {
    opus_encoder_destroy(enc);
    
    opus_decoder_destroy(dec);
}

- (NSData *)encodePCM:(NSData *)pcmData {
    return  [self encode:(short *)[pcmData bytes] length:[pcmData length]];
}

- (void)initKit {
    int error;
    int Fs = 16000;//采样率
    int channels = 1;
    int application = OPUS_APPLICATION_VOIP;
    
    opus_int32 bitrate_bps = kDefaultSampleRate;
    int bandwidth = OPUS_AUTO;//OPUS_BANDWIDTH_NARROWBAND 宽带窄带
    int use_vbr = 0;
    int cvbr = 1;
    int complexity = 4; //录制质量 1-10
    int packet_loss_perc = 0;
    
    enc = opus_encoder_create(Fs, channels, application, &error);
    dec = opus_decoder_create(Fs, channels, &error);
    
    opus_encoder_ctl(enc, OPUS_SET_BITRATE(bitrate_bps));
    opus_encoder_ctl(enc, OPUS_SET_BANDWIDTH(bandwidth));
    opus_encoder_ctl(enc, OPUS_SET_VBR(use_vbr));
    opus_encoder_ctl(enc, OPUS_SET_VBR_CONSTRAINT(cvbr));
    opus_encoder_ctl(enc, OPUS_SET_COMPLEXITY(complexity));
    opus_encoder_ctl(enc, OPUS_SET_PACKET_LOSS_PERC(packet_loss_perc));
    opus_encoder_ctl(enc, OPUS_SET_SIGNAL(OPUS_SIGNAL_VOICE));//信号
}

#pragma mark -private methods

- (NSData *)encode:(short *)pcmBuffer length:(int)lengthOfShorts
{
    NSMutableData *decodedData = [NSMutableData data];
    int frame_size = WB_FRAME_SIZE;
    short input_frame[frame_size];
    opus_int32 max_data_bytes = 2500;
    
    memcpy(input_frame, pcmBuffer, frame_size * sizeof(short));
    int encodeBack = opus_encode(enc, input_frame, frame_size, opus_data_encoder, max_data_bytes);
    NSLog(@"encodeBack===%d",encodeBack);
    if (encodeBack > 0)
    {
        [decodedData appendBytes:opus_data_encoder length:encodeBack];
    }
    
    return decodedData;
}

//int decode(unsigned char* in_data, int len, short* out_data, int* out_len) {
-(int)decode:(unsigned char *)encodedBytes length:(int)lengthOfBytes output:(short*)decoded {
    int frame_size = WB_FRAME_SIZE;
    char cbits[frame_size + 1];
    memcpy(cbits, encodedBytes, lengthOfBytes);
    pcm_num = opus_decode(dec,
                          cbits,
                          lengthOfBytes,
                          decoded,
                          frame_size,
                          0);
    
    return frame_size;
    
}

@end
