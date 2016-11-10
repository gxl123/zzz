//
//  ShangYunDevice.h
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import <GP2PCollect/GP2PCollect.h>
#import "Device.h"
#define MAXSIZE_IMG_BUFFER  2764800

#define NOTDONE             0
#define DONE                1

#define CONN_MODE_UNKNOWN  -1
#define CONN_MODE_P2P       0
#define CONN_MODE_RLY       1

#define AV_TYPE_REALAV      1
#define AV_TYPE_PLAYBACK    2

@protocol DeviceDelegate;
typedef enum {
    CONN_INFO_UNKNOWN=5000,
    CONN_INFO_CONNECTING,        CONN_INFO_NO_NETWORK,
    CONN_INFO_CONNECT_WRONG_DID, CONN_INFO_CONNECT_WRONG_PWD,
    CONN_INFO_CONNECT_FAIL,      STATUS_INFO_SESSION_CLOSED,
    CONN_INFO_CONNECTED,         STATUS_INFO_PPPP_CHECK_OK,

}E_CAM_STATE;

@interface ShangYunDevice : Device{
        NSUInteger nRowID;
        NSString  *nsCamName;
        NSString  *nsDID;
        //-------------------
    
        E_CAM_STATE   mCamState;
        volatile int  mConnMode;
        volatile int  m_handle;
        volatile char m_bConnecting;
      //  av_fifo_t *m_fifoVideo, *m_fifoAudio;
    
        volatile BOOL m_bRunning, m_bVideoPlaying, m_bAudioDecording;
        NSThread *mThreadPlayVideo;
        NSThread *mThreadDecordAudio;
        NSThread *mThreadRecvAVData;
        NSThread *mThreadRecvIOData;
        NSConditionLock *mLockPlayVideo;
        NSConditionLock *mLockDecordAudio;
        NSConditionLock *mLockRecvAVData;
        NSConditionLock *mLockRecvIOData;
    
        unsigned long m_nTickUpdateInfo;
        unsigned long m_nFirstTickLocal_video, m_nTick2_video, m_nFirstTimestampDevice_video;
        unsigned long m_nFirstTickLocal_audio, m_nTick2_audio, m_nFirstTimestampDevice_audio;
        BOOL  m_bFirstFrame;
        int   m_nInitH264Decoder;
        int   m_framePara[4];
        unsigned char *m_pBufBmp24;
        NSInteger  mVideoHeight, mVideoWidth;
        NSUInteger mTotalFrame;
        char mOutAudio[640], mTmp[40];
        unsigned long mWaitTime_ms;
    
        NSMutableData *fileData;
        NSMutableArray* imgList1;
}
@property(assign)  NSUInteger   nRowID;
@property(assign)  E_CAM_STATE  mCamState;
@property(assign)  NSInteger mVideoHeight, mVideoWidth;

//@property(assign)  av_fifo_t *m_fifoVideo, *m_fifoAudio;
@property(nonatomic, retain) NSLock  *mLockConnecting;

@property(assign) BOOL m_bRunning, m_bVideoPlaying, m_bAudioDecording,m_bRecvIODataRunning,m_bRecvAVDataRunning;
@property(nonatomic, retain) NSString *nsCamName;
@property(nonatomic, retain) NSString *nsDID;
@property(nonatomic, retain) id<DeviceDelegate> callbackDelegate;
@property(nonatomic,strong) NSMutableArray* imgList1;
/*初始化p2psdk*/
+ (void)initSDK;
+ (void)deinitSDK;
- (id)init;
/* 连线 */
- (NSInteger)startConnect;
- (void)stopConnect;
/* 公钥获取 */
- (NSInteger)getPublickeyReq;
/*　登录　*/
- (NSInteger)LoginReq:(NSString*)sUserName password:(NSString*)sPassword;
/*　预览　*/
- (NSInteger)startLive;
- (NSInteger)stopLive;
/*　音频监听　*/
- (NSInteger)openAudio;
- (NSInteger)closeAudio;
/* 通话 */
- (NSInteger)openSpeak;
- (NSInteger)closeSpeak;
//发音频数据
- (NSInteger)sendAudioData:(NSData*)data time:(int)nTime;
///* 开门、重启、恢复出厂 */
//- (NSInteger)openDoor:(NSString*)sUserName password:(NSString*)sPassword unlockPassword:(NSString*)sUnlockPassword;
//- (NSInteger)reboot:(NSString*)sUserName password:(NSString*)sPassword;
//- (NSInteger)reset:(NSString*)sUserName password:(NSString*)sPassword;
///* SD卡相关*/
//- (NSInteger)formatStorage:(NSString*)sUserName password:(NSString*)sPassword;
///* 设备信息 */
//- (NSInteger)getDevinfoReq;
///* wifi 相关 */
//- (NSInteger)geWifiListReq;
////请求网络参数
//- (NSInteger)getNETReq;
////设置网络信息
//- (NSInteger)setNetReq:(NSDictionary*)dt;
///* 用户相关 */
//- (NSInteger)getUserinfoReq;
//- (NSInteger)setUserinfoReq:(NSDictionary*)dtCurUserInfo userinfo:(NSDictionary*)dtUserinfo;
///* 告警参数相关 */
//- (NSInteger)getAlarmParametersReq;
//- (NSInteger)setAlarmParmetersReq:(int)nPir pirSensitive:(int)nPirSensitive lamp:(int)nLamp sceneMode:(int)nSceneMode durationTime:(int)nDurationTime action:(int)nAction snapNumber:(int)nSnapNumber volumeOut:(int)nVolumeOut audioAlert:(int)nAudioAlert;
///* 日志查询相关 */
//- (NSInteger)searchLogReq:(NSString*)sStartTime endTime:(NSString*)sEndTime type:(int)nType;
///* 图像抓拍 */
//- (NSInteger)snapJpegReq;
///* 下载相关 */
//- (NSInteger)downLoadReq:(int)nReqType ID:(NSString*)sID filePath:(NSString*)sFilePath;
//@end
//
//@protocol DeviceDelegate <NSObject>
//@optional
///* 设备状态变更 */
//- (void)didDeviceSessionChanged:(Device*)dv;
///* 公钥获取 */
//- (void)didReceivedPublicKeyResp:(int)nErrorNo publicKey:(NSString *)sPublicKey  keyValue:(NSString*)sKeyValue;
///*　登录　*/
//- (void)didReceivedLoginResp:(int)nErrorNo operating:(int)nOperating cfgSet:(int)nCfgSet factoryReset:(int)nFactoryReset unlock:(int)nUnlock;
///*　预览　*/
//- (void)didReceivedStartResp:(int)nErrorNo;
//- (void)didReceivedStopResp:(int)nErrorNo;
///*　音频监听　*/
//- (void)didReceivedAudioStartResp:(int)nErrorNo;
//- (void)didReceivedAudioStopResp:(int)nErrorNo;
///* 通话 */
//- (void)didReceivedSpeakStartResp:(int)nErrorNo;
//- (void)didReceivedSpeakStopResp:(int)nErrorNo;
///* 开门、重启、恢复出厂 */
//- (void)didReceivedOpenDoorResp:(int)nErrorNo;
//- (void)didReceivedRebootResp:(int)nErrorNo;
//- (void)didReceivedResetResp:(int)nErrorNo;
///* SD卡相关*/
//- (void)didReceivedFormatStorageResp:(int)nErrorNo;
///* 设备信息 */
//- (void)didReceivedDeviceInfoResp:(int)nErrorNo deviceType:(NSString*)sDeviceType softwareDwVersion:(NSString*)sSoftwareDwVersion hardwareDwVersion:(NSString*)sHardwareDwVersion serialNumber:(NSString*)sSerialNumber;
///* wifi 相关 */
//- (void)didReceivedGetWifiListResp:(int)nErrorNo wifilistinfo:(NSArray*)arrayWifiListinfo;
//- (void)didReceivedGetNetResp:(int)nErrorNo wifiInfo:(NSDictionary*)dtWifiInfo;
//- (void)didReceivedSetNetResp:(int)nErrorNo;
///* 用户信息相关*/
//- (void)didReceivedGetUserInfoResp:(int)nErrorNo userinfo:(NSArray*)arrUserInfo;
//- (void)didReceivedSetUserinfoResp:(int)nErrorNo;
///* 告警参数相关 */
//- (void)didReceivedGetAlarmParmetersResp:(int)nErrorNo pir:(int)nPir pirSensitive:(int)nPirSensitive lamp:(int)nLamp sceneMode:(int)nSceneMode durationTime:(int)nDurationTime action:(int)nAction snapNumber:(int)nSnapNumber volumeOut:(int)nVolumeOut audioAlert:(int)nAudioAlert;
//- (void)didReceivedSetAlarmParmetersResp:(int)nErrorNo;
///* 日志查询相关 */
//- (void)didReceivedSearchLogResp:(int)nErrorNo Loglist:(NSArray*)arrLoglist;
///* 图像抓拍 */
//- (void)didReceivedSnapJpegResp:(int)nErrorNo data:(const char*)buf len:(int)nLen;
///* 下载相关 */
//- (void)didReceivedDownloadResp:(int)nErrorNo data:(const char*)buf len:(int)nLen;
@end
