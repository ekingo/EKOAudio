
#include "amrnbcodec.h"
#include <assert.h>
//#include <android/log.h>

//#include <sp_dec.h>
//#include <gsmamr_dec.h>
//#include <gsmamr_enc.h>
//#include <amrdecode.h>
//#include <amrencode.h>
#include "interf_dec.h"
#include "interf_enc.h"
#import     "dec_if.h"
#include <stdlib.h>

/*void* Decoder_Interface_init(void) {
	void* ptr = NULL;
	GSMInitDecode(&ptr, (int8*)"Decoder");
	return ptr;
}

void Decoder_Interface_exit(void* state) {
	GSMDecodeFrameExit(&state);
}

Word16 Decoder_Interface_Decode(void* state, const unsigned char* in, short* out, int bfi) {
	unsigned char type = (in[0] >> 3) & 0x0f;
	in++;
	return AMRDecode(state, (enum Frame_Type_3GPP) type, (UWord8*) in, out, MIME_IETF);
}


struct encoder_state {
	void* encCtx;
	void* pidSyncCtx;
};

void* Encoder_Interface_init(int dtx) {
	struct encoder_state* state = (struct encoder_state*) malloc(sizeof(struct encoder_state));
	AMREncodeInit(&state->encCtx, &state->pidSyncCtx, dtx);
	return state;
}

void Encoder_Interface_exit(void* s) {
	struct encoder_state* state = (struct encoder_state*) s;
	AMREncodeExit(&state->encCtx, &state->pidSyncCtx);
	free(state);
}

int Encoder_Interface_Encode(void* s, enum Mode mode, const short* speech, unsigned char* out, int forceSpeech) {
	struct encoder_state* state = (struct encoder_state*) s;
	enum Frame_Type_3GPP frame_type = (enum Frame_Type_3GPP) mode;
	int ret = AMREncode(state->encCtx, state->pidSyncCtx, mode, (Word16*) speech, out, &frame_type, AMR_TX_IETF);
	out[0] |= 0x04;
	return ret;
}*/


/* From WmfDecBytesPerFrame in dec_input_format_tab.cpp */
//const int sizes[] = { 12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0 };


AMRNBEnc::AMRNBEnc()
{
	enc_fream_size = 160*sizeof(short);
//	dec_fream_size = 12*sizeof(short);
	dec_fream_size = 13;
	amr = Encoder_Interface_init(0);
//	udp_log_print("%s\n",__FUNCTION__);
}



AMRNBEnc::~AMRNBEnc()
{
	Destroy();
}

void AMRNBEnc::Destroy()
{
	Encoder_Interface_exit(amr);
}

int AMRNBEnc::Enc(unsigned char*pOut,unsigned char*pIn,int len)
{
	//gsm_encode(enc_state->state,(gsm_signal*)in_tmp,(gsm_byte*)out_tmp);
//	static unsigned int fn = 0;
	int n=0;
	for(int offset=0;offset<len;offset+=enc_fream_size){
		int ne = Encoder_Interface_Encode(amr, MR475, (short *)pIn, pOut, 0);
		
		assert(ne==dec_fream_size);
		//gsm_encode(codec,(gsm_signal*)pIn,(gsm_byte*)pOut);
	//	fn++;
	//	if(fn%10==0) //√ø10÷°»•µÙ“‘◊÷Ω⁄
	//		ne--;
		
		pIn+=enc_fream_size;
		pOut+=ne;
		n+=ne;


		//a_stat.stat_feed(ne);
	}
	
	
	return n;
}

int AMRNBEnc::Dec(unsigned char*pOut,unsigned char*pIn,int len)
{
	assert(0);
	return -1;	
}


AMRNBDec::AMRNBDec()
{
	enc_fream_size = 160*sizeof(short);
	dec_fream_size = 13;
//	dec_fream_size = 12*sizeof(short);
	amr = Decoder_Interface_init();
//	udp_log_print("%s\n",__FUNCTION__);
}



AMRNBDec::~AMRNBDec()
{
	Destroy();
}

void AMRNBDec::Destroy()
{
	Decoder_Interface_exit(amr);
}

int AMRNBDec::Enc(unsigned char*pOut,unsigned char*pIn,int len)
{
	assert(0);
	return -1;	
}

int AMRNBDec::Dec(unsigned char*pOut,unsigned char*pIn,int len)
{
	int n=0;
	unsigned char *pend = pIn+len;
	
	while(pIn<pend){
//		int nd;
        Decoder_Interface_Decode(amr, pIn, (short *)pOut, 0);
		//udp_log_print("%s %d--->%d  dec_fream_size:%d\n",__FUNCTION__,dec_fream_size,nd,enc_fream_size);
		pIn+=dec_fream_size;
	//	pIn+=nd;
		pOut+=enc_fream_size;
		n+=enc_fream_size;		

		//a_stat.stat_feed(nd);
	}

	
	/*
	for(int offset=0;offset<len;offset+=dec_fream_size){
		//if (gsm_decode(dec_state,(gsm_byte*)in_tmp,(gsm_signal*)out_tmp)<0){

		int nd = Decoder_Interface_Decode(amr, pIn, (short *)pOut, 0);
		udp_log_print("%s %d--->%d  dec_fream_size:%d\n",__FUNCTION__,dec_fream_size,nd,enc_fream_size);
	//	pIn+=dec_fream_size;
		pIn+=nd;
		pOut+=enc_fream_size;
		n+=enc_fream_size;
	}
	*/
	return n;	
}

