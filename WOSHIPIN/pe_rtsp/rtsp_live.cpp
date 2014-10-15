
//#include "windows.h"


#include "rtsp_live.h"
#include "GroupsockHelper.hh"
#include "dumpsink.h"

#define QTFILESINK		0

#define rtspClient ctx->rtspClient
#define mediaSession ctx->mediaSession

static	UsageEnvironment* env = NULL;

static void subsessionAfterPlaying(void* clientData) 
{

  // Begin by closing this media subsession's stream:
  MediaSubsession* subsession = (MediaSubsession*)clientData;
  RTSP_Context *ctx = ((DumpSink *)subsession->sink)->getRTSPContext();
  Medium::close(subsession->sink);
  subsession->sink = NULL;

  // Next, check whether *all* subsessions' streams have now been closed:
  MediaSession& session = subsession->parentSession();
  MediaSubsessionIterator iter(session);
  while ((subsession = iter.next()) != NULL) {
    if (subsession->sink != NULL) return; // this subsession is still active
  }

  // All subsessions' streams have now been closed
  //shutdown();
  ctx->watchVariable = 1;
  if (ctx->pcallback)
  {
	 ctx->pcallback(ctx->caller, RTSP_EVT_SOURCECLOSURE, 0);
  }
}

void sessionAfterPlaying(void* /*clientData*/) {

}
static void subsessionByeHandler(void* clientData) {
  //struct timeval timeNow;
  //gettimeofday(&timeNow, NULL);
  //unsigned secsDiff = timeNow.tv_sec - startTime.tv_sec;

	MediaSubsession* subsession = (MediaSubsession*)clientData;
	printf("Received RTCP \"BYE\" ");

	// Act now as if the subsession had closed:
	subsessionAfterPlaying(subsession);
}


static void shutdown(RTSP_Context *ctx)
{
	MediaSession * session = mediaSession;
#if QTFILESINK
	Medium::close(ctx->qtOut);
	ctx->qtOut = NULL;
#else
	RTSPClient_StopRecord(ctx);
#endif
	//closeMediaSinks
	if (session == NULL) return;
	MediaSubsessionIterator iter(*session);
	MediaSubsession* subsession;
	while ((subsession = iter.next()) != NULL) {
		Medium::close(subsession->sink);
		subsession->sink = NULL;
	}


	// Teardown, then shutdown, any outstanding RTP/RTCP subsessions
	rtspClient->teardownMediaSession(*session);
	Medium::close(session);

    // Finally, shut down our client:
    Medium::close(rtspClient);

	rtspClient = NULL;
	mediaSession = NULL;

}

RTSP_Context * RTSPClient_Init(void *caller, ON_RTSP_CALLBACK cb)
{
	RTSP_Context *ctx;
	ctx = (RTSP_Context *)malloc(sizeof(RTSP_Context));

	memset(ctx, 0, sizeof(RTSP_Context));
	ctx->caller = caller;
	ctx->pcallback =cb;
	ctx->watchVariable = 1;
	ctx->lock = SDL_CreateMutex();
	// setting up our usage environment:
	if (!env )
	{
		TaskScheduler* scheduler = BasicTaskScheduler::createNew();
		env = BasicUsageEnvironment::createNew(*scheduler);
	}
	return ctx;
}

void RTSPClient_Deinit(RTSP_Context *ctx)
{
//	delete env; destructor is protected

	SDL_DestroyMutex(ctx->lock);
	free(ctx);
}


//Initial Command/Resposne, to establish a session
int RTSPClient_Open(RTSP_Context *ctx, const char *url/*, char *username, char *password*/)
{
	int ret = -1;

	do 
	{

		//Create RTSP Client
		rtspClient = RTSPClient::createNew(*env, /*verbose*/1, "iphone_player");
		if (rtspClient == NULL) {
		  //fprintf(stderr, "Failed to create RTSP client: %s\n", env->getResultMsg());
		  break;
		}

		// send an "OPTIONS" command first. is this step Optional??
		char *optionsResponse = NULL;
		optionsResponse = rtspClient->sendOptionsCmd(url/*, username, password*/);
		if (optionsResponse)
			delete[] optionsResponse;
		else
			break;

		// send "DESCRIBE" command; Open the URL, to get a SDP description:
		char *sdpDescription = NULL; 
		//if (username != NULL && password != NULL) {
		//	sdpDescription = rtspClient->describeWithPassword(url, username, password);
		//} else {
			sdpDescription = rtspClient->describeURL(url);
		//}

		if (sdpDescription == NULL) {
			//fprintf(stderr, "Failed to get a SDP description : %s\n",env->getResultMsg());
			break;
		}

		// Now that we have a SDP description, create a MediaSession from it:
		mediaSession = MediaSession::createNew(*env, sdpDescription);
		delete[] sdpDescription;//

		if (mediaSession == NULL) break;

#if QTFILESINK
		ctx->qtOut  = QuickTimeFileSink2::createNew(*env, *mediaSession, "D:\\netcamdump.mov",
		   20000,
		   320, 240,
		   8,
		   False,
		   False,
		   False,
		   1);
		ctx->qtOut->startPlaying(sessionAfterPlaying, NULL);
		ret = 0;
		break;
#endif

		// Create RTP receivers (sources) for each subsession:
		Boolean madeProgress = False;
		MediaSubsessionIterator iter(*mediaSession);
		MediaSubsession* subsession;
		while ((subsession = iter.next()) != NULL) 
		{
		  // We only care H264 Video 
			if (strcmp(subsession->mediumName(), "video") == 0 && 
				strcmp(subsession->codecName(), "H264") == 0 ) 
			{
				//go forward
			} 
			else 
				continue;

			 // Creates a "RTPSource" for this subsession. 
			if (!subsession->initiate()) {
				//fprintf(stderr, "Failed to initiate RTP subsession: %s\n",  env->getResultMsg());
			} 
			else {
				//fprintf(stderr, "Initiated RTP subsession on port %d\n", subsession->clientPortNum());

				if (subsession->rtpSource() != NULL && subsession->rtcpInstance()!= NULL) 
				{
					//??????????????
					unsigned const thresh = 1000000; // 1 second
					subsession->rtpSource()->setPacketReorderingThresholdTime(thresh);

					 //Set the RTP source's OS socket buffer size as appropriate
					int rtpSocketNum = subsession->rtpSource()->RTPgs()->socketNum();
					setReceiveBufferTo(*env, rtpSocketNum, 128*1024);

					// Issue a RTSP "SETUP" command on the chosen subsession:
					if (!rtspClient->setupMediaSubsession(*subsession, False,False)) break;

					//IMPORTANT: coreplayer do this, and we just follow....
					Groupsock* fgs;
					unsigned char buf[128] = {0};
					buf[0] = 128;
					fgs = subsession->rtpSource()->RTPgs();
					fgs->output(*env,fgs->ttl(),buf,128);

					fgs = subsession->rtcpInstance()->RTCPgs();
					fgs->output(*env,fgs->ttl(),buf,128); 

				
					ctx->fmtp_spropparametersets = (char*)subsession->fmtp_spropparametersets();	//xinghua 20101129

					//create the sink (H.264 dump out)
					DumpSink *dumpsink = DumpSink::createNew(*(env), ctx,/*subsession,*/ PAYLOAD_H264);   
					if (dumpsink == NULL)
					{
						//fprintf(stderr, "Failed to create dumpsink : %s\n",env->getResultMsg());
						continue;
					}
					subsession->sink = dumpsink;
					subsession->sink->startPlaying(*(subsession->readSource()),
					subsessionAfterPlaying, subsession);

					// Also set a handler to be called if a RTCP "BYE" arrives
					// for this subsession:
					subsession->rtcpInstance()->setByeHandler(subsessionByeHandler,
										  subsession);




					madeProgress = True;
				}

			}
		}//endof while ((subsession = iter.next()) != NULL)
		if (! madeProgress ) break; 

		// Issue a RTSP aggregate "PLAY" command on the whole session:
    	if (!rtspClient->playMediaSession(*mediaSession)) 
		{
			//fprintf(stderr,  "Failed to start playing session: %s\n",env->getResultMsg());		
			break;
		}
		ret = 0;

	}while(0);//endof do-while

	if (ret < 0)
		shutdown(ctx);
	return ret; 
}

//Run the session
void RTSPClient_RunningProc(RTSP_Context *ctx)
{
	ctx->watchVariable = 0; 
	env->taskScheduler().doEventLoop(&(ctx->watchVariable)); // blocking function...

	shutdown(ctx);
}

void RTSPClient_Terminate(RTSP_Context *ctx)
{
	ctx->watchVariable = 1;
}


void RTSPClient_StartRecord(RTSP_Context *ctx, char *filename, int width, int height)
{
	if (ctx->record_flag == 0 && mediaSession != NULL)
	{
		
		ctx->qtOut = QuickTimeFileSink2::createNew(*env, *(mediaSession), filename,
					   20000,
					   width, height,
					   8,
					0,//NOTE: xinghua 20101102, must set to 0
					0,// must set to 0
					0,//better to set 0
					1);//generate MP4 format		
		ctx->record_flag = 1; //request
	}
}

void RTSPClient_StopRecord(RTSP_Context *ctx)
{
	SDL_mutexP(ctx->lock);
	if (ctx->record_flag)
	{	
		Medium::close(ctx->qtOut);
		ctx->qtOut = NULL;
		ctx->record_flag = 0;
	}
	SDL_mutexV(ctx->lock);
}
