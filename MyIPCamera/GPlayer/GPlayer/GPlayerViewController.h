//
//  GPlayerViewController.h
//  MyIPCamera
//
//  Created by gxl on 16/10/24.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol GPlayerDelegate;
@interface GPlayerViewController : UIViewController
@property(nonatomic, retain) id<GPlayerDelegate> callbackDelegate;

-(void)sendVideo:(NSData*)videoData;//开始显示视频
//-(void)stopVideo;//停止显示视频
-(void)sendAudio:(NSData*)audioData;//开始播放音频
//-(void)stopListen;//停止播放音频
//-(void)startSpeak;//开始采集音频
//-(void)stopSpeak;//停止采集音频
-(void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;//设置横屏
-(void)snapshot:(NSString*)strPath;//抓取快照

- (void)setFrame:(CGRect)frame;//设置view尺寸
@end

@protocol GPlayerDelegate <NSObject>
-(void)didStartVideo;
-(void)didStopVideo;
-(void)didStartListen;
-(void)didStopListen;
-(void)didStartSpeak;
-(void)didStopSpeak;
-(void)didReceivedAudioData:(NSData*)audioData;//反馈采集到的音频

@end

