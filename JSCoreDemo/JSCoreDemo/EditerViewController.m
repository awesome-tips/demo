//
//  EditerViewController.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/6.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "EditerViewController.h"

@interface EditerViewController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation EditerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *dict = @{
                           @"name": @"Lefe_x",
                           @"age": @(12),
                           @"sex": @"man回复虎岛和夫客户端开发和快递发货看得见繁华看就会疯狂的很快恢复的空间回复肯定会分开很快就会疯狂的",
                           @"aduios": @[@"player", @"ji"],
                           @"section": @[@"player", @{@"author": @"wsy"}],
                           @"name1": @"Lefe_x",
                           @"age1": @(12),
                           @"sex1": @"man回复虎岛和夫客户端开发和快递发货看得见繁华看就会疯狂的很快恢复的空间回复肯定会分开很快就会疯狂的",
                           @"aduios1": @[@"player", @"ji"],
                           @"section1": @[@"player", @{@"author": @"wsy"}],
                           @"name2": @"Lefe_x",
                           @"age2": @(12),
                           @"sex2": @"man回复虎岛和夫客户端开发和快递发货看得见繁华看就会疯狂的很快恢复的空间回复肯定会分开很快就会疯狂的",
                           @"aduios2": @[@"player", @"ji"],
                           @"section2": @[@"player", @{@"author": @"wsy"}],
                           @"name3": @"Lefe_x",
                           @"age3": @(12),
                           @"sex3": @"man回复虎岛和夫客户端开发和快递发货看得见繁华看就会疯狂的很快恢复的空间回复肯定会分开很快就会疯狂的",
                           @"aduios3": @[@"player", @"ji"],
                           @"section3": @[@"player", @{@"author": @"wsy"}]
                           };
    NSString *json = [self convertToJSONString:dict];
    
    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.text = json;
    [self.view addSubview:_textView];
}

- (NSString *)convertToJSONString:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = nil;
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"convertToJsonData-error: %@", error?:@"object is nil");
    }
    return jsonString;
}

@end
