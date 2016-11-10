//
//  ShangyunDoorBellCmdDef.h
//  GoolinkViewEasy
//
//  Created by gxl on 16/10/9.
//
//

#ifndef ShangyunDoorBellCmdDef_h
#define ShangyunDoorBellCmdDef_h


#endif /* ShangyunDoorBellCmdDef_h */
#import "AVSTREAM_IO_Proto.h"
#import "PPCS_API.h"
#import "PPCS_Error.h"
#import "PPCS_Type.h"

typedef int DWORD;
typedef char BYTE;
#define DMS_FLAG 9000
//协议传输包头结构体
typedef struct{
    DWORD	dwSize;		//结构体大小sizeof(TransParant_ MsgHead)
    DWORD	dwFlag;		//DMS_FLAG:9000
    DWORD  dwVersion;	//消息头版本 0 不加密; 1 加密
    DWORD	dwMsgType;	//消息类型详见　ENUM_IOCTRL_OP_MSGTYPE, 													ENUM_IOCTRL_CFG_MSGTYPE
    DWORD	dwErrorNo;	//错误码,详见DMSErrno.h
    DWORD	dwLen;		//消息头后面的数据大小（JSON数据）
    DWORD	dwSeq;		//消息序列号，标识一次消息的唯一性，由请求方创建，回应方							原值返回
    DWORD	dwChannel;	//通道号（默认传0）
    BYTE	Aes[256];			//通过rsa2048加密之后的aes256密钥值 									RSA2048_Encode(value), value:用ＡＥＳ２５６算法随机生成密钥
    BYTE	CheckValue[32];//包体校验值sha256
    DWORD	dwRes;		//保留字节
}TransParant_MsgHead_DoorBell;

//操作消息类型枚举
typedef enum
{
    /*　登录　*/
    IOCTRL_TYPE_OP_LOGIN_REQ			= 0x0110,
    IOCTRL_TYPE_OP_LOGIN_RESP		=0x0111,
    /*　预览　*/
    IOCTRL_TYPE_OP_START				= 0x01FF,
    IOCTRL_TYPE_OP_STOP				= 0x02FF,
    /*　音频监听　*/
    IOCTRL_TYPE_OP_AUDIOSTART			= 0x0300,
    IOCTRL_TYPE_OP_AUDIOSTOP			= 0x0301,
    /* 通话 */
    IOCTRL_TYPE_OP_SPEAKERSTART		= 0x0310,
    IOCTRL_TYPE_OP_SPEAKERSTOP		= 0x0311,
    /* 升级相关 */
    IOCTRL_TYPE_OP_GET_FWUPDATE_REQ		= 0x0320,
    IOCTRL_TYPE_OP_GET_FWUPDATE_RESP		= 0x0321,
    IOCTRL_TYPE_OP_SET_FWUPDATE_REQ		= 0x0322,
    IOCTRL_TYPE_OP_SET_FWUPDATE_RESP		= 0x0323,
    /* 开门、重启、恢复出厂 */
    IOCTRL_TYPE_OP_OPEN_DOOR_REQ				= 0x0330,
    IOCTRL_TYPE_OP_OPEN_DOOR_RESP				= 0x0331,
    IOCTRL_TYPE_OP_REBOOT_REQ				= 0x0332,
    IOCTRL_TYPE_OP_REBOOT_RESP				= 0x0333,
    IOCTRL_TYPE_OP_RESET_REQ				= 0x0334,
    IOCTRL_TYPE_OP_RESET_RESP				= 0x0335,
    /* 日志查询 */
    IOCTRL_TYPE_OP_LOG_SEARCH_REQ				= 0x0340,
    IOCTRL_TYPE_OP_LOG_SEARCH_RESP				= 0x0341,
    /* 录像文件下载 */
    IOCTRL_TYPE_OP_DOWNLOAD_RECORD_REQ				= 0x0350,
    IOCTRL_TYPE_OP_DOWNLOAD_RECORD_RESP			= 0x0351,
    /* 图像下载 */
    IOCTRL_TYPE_OP_DOWNLOAD_JPEG_REQ				= 0x0352,
    IOCTRL_TYPE_OP_DOWNLOAD_JPEG_RESP				= 0x0353,
    /*  图像抓拍 */
    IOCTRL_TYPE_OP_SNAP_JPEG_REQ				       = 0x0354,
    IOCTRL_TYPE_OP_SNAP_JPEG_RESP				= 0x0355,
    
    /* 下载相关 */
    IOCTRL_TYPE_OP_DOWNLOAD_REQ				       = 0x0356,
    IOCTRL_TYPE_OP_DOWNLOAD_RESP				= 0x0357,
    /* SD卡相关*/
    IOCTRL_TYPE_OP_FORMATEXTSTORAGE_REQ		= 0x0360,
    IOCTRL_TYPE_OP_FORMATEXTSTORAGE_RESP		= 0x0361,
    
} ENUM_IOCTRL_OP_MSGTYPE;

//配置消息类型枚举
typedef enum
{
    /* 设备信息 */
    IOCTRL_TYPE_CFG_DEVINFO_REQ		= 0x0370,
    IOCTRL_TYPE_CFG_DEVINFO_RESP		= 0x0371,
    /* wifi 相关 */
    IOCTRL_TYPE_CFG_GET_NET_REQ		= 0x0380,
    IOCTRL_TYPE_CFG_GET_NET_RESP		= 0x0381,
    IOCTRL_TYPE_CFG_SET_NET_REQ		= 0x0382,
    IOCTRL_TYPE_CFG_SET_NET_RESP		= 0x0383,
    IOCTRL_TYPE_CFG_GET_WIFI_LIST_REQ		= 0x0384,
    IOCTRL_TYPE_CFG_GET_WIFI_LIST_RESP		= 0x0385,
    /* 用户信息相关 */
    IOCTRL_TYPE_CFG_GET_USERINFO_REQ				= 0x0390,
    IOCTRL_TYPE_CFG_GET_USERINFO_RESP				= 0x0391,
    IOCTRL_TYPE_CFG_SET_USERINFO_REQ				= 0x0392,
    IOCTRL_TYPE_CFG_SET_USERINFO_RESP				= 0x0393,
    /* 告警参数相关 */
    IOCTRL_TYPE_CFG_GET_ALARM_PARAMETERS_REQ            = 0x03A0,
    IOCTRL_TYPE_CFG_GET_ALARM_PARAMETERS_RESP            = 0x03A1,
    IOCTRL_TYPE_CFG_SET_ALARM_PARAMETERS_REQ            = 0x03A2,
    IOCTRL_TYPE_CFG_SET_ALARM_PARAMETERS_RESP            = 0x03A3,
    
    /* 公钥获取 */
    IOCTRL_TYPE_CFG_GET_PUBLICKEY_REQ            = 0x03B0,
    IOCTRL_TYPE_CFG_GET_PUBLICKEY_RESP            = 0x03B1,
    
    /*门铃推送*/
    IOCTRL_TYPE_CFG_PRESS_BELL					= 0x03c0,
    
} ENUM_IOCTRL_CFG_MSGTYPE;

/* Audio/Video Frame Header Info */
typedef struct _FRAMEINFO2
{
    unsigned short codec_id;	// Media codec type defined, refer to ENUM_CODECID_ANNI
    unsigned char flags;		// Video: Combined with IPC_FRAME_xxx.   											Audio:(samplerate << 2) | (databits << 1) | (channel)
    unsigned char cam_index;	// 0 - n
    
    unsigned char onlineNum;	// number of client connected this device
    unsigned char reserve1[3];
    
    unsigned int nDataSize;//　帧数据大小
    unsigned int nPackLen;//一个音频帧有可能有多个音频包，通过它换算出音频包个数
    unsigned int nFrameIndex;
    unsigned int reserve2;	//
    unsigned int timestamp;	// Timestamp of the frame, in milliseconds
}FRAMEINFO_t_DoorBell;

//codec_id：
typedef enum
{

    MEDIA_CODEC_UNKNOWN 		= 0x00,
    MEDIA_CODEC_VIDEO_MPEG4		= 0x4C,
    MEDIA_CODEC_VIDEO_H263		= 0x4D,
    MEDIA_CODEC_VIDEO_H264		= 0x4E,
    MEDIA_CODEC_VIDEO_MJPEG		= 0x4F,

    MEDIA_CODEC_AUDIO_AAC_TUTK  = 0x88,
    MEDIA_CODEC_AUDIO_G711U_TUTK= 0x89,   //g711 u-law
    MEDIA_CODEC_AUDIO_G711A_TUTK= 0x8A,   //g711 a-law

    MEDIA_CODEC_AUDIO_ADPCM     = 0X8B,
    MEDIA_CODEC_AUDIO_PCM		= 0x8C,
    MEDIA_CODEC_AUDIO_SPEEX		= 0x8D,
    MEDIA_CODEC_AUDIO_MP3		= 0x8E,
    MEDIA_CODEC_AUDIO_G726      = 0x8F,
    MEDIA_CODEC_AUDIO_G711A  = 0x90,
    MEDIA_CODEC_AUDIO_G711U  = 0x91,
}ENUM_CODECID_DoorBell;

enum
{
    DMS_LOG_TYPE_ALL = 1, /* 所有日志类型 */
    DMS_LOG_TYPE_PIR,
    DMS_LOG_TYPE_MOTION,
    DMS_LOG_TYPE_INVADE,
    DMS_LOG_TYPE_DOORBELL,
}DMS_LOG_TYPE;

/* FRAME Flag */
 typedef enum
{
    
    IPC_FRAME_FLAG_PBFRAME	= 0x00,	// A/V P/B frame..
    IPC_FRAME_FLAG_IFRAME	= 0x01,	// A/V I frame.
    IPC_FRAME_FLAG_MD		= 0x02,	// For motion detection.
    IPC_FRAME_FLAG_IO		= 0x03,	// For Alarm IO detection.
}ENUM_FRAMEFLAG;
