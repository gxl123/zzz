//
//  EZGLView.m
//  DVRiPhoneLibDemo
//
//  Created by user on 12-5-22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "EZGLView.h"
//#import "Common3.h"
//#import "FileManager.h"
//#import "ToolCommon.h"
//#import "Reachability.h"
#import "iOSLogEngine.h"
#import "GLog.h"
#import "GLogZone.h"
unsigned int g_dwGLogZoneSeed = tAll_MSK;
@implementation EZGLView

@synthesize zoomScale = _zoomScale;

#define TEX_COORD_MAX 1
#define iconname @"bg.png"

typedef struct
{
    float Position[3];
    float TexCoord[2];
} Vertex;

const Vertex Vertices[] = {
    {{1, -1, 0}, {TEX_COORD_MAX, TEX_COORD_MAX}},
    {{1, 1, 0}, {TEX_COORD_MAX, 0}},
    {{-1, 1, 0}, {0, 0}},
    {{-1, -1, 0}, {0, TEX_COORD_MAX}},
};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

// return a CAEAGLLayer so that the layer is created for OpenGL ES rendering
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer *)self.layer;
    _eaglLayer.opaque = YES;
    //    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
    //                                    [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
    //                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
    //                                    nil];
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        GLog(tOther,(@"Failed to initialize OpenGLES 2.0 context"));
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context])
    {
        GLog(tOther,(@"Failed to set current OpenGLES 2.0 context"));
        exit(1);
    }
}

- (void)setupFrameBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
	{
		GLog(tOther,(@"failed to make complete framebuffer object %x", status));
	}
}

- (void)destroyFrameBuffer
{
    if (_frameBuffer)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (_colorRenderBuffer)
    {
        glDeleteBuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
}

- (GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        GLog(tOther,(@"Error loading shader: %@", error.localizedDescription));
        exit(1);
    }
    
    // create ID for shader
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // define shader text
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // compile shader
    glCompileShader(shaderHandle);
    
    // verify the compiling
    GLint compileSucess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSucess);
    if (compileSucess == GL_FALSE)
    {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        GLog(tOther,(@"----%@", messageStr));
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileShaders
{
    GLuint vertexShader = [self compileShader:@"GPlayer.framework/SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"GPlayer.framework/SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar message[256];
        glGetProgramInfoLog(programHandle, sizeof(message), 0, &message[0]);
        NSString *messageStr = [NSString stringWithUTF8String:message];
        GLog(tOther,(@"%@", messageStr));
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    glEnableVertexAttribArray(_positionSlot);
    
    _texCoordSlot = glGetAttribLocation(programHandle, "TexCoordIn");
    glEnableVertexAttribArray(_texCoordSlot);
    
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    _samplerYUniform = glGetUniformLocation(programHandle, "samplerY");
    _samplerUUniform = glGetUniformLocation(programHandle, "samplerU");
    _samplerVUniform = glGetUniformLocation(programHandle, "samplerV");
}

// setup the Vertex Buffer Object to store the verdices and index data in OpenGL
- (void)setupVBOs
{
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
}

// test method
- (void)setupDisplayLink
{
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    displayLink.frameInterval = 3;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        _zoomScale = 1.0;
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
        
        [self setupLayer];
        [self setupContext];
        [self setupFrameBuffer];
        
        [self compileShaders];
        [self setupVBOs];
        
        _snapshotRequests = [[NSMutableArray alloc] init];
#ifdef showiconView
        if (!isIPhone && LENOVO) {
            if (!iconView) {
                iconView = [[UIImageView alloc] initWithFrame:self.bounds];
                [iconView setImage:[UIImage imageNamed:iconname]];
                [self addSubview:iconView];
                [iconView setHidden:NO];
            }
        }
       
#endif
#ifdef P2PLib
        if (!lineView) {
            lineView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -2, self.bounds.size.width, 3)];
            
            [lineView setBackgroundColor:[UIColor redColor]];
            lineView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
            [self addSubview:lineView];

        }
#endif
        
//        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(setIsOnline) userInfo:nil repeats:YES];
    }
    
    return self;
}

//- (void)dealloc
//{
//     
//    // tear down OpenGL ES
//    if (_frameBuffer)
//    {
//        glDeleteBuffers(1, &_frameBuffer);
//        _frameBuffer = 0;
//    }
//    
//    if (_colorRenderBuffer)
//    {
//        glDeleteBuffers(1, &_colorRenderBuffer);
//        _colorRenderBuffer = 0;
//    }
//    
//    if (_vertexBuffer)
//    {
//        glDeleteBuffers(1, &_vertexBuffer);
//        _vertexBuffer = 0;
//    }
//    
//    if (_indexBuffer)
//    {
//        glDeleteBuffers(1, &_indexBuffer);
//        _indexBuffer = 0;
//    }
//    
//    if (_samplerYTexture)
//    {
//        glDeleteTextures(1, &_samplerYTexture);
//        _samplerYTexture = 0;
//    }
//    
//    if (_samplerUTexture)
//    {
//        glDeleteTextures(1, &_samplerUTexture);
//        _samplerUTexture = 0;
//    }
//    
//    if (_samplerVTexture)
//    {
//        glDeleteTextures(1, &_samplerVTexture);
//        _samplerVTexture = 0;
//    }
//    
//    if ([EAGLContext currentContext] == _context)
//    {
//        [EAGLContext setCurrentContext:nil];
//    }
//    
//    [_context release];
//    _context = nil;
//    
//    [_snapshotRequests release];
//    
//    if (lastData) {
//        [lastData release];
//        lastData = nil;
//    }
//    
//    [super dealloc];
//}

- (void)snapshot:(NSString *)fileName data:(NSData*)data{
    
}


- (void)snapshot:(NSString *)fileName
{
    GLint backWidth;
    GLint backHeight;
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backHeight);
    int x = 0;
    int y = 0;
    
    int width = backWidth;
    int height = backHeight;

    int dataLen = width * height * 4;
    GLubyte *data = (GLubyte *)malloc(dataLen * sizeof(GLubyte));
    
    // Read pixel data from frame buffer
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    // Create a CGImage with the pixel data
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLen, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast, ref, NULL, true, kCGRenderingIntentDefault);
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    // Flip the CGImage by rendering it to the flipped bitmap context.
    CGContextSetBlendMode(ctxt, kCGBlendModeCopy);
    CGContextDrawImage(ctxt, CGRectMake(0.0, 0.0, width, height), iref);
    
    // Retrieve the UIImage from the current context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  
#ifdef P2PLib
    NSString *man = [[FileManager sharedInstance] defaultphotopath];
    NSString *photo = [[FileManager sharedInstance] photoPath];
    GLog(tOther,(@"path=%@",man));
    if ([man isEqualToString:photo]) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }else{
        NSData *imageData = UIImagePNGRepresentation(image);
        
        [imageData writeToFile:fileName atomically:NO];
    }
#else
    NSData *imageData = UIImagePNGRepresentation(image);
    
    [imageData writeToFile:fileName atomically:NO];
#endif
    UIGraphicsEndImageContext();
    
    // Clean up
    free(data);
    CGDataProviderRelease(ref);
    CGColorSpaceRelease(colorspace);
    CGImageRelease(iref);
}

//- (void)layoutSubviews
//{
//    [EAGLContext setCurrentContext:_context];
//
//    [self destroyFrameBuffer];
//    [self setupFrameBuffer];
//}




- (void)updateFrame:(CGRect)newFrame
{
    @synchronized(self){
        self.frame = newFrame;

        [EAGLContext setCurrentContext:_context];
      
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE)
        {
            GLog(tOther,(@"Layout: failed to make complete frame buffer object %x", status));
        }
//        glFlush();\
        
//        if ([Reachability isHaveNet]) {
//        }else{
            if (lastData) {
                isRenderLastData = YES;
                //[self render:lastData frameWidth:awidth frameHeight:aheight];
                isRenderLastData = NO;
            }
//        }
        
        
#ifdef showiconView
        if (iconView) {
            [iconView setFrame:CGRectMake(0, 0, newFrame.size.width, newFrame.size.height)];
        }
#endif
#ifdef P2PLib
        if (lineView) {
            self.clipsToBounds = YES;
            [lineView setFrame:CGRectMake(0, -2, newFrame.size.width, 3)];
//            GLog(tOther,(@"lineView===%f",lineView.frame.size.width));
            if (lineView.frame.size.width == 375-2 || lineView.frame.size.width == 320-2 || lineView.frame.size.width == 621-2 || lineView.frame.size.width == 768-2) {
                [lineView setHidden:YES];
            }else{
                [lineView setHidden:YES];

            }
        }
#endif
    }
}

- (void)setIsOnline {
    _isOnline = NO;
}

- (void)render:(NSData *)data frameWidth:(int)width frameHeight:(int)height
{
    @synchronized(self){

        //    GLog(tOther,(@"render===="));
        int idxU = width * height;
        int idxV = idxU + (idxU / 4);
        uint8_t *pyuvData = (uint8_t *)[data bytes];
        int datalength = [data length];
        if (datalength <= idxV || datalength<= idxU || !pyuvData[idxU] || !pyuvData[idxV]) {
            GLog(tOther,(@"woca"));
            return;
        }
        //NSAutoreleasePool *pool_ = [[NSAutoreleasePool alloc] init];
        if (!isRenderLastData) {
            if (lastData) {
                //[lastData release];
                lastData = nil;
            }
            lastData = [[NSData alloc] initWithData:data];
        }else{
            
            GLog(tOther,(@"--------->set is on line"));
            
            _isOnline = YES;
        }
        //[pool_ release];
        
        [EAGLContext setCurrentContext:_context];

        float screenScale = [[UIScreen mainScreen] scale];
        GLsizei w = self.frame.size.width * screenScale / _zoomScale;
        GLsizei h = self.frame.size.height * screenScale / _zoomScale;
        GLint x = 0;
        GLint y = 0;
        
        GLsizei bw = w;
        GLsizei bh = h;
        
        if (awidth == 0 && aheight==0) {
            awidth = width;
            aheight = height;
        }
        
        if (bw*height > bh*width)
        {
            w = (bh * width) / height;
            x = (bw - w) / 2;
        }
        else
        {
            h = (bw * height) / width;
            y = (bh - h) / 2;
        }
        
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glViewport(x, y, w, h);
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
        glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(offsetof(Vertex, TexCoord)));
        
        // Y texture
        if (_samplerYTexture)
        {
            glDeleteTextures(1, &_samplerYTexture);
        }
        
        glActiveTexture(GL_TEXTURE0);
        glGenTextures(1, &_samplerYTexture);
        glBindTexture(GL_TEXTURE_2D, _samplerYTexture);
        glUniform1i(_samplerYUniform, 0);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pyuvData);
        
        // U texture
        if (_samplerUTexture)
        {
            glDeleteTextures(1, &_samplerUTexture);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glGenTextures(1, &_samplerUTexture);
        glBindTexture(GL_TEXTURE_2D, _samplerUTexture);
        glUniform1i(_samplerUUniform, 1);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        if (datalength>idxU && pyuvData[idxU]) {
             glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, &pyuvData[idxU]);
        }else{
            GLog(tOther,(@"error1"));
        }
       
        
        // V texture
//        if (_samplerVTexture)
//        {
//            glDeleteTextures(1, &_samplerVTexture);
//        }
        
        glActiveTexture(GL_TEXTURE2);
        glGenTextures(1, &_samplerVTexture);
        glBindTexture(GL_TEXTURE_2D, _samplerVTexture);
        glUniform1i(_samplerVUniform, 2);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        if (datalength>idxV && pyuvData[idxV]) {
            glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, &pyuvData[idxV]);
        }else{
            GLog(tOther,(@"error2"));
        }
        
        
        
        
        if (Indices) {
            //            glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
            glDrawElements(GL_TRIANGLE_STRIP, sizeof(Indices)/sizeof(GLubyte), GL_UNSIGNED_BYTE, 0);
            
            
        }else{
            GLog(tOther,(@"error3"));
            
        }
        
        if ([_snapshotRequests count] > 0)
        {
            NSString *file = [_snapshotRequests objectAtIndex:0];
            [self snapshot:file];
            [_snapshotRequests removeObjectAtIndex:0];
        }
        if (_context) {
            [_context presentRenderbuffer:GL_RENDERBUFFER];
        }
        if (_samplerYTexture) {
            glDeleteTextures(1, &_samplerYTexture);
            
        }
        if (_samplerUTexture) {
            glDeleteTextures(1, &_samplerUTexture);
            
        }
        if (_samplerVTexture)
        {
            glDeleteTextures(1, &_samplerVTexture);
        }
//        [self renderClear];
#ifdef showiconView
        if (iconView) {
            if (![iconView isHidden]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [iconView setHidden:YES];
                });
            }
        }
#endif
    }
}

- (void)renderOnFullScreen:(NSData *)data frameWidth:(int)width frameHeight:(int)height
{
     @synchronized(self){
#ifdef showiconView
         if (iconView) {
             if (![iconView isHidden]) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [iconView setHidden:YES];
                 });
             }
         }
#endif
         
    [EAGLContext setCurrentContext:_context];
    int idxU = width * height;
    int idxV = idxU + (idxU / 4);
    uint8_t *pyuvData = (uint8_t *)[data bytes];
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
    float screenScale = [[UIScreen mainScreen] scale];
    glViewport(0, 0, self.frame.size.width * screenScale / _zoomScale, self.frame.size.height*screenScale / _zoomScale);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glVertexAttribPointer(_texCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(offsetof(Vertex, TexCoord)));
    
    // Y texture
    if (_samplerYTexture)
    {
        glDeleteTextures(1, &_samplerYTexture);
    }
    
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_samplerYTexture);
    glBindTexture(GL_TEXTURE_2D, _samplerYTexture);
    glUniform1i(_samplerYUniform, 0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pyuvData);
    
    // U texture
    if (_samplerUTexture)
    {
        glDeleteTextures(1, &_samplerUTexture);
    }
    
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_samplerUTexture);
    glBindTexture(GL_TEXTURE_2D, _samplerUTexture);
    glUniform1i(_samplerUUniform, 1);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, &pyuvData[idxU]);
    
    // V texture
    if (_samplerVTexture)
    {
        glDeleteTextures(1, &_samplerVTexture);
    }
    
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &_samplerVTexture);
    glBindTexture(GL_TEXTURE_2D, _samplerVTexture);
    glUniform1i(_samplerVUniform, 2);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width/2, height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, &pyuvData[idxV]);
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    if ([_snapshotRequests count] > 0)
    {
        NSString *file = [_snapshotRequests objectAtIndex:0];
        [self snapshot:file];
        [_snapshotRequests removeObjectAtIndex:0];
    }
     if (_context) {
          [_context presentRenderbuffer:GL_RENDERBUFFER];
     }
    if (_samplerYTexture) {
        glDeleteTextures(1, &_samplerYTexture);
        
    }
    if (_samplerUTexture) {
        glDeleteTextures(1, &_samplerUTexture);
        
    }
    if (_samplerVTexture)
    {
        glDeleteTextures(1, &_samplerVTexture);
    }
    
    glFlush();
     }
}


- (void)renderClear
{
    @synchronized(self){
        [EAGLContext setCurrentContext:_context];
#ifdef showiconView
       
        if (iconView) {
            if ([iconView isHidden]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [iconView setHidden:NO];
                });
            }
        }
        
#endif
        if(lastData){
            //[lastData release];
            lastData = nil;
        }
        
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
        
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        if (_samplerYTexture) {
            glDeleteTextures(1, &_samplerYTexture);
            
        }
        if (_samplerUTexture) {
            glDeleteTextures(1, &_samplerUTexture);
            
        }
        if (_samplerVTexture)
        {
            glDeleteTextures(1, &_samplerVTexture);
        }

        
    }
}

- (void)takeSnapshot:(NSString *)fileName
{
    [_snapshotRequests addObject:fileName];
}

@end






