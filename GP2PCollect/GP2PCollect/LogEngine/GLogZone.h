//
//  GLogZone.h
//  
//

#ifndef _GLog_Zone_h
#define _GLog_Zone_h

extern unsigned int g_dwGLogZoneSeed;


#define tAll_MSK				-1
#define tUI_MSK					(1)				//trace UI flow
#define tCtrl_MSK				(1<< 1)			//trace Control
#define tMemory_MSK				(1<< 2)			//trace Memory load
#define tPushNotify_MSK			(1<< 3)			//trace TPNS
#define tAudioDecode_MSK		(1<< 4)			//trace audio decode
#define tReStartShow_MSK		(1<< 5)			//
#define tHWDecode_Alex_MSK		(1<< 6)			//trace HWDecode decode
#define tConnect_MSK			(1<< 7)			//trace Connect
#define tAudioSpeak_MSK         (1<< 8)
#define tAudioListen_MSK        (1<< 9)
#define tVideoShow_MSK          (1<< 10)
#define tDecode_MSK				(1<< 11)
#define tOther_MSK              (1<< 12)
#define tTUTKSDK_MSK            (1<< 13)
#define tLangTaoSDK_MSK         (1<< 14)
#define tSonic_MSK              (1<< 15)
#define tSmartlink_MSK          (1<< 16)
#define tTransparent_MSK        (1<< 17)
#define tLangTaoSDKNew_MSK      (1<< 18)
#define tShangYun_MSK           (1<< 19)
#define tShangYunPush_MSK       (1<< 20)

#define tAll					1
#define tUI						(g_dwGLogZoneSeed & tUI_MSK)
#define tCtrl					(g_dwGLogZoneSeed & tCtrl_MSK)
#define tMemory					(g_dwGLogZoneSeed & tMemory_MSK)
#define tPushNotify				(g_dwGLogZoneSeed & tPushNotify_MSK)
#define tAudioDecode			(g_dwGLogZoneSeed & tAudioDecode_MSK)
#define tReStartShow			(g_dwGLogZoneSeed & tReStartShow_MSK)
#define tHWDecode_Alex			(g_dwGLogZoneSeed & tHWDecode_Alex_MSK)
#define tConnect				(g_dwGLogZoneSeed & tConnect_MSK)
#define tAudioSpeak			    (g_dwGLogZoneSeed & tAudioSpeak_MSK)
#define tAudioListen			(g_dwGLogZoneSeed & tAudioListen_MSK)
#define tVideoShow				(g_dwGLogZoneSeed & tVideoShow_MSK)
#define tDecode					(g_dwGLogZoneSeed & tDecode_MSK)
#define tOther					(g_dwGLogZoneSeed & tOther_MSK)
#define tTUTKSDK                (g_dwGLogZoneSeed & tTUTKSDK_MSK)
#define tLangTaoSDK             (g_dwGLogZoneSeed & tLangTaoSDK_MSK)
#define tSonic                  (g_dwGLogZoneSeed & tSonic_MSK)
#define tSmartlink              (g_dwGLogZoneSeed & tSmartlink_MSK)
#define tTransparent            (g_dwGLogZoneSeed & tTransparent_MSK)
#define tLangTaoSDKNew          (g_dwGLogZoneSeed & tLangTaoSDKNew_MSK)
#define tShangYun               (g_dwGLogZoneSeed & tShangYun_MSK)
#define tShangYunPush           (g_dwGLogZoneSeed & tShangYunPush_MSK)
#endif
