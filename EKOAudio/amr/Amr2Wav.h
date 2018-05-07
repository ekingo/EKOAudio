//
//  Amr2Wav.h
//  PetFone_EnterPrise_iPhone
//
//  Created by  apple on 11-8-10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "interf_dec.h"
//#import "interf_enc.h"
//#import "dec_if.h"
#import "WavData.h"

@interface Amr2Wav : NSObject {
    NSString*       sourcePath;
    NSString*       destPath;

}

@property   (nonatomic, retain) NSString*       sourcePath;
@property   (nonatomic, retain) NSString*       destPath;
-(Amr2Wav*)initWithSourceAndDest:(NSString*)source dest:(NSString*)destination;

-(BOOL)startTransfer;

@end
