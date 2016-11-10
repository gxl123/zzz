//
//  EZVideoDecoder.m
//  DVRLibDemo
//
//  Created by Liu Leon on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EZVideoDecoder.h"
#import "MediaFrame.h"
#import "EZYuv2RGB.h"
#import <QuartzCore/QuartzCore.h>
//#import "EZApplicationPreference.h"
//#import "Common3.h"
//#import "ToolCommon.h"
//#import "owsp_def_internal.h"
//#import "goolinksleep.h"
#import "iOSLogEngine.h"
#import "GLog.h"
#import "GLogZone.h"
unsigned int g_dwGLogZoneSeed = tAll_MSK;
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640,960), [[UIScreen mainScreen] currentMode].size) : NO)
@interface EZVideoDecoder()

- (BOOL)checkIfDecodingNeeded;

// Decode a frame. Output format is YUV420p.
- (void)decodeOneFrameToYUV;

// Decode a frame. Output format is RGB24.
- (void)decodeOneFrameToRGB;

@end

@implementation EZVideoDecoder

@synthesize dropFrameIfNeeded = _dropFrameIfNeeded;
@synthesize bufferSize = _bufferSize;
@synthesize delegate = _delegate;
@synthesize isPause = _isPause;
@synthesize isEliminate = _isEliminate;
@synthesize change = _change;
@synthesize cmdSuccess = _cmdSuccess;
@synthesize plus = _plus;
@synthesize isEmpty = _isEmpty;
- (id)init
{
    return [self initWithDelegate:nil decoderQueue:NULL];
}

- (id)initWithDelegate:(id)aDelegate decoderQueue:(dispatch_queue_t)dq
{
    if ((self = [super init]))
    {
        _delegate = aDelegate;
        if (dq)
        {
            NSAssert(dq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                     @"The decoder queue must not be a concurrent queue.");
            NSAssert(dq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                     @"The decoder queue must not be a concurrent queue.");
            NSAssert(dq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                     @"The decoder queue must not be a concurrent queue.");
            
            dispatch_retain(dq);
            _decoderQueue = dq;
        }
        else
        {
            const char *aa = [[NSString stringWithFormat:@"com.cn.decoder_%d",rand()%10000] UTF8String];
            _decoderQueue = dispatch_queue_create(aa, NULL);
            //            _decoderQueue = dispatch_get_global_queue(0, 0);
        }
        //         group = dispatch_group_create();
        //         ioQueue = dispatch_queue_create("com.mikeash.imagegcd.io", NULL);
        //        _recvQueue = dispatch_queue_create("com.ezeye.recv", NULL);
        _inputBuffer = [[NSMutableData alloc] init];
        _frameList = [[NSMutableArray alloc] init];
        _bufferArr = [[NSMutableArray alloc] init];
        _decodeTimeThreshold = 50;
        _outputFormat = DEC_OUTPUT_FMT_YUV;
        _callCount = 0;
        _totalCost = 0;
        _averageCost = 0;
        _pCodec = NULL;
        _pCodecCtx = NULL;
        _pFrame = NULL;
        _frameIdx = 1;
        _bufferReady = NO;
        _bufferSize = 0;
        _dropFrameIfNeeded = NO;
        _rgbBuffer = NULL;
        _isDecoding = YES;
        _isPause = NO;
        _isEliminate = NO;
        _change = 1;
        _cmdSuccess = NO;
        _isEmpty = NO;
    }
    
    return self;
}


- (void)dealloc
{
    //    dispatch_block_t block = ^{
    
    [_inputBuffer replaceBytesInRange:NSMakeRange(0, _inputBuffer.length) withBytes:nil length:0];
    [_frameList removeAllObjects];
    //    };
    //
    //    if (dispatch_get_current_queue() == _decoderQueue)
    //    {
    //        block();
    //    }
    //    else
    //    {
    //        dispatch_sync(_decoderQueue, block);
    //    }
    
    [_inputBuffer release];
    _inputBuffer = nil;
    
    [_frameList release];
    _frameList = nil;
    if (_decodeTimer)
    {
        dispatch_source_cancel(_decodeTimer);
        dispatch_release(_decodeTimer);
        _decodeTimer = NULL;
    }
    
    _delegate = nil;
    dispatch_block_t block=^{
        if (_decoderQueue) {
            dispatch_release(_decoderQueue);
        }
        _decoderQueue = NULL;
        
    };
    block();
    

    if (_pCodecCtx != NULL)
    {
        avcodec_close(_pCodecCtx);
        _pCodecCtx = NULL;
    }
    
    if (_pFrame != NULL)
    {
        av_free(_pFrame);
        _pFrame = NULL;
    }
    
    if (_rgbBuffer != NULL)
    {
        free(_rgbBuffer);
        _rgbBuffer = NULL;
    }
    
    if (_bufferArr) {
        [_bufferArr release];
    }
    
    [super dealloc];
}

- (id)delegate
{
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        return _delegate;
    }
    else
    {
        __block id result;
        if (_decoderQueue == NULL) {
            return NULL;
        }
        
        dispatch_sync(_decoderQueue, ^{
            result = _delegate;
        });
        
        return result;
    }
}

- (void)setDelegate:(id)delegate
{
    dispatch_block_t block = ^{
        _delegate = delegate;
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_async(_decoderQueue, block);
    }
}

- (BOOL)dropFrameIfNeeded
{
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        return _dropFrameIfNeeded;
    }
    else
    {
        __block BOOL result;
        dispatch_sync(_decoderQueue, ^{
            result = _dropFrameIfNeeded;
        });
        return result;
    }
}

- (void)setDropFrameIfNeeded:(BOOL)dropFrameIfNeeded
{
    dispatch_block_t block = ^{
        _dropFrameIfNeeded = dropFrameIfNeeded;
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_async(_decoderQueue, block);
    }
}

- (uint32_t)bufferSize
{
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        return _bufferSize;
    }
    else
    {
        __block unsigned int result;
        dispatch_sync(_decoderQueue, ^{
            result = _bufferSize;
        });
        
        return result;
    }
}

- (void)setBufferSize:(uint32_t)bufferSize
{
    dispatch_block_t block = ^{
        _bufferSize = bufferSize;
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_async(_decoderQueue, block);
    }
}

- (int)pictureWidth
{
    __block int ret = 0;
    dispatch_block_t block = ^{
        if (_pCodecCtx)
        {
            ret = _pCodecCtx->width;
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
    return ret;
}

- (int)pictureHeight
{
    __block int ret = 0;
    dispatch_block_t block = ^{
        if (_pCodecCtx)
        {
            ret = _pCodecCtx->height;
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
    return ret;
}

- (BOOL)setupDecoder:(NSTimeInterval)interval inputFormat:(int)videoCodec outputFormat:(DecoderOutputFormat)format isVideo:(BOOL)isVideo duration:(int32_t)duration
{
    _isVideo = isVideo;
    _duration = duration;
    BOOL result = NO;
    //    __block BOOL result = NO;
    //    dispatch_block_t block = ^{
    //EZApplicationPreference *per = [EZApplicationPreference sharedInstance];
    
    @synchronized(self){
        _isDecoding = YES;
        // reset the data
        _decodeTimeThreshold = interval * 1;
        _timerFireCount = 0;
        _callCount = 0;
        _totalCost = 0;
        _averageCost = 0;
        
        _frameIdx = 1;
        _bufferReady = NO;
        _bufferSize = 0;
        _outputFormat = format;
        _interval = interval;
        [_inputBuffer replaceBytesInRange:NSMakeRange(0, _inputBuffer.length) withBytes:nil length:0];
        
        avcodec_register_all();
        // initialize the ffmpeg libraries
        av_register_all();
        //改为每次都alloc packet
        //            av_init_packet(&_packet);
        
        // find the decoder for H264
//        if(videoCodec==CODEC_H265)
//            _pCodec=avcodec_find_decoder(AV_CODEC_ID_HEVC);
//        else
            _pCodec = avcodec_find_decoder_by_name("h264");
        if (_pCodec == NULL)
        {
            GLog(tOther,(@"Can not find H264 decoder."));
            return result;
            //                return;
        }
        
        // allocate the context
        _pCodecCtx = avcodec_alloc_context3(_pCodec);

        if(_pCodec->capabilities&CODEC_CAP_TRUNCATED)
            _pCodecCtx->flags|= CODEC_FLAG_TRUNCATED; // we do not send complete frames
        if (_pCodecCtx == NULL)
        {
            GLog(tOther,(@"Can not create codec context."));
            //                return;
            return result;
        }
        
        // open codec

        
        if(avcodec_open2(_pCodecCtx, _pCodec, NULL)<0){
            GLog(tOther,(@"Can not open codec."));
            return result;
            //                return;
        }

        
        // allocate frame
        //            _pFrame = avcodec_alloc_frame();
        //            if (_pFrame == NULL)
        //            {
        //                GLog(tOther,(@"Can not allocate frame"));
        ////                return;
        //                return result;
        //
        //            }
        
        
        
        //        _pCodecCtx->flags |= CODEC_FLAG_EMU_EDGE | CODEC_FLAG_LOW_DELAY;
        //        _pCodecCtx->debug |= FF_DEBUG_MMCO;
        _pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
        _decodeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _decoderQueue);
        //        dispatch_source_set_timer(_decodeTimer, DISPATCH_TIME_NOW, 1, 1);
        if (isVideo) {
            if (isRetina) {
                dispatch_source_set_timer(_decodeTimer, DISPATCH_TIME_NOW, 1000000, 0);
            }else{
                dispatch_source_set_timer(_decodeTimer, DISPATCH_TIME_NOW, 1000000, 0);
            }
        } else{
            if (isRetina) {
                dispatch_source_set_timer(_decodeTimer, DISPATCH_TIME_NOW, (interval-5)*1000000, 0);
            }else{
                dispatch_source_set_timer(_decodeTimer, DISPATCH_TIME_NOW, (interval)*1000000, 0);
            }
        }
        
        _bufferSize = 0;
        jumpDoor = 10*(1000/interval)+_bufferSize;
        int smallbuffer = 3*(1000/interval);
//        GLog(tOther,(@"jumpDoor1==%d,1000/interval=%f",jumpDoor,1000/interval));
        
//        if ([[EZApplicationPreference sharedInstance] livePreference] == VideoPreferenceRealtime) {
//            jumpDoor =  4*2*(1000/interval)+_bufferSize;
////            GLog(tOther,(@"jumpDoor2==%d,1000/interval=%f",jumpDoor,1000/interval));
//        }
        //        __block id unretainedSelf = self;
        
        if (_outputFormat == DEC_OUTPUT_FMT_YUV)
        {
            dispatch_source_set_event_handler(_decodeTimer, ^{
                if (_isDecoding) {
                    //                        GLog(tOther,(@"_framelist==%d",_frameList.count));
//                    if ([per livePreference] != VideoPreferenceRealtime){
//                        if (_frameList.count>smallbuffer) {
//                            shouldgo = YES;
//                        }else{
//                            if (_frameList.count == 0) {
//                                shouldgo = NO;
//                                if (_delegate) {
//                                    if (self.delegate && [self.delegate respondsToSelector:@selector(didSetCommd:)]) {
//                                        [self.delegate didSetCommd];
//                                    }
//                                }
//                            }
//                        }
//                        if (isVideo) {
//                            //                            GLog(tOther,(@"_duration = %d",duration));
//                            //                            if (duration <25*8) {
//                            if (shouldgo == NO) {
//                                GLog(tVideoShow,(@"没满5s,count=%d",_frameList.count));
//                                
//                                
//                                return;
//                            }
//                            //                            }
//                            
//                        }
//                        
//                    }
                    if (isVideo) {
                        if (_frameList.count == 0) {
                            //                                [self decodeOneFrameToYUV];
                            //                            MediaFrame *frame = [[self getFirstFrame] copy];
                            shouldgo = NO;
                            //                            if (!_isPause) {
                            //                                //                                if (_isEliminate && _cmdSuccess) {
                            //                                //                                    [self removeAllFrame];
                            //                                //                                }
                            //                                if (!_isEmpty) {
                            //                                    GLog(tOther,(@"切换 ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝1"));
                            //                                    [self decodeOneFrameToYUV];
                            //                                }
                            //                                else
                            //                                {
                            //                                    [self removeAllFrame];
                            //                                     GLog(tOther,(@"切换 ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝2"));
                            //                                }
                            //                            } else
                            //                            {
                            //                                if (_isEmpty) {
                            //                                    [self removeAllFrame];
                            //                                }
                            //                            }
                            
                            
                            //                            if (self.delegate && [self.delegate respondsToSelector:@selector(didEndOfRecord:)]) {
                            //                                [self.delegate didEndOfRecord:self];
                            //                            }
                            //
                            //                            return;
                        }
                    }
                    
                    if (isVideo) {
                        if (_duration > 25*2) {
                            if (_frameList.count>25*2) {
                                shouldgo = YES;
                            }else{
                                if (_frameList.count == 0) {
                                    shouldgo = NO;
                                }
                            }
                        }
                    }
                    
                    
                    if (isVideo) {
                        //                        if (shouldgo == NO) {
                        //                            GLog(tOther,(@"_duration = %d",duration));
                        if (shouldgo == NO)
                        {   if (_frameList.count > 25*2)
                        {
                            GLog(tVideoShow,(@"没满3s,count=%d",_frameList.count));
                            //return;//此代码会导致无法正常解码
                        }
                            
                        }
                        //                        }
                        
                    }
                    if (isVideo) {
                        if (!_isPause) {
                            //                            if (_isEliminate && _cmdSuccess) {
                            //                                [self removeAllFrame];
                            //                            }
                            if (!_isEmpty) {
                                [self decodeOneFrameToYUV];
                                
                            }
                            else
                            {
                                
                                [self removeAllFrame];
                            }
                            
                        }
                        else
                        {
                            if(_isEmpty)
                            {
                                [self removeAllFrame];
                            }
                        }
                    }
                    else
                    {
                        if (_frameList.count>jumpDoor) {
//                            GLog(tOther,(@"jumpdoor-------%d===%d",_frameList.count,jumpDoor));
                            //                        usleep(_interval*1000);
                            //                        if (_frameList.count>jumpDoor*2) {
                            //                            [self removeToLastIIFrame];
                            //                        }else{
                            dispatch_block_t block =^{
                                [self removeToLastIFrame];
                                @synchronized(self){
                                    [self decodeOneFrameToYUV];
                                }
                            };
                            block();
                            //                        }
                            
                        }else{
                            //edit by kelven 2014.02.21
                            dispatch_block_t block =^{
                                //                                @synchronized(per){
                                [self decodeOneFrameToYUV];
                                //                                }
                            };
                            block();
                        }
                        
                    }
                    
                }
                //                }
            });
            //            [self begindecode];
        }
        else
        {
            [EZYuv2RGB setupDitherTable];
            
            
            dispatch_source_set_event_handler(_decodeTimer, ^{
                //                [self decodeOneFrameToRGB];
                if (_frameList.count>jumpDoor) {
//                    GLog(tOther,(@"jumpdoor-------%d===%d",_frameList.count,jumpDoor));
                    //                        usleep(_interval*1000);
                    //                        if (_frameList.count>jumpDoor*2) {
                    //                            [self removeToLastIIFrame];
                    //                        }else{
                    dispatch_block_t block =^{
                        [self removeToLastIFrame];
                        @synchronized(self){
                            [self decodeOneFrameToRGB];
                        }
                    };
                    block();
                    //                        }
                    
                }else{
                    //edit by kelven 2014.02.21
                    dispatch_block_t block =^{
                        //                                @synchronized(per){
                        [self decodeOneFrameToRGB];
                        //                                }
                    };
                    block();
                }
                
            });
        }
        dispatch_source_set_cancel_handler(_decodeTimer,^{});
        dispatch_resume(_decodeTimer);
        
        
        result = YES;
    }
    
    return result;
}



-(void)removeToLastIIFrame{
    if (!_decoderQueue) {
        return;
    }
    dispatch_block_t block = ^{
        @synchronized(self){
            for (int i = _frameList.count-1; i>=0; i--) {
                MediaFrame *frame = [_frameList objectAtIndex:i];
                if (!frame.keyFrame) {
                    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                    [_frameList removeObjectAtIndex:i];
                    [pool release];
                }
            }
            for (int i = _frameList.count-2; i>=0; i--) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                [_frameList removeObjectAtIndex:i];
                [pool release];
            }
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            
            [_inputBuffer replaceBytesInRange:NSMakeRange(0, _inputBuffer.length) withBytes:nil length:0];
            [pool release];
            
            
            //            GLog(tOther,(@"_framelist===%d",_frameList.count));
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
}

- (void)destroy
{
    _isDecoding = NO;
    _interval = 0;
    _shouldDropFrame = NO;
    
    //    dispatch_block_t block = ^{
    //EZApplicationPreference *per = [EZApplicationPreference sharedInstance];
    @synchronized(self){
        if (_decodeTimer)
        {
            dispatch_source_cancel(_decodeTimer);
            dispatch_release(_decodeTimer);
            _decodeTimer = NULL;
        }
        
        [_inputBuffer setLength:0];
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [yuv replaceBytesInRange:NSMakeRange(0, yuv.length) withBytes:nil length:0];
        [pool release];
        // free the YUV frame
        if (_pFrame)
        {
            av_free(_pFrame);
            _pFrame = NULL;
        }
        
        // close the codec context
        
        if (_pCodecCtx)
        {
            avcodec_close(_pCodecCtx);
            av_free(_pCodecCtx);
            _pCodecCtx = NULL;
        }
        
        _pCodec = NULL;
        
        _decodeTimeThreshold = 50;
        _callCount = 0;
        _totalCost = 0;
        _averageCost = 0;
        
        _frameIdx = 1;
        _dropFrameIfNeeded = NO;
        _bufferReady = NO;
        lastframe = 0;
        if (_rgbBuffer)
        {
            free(_rgbBuffer);
            _rgbBuffer = NULL;
        }
        //        if(_decoderQueue){
        //
        //
        //            dispatch_release(_decoderQueue);
        //        }
        //        _decoderQueue = NULL;
    }
    //    };
    //
    //    if (dispatch_get_current_queue() == _decoderQueue)
    //    {
    //        block();
    //    }
    //    else
    //    {
    //        dispatch_sync(_decoderQueue, block);
    //    }
}

NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    //    GLog(tOther,(@"width=%d,height=%d",width,height));
    width = MIN(linesize, width);
    //    NSMutableData *aa = [[NSMutableData alloc] initWithBytes:src length:width * height-10000];
    //    //    GLog(tOther,(@"aa===%d",aa.length));
    //    [aa release];
    NSMutableData *md = [[NSMutableData alloc] initWithLength: width * height];
    Byte *dst = md.mutableBytes;
    //    GLog(tOther,(@"strlensrc===%lu",strlen((const char*)src)));
    for (NSUInteger i = 0; i < height; i++) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}


- (uint32_t)findFrame:(unsigned char *)stream streamLen:(int)streamLen isKeyFrame:(BOOL *)keyFrame
{
    uint32_t state = 0xFFFFFFFF;
    uint32_t frameLength = 0;
    BOOL frameStartFound = NO;
    
    for (int i = 0; i < streamLen; i++)
    {
        // find the NALU with type 1 and 5
        if (((state & 0xFFFFFF1F) == 0x101) || ((state & 0xFFFFFF1F) == 0x105))
        {
            // find the slice header which has first_mb_slice equal to 0
            if (stream[i] & 0x80)
            {
                if (frameStartFound)
                {
                    // We have found the next frame start.
                    // Now we can calculate the current frame length and return.
                    frameLength = i - 4;
                    break;
                }
                else
                {
                    // this is the current frame's start
                    frameStartFound = YES;
                    
                    if ((state & 0xFFFFFF1F) == 0x105)
                    {
                        *keyFrame = YES;
                    }
                    else
                    {
                        *keyFrame = NO;
                    }
                }
            }
        }
        
        // shift to the next byte
        state = (state << 8) | stream[i];
    }
    
    return frameLength;
}

- (BOOL)checkIfDecodingNeeded
{
    BOOL ret = YES;
    int frameCount = [_frameList count];
    
    if (frameCount > 0)
    {
        // increase the timer fire count first
        //        _timerFireCount++;
        
        // check if buffering is needed
        // check if buffering is done
        if (!_bufferReady)
        {
            if (frameCount >= _bufferSize)
            {
                _bufferReady = YES;
            }
            else if ((_timerFireCount % 4) != 0)
            {
                ret = NO;
            }
        }
        
        // check if dropping frame is needed
        MediaFrame *frame = [_frameList objectAtIndex:0];
        if (_dropFrameIfNeeded && (_averageCost > _decodeTimeThreshold) && !frame.keyFrame)
        {
            GLog(tOther,(@"dropped one frame"));
            // drop one frame
            //            [_frameList removeObjectAtIndex:0];
            [self removeFirstFrame];
            ret = NO;
        }
    }
    else
    {
        _bufferReady = NO;
        ret = NO;
    }
    
    return ret;
}

-(void)resetLastFrame{
    dispatch_block_t block = ^{
        lastframe = 0;
    };
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
}

- (void)decodeOneFrameToYUV
{
    
    NSAutoreleasePool *drawpool = [[NSAutoreleasePool alloc] init];
    
    _callCount++;
    
//    GLog(tOther,(@"framelist================================%d",_frameList.count));
    
    if (![self getFirstFrame] ) {
        //        GLog(tOther,(@"no frame"));
        [drawpool drain];
        //        [videoLock unlock];
        usleep(100*1000);
        return;
    }
    
    
    
    MediaFrame *frame = [[self getFirstFrame] copy];
    
    MediaFrame *secondFrame = [self getSecondFrame];
    [self removeFirstFrame];
    if (_isVideo) {
        
        sleeptime = (secondFrame.timestamp - frame.timestamp);
    }
    
    
    //    if (_shouldDropFrame && !frame.keyFrame) {
    //        GLog(tOther,(@"丢帧---%ld,framekey==%d",frame.frameIndex,frame.keyFrame));
    //        [frame release];
    //        [drawpool release];
    //        return;
    //    }
    //    GLog(tOther,(@"frame=========timestame===%lld",frame.timestamp));
    AVFrame *_pFrametest = av_frame_alloc();//avcodec_alloc_frame();
    AVPacket pkt, *packettest = &pkt;
    int size = [[frame buffer] length];
    av_new_packet(packettest,size);
    
    if (packettest==NULL) {
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    memcpy(packettest->data,(uint8_t *)[[frame buffer] bytes], size);
    //    packettest->size = [[frame buffer] length];
    //    GLog(tOther,(@"_packet.size ==%d",_packet.size));
    // start benchmark
    if (_pCodecCtx==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    if (_pFrametest==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    int gotten = 0;
    double cost = CACurrentMediaTime() * 1000;
    //    EZApplicationPreference *per = [EZApplicationPreference sharedInstance];
    //加上全局锁
    int dec = 0;
    
    //    GLog(tOther,(@"framelength---%u,framekey==%d,framelength---%d",frame.frameLength,frame.keyFrame,frame.buffer.length));
    //    @synchronized(per){
    if (_pCodecCtx)
        dec = avcodec_decode_video2(_pCodecCtx, _pFrametest, &gotten, packettest);
    else{
        GLog(tDecode_MSK, (@"异常_pCodecCtx==NULL"));
        return;
    }
    //    }
    cost = CACurrentMediaTime() * 1000-cost;
    //    if (cost>30) {
    //        GLog(tOther,(@"cost>30====%f",cost));
    //
    //    }else{
    //        GLog(tOther,(@"cost====%f",cost));
    //    }
    av_free_packet(packettest);
    packettest = NULL;
    
    if (dec<=0) {
        GLog(tOther,(@"gotten=%d,dec=%d",gotten,dec));
    }
    
    if (gotten && dec > 0)
    {
        if (_shouldDropFrame && !frame.keyFrame) {
            GLog(tAudioDecode,(@"丢帧---"));
            GLog(tOther,(@"frame.stamp %lld",frame.timestamp));
            int h2 = _pCodecCtx->height;
            frame.width = _pCodecCtx->width;
            frame.height = h2;
            NSData *dataY2 = copyFrameData(_pFrametest->data[0], _pFrametest->linesize[0], _pCodecCtx->width, h2);
            NSMutableData *yuv2 = [[NSMutableData alloc] initWithData:dataY2];
            if (self.delegate && [self.delegate respondsToSelector:@selector(didTimestamp:decoder:didDecodeFrame:toYUV:)]) {
                [self.delegate didTimestamp:frame.timestamp decoder:self didDecodeFrame:frame toYUV:yuv2];
                [yuv2 release];
                yuv2 = nil;
            }
            //            [self removeFirstFrame];
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            
            return;
        }
        _shouldDropFrame = NO;
        if (_pFrametest->data[1]==NULL) {
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            return;
        }
        if (_pFrametest->data[2]==NULL) {
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            return;
        }
        //解决看某些设备，切换高清流畅卡死的问题
        int h = MIN(_pCodecCtx->height,_pFrametest->height);
        frame.width = _pCodecCtx->width;
        frame.height = h;
        //GLog(tOther,(@"src=%d*%d,dest=%d*%d",_pFrametest->width,_pFrametest->height,_pCodecCtx->width,_pCodecCtx->height));
        NSData *dataY = copyFrameData(_pFrametest->data[0], _pFrametest->linesize[0], _pCodecCtx->width, h);
        NSData *dataU = copyFrameData(_pFrametest->data[1], _pFrametest->linesize[1], _pCodecCtx->width / 2, h / 2);
        NSData *dataV = copyFrameData(_pFrametest->data[2], _pFrametest->linesize[2],_pCodecCtx->width / 2, h / 2);
        
        //        NSData *dataY = [[NSMutableData alloc] initWithBytes:_pFrametest->data[0] length:_pFrametest->linesize[0]*h];
        //        NSData *dataU = [[NSMutableData alloc] initWithBytes:_pFrametest->data[1] length:_pFrametest->linesize[1]*h/2];
        //        NSData *dataV = [[NSMutableData alloc] initWithBytes:_pFrametest->data[2] length:_pFrametest->linesize[2]*h/2];
        
        //////保存快照 begin//////////////////////////////////////
        if(_isSnapshot||_shouldSnapThumbnail){
            //yuv->rgb
            AVPicture tPicture;
            // Allocate RGB picture
            avpicture_alloc(&tPicture, AV_PIX_FMT_RGB24,_pCodecCtx->width, _pCodecCtx->height);
            AVFrame *tpFrame=_pFrametest;//(AVFrame*)inData;
            AVPicture *tpPicture=&tPicture;//=(AVPicture*)outData;
            enum AVPixelFormat srcFormat=_pCodecCtx->pix_fmt;//一般是PIX_FMT_YUV420P
            enum AVPixelFormat dstFormat = AV_PIX_FMT_RGB24;//RGBA与RGB24区别是？必须用RGB24,如果用RGBA图片会出现竖条纹
            int dstW=_pCodecCtx->width;//暂时固定，由UI层下发
            int dstH=_pCodecCtx->height;//暂时固定，由UI层下发
            int flags=SWS_BICUBLIN;//SWS_FAST_BILINEAR;//转换算法，还有很多种都有何区别？
            
            
            CVPixelBufferPoolRef pixelBufferPool;
            CVPixelBufferRef pixelBuffer;
            
            NSMutableDictionary* attributes;
            attributes = [NSMutableDictionary dictionary];
            [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
            [attributes setObject:[NSNumber numberWithInt:1920] forKey: (NSString*)kCVPixelBufferWidthKey];
            [attributes setObject:[NSNumber numberWithInt:1080] forKey: (NSString*)kCVPixelBufferHeightKey];
            
            CVReturn err = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &pixelBufferPool);
            if( err != kCVReturnSuccess ) {
                // GLog(tOther,( @"onSnapshot -- pixelBufferPool create failed!"));
            }
            err = CVPixelBufferPoolCreatePixelBuffer (NULL, pixelBufferPool, &pixelBuffer);
            if( err != kCVReturnSuccess ) {
                //GLog(tOther,(@"onSnapshot -- pixelBuffer create failed!"));
            }
            struct SwsContext *c=sws_getContext(_pCodecCtx->width, _pCodecCtx->height, srcFormat,
                                                dstW, dstH, dstFormat,
                                                flags, NULL, NULL, NULL);
            //GLog(tOther,(@"sws_getContext s_w=%d,s_h=%d,s_f=%d,d_w=%d,d_h=%d,d_f=%d",_pCodecCtx->width, _pCodecCtx->height, srcFormat,dstW, dstH, dstFormat));
            const uint8_t *const *srcSlice=(const uint8_t *const *)tpFrame->data;
            const int *srcStride=tpFrame->linesize;
            int srcSliceY=0;
            int srcSliceH=_pCodecCtx->height;
            uint8_t *const *dst=(uint8_t *const *)tpPicture->data;
            const int *dstStride=tpPicture->linesize;
            
            int result=sws_scale(c, srcSlice, srcStride, srcSliceY, srcSliceH, dst, dstStride);
            
            //rgb->image
            UIImage *pImg_=[self imageFromAVPicture:*tpPicture width:dstW height:dstH];
            
            //image保存图片
            if(_shouldSnapThumbnail){
                [self saveImageToFile:pImg_ :_lastphotoPath];
                _shouldSnapThumbnail=!_shouldSnapThumbnail;
            } 
            else{
                [self saveImageToFile:pImg_ :_photoPath];
                _isSnapshot=!_isSnapshot;
            }
            //GLog(tOther,(@"result=%d;c=%d,s1=%d,s2=%d,sY=%d,sH=%d;d1=%d,d2=%d",result,c,srcSlice,srcStride,srcSliceY, srcSliceH, dst, dstStride));
            CVPixelBufferRelease(pixelBuffer);
            CVPixelBufferPoolRelease(pixelBufferPool);
            sws_freeContext(c);
            avpicture_free(&tPicture);
        }
        //////保存快照  end///////////////////////////////////////

        NSMutableData *yuv1 = [[NSMutableData alloc] initWithData:dataY];
        [yuv1 appendData:dataU];
        [yuv1 appendData:dataV];
        [dataY release];
        [dataV release];
        [dataU release];
        dataY = nil;
        dataV = nil;
        dataU = nil;
        av_free(_pFrametest);
        _pFrametest = NULL;
        
        
        if (_delegate && [_delegate respondsToSelector:@selector(decoder:didDecodeFrame:toYUV:)])
        {
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *drawpool1 = [[NSAutoreleasePool alloc] init];
            if (_isVideo) {
                //                GLog(tOther,(@"sleep=%f,cost=%f",sleeptime,cost));
                if (self.delegate && [self.delegate respondsToSelector:@selector(didFrameList:)]) {
                    [self.delegate didFrameList:_frameList.count];
                }
                
                
                
                
                //                if (sleeptime - cost >0) {
                //                    usleep((sleeptime-cost)*1000);
                //                }
                double ceo = CACurrentMediaTime()*1000;
                //                _secondTimer = ceo;
                //                GLog(tOther,(@"解码相差=%f,sleetime＝%f,减= %f",(_secondTimer-_getTimer),sleeptime,(sleeptime-(_secondTimer-_getTimer))));
                //                GLog(tOther,(@"ceo======================%f",ceo-_getTimer));
                double shouldsleeptime = (sleeptime - (ceo - _getTimer));
                double shouSleeptimer;
                if (shouldsleeptime>0 && shouldsleeptime<200) {
                    if (_plus) {
                        usleep((shouldsleeptime*1000)/_change);
                        shouSleeptimer = ((shouldsleeptime*1000)/_change);
                    }else
                    {
                        usleep((shouldsleeptime*1000)*_change);
                        shouSleeptimer = ((shouldsleeptime*1000)*_change);
                    }
                    GLog(tOther,(@"usleep ===== %f",shouSleeptimer));
                    //                    _getTimer = ceo;
                } else {
                    GLog(tOther,(@"No sleep!"));
                }
                
                _getTimer = CACurrentMediaTime()*1000;
                
                //                GLog(tOther,(@"shouldseeptime1111 = =%f",shouldsleeptime));
                
            }
            
            //            GLog(tOther,(@"ceo2 ==============================%f",ceo2-_getTimer));
            if (_delegate && [_delegate respondsToSelector:@selector(decoder:didDecodeFrame:toYUV:)]) {
                [_delegate decoder:self didDecodeFrame:frame toYUV:yuv1];
            }
            
            
            //            GLog(tOther,(@"画了keyframe===%d,frame.frameindex==%ld,goten=%d,time=%lld",frame.keyFrame,frame.frameIndex,gotten,frame.timestamp));
            if (frame.frameIndex-lastframe>1) {
//                GLog(tOther,(@"帧不对了"));
            }
            lastframe = frame.frameIndex;
            [yuv1 release];
            [frame release];
            yuv1 = nil;
            [drawpool1 release];
            //            _rendertime = CACurrentMediaTime()*1000 -ceo2;
            //            GLog(tOther,(@"rende/rtime ====%f",_rendertime));
            //            });
            
        }
        //[self removeFirstFrame];
    }else{
        //        if (gotten<0) {
        _shouldDropFrame = YES;
        //[self removeFirstFrame];
        
        //        [self removetoNextIFrame];
        //        }
    }
    [drawpool drain];
    
}
-(void)setThumbnailPath:(NSString*)filePath{
     _lastphotoPath=[[NSString alloc]initWithString:filePath];
    _shouldSnapThumbnail = YES;
}
-(void)snapshot:(NSString*)filePath{
    _isSnapshot=YES;
    _photoPath=[[NSString alloc]initWithString:filePath];//[NSString stringWithString:filePath];
}
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);//CGDataProviderCreateWithData(NULL, pict.data[0], width * height * 3, NULL);//
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],//-》是640*3吗？
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,//true,//
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}
- (void)saveImageToFile:(UIImage *)image :(NSString *)imgFullName {
    NSData *imgData = UIImagePNGRepresentation(image);
    [imgData writeToFile:imgFullName atomically:YES];
}

- (void)decodeOneFrameToYUV1
{
    NSAutoreleasePool *drawpool = [[NSAutoreleasePool alloc] init];
    
    _callCount++;
    
    
    
    if (![self getFirstFrame] ) {
        //        GLog(tOther,(@"no frame"));
        [drawpool drain];
        //        [videoLock unlock];
        usleep(10*1000);
        return;
    }
    
    
    MediaFrame *frame = [[self getFirstFrame] copy];
    [self removeFirstFrame];
    AVFrame *_pFrametest = av_frame_alloc();//avcodec_alloc_frame();
    AVPacket pkt, *packettest = &pkt;
    int size = [[frame buffer] length];
    av_new_packet(packettest,size);
    
    if (packettest==NULL) {
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    if (frame.frameIndex <= lastframe && frame.frameIndex != 0 && !frame.keyFrame) {
        GLog(tOther,(@"lastframe==%lld,index=%ld",lastframe, frame.frameIndex));
        //[self removeFirstFrame];
        _shouldDropFrame = YES;
        [frame release];
        [drawpool drain];
        return;
    }else{
        _shouldDropFrame = NO;
    }
    
    memcpy(packettest->data,(uint8_t *)[[frame buffer] bytes], size);
    
    if (_pCodecCtx==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    if (_pFrametest==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    int gotten = 0;
    //加上全局锁
    int dec = 0;
    
    //    GLog(tOther,(@"framelength---%u,framekey==%d,framelength---%d",frame.frameLength,frame.keyFrame,frame.buffer.length));
    //    @synchronized(per){
    dec = avcodec_decode_video2(_pCodecCtx, _pFrametest, &gotten, packettest);
    //    }
    av_free_packet(packettest);
    packettest = NULL;
    
    if (dec<=0) {
        GLog(tOther,(@"gotten=%d,dec=%d",gotten,dec));
    }
    
    if (gotten && dec > 0)
    {
        if (_shouldDropFrame && !frame.keyFrame) {
            //            GLog(tOther,(@"丢帧---"));
            [self removeFirstFrame];
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            
            return;
        }
        _shouldDropFrame = NO;
        if (_pFrametest->data[1]==NULL) {
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            return;
        }
        if (_pFrametest->data[2]==NULL) {
            av_free(_pFrametest);
            _pFrametest = NULL;
            [drawpool drain];
            return;
        }
        
        int h = _pCodecCtx->height;
        frame.width = _pCodecCtx->width;
        frame.height = h;
        //        GLog(tOther,(@"dec=%d,size=%d",dec,size));
        NSData *dataY = copyFrameData(_pFrametest->data[0], _pFrametest->linesize[0], _pCodecCtx->width, h);
        NSData *dataU = copyFrameData(_pFrametest->data[1], _pFrametest->linesize[1], _pCodecCtx->width / 2, h / 2);
        NSData *dataV = copyFrameData(_pFrametest->data[2], _pFrametest->linesize[2],_pCodecCtx->width / 2, h / 2);
        
        //        NSData *dataY = [[NSMutableData alloc] initWithBytes:_pFrametest->data[0] length:_pFrametest->linesize[0]*h];
        //        NSData *dataU = [[NSMutableData alloc] initWithBytes:_pFrametest->data[1] length:_pFrametest->linesize[1]*h/2];
        //        NSData *dataV = [[NSMutableData alloc] initWithBytes:_pFrametest->data[2] length:_pFrametest->linesize[2]*h/2];
        if (!yuv) {
            yuv = [[NSMutableData alloc] init];
        }
        [yuv setData:nil];
        [yuv appendData:dataY];
        [yuv appendData:dataU];
        [yuv appendData:dataV];
        [dataY release];
        [dataV release];
        [dataU release];
        dataY = nil;
        dataV = nil;
        dataU = nil;
        av_free(_pFrametest);
        _pFrametest = NULL;
        if (_delegate && [_delegate respondsToSelector:@selector(decoder:didDecodeFrame:toYUV:)])
        {
            
            //            dispatch_async(dispatch_get_main_queue(), ^{
            NSAutoreleasePool *drawpool1 = [[NSAutoreleasePool alloc] init];
            if (frame.frameIndex <= lastframe && lastframe != 0) {
//                GLog(tOther,(@"帧不对了111,frame.frameindex=%ld,lastframe=%lld",frame.frameIndex,lastframe));
                
            }else{
                
                [_delegate decoder:self didDecodeFrame:frame toYUV:yuv];
                
                //            GLog(tOther,(@"画了keyframe===%d,frame.frameindex==%ld,goten=%d,time=%lld",frame.keyFrame,frame.frameIndex,gotten,frame.timestamp));
            }
            if (frame.frameIndex-lastframe>1) {
                //                GLog(tOther,(@"帧不对了"));
            }
            lastframe = frame.frameIndex;
            [frame release];
            [drawpool1 release];
            
            //            });
            
        }
        //[self removeFirstFrame];
    }else{
        //        if (gotten<0) {
        _shouldDropFrame = YES;
        //[self removeFirstFrame];
        
        //        [self removetoNextIFrame];
        //        }
    }
    [drawpool drain];
    
}

- (void)decodeOneFrameToRGB
{
    NSAutoreleasePool *drawpool = [[NSAutoreleasePool alloc] init];
    
    if (![self getFirstFrame] ) {
        //        GLog(tOther,(@"no frame"));
        [drawpool drain];
        //        [videoLock unlock];
        usleep(10*1000);
        return;
    }
    
    MediaFrame *frame = [[self getFirstFrame] copy];
    [self removeFirstFrame];
    
    //    if (_shouldDropFrame && !frame.keyFrame) {
    //        GLog(tOther,(@"丢帧---%ld,framekey==%d",frame.frameIndex,frame.keyFrame));
    //        [frame release];
    //        [drawpool release];
    //        return;
    //    }
    AVFrame *_pFrametest = av_frame_alloc();//avcodec_alloc_frame();
    AVPacket pkt, *packettest = &pkt;
    int size = [[frame buffer] length];
    av_new_packet(packettest,size);
    
    if (packettest==NULL) {
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    memcpy(packettest->data,(uint8_t *)[[frame buffer] bytes], size);
    //    packettest->size = [[frame buffer] length];
    //    GLog(tOther,(@"_packet.size ==%d",_packet.size));
    // start benchmark
    if (_pCodecCtx==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    if (_pFrametest==NULL) {
        av_free_packet(packettest);
        av_free(_pFrametest);
        [frame release];
        [drawpool drain];
        return;
    }
    int gotten = 0;
    //    double cost = CACurrentMediaTime() * 1000;
    //    EZApplicationPreference *per = [EZApplicationPreference sharedInstance];
    //加上全局锁
    int decLen = 0;
    
    //    GLog(tOther,(@"framelength---%u,framekey==%d,framelength---%d",frame.frameLength,frame.keyFrame,frame.buffer.length));
    //    @synchronized(per){
    decLen = avcodec_decode_video2(_pCodecCtx, _pFrametest, &gotten, packettest);
    //    }
    av_free_packet(packettest);
    packettest = NULL;
    // end benchmark
    _averageCost = _totalCost/_callCount;
    
    //GLog(tOther,(@"callCount=%d, cost=%f, average decoding cost=%f", _callCount, cost, _averageCost));
    
    if (gotten && (decLen > 0))
    {
        int h = _pCodecCtx->height;
        int w = _pCodecCtx->width;
        frame.width = _pCodecCtx->width;
        frame.height = h;
        if (_rgbBuffer == NULL)
        {
            _rgbBuffer = (uint8_t *)malloc(w*h*4);
        }
        if (_imgReg == NULL) {
            CGColorSpaceRef			colorSpace;
            colorSpace = CGColorSpaceCreateDeviceRGB();
            //            _imgReg = CGBitmapContextCreate(_rgbBuffer, (w + 32), h, 8, (w + 32)*4, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
            _imgReg = CGBitmapContextCreate(_rgbBuffer, (w), h, 8, (w)*4, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
            CGColorSpaceRelease(colorSpace);
        }
        NSData *datay = copyFrameData(_pFrametest->data[0], _pFrametest->linesize[0], w, h);
        NSData *datau = copyFrameData(_pFrametest->data[1], _pFrametest->linesize[1], (w)/2, h/2);
        NSData *datav = copyFrameData(_pFrametest->data[2], _pFrametest->linesize[2], (w)/2, h/2);
        
        [EZYuv2RGB convertYuv420ToRgb32:(uint8_t*)[datay bytes]
                                   src1:(uint8_t*)[datau bytes]
                                   src2:(uint8_t*)[datav bytes]
                                    dst:_rgbBuffer width:(w) height:h];
        
        //        NSMutableData *rgbData = [NSMutableData dataWithBytes:_rgbBuffer length:w*h*4];
        CGImageRef imgref = CGBitmapContextCreateImage(_imgReg);
        frame.width = (int)CGImageGetWidth(imgref);
        frame.height= (int)CGImageGetHeight(imgref);
        [datay release];
        [datav release];
        [datau release];
        datay = nil;
        datav = nil;
        datau = nil;
        av_free(_pFrametest);
        _pFrametest = NULL;
        if (_delegate && [_delegate respondsToSelector:@selector(decoder:didDecodeFrame:toRGB:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAutoreleasePool *drawpool = [[NSAutoreleasePool alloc] init];
                [_delegate decoder:self didDecodeFrame:frame toRGB:imgref];
                [drawpool drain];
            });
        }
        [frame release];
    }
    [drawpool drain];
    
}

- (void)decodeStreamData:(NSData *)data
{
    dispatch_block_t block = ^{
        [_inputBuffer appendData:data];
        BOOL keyFrame = NO;
        
        uint32_t frameLen = [self findFrame:(unsigned char *)[_inputBuffer bytes]
                                  streamLen:[_inputBuffer length] isKeyFrame:&keyFrame];
        
        while (frameLen > 0)
        {
            NSData *frameData = [_inputBuffer subdataWithRange:NSMakeRange(0, frameLen)];
            MediaFrame *frame = [[MediaFrame alloc] initWithData:frameData];
            frame.isVideo = YES;
            frame.frameIndex = _frameIdx++;
            frame.keyFrame = keyFrame;
            frame.width = _pCodecCtx->width;
            frame.height = _pCodecCtx->height;
            
            [_frameList addObject:frame];
            [frame release];
            
            [_inputBuffer replaceBytesInRange:NSMakeRange(0, frameLen) withBytes:nil length:0];
            frameLen = [self findFrame:(unsigned char *)[_inputBuffer bytes]
                             streamLen:[_inputBuffer length] isKeyFrame:&keyFrame];
            
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_async(_decoderQueue, block);
    }
}

- (void)decodeFrame:(MediaFrame *)frame
{
    
    if (frame) {
        @synchronized(self){
            [_frameList addObject:frame];
            GLog(tVideoShow,(@"------------>_frameList.count=%ld",_frameList.count));
        }
    }
}


-(void)removeAllFrame{
    if (!_decoderQueue) {
        return;
    }
    dispatch_block_t block = ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        @synchronized(self){
            [_frameList removeAllObjects];
            [_inputBuffer replaceBytesInRange:NSMakeRange(0, _inputBuffer.length) withBytes:nil length:0];
            //            GLog(tOther,(@"_framelist===%d",_frameList.count));
        }
        usleep(10);
        [pool release];
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
}

-(void)removeAllFrameWithoutI{
    dispatch_block_t block = ^{
        //    @synchronized(self){
        for (int i = _frameList.count-1; i>=0; i--) {
            MediaFrame *frame = [_frameList objectAtIndex:i];
            if (!frame.keyFrame) {
                [_frameList removeObjectAtIndex:i];
            }
        }
        //     }
    };
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
}

-(MediaFrame*)getFirstFrame{
    
    if (!_decoderQueue) {
        return nil;
    }
    __block MediaFrame *frame = nil;
    dispatch_block_t block = ^{
        if (_frameList.count>0) {
            
            frame = [_frameList objectAtIndex:0];
            //            GLog(tOther,(@"frame List count: %d", [_frameList count]));
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    //     GLog(tOther,(@"_framelistframe===%@",frame));
    return frame;
}

-(MediaFrame*)getSecondFrame{
    _secondTimer =  CACurrentMediaTime() * 1000;
    if (!_decoderQueue) {
        return nil;
    }
    __block MediaFrame *frame = nil;
    dispatch_block_t block = ^{
        if (_frameList.count>1) {
            
            frame = [_frameList objectAtIndex:1];
            //            GLog(tOther,(@"frame List count: %d", [_frameList count]));
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    //     GLog(tOther,(@"_framelistframe===%@",frame));
    return frame;
}


-(void)removetoNextIFrame{
    @synchronized(self){
        int index = 0;
        for (int i = 1; i<_frameList.count; i++) {
            MediaFrame *frame = [_frameList objectAtIndex:i];
            if (frame.keyFrame) {
                index = i;
            }
        }
        if (index>=1) {
            [_frameList removeObjectsInRange:NSMakeRange(1, index-1)];
            GLog(tOther,(@"_framelist[1]===%d",[[_frameList objectAtIndex:1] count]));
        }
    }
}

-(void)removeFirstFrame{
    if (!_decoderQueue) {
        return;
    }
    dispatch_block_t block = ^{
        if (_frameList.count>0) {
            //            @synchronized(self){
            //            GLog(tOther,(@"removefirstframe"));
            @synchronized(self){
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [_frameList removeObjectAtIndex:0];
                [pool release];
                
            }
        }
    };
    
    if (dispatch_get_current_queue() == _decoderQueue)
    {
        block();
    }
    else
    {
        dispatch_sync(_decoderQueue, block);
    }
    
}

-(void)removeToLastIFrame{
    //    dispatch_block_t block = ^{
//    GLog(tOther,(@"remove"));
    BOOL findLastI = NO;
    int  lastIFrameIndex = 0;
    @synchronized(self){
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        for (int i = _frameList.count-1; i>=0; i--) {
            if (i>_frameList.count-1) {
                continue;
            }
            //                    GLog(tOther,(@"Framelistcount=-==%d",_frameList.count));
            MediaFrame *frame = [_frameList objectAtIndex:i];
            //                GLog(tOther,(@"frame.keyframe===i====%d=======%d",i,frame.keyFrame));
            if (frame.keyFrame) {
                lastIFrameIndex = i;
                findLastI = YES;
                break;
            }
            //                GLog(tOther,(@"lastI==%d",lastIFrameIndex));
        }
        if (findLastI) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            [_frameList removeObjectsInRange:NSMakeRange(0, lastIFrameIndex)];
            [pool release];
        }
        //            if (_frameList.count>jumpDoor) {
        //                needWaiting = YES;
        //            }else{
        //                needWaiting = NO;
        //            }
        [pool release];
        //        GLog(tOther,(@"FrameList===%d",_frameList.count));
        
    }
    
    //    };
    //
    //    if (dispatch_get_current_queue() == _decoderQueue)
    //    {
    //        block();
    //    }
    //    else
    //    {
    //        dispatch_sync(_decoderQueue, block);
    //    }
}




@end
