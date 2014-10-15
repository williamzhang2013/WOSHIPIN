#ifndef _PECTRL_H
#define _PECTRL_H


#ifdef __cplusplus
extern "C"{
#endif


#define PE_CALL	
#define PE_API
/*
#ifdef PE_EXPORTS
#define PE_API __declspec(dllexport)
#else
#define PE_API __declspec(dllimport)
#endif
#endif
*/

struct PE_CTRL_S;
typedef struct PE_CTRL_S PE_CTRL_T;

enum{
	PE_EVENT_START	= 200,
	PE_EVENT_BUFFERING,
	PE_EVENT_PLAYING,
	PE_EVENT_RTSPOPEN_COMPLETE,//success or fail
	PE_EVENT_RTSPCONN_LOST,
	PE_EVENT_VIDEOYUVOUT,	//VIDEOYUV_T* passed as param
	PE_EVENT_PLAYFILE,		//only for pe_file module
	
	PE_EVENT_MAX	= 299,
};

enum  {
	PF_ENDOFFILE,
	PF_USERTERMINATE,
};
	
//the same as AVPicture	define
typedef struct {
	unsigned char **data;
	int *linesize;
	int width;
	int height;
}VIDEOYUV_T;
	
typedef void (PE_CALL * PE_EVT_CALLBACK)(void *caller, int evt, int param);

PE_API PE_CTRL_T * PE_CALL PE_Create(PE_EVT_CALLBACK evt_cb, void *caller);
PE_API void PE_CALL PE_Destroy(PE_CTRL_T *ctrl);
PE_API int PE_CALL PE_Start(PE_CTRL_T *ctrl, char *url);
PE_API void PE_CALL PE_Stop(PE_CTRL_T *ctrl);
    
    // size type:
    // 1  GPRS/EDGE (2G，对于中国电信则是 CMDA 1X网络) QCIF（176＊144）
    // 2  WCDMA (3G, 对于中国电信则是EVDO网络)  QVGA （320＊240）
void PE_StartRecord(PE_CTRL_T *ctrl, char *filename, int sizeType);
void PE_StopRecord(PE_CTRL_T *ctrl);
void PE_RequestSnapshot(PE_CTRL_T *ctrl, char *filename);
int PE_CheckSnapshot(PE_CTRL_T *ctrl);
void PE_UndoSnapshotRequest(PE_CTRL_T *ctrl);

//for Windows PC
PE_API void PE_CALL PE_SetVideoWindow(PE_CTRL_T *ctrl, void * videownd);
PE_API void PE_CALL PE_UpdateVideoWindow(PE_CTRL_T *ctrl);

//for PF (PE_File)
typedef  void*  PF_HANDLE;
	
PE_API PF_HANDLE PE_CALL PF_Open(const char *filename,PE_EVT_CALLBACK evt_cb, void *caller);	
PE_API void PE_CALL PF_Play(PF_HANDLE h);
PE_API void PE_CALL PF_Pause(PF_HANDLE h);
PE_API void PE_CALL PF_Close(PF_HANDLE h);
PE_API	int PE_CALL PF_GetDuration(PF_HANDLE h);
PE_API	int PE_CALL PF_GetPosition(PF_HANDLE h);
PE_API	void PE_CALL PF_Seek(PF_HANDLE h, int incr);
PE_API	void PE_CALL PF_Seek2(PF_HANDLE h, int pos) ;
	PE_API	int PE_CALL PF_GetSeekStatus(PF_HANDLE h);
	
#ifdef __cplusplus
}
#endif

#endif