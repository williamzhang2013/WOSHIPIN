#ifndef _RTSP_LIVE_H
#define _RTSP_LIVE_H

//#include "NetCommon.h"
#include "BasicUsageEnvironment.hh"
#include "liveMedia.hh"
#include "QuickTimeFileSink2.h"
#include "SDL.h"

enum {
	PAYLOAD_H264,
	PAYLOAD_MAX,
};

enum {
	RTSP_EVT_RTPPAYLOADDUMP,
	RTSP_EVT_SOURCECLOSURE,
};

typedef struct {
	int media_type;
	unsigned char *buf;
	unsigned int len;
	struct timeval timestamp;
}RTP_PLAYLOAD_PACKET;

typedef void (*ON_RTSP_CALLBACK)(void *caller, int evt, void* param);

struct RTSP_Context_S{

	RTSPClient* rtspClient;
	MediaSession* mediaSession;

	void *caller;
	ON_RTSP_CALLBACK pcallback;

	char watchVariable;//param of doEventLoop() , set 0 to terminate the loop

	int record_flag;

	QuickTimeFileSink2 *qtOut;

	SDL_mutex *lock;	

	char *fmtp_spropparametersets;//xinghua 20101129
};

typedef struct RTSP_Context_S RTSP_Context;


#if defined __cplusplus
extern "C" {
#endif

RTSP_Context * RTSPClient_Init(void *caller, ON_RTSP_CALLBACK cb);
void RTSPClient_Deinit(RTSP_Context *ctx);
int RTSPClient_Open(RTSP_Context *ctx, const char *url);
void RTSPClient_RunningProc(RTSP_Context *ctx);
void RTSPClient_Terminate(RTSP_Context *ctx);

void RTSPClient_StartRecord(RTSP_Context *ctx, char *filename, int width, int height);
void RTSPClient_StopRecord(RTSP_Context *ctx);
#if defined __cplusplus
}
#endif

#endif