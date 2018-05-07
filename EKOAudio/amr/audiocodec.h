#ifndef AUDIO_CODEC_H
#define AUDIO_CODEC_H

//#include "codecFiter.h"
#include "amrnbcodec.h"



AMRNBEnc *createAudioEnc(const char *codec);
void destroyAudioEnc(AMRNBEnc *codec);

AMRNBDec *createAudioDec(const char *codec);
void destroyAudioDec(AMRNBDec *codec);


#endif

