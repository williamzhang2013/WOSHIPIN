// tutorial08.c
extern "C"
{
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
}
#include <stdio.h>
#include <math.h>
#include "SDL.h"
#include "msgq.h"
#include "pe_ctrl.h"

#undef USE_SDL_VIDEORENDER

////////////////////////////////////////////////////
#define SDL_AUDIO_BUFFER_SIZE 1024
#define MAX_AUDIOQ_SIZE (5 * 16 * 1024)
#define MAX_VIDEOQ_SIZE (5 * 20 * 1024)
#define AV_SYNC_THRESHOLD 0.01
#define AV_NOSYNC_THRESHOLD 10.0
#define SAMPLE_CORRECTION_PERCENT_MAX 10
#define AUDIO_DIFF_AVG_NB 20
#define FF_ALLOC_EVENT   (SDL_USEREVENT)
#define FF_REFRESH_EVENT (SDL_USEREVENT + 1)
#define FF_QUIT_EVENT (SDL_USEREVENT + 2) //user terminate
#define VIDEO_PICTURE_QUEUE_SIZE 1
#define DEFAULT_AV_SYNC_TYPE AV_SYNC_VIDEO_MASTER
#define TIMER_REFRESH_PERIOD	10			

typedef struct msg_s
{
	int type;
	int code;
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

  AVFormatContext *pFormatCtx;
  int             videoStream, audioStream;

  int             av_sync_type;
  double          external_clock; /* external clock base */
  int64_t         external_clock_time;
  int             seek_req;
  int             seek_flags;
  int64_t         seek_pos;
  double          audio_clock;
  AVStream        *audio_st;
  PacketQueue     audioq;
  DECLARE_ALIGNED(16, uint8_t, audio_buf[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2]);

  unsigned int    audio_buf_size;
  unsigned int    audio_buf_index;
  AVPacket        audio_pkt;
  uint8_t         *audio_pkt_data;
  int             audio_pkt_size;
  int             audio_hw_buf_size;  
  double          audio_diff_cum; /* used for AV difference average computation */
  double          audio_diff_avg_coef;
  double          audio_diff_threshold;
  int             audio_diff_avg_count;
  double          frame_timer;
  double          frame_last_pts;
  double          frame_last_delay;
  double          video_clock; ///<pts of last decoded frame / predicted pts of next decoded frame
  double          video_current_pts; ///<current displayed pts (different from video_clock if frame fifos are used)
  int64_t         video_current_pts_time;  ///<time (av_gettime) at which we updated video_current_pts - used to have running video pts
  AVStream        *video_st;
  PacketQueue     videoq;

  VideoPicture    pictq[VIDEO_PICTURE_QUEUE_SIZE];
  int             pictq_size, pictq_rindex, pictq_windex;
  SDL_mutex       *pictq_mutex;
  SDL_cond        *pictq_cond;
  SDL_Thread      *parse_tid;
  SDL_Thread      *video_tid;
	SDL_Thread    *main_tid;
  //char            filename[1024];
  int             quit;
	
	SDL_TimerID	timer_refresh;//10ms timer
	int schedule_delay;
	
	int paused ;
	int frame_step;
	int readframe_end;
  MSGQ_T *pMSGQ;	
  PF_HANDLE pf_handle;
	PE_EVT_CALLBACK evt_callback;
	void * caller;	
} VideoState;


enum {
  AV_SYNC_AUDIO_MASTER,
  AV_SYNC_VIDEO_MASTER,
  AV_SYNC_EXTERNAL_MASTER,
};


/* Since we only have one decoding thread, the Big Struct
   can be global in case we need it. */
static VideoState *global_video_state;
static AVPacket flush_pkt;


static void packet_queue_init(PacketQueue *q) {
  memset(q, 0, sizeof(PacketQueue));
  q->mutex = SDL_CreateMutex();
  q->cond = SDL_CreateCond();
}

static int packet_queue_put(PacketQueue *q, AVPacket *pkt) {
  AVPacketList *pkt1;
  if(pkt != &flush_pkt && av_dup_packet(pkt) < 0) {
    return -1;
  }
  pkt1 = (AVPacketList*)av_malloc(sizeof(AVPacketList));
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
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block) {
  AVPacketList *pkt1;
  int ret;

  SDL_LockMutex(q->mutex);
  
  for(;;) {
    
    if(global_video_state->quit) {
      ret = -1;
      break;
    }

    pkt1 = q->first_pkt;
    if (pkt1) {
      q->first_pkt = pkt1->next;
      if (!q->first_pkt)
	q->last_pkt = NULL;
      q->nb_packets--;
      q->size -= pkt1->pkt.size;
      *pkt = pkt1->pkt;
      av_free(pkt1);
      ret = 1;
      break;
    } else if (!block) {
      ret = 0;
      break;
    } else {
      if (SDL_CondWaitTimeout(q->cond, q->mutex,50) == SDL_MUTEX_TIMEDOUT)
	  {
		 if (global_video_state->readframe_end)
		 {
			 Msg_t event;
			 event.type = FF_QUIT_EVENT;
			 event.code = PF_ENDOFFILE;
			 event.data1 = global_video_state;
			 MSGQ_Post(global_video_state->pMSGQ, &event);
			 ret = -1;
			 break;
		 }
	  }
    }
  }
  SDL_UnlockMutex(q->mutex);
  return ret;
}
static void packet_queue_flush(PacketQueue *q) {
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

static double get_audio_clock(VideoState *is) {
  double pts;
  int hw_buf_size, bytes_per_sec, n;

  pts = is->audio_clock; /* maintained in the audio thread */
  hw_buf_size = is->audio_buf_size - is->audio_buf_index;
  bytes_per_sec = 0;
  n = is->audio_st->codec->channels * 2;
  if(is->audio_st) {
    bytes_per_sec = is->audio_st->codec->sample_rate * n;
  }
  if(bytes_per_sec) {
    pts -= (double)hw_buf_size / bytes_per_sec;
  }
  return pts;
}

static double get_video_clock(VideoState *is) {
  double delta;

  delta = (av_gettime() - is->video_current_pts_time) / 1000000.0;
  return is->video_current_pts + delta;
}

static double get_external_clock(VideoState *is) {
  return av_gettime() / 1000000.0;
}

static double get_master_clock(VideoState *is) {
  if(is->av_sync_type == AV_SYNC_VIDEO_MASTER) {
    return get_video_clock(is);
  } else if(is->av_sync_type == AV_SYNC_AUDIO_MASTER) {
    return get_audio_clock(is);
  } else {
    return get_external_clock(is);
  }
}
/* Add or subtract samples to get a better sync, return new
   audio buffer size */
static int synchronize_audio(VideoState *is, short *samples,
		      int samples_size, double pts) {
  int n;
  double ref_clock;
  
  n = 2 * is->audio_st->codec->channels;
  
  if(is->av_sync_type != AV_SYNC_AUDIO_MASTER) {
    double diff, avg_diff;
    int wanted_size, min_size, max_size, nb_samples;
    
    ref_clock = get_master_clock(is);
    diff = get_audio_clock(is) - ref_clock;
    if(diff < AV_NOSYNC_THRESHOLD) {
      // accumulate the diffs
      is->audio_diff_cum = diff + is->audio_diff_avg_coef
	* is->audio_diff_cum;
      if(is->audio_diff_avg_count < AUDIO_DIFF_AVG_NB) {
	is->audio_diff_avg_count++;
      } else {
	avg_diff = is->audio_diff_cum * (1.0 - is->audio_diff_avg_coef);
	if(fabs(avg_diff) >= is->audio_diff_threshold) {
	  wanted_size = samples_size + ((int)(diff * is->audio_st->codec->sample_rate) * n);
	  min_size = samples_size * ((100 - SAMPLE_CORRECTION_PERCENT_MAX) / 100);
	  max_size = samples_size * ((100 + SAMPLE_CORRECTION_PERCENT_MAX) / 100);
	  if(wanted_size < min_size) {
	    wanted_size = min_size;
	  } else if (wanted_size > max_size) {
	    wanted_size = max_size;
	  }
	  if(wanted_size < samples_size) {
	    /* remove samples */
	    samples_size = wanted_size;
	  } else if(wanted_size > samples_size) {
	    uint8_t *samples_end, *q;
	    int nb;
	    /* add samples by copying final sample*/
	    nb = (samples_size - wanted_size);
	    samples_end = (uint8_t *)samples + samples_size - n;
	    q = samples_end + n;
	    while(nb > 0) {
	      memcpy(q, samples_end, n);
	      q += n;
	      nb -= n;
	    }
	    samples_size = wanted_size;
	  }
	}
      }
    } else {
      /* difference is TOO big; reset diff stuff */
      is->audio_diff_avg_count = 0;
      is->audio_diff_cum = 0;
    }
  }
  return samples_size;
}
static int audio_decode_frame(VideoState *is, uint8_t *audio_buf, int buf_size, double *pts_ptr) {
  int len1, data_size, n;
  AVPacket *pkt = &is->audio_pkt;
  double pts;

  for(;;) {
    while(is->audio_pkt_size > 0) {
      data_size = buf_size;
      len1 = avcodec_decode_audio2(is->audio_st->codec, 
				   (int16_t *)audio_buf, &data_size, 
				   is->audio_pkt_data, is->audio_pkt_size);
      if(len1 < 0) {
	/* if error, skip frame */
	is->audio_pkt_size = 0;
	break;
      }
      is->audio_pkt_data += len1;
      is->audio_pkt_size -= len1;
      if(data_size <= 0) {
	/* No data yet, get more frames */
	continue;
      }
      pts = is->audio_clock;
      *pts_ptr = pts;
      n = 2 * is->audio_st->codec->channels;
      is->audio_clock += (double)data_size /
	(double)(n * is->audio_st->codec->sample_rate);

      /* We have data, return it and come back for more later */
      return data_size;
    }
    if(pkt->data)
      av_free_packet(pkt);

    if(is->quit) {
      return -1;
    }
    /* next packet */
    if(packet_queue_get(&is->audioq, pkt, 1) < 0) {
      return -1;
    }
    if(pkt->data == flush_pkt.data) {
      avcodec_flush_buffers(is->audio_st->codec);
      continue;
    }
    is->audio_pkt_data = pkt->data;
    is->audio_pkt_size = pkt->size;
    /* if update, update the audio clock w/pts */
    if(pkt->pts != AV_NOPTS_VALUE) {
      is->audio_clock = av_q2d(is->audio_st->time_base)*pkt->pts;
    }
  }
}

static void audio_callback(void *userdata, Uint8 *stream, int len) {
  VideoState *is = (VideoState *)userdata;
  int len1, audio_size;
  double pts;

  while(len > 0) {
    if(is->audio_buf_index >= is->audio_buf_size) {
      /* We have already sent all our data; get more */
      audio_size = audio_decode_frame(is, is->audio_buf, sizeof(is->audio_buf), &pts);
      if(audio_size < 0) {
		/* If error, output silence */
		is->audio_buf_size = 1024;
		memset(is->audio_buf, 0, is->audio_buf_size);
      } else {
		audio_size = synchronize_audio(is, (int16_t *)is->audio_buf,
						   audio_size, pts);
		is->audio_buf_size = audio_size;
      }
      is->audio_buf_index = 0;
    }
    len1 = is->audio_buf_size - is->audio_buf_index;
    if(len1 > len)
      len1 = len;
    memcpy(stream, (uint8_t *)is->audio_buf + is->audio_buf_index, len1);
    len -= len1;
    stream += len1;
    is->audio_buf_index += len1;
  }
}

static Uint32 sdl_refresh_timer_cb(Uint32 interval, void *opaque) {
	VideoState *is = (VideoState *)opaque;
	Msg_t event;
	event.type = FF_REFRESH_EVENT;
	event.data1 = is;
	MSGQ_Post(is->pMSGQ, &event);
	
 // return 0; /* 0 means stop timer */
	return interval;
}


/* schedule a video refresh in 'delay' ms */
static void schedule_refresh(VideoState *is, int delay) 
{
	if (is->quit) return;
	if(delay < TIMER_REFRESH_PERIOD) delay = TIMER_REFRESH_PERIOD;
	is->schedule_delay = delay;
  //SDL_AddTimer(delay, sdl_refresh_timer_cb, is);
}


//this must be implemented outside
extern void VIDEO_RENDER_CALLBACK(int pix_format,unsigned char **data, int *linesize, int Width, int Height);

//update yuv , xinghua
static void video_display(VideoState *is) 
{

  VideoPicture *vp;

  vp = &is->pictq[is->pictq_rindex];
  if(vp->bmp) 
  {
		  VIDEOYUV_T yuvcb;
		  yuvcb.data = vp->pic.data;
		  yuvcb.linesize = vp->pic.linesize;
		  
		  yuvcb.width = vp->width;
		  yuvcb.height = vp->height;
		  is->evt_callback(is->caller, PE_EVENT_VIDEOYUVOUT, (int)&yuvcb);
	  printf("-VDISP-");
  }
}

static void video_refresh_timer(void *userdata) {

  VideoState *is = (VideoState *)userdata;
  VideoPicture *vp;
  double actual_delay, delay, sync_threshold, ref_clock, diff;
  
  if(is->video_st) 
  {
	if (is->paused )//xinghua 20100901
	{
		is->frame_timer = (double)av_gettime() / 1000000.0;
		is->video_current_pts_time = av_gettime();
		
		if(is->frame_step == 0 /*|| is->pictq_size == 0*/)
		{
			schedule_refresh(is, 40);
			return;
		}
	} 
    if(is->pictq_size == 0) 
	{
      schedule_refresh(is, 1);
    } 
	else 
	{
		if (is->frame_step > 0)
			is->frame_step --;
		
      vp = &is->pictq[is->pictq_rindex];

      is->video_current_pts = vp->pts;
      is->video_current_pts_time = av_gettime();
		
	  if(!is->paused)
	  {

		  delay = vp->pts - is->frame_last_pts; /* the pts from last time */
		  if(delay <= 0 || delay >= 1.0) 
		  {
			/* if incorrect delay, use previous one */
			delay = is->frame_last_delay;
		  }
		  /* save for next time */
		  is->frame_last_delay = delay;
		  is->frame_last_pts = vp->pts;

		  /* update delay to sync to audio if not master source */
		  if(is->av_sync_type != AV_SYNC_VIDEO_MASTER) 
		  {
			ref_clock = get_master_clock(is);
			diff = vp->pts - ref_clock;
			
			/* Skip or repeat the frame. Take delay into account
			   FFPlay still doesn't "know if this is the best guess." */
			sync_threshold = (delay > AV_SYNC_THRESHOLD) ? delay : AV_SYNC_THRESHOLD;
			if(fabs(diff) < AV_NOSYNC_THRESHOLD) 
			{
				if(diff <= -sync_threshold) 
				{
					delay = 0;
				} else if(diff >= sync_threshold) 
				{
					delay = 2 * delay;
				}
			}
		  }//if(is->av_sync_type ...)

		  is->frame_timer += delay;
		  /* computer the REAL delay */
		  actual_delay = is->frame_timer - (av_gettime() / 1000000.0);
		  //printf("-actual_delay %f-",actual_delay);
		  if(actual_delay < 0.010) 
		  {
			/* Really it should skip the picture instead */
			actual_delay = 0.010;
		  }
			
		  schedule_refresh(is, (int)(actual_delay * 1000));
	  }
	  else {
		  is->frame_last_pts = vp->pts;
		  schedule_refresh(is, 10);
			  
	  }

      /* show the picture! */
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
  else {
    schedule_refresh(is, 100);
  }
}
      
static void alloc_picture(void *userdata) {

  VideoState *is = (VideoState *)userdata;
  VideoPicture *vp;

  vp = &is->pictq[is->pictq_windex];

#ifndef USE_SDL_VIDEORENDER //xinghua 20100317
  //if (vp->bmp)
  {
  //	  avpicture_free(&vp->bmppic);
	//  vp->bmp = 0;
  }
	
	if (vp->bmp == 0)
	{
		//avpicture_alloc(&vp->bmppic,PIX_FMT_BGRA, is->video_st->codec->width,is->video_st->codec->height);
		avpicture_alloc(&vp->pic, PIX_FMT_YUV420P, is->video_st->codec->width,is->video_st->codec->height);
		vp->bmp = 1;
	}

#else
  if(vp->bmp) {
    // we already have one make another, bigger/smaller
    SDL_FreeYUVOverlay(vp->bmp);
  }
  // Allocate a place to put our YUV image on that screen
  vp->bmp = SDL_CreateYUVOverlay(is->video_st->codec->width,
				 is->video_st->codec->height,
				 SDL_YV12_OVERLAY,
				 screen);
#endif
  vp->width = is->video_st->codec->width;
  vp->height = is->video_st->codec->height;
  
  SDL_LockMutex(is->pictq_mutex);
  vp->allocated = 1;
  SDL_CondSignal(is->pictq_cond);
  SDL_UnlockMutex(is->pictq_mutex);

}

static int queue_picture(VideoState *is, AVFrame *pFrame, double pts) {

  VideoPicture *vp;
  int dst_pix_fmt;
  //AVPicture pict;
  static struct SwsContext *img_convert_ctx;

  /* wait until we have space for a new pic */
  SDL_LockMutex(is->pictq_mutex);
  while(is->pictq_size >= VIDEO_PICTURE_QUEUE_SIZE &&
	!is->quit) {
    SDL_CondWaitTimeout(is->pictq_cond, is->pictq_mutex, 50);
  }
  SDL_UnlockMutex(is->pictq_mutex);

  if(is->quit)
    return -1;

  // windex is set to 0 initially
  vp = &is->pictq[is->pictq_windex];

  /* allocate or resize the buffer! */
  if(!vp->bmp ||
     vp->width != is->video_st->codec->width ||
     vp->height != is->video_st->codec->height) {
    //SDL_Event event;

    vp->allocated = 0;
    /* we have to do it in the main thread */

	 
	  Msg_t event;
	  event.type = FF_ALLOC_EVENT;
	  event.data1 = is;
	  MSGQ_Post(is->pMSGQ, &event);

    /* wait until we have a picture allocated */
    SDL_LockMutex(is->pictq_mutex);
    while(!vp->allocated && !is->quit) {
      SDL_CondWaitTimeout(is->pictq_cond, is->pictq_mutex, 50);
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

	av_picture_copy(&vp->pic, (const AVPicture *)pFrame, PIX_FMT_YUV420P, is->video_st->codec->width, is->video_st->codec->height);

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
			fprintf(stderr, "Cannot initialize the conversion context!\n");
			return -1;
		}
	}
	pic.data[0] = rgb;
	pic.linesize[0] = w*4;

	
	sws_scale(img_convert_ctx, srcSlice, srcStride,
			  0, h, pic.data, pic.linesize);
	return 0;
}
*/

static double synchronize_video(VideoState *is, AVFrame *src_frame, double pts) {

  double frame_delay;

  if(pts != 0) {
    /* if we have pts, set video clock to it */
    is->video_clock = pts;
  } else {
    /* if we aren't given a pts, set it to the clock */
    pts = is->video_clock;
  }
  /* update the video clock */
  frame_delay = av_q2d(is->video_st->codec->time_base);
  /* if we are repeating a frame, adjust clock accordingly */
  frame_delay += src_frame->repeat_pict * (frame_delay * 0.5);
  is->video_clock += frame_delay;
  return pts;
}

static uint64_t global_video_pkt_pts = AV_NOPTS_VALUE;

/* These are called whenever we allocate a frame
 * buffer. We use this to store the global_pts in
 * a frame at the time it is allocated.
 */
static int our_get_buffer(struct AVCodecContext *c, AVFrame *pic) {
  int ret = avcodec_default_get_buffer(c, pic);
  uint64_t *pts = (uint64_t*)av_malloc(sizeof(uint64_t));
  *pts = global_video_pkt_pts;
  pic->opaque = pts;
  return ret;
}
static void our_release_buffer(struct AVCodecContext *c, AVFrame *pic) {
  if(pic) av_freep(&pic->opaque);
  avcodec_default_release_buffer(c, pic);
}

int SDLCALL video_thread(void *arg) {
  VideoState *is = (VideoState *)arg;
  AVPacket pkt1, *packet = &pkt1;
  int len1, frameFinished;
  AVFrame *pFrame;
  double pts;

  pFrame = avcodec_alloc_frame();

  for(;;) {
    if(packet_queue_get(&is->videoq, packet, 1) < 0) {
      // means we quit getting packets
      break;
    }
    if(packet->data == flush_pkt.data) {
      avcodec_flush_buffers(is->video_st->codec);
      continue;
    }
    pts = 0;

    // Save global pts to be stored in pFrame
    global_video_pkt_pts = packet->pts;
    // Decode video frame
    //len1 = avcodec_decode_video(is->video_st->codec, pFrame, &frameFinished, packet->data, packet->size);
	  frameFinished = 0;
	  len1 = avcodec_decode_video2(is->video_st->codec, pFrame, &frameFinished, packet);
	  //printf("-keyframe: %d, pict_type:%d-",pFrame->key_frame, pFrame->pict_type);
	  
    if(packet->dts == AV_NOPTS_VALUE 
       && pFrame->opaque && *(uint64_t*)pFrame->opaque != AV_NOPTS_VALUE) {
      pts = *(uint64_t *)pFrame->opaque;
    } else if(packet->dts != AV_NOPTS_VALUE) {
      pts = packet->dts;
    } else {
      pts = 0;
    }
    pts *= av_q2d(is->video_st->time_base);


    // Did we get a video frame?
    if(frameFinished) {
      pts = synchronize_video(is, pFrame, pts);
		//printf("-queue_pic-");
      if(queue_picture(is, pFrame, pts) < 0) {
		  break;
      }
    }
    av_free_packet(packet);
  }
  av_free(pFrame);
  return 0;
}

int stream_component_open(VideoState *is, int stream_index) {

  AVFormatContext *pFormatCtx = is->pFormatCtx;
  AVCodecContext *codecCtx;
  AVCodec *codec;
  SDL_AudioSpec wanted_spec, spec;

  if(stream_index < 0 || stream_index >= pFormatCtx->nb_streams) {
    return -1;
  }

  // Get a pointer to the codec context for the video stream
  codecCtx = pFormatCtx->streams[stream_index]->codec;

  if(codecCtx->codec_type == CODEC_TYPE_AUDIO) {
    // Set audio settings from codec info
    wanted_spec.freq = codecCtx->sample_rate;
    wanted_spec.format = AUDIO_S16SYS;
    wanted_spec.channels = codecCtx->channels;
    wanted_spec.silence = 0;
    wanted_spec.samples = SDL_AUDIO_BUFFER_SIZE;
    wanted_spec.callback = audio_callback;
    wanted_spec.userdata = is;
    
    if(SDL_OpenAudio(&wanted_spec, &spec) < 0) {
      fprintf(stderr, "SDL_OpenAudio: %s\n", SDL_GetError());
      return -1;
    }
    is->audio_hw_buf_size = spec.size;
  }


  codec = avcodec_find_decoder(codecCtx->codec_id);
  if(!codec || (avcodec_open(codecCtx, codec) < 0)) {
    fprintf(stderr, "Unsupported codec!\n");
    return -1;
  }

  switch(codecCtx->codec_type) {
  case CODEC_TYPE_AUDIO:
    is->audioStream = stream_index;
    is->audio_st = pFormatCtx->streams[stream_index];
    is->audio_buf_size = 0;
    is->audio_buf_index = 0;
    
    /* averaging filter for audio sync */
    is->audio_diff_avg_coef = exp(log(0.01 / AUDIO_DIFF_AVG_NB));
    is->audio_diff_avg_count = 0;
    /* Correct audio only if larger error than this */
    is->audio_diff_threshold = 2.0 * SDL_AUDIO_BUFFER_SIZE / codecCtx->sample_rate;

    memset(&is->audio_pkt, 0, sizeof(is->audio_pkt));
    packet_queue_init(&is->audioq);
    SDL_PauseAudio(1);
    break;
  case CODEC_TYPE_VIDEO:
    is->videoStream = stream_index;
    is->video_st = pFormatCtx->streams[stream_index];

    is->frame_timer = (double)av_gettime() / 1000000.0;
    is->frame_last_delay = 40e-3;
    is->video_current_pts_time = av_gettime();

    packet_queue_init(&is->videoq);
    is->video_tid = SDL_CreateThread(video_thread, is);
    codecCtx->get_buffer = our_get_buffer;
    codecCtx->release_buffer = our_release_buffer;

    break;
  default:
    break;
  }

	return 0;
}

static int decode_interrupt_cb(void) {
  return (global_video_state && global_video_state->quit);
}



static int SDLCALL decode_thread(void *arg) {

  VideoState *is = (VideoState *)arg;

  AVPacket pkt1, *packet = &pkt1;


  // main decode loop

  for(;;) {
    if(is->quit) {
      break;
    }
    // seek stuff goes here
    if(is->seek_req) 
	{
      int stream_index= -1;
      int64_t seek_target = is->seek_pos;

      if     (is->videoStream >= 0) stream_index = is->videoStream;
      else if(is->audioStream >= 0) stream_index = is->audioStream;

      if(stream_index>=0){
		  const AVRational avr=AV_TIME_BASE_Q;
		  seek_target= av_rescale_q(seek_target, avr, is->pFormatCtx->streams[stream_index]->time_base);
      }
      if(av_seek_frame(is->pFormatCtx, stream_index, seek_target, is->seek_flags) < 0) 
	  {
		  /*
		if (is->pFormatCtx->iformat->read_seek) {
		  printf("format specific\n");
		} else if(is->pFormatCtx->iformat->read_timestamp) {
		  printf("frame_binary\n");
		} else {
		  printf("generic\n");
		}*/

		fprintf(stderr, "error while seeking. target: %d, stream_index: %d\n", seek_target, stream_index);
      } 
	  else 
	  {
		if(is->audioStream >= 0) {
		  packet_queue_flush(&is->audioq);
		  packet_queue_put(&is->audioq, &flush_pkt);
		}
		if(is->videoStream >= 0) {
		  packet_queue_flush(&is->videoq);
		  packet_queue_put(&is->videoq, &flush_pkt);
		}
		  
		if (is->paused)  //xinghua 20100901
			is->frame_step = 8;
      }
      is->seek_req = 0;
    }
	  
    //if(is->audioq.size > MAX_AUDIOQ_SIZE || is->videoq.size > MAX_VIDEOQ_SIZE) 
	if (is->videoq.nb_packets > 24)//xinghua 20100831, we only care video packets queue here. (8 freames /second)
	{
      SDL_Delay(10);
      continue;
    }
	  
	if (is->readframe_end)
	{
		  SDL_Delay(100); /* no error; wait for user input */
		  continue;
	}
	  
	  //xinghua 20100831
    if(av_read_frame(is->pFormatCtx, packet) < 0) 
	{
		is->readframe_end = 1;
		continue;
#if 0		
      if(url_ferror(&pFormatCtx->pb) == 0) {
		SDL_Delay(100); /* no error; wait for user input */
		continue;
      } else {
		break;
      }
#endif
    }

    // Is this a packet from the video stream?
    if(packet->stream_index == is->videoStream) {
      packet_queue_put(&is->videoq, packet);
    } else if(packet->stream_index == is->audioStream) {
      packet_queue_put(&is->audioq, packet);
    } else {
      av_free_packet(packet);
    }
  }
  /* all done - wait for it */
	/*
  while(!is->quit) {
    SDL_Delay(100);
  }
	 */

	
  return 0;
}


static int main_loop(void *arg) 
{
	VideoState      *is = (VideoState *)arg;
	Msg_t	event;
	

	is->timer_refresh = SDL_AddTimer(TIMER_REFRESH_PERIOD, sdl_refresh_timer_cb, is);
	
	for(;;) {

		MSGQ_Wait(is->pMSGQ, &event);
		switch(event.type) 
		{
			case FF_QUIT_EVENT:
				is->quit = 1;
				if (event.code == PF_USERTERMINATE)
					goto exit2;
				else
					is->evt_callback(is->caller, PE_EVENT_PLAYFILE, event.code);
				break;
				
			case FF_ALLOC_EVENT:

				alloc_picture(event.data1);
				break;
				
			case FF_REFRESH_EVENT:
				if (is->quit == 0)
				{
					if (is->schedule_delay <= TIMER_REFRESH_PERIOD)
					{
						video_refresh_timer(event.data1);
					}
					else
						is->schedule_delay -= TIMER_REFRESH_PERIOD;
					
				}
				break;
				
			default:

				break;
		}
	}
	
exit2:
	
	SDL_RemoveTimer(is->timer_refresh);
	return 0;
}


PF_HANDLE PF_Open(const char *filename, PE_EVT_CALLBACK evt_cb, void *caller)
{

	VideoState      *is;
	int i;
    AVFormatContext *pFormatCtx;	
	int video_index = -1;
	int audio_index = -1;
	
	if (global_video_state)//some file is playing
		return 0;
	

	
	/*{
	FILE *fp = fopen(filename, "rb");
	if (fp == NULL)
	{
		printf("file not exists");
		return 0;
	}
	fclose(fp);
	}*/

	is = (VideoState *)av_mallocz(sizeof(VideoState));
	global_video_state = is;
	
	is->evt_callback = evt_cb;
	is->caller = caller;
	
	// Register all formats and codecs
	av_register_all();


	if(SDL_Init(/*SDL_INIT_VIDEO |*/ SDL_INIT_AUDIO | SDL_INIT_TIMER)) {
	//fprintf(stderr, "Could not initialize SDL - %s\n", SDL_GetError());
		return 0;
	}

	//strcpy(is->filename,filename);
	av_init_packet(&flush_pkt);
	flush_pkt.data = (uint8_t*)"FLUSH";

	is->paused = 1;
	is->av_sync_type = DEFAULT_AV_SYNC_TYPE;	
	
	//try to open file now
	is->videoStream=-1;
	is->audioStream=-1;
	
	// will interrupt blocking functions if we quit!
	url_set_interrupt_cb(decode_interrupt_cb);
	
	i = av_open_input_file(&pFormatCtx, filename,NULL, 0, NULL);
	
	if(i !=0)
		return 0; // Couldn't open file
	
	is->pFormatCtx = pFormatCtx;
	
	// Retrieve stream information
	if(av_find_stream_info(pFormatCtx)<0)
		;//return -1; // Couldn't find stream information
	
	// Dump information about file onto standard error
	//dump_format(pFormatCtx, 0, filename, 0);
	
	// Find the first video stream
	
	for(i=0; i<pFormatCtx->nb_streams; i++) {
		if(pFormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_VIDEO &&
		   video_index < 0) {
			video_index=i;
		}
		if(pFormatCtx->streams[i]->codec->codec_type==CODEC_TYPE_AUDIO &&
		   audio_index < 0) {
			audio_index=i;
		}
	}
	if(audio_index >= 0) {
		stream_component_open(is, audio_index);
	}
	if(video_index >= 0) {
		stream_component_open(is, video_index);
	}   
	
	if(is->videoStream < 0 && is->audioStream < 0) {
		fprintf(stderr, " could not open codecs\n");
		av_close_input_file(pFormatCtx);	
		return 0;
	}
	
	
	//create a msgq here
	is->pMSGQ = MSGQ_Create(sizeof(Msg_t), 64);
	
	
	is->pictq_mutex = SDL_CreateMutex();
	is->pictq_cond = SDL_CreateCond();
	
	schedule_refresh(is, 40);

	
	is->parse_tid = SDL_CreateThread(decode_thread, is);
	is->main_tid = SDL_CreateThread(main_loop, is);

	return is;
}

//user terminate file

void PF_Close(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;
	Msg_t event;
	if (global_video_state == NULL)
		return;
	
	event.type = FF_QUIT_EVENT;
	event.code = PF_USERTERMINATE;
	event.data1 = global_video_state;
	MSGQ_Post(global_video_state->pMSGQ, &event);
	

	
	if (is->parse_tid)
	{
		SDL_WaitThread(is->parse_tid, NULL);
	}
	
	if (is->main_tid)
	{
		SDL_WaitThread(is->main_tid, NULL);
	}
	
	av_close_input_file(is->pFormatCtx);	
	
	SDL_CloseAudio();
	
	if (is->video_tid)
	{
		SDL_WaitThread(is->video_tid, NULL);
		is->video_tid = NULL;
	}
	
	if(is->audioStream >= 0) {
		packet_queue_flush(&is->audioq);
		packet_queue_cleanup(&is->audioq);
	}
	if(is->videoStream >= 0) {
		packet_queue_flush(&is->videoq);
		packet_queue_cleanup(&is->videoq);
	}	
	
	MSGQ_Destroy(is->pMSGQ);
	SDL_DestroyMutex(is->pictq_mutex);
	SDL_DestroyCond(is->pictq_cond);
	
	av_free(is);
	SDL_Quit();
	global_video_state = NULL;
	
}

void PF_Play(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;	
	SDL_PauseAudio(0);
	is->paused = 0;
}

void PF_Pause(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;	
	SDL_PauseAudio(1);
	is->paused = 1;
}


//incr in seconds
void PF_Seek(PF_HANDLE h, int incr) 
{
	VideoState *is = (VideoState *)h;
	double pos;	

	pos = get_master_clock(is);
	pos += incr;
	
	if(!is->seek_req) {
		is->seek_pos = (int64_t)(pos * AV_TIME_BASE);
		is->seek_flags = incr < 0 ? AVSEEK_FLAG_BACKWARD : 0;
		is->seek_req = 1;
	}
}

void PF_Seek2(PF_HANDLE h, int pos) 
{
	VideoState *is = (VideoState *)h;
	int curpos;
	curpos = (int)get_master_clock(is);
	
	if(!is->seek_req) {
		is->seek_pos = (int64_t)(pos * AV_TIME_BASE);
		is->seek_flags = curpos < pos ? AVSEEK_FLAG_BACKWARD : 0;
		is->seek_req = 1;
	}
}

int PF_GetSeekStatus(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;
	return is->seek_req; 
}

//duration in seconds
int PF_GetDuration(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;
	return (int)(is->pFormatCtx->duration / AV_TIME_BASE) ;
}

int PF_GetPosition(PF_HANDLE h)
{
	VideoState *is = (VideoState *)h;
	
	return (int)get_master_clock(is);
	
}
