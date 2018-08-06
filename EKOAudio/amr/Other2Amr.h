//
//  Other2Amr.h
//  PetFone_EnterPrise_iPhone
//
//  Created by  apple on 11-10-13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "audiocodec.h"
//#import "amrnbcodec.h"

//#import "interf_enc.h"
#import "dec_if.h"

#ifdef __cplusplus
extern "C" {
#endif

int WAVFileDataIndex(NSData *srcData);

#ifdef __cplusplus
} // extern "C"
#endif


@interface Other2Amr : NSObject {
    NSString*       sourcePath;
    NSString*       destPath;
}

@property   (nonatomic, retain) NSString*       sourcePath;
@property   (nonatomic, retain) NSString*       destPath;
-(Other2Amr*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination;

-(BOOL)startTransfer;

+(BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest;

/**
 使用相同的上下文转换二进制pcm数据

 @param src pcm数据
 @param dest amr转换后的数据
 @return 是否成功
 */
-(BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest;

+ (int)frameSize;

@end
