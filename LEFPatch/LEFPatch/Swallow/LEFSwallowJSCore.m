//
//  LEFSwallowJSCore.m
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "LEFSwallowJSCore.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "LEFSwallowRuntime.h"
#import "LEFSwallowDef.h"
#import "LEFSwallowWrap.h"
#import "LEFSwallowValueFormat.h"
#import "LEFSwallow.h"

static NSString * const kMainSwallowFileName = @"swallow.js";

static NSString *_regexStr = @"(?<!\\\\)\\.\\s*(\\w+)\\s*\\(";
static NSString *_replaceStr = @".__c(\"$1\")(";
static NSRegularExpression* _regex;

@interface LEFSwallowJSCore()
@property (nonatomic, strong) JSContext *context;
@property (nonatomic, strong) LEFSwallowRuntime *runtime;
@end

@implementation LEFSwallowJSCore

- (instancetype)init
{
    self = [super init];
    if (self) {
        _runtime = [[LEFSwallowRuntime alloc] init];
        _exception = ^(NSString *msg) {
            NSLog(@"JS exception: %@", msg);
        };
    }
    return self;
}

// 执行上下文
- (JSContext *)context
{
    if (!_context) {
        _context = [[JSContext alloc] init];
        _context.name = @"lefe.swallow.context";
        __weak typeof(self) weakself = self;
        _context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
            weakself.exception([exception toString]);
        };
        _context[@"_OC_null"] = [LEFSwallow shareInstance].nilObj;

    }
    return _context;
}

// 提前执行 swallow.js 中的 js 代码，为 js 执行环境提供必要的方法
- (void)startJSCore
{
    NSString *filepath = [[NSBundle mainBundle] pathForResource:kMainSwallowFileName ofType:nil];
    
    NSString *js = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:filepath] encoding:NSUTF8StringEncoding];
    
    [self.context evaluateScript:js withSourceURL:[NSURL URLWithString:kMainSwallowFileName]];
    
    [self registerGolableMethodToContext];
}

// 执行某个文件中的 JS 代码
- (void)excuteAtFilePath:(NSString *)filepath
{
    if (!filepath) {
        if (self.exception) {
            self.exception(@"The swallow.js file is not found!");
        }
        return;
    }
    
    if (!_regex) {
        _regex = [NSRegularExpression regularExpressionWithPattern:_regexStr options:0 error:nil];
    }
    
    NSString *js = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:filepath] encoding:NSUTF8StringEncoding];
    
    // 所有的方法前需要添加 __c
    NSString *formatScript = [NSString stringWithFormat:@";(function(){try{\n%@\n}catch(e){_OC_catch(e.message, e.stack)}})();", [_regex stringByReplacingMatchesInString:js options:0 range:NSMakeRange(0, js.length) withTemplate:_replaceStr]];
    
    [self.context evaluateScript:formatScript withSourceURL:[NSURL URLWithString:[filepath lastPathComponent]]];
}

- (void)excuetAtMainBundleFileWithName:(NSString *)filename
{
    NSString *filepath = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    [self excuteAtFilePath:filepath];
}

- (void)registerGolableMethodToContext
{
    __weak typeof(self) weakself = self;
    
    // _OC_defineClass 需要替换或新增的方法
    self.context[@"_OC_defineClass"] = ^id(NSString *declaration, JSValue *instanceMethod, JSValue *classMethods) {
        return [weakself.runtime defineClassWithDeclaration:declaration instanceMethods:instanceMethod classMethods:classMethods context:weakself.context];
    };
    
    // consloe.log -> NSLog
    self.context[@"_OC_log"] = ^(){
        NSArray *args = [JSContext currentArguments];
        for (JSValue *jsVal in args) {
            id obj = [LEFSwallowValueFormat formatJSToOC:jsVal];
            NSLog(@"Swallow: %@", obj == [LEFSwallow shareInstance].nilObj ? nil : (obj == [LEFSwallow shareInstance].nullObj ? [NSNull null]: obj));
        }
    };
    
    // try-catch
    self.context[@"_OC_catch"] = ^(JSValue *msg, JSValue *stack) {
        NSLog(@"catch: %@", [NSString stringWithFormat:@"%@ - %@", [msg toObject], [stack toObject]]);
    };
    
    // 调用实例方法
    self.context[@"_OC_callI"] = ^id(JSValue *obj, NSString *selectorName, JSValue *arguments, BOOL isSuper) {
        NSLog(@"_OC_callI: %@, obj: %@", selectorName, [obj toObject]);
        return [LEFSwallowRuntime callSelectorWithClassName:nil selectorName:selectorName arguments:arguments instance:obj isSuper:isSuper];
    };
    
    // 调用类方法
    self.context[@"_OC_callC"] = ^id(NSString *className, NSString *selectorName, JSValue *arguments) {
        NSLog(@"_OC_callC: %@, obj: %@", className, selectorName);
        return [LEFSwallowRuntime callSelectorWithClassName:className selectorName:selectorName arguments:arguments instance:nil isSuper:NO];
    };
    
}

#pragma mark - 类型转换
@end
