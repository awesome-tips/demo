//
//  ViewController.m
//  LEFPatch
//
//  Created by wsy on 2018/6/29.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "ViewController.h"
#import "LEFSwallow.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [LEFSwallow shareInstance].exception = ^(NSString *msg) {
        NSLog(@"error: %@", msg);
    };
    
    [[LEFSwallow excuteCore] startJSCore];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[LEFSwallow excuteCore] excuetAtMainBundleFileWithName:@"demo.js"];
    });
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 40)];
    button.backgroundColor = [UIColor blueColor];
    [button setTitle:@"知识小集" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)clickAction:(UIButton *)sender
{
}

- (void)changeName:(NSString *)name age:(NSInteger)age
{
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self changeName:@"Lefe_x" age:24];
}

@end
