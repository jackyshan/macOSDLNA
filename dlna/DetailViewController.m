//
//  DetailViewController.m
//  dlna
//
//  Created by jackyshan on 2017/3/23.
//  Copyright © 2017年 jackyshan. All rights reserved.
//

#import "DetailViewController.h"
#import "ZM_DMRControl.h"
#import "ZM_SingletonControlModel.h"

@interface DetailViewController ()<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *currentPlayLabel;
@property (assign) NSInteger idx;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.title = @"视频列表";
    
    __weak __typeof(self) wself = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"playNext" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if (!wself || ++wself.idx >= wself.videoList.count) {
            return;
        }        
        NSString *aUrlString = wself.videoList[wself.idx];
        NSLog(@"开始播放%@", aUrlString);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            wself.currentPlayLabel.stringValue = aUrlString.stringByRemovingPercentEncoding;
            
            if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
                [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:aUrlString metaData:nil];
                [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
            }
        });
    }];
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.videoList.count;
}

- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    
    return nil;
}

#pragma mark NSTableViewDelegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    static NSString *cellIdentifier = @"NameCellID";
    
    NSTableCellView *cell = [tableView makeViewWithIdentifier:cellIdentifier owner:nil];
    cell.textField.stringValue = [self.videoList[row] stringByRemovingPercentEncoding];
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"%ld", self.tableView.selectedRow);
    self.idx = self.tableView.selectedRow;
    NSString *aUrlString = self.videoList[self.idx];
    NSLog(@"开始播放%@", aUrlString);
    
    self.currentPlayLabel.stringValue = aUrlString.stringByRemovingPercentEncoding;
    
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:aUrlString metaData:nil];
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
    }
}

@end
