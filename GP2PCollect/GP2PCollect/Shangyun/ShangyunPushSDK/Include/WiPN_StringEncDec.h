/*
//  CS2 Network LIMITED All right reserved.
//
//  WiPN_StringEncDec.h: The Web iPN String Enc / Dec include file
//  Author: Charlie Chang (sengfu@gmail.com)
//
*/
#include "NDT_Type.h"
int iPN_StringEnc(const CHAR *keystr, const CHAR *src, CHAR *dest, UINT32 maxsize);
int iPN_StringDnc(const CHAR *keystr, const CHAR *src, CHAR *dest, UINT32 maxsize);
void Base64_Decode(const char *b64src, char *dststr);
void Base64_Encode(const char *scrstr, char *b64dst);