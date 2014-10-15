#include "DumpSink.h"
#include "GroupsockHelper.hh"

DumpSink::DumpSink(UsageEnvironment& env, RTSP_Context *ctx, int pltype, unsigned bufferSize)
  : MediaSink(env), fpRTSPContext(ctx), fPayloadType(pltype), fBufferSize(bufferSize) 
{
	fHeaderLen = 0;
    fBuffer = new unsigned char[bufferSize];
#if 0
	if (fPayloadType == PAYLOAD_H264 && ss->fmtp_spropparametersets() != NULL)
	{
		unsigned nrec =0;
		SPropRecord *sproprec = parseSPropParameterSets(ss->fmtp_spropparametersets(),nrec);

		int pos = 0;
		for (int i = 0; i < nrec; i++)
		{
			fBuffer[pos+0] = 0x00;
			fBuffer[pos+1] = 0x00;
			fBuffer[pos+2] = 0x00;
			fBuffer[pos+3] = 0x01;
			pos += 4;
			memcpy(&fBuffer[pos], sproprec[i].sPropBytes, sproprec[i].sPropLength);
			pos += sproprec[i].sPropLength;
		}
			fBuffer[pos+0] = 0x00;
			fBuffer[pos+1] = 0x00;
			fBuffer[pos+2] = 0x00;
			fBuffer[pos+3] = 0x01;
			pos += 4;

		fHeaderLen = pos + 4;
		delete []sproprec;
	}
#else
	if (fPayloadType == PAYLOAD_H264)
	{
			fBuffer[0] = 0x00;
			fBuffer[1] = 0x00;
			fBuffer[2] = 0x00;
			fBuffer[3] = 0x01;
			fHeaderLen = 4;
	}
#endif
}

DumpSink::~DumpSink() 
{
  delete[] fBuffer;
}

DumpSink* DumpSink::createNew(UsageEnvironment& env, RTSP_Context *ctx, int pltype,unsigned bufferSize) 
{
    return new DumpSink(env, ctx, pltype, bufferSize);
}

Boolean DumpSink::continuePlaying() 
{
  if (fSource == NULL) return False;

  fSource->getNextFrame(fBuffer+fHeaderLen, fBufferSize-fHeaderLen,
			afterGettingFrame, this,
			onSourceClosure, this);

  return True;
}

void DumpSink::afterGettingFrame(void* clientData, unsigned frameSize,
				 unsigned /*numTruncatedBytes*/,
				 struct timeval presentationTime,
				 unsigned /*durationInMicroseconds*/) 
{
  DumpSink* sink = (DumpSink*)clientData;
  sink->afterGettingFrame1(frameSize, presentationTime);
}

void DumpSink::afterGettingFrame1(unsigned frameSize,
				  struct timeval presentationTime) 
{
	if (fpRTSPContext->pcallback)
	{
		RTP_PLAYLOAD_PACKET pkt;
		pkt.media_type = fPayloadType;
		pkt.buf = fBuffer;
		pkt.len = frameSize + fHeaderLen;
		pkt.timestamp =  presentationTime;

		fpRTSPContext->pcallback(fpRTSPContext->caller, RTSP_EVT_RTPPAYLOADDUMP,(void*) &pkt);


		SDL_mutexP(fpRTSPContext->lock);
		if (fpRTSPContext->record_flag)
		{
			//xinghua NOTES:
			//Apple QuickTime Player does not like 00 00 00 01 NAL unit header;
			//While VLC does not care the header
			pkt.buf = fBuffer + fHeaderLen;
			pkt.len = frameSize;
			fpRTSPContext->qtOut->WritePacket((void *)&pkt);
		}
		SDL_mutexV(fpRTSPContext->lock);



	}

	// Then try getting the next frame:
	continuePlaying();
}

