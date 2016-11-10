//
//  ViewController.m
//  MyIPCamera
//
//  Created by gxl on 16/10/24.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "ViewController.h"
#import "testViewController.h"
#import <GPlayer/GPlayer.h>
#import <GP2PCollect/GP2PCollect.h>
@interface ViewController (){
    Device* dv;
    GPlayerViewController *GPVC;
    testViewController *GPVC2;
    TutkDevice* SYD;
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //单击
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    GPVC=[[GPlayerViewController alloc]initWithNibName:@"GPlayer.framework/GPlayerViewController" bundle:nil];
    GPVC=[[GPlayerViewController alloc]init];
    //GPVC2=[[testViewController alloc]init];
    [GPVC.view setFrame:CGRectMake(0, 0, 300, 400)];
    //[GPVC setFrame:CGRectMake(0, 0, 300, 400)];
    [self.view addSubview:GPVC.view];
    //[GPVC.view setExclusiveTouch:YES];
    //[GPVC.view setUserInteractionEnabled:YES];
    //[GPVC.view setBackgroundColor:[UIColor greenColor]];
    //[GPVC.bttest setBackgroundColor:[UIColor orangeColor]];
    //[GPVC.topView2 setBackgroundColor:[UIColor redColor]];
    //[GPVC playVideo:nil];
    NSLog(@"%s",__FUNCTION__);
}
- (IBAction)handleSingleTap:(UITapGestureRecognizer*)singleTap
{
        NSLog(@"%s",__FUNCTION__);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSLog(@"%s",__FUNCTION__);
//    BOOL isinView = NO;
//    UIView *clickView = nil;
//    for (UIView *showView in self.currentShowItemViewArray)
//    {
//        CGRect rect = showView.frame;
//        if ([showView isKindOfClass:[MyTabBarView class]])
//            rect = showView.bounds;
//        
//        isinView = CGRectContainsPoint(rect , point);
//        if (isinView)
//        {
//            clickView = showView;
//            break;
//        }
//    }
//    
//    if (isinView)
//        return clickView;
    return nil;
}

- (IBAction)clickedInitBt:(id)sender {
    SYD=[[TutkDevice alloc]init];
    SYD.udid=@"DBGT9G5P9RYLBH6MY7FJ";
    SYD.password=@"admin";
    [SYD startConnect];
    [SYD startLive];
 
    
}
- (IBAction)clickedConnectBt:(id)sender {
   // [SYD startConnect];
}
- (IBAction)clickedStartVideoBt:(id)sender {
   // [SYD startLive];
}

@end
