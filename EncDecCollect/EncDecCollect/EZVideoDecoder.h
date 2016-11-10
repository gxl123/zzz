//
//  EZVideoDecoder.h
//  DVRLibDemo
//
//  Created by Liu Leon on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavcodec/avcodec.h"
#import <UIKit/UIKit.h>

typedef enum
{
    DEC_OUTPUT_FMT_YUV,
    DEC_OUTPUT_FMT_RGB
} DecoderOutputFormat;

@class MediaFrame;
@interface EZVideoDecoder : NSObject
{
@private
    
    id _delegate;
    dispatch_queue_t _decoderQueue;
    dispatch_queue_t _recvQueue;
    NSMutableData *_inputBuffer;
    NSMutableArray *_frameList;
    
    dispatch_source_t _decodeTimer;
    
    // ffmpeg types
    AVCodec *_pCodec;
    AVPacket _packet;
    AVCodecContext *_pCodecCtx;
    AVFrame *_pFrame;
    
    NSTimeInterval _decodeTimeThreshold; // in ms, default to 50ms
    DecoderOutputFormat _outputFormat; // output picture format
    
    uint32_t _timerFireCount;
    uint32_t _callCount;
    double _totalCost;
    NSTimeInterval _averageCost;   // average time cost of decoding
    
    long _frameIdx;
    uint32_t _bufferSize;
    BOOL _bufferReady;
    BOOL _dropFrameIfNeeded;
    BOOL _shouldDropFrame;
    // for RGBA output
    uint8_t *_rgbBuffer;
    BOOL _isDecoding;
    int _currentpackinsec;
    int _interval;
    long long lastframe;
    //    BOOL needWaiting;
    //    NSLock *videoLock;
    int jumpDoor;
    NSMutableData *yuv;
    NSMutableArray *_bufferArr;
    //    Byte prebyte[3];
    BOOL shouldgo;
    CGContextRef  _imgReg;
    BOOL _isVideo;
    double sleeptime;
    int32_t _duration;
    BOOL _isPause;
    BOOL _isEliminate;
    float _change;
    BOOL _cmdSuccess;
    double _getTimer;
    double _secondTimer;
    double _rendertime;
    BOOL _plus;
    BOOL _isEmpty;
    BOOL _isSnapshot;//是否抓取快照
    NSString *_photoPath;//快照保存路径
    BOOL _shouldSnapThumbnail;//是否抓取缩略图
    NSString *_lastphotoPath;//缩略图保存路径

}

// Note that all the 'getters' are synchronized calls, which will
// be blocking your calling thread until they are done. Use them carefully!
@property (nonatomic) uint32_t bufferSize;
@property (nonatomic) BOOL dropFrameIfNeeded;
@property (nonatomic, assign) id delegate;
@property (nonatomic) int currentpackinsec;
@property (nonatomic) BOOL isPause;
@property (nonatomic) BOOL isEliminate;
@property (nonatomic) float change;
@property (nonatomic) BOOL cmdSuccess;
@property (nonatomic) BOOL plus;
@property (nonatomic) BOOL isEmpty;
- (int)pictureWidth;
- (int)pictureHeight;
-(void)resetLastFrame;

- (id)initWithDelegate:(id)aDelegate decoderQueue:(dispatch_queue_t)dq;

// Set up the decoder with frame rate, you must call this method before
// any subsequent calls of decoding.
- (BOOL)setupDecoder:(NSTimeInterval)interval inputFormat:(int)videoCodec outputFormat:(DecoderOutputFormat)format isVideo:(BOOL)isVideo duration:(int32_t)duration;

// Decode a stream of data which is not delimited as "frame". The decoder
// will decide the frame boundary.
- (void)decodeStreamData:(NSData *)data;

// Decode a frame of data. Decoder will not check the frame boundary.
// Note that the caller shall set the frame index properly if the
// buffer size is set to non-zero. And the I/P frame information
// shall be provided if the dropFrameIfNeeded is set to 'YES'.
- (void)decodeFrame:(MediaFrame *)frame;

// Call this method to release the decoder resources when you are done.
// It is recommended to release the decoder itself instead.
- (void)destroy;
-(void)removeToLastIFrame;
-(void)removeAllFrame;

-(void)snapshot:(NSString*)filePath;//抓取快照
-(void)setThumbnailPath:(NSString*)filePath;//设置缩略图路径
@end


// Note: the delegate methods are ALWAYS called on the main dispatch queue!
@protocol EZVideoDecoderDelegate <NSObject>

@optional
- (void)decoder:(EZVideoDecoder *)decoder didDecodeFrame:(MediaFrame *)frame toYUV:(NSData *)yuv;
- (void)decoder:(EZVideoDecoder *)decoder didDecodeFrame:(MediaFrame *)frame toRGB:(CGImageRef)rgb;
- (void)didEndOfRecord:(EZVideoDecoder *)decoder;
- (void)didTimestamp:(long long)timestamp decoder:(EZVideoDecoder *)decoder didDecodeFrame:(MediaFrame *)frame toYUV:(NSData *)yuv;
- (void)didFrameList:(NSInteger)ListCount;
- (void)didSetCommd;

@end
