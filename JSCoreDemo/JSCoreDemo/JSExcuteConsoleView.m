//
//  JSExcuteConsoleView.m
//  JSCoreDemo
//
//  Created by Wang,Suyan on 2018/6/3.
//  Copyright © 2018年 Wang,Suyan. All rights reserved.
//

#import "JSExcuteConsoleView.h"

@implementation JSExcuteConsoleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createView];
    }
    return self;
}

- (void)createView
{
    _errorTextView = ({
        UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 100)];
        view.textColor = [UIColor redColor];
        view.backgroundColor = [UIColor blackColor];
        view.font = [UIFont systemFontOfSize:15];
        view.editable = NO;
        [self addSubview:view];
        view;
    });
    
    _showLabel = ({
        UILabel *view = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.errorTextView.bounds), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-CGRectGetHeight(self.errorTextView.bounds))];
        view.backgroundColor = [UIColor blackColor];
        view.numberOfLines = 0;
        view.textColor = [UIColor whiteColor];
        view.font = [UIFont systemFontOfSize:15];
        [self addSubview:view];
        view;
    });
}

- (void)setLog:(NSString *)log
{
    _log = log;
    _showLabel.text = log;
}

- (void)setErrorlog:(NSString *)errorlog
{
    _errorlog = errorlog;
    _errorTextView.text = errorlog;
}

- (void)addLog:(NSString *)log
{
    NSMutableString *lastLog = [[NSMutableString alloc] initWithString:_showLabel.text ?: @""];
    if (log) {
        [lastLog appendString:[NSString stringWithFormat:@"\n%@", log]];
    }
    _showLabel.text = lastLog;
}

@end
