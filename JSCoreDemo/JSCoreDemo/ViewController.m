//
//  ViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/4.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "ViewController.h"
#import "LEFWebViewController.h"
#import "HybridViewController.h"
#import "LEFUIWebViewViewController.h"
#import "JSExcuteViewController.h"
#import "EditerViewController.h"
#import "JSExportViewController.h"
#import "Runtime.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView *_tableView;
    NSArray *_dataSource;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"JavaScript";
    
    _dataSource = @[NSStringFromClass([LEFWebViewController class]),
                    NSStringFromClass([HybridViewController class]),
                    NSStringFromClass([LEFUIWebViewViewController class]),
                    NSStringFromClass([JSExcuteViewController class]),
                    NSStringFromClass([EditerViewController class]),
//                    NSStringFromClass([InvokeViewController class]),
                    NSStringFromClass([JSExportViewController class])];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview:_tableView];
    
    [_tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ID"];
    }
    cell.textLabel.text = _dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
     UIViewController *vc = [[NSClassFromString(_dataSource[indexPath.row]) alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
