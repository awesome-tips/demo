//
//  LEFUIWebViewViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/2.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "LEFUIWebViewViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface LEFUIWebViewViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;


@end

@implementation LEFUIWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.webView];
    
    [self loadHtmlData];
    
    JSContext *context = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    if (context) {
        NSLog(@"context:%@", context);
    }
    
    NSString *js = @"function add(a, b) {return a + b;};add(1,3)";
    JSValue *result = [context evaluateScript:js];
    NSLog(@"Result: %@", @([result toInt32]));
}

- (void)loadHtmlData
{
//    NSURL *srcURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
//    NSError *error;
//    NSString *html = [NSString stringWithContentsOfURL:srcURL encoding:NSUTF8StringEncoding error:&error];
//    if (error) {
//        NSLog(@"Load html error: %@", error);
//    }
//    [self.webView loadHTMLString:html baseURL:nil];
    
    [self.webView loadHTMLString:[self testHelightDemo] baseURL:nil];
}

- (NSString *)testHelightDemo
{
    NSString *consoleJS = @"var global = this;;(function() {if (global.console) {var jsLogger = console.log;global.console.log = function() {global._OC_log.apply(global, arguments);if (jsLogger) {jsLogger.apply(global.console, arguments);}}} else {global.console = {log: global._OC_log}}})()";
    return consoleJS;
}

- (UIWebView *)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.delegate = self;
    }
    return _webView;
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"didFailLoadWithError");
}

@end
