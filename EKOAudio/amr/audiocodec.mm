#include "audiocodec.h"
#define __AMRNB_ENABLED__ 1

#ifdef __AMRNB_ENABLED__
#include "amrnbcodec.h"
#endif

#include "string.h"


AMRNBEnc *createAudioEnc(const char *codec_name)
{
	AMRNBEnc *codec = 0;


#ifdef __AMRNB_ENABLED__
	if(strcmp(codec_name,"amrnb")==0){
		codec = (AMRNBEnc *)new AMRNBEnc();
		goto end;
	}
#endif


end:
	return codec;	
}

void destroyAudioEnc(AMRNBEnc *codec)
{
	delete codec;
}

AMRNBDec *createAudioDec(const char *codec_name)
{
	AMRNBDec *codec = 0;





#ifdef __AMRNB_ENABLED__	
	if(strcmp(codec_name,"amrnb")==0){
		codec = (AMRNBDec *)new AMRNBDec();
		goto end;
	}
#endif


end:
	return codec;	
}

void destroyAudioDec(AMRNBDec *codec)
{
	delete codec;
}


