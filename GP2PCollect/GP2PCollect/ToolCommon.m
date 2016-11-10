//
//  ToolCommon.m
//  GoolinkViewEasy
//
//  Created by Anni on 16/3/25.
//
//

#import "ToolCommon.h"
#import <AVFoundation/AVAssetImageGenerator.h>
#import <AVFoundation/AVAsset.h>
//#import "FileManager.h"
unsigned int g_dwGLogZoneSeed = tAll_MSK;
@implementation ToolCommon
/**
 *  获取某个日期是星期几
 *  eg:2016_03_26_15_05_19 -> 2016-03-26 15:05:19
 */
+ (NSString *)getStandardDate:(NSString *)uiDate{
    NSArray *array=[uiDate componentsSeparatedByString:@"_"];
    int year=[[array objectAtIndex:0]intValue];
    int month=[[array objectAtIndex:1]intValue];
    int day=[[array objectAtIndex:2]intValue];
    int hour=[[array objectAtIndex:3]intValue];
    int min=[[array objectAtIndex:4]intValue];
    int second=[[array objectAtIndex:5]intValue];
    return [NSString stringWithFormat:@"%d-%02d-%02d %02d:%02d:%02d",year,month,day,hour,min,second];
}
/**
 *  获取某个日期是星期几
 *  eg:2016_03_26 -> 2016-03-26 星期六
 */
+ (NSString *)getWeekdayWithDate:(NSString *)uiDate{
    NSArray *array=[uiDate componentsSeparatedByString:@"_"];
    int year=[[array objectAtIndex:0]intValue];
    int month=[[array objectAtIndex:1]intValue];
    int day=[[array objectAtIndex:2]intValue];
    NSDateComponents *_comps = [[NSDateComponents alloc] init];
    [_comps setDay:day];
    [_comps setMonth:month];
    [_comps setYear:year];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *_date = [gregorian dateFromComponents:_comps];
    NSDateComponents *weekdayComponents =
    [gregorian components:NSWeekdayCalendarUnit fromDate:_date];
    int _weekday = (int)[weekdayComponents weekday];
    GLog(tOther,(@"_weekday::%d",_weekday));
    NSString *strWeekDay;
    switch (_weekday) {
        case 1:
            strWeekDay= @"星期天";
            break;
        case 2:
            strWeekDay= @"星期一";
            break;
        case 3:
            strWeekDay= @"星期二";
            break;
        case 4:
            strWeekDay= @"星期三";
            break;
        case 5:
            strWeekDay= @"星期四";
            break;
        case 6:
            strWeekDay= @"星期五";
            break;
        case 7:
            strWeekDay= @"星期六";
            break;
            
        default:
            break;
    }
    return [NSString stringWithFormat:@"%d-%d-%d %@",year,month,day,strWeekDay];
}
/**
*NSString转NSDate
@format=如"yyyy年MM月dd日"
*/
+(NSDate*) convertDateFromString:(NSString*)uiDate format:format
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:format];
    NSDate *date=[formatter dateFromString:uiDate];
    //[formatter release];
    return date;
}
/**
 *NSDate转NSString
 @format=如"yyyy年MM月dd日"
 */
+(NSString*) convertStringFromDate:(NSDate*)date format:format
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    NSString *str = [dateFormatter stringFromDate:date];
    return str;
}
/**
 *获取本地视频的缩略图
 */
//+(UIImage *)thumbnailImageForVideo:(NSString *)videoURL
//{
//    
//    AVURLAsset *asset = [[[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil]autorelease];
//    
//    AVAssetImageGenerator *gen = [[[AVAssetImageGenerator alloc] initWithAsset:asset]autorelease];
//    
//    gen.appliesPreferredTrackTransform = YES;
//    
//    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
//    
//    NSError *error = nil;
//    
//    CMTime actualTime;
//    
//    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
//    
//    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
//    
//    CGImageRelease(image);
//
//    return [thumb autorelease] ;//解决有时进本地录像列表( Received memory warning)crash的问题
//
//}
//
///**
// *获取实时视频的缩略图
// */
//+(UIImage *)thumbnailImageForDeivce:(NSString *)deviceName channelCount:(int)cnt
//{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *dirPath = [[FileManager sharedInstance] applicationPath];
//    NSMutableArray *array=[[NSMutableArray alloc]init];
//    for (int i=0; i<cnt; i++) {
//        UIImage * img=nil;
//        NSString* path_ = [NSString stringWithFormat:@"%@%@/%@_%d.png", dirPath, DEFAULT_Thumbnail_PATH,deviceName,i];
//        if(![fileManager fileExistsAtPath:path_]) //如果不存在
//        {
//            GLog(tOther,(@"%@ is not exist",path_));
//            img=[UIImage imageNamed:@"preview_1.png"];
//        }
//        else{
//            img=[UIImage imageWithContentsOfFile:path_];
//        }
//        [array addObject:img];
//    }
//    UIImage *pImg= [ToolCommon composeWithImgList:array];
//    [array release];
//    return pImg;
//}
//
///**
// *合并n张图片
// */
//+(UIImage *)composeWithImgList:(NSMutableArray *)imgList{
//    int cnt=(int)imgList.count;
//    int n=1;
//    switch (cnt) {
//        case 1:
//            n=1;
//            break;
//        case 2:
//        case 3:
//        case 4:
//            n=2;
//            for (int i=0; i<4-cnt; i++) {
//                [imgList addObject:[UIImage imageNamed:@"preview_1.png"]];
//            }
//            break;
//        case 5:
//        case 6:
//        case 7:
//        case 8:
//        case 9:
//            n=3;
//            for (int i=0; i<9-cnt; i++) {
//                [imgList addObject:[UIImage imageNamed:@"preview_1.png"]];
//            }
//            break;
//        case 10:
//        case 11:
//        case 12:
//        case 13:
//        case 14:
//        case 15:
//        case 16:
//            n=4;
//            for (int i=0; i<16-cnt; i++) {
//                [imgList addObject:[UIImage imageNamed:@"preview_1.png"]];
//            }
//            break;
//        default://大于16时,取前16个
//            n=4;
//            [imgList removeObjectsInRange:NSMakeRange(16, imgList.count-16)];
//            break;
//    }
//    UIImage *tImge=[imgList objectAtIndex:0];
//    CGSize size = CGSizeMake(tImge.size.width*n, tImge.size.height*n);
//    UIGraphicsBeginImageContext(size);
//    int i=0,j=0,k=0;
//    for (UIImage *pImge in imgList) {
//        if(k==n)
//            k=0;
//        [pImge drawInRect:CGRectMake(tImge.size.width*k, tImge.size.height*j, tImge.size.width, tImge.size.height)];
//        i++;
//        k++;
//        j=i/n;
//    }
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}
///**
// *合并多张图片
// */
//+(UIImage *)composeWithHeader:(UIImage *)header content:(UIImage *)content footer:(UIImage *)footer{
//    CGSize size = CGSizeMake(content.size.width, header.size.height +content.size.height +footer.size.height);
//    UIGraphicsBeginImageContext(size);
//    [header drawInRect:CGRectMake(0,
//                                  0,
//                                  header.size.width,
//                                  header.size.height)];
//    [content drawInRect:CGRectMake(0,
//                                   header.size.height,
//                                   content.size.width,
//                                   content.size.height)];
//    [footer drawInRect:CGRectMake(0,
//                                  header.size.height+content.size.height,
//                                  footer.size.width,
//                                  footer.size.height)];
//    
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return image;
//}
/**
 *打印二进制
 */
+ (NSString *) _getHexString:(char *)buff Size:(int)size
{
    int i = 0;
    char *ptr = buff;
    
    NSMutableString *str = [[NSMutableString alloc] init];
    while(i++ < size) [str appendFormat:@"%02X ", *ptr++ & 0x00FF];
    
    return str ;
}

+ (NSString*)convertObjectTojsonString:(id)object{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

+ (NSString*)getCPUType:(int)v_nCpuType{
    NSString* str=nil;
    switch (v_nCpuType) {
        case DMS_CPU_8120:
            str=@"A";
            break;
        case DMS_CPU_8180:
            str=@"B";
            break;
        case DMS_CPU_8160:
            str=@"C";
            break;
        case DMS_CPU_3510:
            str=@"C";
            break;
        case DMS_CPU_3511:
            str=@"C";
            break;
        case DMS_CPU_3515:
            str=@"D";
            break;
        case DMS_CPU_3516:
            str=@"E";
            break;
        case DMS_CPU_3516A:
            str=@"GA";
            break;
        case DMS_CPU_3516C:
            str=@"F";
            break;
        case DMS_CPU_3516D:
            str=@"GD";
            break;
        case DMS_CPU_3518:
            str=@"F";
            break;
        case DMS_CPU_3518A:
            str=@"FA";
            break;
        case DMS_CPU_3518C:
            str=@"FC";
            break;
        case DMS_CPU_3518E:
            str=@"FE";
            break;
        case DMS_CPU_TI365:
            str=@"H";
            break;
        case DMS_CPU_HI3515A:
            str=@"G" ;
            break;
        case DMS_CPU_HI3520:
            str=@"G" ;
            break;
        case DMS_CPU_HI3520A:
            str=@"G" ;
            break;
        case DMS_CPU_HI3520D:
            str=@"G" ;
            break;
        case DMS_CPU_HI3521:
            str=@"G" ;
            break;
        case DMS_CPU_HI3531:
            str=@"G" ;
            break;
        case DMS_CPU_HI3535:
            str=@"G" ;
            break;
        case DMS_CPU_HI3518EV2:
            str=@"KE";
            break;
        case DMS_CPU_HI3518EV21:
        str=@"KF";
            break;
        case DMS_CPU_HI3516CV2:
        str=@"K";
            break;
        case -1:
            str=@" " ;
            break;
        default:
             str=@"unknown" ;
            break;
    }
    return str;
}
@end
