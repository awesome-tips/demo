//
//  JSExcuteViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/3.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "JSExcuteViewController.h"
#import "JSExcuteEditerView.h"
#import "JSExcuteConsoleView.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "Member.h"

const NSInteger kEditerViewHeight = 400;

@interface JSExcuteViewController ()

@property (nonatomic, strong) JSExcuteEditerView *editerView;
@property (nonatomic, strong) JSExcuteConsoleView *consoleView;
@property (nonatomic, strong) JSContext *context;

@end

@implementation JSExcuteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"执行JavaScript";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.editerView];
    [self.view addSubview:self.consoleView];
    
    self.editerView.textView.text = @"console.log(\"Hello I am Lefe_x\")";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Run" style:UIBarButtonItemStyleDone target:self action:@selector(runAction)];
    
    __weak typeof(self) weakself = self;
    [self.context setExceptionHandler:^(JSContext *context, JSValue *exception) {
        NSString *log = [exception toString];
        if (log) {
            weakself.consoleView.errorlog = log;
        }
    }];
    
//    [self registerJSCode];
    
//    [self runJSValue];
    
    [self testHelightDemo];
}

- (void)testHelightDemo
{
    NSString *consoleJS = @"var global = this;;(function() {if (global.console) {var jsLogger = console.log;global.console.log = function() {global._OC_log.apply(global, arguments);if (jsLogger) {jsLogger.apply(global.console, arguments);}}} else {global.console = {log: global._OC_log}}})()";
}

- (void)registerJSCode
{
    NSString *consoleJS = @"var global = this;;(function() {if (global.console) {var jsLogger = console.log;global.console.log = function() {global._OC_log.apply(global, arguments);if (jsLogger) {jsLogger.apply(global.console, arguments);}}} else {global.console = {log: global._OC_log}}})()";
    
    __weak typeof(self) weakself = self;
    self.context[@"_OC_log"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            NSString *log = [jsVal toString];
            if (log) {
                [weakself.consoleView addLog:log];
            }
        }
    };
    [self.context evaluateScript:consoleJS withSourceURL:[NSURL URLWithString:@"consloe.js"]];
}

- (void)addAction
{
    NSString *addjs = @"function add(a, b) {return a + b;}";
    [self.context evaluateScript:addjs withSourceURL:[NSURL URLWithString:@"add.js"]];
    JSValue *resultValue = [self.context[@"add"] callWithArguments:@[@2, @4]];
    
    // 执行未定义的函数
//    [self.context[@"sum"] callWithArguments:@[@2, @4]];
    NSLog(@"Result: %@", @([resultValue toInt32]));
}

- (void)excuteJS
{
    [self.context setObject:@"ObjectC" forKeyedSubscript:@"ObjectC_add"];

    NSString *js = @"var name = \"Lefe_x\";var log_name = function(aname){var res = 'Hello ' + aname;console.log(res);};log_name(name);var age = 24;var sum_age = age + 1;";
    [self.context evaluateScript:js withSourceURL:[NSURL URLWithString:@"lefe.js"]];
    
    NSLog(@"%@", [self.context[@"name"] toString]);
    NSLog(@"%@", [self.context[@"sum_age"] toString]);
}

- (void)runJSValue
{

    Member *aMember = [Member new];
    JSValue *value = [JSValue valueWithObject:aMember inContext:self.context];
    [value setValue:@"Lefe_x" forProperty:@"lefe_name"];
    [value setValue:@(24) forProperty:@"lefe_age"];
    [value setValue:@"var sum(a,b){return a + b;}" forProperty:@"sum"];
    
//    JSValue *resValue = [value invokeMethod:@"sum" withArguments:@[@1, @3]];
//    NSLog(@"resValue: %@", [resValue toString]);
}

- (void)runAction
{
    [self excuteJS];
    return;
    
    [self reset];
    [self.view endEditing:YES];
    
    NSString *js = self.editerView.textView.text;
    if ([js length] == 0) {
        [self.editerView.textView becomeFirstResponder];
        return;
    }
    
    JSValue *result = [self.context evaluateScript:js];
    if (![result isUndefined] && ![result isNull]) {
        [self.consoleView addLog:[result toString]];        
    }
}

- (void)reset
{
    self.consoleView.log = @"";
    self.consoleView.errorlog = @"";
}

- (JSExcuteEditerView *)editerView
{
    if (!_editerView) {
        _editerView = [[JSExcuteEditerView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), kEditerViewHeight)];
    }
    return _editerView;
}

- (JSExcuteConsoleView *)consoleView
{
    if (!_consoleView) {
        _consoleView = [[JSExcuteConsoleView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_editerView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-kEditerViewHeight)];
    }
    return _consoleView;
}

- (JSContext *)context
{
    if (!_context) {
        JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
        _context = [[JSContext alloc] initWithVirtualMachine:vm];
        _context.name = @"lefex.context";
    }
    return _context;
}

@end
