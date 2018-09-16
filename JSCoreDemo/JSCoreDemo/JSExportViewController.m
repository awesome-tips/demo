//
//  JSExportViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/16.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "JSExportViewController.h"
#import "TeachSet.h"
#import "Member.h"
#import "Manager.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "UILabelExportProtocol.h"

@interface JSExportViewController ()

@end

@implementation JSExportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self exportPrototypeDemo];
    [self exportExistClassDemo];
    [self exportJSValueDemo];
}

- (void)excuteJS
{
    NSString *js = @"console.log(10)";
    [self.context evaluateScript:js withSourceURL:[NSURL URLWithString:@"lefe.js"]];
}

- (void)exportJSValueDemo
{
    JSValue *intValue = [JSValue valueWithInt32:10 inContext:self.context];
    JSValue *boolValue = [JSValue valueWithBool:YES inContext:self.context];
    
    
    JSValue *memberValue = [JSValue valueWithObject:[Member new] inContext:self.context];
    NSLog(@"memberValue: %@", [memberValue toObject]);
    
    JSValue *person = [JSValue valueWithNewObjectInContext:self.context];
    [person setObject:@"Lefe_x" forKeyedSubscript:@"name"];
    [person setObject:@25 forKeyedSubscript:@"age"];
    
    NSLog(@"name: %@", person[@"name"]);
    NSLog(@"name: %@", [person objectForKeyedSubscript:@"name"]);
    
    NSLog(@"==== %@", [person toObject]);
    
    self.context[@"_OC_person"] = ^(JSValue *p) {
        NSLog(@"p ==== %@", [p toObject]);

    };
    
    NSString *jsTypeStr = @"var person = {name:'Lefe_x', age:25, des: function(){return 'Hello'}};_OC_person(person)";
    [self.context evaluateScript:jsTypeStr];
    
    JSValue *rectValue = [JSValue valueWithRect:CGRectMake(0, 0, 100, 100) inContext:self.context];
    [rectValue toRect];
    
    [self.context evaluateScript:@"function add(a, b) {return a + b;}"];
    // 调用 JS 函数
    JSValue *addValue = [self.context[@"add"] callWithArguments:@[@2, @3] ];
}

// 导出已有的类的方法
- (void)exportExistClassDemo
{
    class_addProtocol([UILabel class], @protocol(UILabelExportProtocol));
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 100, 200, 44)];
    label.text = @"知识小集";
    label.textColor = [UIColor blackColor];
    [self.view addSubview:label];
    
    self.context[@"_OC_label"] = label;
    
    [self.context evaluateScript:@"_OC_label.text='关注知识小集公众号'"];
    [self.context evaluateScript:@"console.log(_OC_label.text)"];
}

// 查看导出原型
- (void)exportPrototypeDemo
{
    // 导出 TeachSet 对象
    TeachSet *teachSet = [TeachSet teachSet];
    self.context[@"_OC_teachSet"] = teachSet;
    
    // 导出 TeachSet 类
    self.context[@"_OC_TeachSet"] = [TeachSet class];
    
    // 导出 Member 类，并创建一个 Member 对象添加到 TeachSet 对象中
    // 通过构造函数的方式创建 Member 对象
    // addMember 被重命名为 add
    self.context[@"_OC_Member"] = [Member class];
    [self.context evaluateScript:@"var member = new _OC_Member('Lefe_x', 25);_OC_teachSet.add(member);"];
    
    // 通过类方法创建 Member 对象添加到 TeachSet 对象中
    [self.context evaluateScript:@"var member = _OC_Member.member();member.name='Lefe_x_1';member.age=26;_OC_teachSet.add(member);"];
    
    // 没导出会报错，_OC_teachSet.maxMemberCount is not a function
//    [self.context evaluateScript:@"_OC_teachSet.maxMemberCount()"];
    
    // 获取最终 TeachSet 中的成员数
    JSValue *membersValue = [self.context evaluateScript:@"_OC_teachSet.currentMembers()"];
    
    /**
     membersValue: (
       "name: Lefe_x, age: 25",
       "name: Lefe_x_1, age: 26"
     )*/
    NSLog(@"membersValue: %@", [membersValue toArray]);
}

- (void)exportTotalDemo
{
    TeachSet *teachSet = [TeachSet teachSet];
    self.context[@"_OC_teachSet"] = teachSet;
    
    self.context[@"_OC_member"] = [[Member alloc] init];
    
    JSValue *nameValue = [self.context evaluateScript:@"_OC_teachSet.name" withSourceURL:[NSURL URLWithString:@"export.js"]];
    NSLog(@"nameValue: %@", [nameValue toString]);
    
    [self.context evaluateScript:@"_OC_member.name=\"Lefe_x_new\"" withSourceURL:[NSURL URLWithString:@"export.js"]];
    
    JSValue *addValue = [self.context evaluateScript:@"_OC_member.name=\"Lefe_x_new\";_OC_teachSet.addMember(_OC_member)" withSourceURL:[NSURL URLWithString:@"export.js"]];
    NSLog(@"addValue: %@", @([addValue toBool]));
    
    JSValue *membersValue = [self.context evaluateScript:@"console.log(_OC_member.name);_OC_teachSet.currentMembers()" withSourceURL:[NSURL URLWithString:@"export.js"]];
    NSLog(@"membersValue: %@", [membersValue toArray]);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self excuteJS];
}

@end
