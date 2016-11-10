#ifndef _WIPN_ERROR_H_
#define _WIPN_ERROR_H_

//// for WiPN 离线推送的错误返回值
#define WiPN_ERROR_InvalidParameter                 	-1000 // 无效的参数
#define WiPN_ERROR_iPNStringEncFailed               	-1001 // 加密失败
#define WiPN_ERROR_iPNStringDncFailed               	-1002 // 解密失败
#define WiPN_ERROR_GetPostServerStringItemFailed    	-1003 // 截取 PostServerString 失败
#define WiPN_ERROR_GetSubscribeServerStringItemFailed  	-1004 // 截取 SubscribeServerString 失败
#define WiPN_ERROR_GetUTCTStringItemFailed             	-1005 // 截取 UTCTString 失败
#define WiPN_ERROR_GetNumberFromPostServerStringFailed  	-1006 // 从 PostServerString 获取 PostServer 的数量失败
#define WiPN_ERROR_GetNumberFromSubscribeServerStringFailed -1007 // 从 SubscribeServerString 获取 SubscribeServer 的数量失败
#define WiPN_ERROR_GetDIDFromPostServerStringFailed        	-1008 // 从 PostServerString 获取 PostServer 的 DID 失败
#define WiPN_ERROR_GetDIDFromSubscribeServerStringFailed    -1009 // 从 SubscribeServerString 获取 SubscribeServer 的 DID 失败
#define WiPN_ERROR_GetRETStringItemFailed           	-1010 // 截取 RETString 失败
#define WiPN_ERROR_MallocFailed                     	-1011 // 分配内存空间失败
#define WiPN_ERROR_ExceedMaxSize                		-1012 // 超过最大字节大小, 有可能标题、内容或者指令长度超过了限制

//// for WiPN Web API 版离线推送的错误返回值
#define WiPN_ERROR_TimeOut                 				-1013 // 超时
#define WiPN_ERROR_SocketCreateFailed					-1014 // 创建 socket 失败
#define WiPN_ERROR_SocketConnectFailed					-1015 // TCP Connect 失败
#define WiPN_ERROR_InvalidSocketID						-1016 // 无效的 socket 
#define WiPN_ERROR_SetSockOptFailed						-1017 // SetSockOpt 错误 
#define WiPN_ERROR_SocketWriteFailed					-1018 // TCP Write/Send 失败
#define WiPN_ERROR_SocketReadFailed						-1019 // TCP Read/Recv 失败
#define WiPN_ERROR_RemoteSocketClosed					-1020 // 对方关闭了 Socket
#define WiPN_ERROR_SelectError							-1021 // select return -1
#define WiPN_ERROR_GetContentFromHttpRetDataFailed		-1022 // 获取 HTTP Body 数据失败
#define WiPN_ERROR_GetNDTRETItemFailed           		-1023 // 截取 NDTRET 失败

#endif 	// _WIPN_ERROR_H_