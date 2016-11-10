//
//  MediaFrame.m
//  GP2PCollect
//
//  Created by gxl on 16/10/26.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "MediaFrame.h"

@implementation MediaFrame
- (id)initWithData:(NSData *)data{
    if ((self = [super init]))
    {
        _buffer=[[NSMutableData alloc]initWithData:data];
    }
    
    return self;
}
@end
