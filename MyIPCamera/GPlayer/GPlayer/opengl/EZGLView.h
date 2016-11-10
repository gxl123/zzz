//
//  EZGLView.h
//  DVRiPhoneLibDemo
//
//  Created by user on 12-5-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "FileManager.h"
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
//#import "DisplayView.h"

@interface EZGLView : UIView
{
    float _zoomScale;
    NSMutableArray *_snapshotRequests;
    
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    
    GLuint _frameBuffer;
    GLuint _colorRenderBuffer;
    
    GLuint _positionSlot;
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    
    GLuint _texCoordSlot;
    GLuint _samplerYUniform;  // Y sampler uniform
    GLuint _samplerUUniform;  // U sampler uniform
    GLuint _samplerVUniform;  // V sampler uniform
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint     _program;

    GLuint _samplerYTexture;
    GLuint _samplerUTexture;
    GLuint _samplerVTexture;
    int awidth;
    int aheight;
    UIImageView *iconView;
    UIImageView *lineView;
    NSData *lastData;
    BOOL isRenderLastData;
    BOOL _isOnline;
}

@property (nonatomic) float zoomScale;

- (void)updateFrame:(CGRect)newFrame;
- (void)render:(NSData *)data frameWidth:(int)width frameHeight:(int)height;
- (void)renderOnFullScreen:(NSData *)data frameWidth:(int)width frameHeight:(int)height;
- (void)renderClear;
- (void)takeSnapshot:(NSString *)fileName;

@end
