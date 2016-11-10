//
//  ShangYunPushMana.m
//  GoolinkViewEasy
//
//  Created by gxl on 16/10/14.
//
//

#import "ShangYunPushMana.h"
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/time.h>

#include "NDT_Type.h"
#include "NDT_API.h"
#include "NDT_Error.h"

#include "WiPN_Error.h"
#include "WiPN_StringEncDec.h"
#import "ToolCommon.h"
@implementation ShangYunPushMana

//// ---------------------------- WiPN 全局变量 ----------------------------
//// This InitString is CS2 PPCS InitString, you must Todo: Modify this for your own InitString
//// 此initstring默认为尚云互联的服务器字符串，客户端需要改为自己NDT服务器的字符串
const CHAR *g_DefaultInitString = "EBGAEIBIKHJJGFJKEOGCFAEPHPMAHONDGJFPBKCPAJJMLFKBDBAGCJPBGOLKIKLKAJMJKFDOOFMOBECEJIMM";
//// Todo: Modify this for your own AESKey
//// 此AES128Key默认为尚云互联的AES128Key，客户需要改为自己NDT服务器的AES128Key
const CHAR *g_DefaultAES128Key = "0123456789ABCDEF";

//// QueryServer Number -> QueryServer的个数, 每个客户都有自己固定的QueryServerDID, 在部署 WiPN 服务器时就已经确定 QueryServer 的 DID 和数量
#define QUERY_SERVER_NUMBER 2
//// QueryServer 的 DID， 用户需改为自己 QueryServer 的DID
#define QUERY_SERVER_DID_Test_1 "PPCS-014143-SBKHR"
#define QUERY_SERVER_DID_Test_2 "PPCS-014144-RVDKK"

// 用于存放 QueryServer DID
const char *g_QueryServerDIDBuf[QUERY_SERVER_NUMBER] = {QUERY_SERVER_DID_Test_1, QUERY_SERVER_DID_Test_2};

// AA_key: 加密／解密数据时所需的金钥匙
char g_StringEncDecKey[] = "WiPN@CS2-Network";

#define SIZE_DID                    32
#define SIZE_InitString             256
#define SIZE_AES128Key              20
#define SIZE_DeviceToken            256
#define SIZE_PostServerString       512
#define SIZE_SubscribeServerString  512
#define SIZE_UTCTString             20
#define SIZE_RETString              128
#define SIZE_AA_enc                 1280
#define SIZE_AA_dnc                 1280

UINT32 g_APIVersion;
//CHAR g_DeviceDID[SIZE_DID] = {0};
CHAR g_InitString[SIZE_InitString] = {0};
CHAR g_AES128Key[SIZE_AES128Key] = {0};
ULONG g_EventCH = 0;

// Mode: for SendTo
// 0 -> 内网广播优先其次公网
// 1 -> 仅公网
// 2 -> 仅内网广播
int g_SendToMode = 1;

// Agent 的名称 例如: APNS
char g_AG_Name[] = "APNS";
// 订阅者 APP 名称，客户需要改为自己的 APP 名字
char g_APP_Name[] = "RingViews_dev";//"CamViews";//"WiPN_Client";
// 用于保存手机的 DeviceToken
char g_DeviceToken[SIZE_DeviceToken] = {0};

// 用于保存 Subscribe 订阅时所需的 SubscribeServerString
char g_SubscribeServerString[SIZE_SubscribeServerString] = {0};
// 用于保存 Server 的时间
char g_UTCTString[SIZE_UTCTString] = {0};
// 用于记录每次 recvFrom 返回所记下的当前时间
time_t g_Time_ServerRet = 0;

// 开始标志
int g_startRunningFalg = 0;
// 初始化标志
int g_NDTInitialize = 0;
// 订阅线程运行标志
int thread_WiPN_Subscribe_Running = 0;
//// ----------------------------------------------------------------------

//// ------------------------------ WiPN API ------------------------------
////  WiPN_Query 查询
INT32 WiPN_Query(const CHAR *pDeviceDID, 			// 设备的DID
                 const CHAR *QueryServerDID[], 		// QueryServer 的DID
                 CHAR *pPostServerString, 			// 保存查询到的 PostServerString
                 UINT32 SizeOfPostServerString, 	// PostServerString Buf 的大小
                 CHAR *pSubscribeServerString, 		// 保存查询到的 SubscribeServerString
                 UINT32 SizeOfSubscribeServerString,// SubscribeServerString Buf 的大小
                 CHAR *pUTCTString, 				// 保存查询到的 UTCTString
                 UINT32 SizeOfUTCTString);			// UTCTString Buf 的大小

//// WiPN_Subscribe 订阅
INT32 WiPN_Subscribe(const CHAR *pSubscribeServerString,// 由 WiPN_Query 查询所得
                     const CHAR *pSubCmd,		// 订阅指令
                     CHAR *pRETString,			// 用于保存 SubscribeServer 返回的说明信息
                     UINT32 SizeOfRETString,	// RETString Buf 的大小
                     CHAR *pUTCTString,			// 用于保存 SubscribeServer 返回的 UTCTString
                     UINT32 SizeOfUTCTString);	// UTCTString Buf 的大小

//// WiPN_UnSubscribe 取消订阅
INT32 WiPN_UnSubscribe(const CHAR *pSubscribeServerString,// 由 WiPN_Query 查询所得
                       const CHAR *pSubCmd,			// 订阅指令
                       CHAR *pRETString,			// 用于保存 SubscribeServer 返回的说明信息
                       UINT32 SizeOfRETString,		// RETString Buf 的大小
                       CHAR *pUTCTString,			// 用于保存 SubscribeServer 返回的 UTCTString
                       UINT32 SizeOfUTCTString);	// UTCTString Buf 的大小
//// ----------------------------------------------------------------------


void mSecSleep(UINT32 ms)
{
#if defined WINDOWS
    Sleep(ms);
#elif defined LINUX
    usleep(ms * 1000);
#endif
}

const char *getErrorCodeInfo(int err)
{
    if (0 < err)
        return "NoError, May be handle value!";
    
    switch (err)
    {
        case 0: return "NDT_ERROR_NoError";
        case -1: return "NDT_ERROR_AlreadyInitialized";
        case -2: return "NDT_ERROR_NotInitialized";
        case -3: return "NDT_ERROR_TimeOut";
        case -4: return "NDT_ERROR_ScketCreateFailed";
        case -5: return "NDT_ERROR_ScketBindFailed";
        case -6: return "NDT_ERROR_HostResolveFailed";
        case -7: return "NDT_ERROR_ThreadCreateFailed";
        case -8: return "NDT_ERROR_MemoryAllocFailed";
        case -9: return "NDT_ERROR_NotEnoughBufferSize";
        case -10: return "NDT_ERROR_InvalidInitString";
        case -11: return "NDT_ERROR_InvalidAES128Key";
        case -12: return "NDT_ERROR_InvalidDataOrSize";
        case -13: return "NDT_ERROR_InvalidDID";
        case -14: return "NDT_ERROR_InvalidNDTLicense";
        case -15: return "NDT_ERROR_InvalidHandle";
        case -16: return "NDT_ERROR_ExceedMaxDeviceHandle";
        case -17: return "NDT_ERROR_ExceedMaxClientHandle";
        case -18: return "NDT_ERROR_NetworkDetectRunning";
        case -19: return "NDT_ERROR_SendToRunning";
        case -20: return "NDT_ERROR_RecvRunning";
        case -21: return "NDT_ERROR_RecvFromRunning";
        case -22: return "NDT_ERROR_SendBackRunning";
        case -23: return "NDT_ERROR_DeviceNotOnRecv";
        case -24: return "NDT_ERROR_ClientNotOnRecvFrom";
        case -25: return "NDT_ERROR_NoAckFromCS";
        case -26: return "NDT_ERROR_NoAckFromPushServer";
        case -27: return "NDT_ERROR_NoAckFromDevice";
        case -28: return "NDT_ERROR_NoAckFromClient";
        case -29: return "NDT_ERROR_NoPushServerKnowDevice";
        case -30: return "NDT_ERROR_NoPushServerKnowClient";
        case -31: return "NDT_ERROR_UserBreak";
        case -32: return "NDT_ERROR_SendToNotRunning";
        case -33: return "NDT_ERROR_RecvNotRunning";
        case -34: return "NDT_ERROR_RecvFromNotRunning";
        case -35: return "NDT_ERROR_SendBackNotRunning";
        case -36: return "NDT_ERROR_RemoteHandleClosed";
        case -99: return "NDT_ERROR_FAESupportNeeded";
            // WiPN 的错误信息
        case WiPN_ERROR_InvalidParameter: return "WiPN_ERROR_InvalidParameter";
        case WiPN_ERROR_iPNStringEncFailed: return "WiPN_ERROR_iPNStringEncFailed";
        case WiPN_ERROR_iPNStringDncFailed: return "WiPN_ERROR_iPNStringDncFailed";
        case WiPN_ERROR_GetPostServerStringItemFailed: return "WiPN_ERROR_GetPostServerStringItemFailed";
        case WiPN_ERROR_GetSubscribeServerStringItemFailed: return "WiPN_ERROR_GetSubscribeServerStringItemFailed";
        case WiPN_ERROR_GetUTCTStringItemFailed: return "WiPN_ERROR_GetUTCTStringItemFailed";
        case WiPN_ERROR_GetNumberFromPostServerStringFailed: return "WiPN_ERROR_GetNumberFromPostServerStringFailed";
        case WiPN_ERROR_GetNumberFromSubscribeServerStringFailed: return "WiPN_ERROR_GetNumberFromSubscribeServerStringFailed";
        case WiPN_ERROR_GetDIDFromPostServerStringFailed: return "WiPN_ERROR_GetDIDFromPostServerStringFailed";
        case WiPN_ERROR_GetDIDFromSubscribeServerStringFailed: return "WiPN_ERROR_GetDIDFromSubscribeServerStringFailed";
        case WiPN_ERROR_GetRETStringItemFailed: return "WiPN_ERROR_GetRETStringItemFailed";
        case WiPN_ERROR_MallocFailed: return "WiPN_ERROR_MallocFailed";
        case WiPN_ERROR_ExceedMaxSize: return "WiPN_ERROR_ExceedMaxSize";
        default:
            return "Unknow, something is wrong!";
    }
}


//// 根据 ItemName 获取相应的字符串
//// ret=0 OK, ret=-1 Invalid Parameter, ret=-2 No such Item
int GetStringItem(const char *SrcStr,
                  const char *ItemName,
                  const char Seperator,
                  char *RetString,
                  const int MaxSize)
{
    if (!SrcStr || !ItemName || !RetString || 0 == MaxSize)
        return -1;
    
    const char *pFand = SrcStr;
    while (1)
    {
        pFand = strstr(pFand, ItemName);
        if (NULL == pFand)
            return -2;
        pFand += strlen(ItemName);
        if ('=' != *pFand)
            continue;
        else
            break;
    }
    
    pFand += 1;
    int i = 0;
    while (1)
    {
        if (Seperator == *(pFand + i) || '\0' == *(pFand + i) || i >= (MaxSize - 1))
            break;
        else
            *(RetString + i) = *(pFand + i);
        i++;
    }
    *(RetString + i) = '\0';
    
    return 0;
}

// 获取 PostServer/SubscribeServer 服务器数量和 DID 的长度
int pharse_number(const CHAR *pServerString, unsigned short *Number, unsigned short *SizeOfDID)
{
    if (!pServerString || !Number)
        return -1;
    
    // 获取 PostServerDID 数量
    CHAR buf[8];
    memset(buf, 0, sizeof(buf));
    const CHAR *pS = pServerString;
    const CHAR *p1 = strstr(pServerString, ",");
    if (NULL == p1)
        return -1;
    if (p1 - pS > sizeof(buf) - 1)
        return -1;
    int i = 0;
    while (1)
    {
        if (pS + i >= p1)
            break;
        buf[i] = *(pS + i);
        i++;
    }
    buf[i] = '\0';
    *Number = atoi(buf);
    
    // 获取 PostServerDID 长度
    p1 += 1; 	// 指向第一个 DID
    const char *p2 = strstr(p1, ",");
    if (!p2)	// -> 只有一个 DID -> "01,ABCD-123456-ABCDEF"
        *SizeOfDID = strlen(p1);
    else
        *SizeOfDID = (unsigned short)(p2 - p1);
    //printf("SizeOfDID= %d\n", *SizeOfDID);
    
    return 0;
}

// 获取 PostServer/SubscribeServer 服务器DID
const char *pharse_DID(const char *pServerString, int index)
{
    if (!pServerString || 0 > index)
        return NULL;
    const char *p1 = strstr(pServerString, ",");
    if (NULL == p1)
        return NULL;
    p1 += 1;		// -> 指向第一个 DID
    
    const char *p2 = strstr(p1, ",");
    if (NULL == p2) // -> 只有一个 DID
    {
        unsigned short LengthOfDID = strlen(p1);
        if (0 == LengthOfDID)
            return NULL;
        //printf("LengthOfDID= %d\n", LengthOfDID);
        char *pDID = (char *)malloc((LengthOfDID/4+1)*4);
        if (!pDID)
        {
            GLog(tShangYunPush, (@"pharse_DID - malloc falied!!\n"));
            return NULL;
        }
        memset(pDID, '\0', (LengthOfDID/4+1)*4);
        memcpy(pDID, p1, LengthOfDID);
        return pDID;
    }
    unsigned short SizeOfDID = (unsigned short)(p2 - p1);
    //printf("SizeOfDID= %d\n", SizeOfDID);
    
    p1 = pServerString;
    int i = 0;
    for (; i < index + 1; i++)
    {
        p1 = strstr(p1, ",");
        if (!p1)
            break;
        p1 += 1;
    }
    if (!p1)
        return NULL;
    char *pDID = (char *)malloc((SizeOfDID/4+1)*4);
    if (!pDID)
    {
        GLog(tShangYunPush, (@"pharse_DID - malloc falied!!\n"));
        return NULL;
    }
    memset(pDID, '\0', (SizeOfDID/4+1)*4);
    memcpy(pDID, p1, SizeOfDID);
    //printf("p_DID = %s\n", p_DID);
    
    return pDID;
}

// set Subscribe / UnSubscribe Cmd
int setSubCmd(char *pSubCmd,
              unsigned short SizeOfSubCmd,
              const char *pDeviceDID,
              unsigned long EventCH,
              const char *pAG_Name,
              const char *pAPP_Name,
              const char *pDeviceToken)
{
    if (!pSubCmd || 0 == SizeOfSubCmd)
        return WiPN_ERROR_InvalidParameter;
    if (!pDeviceDID || !pAG_Name || !pAPP_Name || 0xFFFFFFFF < EventCH)
        return WiPN_ERROR_InvalidParameter;
    if (0 == strlen(pDeviceDID)  || 0 == strlen(pAG_Name) || 0 == strlen(pAPP_Name))
        return WiPN_ERROR_InvalidParameter;
    if (!pDeviceToken || 0 == strlen(pDeviceToken))
        GLog(tShangYunPush, (@"***Warning: DeviceToken is empty!!\n"));
    if (!pDeviceToken)
        pDeviceToken = "";
    
    unsigned short LengthOfParameter = strlen(pDeviceDID)
    +sizeof(EventCH)
    +strlen(pAG_Name)
    +strlen(pAPP_Name)
    +strlen(pDeviceToken);
    if (LengthOfParameter > SizeOfSubCmd - 1)
        return WiPN_ERROR_ExceedMaxSize;
    
    // 格式化 SubCmd
    memset(pSubCmd, '\0', SizeOfSubCmd);
    snprintf(pSubCmd, SizeOfSubCmd, "DID=%s&CH=%lu&AG=%s&APP=%s&INFO=%s&", pDeviceDID, EventCH, pAG_Name, pAPP_Name, pDeviceToken);
    
    return 0;
}

//// -------------------------------- WiPN API Begin --------------------------------
INT32 WiPN_Query(const CHAR *pDeviceDID,
                 const CHAR *QueryServerDID[],
                 CHAR *pPostServerString,
                 UINT32 SizeOfPostServerString,
                 CHAR *pSubscribeServerString,
                 UINT32 SizeOfSubscribeServerString,
                 CHAR *pUTCTString,
                 UINT32 SizeOfUTCTString)
{
    if (!pDeviceDID || 0 == strlen(pDeviceDID))
    {
        GLog(tShangYunPush, (@"WiPN_Query - pDeviceDID is NULL!!\n"));
        return WiPN_ERROR_InvalidParameter;
    }
    if (NULL == QueryServerDID)
    {
        GLog(tShangYunPush, (@"WiPN_Query - QueryServerDID Buf is NULL!!\n"));
        return WiPN_ERROR_InvalidParameter;
    }
    int i = 0;
    for (; i < QUERY_SERVER_NUMBER; i++)
    {
        if (NULL == QueryServerDID[i])
        {
            GLog(tShangYunPush, (@"WiPN_Query - QueryServerDIDbuf[%d] have no DID!!\n", i));
            return WiPN_ERROR_InvalidParameter;
        }
    }
    if (!pPostServerString && !pSubscribeServerString)
    {
        GLog(tShangYunPush, (@"WiPN_Query - pPostServerString && pSubscribeServerString is NULL!!\n"));
        return WiPN_ERROR_InvalidParameter;
    }
    if (NULL != pPostServerString && 0 == SizeOfPostServerString)
    {
        GLog(tShangYunPush, (@"WiPN_Query - SizeOfPostServerString = %d\n", SizeOfPostServerString));
        return WiPN_ERROR_InvalidParameter;
    }
    if (NULL != pSubscribeServerString && 0 == SizeOfSubscribeServerString)
    {
        GLog(tShangYunPush, (@"WiPN_Query - SizeOfSubscribeServerString = %d\n", SizeOfSubscribeServerString));
        return WiPN_ERROR_InvalidParameter;
    }
    if (!pUTCTString)
    {
        GLog(tShangYunPush, (@"WiPN_Query - pUTCTString is NULL!!\n"));
        return WiPN_ERROR_InvalidParameter;
    }
    if (NULL != pUTCTString && 0 == SizeOfUTCTString)
    {
        GLog(tShangYunPush, (@"WiPN_Query - SizeOfUTCTString = 0 !!\n"));
        return WiPN_ERROR_InvalidParameter;
    }
    
    // 保存查询指令
    CHAR QueryCmdBuf[36];
    memset(QueryCmdBuf, 0, sizeof(QueryCmdBuf));
    sprintf(QueryCmdBuf, "DID=%s&", pDeviceDID);
    GLog(tShangYunPush, (@"QueryCmd= %s\n", QueryCmdBuf));
    
    // 加密查询命令
    CHAR AA_enc[SIZE_AA_enc] = {0};
    if (0 > iPN_StringEnc(g_StringEncDecKey, QueryCmdBuf, AA_enc, sizeof(AA_enc)))
    {
        GLog(tShangYunPush, (@"WiPN_Query - iPN_StringEnc failed!\n"));
        return WiPN_ERROR_iPNStringEncFailed;
    }
    
    srand((UINT32)time(NULL));
    int ret = 0;
    int QueryServerHandle = -1;
    int repeatTimes_RecvFrom = 0;
    struct tm *ptm = NULL;
    
    UINT16 SizeOfRecvFrom = 1280;
    char *RecvFromBuf = (char *)malloc( (SizeOfRecvFrom/4+1)*4 );
    if (!RecvFromBuf)
    {
        GLog(tShangYunPush, (@"WiPN_Query - malloc RecvFromBuf falied!!\n"));
        return WiPN_ERROR_MallocFailed;
    }
    memset(RecvFromBuf, 0, (SizeOfRecvFrom/4+1)*4 );
    UINT16 SizeToRead = SizeOfRecvFrom;
    
    int index = rand() % QUERY_SERVER_NUMBER;
    while (1)
    {
        if (0 > QueryServerHandle)
        {
            for (i = 0; i < QUERY_SERVER_NUMBER*2; i++)
            {
                index = (index + 1) % QUERY_SERVER_NUMBER;
                
                GLog(tShangYunPush, (@"send cmd to QueryServer, QueryServerDID[%d]= %s. sending...\n", index, QueryServerDID[index]));
                
                ret = NDT_PPCS_SendTo(QueryServerDID[index], AA_enc, strlen(AA_enc), g_SendToMode);
                
                if (0 > ret)
                {
                    GLog(tShangYunPush, (@"send cmd to QueryServer failed!! ret= %d [%s]\n\n", ret, getErrorCodeInfo(ret)));
                    GLog(tShangYunPush, (@"repet try to send ...\n\n"));
                    continue;
                }
                else
                {
                    GLog(tShangYunPush, (@"send cmd to QueryServer success!! \n"));
                    QueryServerHandle = ret;
                    break;
                }
            }
            if (0 > QueryServerHandle)
            {
                GLog(tShangYunPush, (@"WiPN_Query - Get QueryServerHandle failed! QueryServerDID[%d]= %s. ret= %d [%s]\n", index, QueryServerDID[index], ret, getErrorCodeInfo(ret)));
                break;
            }
        }
        else
        {
            GLog(tShangYunPush, (@"Waiting for QueryServer response, please wait ...\n"));
            
            memset(RecvFromBuf, 0, (SizeOfRecvFrom/4+1)*4 );
            ret = NDT_PPCS_RecvFrom(QueryServerHandle, RecvFromBuf, &SizeToRead, 30000);
            
            // 记录 RecvFrom 返回的当前时间
            time_t Time_ServerRet = time(NULL);
            ptm = localtime((const time_t *)&Time_ServerRet);
            
            if (0 > ret)
            {
                if (ptm)
                    GLog(tShangYunPush, (@"WiPN_Query - NDT_PPCS_RecvFrom: QueryServerDID[%d]= %s. ret= %d. [%s] [%d-%d-%d %02d:%02d:%02d]\n", index, QueryServerDID[index], ret, getErrorCodeInfo(ret), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec));
                else
                    GLog(tShangYunPush, (@"WiPN_Query - NDT_PPCS_RecvFrom: QueryServerDID[%d]= %s. ret= %d. [%s]\n", index, QueryServerDID[index], ret, getErrorCodeInfo(ret)));
                
                // -26 -27 -3
                if ((NDT_ERROR_NoAckFromPushServer == ret
                     || NDT_ERROR_NoAckFromDevice == ret
                     || NDT_ERROR_TimeOut == ret)
                    && 3 > repeatTimes_RecvFrom)
                {
                    repeatTimes_RecvFrom++;
                    continue;
                }
                else if (NDT_ERROR_RemoteHandleClosed == ret) // -36
                    GLog(tShangYunPush, (@"WiPN_Query - QueryServer already call CloseHandle(). \n"));
                break;
            }
            else
            {
                // 解密接收到的数据
                CHAR AA_dnc[SIZE_AA_dnc] = {0};
                if (0 > iPN_StringDnc(g_StringEncDecKey, RecvFromBuf, AA_dnc, sizeof(AA_dnc)))
                {
                    GLog(tShangYunPush, (@"WiPN_Query - NDT_PPCS_RecvFrom: iPN_StringDnc failed! QueryServerDID[%d]= %s. \n", index, QueryServerDID[index]));
                    ret = WiPN_ERROR_iPNStringDncFailed;
                    break ;
                }
                
                if (ptm)
                    GLog(tShangYunPush, (@"\nFrom QueryServer: \nQueryServerDID[%d]= %s\nQueryServerHandle= %d\nData: %s\nSize: %u byte\nlocalTime: %d-%02d-%02d %02d:%02d:%02d\n\n", index, QueryServerDID[index], QueryServerHandle, AA_dnc, (UINT32)strlen(AA_dnc), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec));
                else
                    GLog(tShangYunPush, (@"\nFrom QueryServer: \nQueryServerDID[%d]= %s\nQueryServerHandle= %d\nData: %s\nSize: %u byte\n\n", index, QueryServerDID[index], QueryServerHandle, AA_dnc, (UINT32)strlen(AA_dnc)));
                
                // 拆分 AA_dnc 获取 PostServerString , 其中 '&' 为截取结束标志符
                if (NULL != pPostServerString && 0 > GetStringItem(AA_dnc, "Post", '&', pPostServerString, SizeOfPostServerString))
                {
                    GLog(tShangYunPush, (@"WiPN_Query - Get PostServerString failed!\n"));
                    ret = WiPN_ERROR_GetPostServerStringItemFailed;
                }
                // 拆分 AA_dnc 获取 SubscribeString
                if (NULL != pSubscribeServerString && 0 > GetStringItem(AA_dnc, "Subs", '&', pSubscribeServerString, SizeOfSubscribeServerString))
                {
                    GLog(tShangYunPush, (@"WiPN_Query - Get SubscribeServerString failed!\n"));
                    ret = WiPN_ERROR_GetSubscribeServerStringItemFailed;
                }
                // 拆分 AA_dnc 获取 UTCTString
                memset(pUTCTString, 0, SizeOfUTCTString);
                if (0 > GetStringItem(AA_dnc, "UTCT", '&', pUTCTString, SizeOfUTCTString))
                {
                    GLog(tShangYunPush, (@"WiPN_Query - Get UTCTString failed!\n"));
                    ret = WiPN_ERROR_GetUTCTStringItemFailed;
                }
                else
                {
                    // g_Time_ServerRet 必须要与 UTCTString 时间同步更新
                    g_Time_ServerRet = Time_ServerRet;
                }
            }
            break;
        } // Handle > 0
    } // while
    if (0 <= QueryServerHandle)
        NDT_PPCS_CloseHandle(QueryServerHandle);
    
    free((void *)RecvFromBuf);
    
    return ret;
} // WiPN_Query

//// WiPN_Subscribe for 离线推送
INT32 WiPN_Subscribe(const CHAR *pSubscribeServerString,
                     const CHAR *pSubCmd,
                     CHAR *pRETString,
                     UINT32 SizeOfRETString,
                     CHAR *pUTCTString,
                     UINT32 SizeOfUTCTString)
{
    if (!pSubscribeServerString || !pSubCmd || !pRETString || !pUTCTString )
        return WiPN_ERROR_InvalidParameter;
    if (0 == strlen(pSubscribeServerString) || 0 == strlen(pSubCmd) || 0 == strlen(pUTCTString))
        return WiPN_ERROR_InvalidParameter;
    
    //// -------------------------- 获取 SubscribeServer DID -------------------------
    // 获取 SubscribeServerString 中 SubscribeServer 的个数
    unsigned short NumberOfSubscribeServer = 0;
    unsigned short SizeOfDID = 0;
    if (0 > pharse_number(pSubscribeServerString, &NumberOfSubscribeServer, &SizeOfDID) || 0 == NumberOfSubscribeServer)
        return WiPN_ERROR_GetNumberFromSubscribeServerStringFailed;
    SizeOfDID = (SizeOfDID/4+1)*4; // DID 之间保持足够间隔
    
    // 根据 SubscribeServer DID 的个数分配内存空间
    CHAR *pSubscribeServerDID = (CHAR *)malloc( SizeOfDID * NumberOfSubscribeServer );
    if (!pSubscribeServerDID)
    {
        printf("WiPN_Subscribe - malloc SubscribeServerDID Buf falied!!\n");
        return WiPN_ERROR_MallocFailed;
    }
    memset(pSubscribeServerDID, '\0', SizeOfDID * NumberOfSubscribeServer );
    
    // 获取 SubscribeServerString 中的 SubscribeServer DID, 并保存
    const CHAR *pDID = NULL;
    int i = 0;
    for ( ; i < NumberOfSubscribeServer; i++)
    {
        pDID = pharse_DID(pSubscribeServerString, i);
        if (NULL == pDID)
        {
            free((void *)pSubscribeServerDID);
            return WiPN_ERROR_GetDIDFromSubscribeServerStringFailed;
        }
        memcpy(&pSubscribeServerDID[SizeOfDID*i], pDID, strlen(pDID));
        //printf("SubscribeServerDID[%d]= %s\n", i, &pSubscribeServerDID[SizeOfDID*i]);
        free((void*)pDID);
        pDID = NULL;
    }
    
    //// --------------------------- 准备 SubscribeCmd ---------------------------
    // 计算 SubscribeCmd 指令大小
    unsigned long LengthForSubscribeCmd = strlen("UTCT=0x&")+strlen(pSubCmd)+strlen(pUTCTString);
    
    // NDT 一次最大只能发送 1280 字节大小的数据，根据加密算法，加密之前的数据不能超过 630 个字节
    int MaxSizeOfCmd = 630;
    if (MaxSizeOfCmd < LengthForSubscribeCmd)
    {
        printf("WiPN_Subscribe - Length Of SubscribeCmd is Exceed %d bytes!!\n", MaxSizeOfCmd);
        free((void *)pSubscribeServerDID);
        return WiPN_ERROR_ExceedMaxSize;
    }
    // 分配 SubscribeCmd 的内存空间
    unsigned short LengthForSubscribeCmdMalloc = (LengthForSubscribeCmd/4+1)*4;
    char *pSubscribeCmd = (char *)malloc(LengthForSubscribeCmdMalloc);
    if (!pSubscribeCmd)
    {
        printf("WiPN_Subscribe - malloc SubscribeCmd Buf falied!!\n");
        free((void *)pSubscribeServerDID);
        return WiPN_ERROR_MallocFailed;
    }
    //// -------------------------------------------------------------------------
    
    int ret = 0;
    int SubscribeServerHandle = -1;
    srand((unsigned int)time(NULL));
    struct tm *ptm = NULL;
    int repeatTimes_RecvFrom = 0;
    unsigned int PrintfFlag = 0;
    
    UINT16 SizeOfRecvFrom = 1280;
    UINT16 SizeForRecvFromMalloc = (SizeOfRecvFrom/4+1)*4;
    char *RecvFromBuf = (char *)malloc(SizeForRecvFromMalloc);
    if (!RecvFromBuf)
    {
        GLog(tShangYunPush, (@"WiPN_Subscribe - malloc RecvFromBuf falied!!\n"));
        free((void *)pSubscribeServerDID);
        free((void *)pSubscribeCmd);
        return WiPN_ERROR_MallocFailed;
    }
    memset(RecvFromBuf, 0, SizeForRecvFromMalloc);
    UINT16 SizeToRead = SizeOfRecvFrom;
    
    int index = 0;
    int j = rand() % NumberOfSubscribeServer;
    while (1)
    {
        if (0 > SubscribeServerHandle)
        {
            for (i = 0; i < NumberOfSubscribeServer*2; i++)
            {
                j = (j + 1) % NumberOfSubscribeServer;
                index = SizeOfDID * j;
                
                // 计算 UTCT 时间
                long int UTCT_Server = strtol(pUTCTString, NULL, 16);
                long int UTCT_Subscribe = time(NULL) - g_Time_ServerRet + UTCT_Server;
                
                // 格式化 Subscribe 指令
                memset(pSubscribeCmd, 0, LengthForSubscribeCmdMalloc);
                sprintf(pSubscribeCmd, "%sUTCT=0x%lX&", pSubCmd, UTCT_Subscribe);
                if (0 == PrintfFlag++)
                    GLog(tShangYunPush, (@"SubscribeCmd= %s\nSubscribeCmdSize= %lu byte\n\n", pSubscribeCmd, strlen(pSubscribeCmd)));
                
                // 加密 Subscribe 指令
                char AA_enc[SIZE_AA_enc] = {0};
                if (0 > iPN_StringEnc(g_StringEncDecKey, pSubscribeCmd, AA_enc, sizeof(AA_enc)))
                {
                    GLog(tShangYunPush, (@"WiPN_Subscribe - iPN_StringEnc failed!\n"));
                    free((void *)pSubscribeServerDID);
                    free((void *)pSubscribeCmd);
                    free((void *)RecvFromBuf);
                    return WiPN_ERROR_iPNStringEncFailed;
                }
                
                GLog(tShangYunPush, (@"send cmd to SubscribeServer, SubscribeServerDID[%d]= %s. sending...\n", j, &pSubscribeServerDID[index]));
                
                ret = NDT_PPCS_SendTo(&pSubscribeServerDID[index], AA_enc, strlen(AA_enc), g_SendToMode);
                
                if (0 > ret)
                {
                    GLog(tShangYunPush, (@"send cmd to SubscribeServer failed! ret= %d [%s]\n", ret, getErrorCodeInfo(ret)));
                    GLog(tShangYunPush, (@"repet try to send ...\n\n"));
                    continue;
                }
                else
                {
                    GLog(tShangYunPush, (@"send cmd to SubscribeServer success! \n"));
                    SubscribeServerHandle = ret;
                    break;
                }
            }
            if (0 > SubscribeServerHandle)
            {
                GLog(tShangYunPush, (@"WiPN_Subscribe - Get SubscribeServerHandle failed! SubscribeServerDID[%d]= %s. ret= %d [%s]\n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret)));
                break;
            }
        }
        else
        {
            GLog(tShangYunPush, (@"Waiting for SubscribeServer response, please wait ...\n"));
            
            memset(RecvFromBuf, 0, (SizeOfRecvFrom/4+1)*4 );
            ret = NDT_PPCS_RecvFrom(SubscribeServerHandle, RecvFromBuf, &SizeToRead, 30000);
            
            // 记录 recvFrom 返回的当前时间
            time_t Time_ServerRet = time(NULL);
            
            struct timeval tv_currentTime;
            gettimeofday(&tv_currentTime, NULL);
            ptm = localtime((const time_t *)&tv_currentTime.tv_sec);
            
            if (0 > ret)
            {
                if (ptm)
                    GLog(tShangYunPush, (@"WiPN_Subscribe - NDT_PPCS_RecvFrom: SubscribeServerDID[%d]= %s. ret= %d. [%s] [%d-%02d-%02d %02d:%02d:%02d]\n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec));
                else
                    GLog(tShangYunPush, (@"WiPN_Subscribe - NDT_PPCS_RecvFrom: SubscribeServerDID[%d]= %s. ret= %d. [%s] \n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret)));
                
                // -26 -27 -3
                if ((NDT_ERROR_NoAckFromPushServer == ret || NDT_ERROR_NoAckFromDevice == ret || NDT_ERROR_TimeOut == ret) && 3 > repeatTimes_RecvFrom)
                {
                    repeatTimes_RecvFrom++;
                    continue;
                }
                else if (NDT_ERROR_RemoteHandleClosed == ret) // -36
                    GLog(tShangYunPush, (@"WiPN_Subscribe - SubscribeServer already call CloseHandle(). \n"));
                break;
            }
            else
            {
                // 解密接收到的数据
                char AA_dnc[SIZE_AA_dnc] = {0};
                if (0 > iPN_StringDnc(g_StringEncDecKey, RecvFromBuf, AA_dnc, sizeof(AA_dnc)))
                {
                    GLog(tShangYunPush, (@"WiPN_Subscribe - NDT_PPCS_RecvFrom: iPN_StringDnc failed! SubscribeServerDID[%d]= %s.\n", j, &pSubscribeServerDID[index]));
                    ret = WiPN_ERROR_iPNStringDncFailed;
                    break ;
                }
                
                if (ptm)
                    GLog(tShangYunPush, (@"\nFrom SubscribeServer: \nSubscribeServerDID[%d]: %s\nSubscribeServerHandle= %d\nData: %s\nSize: %lu byte\nlocalTime: %d-%02d-%02d %02d:%02d:%02d.%03ld\n\n", j, &pSubscribeServerDID[index], SubscribeServerHandle, AA_dnc, strlen(AA_dnc), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec, (long int)(tv_currentTime.tv_usec / 1000)));
                else
                    GLog(tShangYunPush, (@"\nFrom SubscribeServer: \nSubscribeServerDID[%d]: %s\nSubscribeServerHandle= %d\nData: %s\nSize: %lu byte\n\n", j, &pSubscribeServerDID[index], SubscribeServerHandle, AA_dnc, strlen(AA_dnc)));
                
                if (0 > GetStringItem(AA_dnc, "RET", '&', pRETString, SizeOfRETString))
                {
                    GLog(tShangYunPush, (@"WiPN_Subscribe - Get RETString failed!\n"));
                    ret = WiPN_ERROR_GetRETStringItemFailed;
                    break;
                }
                if (0 > GetStringItem(AA_dnc, "UTCT", '&', pUTCTString, SizeOfUTCTString))
                {
                    GLog(tShangYunPush, (@"WiPN_Subscribe - Get UTCTString failed!\n"));
                    ret =  WiPN_ERROR_GetUTCTStringItemFailed;
                    break;
                }
                else
                {
                    // g_Time_ServerRet 必须要与 UTCTString 时间同步更新
                    g_Time_ServerRet = Time_ServerRet;
                }
                break;
            } // ret > 0
        } // Handle > 0
    } // while (1)
    
    if (0 <= SubscribeServerHandle)
        NDT_PPCS_CloseHandle(SubscribeServerHandle);
    
    free((void *)pSubscribeServerDID);
    free((void *)pSubscribeCmd);
    free((void *)RecvFromBuf);
    
    return ret;
} // WiPN_Subscribe

//// 取消订阅
int WiPN_UnSubscribe(const CHAR *pSubscribeServerString,
                     const CHAR *pSubCmd,
                     CHAR *pRETString,
                     UINT32 SizeOfRETString,
                     CHAR *pUTCTString,
                     UINT32 SizeOfUTCTString)
{
    if (!pSubscribeServerString || !pSubCmd || !pRETString || !pUTCTString )
        return WiPN_ERROR_InvalidParameter;
    if (0 == strlen(pSubscribeServerString) || 0 == strlen(pSubCmd) || 0 == strlen(pUTCTString))
        return WiPN_ERROR_InvalidParameter;
    
    //// -------------------------- 获取 SubscribeServer DID -------------------------
    // 获取 SubscribeServerString 中 SubscribeServer 的个数
    unsigned short NumberOfSubscribeServer = 0;
    unsigned short SizeOfDID = 0;
    if (0 > pharse_number(pSubscribeServerString, &NumberOfSubscribeServer, &SizeOfDID) || 0 == NumberOfSubscribeServer)
        return WiPN_ERROR_GetNumberFromSubscribeServerStringFailed;
    SizeOfDID = (SizeOfDID/4+1)*4; // DID 之间保持足够间隔
    
    // 根据 SubscribeServer DID 的个数分配内存空间
    CHAR *pSubscribeServerDID = (CHAR *)malloc(SizeOfDID*NumberOfSubscribeServer);
    if (!pSubscribeServerDID)
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe - malloc SubscribeServerDID Buf falied!!\n"));
        return WiPN_ERROR_MallocFailed;
    }
    memset(pSubscribeServerDID, '\0', SizeOfDID * NumberOfSubscribeServer );
    
    // 获取 SubscribeServerString 中的 SubscribeServer DID, 并保存
    const CHAR *pDID = NULL;
    int i = 0;
    for (; i < NumberOfSubscribeServer; i++)
    {
        pDID = pharse_DID(pSubscribeServerString, i);
        if (NULL == pDID)
        {
            free((void *)pSubscribeServerDID);
            return WiPN_ERROR_GetDIDFromSubscribeServerStringFailed;
        }
        memcpy(&pSubscribeServerDID[SizeOfDID*i], pDID, strlen(pDID));
        //printf("SubscribeServerDID[%d]= %s\n", i, &pSubscribeServerDID[SizeOfDID*i]);
        free((void*)pDID);
        pDID = NULL;
    }
    
    //// --------------------------- 准备 UnSubscribeCmd ---------------------------
    // 计算 UnSubscribeCmd 指令大小
    unsigned long LengthForUnSubscribeCmd = strlen("UTCT=0x&ACT=UnSubscribe&")+strlen(pSubCmd)+strlen(pUTCTString);
    
    // NDT 一次最大只能发送 1280 字节大小的数据，根据加密算法，加密之前的数据不能超过 630 个字节
    int MaxSizeOfCmd = 630;
    if (MaxSizeOfCmd < LengthForUnSubscribeCmd)
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe - Length Of UnSubscribeCmd is Exceed %d bytes!!\n", MaxSizeOfCmd));
        free((void *)pSubscribeServerDID);
        return WiPN_ERROR_ExceedMaxSize;
    }
    // 分配 UnSubscribeCmd 的内存空间
    unsigned short LengthForUnSubscribeCmdMalloc = (LengthForUnSubscribeCmd/4+1)*4;
    char *pUnSubscribeCmd = (char *)malloc(LengthForUnSubscribeCmdMalloc);
    if (!pUnSubscribeCmd)
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe - malloc UnSubscribeCmd Buf falied!!\n"));
        free((void *)pSubscribeServerDID);
        return WiPN_ERROR_MallocFailed;
    }
    //// ---------------------------------------------------------------------------
    
    int ret = 0;
    int SubscribeServerHandle = -1;
    srand((unsigned int)time(NULL));
    struct tm *ptm = NULL;
    int repeatTimes_RecvFrom = 0;
    unsigned int PrintfFlag = 0;
    
    UINT16 SizeOfRecvFrom = 1280;
    UINT16 SizeForRecvFromMalloc = (SizeOfRecvFrom/4+1)*4;
    char *RecvFromBuf = (char *)malloc(SizeForRecvFromMalloc);
    if (!RecvFromBuf)
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe - malloc RecvFromBuf falied!!\n"));
        free((void *)pSubscribeServerDID);
        free((void *)pUnSubscribeCmd);
        return WiPN_ERROR_MallocFailed;
    }
    memset(RecvFromBuf, 0, SizeForRecvFromMalloc);
    UINT16 SizeToRead = SizeOfRecvFrom;
    
    int index = 0;
    int j = rand() % NumberOfSubscribeServer;
    while (1)
    {
        if (0 > SubscribeServerHandle)
        {
            for (i = 0; i < NumberOfSubscribeServer*2; i++)
            {
                j = (j + 1) % NumberOfSubscribeServer;
                index = SizeOfDID * j;
                
                // 计算 UTCT 时间
                long int UTCT_Server = strtol(pUTCTString, NULL, 16);
                long int UTCT_UnSubscribe = time(NULL) - g_Time_ServerRet + UTCT_Server;
                
                // 格式化 UnSubscribe 指令
                memset(pUnSubscribeCmd, 0, ((LengthForUnSubscribeCmd/4)+1)*4);
                sprintf(pUnSubscribeCmd, "%sUTCT=0x%lX&ACT=UnSubscribe&", pSubCmd, UTCT_UnSubscribe);
                
                if (0 == PrintfFlag++)
                    GLog(tShangYunPush, (@"UnSubscribeCmd= %s\nUnSubscribeCmdSize= %lu byte\n\n", pUnSubscribeCmd, strlen(pUnSubscribeCmd)));
                
                // 加密 UnSubscribe 指令
                char AA_enc[SIZE_AA_enc] = {0};
                if (0 > iPN_StringEnc(g_StringEncDecKey, pUnSubscribeCmd, AA_enc, sizeof(AA_enc)))
                {
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - iPN_StringEnc failed!\n"));
                    free((void *)pSubscribeServerDID);
                    free((void *)pUnSubscribeCmd);
                    free((void *)RecvFromBuf);
                    return WiPN_ERROR_iPNStringEncFailed;
                }
                
                GLog(tShangYunPush, (@"send cmd to SubscribeServer, SubscribeServerDID[%d]= %s. sending...\n", j, &pSubscribeServerDID[index]));
                
                ret = NDT_PPCS_SendTo(&pSubscribeServerDID[index], AA_enc, strlen(AA_enc), g_SendToMode);
                if (0 > ret)
                {
                    GLog(tShangYunPush, (@"send cmd to SubscribeServer failed! ret= %d [%s]\n", ret, getErrorCodeInfo(ret)));
                    GLog(tShangYunPush, (@"repet try to send ...\n\n"));
                    continue;
                }
                else
                {
                    GLog(tShangYunPush, (@"send cmd to SubscribeServer success! \n"));
                    SubscribeServerHandle = ret;
                    break;
                }
            }
            if (0 > SubscribeServerHandle)
            {
                GLog(tShangYunPush, (@"WiPN_UnSubscribe - Get SubscribeServerHandle failed! SubscribeServerDID[%d]= %s. ret= %d [%s]\n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret)));
                break;
            }
        }
        else
        {
            GLog(tShangYunPush, (@"Waiting for SubscribeServer response, please wait ...\n"));
            
            memset(RecvFromBuf, 0, (SizeOfRecvFrom/4+1)*4 );
            ret = NDT_PPCS_RecvFrom(SubscribeServerHandle, RecvFromBuf, &SizeToRead, 30000);
            
            // 记录 recvFrom 返回的当前时间
            time_t Time_ServerRet = time(NULL);
            
            struct timeval tv_currentTime;
            gettimeofday(&tv_currentTime, NULL);
            ptm = localtime((const time_t *)&tv_currentTime.tv_sec);
            
            if (0 > ret)
            {
                if (ptm)
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - NDT_PPCS_RecvFrom: SubscribeServerDID[%d]= %s. ret= %d. [%s] [%d-%02d-%02d %02d:%02d:%02d]\n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec));
                else
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - NDT_PPCS_RecvFrom: SubscribeServerDID[%d]= %s. ret= %d. [%s]\n", j, &pSubscribeServerDID[index], ret, getErrorCodeInfo(ret)));
                
                // -26 -27 -3
                if ((NDT_ERROR_NoAckFromPushServer == ret || NDT_ERROR_NoAckFromDevice == ret || NDT_ERROR_TimeOut == ret) && 3 > repeatTimes_RecvFrom)
                {
                    repeatTimes_RecvFrom++;
                    continue;
                }
                else if (NDT_ERROR_RemoteHandleClosed == ret) // -36
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - SubscribeServer already call CloseHandle(). \n"));
                break;
            }
            else
            {
                // 解密接收到的数据
                char AA_dnc[SIZE_AA_dnc] = {0};
                if (0 > iPN_StringDnc(g_StringEncDecKey, RecvFromBuf, AA_dnc, sizeof(AA_dnc)))
                {
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - NDT_PPCS_RecvFrom: iPN_StringDnc failed! SubscribeServerDID[%d]= %s.\n", j, &pSubscribeServerDID[index]));
                    ret = WiPN_ERROR_iPNStringDncFailed;
                    break ;
                }
                UINT16 AA_dncBufSize = strlen(AA_dnc);
                
                if (ptm)
                    GLog(tShangYunPush, (@"\nFrom SubscribeServer: \nSubscribeServerDID[%d]: %s\nSubscribeServerHandle= %d\nData: %s\nSize: %u byte\nlocalTime: %d-%02d-%02d %02d:%02d:%02d.%03ld\n\n", j, &pSubscribeServerDID[index], SubscribeServerHandle, AA_dnc, AA_dncBufSize, ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec, (long int)(tv_currentTime.tv_usec / 1000)));
                else
                    GLog(tShangYunPush, (@"\nFrom SubscribeServer: \nSubscribeServerDID[%d]: %s\nSubscribeServerHandle= %d\nData: %s\nSize: %u byte\n\n", j, &pSubscribeServerDID[index], SubscribeServerHandle, AA_dnc, AA_dncBufSize));
                
                if (0 > GetStringItem(AA_dnc, "RET", '&', pRETString, SizeOfRETString))
                {
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - Get RETString failed!\n"));
                    ret = WiPN_ERROR_GetRETStringItemFailed;
                    break;
                }
                if (0 > GetStringItem(AA_dnc, "UTCT", '&', pUTCTString, SizeOfUTCTString))
                {
                    GLog(tShangYunPush, (@"WiPN_UnSubscribe - Get UTCTString failed!\n"));
                    ret =  WiPN_ERROR_GetUTCTStringItemFailed;
                    break;
                }
                else
                {
                    // g_Time_ServerRet 必须要与 UTCTString 时间同步更新
                    g_Time_ServerRet = Time_ServerRet;
                }
                
                break;
            } // ret > 0
        } // Handle > 0
    } // while (1)
    
    if (0 <= SubscribeServerHandle)
        NDT_PPCS_CloseHandle(SubscribeServerHandle);
    
    free((void *)pSubscribeServerDID);
    free((void *)pUnSubscribeCmd);
    free((void *)RecvFromBuf);
    
    return ret;
} // WiPN_UnSubscribe
//// --------------------------------- WiPN API End ---------------------------------

// thread for WiPN Subscribe 该线程用于订阅
- (void) thread_WiPN_Subscribe:(id)strDID
{
    // 订阅线程运行标志置 1
    thread_WiPN_Subscribe_Running = 1;
    
    char RETString[SIZE_RETString];
    memset(RETString, 0, sizeof(RETString));
    
    // set Cmd 设置订阅指令
    char SubCmd[SIZE_DID+sizeof(g_EventCH)+sizeof(g_AG_Name)+sizeof(g_APP_Name)+SIZE_DeviceToken] = {0};
    
    int ret = setSubCmd(SubCmd, 		// 存放转换后的订阅指令
                        sizeof(SubCmd), // SubCmd Buf 大小
                        [strDID UTF8String], 	// 设备 DID
                        g_EventCH, 		// 事件通道: 0~0xFFFFFFFF
                        g_AG_Name, 		// 代理名字，如: APNS, XinGe...
                        g_APP_Name, 	// App 名字
                        g_DeviceToken);	// 手机设备唯一的 DeviceToken
    if (0 > ret)
    {
        GLog(tShangYunPush, (@"set SubCmd failed!! ret= %d. [%s]\n", ret, getErrorCodeInfo(ret)));
        return ;
    }
    
    static unsigned long SubscribeCount = 0;
    GLog(tShangYunPush, (@"\nBeing Subscribe...%03lu\n", ++SubscribeCount));
    
    // 开始订阅
    ret = WiPN_Subscribe(g_SubscribeServerString,
                         SubCmd,
                         RETString,
                         sizeof(RETString),
                         g_UTCTString,
                         sizeof(g_UTCTString));
    if (0 > ret)
    {
        GLog(tShangYunPush, (@"thread_WiPN_Subscribe - Subscribe failed! ret= %d [%s]\n", ret, getErrorCodeInfo(ret)));
    }
    else
    {
        time_t ServerTime = strtol(g_UTCTString, NULL, 16);
        struct tm *ptm = localtime((const time_t *)&ServerTime);
        if (!ptm)
        {
            GLog(tShangYunPush, (@"thread_WiPN_Subscribe - RET= %s\nthread_WiPN_Subscribe - UTCT= %s\n", RETString, g_UTCTString));
        }
        else
        {
            GLog(tShangYunPush, (@"thread_WiPN_Subscribe - RET= %s\nthread_WiPN_Subscribe - ServerTime: %d-%02d-%02d %02d:%02d:%02d\n", RETString, ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec));
        }
        
        if (0 == strcmp(RETString, "OK"))
        {
            GLog(tShangYunPush, (@"thread_WiPN_Subscribe - Subscribe success!\n"));
        }
        else
        {
            GLog(tShangYunPush, (@"thread_WiPN_Subscribe - Subscribe failed!\n"));
        }
        GLog(tShangYunPush, (@"-------------------------------------------------------\n\n"));
    }
    thread_WiPN_Subscribe_Running = 0;
}
static ShangYunPushMana *sharedInstance = nil;
+ (ShangYunPushMana *)sharedInstance
{
    static dispatch_once_t onceman;
    dispatch_once(&onceman, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}
- (id)init
{
    if ((self = [super init]))
    {
        // 1. Get NDT Version
        CHAR *API_Description = NDT_PPCS_GetAPIVersion(&g_APIVersion);
        printf("NDT API Version: %d.%d.%d.%d \nAPI Description:%s\n", (g_APIVersion & 0xFF000000) >> 24, (g_APIVersion & 0x00FF0000) >> 16, (g_APIVersion & 0x0000FF00) >> 8, (g_APIVersion & 0x000000FF) >> 0, API_Description );
        
        _APIVersionString = [[NSString alloc] initWithFormat:@"NDT API Version: %d.%d.%d.%d \nAPI Description:%s\n------------------------------------------------\n", (g_APIVersion & 0xFF000000) >> 24, (g_APIVersion & 0x00FF0000) >> 16, (g_APIVersion & 0x0000FF00) >> 8, (g_APIVersion & 0x000000FF) >> 0, API_Description ];
        
         GLog(tShangYunPush, (@"APIVersionString:%@",_APIVersionString));
    }
    
    return self;
}

//- (void)dealloc
//{
//    NDT_PPCS_DeInitialize();
//    g_NDTInitialize = 0;
//    g_startRunningFalg = 0;
//    GLog(tShangYunPush, (@"DeInitialize done!\n"));
//    [super dealloc];
//}
// 开始
- (void) Start:(NSString*)strDID
{
    if (1 == g_startRunningFalg)
        return ;
    
    // 检查并获取参数
    if (![self checkAndSaveInfo])
        return ;
    
    g_startRunningFalg = 1;
    
    int ret;
    UINT16 Port = 0;
    
    // 2. Initialize
    if (0 == g_NDTInitialize) // 初始化标志: 0->未初始化; 1->已初始化
    {
        ret = NDT_PPCS_Initialize(g_InitString, Port, NULL, g_AES128Key);// for Client
        if (0 > ret)
        {
            GLog(tShangYunPush, (@"Initialize ret = %d [%s]\n", ret, getErrorCodeInfo(ret)));
            g_startRunningFalg = 0;
            return ;
        }
        else
        {
            g_NDTInitialize = 1;
            GLog(tShangYunPush, (@"Initialize Success!! ret = %d\n", ret));
        }
    }
    
    // 3. Network Detect 网络侦测
    st_NDT_NetInfo NetInfo;
    NDT_PPCS_NetworkDetect(&NetInfo, 3000); //// wait for 3 sec
    GLog(tShangYunPush, (@"My Lan IP:Port=%s:%d\n", NetInfo.LanIP, NetInfo.LanPort));
    GLog(tShangYunPush, (@"My Wan IP:Port=%s:%d\n", NetInfo.WanIP, NetInfo.WanPort));
    GLog(tShangYunPush, (@"Server Hello Ack: %s\n", 1 == NetInfo.bServerHelloAck ? "Yes":"No"));
    
    if (0 == NetInfo.bServerHelloAck)
    {
        GLog(tShangYunPush, (@"*** Warning!! CS didn't response!! Client from Internet won't be able to send command to Device.\n"));

        NDT_PPCS_DeInitialize();
        g_startRunningFalg = 0;
        g_NDTInitialize = 0;
        return ;
    }
    
    // 4. Do job
    // 离线推送 必须先向 QueryServer 获取 SubscribeServerString 与 UTCTString
    GLog(tShangYunPush, (@"\nBeing Query ...\n"));
    
    // 对于客户端，只需要查询出 SubscribeServerString 就ok, 而 PostServerString 是设备端推送时需要, 若不需要 PostServerString, 传 NULL
    ret = WiPN_Query([strDID UTF8String],
                     g_QueryServerDIDBuf,
                     NULL,   // 若不需要查询 PostServerString, 传 NULL
                     0,
                     g_SubscribeServerString,
                     sizeof(g_SubscribeServerString),
                     g_UTCTString,
                     sizeof(g_UTCTString));
    
    if (0 > ret)
    {
        GLog(tShangYunPush, (@"Get SubscribeServerString failed! ret= %d [%s]\n", ret, getErrorCodeInfo(ret)));

        NDT_PPCS_DeInitialize();
        g_NDTInitialize = 0;
        g_startRunningFalg = 0;
        return ;
    }
    else
    {
        GLog(tShangYunPush, (@"WiPN_Query: SubscribeServerString= %s\nWiPN_Query: UTCTString= %s\n\n", g_SubscribeServerString, g_UTCTString));
    }
}

// 订阅
- (void) Subscribe:(NSString*)strDID
{
    // 收起键盘
    if (0 == g_startRunningFalg)
    {
        [self Start:strDID];
        //GLog(tShangYunPush, (@"请先点击start开始!"));
        //return ;
    }
    // 判断订阅线程是否在运行
    if (thread_WiPN_Subscribe_Running)
        return ;
    
    // 离线推送
    NSThread *pthread_WiPN_Subscribe = [[NSThread alloc] initWithTarget:self
                                                               selector:@selector(thread_WiPN_Subscribe:)
                                                                 object:strDID];
    [pthread_WiPN_Subscribe start];
}

// 取消订阅
- (void) UnSubscribe:(NSString*)strDID
{
    if (0 == g_startRunningFalg)
    {
        GLog(tShangYunPush, (@"请先点击start开始!"));
        return ;
    }
    
    GLog(tShangYunPush, (@"\nBeing UnSubscribe...\n"));
    char RETString[SIZE_RETString];
    memset(RETString, 0, sizeof(RETString));
    
    // set Cmd 设置订阅指令
    char SubCmd[SIZE_DID+sizeof(g_EventCH)+sizeof(g_AG_Name)+sizeof(g_APP_Name)+SIZE_DeviceToken] = {0};
    
    int ret = setSubCmd(SubCmd, 		// 存放转换后的订阅指令
                        sizeof(SubCmd), // SubCmd Buf 大小
                        [strDID UTF8String], 	// 设备 DID
                        g_EventCH, 		// 事件通道: 0~0xFFFFFFFF
                        g_AG_Name, 		// 代理名字，如: APNS, XinGe...
                        g_APP_Name, 	// App 名字
                        g_DeviceToken);	// 手机设备唯一的 DeviceToken
    if (0 > ret)
    {
        GLog(tShangYunPush, (@"set SubCmd failed!! ret= %d. [%s]\n", ret, getErrorCodeInfo(ret)));
        return ;
    }
    
    // 取消订阅
    ret = WiPN_UnSubscribe(g_SubscribeServerString,
                           SubCmd,
                           RETString,
                           sizeof(RETString),
                           g_UTCTString,
                           sizeof(g_UTCTString));
    if (0 > ret)
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe: UnSubscribe failed! ret= %d [%s]\n", ret, getErrorCodeInfo(ret)));
    }
    else
    {
        GLog(tShangYunPush, (@"WiPN_UnSubscribe: RET= %s\nWiPN_UnSubscribe: UTCT= %s\n", RETString, g_UTCTString));
        
        if (0 == strcmp(RETString, "OK"))
        {
            GLog(tShangYunPush, (@"WiPN_UnSubscribe: UnSubscribe success!\n"));
        }
        else
        {
            GLog(tShangYunPush, (@"WiPN_UnSubscribe: UnSubscribe failed!\n"));
        }
    }
    /* 先不要释放
    NDT_PPCS_DeInitialize();
    g_NDTInitialize = 0;
    g_startRunningFalg = 0;
    GLog(tShangYunPush, (@"DeInitialize done!\n"));*/
}
//// -----------------------------------------------------



// 检查输入信息是否正确
- (BOOL) checkAndSaveInfo
{
//    BOOL ret_DID = [_DIDText.text isEqualToString: @""];
    BOOL ret_AES128Key = YES;//[_AES128KeyText.text isEqualToString: @""];
    BOOL ret_InitString = YES;//[_InitStringText.text isEqualToString: @""];
    BOOL ret_SendToMode = YES;//[_SendToModeText.text isEqualToString: @""];
    BOOL ret_EventCH = YES;//[_EventCHText.text isEqualToString: @""];
    
//    if (ret_DID)
//    {
//        printf("DID 不能为空!!\n");
//        [self showAlert:@"提示:" message:@"DID 不能为空!!" time:1.2f];
//        return false;
//    }
    
    // 保存参数
//    strcpy(g_DeviceDID, [[_DIDText text] UTF8String]);
    if (ret_InitString)
        strcpy(g_InitString, g_DefaultInitString);
//    else
//        strcpy(g_InitString, [[_InitStringText text] UTF8String]);
    if (ret_AES128Key)
        strcpy(g_AES128Key, g_DefaultAES128Key);
//    else
//        strcpy(g_AES128Key, [[_AES128KeyText text] UTF8String]);
    
    if (ret_SendToMode)
        g_SendToMode = 1;
//    else
//    {
//        g_SendToMode = [[_SendToModeText text] intValue];
//        if (0 != g_SendToMode && 1 != g_SendToMode && 2 != g_SendToMode)
//        {
//            printf("Mode 只能为 0 ~ 2 \n");
//            [self showAlert:@"提示:" message:@"Mode 只能为 0 ~ 2 " time:1.2f];
//            return false;
//        }
//    }
    if (ret_EventCH)
        g_EventCH = 0;
//    else
//    {
//        g_EventCH = [[_EventCHText text] longLongValue];
//        if (0xFFFFFFFF < g_EventCH)
//        {
//            printf("EventCH: 0 ~ 0xFFFFFFFF (0 ~ 4294967295), 客户端与设备端的 EventCH 必须一致!\n");
//            [self showAlert:@"提示:" message:@"EventCH: 0 ~ 0xFFFFFFFF (0 ~ 4294967295), 客户端与设备端的 EventCH 必须一致!" time:1.2f];
//            return false;
//        }
//    }
//    printf("EventCH= %ld\n", g_EventCH);
    
    // 获取 DeviceToken
    NSUserDefaults *devid_init = [NSUserDefaults standardUserDefaults];
    NSString *devicetoken = [devid_init stringForKey:@"devicetoken"];
    memset(g_DeviceToken, 0, sizeof(g_DeviceToken));
    
    if (devicetoken)
    {
        // 保存 DeviceToken
        strcpy(g_DeviceToken, [devicetoken UTF8String]);
        // 显示 DeviceToken
        GLog(tShangYunPush,(@"DeviceToken= %s\nDeviceTokenSize= %lu byte\n\n", g_DeviceToken, strlen(g_DeviceToken)));
    }
    else
    {
        GLog(tShangYunPush,(@"\nGet DeviceToken falied!!\n\n"));
    }
    
    return true;
}

@end
