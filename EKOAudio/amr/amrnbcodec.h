#ifndef AMRNBCODEC_H
#define AMRNBCODEC_H

//#include "codecFiter.h"


class AMRNBEnc {
public:
	AMRNBEnc();
	~AMRNBEnc();
	
	int Enc(unsigned char*pOut,unsigned char*pIn,int len);
	int Dec(unsigned char*pOut,unsigned char*pIn,int len);
	void Destroy();
protected:
	int enc_fream_size;
	int dec_fream_size;
private:

	void *amr;

	//AVCodecStat a_stat;
};

class AMRNBDec {
public:
	AMRNBDec();
	~AMRNBDec();
	
	int Enc(unsigned char*pOut,unsigned char*pIn,int len);
	int Dec(unsigned char*pOut,unsigned char*pIn,int len);
	void Destroy();
protected:
	int enc_fream_size;
	int dec_fream_size;
private:

	void *amr;
	//AVCodecStat a_stat;
};


#endif


