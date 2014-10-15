extern "C"
{
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
}
#include "SDL.h"
#include <math.h>
#include "rtsp_live.h"
#include "pe_ctrl.h"
#include "msgq.h"
#include "pngfile.h"

#ifdef WIN32
#include "windows.h"
#define USE_SDL_VIDEORENDER
#endif

#define FF_ALLOC_EVENT		(SDL_USEREVENT)
#define FF_REFRESH_EVENT	(SDL_USEREVENT + 1)
#define FF_QUIT_EVENT		(SDL_USEREVENT + 2)
#define FF_SETVIDEOMODE		(SDL_USEREVENT + 3)
#define FF_BUFFERSTART		(SDL_USEREVENT + 4)
#define FF_BUFFEROVER		(SDL_USEREVENT + 5)

#define VIDEO_PICTURE_QUEUE_SIZE 1
#define VIDEO_DROP_THRESHOLD	100
#define VIDEO_BUFFEROVER_NB		8
#define TIMER1_PERIOD	100
#define TIMER_REFRESH_PERIOD	10

/////////////////////////////////////////////////////////
typedef struct {
	int type;
	void *data1;
}Msg_t;

typedef struct PacketQueue {
  AVPacketList *first_pkt, *last_pkt;
  int nb_packets;
  int size;
  SDL_mutex *mutex;
  SDL_cond *cond;
} PacketQueue;

typedef struct VideoPicture {
#ifdef USE_SDL_VIDEORENDER
  SDL_Overlay *bmp;
#else
	AVPicture pic;
	int bmp;
#endif
  int width, height; /* source height & width */
  int allocated;
  double pts;
} VideoPicture;


typedef struct VideoState {
  PE_CTRL_T		*pectrl;
  double          frame_timer;
  double          frame_last_pts;
  double          frame_last_delay;
  double          video_clock; ///<pts of last decoded frame / predicted pts of next decoded frame
//  double          video_current_pts; ///<current displayed pts (different from video_clock if frame fifos are used)
//  int64_t         video_current_pts_time;  ///<time (av_gettime) at which we updated video_current_pts - used to have running video pts
  AVCodecContext	*video_codec;
  PacketQueue     videoq;

  VideoPicture    pictq[VIDEO_PICTURE_QUEUE_SIZE];
  int             pictq_size, pictq_rindex, pictq_windex;
  SDL_mutex       *pictq_mutex;
  SDL_cond        *pictq_cond;
  SDL_Thread      *video_tid;
  int             quit;
  int			buffering;
  int			bufferingover;

#ifdef USE_SDL_VIDEORENDER
  SDL_Surface     *screen;
#endif
  uint64_t global_video_pkt_pts;
  //int paused;
  //int schedule_refresh_tid;
  int schedule_delay;
  SDL_TimerID    timer1;
  SDL_TimerID	timer_refresh;//10ms timer

} VideoState;

struct PE_CTRL_S
{
	PE_EVT_CALLBACK evt_callback ;
	void *caller;

#ifdef WIN32
	void *hwnd;	//video window handle
#endif

	char url[256];
	RTSP_Context *rtsp_context;
	SDL_Thread   *rtsp_threadid;
    
	int mainloop_running;
	SDL_Thread	*mainloop_tid;

	VideoState *is;
	MSGQ_T *pMSGQ;

	int snapshot_request;
	char snapshot_filename[256];

	uint8_t *extradata ;
};


//////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////
int PE_PushPacket(PE_CTRL_T *ctrl, RTP_PLAYLOAD_PACKET *pkt);
void on_rtsp_callback(void *caller, int evt, void* param)
{
	PE_CTRL_T *ctrl = (PE_CTRL_T*)caller;

	if (evt == RTSP_EVT_RTPPAYLOADDUMP)
	{
		RTP_PLAYLOAD_PACKET *pkt = (RTP_PLAYLOAD_PACKET*)param;
		printf("-");
		
		/*wchar_t www[64] = {0};
		swprintf(www, 64, TEXT("--%d, %d, %d --\n"), pkt->len, pkt->timestamp.tv_sec , pkt->timestamp.tv_usec );
		OutputDebugString(www);*/
		//printf("(%d,%ld,%ld)",pkt->len, pkt->timestamp.tv_sec , pkt->timestamp.tv_usec);
		/*
		FILE *fp;
		//static int cnt ;
		//char fn[16] = {0};
		//sprintf(fn, "dump.h264",cnt++);
		fp = fopen("d:\\rtpdump.h264", "ab");
		fwrite(pkt->buf, 1, pkt->len, fp);
		fclose(fp);
		*/
		PE_PushPacket(ctrl, pkt);

	}
	else if (evt == RTSP_EVT_SOURCECLOSURE)
	{
		if (ctrl->evt_callback)
			ctrl->evt_callback(ctrl->caller,PE_EVENT_RTSPCONN_LOST, 0);
		
	}
}

static int SDLCALL rtsp_threadfunc(void *data)
{
	PE_CTRL_T *ctrl = (PE_CTRL_T *)data;
	RTSPClient_RunningProc(ctrl->rtsp_context);//blocking
	return 0;
}

//////////////////////////////////////////////////////////////////
//	global var
//////////////////////////////////////////////////////////////////
static VideoState *g_video_state ;
const AVRational RTP_TIMEBASE = {1,1000000};
static AVPacket flush_pkt;

#ifdef WIN32
 #include <excpt.h>
int filter(unsigned int code, struct _EXCEPTION_POINTERS *ep) 
{
   if (code == EXCEPTION_ACCESS_VIOLATION) {

      return EXCEPTION_EXECUTE_HANDLER;
   }

   else {

      return EXCEPTION_CONTINUE_SEARCH;
   };
} 
#endif

///////////////////////////////////////////////////////////
//          Packet Queue Operations
void packet_queue_init(PacketQueue *q) 
{
  memset(q, 0, sizeof(PacketQueue));
  q->mutex = SDL_CreateMutex();
  q->cond = SDL_CreateCond();
}

int packet_queue_put(PacketQueue *q, AVPacket *pkt) 
{
  AVPacketList *pkt1;
  if(pkt != &flush_pkt && av_dup_packet(pkt) < 0) {
    return -1;
  }
  pkt1 = (AVPacketList *)av_malloc(sizeof(AVPacketList));
  if (!pkt1)
    return -1;
  pkt1->pkt = *pkt;
  pkt1->next = NULL;
  
  SDL_LockMutex(q->mutex);

  if (!q->last_pkt)
    q->first_pkt = pkt1;
  else
    q->last_pkt->next = pkt1;
  q->last_pkt = pkt1;
  q->nb_packets++;
  q->size += pkt1->pkt.size;
  SDL_CondSignal(q->cond);
  SDL_UnlockMutex(q->mutex);
  return 0;
}

/*
return values:
-1 : request to quit
-2 : undering buffering 
1 : one packet got
0 : no packet got (empty queue) in non-blocking style
*/

static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block) {
  AVPacketList *pkt1;
  int ret;

  SDL_LockMutex(q->mutex);
  
  for(;;) {
    
    if(g_video_state->quit) {
      ret = -1;
      break;
    }

    pkt1 = q->first_pkt;
    if (pkt1) 
	{
		//!!!just return when it's not a flush packet and system is request buffering!!!
		//if ((pkt1->pkt.data != flush_pkt.data) && g_video_state->buffering)
		//{
		//	ret = -2;
		//	break;
		//}


		q->first_pkt = pkt1->next;
		if (!q->first_pkt)
		q->last_pkt = NULL;
		q->nb_packets--;
		q->size -= pkt1->pkt.size;
		*pkt = pkt1->pkt;
		av_free(pkt1);
		ret = 1;
		break;
    } 
	else if (!block) 
	{
      ret = 0;
      break;
    } 
	else {
		SDL_CondWaitTimeout(q->cond, q->mutex,40);//xinghua
    }
  }
  SDL_UnlockMutex(q->mutex);
  return ret;
}

static void packet_queue_flush(PacketQueue *q) 
{
  AVPacketList *pkt, *pkt1;
  
  SDL_LockMutex(q->mutex);
  for(pkt = q->first_pkt; pkt != NULL; pkt = pkt1) {
    pkt1 = pkt->next;
    av_free_packet(&pkt->pkt);
    av_freep(&pkt);
  }
  q->last_pkt = NULL;
  q->first_pkt = NULL;
  q->nb_packets = 0;
  q->size = 0;
  SDL_UnlockMutex(q->mutex);
}

static void packet_queue_cleanup(PacketQueue *q)
{
   SDL_DestroyMutex(q->mutex);
   SDL_DestroyCond(q->cond);
}
////////////////////////////////////////////////////////
//forward declarations
//
void alloc_picture(void *userdata);
int our_get_buffer(struct AVCodecContext *c, AVFrame *pic) ;
int queue_picture(VideoState *is, AVFrame *pFrame, double pts) ;
int our_get_buffer(struct AVCodecContext *c, AVFrame *pic) ;
void our_release_buffer(struct AVCodecContext *c, AVFrame *pic) ;
void video_refresh_timer(void *userdata) ;

static Uint32 timer1_proc(Uint32 interval, void *opaque)
{
	VideoState *is = (VideoState *)opaque;

#ifdef USE_SDL_VIDEORENDER
	SDL_Event evt;
	if (SDL_PollEvent(&evt) == 1)//User resized window
	{
		if (evt.type == SDL_VIDEORESIZE)
		{
			Msg_t msg;
			msg.type = FF_SETVIDEOMODE;
			msg.data1 = is;
			MSGQ_Post(is->pectrl->pMSGQ, &msg);
		}
	}
#endif

	//check videoq 
	if (is->videoq.nb_packets == 0 && is->buffering == 0)
	{
		Msg_t msg;
		msg.type = FF_BUFFERSTART;
		msg.data1 = is;
		MSGQ_Post(is->pectrl->pMSGQ, &msg);
	}

	if (is->buffering && is->videoq.nb_packets >= VIDEO_BUFFEROVER_NB)
	{
			Msg_t msg;
			msg.type = FF_BUFFEROVER;
			msg.data1 = is;
			MSGQ_Post(is->pectrl->pMSGQ, &msg);


	}
	return interval;
}

static Uint32 sdl_refresh_timer_cb(Uint32 interval, void *opaque) 
{
	VideoState *is = (VideoState *)opaque;

	Msg_t event;
	event.type = FF_REFRESH_EVENT;
	event.data1 = opaque;
	if (MSGQ_Post(is->pectrl->pMSGQ, &event) < 0)
		//OutputDebugString(TEXT("\n---Q_FULL---\n"));
		printf("\n-----Q_FULL-----\n");

	return interval;
    //return 0; /* 0 means stop timer */
}

/* schedule a video refresh in 'delay' ms */
static void schedule_refresh(VideoState *is, int delay) 
{
	if (is->quit) return;
	is->schedule_delay = delay;
	//OutputDebugString(TEXT("A"));
	//SDL_AddTimer(delay, sdl_refresh_timer_cb, is);
}

static int video_thread(void *arg) 
{
  VideoState *is = (VideoState *)arg;
  AVPacket pkt1, *packet = &pkt1;
  int len1, frameFinished;
  AVFrame *pFrame;
  double pts;

  pFrame = avcodec_alloc_frame();

  for(;;)
  {
	  int r;

	  r = packet_queue_get(&is->videoq, packet, 1);
	  if(r ==-1)
	  {
		break;// means we quit getting packets
      }

	  if (r == -2)
		  continue;

      if(packet->data == flush_pkt.data) {
        avcodec_flush_buffers(is->video_codec);
        continue;
      }

	  pts = 0;

      // Save global pts to be stored in pFrame
      is->global_video_pkt_pts = packet->pts;

	  // Decode video frame

		len1 = avcodec_decode_video(is->video_codec, pFrame, &frameFinished, 
				packet->data, packet->size);




    // Did we get a video frame?
		
		if(packet->dts == AV_NOPTS_VALUE 
		   && pFrame->opaque && *(uint64_t*)pFrame->opaque != AV_NOPTS_VALUE) 
		{
		  pts = *(uint64_t *)pFrame->opaque;
			
		} else if(packet->dts != AV_NOPTS_VALUE) {
		  pts = packet->dts;
		} else {
		  pts = 0;
		}
		pts *= av_q2d(RTP_TIMEBASE);

		if(frameFinished) 
		{

		  //pts = synchronize_video(is, pFrame, pts);

		  if(queue_picture(is, pFrame, pts) < 0) {
			break;//we need to quit
		  }
		}
		av_free_packet(packet);

  }//end of for-loop
  av_free(pFrame);

  return 0;
}


static int b64_decode( char *dest, char *src )
{
    const char *dest_start = dest;
    int  i_level;
    int  last = 0;
    int  b64[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 00-0F */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 10-1F */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,  /* 20-2F */
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,  /* 30-3F */
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,  /* 40-4F */
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,  /* 50-5F */
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,  /* 60-6F */
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,  /* 70-7F */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 80-8F */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 90-9F */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* A0-AF */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* B0-BF */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* C0-CF */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* D0-DF */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* E0-EF */
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   /* F0-FF */
        };

    for( i_level = 0; *src != '\0'; src++ )
    {
        int  c;

        c = b64[(unsigned int)*src];
        if( c == -1 )
        {
            continue;
        }

        switch( i_level )
        {
            case 0:
                i_level++;
                break;
            case 1:
                *dest++ = ( last << 2 ) | ( ( c >> 4)&0x03 );
                i_level++;
                break;
            case 2:
                *dest++ = ( ( last << 4 )&0xf0 ) | ( ( c >> 2 )&0x0f );
                i_level++;
                break;
            case 3:
                *dest++ = ( ( last &0x03 ) << 6 ) | c;
                i_level = 0;
        }
        last = c;
    }

    *dest = '\0';

    return dest - dest_start;
}


static unsigned char* parseH264ConfigStr( char const* configStr,
                                          unsigned int& configSize )
{
    char *dup, *psz;
    int i, i_records = 1;

    if( configSize )
    configSize = 0;

    if( configStr == NULL || *configStr == '\0' )
        return NULL;

    psz = dup = strDup( configStr );

    /* Count the number of comma's */
    for( psz = dup; *psz != '\0'; ++psz )
    {
        if( *psz == ',')
        {
            ++i_records;
            *psz = '\0';
        }
    }

    unsigned char *cfg = new unsigned char[5 * strlen(dup)];
    psz = dup;
    for( i = 0; i < i_records; i++ )
    {
        cfg[configSize++] = 0x00;
        cfg[configSize++] = 0x00;
        cfg[configSize++] = 0x00;
        cfg[configSize++] = 0x01;

        configSize += b64_decode( (char*)&cfg[configSize], psz );
        psz += strlen(psz)+1;
    }

    free( dup );
    return cfg;
}


static void setup_codec(VideoState *is)
{
  AVCodec *codec;
   unsigned int extradata_size;
	is->pectrl->extradata = NULL;
#if 0
	if (is->pectrl->rtsp_context->fmtp_spropparametersets)
	{
		unsigned char *parsed_extradata = parseH264ConfigStr(is->pectrl->rtsp_context->fmtp_spropparametersets,extradata_size);
		is->pectrl->extradata = (unsigned char *)malloc(extradata_size + FF_INPUT_BUFFER_PADDING_SIZE);
		memcpy(is->pectrl->extradata,parsed_extradata ,extradata_size);
		free(parsed_extradata);
	}
#endif
  is->video_codec = avcodec_alloc_context();
  is->video_codec->codec_type = CODEC_TYPE_VIDEO;
  is->video_codec->codec_id = CODEC_ID_H264;
  is->video_codec->time_base = RTP_TIMEBASE;
  is->video_codec->pix_fmt = PIX_FMT_YUV420P;
  if (0)//(is->pectrl->extradata != NULL)  //xinghua pass extradata may cause masaic at beginning, though it product the first frame more soon.
  {
	  printf("\n--------- codec extradata  ---------");
	is->video_codec->extradata = is->pectrl->extradata;
	is->video_codec->extradata_size = extradata_size;
	  is->video_codec->flags |= (CODEC_FLAG_GLOBAL_HEADER | CODEC_FLAG2_AUD | CODEC_FLAG2_FASTPSKIP |CODEC_FLAG2_BPYRAMID);
  }
  //is->video_codec->width = 320;
  //is->video_codec->height = 240;
  codec = avcodec_find_decoder(CODEC_ID_H264);
  avcodec_open(is->video_codec, codec);

  is->video_codec->get_buffer = our_get_buffer;
  is->video_codec->release_buffer = our_release_buffer;

}

static void cleanup_codecsetup(VideoState * is)
{
	avcodec_close(is->video_codec);
	av_free(is->video_codec);//free - avcodec_alloc_context

	delete [] is->pectrl->extradata;//xinghua 20101129
}

void take_snapshot_png(VideoState *is, AVPicture *pic );
const AVRational aspect_ratio = {4,3};//width/height
void video_display(VideoState *is) 
{

  
  VideoPicture *vp;

	vp = &is->pictq[is->pictq_rindex];
#ifdef USE_SDL_VIDEORENDER		
  if(vp->bmp)
  {
	  SDL_Rect rect;
	  int w, h, x, y; 
	// apparently this assumption is bad
    h = is->screen->h;
    //w = ((int)rint(h * aspect_ratio)) & -3;
	w = ((int)(h * aspect_ratio.num / aspect_ratio.den)) & -3;
    if(w > is->screen->w) {
      w = is->screen->w;
      //h = ((int)rint(w / aspect_ratio)) & -3;
	  h = ((int)(w * aspect_ratio.den/ aspect_ratio.num)) & -3;
    }
    x = (is->screen->w - w) / 2;
    y = (is->screen->h - h) / 2;

    rect.x = x;
    rect.y = y;
    rect.w = w;
    rect.h = h;

	SDL_DisplayYUVOverlay(vp->bmp, &rect);

  }
#else

	if (vp->bmp)
	{
		take_snapshot_png(is, &(vp->pic));
	}

	//YUV Callback out
	if (vp->bmp && is->pectrl->evt_callback)
	{
		VIDEOYUV_T yuvcb;
		yuvcb.data = vp->pic.data;
		yuvcb.linesize = vp->pic.linesize;

		yuvcb.width = vp->width;
		yuvcb.height = vp->height;
		is->pectrl->evt_callback(is->pectrl->caller, PE_EVENT_VIDEOYUVOUT, (int)&yuvcb);
	}
#endif
}

void video_refresh_timer(void *userdata) 
{
  VideoState *is = (VideoState *)userdata;
  VideoPicture *vp;
  double actual_delay, delay/*, sync_threshold , ref_clock, diff*/;
  
  if(is->quit == 0/*is->video_st*/) 
  {


    if(is->pictq_size == 0) 
	{
      schedule_refresh(is, 40);
	  return;
    } 
	else 
	{
		if(is->buffering)
		{
			schedule_refresh(is, 50);
			return;
		}
		
		if (is->bufferingover)
		{
			is->bufferingover = 0;
			is->frame_timer = (av_gettime() / 1000000.0);
		}

      vp = &is->pictq[is->pictq_rindex];

      //is->video_current_pts = vp->pts;
      //is->video_current_pts_time = av_gettime();

	  delay = vp->pts - is->frame_last_pts; /* the pts from last time */
      if(delay <= 0 || delay >= 1.0) 
	  {
		/* if incorrect delay, use previous one */
		delay = is->frame_last_delay;

      }
      /* save for next time */
      is->frame_last_delay = delay;
      is->frame_last_pts = vp->pts;

      is->frame_timer += delay;
      /* computer the REAL delay */
      actual_delay = is->frame_timer - (av_gettime() / 1000000.0);

		if (actual_delay > 0.5)
			printf("-delay>>-");
	  if(actual_delay < 0.010) 
	  {
		///* Really it should skip the picture instead */
		actual_delay = 0.010;
      }


	  schedule_refresh(is, (int)(actual_delay * 1000));
		
      video_display(is);
		
	  /* update queue for next picture! */
      if(++is->pictq_rindex == VIDEO_PICTURE_QUEUE_SIZE) 
	  {
		is->pictq_rindex = 0;
      }
      SDL_LockMutex(is->pictq_mutex);
      is->pictq_size--;
      SDL_CondSignal(is->pictq_cond);
      SDL_UnlockMutex(is->pictq_mutex);
    }
  } 

}

//should do reset when buffering over and need to do AV Re-sync
static void reset_avparameters(VideoState * is)
{
	//video related reset
	is->global_video_pkt_pts = AV_NOPTS_VALUE;

    is->frame_timer = (double)av_gettime() / 1000000.0;
    is->frame_last_delay = 40e-3;
    //is->video_current_pts_time = av_gettime();
}

void alloc_picture(void *userdata) 
{

  VideoState *is = (VideoState *)userdata;
  VideoPicture *vp;

  vp = &is->pictq[is->pictq_windex];
#ifdef USE_SDL_VIDEORENDER
  if(vp->bmp) {
    // we already have one make another, bigger/smaller
    SDL_FreeYUVOverlay(vp->bmp);
	vp->bmp = NULL;
  }
  //if (vp->bmp == NULL)
  {
  // Allocate a place to put our YUV image on that screen
  vp->bmp = SDL_CreateYUVOverlay(is->video_codec->width,
				 is->video_codec->height,
				 SDL_YV12_OVERLAY,
				 is->screen);
  vp->width = is->video_codec->width;
  vp->height = is->video_codec->height;
  }
	
#else
	if (vp->bmp == 0)
	{
		avpicture_alloc(&vp->pic, PIX_FMT_YUV420P, is->video_codec->width,is->video_codec->height);
		vp->bmp = 1;
		vp->width = is->video_codec->width;
		vp->height = is->video_codec->height;		
	}
	
#endif
	
  SDL_LockMutex(is->pictq_mutex);
  vp->allocated = 1;
  SDL_CondSignal(is->pictq_cond);
  SDL_UnlockMutex(is->pictq_mutex);

}

void take_snapshot_png(VideoState *is, AVPicture *pic )
{
  	static struct SwsContext *sws_Context;

		//convert from YUV420P into RGB format
	if(is->pectrl->snapshot_request == 1)
	{
		AVPicture picRGB;
		//int numbyte;
		int w,h;
		w = is->video_codec->width;
		h = is->video_codec->height;
        sws_Context = sws_getCachedContext(sws_Context,
                                           w, h, PIX_FMT_YUV420P, /* src format */
                                           w, h, PIX_FMT_RGB24,      /* destination format */
                                           SWS_BICUBIC, NULL, NULL, NULL);
        if (!sws_Context) {
			is->pectrl->snapshot_request = -1;
			return;
        }
		avpicture_alloc(&picRGB,PIX_FMT_RGB24, w, h);

        int res = sws_scale(sws_Context,
				pic->data,pic->linesize, 0, h, /* src format */
                            picRGB.data, picRGB.linesize);  /* destination format */
        if (res<0) {

			is->pectrl->snapshot_request = -1;
			return;
        }
		else 
			write_png(is->pectrl->snapshot_filename, picRGB.data[0], w, h, 8, 3);

		avpicture_free(&picRGB);
		is->pectrl->snapshot_request = 0;
	}
}

int queue_picture(VideoState *is, AVFrame *pFrame, double pts) 
{

  VideoPicture *vp;



  /* wait until we have space for a new pic */
  SDL_LockMutex(is->pictq_mutex);
  while(is->pictq_size >= VIDEO_PICTURE_QUEUE_SIZE &&
	!is->quit) {
    SDL_CondWaitTimeout(is->pictq_cond, is->pictq_mutex,50);
  }
  SDL_UnlockMutex(is->pictq_mutex);

  if(is->quit)
    return -1;

  // windex is set to 0 initially
  vp = &is->pictq[is->pictq_windex];

  /* allocate or resize the buffer! */
  if(!vp->bmp ||
     vp->width != is->video_codec->width ||
     vp->height != is->video_codec->height) 
  {

    vp->allocated = 0;
    /* we have to do it in the main thread */
	Msg_t event;
	event.type = FF_ALLOC_EVENT;
	event.data1 = is;
	MSGQ_Post(is->pectrl->pMSGQ, &event);

    /* wait until we have a picture allocated */
    SDL_LockMutex(is->pictq_mutex);
    while(!vp->allocated && !is->quit) {
      SDL_CondWaitTimeout(is->pictq_cond, is->pictq_mutex,200);
    }
    SDL_UnlockMutex(is->pictq_mutex);
    if(is->quit) {
      return -1;
    }
  }
  /* We have a place to put our picture on the queue */
  /* If we are skipping a frame, do we set this to null 
     but still return vp->allocated = 1? */


  if(vp->bmp) {
	  
#ifdef USE_SDL_VIDEORENDER
	 static int avcopyfail_flag;
	  int dst_pix_fmt;
	  AVPicture pict;	  
    SDL_LockYUVOverlay(vp->bmp);
    
    dst_pix_fmt = PIX_FMT_YUV420P;
    /* point pict at the queue */

    pict.data[0] = vp->bmp->pixels[0];
    pict.data[1] = vp->bmp->pixels[2];
    pict.data[2] = vp->bmp->pixels[1];
    
    pict.linesize[0] = vp->bmp->pitches[0];
    pict.linesize[1] = vp->bmp->pitches[2];
    pict.linesize[2] = vp->bmp->pitches[1];
	
	take_snapshot_png(is, (AVPicture *)pFrame);

//#ifdef WIN32
	__try {
		av_picture_copy(&pict, (const AVPicture *)pFrame, dst_pix_fmt, is->video_codec->width, is->video_codec->height);
	}
	__except (filter(GetExceptionCode(), GetExceptionInformation()))
	{
		SDL_UnlockYUVOverlay(vp->bmp);
		avcopyfail_flag = 1;
		return 0;
	}

	if (avcopyfail_flag)
	{
		Msg_t msg;
		msg.type = FF_SETVIDEOMODE;
		msg.data1 = is;
		MSGQ_Post(is->pectrl->pMSGQ, &msg);
	}
	avcopyfail_flag = 0;
//#endif
	
    SDL_UnlockYUVOverlay(vp->bmp);
#else
	  
	av_picture_copy(&vp->pic, (const AVPicture *)pFrame, PIX_FMT_YUV420P, is->video_codec->width, is->video_codec->height);
	  
#endif
    vp->pts = pts;

    /* now we inform our display thread that we have a pic ready */
    if(++is->pictq_windex == VIDEO_PICTURE_QUEUE_SIZE) {
      is->pictq_windex = 0;
    }
    SDL_LockMutex(is->pictq_mutex);
    is->pictq_size++;
    SDL_UnlockMutex(is->pictq_mutex);
  }
  return 0;
}


#if 0
double synchronize_video(VideoState *is, AVFrame *src_frame, double pts) 
{

  double frame_delay;

  if(pts != 0) {
    /* if we have pts, set video clock to it */
    is->video_clock = pts;
  } else {
    /* if we aren't given a pts, set it to the clock */
    pts = is->video_clock;
  }
  /* update the video clock */
  //frame_delay = av_q2d(is->video_codec->time_base) ;
  frame_delay = is->frame_last_delay;
  /* if we are repeating a frame, adjust clock accordingly */
   /* for MPEG2, the frame can be repeated, so we update the
       clock accordingly */

  frame_delay += src_frame->repeat_pict * (frame_delay * 0.5);
  is->video_clock += frame_delay;
  return pts;
}
#endif

/* These are called whenever we allocate a frame
 * buffer. We use this to store the global_pts in
 * a frame at the time it is allocated.
 */
int our_get_buffer(struct AVCodecContext *c, AVFrame *pic) 
{
  int ret = avcodec_default_get_buffer(c, pic);
  uint64_t *pts = (uint64_t *)av_malloc(sizeof(uint64_t));
  *pts = g_video_state->global_video_pkt_pts;
  pic->opaque = pts;
  return ret;
}

void our_release_buffer(struct AVCodecContext *c, AVFrame *pic) 
{
  if(pic) av_freep(&pic->opaque);
  avcodec_default_release_buffer(c, pic);
}

int decode_interrupt_cb(void) 
{
  return (g_video_state && g_video_state->quit);
}

int mainloop_thread(void *arg)
{
	PE_CTRL_T * ctrl = (PE_CTRL_T*)arg;
	VideoState *is = ctrl->is;

	is->buffering = 1;
	MSGQ_Flush(ctrl->pMSGQ);

	//at first Open RTSP connection, It may take some time 
	if (RTSPClient_Open(ctrl->rtsp_context, ctrl->url) < 0)
	{
		if (ctrl->evt_callback)
			ctrl->evt_callback(ctrl->caller, PE_EVENT_RTSPOPEN_COMPLETE, -1);
		ctrl->mainloop_running = 0;
		return -1;
	}

	if (ctrl->mainloop_running == 0)//could be terminated by user
	{
		return -1;
	}
	
	if (ctrl->evt_callback)
			ctrl->evt_callback(ctrl->caller, PE_EVENT_RTSPOPEN_COMPLETE, 0);

	//init VideoState context
	memset(is, 0, sizeof(VideoState));
	is->pectrl = ctrl;

	is->pictq_mutex = SDL_CreateMutex();
	is->pictq_cond = SDL_CreateCond();
	packet_queue_init(&(is->videoq));

	setup_codec(is);
	reset_avparameters(is);

	if (ctrl->rtsp_threadid == 0)
	ctrl->rtsp_threadid = SDL_CreateThread(rtsp_threadfunc, ctrl);


	if (is->video_tid == 0)
		is->video_tid = SDL_CreateThread(video_thread, is);


#ifdef USE_SDL_VIDEORENDER

	SDL_putenv("SDL_VIDEODRIVER=directx");
	SDL_putenv("SDL_VIDEO_YUV_DIRECT");
	SDL_putenv("SDL_VIDEO_YUV_HWACCEL");	
	SDL_Init(SDL_INIT_VIDEO /*| SDL_INIT_AUDIO */| SDL_INIT_NOPARACHUTE);


	RECT rect;
	GetClientRect((HWND)ctrl->hwnd,&rect);
	ctrl->is->screen  = SDL_SetVideoMode(/*320*/rect.right -rect.left, rect.bottom - rect.top/*240*/, 0,SDL_HWSURFACE | SDL_RESIZABLE);

	if(ctrl->hwnd)//xinghua,  patch for SDL_DirectX
	{//xinghua,  patch for SDL_DirectX
		WINDOWPOS pos ;
		pos.hwnd = (HWND)ctrl->hwnd;
		pos.flags = SWP_NOZORDER | SWP_NOSIZE | SWP_NOREPOSITION | SWP_NOREDRAW | SWP_NOCOPYBITS | SWP_NOMOVE;
		SendMessage((HWND)ctrl->hwnd,WM_WINDOWPOSCHANGED,0,(LPARAM)&pos);
	}
#endif
	
	//main-event-checking-loop
	if (is->pectrl->evt_callback)
		is->pectrl->evt_callback(is->pectrl->caller, PE_EVENT_BUFFERING, 0);

	is->timer1 = SDL_AddTimer(TIMER1_PERIOD, timer1_proc, is);


	schedule_refresh(is, 100);
	is->timer_refresh = SDL_AddTimer(TIMER_REFRESH_PERIOD, sdl_refresh_timer_cb, is);
    for(;;) 
	{
		Msg_t msg;
		MSGQ_Wait(ctrl->pMSGQ, &msg);

		switch(msg.type) 
		{
		case FF_SETVIDEOMODE:
			{
#ifdef WIN32
				//SDL_Event evt;
				//if (SDL_PollEvent(&evt) == 1)//User resized window
				//{
				//	if (evt.type == SDL_VIDEORESIZE)
				//		ctrl->is->screen = SDL_SetVideoMode(evt.resize.w, evt.resize.h, 0,SDL_HWSURFACE | SDL_RESIZABLE); 
				//}
			RECT rect;
			GetClientRect((HWND)is->pectrl->hwnd,&rect);
			is->screen  = SDL_SetVideoMode(rect.right -rect.left, rect.bottom - rect.top, 0,SDL_HWSURFACE | SDL_RESIZABLE);
#endif
			}
			break;

		case FF_QUIT_EVENT:
			goto __exit1;
		  break;

		case FF_ALLOC_EVENT:
		  alloc_picture(msg.data1);
		  break;
		case FF_REFRESH_EVENT:
			if (is->quit == 0)
			{
				if (is->schedule_delay <= TIMER_REFRESH_PERIOD)
				{
					video_refresh_timer(msg.data1);
				}
				else
					is->schedule_delay -= TIMER_REFRESH_PERIOD;

			}
		  break;
		case FF_BUFFERSTART:
			if(is->buffering == 0)
			{
				is->buffering = 1;
				if (is->pectrl->evt_callback)
					is->pectrl->evt_callback(is->pectrl->caller, PE_EVENT_BUFFERING, 0);
			}
			break;
				
		case FF_BUFFEROVER:
			if(is->buffering)
			{
				is->buffering = 0;
				is->bufferingover = 1;
				if (is->pectrl->evt_callback)
					is->pectrl->evt_callback(is->pectrl->caller, PE_EVENT_PLAYING, 0);
			}
			break;
		default:

		  break;
		}
    }
__exit1:
	//SDL_CloseAudio();

	is->quit = 1;
	is->buffering = 0;

	SDL_RemoveTimer(is->timer_refresh);
	SDL_RemoveTimer(is->timer1);

	//stop rtsp dump procedure
	{
		
		RTSPClient_Terminate(ctrl->rtsp_context);
		SDL_WaitThread(ctrl->rtsp_threadid, NULL);
		ctrl->rtsp_threadid = NULL;
	}

	if(is->video_tid)//end of video thread
	{
		SDL_WaitThread(is->video_tid,NULL);
		is->video_tid = 0;
	}

	cleanup_codecsetup(is);

	//cleanup items allocated previously
#ifdef USE_SDL_VIDEORENDER
#else
	for (int i=0; i<is->pictq_size; i++)
	{
		avpicture_free(&is->pictq[i].pic);
		is->pictq[i].bmp = 0;
	}
#endif
	packet_queue_cleanup(&is->videoq);
	
	
	SDL_DestroyMutex(is->pictq_mutex);
	SDL_DestroyCond(is->pictq_cond );

	ctrl->mainloop_running = 0;
    return 0;
}


//////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////


PE_CTRL_T *PE_Create(PE_EVT_CALLBACK evt_cb, void *caller)
{
	PE_CTRL_T *ctrl ; 

	SDL_Init(SDL_INIT_TIMER);

	// Register all formats and codecs
	av_register_all();

	av_init_packet(&flush_pkt);
	flush_pkt.data = (uint8_t*)"FLUSH";

	ctrl = (PE_CTRL_T*)malloc(sizeof(PE_CTRL_T));
	memset(ctrl, 0, sizeof(PE_CTRL_T));

	ctrl->evt_callback = evt_cb;
	ctrl->caller = caller;

	//rtsp_context init
	ctrl->rtsp_context = RTSPClient_Init(ctrl, on_rtsp_callback);
	
	//create a msg queue
	ctrl->pMSGQ = MSGQ_Create(sizeof(Msg_t), 64);
	//ctrl->schedule_refresh_lock = SDL_CreateMutex();

	ctrl->is = (VideoState *)av_mallocz(sizeof(VideoState));
	g_video_state = ctrl->is;
	return ctrl;

}

void PE_Destroy(PE_CTRL_T *ctrl)
{
	PE_Stop(ctrl);

	RTSPClient_Deinit(ctrl->rtsp_context);
	av_free(ctrl->is);
	ctrl->is = NULL;

	g_video_state = NULL;
	//SDL_DestroyMutex(ctrl->schedule_refresh_lock);
	MSGQ_Destroy(ctrl->pMSGQ);
	free(ctrl);
}

/*
return:
0 - OK
<0 - fail
*/
int PE_Start(PE_CTRL_T *ctrl, char *url)
{
	if (ctrl->mainloop_running == 1)
		return -1 ;

	strcpy(ctrl->url, url);
	ctrl->mainloop_running = 1;
	ctrl->mainloop_tid = SDL_CreateThread(mainloop_thread, ctrl);
	return 0;
}

void PE_Stop(PE_CTRL_T *ctrl)
{
	PE_StopRecord(ctrl);//xinghua 20101029
	if (ctrl->mainloop_running == 0)
		return;
	//end main loop thread
	Msg_t event;
	event.type = FF_QUIT_EVENT;
	event.data1 = ctrl;
	MSGQ_Post(ctrl->pMSGQ, &event);

	SDL_WaitThread(ctrl->mainloop_tid, NULL);
	ctrl->mainloop_tid = NULL;
	
}


void PE_SetVideoWindow(PE_CTRL_T *ctrl, void * videownd)
{
#ifdef WIN32
	char envstr[64] = {0};
	sprintf_s(envstr,"SDL_WINDOWID=0x%X", (unsigned int)(videownd));
	SDL_putenv((const char*)envstr);
	ctrl->hwnd = videownd;
#endif
}

void PE_UpdateVideoWindow(PE_CTRL_T *ctrl)
{
	
#ifdef WIN32
	WINDOWPOS pos ;
	pos.hwnd = (HWND)ctrl->hwnd;
#ifdef UNDER_CE
	pos.flags = SWP_NOZORDER | SWP_NOSIZE | SWP_NOREPOSITION | SWP_NOMOVE;
#else
	pos.flags = SWP_NOZORDER | SWP_NOSIZE | SWP_NOREPOSITION | SWP_NOREDRAW | SWP_NOCOPYBITS | SWP_NOMOVE;
#endif
	SendMessage((HWND)ctrl->hwnd,WM_WINDOWPOSCHANGED,0,(LPARAM)&pos);
#endif
	
}


int PE_PushPacket(PE_CTRL_T *ctrl, RTP_PLAYLOAD_PACKET *pkt)
{
	AVPacket apkt, *packet = &apkt;
	VideoState * is = ctrl->is; 

	if (is->videoq.nb_packets >= VIDEO_DROP_THRESHOLD)//reach this drop threshold, we assume decoder could be stuck
	{
		//packet_queue_flush(&is->videoq);
		//packet_queue_put(&is->videoq, &flush_pkt);
		//OutputDebugString(TEXT("--\nVIDEO_DROP_THRESHOLD--"));
		printf("--\nVIDEO_DROP_THRESHOLD--");
		return -1;
	}

	av_new_packet(packet, pkt->len);
	memcpy(packet->data,pkt->buf,pkt->len);
	packet->pts = pkt->timestamp.tv_sec * 1000000 + pkt->timestamp.tv_usec;
	packet_queue_put(&is->videoq, packet);

	return 0;
}


/*---------------------------------------------------------------------
yuv2rgb
*/
/*
int ff_yuv2rgb32(const uint8_t* const srcSlice[], const int srcStride[], uint8_t* rgb, int w, int h)
{
	AVPicture pic = {0};
	static struct SwsContext *img_convert_ctx = NULL;
    if(img_convert_ctx == NULL) 
	{
		
		
		img_convert_ctx = sws_getContext(w, h, 
										 PIX_FMT_YUV420P, w, h, 
										 PIX_FMT_BGRA, SWS_BICUBIC, NULL, NULL, NULL);
		if(img_convert_ctx == NULL) {
			//fprintf(stderr, "Cannot initialize the conversion context!\n");
			return -1;
		}
	}
	pic.data[0] = rgb;
	pic.linesize[0] = w*4;
	
	
	sws_scale(img_convert_ctx, srcSlice, srcStride,
			  0, h, pic.data, pic.linesize);
	return 0;	
}*/

//xinghua 20110831
int ff_yuv2rgb32(const uint8_t* const srcSlice[], const int srcStride[], uint8_t* rgb, int w, int h)
{
	static int width = 0, height = 0;
	AVPicture pic = {0};
	static struct SwsContext *img_convert_ctx = NULL;
    if(width != w || height != h) 
	{
		width = w;
		height = h;
		
		printf("\n===========new video size %d,%d========",width, height);
		
		if (img_convert_ctx)
			sws_freeContext(img_convert_ctx);
		
		img_convert_ctx = sws_getContext(w, h, 
										 PIX_FMT_YUV420P, w, h, 
										 PIX_FMT_BGRA, SWS_BICUBIC, NULL, NULL, NULL);
		if(img_convert_ctx == NULL) {
			//fprintf(stderr, "Cannot initialize the conversion context!\n");
			return -1;
		}
	}
	pic.data[0] = rgb;
	pic.linesize[0] = w*4;
	
	
	sws_scale(img_convert_ctx, srcSlice, srcStride,
			  0, h, pic.data, pic.linesize);
	return 0;	
}



void PE_StartRecord(PE_CTRL_T *ctrl, char *filename, int sizeType)
{
    if (sizeType == 1) {
        RTSPClient_StartRecord(ctrl->rtsp_context, filename, 176, 144);
    } else if (sizeType == 2) {
        RTSPClient_StartRecord(ctrl->rtsp_context, filename, 320, 240);
    } else {
        RTSPClient_StartRecord(ctrl->rtsp_context, filename, 320, 240);
    }
	
}
void PE_StopRecord(PE_CTRL_T *ctrl)
{
	RTSPClient_StopRecord(ctrl->rtsp_context);
}


void PE_RequestSnapshot(PE_CTRL_T *ctrl, char *filename)
{
	strcpy(ctrl->snapshot_filename, filename);
	ctrl->snapshot_request = 1;
}

//snapshot_request value :
//1 : request; 0 : snapshot is taken successfully; -1 : snapshot failed
int PE_CheckSnapshot(PE_CTRL_T *ctrl)
{
	return 	ctrl->snapshot_request;
}

//if last request is not handled, caller may undo it
void PE_UndoSnapshotRequest(PE_CTRL_T *ctrl)
{
	ctrl->snapshot_request = 0;
}
