//
//  MediaFrame.h
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MediaFrame : NSObject{
    NSMutableData *_buffer; // when receiving stream, the buffer may contain more than more H264 frame data
    uint32_t _frameLength;
    long  _frameIndex;
    long long _timeStamp;
    
    int   _channel;
    BOOL  _keyFrame;
    BOOL  _isVideo;
    
    int _width;
    int _height;
    NSData *_luma;
    NSData *_chromaB;
    NSData *_chromaR;
}
@property (nonatomic, assign)BOOL isDecoding;
@property (nonatomic, copy) NSMutableData *buffer;
@property (nonatomic) uint32_t frameLength;
@property (nonatomic, assign) long  frameIndex;
@property (nonatomic, assign) int   channel;
@property (nonatomic, assign) long long timestamp;
@property (nonatomic, assign) BOOL  keyFrame;
@property (nonatomic, assign) BOOL  isVideo;
@property (nonatomic) int width;
@property (nonatomic) int height;


- (id)initWithData:(NSData *)data;
- (void)appendData:(NSData *)data;
- (BOOL)isDataReady;
@end
