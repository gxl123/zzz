//
//  ViewController.m
//  MyUIApp
//
//  Created by gxl on 16/10/25.
//  Copyright © 2016年 gxl. All rights reserved.
//

#import "ViewController.h"
#import <MyLib/MyLib.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    testViewController *GPVC=[[testViewController alloc]init];
    [GPVC.view setFrame:CGRectMake(0, 0, 300, 400)];
    [self.view addSubview:GPVC.view];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
