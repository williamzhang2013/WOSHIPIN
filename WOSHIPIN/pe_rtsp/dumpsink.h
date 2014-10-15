
#ifndef _DUMP_SINK_HH
#define _DUMP_SINK_HH

#ifndef _MEDIA_SINK_HH
#include "MediaSink.hh"
#endif

#include "rtsp_live.h"

class DumpSink: public MediaSink {
public:
  static DumpSink* createNew(UsageEnvironment& env, RTSP_Context *ctx, int pltype, unsigned bufferSize = 20000);
  // "bufferSize" should be at least as large as the largest expected
  //   input frame.

  RTSP_Context *getRTSPContext() {return fpRTSPContext;}
protected:
  DumpSink(UsageEnvironment& env, RTSP_Context *ctx, int pltype, unsigned bufferSize);
      // called only by createNew()
  virtual ~DumpSink();

protected:
  static void afterGettingFrame(void* clientData, unsigned frameSize,
				unsigned numTruncatedBytes,
				struct timeval presentationTime,
				unsigned durationInMicroseconds);
  virtual void afterGettingFrame1(unsigned frameSize,
				  struct timeval presentationTime);

  unsigned char* fBuffer;
  unsigned fBufferSize;
  int fPayloadType;//for future use, when more payload type supported
  int fHeaderLen;
  RTSP_Context *fpRTSPContext; 

private: // redefined virtual functions:
  virtual Boolean continuePlaying();
};


#endif
