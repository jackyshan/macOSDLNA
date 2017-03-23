//
//  ViewController.m
//  dlna
//
//  Created by jackyshan on 2017/3/19.
//  Copyright © 2017年 jackyshan. All rights reserved.
//

#import "ViewController.h"
#import "ZM_DMRControl.h"
#import "ZM_SingletonControlModel.h"
#import <WebKit/WebKit.h>
#import "DetailViewController.h"

@interface ViewController()<ZM_DMRProtocolDelegate, WebPolicyDelegate, WebFrameLoadDelegate>

@property (weak) IBOutlet WebView *webview;

@property (strong) NSMutableArray *mUrlArray;
@property (assign) NSInteger currentIdx;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] setDelegate:self];
    //启动DMC去搜索设备
    if (![[[ZM_SingletonControlModel sharedInstance] DMRControl] isRunning]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] start];
    }
    
    NSString *url = @"http://192.168.1.106";
    [self.webview.mainFrame loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]]];
    self.webview.policyDelegate = self;
    self.webview.frameLoadDelegate = self;
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - 业务
- (IBAction)goBack:(id)sender {
    if (self.webview.canGoBack) {
        [self.webview goBack];
    }
}

- (IBAction)goFoward:(id)sender {
    if (self.webview.canGoForward) {
        [self.webview goForward];
    }
}

- (IBAction)pauseDevice:(NSButton *)sender {
    if ([sender.title isEqualToString:@"暂停"]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPause];
        [sender setTitle:@"播放"];
    }
    else {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
        [sender setTitle:@"暂停"];
    }
}

- (IBAction)nextHandle:(id)sender {
    if ((self.currentIdx + 1) < self.mUrlArray.count) {
        if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:self.mUrlArray[++self.currentIdx] metaData:nil];
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
        }
    }
}

- (IBAction)lastHandle:(id)sender {
    if ((self.currentIdx - 1) >= 0) {
        if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:self.mUrlArray[--self.currentIdx] metaData:nil];
            [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
        }
    }
}

- (IBAction)goToDetailVc:(id)sender {
    
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
    
    [self.webview stringByEvaluatingJavaScriptFromString:jsGetImages];//注入js方法
    NSString *urlResurlt = [self.webview stringByEvaluatingJavaScriptFromString:@"getUrls()"];
    self.mUrlArray = [NSMutableArray arrayWithArray:[urlResurlt componentsSeparatedByString:@"+"]];
    
    DetailViewController *vc = [[DetailViewController alloc] init];
    vc.videoList = self.mUrlArray;
    [self presentViewControllerAsModalWindow:vc];
    
}

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

/**
 移除DMR
 */
-(void)onDMRRemoved
{
    NSLog(@"%s",__FUNCTION__);
    
}

#pragma mark - ZM_DMRProtocolDelegate

-(void)getCurrentAVTransportActionResponse:(ZM_CurrentAVTransportActionResponse *)response
{
    NSLog(@"%@",response.actions);
}
-(void)getTransportInfoResponse:(ZM_TransportInfoResponse *)response
{
    NSLog(@"cur_transport_state:%@--cur_transport_status:%@--:%@",response.cur_transport_state,response.cur_transport_status,response.cur_speed);
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
}

-(void)previousResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%s",__FUNCTION__);
}

-(void)nextResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%s",__FUNCTION__);
}

-(void)DMRStateViriablesChanged:(NSArray <ZM_EventParamsResponse *> *)response
{
    [response enumerateObjectsUsingBlock:^(ZM_EventParamsResponse * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //NSLog(@"deviceUUID:%@,ServiceID:%@,eventName:%@,eventValue:%@",obj.deviceUUID,obj.serviceID,obj.eventName,obj.eventValue);
    }];
}

-(void)playResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"response.result is %ld in %s",(long)response.result,__FUNCTION__);
}
-(void)pasuseResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%ld in %s",(long)response.result,__FUNCTION__);
}

-(void)stopResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%@ in %s",response.userData,__FUNCTION__);
}

-(void)setAVTransponrtResponse:(ZM_EventResultResponse *)response
{
    NSLog(@"%s",__FUNCTION__);
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getTransportInfo];
}

-(void)setVolumeResponse:(ZM_EventResultResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%s",__FUNCTION__);
    
    
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderGetVolome];
}

-(void)getVolumeResponse:(ZM_VolumResponse *)response
{
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentTransportAction];
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"当前音量:%ld",(long)response.volume);
}

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

//获取加载页面的Title
- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame{
    NSLog(@"title ===== %@",title);
}

//加载完成
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame{
    NSLog(@"~~~~~加载完成~~~~~");
}

//加载失败
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    NSLog(@"~~~~~加载失败~~~~~");
}


@end
