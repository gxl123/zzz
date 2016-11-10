2016.10.25
    1.封装的UIView无法响应点击事件，是由于创建的对象是临时变量被自动释放导致
    2.UIView嵌套时，点击事件如果不捕捉，会被父视图捕捉
    3.封装库如何加载xib png等资源：
        a.要做调用Porject中Copy Boundle Resources中加入GPlayer.vramework
        b.[super initWithNibName:@"GPlayer.framework/GPlayerViewController" bundle:nil]
        UIImage *image = [UIImage imageNamed:@"GPlayer.framework/moviePlay.png"]
        详细见：http://blog.csdn.net/xyxjn/article/details/42527341

2016.10.26
    1.需要将GLog封装为库使用
