//
//  ToolCommon.h
//  GoolinkViewEasy
//
//  Created by Anni on 16/3/25.
//
//

#import <Foundation/Foundation.h>
#define DEFAULT_Thumbnail_PATH    @"/Data/Thumbnail"//缩略图路径

#import "stdafxLog.h"
#import "iOSLogEngine.h"
#import "GLog.h"
#import "GLogZone.h"
#ifdef LOGTOFILE
#import "stdafxLog.h"
#import "iOSLogEngine.h"
#endif



 /******************************************/
 /*codes/状态码*/
 /******************************************/
 #define GLNK_status_connecting          166308  //Device connecting
 #define GLNK_status_connected           166310  //Device connected
 #define GLNK_status_videoOnScreen       167705  //Device video on screen
 /*****************************************/
 /* onAuthorized error codes/错误码*/
 /******************************************/
 #define GLNK_AUTH_LOGIN_FAILED			-10 //登录失败
 #define GLNK_AUTH_SUCC					1 // 成功
 #define GLNK_AUTH_USER_PWD_ERROR   		2 // 用户名或密码错
 #define GLNK_AUTH_PDA_VERSION_ERROR  	4 // 版本不一致
 #define GLNK_AUTH_MAX_USER_ERROR   		5  // 超过最大用户数
 #define GLNK_AUTH_DEVICE_OFFLINE   		6  // 设备已经离线
 #define GLNK_AUTH_DEVICE_HAS_EXIST   	7  // 设备已经存在
 #define GLNK_AUTH_DEVICE_OVERLOAD   	8  // 设备性能超载(设备忙)
 #define GLNK_AUTH_INVALID_CHANNLE   	9  // 设备不支持的通道
 #define GLNK_AUTH_PROTOCOL_ERROR   		10  // 协议解析出错
 #define GLNK_AUTH_NOT_START_ENCODE   	11  // 未启动编码
 #define GLNK_AUTH_TASK_DISPOSE_ERROR   	12  // 任务处理过程出错
 #define GLNK_AUTH_CONFIG_ERROR   		13  // 配置失败
 #define GLNK_AUTH_NOT_SUPPORT_TALK   	14  // 不支持双向语音
 #define GLNK_AUTH_TIME_ERROR   			15  // 搜索时间跨天
 #define GLNK_AUTH_OVER_INDEX_ERROR   	16  // 索引超出范围
 #define GLNK_AUTH_MEMORY_ERROR   		17  // 内存分配失败
 #define GLNK_AUTH_QUERY_ERROR   		18  // 搜索失败
 #define GLNK_AUTH_NO_USER_ERROR   		19  // 没有此用户
 #define GLNK_AUTH_NOW_EXITING   		20  // 用户正在退出
 #define GLNK_AUTH_GET_DATA_FAIL   		21  // 获取数据失败
 #define GLNK_AUTH_RIGHT_ERROR   		22  // 验证权限失败
 #define GLNK_AUTH_OPEN_LOCK_PWD_ERROR   23  // 开锁验证失败
 #define GLNK_AUTH_NO_VIDEO   			24  // 当前通道无视频
 #define GLNK_AUTH_WIFI_CONFIG_FAILED   	25 //wifi配置失败
 
 /******************************************/
 /* onDisconnected error codes/错误码*/
 /******************************************/
 #define GLNK_CONN_NO_NETWORK            -5400 //No Network
 #define GLNK_CONN_TO_DOMAIN             -5304 //域名解析超时
 #define GLNK_CONN_GOO_NXDOMAIN          -5303 //服务器域名错误
 #define GLNK_CONN_LBS_NXDOMAIN          -5300 //服务器域名错误
 #define GLNK_CONN_LBS_ERR               -5299 //GID部署出错，请上报GID
 #define GLNK_CONN_NO_FWDSVR             -5000 //无转发服务器
 #define GLNK_CONN_SYS_ERRNO             -4000 //系统连接错误
 #define GLNK_CONN_NET_UNREACH           -4101 //Network is unreachable，客户端网络未启用.
 #define GLNK_CONN_TIMEDOUT              -4110 //连接超时
 #define GLNK_CONN_REFUSED               -4111 //Connection refused，IP地址或端口错误
 #define GLNK_CONN_HOST_UNREACH          -4113 //No route to host。指客户端在纯内网
 #define GLNK_CONN_AUTH_FAILED           -20 //登录验证失败
 #define GLNK_CONN_LOGIN_FAILED          -10 //登录失败
 #define GLNK_CONN_COMPANLYID_INVALID	-3 //gid验证失败
 #define GLNK_CONN_DEV_OFFLINE			-2 //设备离线
 #define GLNK_CONN_GID_NOAUTH			-1 //非法gid
 #define GLNK_CONN_OK					0 //连接已断开
 #define GLNK_CONN_OPEN_ERR              5001 //打开连接出错
 #define GLNK_CONN_ERR                   5002 //连接时出错
 #define GLNK_CONN_CLOSE_TOOFAST         5530 //客户端登录成功后，连接马上被断开。
 #define GLNK_CONN_READ_TIMEOUT          5540 //读取超时
 #define GLNK_CONN_DISCONNECTED          5550 //连接被断开
 #define GLNK_CONN_LAN_TIMEOUT           5110 //内网连接超时
 #define GLNK_CONN_FWD_TIMEOUT           6110 //外网连接超时
 #define GLNK_CONN_DS_TIMEOUT            7110 //分发连接超时
 /******************************************/
 /* other error codes/错误码*/
 /******************************************/
 #define GLNK_error_IP_PORT              5556 //Error 4 IP OR PORT
 #define GLNK_error_IOCtrl               E16260 //Error 4 IOCtrl
 #define GLNK_error_login                E16261 //Error 4 login to device
 #define GLNK_error_connect_obj          E16262 //Error 4 connect object
 


typedef enum __DMS_CPU_TYPE_E
{
    DMS_CPU_8120 = 8120,
    DMS_CPU_8180 = 8180,
    DMS_CPU_8160 = 8160,
    DMS_CPU_3510 = 3510,
    DMS_CPU_3511 = 3511,
    DMS_CPU_3515 = 3515,
    DMS_CPU_3516 = 3516,
    DMS_CPU_3516A = 0x3516A,
    DMS_CPU_3516C = 0x3516C,
    DMS_CPU_3516D = 0x3516D,
    DMS_CPU_3518 = 3518,
    DMS_CPU_3518A = 0x3518A,
    DMS_CPU_3518C = 0x3518C,
    DMS_CPU_3518E = 0x3518E,
    DMS_CPU_TI365 = 365,
    DMS_CPU_HI3515A = 0x3515A,
    DMS_CPU_HI3520 = 0x3520,
    DMS_CPU_HI3520A = 0x352A,
    DMS_CPU_HI3520D = 0x352D,
    DMS_CPU_HI3521 = 0x3521,
    DMS_CPU_HI3531 = 0x3531,
    DMS_CPU_HI3535 = 0x3535,
    DMS_CPU_HI3518EV2 = 35182,
    DMS_CPU_HI3518EV21 = 351821,
    DMS_CPU_HI3516CV2 = 35162,
}DMS_CPU_TYPE_E;
//TYPE_INFO g_CPUTypeInfo[] = {
//    { DMS_CPU_8120,"A" },
//    { DMS_CPU_8180,"B" },
//    { DMS_CPU_8160,"C" },
//    { DMS_CPU_3510,"C" },
//    { DMS_CPU_3511,"C" },
//    { DMS_CPU_3515,"D" },
//    { DMS_CPU_3516,"E" },
//    { DMS_CPU_3516A,"GA" },
//    { DMS_CPU_3516C,"F" },
//    { DMS_CPU_3516D,"GD" },
//    { DMS_CPU_3518,"F" },
//    { DMS_CPU_3518A,"FA" },
//    { DMS_CPU_3518C,"FC" },
//    { DMS_CPU_3518E,"FE" },
//    { DMS_CPU_TI365,"H" },
//    { DMS_CPU_HI3515A,"G" },
//    { DMS_CPU_HI3520,"G" },
//    { DMS_CPU_HI3520A,"G" },
//    { DMS_CPU_HI3520D,"G" },
//    { DMS_CPU_HI3521,"G" },
//    { DMS_CPU_HI3531,"G" },
//    { DMS_CPU_HI3535,"G" },
//    { DMS_CPU_HI3518EV2,"KE"},
//    { DMS_CPU_HI3518EV21,"KF"},
//    { DMS_CPU_HI3516CV2,"K"},
//    { -1," " },
//};
@interface ToolCommon : NSObject
+ (NSString *)getStandardDate:(NSString *)uiDate;
+(NSString*)getWeekdayWithDate:(NSString *)uiDate;
+(NSDate*) convertDateFromString:(NSString*)uiDate format:format;
+(NSString*) convertStringFromDate:(NSDate*)date format:format;
//+(UIImage*)thumbnailImageForVideo:(NSString *)videoURL;
//+(UIImage *)composeWithImgList:(NSArray *)imgList;
//+(UIImage *)thumbnailImageForDeivce:(NSString *)deviceName channelCount:(int)cnt;
+ (NSString *) _getHexString:(char *)buff Size:(int)size;
+(NSString*)convertObjectTojsonString:(id)object;
+ (NSString*)getCPUType:(int)v_nCpuType;
//+(UIImage*)getThumbnailImageForLiveView;
//+(void*)snapThumbnailImageForLiveView;
@end
