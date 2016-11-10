//
//  ShangYunDevice.m
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "ShangYunDevice.h"
#import "ShangyunDoorBellCmdDef.h"
#import "ToolCommon.h"
#import "iOSLogEngine.h"
#import "GLog.h"
#import "GLogZone.h"
#import "ShangYunPushMana.h"
#import "MediaFrame.h"
#import "JSONKit.h"
#define CHANNEL_DATA	1
#define CHANNEL_IOCTRL	2


#define MAX_SIZE_IOCTRL_BUF   5120    //5K
#define MAX_SIZE_AV_BUF       262144  //256K
#define MAX_SIZE_AUDIO_PCM    3200
#define MAX_SIZE_AUDIO_SAMPLE 640

#define MAX_AUDIO_BUF_NUM     25
#define MIN_AUDIO_BUF_NUM     1
@implementation ShangYunDevice
@synthesize nRowID, mCamState;
@synthesize m_bRunning, m_bVideoPlaying, m_bAudioDecording,m_bRecvIODataRunning,m_bRecvAVDataRunning;
@synthesize mVideoHeight, mVideoWidth;
//@synthesize m_fifoVideo, m_fifoAudio;
@synthesize mLockConnecting;
@synthesize nsCamName, nsDID;
+ (void)initSDK{
    char Para[]={"EBGAEIBIKHJJGFJKEOGCFAEPHPMAHONDGJFPBKCPAJJMLFKBDBAGCJPBGOLKIKLKAJMJKFDOOFMOBECEJIMM"};
    int ret=PPCS_Initialize(Para);
    GLog(tShangYun, (@"PPCS_Initialize ret=%d",ret));
    int gAPIVer=PPCS_GetAPIVersion();
    GLog(tShangYun, (@"gAPIVer=0x%X", gAPIVer));
}
+ (void)deinitSDK{
    int ret=PPCS_DeInitialize();
    GLog(tShangYun, (@"PPCS_DeInitialize ret=%d",ret));
}

- (id)init
{
    if ((self = [super init]))
    {
        //[self setP2PSDKType:3];//尚云设备
        //_imgList1=[[NSMutableArray alloc]init];
    }
    
    return self;
}
//- (void)dealloc
//{
//    //UnSubscribe推送
//    [[ShangYunPushMana sharedInstance]UnSubscribe:self.udid];
//    [super dealloc];
//}
- (BOOL) mayContinue
{
    nsDID=self.udid;
    if(nsDID==nil || [nsDID length]<=0) return NO;
    else return YES;
}
-(int) readDataFromRemote:(int) handleSession withChannel:(unsigned char) Channel withBuf:(char *)DataBuf
             withDataSize: (int *)pDataSize withTimeout:(int)TimeOut_ms
{
    int nRet=-1;
    int nTotalRead=0;
    int nRead=0;
    while(nTotalRead < *pDataSize){
        nRead=*pDataSize-nTotalRead;
        if(handleSession>=0) nRet=PPCS_Read(handleSession, Channel,DataBuf+nTotalRead, &nRead, TimeOut_ms);
        else break;
        nTotalRead+=nRead;

        if((nRet != ERROR_PPCS_SUCCESSFUL) && (nRet != ERROR_PPCS_TIME_OUT )) break;
        if((Channel==CHANNEL_DATA&&!m_bRecvAVDataRunning)||(Channel==CHANNEL_IOCTRL&&!m_bRecvIODataRunning))
            break;
    }
        //if(Channel==CHANNEL_IOCTRL)
        //    NSLog(@" readDataFromRemote(.)=%d, *pDataSize=%d hex=%@\n", nRet, *pDataSize,[ToolCommon _getHexString:DataBuf Size:*pDataSize]);
    if(nRet<0) *pDataSize=nTotalRead;
    return nRet;
}
/*
 INT32 myGetDataSizeFrom(st_AVStreamIOHead *pStreamIOHead)
 {
 INT32 nDataSize=pStreamIOHead->nStreamIOHead;
 nDataSize &=0x00FFFFFF;
 return nDataSize;
 }

 - (NSInteger)sendIOCtrl:(int) handleSession withIOType:(int) nIOCtrlType withIOData:(char *)pIOData withIODataSize:(int)nIODataSize
 {
 NSInteger nRet=0;

 //    int nLenHead=sizeof(st_AVStreamIOHead)+sizeof(st_AVIOCtrlHead);
 //    char *packet=new char[nLenHead+nIODataSize];
 //    st_AVStreamIOHead *pstStreamIOHead=(st_AVStreamIOHead *)packet;
 //    st_AVIOCtrlHead *pstIOCtrlHead	 =(st_AVIOCtrlHead *)(packet+sizeof(st_AVStreamIOHead));
 //
 //    pstStreamIOHead->nStreamIOHead=sizeof(st_AVIOCtrlHead)+nIODataSize;
 //    pstStreamIOHead->uionStreamIOHead.nStreamIOType=SIO_TYPE_IOCTRL;
 //
 //    pstIOCtrlHead->nIOCtrlType	  =nIOCtrlType;
 //    pstIOCtrlHead->nIOCtrlDataSize=nIODataSize;
 //
 //    if(pIOData) memcpy(packet+nLenHead, pIOData, nIODataSize);
 //
 //    int nSize=nLenHead+nIODataSize;
 //    nRet=PPCS_Write(handleSession, CHANNEL_IOCTRL, packet, nSize);
 //    delete []packet;
 //GLog(tShangYun,(@"SendIOCtrl(..): PPCS_Write(..)=%d\n", nRet));

 nRet=PPCS_Write(handleSession, CHANNEL_IOCTRL, pIOData, nIODataSize);
 return nRet;
 }
 */
//发音频数据
- (NSInteger)sendAudioData:(NSData*)data time:(int)nTime{
    char buf[1024]={0};
    FRAMEINFO_t_DoorBell *pFrameInfo=(FRAMEINFO_t_DoorBell*)buf;
    pFrameInfo->codec_id=MEDIA_CODEC_AUDIO_G711A_TUTK;
    pFrameInfo->flags=3;
    pFrameInfo->nFrameIndex=0;
    pFrameInfo->nPackLen=data.length;
    pFrameInfo->timestamp=nTime;
    memcpy(pFrameInfo+1, data.bytes, data.length);
    NSInteger nRet=PPCS_Write(m_handle, CHANNEL_DATA, buf, sizeof(FRAMEINFO_t_DoorBell)+data.length);
    GLog(tShangYun, (@"PPCS_Write udid=%@ CHANNEL_DATA nRet=%ld",self.udid,(long)nRet));
    //GLog(tShangYun, (@"PPCS_Write udid=%@ CHANNEL_DATA nRet=%ld byte=%@",self.udid,(long)nRet,[ToolCommon _getHexString:buf Size: sizeof(FRAMEINFO_t_DoorBell)+data.length ]));
    return nRet;
}
//发Cmd数据
- (NSInteger)doSendMsgWithCmd:(int)v_command dict:(NSDictionary*)v_dt{
    NSString *jsonStr=v_dt?[ToolCommon convertObjectTojsonString:v_dt]:@"";
    char buf[1024]={0};
    TransParant_MsgHead_DoorBell *pMsgHead=(TransParant_MsgHead_DoorBell*)buf;
    pMsgHead->dwSize=sizeof(TransParant_MsgHead_DoorBell);
    pMsgHead->dwFlag=DMS_FLAG;
    pMsgHead->dwVersion=1;
    pMsgHead->dwMsgType=v_command;
    pMsgHead->dwLen=jsonStr?(int)jsonStr.length:0;
    memcpy(pMsgHead+1, [jsonStr UTF8String], pMsgHead->dwLen);
    NSInteger nRet=PPCS_Write(m_handle, CHANNEL_IOCTRL, buf, sizeof(TransParant_MsgHead_DoorBell)+pMsgHead->dwLen);
    GLog(tShangYun, (@"PPCS_Write udid=%@ dwCommand=%02x v_json=%@ nRet=%ld byte=%@",self.udid,v_command,jsonStr,(long)nRet,[ToolCommon _getHexString:buf Size: sizeof(TransParant_MsgHead_DoorBell)+pMsgHead->dwLen ]));
    return nRet;
}
//- (void)processIoctrlMsg:(TransParant_MsgHead_DoorBell&)msgHead data:(const char *)data andLength:(unsigned short)nRecvSize{
//    //    TransParant_MsgHead_DoorBell msgHead;
//    //    memcpy(&msgHead, data, sizeof(TransParant_MsgHead_DoorBell));
//    char buf[8*1024]={0};
//    memcpy(buf, data, nRecvSize);
//    int nErrorNo=msgHead.dwErrorNo;
//
//    NSString *str1=nRecvSize>=0?[NSString stringWithUTF8String:data]:nil;
//    NSDictionary *jsonDict=[str1 objectFromJSONString];
//
//    GLog(tShangYun, (@"processIoctrlMsg udid=%@ Command=%02x dwErrorNO=%d dwlen=%d json2%@  nRecvSize=%d",self.udid,msgHead.dwMsgType,msgHead.dwErrorNo,msgHead.dwLen,str1,nRecvSize));
//    if (msgHead.dwMsgType==IOCTRL_TYPE_OP_SNAP_JPEG_RESP) {
//        NSLog(@"xxxx");
//    }
//    //[self delTransparentControllerByCmd:msgHead.dwCommand];//释放TransparentController
////    if(!jsonDict&&msgHead.dwLen>0){
////        NSLog(@"异常 jsonDict==nil");
////        return;
////    }
//    switch (msgHead.dwMsgType) {
//        case IOCTRL_TYPE_CFG_GET_PUBLICKEY_RESP:{
//            NSString* sPublicKey=[jsonDict objectForKey:@"PublicKey"] ;
//            NSString* sKeyValue=[jsonDict objectForKey:@"KeyValue"] ;//didReceivedPublicKeyResp
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedPublicKeyResp:publicKey:keyValue:)]) {
//                [self.callbackDelegate didReceivedPublicKeyResp:nErrorNo publicKey:sPublicKey keyValue:sKeyValue];
//            }
//        }
//            break;
//        case IOCTRL_TYPE_OP_LOGIN_RESP:{
//            int nOperating=[[jsonDict objectForKey:@"Operating"] intValue];
//            int nCfgSet=[[jsonDict objectForKey:@"CfgSet"] intValue];
//            int nFactoryReset=[[jsonDict objectForKey:@"FactoryReset"] intValue];
//            int nUnlock=[[jsonDict objectForKey:@"Unlock"] intValue];
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedLoginResp:operating:cfgSet:factoryReset:unlock:)]) {
//                [self.callbackDelegate didReceivedLoginResp:nErrorNo operating:nOperating cfgSet:nCfgSet factoryReset:nFactoryReset unlock:nUnlock];
//            }
//        }
//            break;
//        case IOCTRL_TYPE_OP_START:
//            //dwErrorNo　为成功时数据通道开始发送（st_AVFrameHead +裸码流）
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedStartResp:)])
//                [self.callbackDelegate didReceivedStartResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_STOP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedStopResp:)])
//                [self.callbackDelegate didReceivedStopResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_AUDIOSTART:
//            //dwErrorNo　为成功时数据通道发送（st_AVFrameHead +裸码流）包括音频流类型
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedAudioStartResp:)])
//                [self.callbackDelegate didReceivedAudioStartResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_AUDIOSTOP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedAudioStopResp:)])
//                [self.callbackDelegate didReceivedAudioStopResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_SPEAKERSTART:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSpeakStartResp:)])
//                [self.callbackDelegate didReceivedSpeakStartResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_SPEAKERSTOP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSpeakStopResp:)])
//                [self.callbackDelegate didReceivedSpeakStopResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_OPEN_DOOR_RESP:
//            //dwErrorNo 0 表示成功；１表示用户没有权限；２用户密码错误；３开锁密码错误
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedOpenDoorResp:)])
//                [self.callbackDelegate didReceivedOpenDoorResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_REBOOT_REQ:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedRebootResp:)])
//                [self.callbackDelegate didReceivedRebootResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_RESET_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedResetResp:)])
//                [self.callbackDelegate didReceivedResetResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_FORMATEXTSTORAGE_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedFormatStorageResp:)])
//                [self.callbackDelegate didReceivedFormatStorageResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_CFG_DEVINFO_RESP:{
//            NSString* sDeviceType=[jsonDict objectForKey:@"DeviceType"] ;
//            NSString* sSoftwareDwVersion=[jsonDict objectForKey:@"SoftwareDwVersion"];
//            NSString* sHardwareDwVersion=[jsonDict objectForKey:@"HardwareDwVersion"];
//            NSString* sSerialNumber=[jsonDict objectForKey:@"SerialNumber"];
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedDeviceInfoResp:deviceType: softwareDwVersion: hardwareDwVersion: serialNumber:)]) {
//                [self.callbackDelegate didReceivedDeviceInfoResp:nErrorNo deviceType:sDeviceType softwareDwVersion:sSoftwareDwVersion hardwareDwVersion:sHardwareDwVersion serialNumber:sSerialNumber];
//            }
//        }
//            break;
//        case IOCTRL_TYPE_CFG_GET_WIFI_LIST_RESP:{
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedGetWifiListResp:wifilistinfo:)]) {
//                NSString* str2= [jsonDict objectForKey:@"wifilistInfo"];
//                NSArray* arr=(NSArray*)str2;
//                if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedGetWifiListResp:wifilistinfo:)])
//                    [self.callbackDelegate didReceivedGetWifiListResp:nErrorNo wifilistinfo:arr];
//            }
//        }
//            break;
//        case IOCTRL_TYPE_CFG_GET_NET_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedGetNetResp:)]) {
//                [self.callbackDelegate didReceivedGetNetResp:nErrorNo wifiInfo:jsonDict];
//            }
//            break;
//        case IOCTRL_TYPE_CFG_SET_NET_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSetNetResp:)])
//                [self.callbackDelegate didReceivedSetNetResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_CFG_GET_USERINFO_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedGetUserInfoResp:arrUserinfo:)]) {
//                NSString* str2= [jsonDict objectForKey:@"UserInfo"];
//                NSArray* arr=(NSArray*)str2;
//                [self.callbackDelegate didReceivedGetUserInfoResp:nErrorNo userinfo:arr];
//            }
//            break;
//        case IOCTRL_TYPE_CFG_SET_USERINFO_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSetUserinfoResp:)])
//                [self.callbackDelegate didReceivedSetUserinfoResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_CFG_GET_ALARM_PARAMETERS_RESP:{
//            int nPir=[[jsonDict objectForKey:@"Pir"] intValue];
//            int nPirSensitive=[[jsonDict objectForKey:@"PirSensitive"] intValue];
//            int nLamp=[[jsonDict objectForKey:@"Lamp"] intValue];
//            int nSceneMode=[[jsonDict objectForKey:@"SceneMode"] intValue];
//            int nDurationTime=[[jsonDict objectForKey:@"DurationTime"] intValue];
//            int nAction=[[jsonDict objectForKey:@"action"] intValue];
//            int nSnapNumber=[[jsonDict objectForKey:@"SnapNumber"] intValue];
//            int nVolumeOut=[[jsonDict objectForKey:@"VolumeOut"] intValue];
//            int nAudioAlert=[[jsonDict objectForKey:@"AudioAlert"] intValue];
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedGetAlarmParmetersResp:pir:pirSensitive:lamp:sceneMode:durationTime:action:snapNumber: volumeOut: audioAlert:)]) {
//                [self.callbackDelegate didReceivedGetAlarmParmetersResp:nErrorNo pir:nPir pirSensitive:nPirSensitive lamp:nLamp sceneMode:nSceneMode durationTime:nDurationTime action:nAction snapNumber:nSnapNumber volumeOut:nVolumeOut audioAlert:nAudioAlert];
//            }
//        }
//            break;
//        case IOCTRL_TYPE_CFG_SET_ALARM_PARAMETERS_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSetAlarmParmetersResp:)])
//                [self.callbackDelegate didReceivedSetAlarmParmetersResp:nErrorNo];
//            break;
//        case IOCTRL_TYPE_OP_LOG_SEARCH_RESP:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSearchLogResp:Loglist:)]) {
//                NSString* str2= [jsonDict objectForKey:@"LogInfo"];
//                NSArray* arr=(NSArray*)str2;
//                if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSearchLogResp:Loglist:)])
//                    [self.callbackDelegate didReceivedSearchLogResp:nErrorNo Loglist:arr];
//            }
//            break;
//        case IOCTRL_TYPE_OP_SNAP_JPEG_RESP:
////            if(nRecvSize>0&&nErrorNo==0){
////                UIImage* tPimage=[[UIImage alloc]initWithData:[[NSData alloc]initWithBytes:buf length:nRecvSize]];
////                self.Img=[[[UIImage alloc]initWithData:[NSData dataWithBytes:buf length:nRecvSize]]autorelease];
////                [self.imgList1 addObject:tPimage];
////            }
////                if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedSnapJpegResp:data:len:)])
////                    [self.callbackDelegate didReceivedSnapJpegResp:nErrorNo data:buf len:nRecvSize];
////
//            break;
//        case IOCTRL_TYPE_OP_DOWNLOAD_REQ:
//            if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didReceivedDownloadResp:data:len:)])
//                [self.callbackDelegate didReceivedDownloadResp:nErrorNo data:buf len:nRecvSize];
//            break;
//        case IOCTRL_TYPE_CFG_PRESS_BELL:
////            [UIApplication sharedApplication].applicationIconBadgeNumber +=1;
////            [self snapJpegReq];
////
////            // 1.创建一个本地通知
////            UILocalNotification *localNote = [[[UILocalNotification alloc] init] autorelease];
////
////            // 1.1.设置通知发出的时间
////            localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
////
////            // 1.2.设置通知内容
////            localNote.alertBody = @"Someone rang the bell";
////
////            // 1.3.设置锁屏时,字体下方显示的一个文字
////            localNote.alertAction = @"Someone rang the bell";
////            localNote.hasAction = YES;
////
////            // 1.4.设置启动图片(通过通知打开的)
////            //    localNote.alertLaunchImage = @"../Documents/IMG_0024.jpg";
////
////            // 1.5.设置通过到来的声音
////            localNote.soundName =@"doorbell.wav";// UILocalNotificationDefaultSoundName;
////
////            // 1.6.设置应用图标左上角显示的数字
////            //localNote.applicationIconBadgeNumber = 1;
////
////            // 1.7.设置一些额外的信息
////            localNote.userInfo = @{@"udid" : self.udid, @"msg" : @"success"};
////
////            // 2.执行通知
////            [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
//            break;
//    }
//}

/* 连线 */
- (NSInteger)startConnect{
    if(![self mayContinue]){
        return -1;
    }
    else if(m_bConnecting) {
        return -2;
    }
    else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //Subscribe推送
            [[ShangYunPushMana sharedInstance]Subscribe:self.udid];
        });

        m_bConnecting=1;
        //        [mLockConnecting lock];
        //        mConnMode=CONN_MODE_UNKNOWN;
        //
        //        char *sDID=NULL;
        //        sDID=(char *)[nsDID cStringUsingEncoding:NSASCIIStringEncoding];
        //        m_handle=PPCS_Connect(sDID, 1, 0);
        //        GLog(tShangYun, (@"PPCS_Connect udid=%@ m_handle=%d",self.udid,m_handle));
        //        if(m_handle>=0){
        //            st_PPCS_Session SInfo;
        //            memset(&SInfo, 0, sizeof(SInfo));
        //            PPCS_Check(m_handle, &SInfo);
        //            GLog(tShangYun, (@"PPCS_Check udid=%@ mode=%d",self.udid,SInfo.bMode));
        //            mConnMode=SInfo.bMode;

        //create receiving io thread
        if(mThreadRecvIOData==nil){
            m_bRecvIODataRunning=YES;
            mLockRecvIOData=[[NSConditionLock alloc] initWithCondition:NOTDONE];
            mThreadRecvIOData=[[NSThread alloc] initWithTarget:self selector:@selector(ThreadRecvIOData) object:nil];
            mThreadRecvAVData.name=@"ThreadRecvIOData";
            [mThreadRecvIOData start];
        }
        //        }
        //        [mLockConnecting unlock];
        m_bConnecting=0;
    }
    return m_handle;
}
- (void)stopConnect{
    int ret=PPCS_Connect_Break();
    GLog(tShangYun, (@"PPCS_Connect_Break udid=%@ ret=%d",self.udid,ret));

    if(m_handle>=0) {
        PPCS_Close(m_handle);
        GLog(tShangYun, (@"PPCS_Close udid=%@ ret=%d",self.udid,ret));

        //stop receiving iodata thread
        m_bRecvIODataRunning=NO;
        if(mThreadRecvIOData!=nil){
            [mLockRecvIOData lockWhenCondition:DONE];//This method blocks the thread’s execution until the lock can be acquired.
            [mLockRecvIOData unlock];

            //[mLockRecvIOData release];
            mLockRecvIOData  =nil;
            //[mThreadRecvIOData release];
            mThreadRecvIOData=nil;
        }

        m_handle=-1;

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //UnSubscribe推送
            [[ShangYunPushMana sharedInstance]UnSubscribe:self.udid];
        });
    }
}
/* 公钥获取 */
- (NSInteger)getPublickeyReq{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_GET_PUBLICKEY_REQ dict:nil] ;
    return nRet;
}
/*　登录　*/
- (NSInteger)LoginReq:(NSString*)sUserName password:(NSString*)sPassword{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sUserName,@"UserName",sPassword,@"Password",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_LOGIN_REQ dict:v_dt] ;
    return nRet;
}
/*　预览　*/
- (NSInteger)startLive{
    NSInteger nRet=-1;
    //    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"Channel",[NSNumber numberWithInt:0],@"StreamType",nil];
    //    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_START dict:v_dt];

    //create receiving data thread
    if(mThreadRecvAVData==nil){
        m_bRecvAVDataRunning=YES;
        mLockRecvAVData=[[NSConditionLock alloc] initWithCondition:NOTDONE];
        mThreadRecvAVData=[[NSThread alloc] initWithTarget:self selector:@selector(ThreadRecvAVData) object:nil];
        mThreadRecvAVData.name=@"ThreadRecvAVData";
        [mThreadRecvAVData start];
    }
    return nRet;
}
- (NSInteger)stopLive{
    NSInteger nRet=-1;
    NSDictionary *v_dt=nil;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_STOP dict:v_dt];
    //stop receiving avdata thread
    m_bRecvAVDataRunning=NO;
    if(mThreadRecvAVData!=nil){
        [mLockRecvAVData lockWhenCondition:DONE];
        [mLockRecvAVData unlock];

        //[mLockRecvAVData release];
        mLockRecvAVData  =nil;
        //[mThreadRecvAVData release];
        mThreadRecvAVData=nil;
    }
    return nRet;
    //    m_bVideoPlaying=NO;
    //    if(nRet>=0 && mThreadPlayVideo!=nil){
    //        [mLockPlayVideo lockWhenCondition:DONE];
    //        [mLockPlayVideo unlock];
    //
    //        [mLockPlayVideo release];
    //        mLockPlayVideo  =nil;
    //        [mThreadPlayVideo release];
    //        mThreadPlayVideo=nil;
    //    }
}
/*　音频监听　*/
- (NSInteger)openAudio
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_AUDIOSTART dict:nil] ;

//    if(nRet>=0 && mThreadDecordAudio==nil){
//        [self ResetAudioVar];
//        mLockDecordAudio=[[NSConditionLock alloc] initWithCondition:NOTDONE];
//        mThreadDecordAudio=[[NSThread alloc] initWithTarget:self selector:@selector(ThreadDecordAudio) object:nil];
//        [mThreadDecordAudio start];
//    }
    return nRet;
}
- (NSInteger)closeAudio
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_AUDIOSTOP dict:nil] ;
    m_bAudioDecording=NO;
//    if(mThreadDecordAudio!=nil){
//        [mLockDecordAudio lockWhenCondition:DONE];
//        [mLockDecordAudio unlock];
//
//        [mLockDecordAudio release];
//        mLockDecordAudio  =nil;
//        [mThreadDecordAudio release];
//        mThreadDecordAudio=nil;
//    }
    return nRet;
}
/* 通话 */
- (NSInteger)openSpeak
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_SPEAKERSTART dict:nil] ;
    return nRet;
}
- (NSInteger)closeSpeak{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_SPEAKERSTOP dict:nil] ;
    return nRet;
}
/* 开门、重启、恢复出厂 */
- (NSInteger)openDoor:(NSString*)sUserName password:(NSString*)sPassword unlockPassword:(NSString*)sUnlockPassword{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sUserName,@"UserName",sPassword,@"Password",sUnlockPassword,@"UnlockPassword",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_OPEN_DOOR_REQ dict:v_dt] ;
    return nRet;
}
- (NSInteger)reboot:(NSString*)sUserName password:(NSString*)sPassword{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sUserName,@"UserName",sPassword,@"Password",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_REBOOT_REQ dict:v_dt] ;
    return nRet;
}
- (NSInteger)reset:(NSString*)sUserName password:(NSString*)sPassword{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sUserName,@"UserName",sPassword,@"Password",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_RESET_REQ dict:v_dt] ;
    return nRet;
}
/* SD卡相关*/
- (NSInteger)formatStorage:(NSString*)sUserName password:(NSString*)sPassword{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sUserName,@"UserName",sPassword,@"Password",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_FORMATEXTSTORAGE_REQ dict:v_dt] ;
    return nRet;
}
/* 设备信息 */
- (NSInteger)getDevinfoReq
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_DEVINFO_REQ dict:nil] ;
    return nRet;
}
/* wifi 相关 */
- (NSInteger)geWifiListReq{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_GET_WIFI_LIST_REQ dict:nil];
    return nRet;
}
//请求网络参数
- (NSInteger)getNETReq{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_GET_NET_REQ dict:nil];
    return nRet;
}
//设置网络信息
- (NSInteger)setNetReq:(NSDictionary*)dt{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_SET_NET_REQ dict:dt];
    return nRet;
}
/* 用户相关 */
- (NSInteger)getUserinfoReq
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_GET_USERINFO_REQ dict:nil] ;
    return nRet;
}
- (NSInteger)setUserinfoReq:(NSDictionary*)dtCurUserInfo userinfo:(NSDictionary*)dtUserinfo
{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:dtCurUserInfo,@"CurUserInfo",dtUserinfo,@"UserInfo",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_SET_USERINFO_REQ dict:nil] ;
    return nRet;
}
/* 告警参数相关 */
- (NSInteger)getAlarmParametersReq
{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_CFG_GET_ALARM_PARAMETERS_REQ dict:nil] ;
    return nRet;
}
- (NSInteger)setAlarmParmetersReq:(int)nPir pirSensitive:(int)nPirSensitive lamp:(int)nLamp sceneMode:(int)nSceneMode durationTime:(int)nDurationTime action:(int)nAction snapNumber:(int)nSnapNumber volumeOut:(int)nVolumeOut audioAlert:(int)nAudioAlert{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nPir],@"Pir",[NSNumber numberWithInt:nPirSensitive],@"PirSensitive",
                        [NSNumber numberWithInt:nLamp],@"Lamp",[NSNumber numberWithInt:nSceneMode],@"SceneMode",
                        [NSNumber numberWithInt:nDurationTime],@"DurationTime",[NSNumber numberWithInt:nAction],@"action",
                        [NSNumber numberWithInt:nSnapNumber],@"SnapNumber",[NSNumber numberWithInt:nVolumeOut],@"VolumeOut",
                        [NSNumber numberWithInt:nAudioAlert],@"AudioAlert",
                        nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_RESET_REQ dict:v_dt] ;
    return nRet;
}
/* 日志查询相关 */
- (NSInteger)searchLogReq:(NSString*)sStartTime endTime:(NSString*)sEndTime type:(int)nType
{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:sStartTime,@"Start",sEndTime,@"End",[NSNumber numberWithInt:nType],@"Type",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_LOG_SEARCH_REQ dict:v_dt] ;
    return nRet;
}
/* 图像抓拍 */
- (NSInteger)snapJpegReq{
    NSInteger nRet=-1;
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_SNAP_JPEG_REQ dict:nil];
    return nRet;
}
/* 下载相关 */
- (NSInteger)downLoadReq:(int)nReqType ID:(NSString*)sID filePath:(NSString*)sFilePath{
    NSInteger nRet=-1;
    NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:nReqType],@"ReqType",sID,@"ID",sFilePath,@"FilePath",nil];
    nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_DOWNLOAD_REQ dict:v_dt];
    return nRet;
}

- (NSInteger)ThreadRecvAVData
{
    NSLog(@"    ThreadRecvAVData going... udid=%@",self.udid);
    CHAR  *pAVData=(CHAR *)malloc(MAX_SIZE_AV_BUF);
    INT32 nRecvSize=4, nRet=0;
    int  nCurStreamIOType=-1;
    FRAMEINFO_t_DoorBell *pFrameInfo=NULL;
    int frameFlag;
    int frameIndex;
    int timeStamp;

    m_bRecvAVDataRunning=YES;
    while(m_bRecvAVDataRunning){
        //等待连接成功
        if (m_handle<0) {
            usleep(50);
            continue;
        }
        else{
            //请求视频
            NSInteger nRet=-1;
            NSDictionary *v_dt=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0],@"Channel",[NSNumber numberWithInt:0],@"StreamType",nil];
            nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_START dict:v_dt];
            if(nRet<0){
                usleep(50);
                continue;
            }
            //请求音频
            nRet=[self doSendMsgWithCmd:IOCTRL_TYPE_OP_AUDIOSTART dict:v_dt];
            if(nRet<0){
                usleep(50);
                continue;
            }
        }

        while (m_bRecvAVDataRunning) {
            /*
             UINT32 nWriteSize;
             UINT32 nReadSize;
             int ret=PPCS_Check_Buffer(m_handle, CHANNEL_DATA, &nWriteSize, &nReadSize);
             GLog(tShangYun, (@"PPCS_Check_Buffer ret=%d nWriteSize=%d nReadSize=%d",ret,nWriteSize,nReadSize));
             */
            nRecvSize=sizeof(FRAMEINFO_t_DoorBell);
            nRet=[self readDataFromRemote:m_handle withChannel:CHANNEL_DATA withBuf:pAVData withDataSize:&nRecvSize withTimeout:1000];
            if(nRet == ERROR_PPCS_SESSION_CLOSED_TIMEOUT){
                NSLog(@"ThreadRecvAVData: Session TimeOUT!!1\n");

                break;

            }else if(nRet == ERROR_PPCS_SESSION_CLOSED_REMOTE){
                NSLog(@"ThreadRecvAVData: Session Remote Close!!1\n");
                break;

            }else if(nRet==ERROR_PPCS_SESSION_CLOSED_CALLED){
                NSLog(@"ThreadRecvAVData: myself called PPCS_Close!!1\n");
                break;

            }
            if(nRecvSize>0){
                pFrameInfo=(FRAMEINFO_t_DoorBell*)pAVData;
                nCurStreamIOType=pFrameInfo->codec_id;
                frameFlag=pFrameInfo->flags==1?IPC_FRAME_FLAG_IFRAME:IPC_FRAME_FLAG_PBFRAME;
                frameIndex=pFrameInfo->nFrameIndex;
                timeStamp=pFrameInfo->timestamp;
                if(nCurStreamIOType==MEDIA_CODEC_AUDIO_G711A
                   ||nCurStreamIOType==MEDIA_CODEC_AUDIO_G711A_TUTK
                   ){
                    nRecvSize=pFrameInfo->nPackLen;
                }else if(nCurStreamIOType==MEDIA_CODEC_VIDEO_H264){
                    nRecvSize=pFrameInfo->nDataSize;
                }
                else {
                    //NSAssert(true, @"异常");
                    GLog(tShangYun, (@"异常 codec_id=%02x",pFrameInfo->codec_id));
                }
                nRet=[self readDataFromRemote:m_handle withChannel:CHANNEL_DATA withBuf:pAVData withDataSize:&nRecvSize withTimeout:1000];

                if(nRet == ERROR_PPCS_SESSION_CLOSED_TIMEOUT){
                    NSLog(@"ThreadRecvAVData: Session TimeOUT!!2\n");
                    break;

                }else if(nRet == ERROR_PPCS_SESSION_CLOSED_REMOTE){
                    NSLog(@"ThreadRecvAVData: Session Remote Close!!2\n");
                    break;

                }else if(nRet==ERROR_PPCS_SESSION_CLOSED_CALLED){
                    NSLog(@"ThreadRecvAVData: myself called PPCS_Close!!2\n");
                    break;

                }
                if(nRecvSize>0){
                    if(nRecvSize>=MAX_SIZE_AV_BUF)
                        NSLog(@"====nRecvSize>256K, nCurStreamIOType\n");
                    else{

                        if(nCurStreamIOType==MEDIA_CODEC_AUDIO_G711A
                           ||nCurStreamIOType==MEDIA_CODEC_AUDIO_G711A_TUTK
                           ){/*
                              pBlock=(block_t *)malloc(sizeof(block_t));
                              block_Alloc(pBlock, pAVData, nRecvSize+sizeof(st_AVStreamIOHead));
                              av_FifoPut(m_fifoAudio, pBlock);*/
//                            GLog(tShangYun, (@"收到音频 length=%d flags=%d frameIndex=%d",nRecvSize,frameFlag,frameIndex));
//                            NSData *tData = [[NSData alloc] initWithBytes:pAVData length:nRecvSize];
//                            //                                dispatch_async(dispatch_get_main_queue(), ^{
//                            //                                    [_audioController playAudioBuffer:tData];
//                            //                                });
//                            dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                                [[AudioHandler sharedInstance] receiverAudio:(unsigned char*)tData.bytes WithLen:(int)tData.length];
//                            });
//                            [tData release];

                        }else if(nCurStreamIOType==MEDIA_CODEC_VIDEO_H264){
                            /*
                             pBlock=(block_t *)malloc(sizeof(block_t));
                             block_Alloc(pBlock, pAVData, nRecvSize+sizeof(st_AVStreamIOHead));
                             av_FifoPut(m_fifoVideo, pBlock);
                             */
                            GLog(tShangYun, (@"收到视频帧 length=%d flags=%d frameIndex=%d",nRecvSize,frameFlag,frameIndex));
                            NSTimeInterval time1= [NSDate timeIntervalSinceReferenceDate];
                            //@synchronized (self.datacontrol) {
                            NSData *tData = [[NSData alloc] initWithBytes:pAVData length:nRecvSize];

#ifdef SaveH264
                            //写文件测试代码
                            if (!fileData) {
                                fileData = [[NSMutableData alloc] init];
                            }
                            [fileData appendData:tData];
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,      NSUserDomainMask, YES);

                            NSString *documentDirectory = [directoryPaths objectAtIndex:0];
                            NSString *filePath = [documentDirectory stringByAppendingPathComponent:@"cc.h264"];
                            //查找文件，如果不存在，就创建一个文件

                            if (![fileManager fileExistsAtPath:filePath]) {
                                [fileManager createFileAtPath:filePath contents:nil attributes:nil];
                            }
                            GLog(tOther,(@"file--%@",filePath));
                            [fileData writeToFile:filePath atomically:YES];
#endif

                            MediaFrame *frame = [[MediaFrame alloc] initWithData:tData];
                            frame.isVideo = YES;
                            frame.frameIndex = frameIndex;
                            frame.keyFrame=(frameFlag==IPC_FRAME_FLAG_IFRAME);
                            frame.width = 100;
                            frame.height = 100;
                            frame.timestamp = timeStamp;
//                            if(self.datacontrol){
//                                // dispatch_async(dispatch_get_global_queue(0, 0), ^{
//
//
//
//                                [self.datacontrol device:self didReceiveVideoFrame:frame onConnection:0];
//
//                                // });
//
//                            }
//                            [frame release];//避免内存泄漏
//                            [tData release];
                            //}
                            NSTimeInterval time2=[NSDate timeIntervalSinceReferenceDate];
                            GLog(tVideoShow, (@"addFrame视频帧花费%f秒",time2-time1));
                        }
                        else{
                            GLog(tShangYun, (@"异常 codec_id=%02x",pFrameInfo->codec_id));
                        }
                    }
                }
            }
        }
    }
    free(pAVData);
    [mLockRecvAVData unlockWithCondition:DONE];
    NSLog(@"=== ThreadRecvAVData exit === udid=%@",self.udid);
    return 0;
}

//- (void)ThreadRecvIOData
//{
//    NSLog(@"    ThreadRecvIOData going... udid=%@",self.udid);
//    CHAR  *pIOData=(CHAR *)malloc(MAX_SIZE_IOCTRL_BUF);
//    INT32 nRecvSize=4, nRet=0;
//    //CHAR  nCurStreamIOType=0;
//
//    //block_t *pBlock=NULL;
//    m_bRecvIODataRunning=YES;
//    while(m_bRecvIODataRunning){
//        //尝试建立连线
//        char *sDID=NULL;
//        sDID=(char *)[nsDID cStringUsingEncoding:NSASCIIStringEncoding];
//        m_handle=PPCS_Connect(sDID, 1, 0);
//        GLog(tShangYun, (@"PPCS_Connect udid=%@ m_handle=%d",self.udid,m_handle));
//        /*************获取连线模式*****************/
//        st_PPCS_Session SInfo;
//        memset(&SInfo, 0, sizeof(SInfo));
//        PPCS_Check(m_handle, &SInfo);
//        GLog(tShangYun, (@"PPCS_Check udid=%@ mode=%d",self.udid,SInfo.bMode));
//        mConnMode=SInfo.bMode;
//        /*****************************/
//        if(m_handle>=0){
//            [self LoginReq:@"admin" password:@"admin"];
//            //更新设备在线状态
//            self.isOnLine=YES;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didDeviceSessionChanged:)])
//                    [self.callbackDelegate didDeviceSessionChanged:self];
//            });
//            while(m_bRecvIODataRunning){
//                nRecvSize=sizeof(TransParant_MsgHead_DoorBell);
//                memset(pIOData, 0, MAX_SIZE_IOCTRL_BUF);
//                nRet=[self readDataFromRemote:m_handle withChannel:CHANNEL_IOCTRL withBuf:pIOData withDataSize:&nRecvSize withTimeout:1000];
//                if(nRet == ERROR_PPCS_SESSION_CLOSED_TIMEOUT){
//                    NSLog(@"ThreadRecvIOData: Session TimeOUT!!1\n");
//                    break;
//
//                }else if(nRet == ERROR_PPCS_SESSION_CLOSED_REMOTE){
//                    NSLog(@"ThreadRecvIOData: Session Remote Close!!1\n");
//                    break;
//
//                }else if(nRet==ERROR_PPCS_SESSION_CLOSED_CALLED){
//                    NSLog(@"ThreadRecvIOData: myself called PPCS_Close!!1\n");
//                    break;
//                }
//                //if(nRecvSize>0){
//                TransParant_MsgHead_DoorBell msgHead;
//                memcpy(&msgHead, pIOData, sizeof(TransParant_MsgHead_DoorBell));
//                nRecvSize=msgHead.dwLen;
//                if(nRecvSize>0){
//                    memset(pIOData, 0, MAX_SIZE_IOCTRL_BUF);
//                    nRet=[self readDataFromRemote:m_handle withChannel:CHANNEL_IOCTRL withBuf:pIOData withDataSize:&nRecvSize withTimeout:1000];
//
//                    if(nRet == ERROR_PPCS_SESSION_CLOSED_TIMEOUT){
//                        NSLog(@"ThreadRecvIOData: Session TimeOUT!!2\n");
//                        break;
//
//                    }else if(nRet == ERROR_PPCS_SESSION_CLOSED_REMOTE){
//                        NSLog(@"ThreadRecvIOData: Session Remote Close!!2\n");
//                        break;
//
//                    }else if(nRet==ERROR_PPCS_SESSION_CLOSED_CALLED){
//                        NSLog(@"ThreadRecvIOData: myself called PPCS_Close!!2\n");
//                        break;
//
//                    }
//                    if(nRecvSize>0){
//                        if(nRecvSize>=MAX_SIZE_IOCTRL_BUF)
//                            NSLog(@"====nRecvSize>5K, ");
//                        else{
//
//                        }
//                    }
//                }
//                //}
//                if(msgHead.dwMsgType==IOCTRL_TYPE_OP_SNAP_JPEG_RESP){
//                    NSLog(@"IOCTRL_TYPE_OP_SNAP_JPEG_RESP");
//                }
//
//                [self processIoctrlMsg:msgHead data:pIOData andLength:nRecvSize];
//            }
//            //更新设备在线状态
//            self.isOnLine=NO;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (self.callbackDelegate&&[self.callbackDelegate respondsToSelector:@selector(didDeviceSessionChanged:)])
//                    [self.callbackDelegate didDeviceSessionChanged:self];
//            });
//            //关闭连线
//            usleep(50);
//            PPCS_Close(m_handle);
//            m_handle=-1;
//        }
//
//    }
//    free(pIOData);
//    [mLockRecvIOData unlockWithCondition:DONE];
//    NSLog(@"=== ThreadRecvIOData exit === udid=%@",self.udid);
//}

@end
