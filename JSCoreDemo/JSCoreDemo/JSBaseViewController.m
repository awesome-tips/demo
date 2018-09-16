//
//  JSBaseViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "JSBaseViewController.h"

@interface JSBaseViewController ()

@end

@implementation JSBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.context setExceptionHandler:^(JSContext *context, JSValue *exception) {
        NSString *log = [exception toString];
        NSLog(@"exception: %@", log);
    }];
    
    [self registerConsoleCode];
}

- (JSContext *)context
{
    if (!_context) {
        JSVirtualMachine *vm = [[JSVirtualMachine alloc] init];
        _context = [[JSContext alloc] initWithVirtualMachine:vm];
        _context.name = @"lefex.invoke.context";
    }
    return _context;
}

- (void)registerConsoleCode
{
    NSString *consoleJS = @"var global = this;;(function() {if (global.console) {var jsLogger = console.log;global.console.log = function() {global._OC_log.apply(global, arguments);if (jsLogger) {jsLogger.apply(global.console, arguments);}}} else {global.console = {log: global._OC_log}}})()";
    
    self.context[@"_OC_log"] = ^() {
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            NSString *log = [jsVal toString];
            NSLog(@"log => : %@", log);
        }
    };
    [self.context evaluateScript:consoleJS withSourceURL:[NSURL URLWithString:@"consloe.js"]];
}

@end
