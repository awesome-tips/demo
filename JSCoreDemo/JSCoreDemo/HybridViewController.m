//
//  HybridViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/5/21.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "HybridViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

// /Library/WebServer/Documents/hybird
// http://127.0.0.1/javascropt/index.html
// http://172.24.184.134/javascropt/index.html
// https://mp.weixin.qq.com/s/0OR4HJQSDq7nEFUAaX1x5A

static NSString *kScriptMsgName = @"JSBridge";
static NSString *kSaveKey = @"bridge.save";
static NSString *kWebURL = @"http://172.24.93.246/javascropt/index.html";
static NSString *kATWebURL = @"http://172.24.93.246/javascropt/index.html";



//static WKWebView *_webView;
static BOOL flag;

@interface HybridViewController ()<UINavigationBarDelegate, WKUIDelegate, WKScriptMessageHandler, WKNavigationDelegate>

@property (nonatomic, assign) BOOL isOKAction;

@end

@implementation HybridViewController

- (void)dealloc
{
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:kScriptMsgName];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"知识小集";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearAction)];
    [self.view addSubview:self.webView];
    
    /**
     给 JS 注入一个 callOCMethod 的方法，那么在 JS 中既可以调用这个方法
     */
    NSString *js = @"function callOCMethod(){alert(\"Call oc action\");}";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [self.webView.configuration.userContentController addUserScript:script];
    [self loadHtmlData];
    
//    JSContext *context = [_webView valueForKeyPath:@"documentView"];
//    NSLog(@"context: %@", context);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    [self.webView loadHTMLString:@"" baseURL:nil];
}

- (void)loadDataFromServer
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://yd.baidu.com/aiting/index"]];
    [self.webView loadRequest:request];
}

- (void)loadHtmlData
{
    NSURL *srcURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"html"]];
    if (flag) {
        srcURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
    }
    NSError *error;
    NSString *html = [NSString stringWithContentsOfURL:srcURL encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Load html error: %@", error);
    }
    [self.webView loadHTMLString:html baseURL:nil];
    
    flag = !flag;
}

- (WKWebView *)webView
{
    if (_webView) {
        return _webView;
    }
    
    WKWebViewConfiguration *con = [[WKWebViewConfiguration alloc] init];
    con.preferences = [WKPreferences new];
    con.preferences.javaScriptEnabled = YES;
    _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:con];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    [_webView.configuration.userContentController addScriptMessageHandler:self name:kScriptMsgName];
    
    return _webView;
}

#pragma mark - UINavigationBarDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.isOKAction = YES;
        completionHandler();
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.isOKAction = NO;
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    NSLog(@"runJavaScriptConfirmPanelWithMessage");
    completionHandler(YES);
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    NSLog(@"runJavaScriptTextInputPanelWithPrompt");
    completionHandler(@"OC input");
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
//    window.webkit.messageHandlers.JSBridge.postMessage({"name" : "Lefe_x"});
//    当在一个网页中调用 window.webkit.messageHandlers.[xxx].postMessage 时，客户端会在这个方法中接收消息
    NSLog(@"userContentController: body=%@, name: %@", message.body, message.name);
    
    
    if ([message.body isKindOfClass:[NSString class]]) {
        if ([message.name isEqualToString:kScriptMsgName] && self.isOKAction) {
            // 保存图片
            NSDictionary *msgInfo = [NSJSONSerialization JSONObjectWithData:[message.body dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
            NSString *url = msgInfo[@"url"];
            if (!url) {
                return;
            }
            UIImage *image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
            if (image) {
                UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSavedToPhotosAlbum:didFinishSavingWithError:contextInfo:), nil);
            }
        }
    }
}

#pragma mark -
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView == self.webView) {
        NSLog(@"didFinishNavigation");
        [self updateSaveState:[self isHaveSaved]];
        
//        NSString *js = @"(function() {var script = document.createElement('script');script.type = 'text/javascript';script.src = 'https://xteko.blob.core.windows.net/neo/eruda-loader.js';document.body.appendChild(script);})();";
//        [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable info, NSError * _Nullable error) {
//            NSLog(@"erro ===== %@", error);
//        }];
    }
}

#pragma mark - Helper
- (void)imageSavedToPhotosAlbum:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(id)contextInfo
{
    if (error) {
        NSLog(@"Save image error");
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSaveKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 在 OC 中执行 JS 代码
    NSLog(@"Save image success");
    [self updateSaveState:YES];
}

- (void)updateSaveState:(BOOL)isSave
{
    NSString *script = isSave ? @"change_state(true);" : @"change_state(false);";
    [self.webView evaluateJavaScript:script completionHandler:^(id _Nullable msg, NSError * _Nullable error) {
        NSLog(@"evaluateJavaScript: %@", msg);
    }];
    
    [self.webView evaluateJavaScript:@"function add(a, b) {return a + b;};add(1,3)" completionHandler:^(id _Nullable msg, NSError * _Nullable error) {
        NSLog(@"evaluateJavaScript add: %@, error: %@", msg, error);
    }];
}

- (BOOL)isHaveSaved
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSaveKey];
}

- (void)clearAction
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSaveKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.webView reloadFromOrigin];
}
    
@end
