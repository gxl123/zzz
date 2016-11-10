//
//  GPlayerViewController.m
//  MyIPCamera
//
//  Created by gxl on 16/10/24.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "GPlayerViewController.h"
#import "EZGLView.h"
@interface GPlayerViewController (){
    BOOL _isStartVideo,_isStartAudio,_isStartSpeak;
    UIView *_topView;
    EZGLView *_glView;
}
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;



@end

@implementation GPlayerViewController

- (id)init
{
    //if ((self = [super init]))
    if ((self = [super initWithNibName:@"GPlayer.framework/GPlayerViewController" bundle:nil]))
    {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // Do any additional setup after loading the view from its nib.
    //单击
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    [_glView addGestureRecognizer:singleFingerTap];
    
    UIImage *image = [UIImage imageNamed:@"GPlayer.framework/moviePlay.png"];
    [_playButton setImage:image forState:UIControlStateNormal];
    
    
    
    _glView = [[EZGLView alloc]initWithFrame:CGRectMake(0, 0, 0, 0)];;
    
//    
//     [self.view setBackgroundColor:[UIColor greenColor]];
//        _topView=[[UIView alloc]init];
//        [_topView setBackgroundColor:[UIColor grayColor]];
//        //[self.view setFrame:frame];
//        [_topView setFrame:CGRectMake(0, 0, 300, 200)];
//       // [self.view addSubview:_topView];
//    //[_topView setUserInteractionEnabled:YES];
//    
//    _playButton=[[UIButton alloc]init];
//    
//    [_playButton setBackgroundColor:[UIColor blueColor]];
//    [_playButton addTarget:self action:@selector(clickedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
//    
//     [_playButton setFrame:CGRectMake(20, 0, 60, 60)];
//    //[_topView addSubview:_playButton];
//     [_playButton setTitle:@"播放" forState:UIControlStateNormal];
//    //[self.view setUserInteractionEnabled:YES];
////    [self.view setExclusiveTouch:YES];
//    
//    //单击
//    UITapGestureRecognizer *singleFingerTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap2:)];
//    [_topView addGestureRecognizer:singleFingerTap2];
 
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSLog(@"%s",__FUNCTION__);
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_glView updateFrame:self.view.bounds];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleSingleTap:(UITapGestureRecognizer*)singleTap
{
        NSLog(@"%s singleTap=%@",__FUNCTION__,singleTap);
    _bottomView.hidden=!_bottomView.hidden;
   // _topView.hidden=!_topView.hidden;

}
- (IBAction)handleSingleTap2:(UITapGestureRecognizer*)singleTap
{
    NSLog(@"%s singleTap=%@",__FUNCTION__,singleTap);
}
- (IBAction)clickedPlayButton:(id)sender {
    NSLog(@"%s",__FUNCTION__);
    _isStartVideo=!_isStartVideo;
    if (_callbackDelegate && [_callbackDelegate respondsToSelector:_isStartVideo?@selector(didStartVideo):@selector(didStopVideo)])
        _isStartVideo? [_callbackDelegate didStartVideo]: [_callbackDelegate didStopVideo];
}
- (IBAction)clickedListenButton:(id)sender {
}
- (IBAction)clickedSpeakButton:(id)sender {
}


- (void)setFrame:(CGRect)frame
{
    [self.view setFrame:frame];
    [_topView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];
    [_playButton setFrame:CGRectMake(0, 100, self.view.bounds.size.width, 80)];
}
//开始显示视频
-(void)playVideo:(NSData*)videoData{
    NSLog(@"%s",__FUNCTION__);
}
//停止显示视频
-(void)stopVideo{
    NSLog(@"%s",__FUNCTION__);

}

//视频显示
- (void)renderShow:(NSData *)data frameWidth:(int)width frameHeight:(int)height framerate:(int)framerate{
  
    
    if (_isStartVideo )
    {
//        if ([[EZApplicationPreference sharedInstance] isFullScreen]) {
//            [_glView renderOnFullScreen: data frameWidth:width frameHeight:height];
//        }else{
            [_glView render:data frameWidth:width frameHeight:height];
//        }
    }
    
}

@end
