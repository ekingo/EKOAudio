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

@interface Other2Amr : NSObject {
    NSString*       sourcePath;
    NSString*       destPath;
}

@property   (nonatomic, retain) NSString*       sourcePath;
@property   (nonatomic, retain) NSString*       destPath;
-(Other2Amr*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination;

-(BOOL)startTransfer;

+(BOOL)transferData:(NSData *)src destData:(NSMutableData *)dest;

@end
