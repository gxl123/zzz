//
//  GLog.h
//
//

#ifndef _GLog_h
#define _GLog_h
#import "iOSLogEngine.h"
#ifdef DEBUG

  #ifdef LOGTOFILE
	//#import "iOSLogEngine.h"
	#define GLog(cond,printf_exp) ((cond)?(GLogToFile printf_exp),1:0)

	#define GLogREL(cond,printf_exp) ((cond)?(GLogToFile printf_exp),1:0)
  #else
	#define GLog(cond,printf_exp) ((cond)?(NSLog printf_exp),1:0)

	#define GLogREL(cond,printf_exp) ((cond)?(NSLog printf_exp),1:0)
  #endif

#else

  #ifdef LOGTOFILE
	//#import "iOSLogEngine.h"
	#define GLog(cond,printf_exp) ((cond)?(GLogToFile printf_exp),1:0)

	#define GLogREL(cond,printf_exp) ((cond)?(GLogToFile printf_exp),1:0)
  #else
	#define GLog(cond,printf_exp)

	#define GLogREL(cond,printf_exp) ((cond)?(NSLog printf_exp),1:0)
  #endif

#endif

#endif
