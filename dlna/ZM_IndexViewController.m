//
//  ZM_IndexViewController.m
//  PlatinumDemo
//
//  Created by GVS on 16/11/24.
//  Copyright © 2016年 GVS. All rights reserved.
//

#import "ZM_IndexViewController.h"
#import "ZM_DMRControl.h"
#import "ZM_SingletonControlModel.h"
@interface ZM_IndexViewController ()<UITableViewDelegate,UITableViewDataSource,ZM_DMRProtocolDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<ZM_RenderDeviceModel *> * dataArray;
@property (weak, nonatomic) IBOutlet UILabel *LocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *InfoLabel;

@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end
static NSString * cellIdentifier = @"cell";

@implementation ZM_IndexViewController
{
    NSArray * _playList;
    NSInteger _index;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.InfoLabel.text = @"";
    self.LocationLabel.text = @"";
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] setDelegate:self];
    //启动DMC去搜索设备
    if (![[[ZM_SingletonControlModel sharedInstance] DMRControl] isRunning]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] start];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.playBtn.selected = NO;
    _playList = @[@"http://192.168.1.106/tv/%e7%96%91%e7%8a%af%e8%bf%bd%e8%b8%aa.Person.of.Interest.S03E01.%e4%b8%ad%e8%8b%b1%e5%ad%97%e5%b9%95.WEB-HR.AC3.1024X576.x264-YYeTs%e4%ba%ba%e4%ba%ba%e5%bd%b1%e8%a7%86.mkv",
                  @"http://bla.gtimg.com/qqlive/201609/BRDD_20160920182023501.mp4",
                  @"http://up.haoduoge.com:82/mp3/2016-07-22/1469188914.mp3"];
    
    _index = 0;
    
    //监听系统音量的变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] stop];
}
//重新搜索，刷新
- (IBAction)reSearchDevice:(id)sender {
    NSLog(@"%s",__FUNCTION__);
    //删掉所有设备
    [self.dataArray removeAllObjects];
    //重启DMC
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] restart];
    //获取新设备
    self.dataArray = [[NSMutableArray alloc] initWithArray:[[[ZM_SingletonControlModel sharedInstance] DMRControl] getActiveRenders]];
}
-(void)playMusic
{
    if (_index > 2) {
        _index = 0;
    }
    if (_index < 0) {
        _index = 2;
    }
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:_playList[_index] metaData:nil];
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
}


#pragma mark - SB方法
- (IBAction)previousBtnHandle:(id)sender {
    
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        _index --;
        [self playMusic];
    }
}
- (IBAction)playBtnHandle:(id)sender {
    
    self.playBtn.selected = !self.playBtn.isSelected;
    if (self.playBtn.isSelected) {
        [self.playBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
    }else{
        [self.playBtn setTitle:@"播放" forState:UIControlStateNormal];
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPause];
    }
    
}
- (IBAction)nextBtnHandle:(id)sender {
    
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        _index ++;
        [self playMusic];
    }
}
- (IBAction)stopBtnHandle:(id)sender {
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderStop];
    }
    
}

-(void)changeInfoLabel
{
    
    NSString * string = [NSString stringWithFormat:@"正在播放的是第%ld首，共%ld首。",_index,_playList.count];
    self.InfoLabel.text = string;
}
-(void)volumeChanged:(NSNotification *)noti
{
    float systemVolume = [[noti.userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetVolume:(systemVolume*100)];
    }
    
}

#pragma mark - ZM_DMRProtocolDelegate
-(void)onDMRAdded
{
    self.dataArray = [[NSMutableArray alloc] initWithArray:[[[ZM_SingletonControlModel sharedInstance] DMRControl] getActiveRenders]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    NSLog(@"%s",__FUNCTION__);
}

/**
 移除DMR
 */
-(void)onDMRRemoved
{
    NSLog(@"%s",__FUNCTION__);
    self.dataArray = [[NSMutableArray alloc] initWithArray:[[[ZM_SingletonControlModel sharedInstance] DMRControl] getActiveRenders]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });

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


#pragma mark - UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.textColor = [UIColor blackColor];
    [cell.textLabel sizeToFit];
    [cell.textLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [cell.textLabel setNumberOfLines:0];
    cell.textLabel.text = [self.dataArray[indexPath.row] name];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.playBtn setTitle:@"暂停" forState:UIControlStateNormal];
    self.playBtn.selected = YES;
    [[[ZM_SingletonControlModel sharedInstance] DMRControl] chooseRenderWithUUID:[self.dataArray[indexPath.row] uuid]];
    ZM_RenderDeviceModel * model = [[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender];
    self.LocationLabel.text = @"";
    //self.LocationLabel.text = model.descriptionURL;
    NSLog(@"设备地址:%@",model.descriptionURL);
    [self playMusic];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
