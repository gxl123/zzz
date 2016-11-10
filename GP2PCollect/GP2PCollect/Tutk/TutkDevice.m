//
//  TutkDevice.m
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "TutkDevice.h"
#import "IOTCAPIs.h"
#import "AVAPIs.h"
#import "AVIOCTRLDEFs.h"
#import "AVFRAMEINFO.h"
#define NOTDONE             0
#define DONE                1
#define VIDEO_BUF_SIZE	500*1024
BOOL g_bTUTKSDKInited = NO;
@implementation TutkDevice{
    int _SID;
    int _avChannelID;
    BOOL _bRecvAVDataRunning;
    NSThread* _threadRecvAVData;
    NSConditionLock* _lockRecvAVData;
}
/*初始化p2psdk*/
+ (void)initSDK{
    if(!g_bTUTKSDKInited){
        g_bTUTKSDKInited=!g_bTUTKSDKInited;
        int ret, nVer2 = 0;
        unsigned long nVer1 = 0;
        ret = IOTC_Initialize2(0);
        IOTC_Get_Version(&nVer1);
        nVer2 = avGetAVApiVer();
        NSLog(@"IOTC_Initialize() ret = %d IOTCversion= 0x%08lX, AVAPIversion=0x%08X",ret, nVer1, nVer2);
        ret = avInitialize(128);
    }
}
+ (void)deinitSDK{
    avDeInitialize();
    IOTC_DeInitialize();
}
- (id)init
{
    if ((self = [super init]))
    {
        _SID=-1;
        [TutkDevice initSDK];
    }
    
    return self;
}

/* 连线 */
- (NSInteger)startConnect{
    _SID=IOTC_Connect_ByUID([_udid UTF8String]);
    NSLog(@"IOTC_Connect_ByUID SID=%d",_SID);
    return _SID;
}
- (void)stopConnect{
    IOTC_Session_Close(_SID);
    IOTC_Connect_Stop();

}
/*　预览　*/
- (NSInteger)startLive{
    //建立Channel
    unsigned long srvType;
    const char *pwd=[_password UTF8String];
    int rets;
    _avChannelID = avClientStart2(_SID, "admin", pwd, 20, &srvType, 0, &rets);
    NSLog(@"avClientStart2 _avChannelID=%d",_avChannelID);
    //发送视频请求
    SMsgAVIoctrlAVStream ioMsg;
    memset(&ioMsg, 0, sizeof(SMsgAVIoctrlAVStream));
    int ret = avSendIOCtrl(_avChannelID, IOTYPE_USER_IPCAM_START, (char*)&ioMsg, sizeof(SMsgAVIoctrlAVStream));
    
    //建立收视频线程
    //create receiving data thread
    if(_threadRecvAVData==nil){
        _bRecvAVDataRunning=YES;
        _lockRecvAVData=[[NSConditionLock alloc] initWithCondition:NOTDONE];
        _threadRecvAVData=[[NSThread alloc] initWithTarget:self selector:@selector(ThreadRecvAVData) object:nil];
        _threadRecvAVData.name=@"ThreadRecvAVData";
        [_threadRecvAVData start];
    }
    return ret;
}
- (NSInteger)stopLive{
    //发送停止视频请求
    SMsgAVIoctrlAVStream ioMsg;
    memset(&ioMsg, 0, sizeof(SMsgAVIoctrlAVStream));
    int ret = avSendIOCtrl(_avChannelID, IOTYPE_USER_IPCAM_STOP, (char*)&ioMsg, sizeof(SMsgAVIoctrlAVStream));
    
    //断开Channel
    avClientStop(_avChannelID);
    
    //结束收视频线程
    _bRecvAVDataRunning=NO;
    if(_threadRecvAVData!=nil){
        [_lockRecvAVData lockWhenCondition:DONE];
        [_lockRecvAVData unlock];
        
        //[mLockRecvAVData release];
        _lockRecvAVData  =nil;
        //[mThreadRecvAVData release];
        _threadRecvAVData=nil;
    }
    return ret;
}
/*　音频监听　*/
- (NSInteger)openAudio{
    return 0;
}
- (NSInteger)closeAudio{
    return 0;
}
/* 通话 */
- (NSInteger)openSpeak{
    return 0;
}
- (NSInteger)closeSpeak{
    return 0;
}
//发音频数据
- (NSInteger)sendAudioData:(NSData*)data time:(int)nTime{
    return 0;
}
- (NSInteger)ThreadRecvAVData
{
    NSLog(@"    ThreadRecvAVData going... udid=%@",self.udid);
    char  *pAVData=(char *)malloc(VIDEO_BUF_SIZE);
    FRAMEINFO_t frameInfo;
    unsigned int frmNo;
    //int nFrmCount = 0, nInCompleteFrmCount = 0;
//    INT32 nRecvSize=4, nRet=0;
//    int  nCurStreamIOType=-1;
//    FRAMEINFO_t_DoorBell *pFrameInfo=NULL;

    _bRecvAVDataRunning=YES;
    while(_bRecvAVDataRunning){
        int pnasize,pnesize,pnfsize;
        int ret = avRecvFrameData2(_avChannelID, pAVData, VIDEO_BUF_SIZE, &pnasize, &pnesize, (char *)&frameInfo, sizeof(FRAMEINFO_t), &pnfsize, &frmNo);
        NSLog(@"avRecvFrameData2 ret=%d",ret);
        if(ret == AV_ER_DATA_NOREADY)
        {
            usleep(4000);
            continue;
        }
        else if(ret == AV_ER_LOSED_THIS_FRAME)
        {
//            nInCompleteFrmCount++;
//            GLog(tOther,(@"Lost video frame NO[%d]", frmNo));
//            _bLostFrame = YES;
            usleep(4000);
            continue;
        }
        else if(ret == AV_ER_INCOMPLETE_FRAME)
        {
//            nInCompleteFrmCount++;
//            GLog(tOther,(@"Incomplete video frame NO[%d]", frmNo));
//            _bLostFrame = YES;
            continue;
        }
        else if(ret == AV_ER_SESSION_CLOSE_BY_REMOTE)
        {
            //[_delegate renderFailed:NSLocalizedStringFromTable(@"MSG_Failed", @"Localization", nil)];
            break;
        }
        else if(ret == AV_ER_REMOTE_TIMEOUT_DISCONNECT)
        {
            //[_delegate renderFailed:NSLocalizedStringFromTable(@"MSG_Failed", @"Localization", nil)];
            break;
        }
        else if(ret == IOTC_ER_INVALID_SID)
        {
            //[_delegate renderFailed:NSLocalizedStringFromTable(@"MSG_Failed", @"Localization", nil)];
            break;
        }
//        if (frameInfo.flags==IPC_FRAME_FLAG_IFRAME||frmNo==(_currentFrameIndex+1)) {
//            nFrmCount++;
//            
//            _isFirstIFrame = YES;
//            _currentFrameIndex = frmNo;
//            _bLostFrame = NO;
//            
//        }else{
//            nInCompleteFrmCount++;
//            _isFirstIFrame = NO;
//            continue;
//        }
//        
//        if (_isFirstIFrame) {
          else  if (ret >= 0) {
//                NSData *data = [[NSData alloc] initWithBytes:pAVData length:ret];
//                
//                MediaFrame *frame = [[MediaFrame alloc] initWithData:data];
//                frame.isVideo = YES;
//                
//                frame.frameIndex = frmNo;
//                if (frameInfo.flags == IPC_FRAME_FLAG_IFRAME) {
//                    frame.keyFrame = YES;
//                }else if (frameInfo.flags == IPC_FRAME_FLAG_PBFRAME){
//                    frame.keyFrame = NO;
//                }
//                frame.width = 100;
//                frame.height = 100;
//                frame.timestamp = frameInfo.timestamp;
//                [_decoder decodeFrame:frame];
//                if (_recorder) {
//                    [_recorder addFrame:frame];
//                }
//                [data release];
            }
//        }else{
//            continue;
//            GLog(tOther,(@"丢东西了？"));
//        }
    }
    [_lockRecvAVData unlockWithCondition:DONE];
    NSLog(@"=== ThreadRecvAVData exit === udid=%@",self.udid);
    return 0;
}
@end
