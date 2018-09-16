//
//  LEFWebViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/4/4.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "LEFWebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "Person.h"
#import <WebKit/WebKit.h>


@interface LEFWebViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong) JSContext *webviewContext;

@end

@implementation LEFWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
    [self loadHtmlFromURL:@"https://www.baidu.com/"];
    
    [self excuteJS];
    
    [self excuteBlcokOC];
    [self excureExportProtocolOC];
    
}

#pragma mark - OC 执行 js 代码
- (void)excuteJS
{
    // 监听执行错误
    [self.context setExceptionHandler:^(JSContext *context, JSValue *exception) {
        NSLog(@"exception : %@", exception);
    }];
    
    // 执行一个 JS 脚本，返回值为最后执行完的值
    JSValue *jsValue = [self.context evaluateScript:@"19+2"  withSourceURL:[NSURL URLWithString:@"lefex.js"]];
    NSInteger result = [jsValue toInt32];
    NSLog(@"Excute js :%@", @(result));
    
    [self.context evaluateScript:@"var names = ['lefex', 'lwsy']"  withSourceURL:[NSURL URLWithString:@"lefex.js"]];
    // 通过下标获取上下文的值
    NSArray *names = [self.context[@"names"] toArray];
    // 通过objectForKeyedSubscript获取上下文的值
    NSArray *names2 = [[self.context objectForKeyedSubscript:@"names"] toArray];
    NSLog(@"Excute js names: %@, names2: %@", names, names2);
    
    JSValue *addValue = [self.context evaluateScript:@"function add(a, b) {return a + b;}var add_result = add(1, 4);"  withSourceURL:[NSURL URLWithString:@"lefex.js"]];
    // 无返回值，所有 addValue 为 0
    NSLog(@"Excute js add value: %@", @([addValue toInt32]));
    // 获取js上下午种的 add_result
    NSLog(@"Excute js add value: %@", @([self.context[@"add_result"] toInt32]));
    
    [self.context evaluateScript:@"function add(a, b) {return a + b;}"];
    // 调用 JS 函数
    JSValue *addValue2 = [self.context[@"add"] callWithArguments:@[@2, @3] ];
    NSLog(@"Excute js add value2: %@", @([addValue2 toInt32]));
    
    // 执行一个有错误的 JS 代码
    [self.context evaluateScript:@"function multiply(value1, value2) { return value1 * value2" withSourceURL:[NSURL URLWithString:@"lefex.js"]];
}

#pragma mark - js 执行 OC 代码
- (void)excuteBlcokOC
{
    // 通过 Block 让 JS 调用 OC 的代码
    self.context[@"multiply"] = ^(NSInteger a, NSInteger b){
        NSLog(@"a*b = %@", @(a * b));
    };
    
    [self.context evaluateScript:@"multiply(2,3)"  withSourceURL:[NSURL URLWithString:@"lefex.js"]];
}

- (void)excureExportProtocolOC
{
    Person *lefe_x = [[Person alloc] init];
    
    [self.context setExceptionHandler:^(JSContext *context, JSValue *exception) {
        NSLog(@"exception : %@", exception);
    }];
    
    self.context[@"OCObj"] = lefe_x;
    
    // 这里需要注意 addAndB 是OC的方法 add:andB 转换而成
    // addLefex 是 JSExportAs 重命名的方法名称
    JSValue *resValue = [self.context evaluateScript:@"OCObj.sum = OCObj.addLefex(2,3)"  withSourceURL:[NSURL URLWithString:@"lefex.js"]];
    
    NSLog(@"js sum: %@", @([resValue toInt32]));
    NSLog(@"lefe_x sum: %@", @(lefe_x.sum));

}

#pragma mark - Context
- (JSContext *)context
{
    if (_context) {
        return _context;
    }
    JSVirtualMachine *virtureMachine = [[JSVirtualMachine alloc] init];
    _context = [[JSContext alloc] init];
    _context.name = @"lefex.context";
    return _context;
}

#pragma mark - WebView
- (void)loadHtmlFromURL:(NSString *)url
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"didFinishNavigation");
//    self.webviewContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    NSLog(@"webviewContext: %@", self.webviewContext);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailNavigation");
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"didStartProvisionalNavigation");
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (decisionHandler) {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    NSLog(@"decidePolicyForNavigationAction");
}

- (WKWebView *)webView
{
    if (_webView) {
        return _webView;
    }
    
    _webView = ({
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.preferences = [WKPreferences new];
        config.preferences.minimumFontSize = 10;
        config.preferences.javaScriptEnabled = YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        WKWebView *view = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
        view.navigationDelegate = self;
        view;
    });
    return _webView;
}

@end
