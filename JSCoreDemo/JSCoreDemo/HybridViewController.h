//
//  HybridViewController.h
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/5/21.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


@interface HybridViewController : UIViewController

@property (nonatomic, strong) WKWebView *webView;

- (WKWebView *)webView;

@end
