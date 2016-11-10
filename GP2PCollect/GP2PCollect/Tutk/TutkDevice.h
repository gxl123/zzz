//
//  TutkDevice.h
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Device.h"

@interface TutkDevice : Device
/*初始化p2psdk*/
//+ (void)initSDK;
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
@end
