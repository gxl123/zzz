//
//  iOSLogEngine.h
//  LogEngineTest
//


#import <Foundation/Foundation.h>

extern NSString* g_strLogFilePath;
extern NSLock* g_idLock;

void GLogToFile (NSString *format, ...);

@interface iOSLogEngine : NSObject {
		
}

+ (void)writeLogWithDateTime:(NSString*)sz, ...;
+ (void)writeLog:(NSString*)sz, ...;
+ (void)OutputDebugString:(NSString*) string;
+ (void)initLogEngine:(NSString*)logFileName;

@end