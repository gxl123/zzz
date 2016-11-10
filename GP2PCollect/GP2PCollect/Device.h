//
//  Device.h
//  GP2PCollect
//
//  Created by gxl on 16/10/25.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Device : NSObject{
    int _deviceId;
    NSString *_name;
    NSString *_address;
    NSUInteger _mediaPort;
    NSString *_userName;
    NSString *_password;
    
    uint8_t _streamType;
    uint8_t _encryptType;
    
    NSString *_companyID;
    NSString *_productID;
    NSString *_deviceName;  // name gotten from server(PU) side
    NSString *_swVersion;
    NSString *_manufactureDate;
    NSString *_ddnsid;
    BOOL _alarmOnGuard;
    BOOL _autoIP;
    int _channelNum;
    BOOL _isCheckCompany;
    //把online socket 改到非主线程中
    dispatch_queue_t _socketconnectQueue;
    // <added by Leo Wan, 01/29/2013>
    NSString *_udid;                // 设备唯一表示ID，用于GooLink注册
    uint32_t _connId;               // GooLink conneciton id
 
    BOOL _isUIDType;                // 是否为UID模式
    BOOL _isUDTConnect;              // 是否是UDT模式
    // </added>
    
    BOOL _trySmallPacket;  // flag used for login with small packets
    BOOL _useOwsp3;   // flag indicating whtether the device support OWSPv3 only
    
    int _currentConnectTag;
    BOOL _isOnLine;
    BOOL _isInIner;
    BOOL _isUPNP;
    NSString *_serverIP;   //当前所在服务器IP
    int _serverPort; //当前所在服务器Port
    int reconUDTTimes;
    NSString *_dstAddress;
    NSString *_srcAddress;
    int _currentConnMode; //当前连接模式 1.内网 2.直连 3.p2p 4.穿透 5.转发
    NSString *_lastAddress; //最后一次连接的address
    int _lastport;   //最后的port
    NSString *_inHourseIpStr;//内网搜索出来的IP和port还有当前的外网地址,用逗号隔开,先不考虑二级路由的情况
    BOOL _isShan;
    BOOL _isConnectSuc;
    int  _connectNum;
    dispatch_queue_t prequeue;
  //  GCDAsyncSocket *onlinesocket;
    int querytime;
    NSURLConnection *authcon;
}
@property (nonatomic, retain) NSString *udid;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *password;
@property (nonatomic) BOOL isOnLine;
@end
