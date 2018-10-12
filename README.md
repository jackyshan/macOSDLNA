![image](http://upload-images.jianshu.io/upload_images/301129-7d0850bb7feaf65f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

DLNA的全称是DIGITAL LIVING NETWORK ALLIANCE(数字生活网络联盟)， 其宗旨是Enjoy your music, photos and videos, anywhere anytime， DLNA(Digital Living Network Alliance) 由索尼、英特尔、微软等发起成立、旨在解决个人PC，消费电器，移动设备在内的无线网络和有线网络的互联互通，使得数字媒体和内容服务的无限制的共享和增长成为可能，目前成员公司已达280多家。

### 1、使用第三方库Neptune和Platinum
下载Platinum工程，carthage update安装，打开universal-apple-macosx工程编译生成Platinum.framework和Neptune.framework

Neptune : a C++ Runtime Library
https://github.com/plutinosoft/Platinum
Platinum: a modular UPnP Framework [Platinum depends on Neptune]
https://github.com/plutinosoft/Neptune

### 2、对Platinum库进行封装实现DLNA扫描连接等功能

开启代理，启动搜索

    [[[ZM_SingletonControlModel sharedInstance] DMRControl] setDelegate:self];
    //启动DMC去搜索设备
    if (![[[ZM_SingletonControlModel sharedInstance] DMRControl] isRunning]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] start];
    }

搜索到设备，开始连接

    #pragma mark - ZM_DMRProtocolDelegate
    - (void)onDMRAdded {
        NSLog(@"%s",__FUNCTION__);
        
        NSArray *devices = [[NSMutableArray alloc] initWithArray:[[[ZM_SingletonControlModel sharedInstance] DMRControl] getActiveRenders]];
        [devices enumerateObjectsUsingBlock:^(ZM_RenderDeviceModel  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"搜索到设备%@", obj.name);
        }];
        
        if (devices.count <= 0) {
            return;
        }
        
        NSLog(@"开始连接设备");
        
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] chooseRenderWithUUID:[devices[0]uuid]];
        ZM_RenderDeviceModel *model = [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender];
        
        self.title = [NSString stringWithFormat:@"已连接盒子%@", [devices[0] name]];
        
        NSLog(@"连接设备设备名%@，设备地址%@", model.name, model.descriptionURL);
    }

开始播放视频连接

        if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:@"视频地址" metaData:nil];
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
        }

### 3、实现播放webview视频连接功能

    #pragma mark - WebPolicyDelegate
    //获取每次加载页面的request
    - (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type
            request:(NSURLRequest *)request
              frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener{
        
        NSLog(@"request=======%@",request);
        
        NSString *aUrlString = request.URL.absoluteString;
        
        if (![aUrlString hasSuffix:@"mkv"]) {
            return;
        }
        
        [listener ignore];
        
        //这里是js，主要目的实现对url的获取
        static  NSString * const jsGetImages =
        @"function getUrls(){\
        var objs = document.getElementsByTagName(\"a\");\
        var imgScr = '';\
        for(var i=0;i<objs.length;i++){\
        imgScr = imgScr + objs[i].href + '+';\
        };\
        return imgScr;\
        };";
        
        [webView stringByEvaluatingJavaScriptFromString:jsGetImages];//注入js方法
        
        NSString *urlResurlt = [webView stringByEvaluatingJavaScriptFromString:@"getUrls()"];
        
        self.mUrlArray = [NSMutableArray arrayWithArray:[urlResurlt componentsSeparatedByString:@"+"]];
        
        if (self.mUrlArray.count > 0) {
            self.currentIdx = [self.mUrlArray indexOfObject:aUrlString];
            
            if (self.currentIdx < 0) {
                return;
            }
            
            NSLog(@"开始播放%@", aUrlString);

            if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
                [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:self.mUrlArray[self.currentIdx] metaData:nil];
                [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
            }
        }
    }

