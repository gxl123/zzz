//
//  iOSLogEngine.m
//  LogEngineTest
//

#import "iOSLogEngine.h"

NSString* g_strLogFilePath;
NSLock* g_idLock;

void GLogToFile (NSString *format, ...){
	
	va_list vl;
	va_start(vl, format);
	
	NSString* strOutputAppending = [[[NSString alloc] initWithFormat:format arguments:vl] stringByAppendingString:@"\r\n"];
	
	NSDate *now = [NSDate date];
	NSString* strOutput = [NSString stringWithFormat:@"[%@] %@", now,strOutputAppending];
	
	[iOSLogEngine OutputDebugString:strOutput];
	
	va_end(vl);
	
}

@implementation iOSLogEngine

+ (void)writeLogWithDateTime:(NSString*)sz, ... {
	
	va_list vl;
	va_start(vl, sz);

	NSString* strOutputAppending = [[NSString stringWithFormat:sz, vl] stringByAppendingString:@"\r\n"];
	NSDate *now = [NSDate date];
	NSString* strOutput = [NSString stringWithFormat:@"[%@] %@", now,strOutputAppending];	
	
	[iOSLogEngine OutputDebugString:strOutput];
	
	va_end(vl);
	
}

+ (void)writeLog:(NSString *)sz, ... {
	
	va_list vl;
	va_start(vl, sz);
	
	NSString* strOutput = [[NSString stringWithFormat:sz, vl] stringByAppendingString:@"\r\n"];
	
	[iOSLogEngine OutputDebugString:strOutput];
	
	va_end(vl);
	
}

+ (void)OutputDebugString:(NSString*) string {
	
	if (g_idLock) {
		
		[g_idLock lock];
		
	//NSLog( @"%@", string );
    
	// To write file here
	//
		// append
    		NSFileHandle *hFile = [NSFileHandle fileHandleForWritingAtPath:g_strLogFilePath];
    		[hFile seekToEndOfFile];
    		[hFile writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
			[hFile closeFile];
		
		[g_idLock unlock];
	}
}

+ (void)initLogEngine:(NSString*)logFileName {
	
#ifdef LOGTOFILE
	if( !g_idLock ) {
		g_idLock = [[NSLock alloc] init];
		
		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		g_strLogFilePath = [[[documentsPaths objectAtIndex:0] stringByAppendingPathComponent:logFileName] retain];
    
		NSLog( @"App log file path is %@", g_strLogFilePath );

		NSDate *now = [NSDate date];
		NSString* strProgramStart = [NSString stringWithFormat:@"[%@] Program start ------------------------------\r\n", now];
	
		// create if needed
		if (![[NSFileManager defaultManager] fileExistsAtPath:g_strLogFilePath]){
			[strProgramStart writeToFile:g_strLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		} else {
			[iOSLogEngine OutputDebugString:strProgramStart];
		}
	}
#endif

}

@end