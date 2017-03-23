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

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.title = @"视频列表";
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
    cell.textField.stringValue = self.videoList[row];
    
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSLog(@"%ld", self.tableView.selectedRow);
    
    NSString *aUrlString = self.videoList[self.tableView.selectedRow];
    NSLog(@"开始播放%@", aUrlString);
    
    if ([[[ZM_SingletonControlModel sharedInstance] DMRControl] getCurrentRender]) {
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetAVTransportWithURI:aUrlString metaData:nil];
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderPlay];
        [[[ZM_SingletonControlModel sharedInstance] DMRControl] renderSetNextAVTransportWithURI:self.videoList[self.tableView.selectedRow + 1]];
    }
}

@end
