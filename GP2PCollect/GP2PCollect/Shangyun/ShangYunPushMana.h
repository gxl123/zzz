//
//  ShangYunPushMana.h
//  GoolinkViewEasy
//
//  Created by gxl on 16/10/14.
//
//

#import <Foundation/Foundation.h>

@interface ShangYunPushMana : NSObject
@property(nonatomic,retain) NSString *APIVersionString;

//@property(nonatomic,retain) IBOutlet UITextField *DIDText;
//@property(nonatomic,retain) IBOutlet UITextField *AES128KeyText;
//@property(nonatomic,retain) IBOutlet UITextField *InitStringText;
//@property(nonatomic,retain) IBOutlet UITextField *SendToModeText;
//@property(nonatomic,retain) IBOutlet UITextField *EventCHText;
//@property(nonatomic,retain) IBOutlet UITextView *ShowView;
+ (ShangYunPushMana *)sharedInstance;
// 订阅
- (void) Subscribe:(NSString*)strDID;
// 取消订阅
- (void) UnSubscribe:(NSString*)strDID;
@end
