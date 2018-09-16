//
//  LEFSwallowRuntime.m
//  LEFPatch
//
//  Created by wsy on 2018/7/7.
//  Copyright © 2018年 WSY. All rights reserved.
//

#import "LEFSwallowRuntime.h"
#import "NSString+swallow.h"
#import "LEFSwallowWrap.h"
#import "LEFSwallowDef.h"
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "LEFSwallowValueFormat.h"
#import "LEFSwallow.h"

static JSContext *_context;
// 被覆盖或者新加的 JS 函数
static NSMutableDictionary *_JSOverideMethodDict;
static NSMutableDictionary *_JSMethodSignatureCache;
static NSLock *_JSMethodSignatureLock;

static NSMutableDictionary *_currentInvokeSuperClsName;

@interface LEFSwallowRuntime()
{
    
}
@end


@implementation LEFSwallowRuntime

- (instancetype)init
{
    self = [super init];
    if (self) {
        _JSOverideMethodDict = [NSMutableDictionary dictionary];
        _currInvokeSuperClsName = [NSMutableDictionary dictionary];
        self.exception = ^(NSString *msg) {
            NSLog(@"runtime error: %@", msg);
        };
    }
    return self;
}

- (NSDictionary *)defineClassWithDeclaration:(NSString *)declaration
                   instanceMethods:(JSValue *)instanceValue
                      classMethods:(JSValue *)classValue
                           context:(JSContext *)context
{
    _context = context;
    
    // LEFTableViewController : UITableViewController <UIAlertViewDelegate>
    NSScanner *scanner = [NSScanner scannerWithString:declaration];
    
    NSString *className;
    NSString *superClassName;
    NSString *protocolNames;
    
    [scanner scanUpToString:@":" intoString:&className];
    if (!scanner.isAtEnd) {
        scanner.scanLocation = scanner.scanLocation + 1;
        [scanner scanUpToString:@"<" intoString:&superClassName];
        if (!scanner.isAtEnd) {
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@">" intoString:&protocolNames];
        }
    }
    
    if (!superClassName) {
        superClassName = @"NSObject";
    }
    
    className = [className trim];
    superClassName = [superClassName trim];
    
    Class cls = NSClassFromString(className);
    if (!cls) {
        // 当前的类不存在，需要新增类
        Class superCls = NSClassFromString(superClassName);
        if (!superCls) {
            // 没有父类，不予新增
            self.exception(@"The class must have supper class");
            return @{@"cls": className};;
        }
        
        // 创建类
        objc_allocateClassPair(superCls, className.UTF8String, 0);
        objc_registerClassPair(cls);
    }
    
    NSArray<NSString *> *protocols = [protocolNames componentsSeparatedByString:@","];
    if (protocols.count > 0) {
        [protocols enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *protocolName = [obj trim];
            // 添加协议
            Protocol *pro = objc_getProtocol(protocolName.UTF8String);
            class_addProtocol(cls, pro);
        }];
    }
    
    // 覆盖或添加实例方法
    JSValue *jsMethods = instanceValue;
    NSDictionary *jsMethodDict = [jsMethods toDictionary];
    if (!jsMethodDict) {
        self.exception([NSString stringWithFormat:@"Instance methods error: %@", jsMethodDict]);
        return @{@"cls": className};;
    }
    
    /**
     所有被替换或者新加的方法都会经过 swallow.js 处理，处理完后是一个 [参数个数，自定义js函数] 的数组
     */
    for (NSString *jsMethodName in jsMethodDict.allKeys) {
        // 获取一个数组类型的 JSValue
        JSValue *jsMethodArr = [jsMethods valueForProperty:jsMethodName];
        // 参数个数
        int numberOfArg = [jsMethodArr[0] toInt32];
        // 方法名字
        NSString *selectorName = [jsMethodName toObjectCSelectorName];
        
        if ([selectorName componentsSeparatedByString:@":"].count - 1 < numberOfArg) {
            selectorName = [selectorName stringByAppendingString:@":"];
        }
        
        // 自定义函数
        JSValue *jsMethod = jsMethodArr[1];
        
        if (class_respondsToSelector(cls, NSSelectorFromString(selectorName))) {
            // 替换方法
            [LEFSwallowRuntime overrideMethod:cls selectorName:selectorName function:jsMethod isClassMethod:NO typeDescription:NULL];
        } else {
            // 添加方法
            BOOL overrided = NO;
            if (!overrided) {
                if (![[jsMethodName substringToIndex:1] isEqualToString:@"_"]) {
                    NSMutableString *typeDescStr = [@"@@:" mutableCopy];
                    for (int i = 0; i < numberOfArg; i ++) {
                        [typeDescStr appendString:@"@"];
                    }
                    [LEFSwallowRuntime overrideMethod:cls selectorName:selectorName function:jsMethod isClassMethod:NO typeDescription:[typeDescStr cStringUsingEncoding:NSUTF8StringEncoding]];
                }
            }
        }
    }
    
    return @{@"cls": @"" ?: @"", @"superCls": @"" ?: @""};

}

+ (void)overrideMethod:(Class)cls selectorName:(NSString *)selectorName function:(JSValue *)function isClassMethod:(BOOL)isClassMethod typeDescription:(const char *)typeDescription
{
    SEL selector = NSSelectorFromString(selectorName);
    
    /**
     如果是要替换方法的实现，那么可以通过 method_getTypeEncoding 来获取 type encoding
     */
    if (!typeDescription) {
        Method method = class_getInstanceMethod(cls, selector);
        typeDescription = method_getTypeEncoding(method);
    }
    
    // 如果这个类的消息转发的实现不是 SwallowForwardInvocation
    if (class_getMethodImplementation(cls, @selector(forwardInvocation:)) != (IMP)SwallowForwardInvocation) {
        // 替换 forwardInvocation 为 SwallowForwardInvocation
        IMP orginForwardIMP = class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)SwallowForwardInvocation, "v@:@");
        if (orginForwardIMP) {
            // 给当前类添加原先消息转发的方法
            class_addMethod(cls, NSSelectorFromString(@"ORIGforwardInvocation:"), orginForwardIMP, "v@:@");
        }
    }
    
    // 添加原方法的实现
    if ([cls respondsToSelector:selector]) {
        IMP orginIMP = class_getMethodImplementation(cls, selector);
        SEL orginSelector = NSSelectorFromString([NSString stringWithFormat:@"ORIG%@", selectorName]);
        if (!class_respondsToSelector(cls, orginSelector)) {
            class_addMethod(cls, orginSelector, orginIMP, typeDescription);
        }
    }
    
    // 保存 JS 方法的自定义实现
    NSString *LEFSelectorName = [NSString stringWithFormat:@"_swallow%@", selectorName];
    if (!_JSOverideMethodDict[cls]) {
        _JSOverideMethodDict[(id<NSCopying>)cls] = [NSMutableDictionary dictionary];
    }
    _JSOverideMethodDict[cls][LEFSelectorName] = function;
    
    // 把方法替换为消息转发的方法，这样所有的方法调用都会执行到 SwallowForwardInvocation 这个方法中
    class_replaceMethod(cls, selector, _objc_msgForward, typeDescription);
}

static void SwallowForwardInvocation(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation)
{
    NSMutableArray *argList = [NSMutableArray array];
    
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    
    NSLog(@"SwallowForwardInvocation: %@ - %@", assignSlf, selectorName);

    // 查找是否有被替换的 jsFunc, 如果没有则直接调用原来的消息转发
    NSString *swallowSelectorName = [NSString stringWithFormat:@"_swallow%@", selectorName];
    JSValue *jsFunc = getJSFunctionInObjectHierachy(assignSlf, swallowSelectorName);
    if (!jsFunc) {
        LEFSwallowExcuteForwardInvocation(assignSlf, selector, invocation);
        return;
    }
    
    id slf = assignSlf;

    // 第一个参数是类或实例
    if ([slf class] == slf) {
        [argList addObject:[JSValue valueWithObject:@{@"__clsName": NSStringFromClass([slf class])} inContext:_context]];
    } else if ([selectorName isEqualToString:@"dealloc"]) {
        [argList addObject:[LEFSwallowWrap wrapAssignObj:slf]];
    } else {
        [argList addObject:[LEFSwallowWrap wrapWaakObj:slf]];
    }
    
    for (NSInteger i = 2; i < numberOfArguments; i++) {
        const char *argTypeChar = [methodSignature getArgumentTypeAtIndex:i];
        LEFSwallowMethodArgumentType argumentType = [LEFSwallowRuntime argumentTypeWithEncode:argTypeChar];
        
        // 根据不同类型获取不同参数
        #define LEF_Swallow_ARG_CASE(_typeChar, _type) \
        case _typeChar:  \
        {  \
        _type value;  \
        [invocation getArgument:&value atIndex:i];  \
        [argList addObject:@(value)];  \
        break;  \
        }
        
        switch (argumentType) {
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeChar, char);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedChar, unsigned char);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeShort, short);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedShort, unsigned short);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeInt, int);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedInt, unsigned int);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeLong, long);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedLong, unsigned long);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeLongLong, long long);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedLongLong, unsigned long long);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeFloat, float);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeDouble, double);
            LEF_Swallow_ARG_CASE(LEFSwallowMethodArgumentTypeBool, BOOL);
                
            case LEFSwallowMethodArgumentTypeObject:
            {
                id arg;
                // TODO: NSBlock 特殊处理
                [invocation getArgument:&arg atIndex:i];
                [argList addObject:arg ?: [LEFSwallow shareInstance].nilObj];
              break;
            }
            case LEFSwallowMethodArgumentTypeCGRect:
            {
                CGRect rect;
                [invocation getArgument:&rect atIndex:i];
                [argList addObject:[JSValue valueWithRect:rect inContext:_context]];
                break;
            }
            case LEFSwallowMethodArgumentTypeCGSize:
            {
                CGSize size;
                [invocation getArgument:&size atIndex:i];
                [argList addObject:[JSValue valueWithSize:size inContext:_context]];
                break;
            }
            case LEFSwallowMethodArgumentTypeCGPoint:
            {
                CGPoint point;
                [invocation getArgument:&point atIndex:i];
                [argList addObject:[JSValue valueWithPoint:point inContext:_context]];
                break;
            }
            case LEFSwallowMethodArgumentTypeSEL:
            {
                SEL selector;
                [invocation getArgument:&selector atIndex:i];
                NSString *selectorName = NSStringFromSelector(selector);
                [argList addObject:(selectorName ? selectorName: [LEFSwallow shareInstance].nilObj)];
                break;
            }
            case LEFSwallowMethodArgumentTypeClass:
            {
                Class arg;
                [invocation getArgument:&arg atIndex:i];
                [argList addObject:[LEFSwallowWrap wrapCls:arg]];
                break;
                break;
            }
            case LEFSwallowMethodArgumentTypeCharacterString:
            {
                void *arg;
                [invocation getArgument:&arg atIndex:i];
                [argList addObject:[LEFSwallowWrap wrapPointer:arg]];
                break;
                break;
            }
            default:
                NSLog(@"error type %@", @(argumentType));
                break;
        }
    }
    
    /**
     至此，上面的代码主要获取方法调用时的参数值，而这些方法的调用的调用者是：
     1.Objective-C 这层主动调用，而这层的调用需要调用 JS 层具体的实现
     2. JS 层调用
     */
    NSLog(@"oc arguments: %@", argList);
    
    // 上面获取到的参数都是 OC 类型的，需要转换成 JS 类型
    NSArray *params = [LEFSwallowValueFormat formatOCToJSList:argList];
    NSLog(@"js arguments: %@", params);
    
    // 返回值的处理
    LEFSwallowMethodArgumentType returnType = [LEFSwallowRuntime argumentTypeWithEncode:[methodSignature methodReturnType]];

    switch (returnType) {
        case LEFSwallowMethodArgumentTypeObject:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            // 这里必须使用 __autoreleasing
            id __autoreleasing ret = [LEFSwallowValueFormat formatJSToOC:jsval];
            if (ret == [LEFSwallow shareInstance].nilObj ||
                ([ret isKindOfClass:[NSNumber class]] && strcmp([ret objCType], "c") == 0 && ![ret boolValue])) {
                ret = nil;
            }
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeCharacterString:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            void *ret;
            id obj = [LEFSwallowValueFormat formatJSToOC:jsval];
            if ([obj isKindOfClass:[LEFSwallowWrap class]]) {
                ret = [((LEFSwallowWrap *)obj) unwrapPointer];
            }
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeClass:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            Class ret;
            ret = [LEFSwallowValueFormat formatJSToOC:jsval];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeSEL:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            SEL ret;
            id obj = [LEFSwallowValueFormat formatJSToOC:jsval];
            if ([obj isKindOfClass:[NSString class]]) {
                ret = NSSelectorFromString(obj);
            }
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeChar:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            char ret = [[jsval toObject] charValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeUnsignedChar:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned char ret = [[jsval toObject] unsignedCharValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeShort:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            short ret = [[jsval toObject] shortValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeUnsignedShort:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned short ret = [[jsval toObject] unsignedShortValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeInt:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            int ret = [[jsval toObject] intValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeUnsignedInt:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned int ret = [[jsval toObject] unsignedIntValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeLong:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            long ret = [[jsval toObject] longValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeUnsignedLong:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned long ret = [[jsval toObject] unsignedLongValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeLongLong:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            long long ret = [[jsval toObject] longLongValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeUnsignedLongLong:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned long long ret = [[jsval toObject] unsignedLongLongValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeFloat:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            unsigned char ret = [[jsval toObject] floatValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeDouble:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            double ret = [[jsval toObject] doubleValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeBool:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            BOOL ret = [[jsval toObject] boolValue];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeVoid:
        {
            callJSFunc(jsFunc, params);
            break;
        }
        case LEFSwallowMethodArgumentTypeCGRect:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            CGRect ret = [jsval toRect];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeCGPoint:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            CGPoint ret = [jsval toPoint];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeCGSize:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            CGSize ret = [jsval toSize];
            [invocation setReturnValue:&ret];
            break;
        }
        case LEFSwallowMethodArgumentTypeNSRange:
        {
            JSValue *jsval = callJSFunc(jsFunc, params);
            NSRange ret = [jsval toRange];
            [invocation setReturnValue:&ret];
            break;
        }
        default:
        NSLog(@"Return type error");
            break;
    }
}

static void LEFSwallowExcuteForwardInvocation(id slf, SEL selector, NSInvocation *invocation) {
    SEL orginForwardSelector = NSSelectorFromString(@"ORIGforwardInvocation:");
    if ([slf respondsToSelector:orginForwardSelector]) {
        NSMethodSignature *methodSignature = [slf methodSignatureForSelector:orginForwardSelector];
        if (!methodSignature) {
            NSLog(@"unrecognized selector - ORIGforwardInvocation: for instance: %@", slf);
            return;
        }
        
        NSInvocation *forwardInv = [NSInvocation invocationWithMethodSignature:methodSignature];
        [forwardInv setTarget:slf];
        [forwardInv setSelector:orginForwardSelector];
        [forwardInv setArgument:&invocation atIndex:2];
        [forwardInv invoke];
    } else {
        // 执行父类的消息转发
        Class superCls = [[slf class] superclass];
        Method superForwardMethod = class_getInstanceMethod(superCls, @selector(forwardInvocation:));
        void(*superForwardIMP)(id, SEL, NSInvocation *);
        superForwardIMP = (void(*)(id, SEL, NSInvocation *))method_getImplementation(superForwardMethod);
        superForwardIMP(slf, @selector(forwardInvocation:), invocation);
    }
}

static JSValue * callJSFunc(JSValue *jsFunc, NSArray *params) {
    JSValue *jsval;
    [_JSMethodForwardCallLock lock];
    jsval = [jsFunc callWithArguments:params];
    [_JSMethodForwardCallLock unlock];
    while (![jsval isNull] && ![jsval isUndefined] && [jsval hasProperty:@"__isPerformInOC"]) {
        NSArray *args = ((void *)0);
        JSValue *cb = jsval[@"cb"];
        if ([jsval hasProperty:@"sel"]) {
            id callRet = [LEFSwallowRuntime callSelectorWithClassName:![jsval[@"clsName"] isUndefined] ? [jsval[@"clsName"] toString] : nil selectorName:[jsval[@"sel"] toString] arguments:jsval[@"args"] instance:![jsval[@"obj"] isUndefined] ? jsval[@"obj"] : ((void *)0) isSuper:NO];
            args = @[[_context[@"_formatOCToJS"] callWithArguments:callRet ? @[callRet] : [LEFSwallowValueFormat formatOCToJSList:@[[LEFSwallow shareInstance].nilObj]]]];
        }
        [_JSMethodForwardCallLock lock];
        jsval = [cb callWithArguments:args];
        [_JSMethodForwardCallLock unlock];
    }
    return jsval;
}

+ (id)callSelectorWithClassName:(NSString *)className selectorName:(NSString *)selectorName arguments:(JSValue *)arguments instance:(JSValue *)instance isSuper:(BOOL)isSuper
{
    NSString *realClsName = [[instance valueForProperty:@"__realClsName"] toString];
    
    NSLog(@"callSelector: %@ - %@", className, selectorName);
    
    // 如果实例存在
    if (instance) {
        instance = [LEFSwallowValueFormat formatJSToOC:instance];
        if (class_isMetaClass(object_getClass(instance))) {
            className = NSStringFromClass((Class)instance);
            instance = nil;
        } else if (!instance || instance == [LEFSwallow shareInstance].nilObj || [instance isKindOfClass:[LEFSwallowWrap class]]) {
            return @{ @"__isNil" : @(YES)};
        }
    }
    
    // 是 toJS 实例方法
    if (instance && [selectorName isEqualToString:@"toJS"]) {
        if([instance isKindOfClass:[NSString class]] || [instance isKindOfClass:[NSDictionary class]] || [instance isKindOfClass:[NSArray class]] || [instance isKindOfClass:[NSDate class]]) {
            return [LEFSwallowValueFormat unBoxOCObejctToJS:instance];
        };
    }
    
    // 参数
    id argumentsObj = [LEFSwallowValueFormat formatJSToOC:arguments];
    // 类
    Class cls = instance ? [instance class] : NSClassFromString(className);
    // 方法
    SEL selector = NSSelectorFromString(selectorName);
    
    NSString *superClassName = nil;
    // 如果是 [super excuteFunc]
    if (isSuper) {
        NSString *superSelectorName = [NSString stringWithFormat:@"SUPER_%@", superClassName];
        SEL superSelector = NSSelectorFromString(superSelectorName);
        
        Class superCls;
        if (realClsName.length) {
            Class defineClass = NSClassFromString(realClsName);
            superCls = defineClass ? [defineClass superclass] : [cls superclass];
        } else {
            superCls = [cls superclass];
        }
        
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP superIMP = method_getImplementation(superMethod);
        
        class_addMethod(cls, superSelector, superIMP, method_getTypeEncoding(superMethod));
        
        NSString *swallowSelectorName = [NSString stringWithFormat:@"_swallow%@", selectorName];
        JSValue *overideFunction = _JSOverideMethodDict[superCls][swallowSelectorName];
        if (overideFunction) {
            [self overrideMethod:cls selectorName:superSelectorName function:overideFunction isClassMethod:NO typeDescription:NULL];
        }
        
        selector = superSelector;
        superClassName = NSStringFromClass(superCls);
    }
    
    NSInvocation *invocation;
    NSMethodSignature *methodSignature;
    
    if (!_JSMethodSignatureCache) {
        _JSMethodSignatureCache = [[NSMutableDictionary alloc] init];
    }
    
    if (instance) {
        [_JSMethodSignatureLock lock];
        if (!_JSMethodSignatureCache[cls]) {
            _JSMethodSignatureCache[(id<NSCopying>)cls] = [[NSMutableDictionary alloc] init];
        }
        
        methodSignature = _JSMethodSignatureCache[cls][selectorName];
        if (!methodSignature) {
            methodSignature = [cls instanceMethodSignatureForSelector:selector];
            _JSMethodSignatureCache[cls][selectorName] = methodSignature;
        }
        [_JSMethodSignatureLock unlock];
        
        if (!methodSignature) {
            NSLog(@"methodSignature is nil");
            return nil;
        }
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:instance];
    } else {
        methodSignature = [cls methodSignatureForSelector:selector];
        if (!methodSignature) {
            NSLog(@"methodSignature is nil");
            return nil;
        }
        
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:cls];
    }
    
    [invocation setSelector:selector];
    
    NSUInteger numberOfArguments = methodSignature.numberOfArguments;
    NSInteger inputArguments = [(NSArray *)argumentsObj count];
    if (inputArguments > numberOfArguments - 2) {
        // 这个是给可变参数使用的，比如 [NSString stringWithFormat:(nonnull NSString *), ...];
        return nil;
    }
    
    /**
     设置参数
     */
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        const char *argTypeChar = [methodSignature getArgumentTypeAtIndex:i];
        LEFSwallowMethodArgumentType argumentType = [LEFSwallowRuntime argumentTypeWithEncode:argTypeChar];
        id valObj = argumentsObj[i-2];
        JSValue *val = arguments[i-2];
        
#define SWALLOW_CALL_ARG_CASE(_typeString, _type, _selector) \
case _typeString: {\
_type value = [valObj _selector]; \
[invocation setArgument:&value atIndex:i];\
break;\
}
        switch (argumentType) {
            // 参数为基本的数据类型
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeChar, char, charValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedChar, unsigned char, unsignedCharValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeShort, short, shortValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedShort, unsigned short, unsignedShortValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeInt, int, intValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedInt, unsigned int, unsignedIntValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeLong, long, longValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedLong, unsigned long, unsignedLongValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeLongLong, long long, longLongValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeUnsignedLongLong, unsigned long long, unsignedLongLongValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeFloat, float, floatValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeDouble, double, doubleValue);
            SWALLOW_CALL_ARG_CASE(LEFSwallowMethodArgumentTypeBool, BOOL, boolValue);
            
            // 参数为结构体
            case LEFSwallowMethodArgumentTypeCGRect:
            {
                CGRect value = [val toRect];
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case LEFSwallowMethodArgumentTypeCGPoint:
            {
                CGPoint value = [val toPoint];
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case LEFSwallowMethodArgumentTypeCGSize:
            {
                CGSize value = [val toSize];
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case LEFSwallowMethodArgumentTypeNSRange:
            {
                NSRange value = [val toRange];
                [invocation setArgument:&value atIndex:i];
                break;
            }
            
            // 参数为 SEL
            case LEFSwallowMethodArgumentTypeSEL:
            {
                SEL value = nil;
                if (valObj != [LEFSwallow shareInstance].nilObj) {
                    value = NSSelectorFromString(valObj);
                }
                [invocation setArgument:&value atIndex:i];
                break;
            }
            case LEFSwallowMethodArgumentTypeCharacterString:
            {
                // TODO: 指针类型
                break;
            }
            case LEFSwallowMethodArgumentTypeClass:
            {
                if ([valObj isKindOfClass:[LEFSwallowWrap class]]) {
                    Class value = [(LEFSwallowWrap *)valObj unwrapClass];
                    [invocation setArgument:&value atIndex:i];
                }
                break;
            }
            default:
            {
                if (valObj == [LEFSwallow shareInstance].nullObj) {
                    valObj = [NSNull null];
                    [invocation setArgument:&valObj atIndex:i];
                    break;
                }
                if (valObj == [LEFSwallow shareInstance].nilObj || ([valObj isKindOfClass:[NSNumber class]] && strcmp([valObj objCType], "c") == 0 && ![valObj boolValue])) {
                    valObj = nil;
                    [invocation setArgument:&valObj atIndex:inputArguments];
                    break;
                }
                if ([(JSValue *)arguments[i-2] hasProperty:@"__isBlock"]) {
                    
                } else {
                    [invocation setArgument:&valObj atIndex:i];
                }
            }
        }
    }
    
    // TODO: invkeSuperClsName
    if (superClassName) {
        _currInvokeSuperClsName[selectorName] = superClassName;
    }
    
    [invocation invoke];
    
    if (superClassName) {
        [_currInvokeSuperClsName removeObjectForKey:selectorName];
    }
    
    // 返回值处理
    char returnType[255];
    strcpy(returnType, [methodSignature methodReturnType]);
    
    id returnValue;
    if (strncmp(returnType, "v", 1) != 0) {
        if (strncmp(returnType, "@", 1) == 0) {
            void *result;
            [invocation getReturnValue:&result];
            
            if ([selectorName isEqualToString:@"alloc"] || [selectorName isEqualToString:@"new"] || [selectorName isEqualToString:@"copy"] || [selectorName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            } else {
                returnValue = (__bridge id)result;
            }
            return [LEFSwallowValueFormat formatOCToJS:returnValue];
        } else {
            LEFSwallowMethodArgumentType argType = [self argumentTypeWithEncode:returnType];
            switch (argType) {
                
                
#define SWALLOW_CALL_RET_CASE(_typeString, _type) \
case _typeString: {\
_type tempResultSet;\
[invocation getReturnValue:&tempResultSet];\
returnValue = @(tempResultSet);\
break;\
}
                
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeChar, char);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeUnsignedChar, unsigned char);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeShort, short);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeUnsignedShort, unsigned short);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeInt, int);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeUnsignedInt, unsigned int);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeLong, long);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeUnsignedLong, unsigned long);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeLongLong, long long);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeUnsignedLongLong, unsigned long long);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeFloat, float);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeDouble, double);
                SWALLOW_CALL_RET_CASE(LEFSwallowMethodArgumentTypeBool, BOOL);
      
                
                case LEFSwallowMethodArgumentTypeCGRect:
                {
                    CGRect result;
                    [invocation getReturnValue:&result];
                    return [JSValue valueWithRect:result inContext:_context];
                    break;
                }
                case LEFSwallowMethodArgumentTypeCGPoint:
                {
                    CGPoint result;
                    [invocation getReturnValue:&result];
                    return [JSValue valueWithPoint:result inContext:_context];
                    break;
                }
                case LEFSwallowMethodArgumentTypeCGSize:
                {
                    CGSize result;
                    [invocation getReturnValue:&result];
                    return [JSValue valueWithSize:result inContext:_context];
                    break;
                }
                case LEFSwallowMethodArgumentTypeNSRange:
                {
                    NSRange result;
                    [invocation getReturnValue:&result];
                    return [JSValue valueWithRange:result inContext:_context];
                    break;
                }
                case LEFSwallowMethodArgumentTypeCharacterString:
                {
                    void *result;
                    [invocation getReturnValue:&result];
                    returnValue = [LEFSwallowValueFormat formatOCToJS:[LEFSwallowWrap wrapPointer:result]];
                    break;
                }
                case LEFSwallowMethodArgumentTypeClass:
                {
                    Class result;
                    [invocation getReturnValue:&result];
                    returnValue = [LEFSwallowValueFormat formatOCToJS:[LEFSwallowWrap wrapCls:result]];
                }
                
                default:
                {
                    break;
                }
            }
            return returnValue;
        }
    }
    
    return nil;
}

// 这个方法主要用来获取 JS 函数的实现，因为每个被替换或者新增的函数都添加了对应的 JS 实现
static JSValue *getJSFunctionInObjectHierachy(id slf, NSString *selectorName)
{
    Class cls = object_getClass(slf);
    if (_currInvokeSuperClsName[selectorName]) {
        // TODO: 不知道这是干什么用的
        cls = NSClassFromString(_currInvokeSuperClsName[selectorName]);
        selectorName = [selectorName stringByReplacingOccurrencesOfString:@"_JPSUPER_" withString:@"_JP"];
    }
    
    JSValue *func = _JSOverideMethodDict[cls][selectorName];
    while (!func) {
        // 如果当前类没有，从父类中查找
        cls = class_getSuperclass(cls);
        if (!cls) {
            return nil;
        }
        func = _JSOverideMethodDict[cls][selectorName];
    }
    return func;
}

+ (LEFSwallowMethodArgumentType)argumentTypeWithEncode:(const char *)encode
{
    if (strcmp(encode, @encode(char)) == 0) {
        return LEFSwallowMethodArgumentTypeChar;
    } else if (strcmp(encode, @encode(int)) == 0) {
        return LEFSwallowMethodArgumentTypeInt;
    } else if (strcmp(encode, @encode(short)) == 0) {
        return LEFSwallowMethodArgumentTypeShort;
    } else if (strcmp(encode, @encode(long)) == 0) {
        return LEFSwallowMethodArgumentTypeLong;
    } else if (strcmp(encode, @encode(long long)) == 0) {
        return LEFSwallowMethodArgumentTypeLongLong;
    } else if (strcmp(encode, @encode(unsigned char)) == 0) {
        return LEFSwallowMethodArgumentTypeUnsignedChar;
    } else if (strcmp(encode, @encode(unsigned int)) == 0) {
        return LEFSwallowMethodArgumentTypeUnsignedInt;
    } else if (strcmp(encode, @encode(unsigned short)) == 0) {
        return LEFSwallowMethodArgumentTypeUnsignedShort;
    } else if (strcmp(encode, @encode(unsigned long)) == 0) {
        return LEFSwallowMethodArgumentTypeUnsignedLong;
    } else if (strcmp(encode, @encode(unsigned long long)) == 0) {
        return LEFSwallowMethodArgumentTypeUnsignedLongLong;
    } else if (strcmp(encode, @encode(float)) == 0) {
        return LEFSwallowMethodArgumentTypeFloat;
    } else if (strcmp(encode, @encode(double)) == 0) {
        return LEFSwallowMethodArgumentTypeDouble;
    } else if (strcmp(encode, @encode(BOOL)) == 0) {
        return LEFSwallowMethodArgumentTypeBool;
    } else if (strcmp(encode, @encode(void)) == 0) {
        return LEFSwallowMethodArgumentTypeVoid;
    } else if (strcmp(encode, @encode(char *)) == 0) {
        return LEFSwallowMethodArgumentTypeCharacterString;
    } else if (strcmp(encode, @encode(id)) == 0) {
        return LEFSwallowMethodArgumentTypeObject;
    } else if (strcmp(encode, @encode(Class)) == 0) {
        return LEFSwallowMethodArgumentTypeClass;
    } else if (strcmp(encode, @encode(CGPoint)) == 0) {
        return LEFSwallowMethodArgumentTypeCGPoint;
    } else if (strcmp(encode, @encode(CGSize)) == 0) {
        return LEFSwallowMethodArgumentTypeCGSize;
    } else if (strcmp(encode, @encode(CGRect)) == 0) {
        return LEFSwallowMethodArgumentTypeCGRect;
    } else if (strcmp(encode, @encode(UIEdgeInsets)) == 0) {
        return LEFSwallowMethodArgumentTypeUIEdgeInsets;
    } else if (strcmp(encode, @encode(SEL)) == 0) {
        return LEFSwallowMethodArgumentTypeSEL;
    }  else if (strcmp(encode, @encode(IMP))) {
        return LEFSwallowMethodArgumentTypeIMP;
    } else {
        return LEFSwallowMethodArgumentTypeUnknown;
    }
}

@end
