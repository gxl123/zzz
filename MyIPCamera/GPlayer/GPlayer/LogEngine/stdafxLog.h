//
//  stdafxLog.h
//  LogEngineTest
//

#ifndef __stdafxLog_h
#define __stdafxLog_h


#import "iOSLogEngine.h"


#ifdef LOGTOFILE

//////////////////////////////////////////////////////////////////////////////////////////////////
// To use log engine
//
// 1. Add stdafxLog.h / iOSLogEngine.h / iOSLogEngine.cpp into your project
// 2. Add preprocessing definition LOGTOFILE via Project->Target->Build Settings->Preprocessor Macros under Apple LLVM compiler 4.2 - Preprocessing
// 3. At the program init stage init iOSLogEngine as following
//        [iOSLogEngine initLogEngine:@"Your log file name here"];
// 3. Turn all LOG( ... ) to your log file as well
//

	//#define LOG(fmt, ...) [iOSLogEngine writeLog:[NSString stringWithFormat:(@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__] ];
	//#define LOG(fmt, ...) [iOSLogEngine writeLog:[NSString stringWithFormat:(@"" fmt), ##__VA_ARGS__] ];
	#define LOG(fmt, ...) [iOSLogEngine writeLogWithDateTime:[NSString stringWithFormat:(@"" fmt), ##__VA_ARGS__] ];

//    //轉印NSLog內容至檔案
//    #define NSLog(fmt, ...) [iOSLogEngine writeLogWithDateTime:[NSString stringWithFormat:(@"" fmt), ##__VA_ARGS__]];

#elif DEBUG

	//#define LOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
	#define LOG(fmt, ...) NSLog( @"%@", [NSString stringWithFormat:(@"" fmt), ##__VA_ARGS__] );

#else

	#define LOG(...)
	#endif

#endif
