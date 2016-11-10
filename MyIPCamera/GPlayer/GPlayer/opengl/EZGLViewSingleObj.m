//
//  EZGLViewSingleObj.m
//  GoolinkViewEasy
//
//  Created by gxl on 16/10/13.
//
//

#import "EZGLViewSingleObj.h"

@implementation EZGLViewSingleObj
static EZGLViewSingleObj *_sharedInstance;
+ (EZGLViewSingleObj *)sharedInstance
{
    static dispatch_once_t onceman;
    dispatch_once(&onceman, ^{
        _sharedInstance = [[self alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    });
    
    return _sharedInstance;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
