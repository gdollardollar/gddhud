//
//  GddHud+DefaultContent.m
//  GddUtils
//
//  Created by Gui on 9/23/14.
//  Copyright (c) 2014 gdd. All rights reserved.
//

#import "GddHud.h"

@implementation GddHud (DefaultContent)

- (CGFloat)labelButtonVMargin
{
    return 5;
}

- (NSString *)defaultText {
    return nil;
}

-(void) setText:(NSString *)text buttons:(NSArray *)buttonTitles defaultButtonIndex:(int)defaultIndex
         action:(GddHudActionBlock)block{
    
    if (text == nil) {
        text = [self defaultText];
    }
    
    _actionBlock = block;

    CGRect frame = CGRectMake(0, 0, 100, 0);
    UIView* view = [[UIView alloc] initWithFrame:frame];

    UIView* label = [self label:text];

    frame.size = label.frame.size;

    NSMutableArray *buttons = [NSMutableArray new];
    for (int index = 0; index < buttonTitles.count; ++index) {
        NSString *t = buttonTitles[index];
        [buttons addObject:index==defaultIndex ? [self defaultButton: t]:[self button: t]];
    }

    CGFloat maxHeight = 0, totalWidth = 0;
    for (UIButton* button in buttons){
        maxHeight = MAX(maxHeight, button.frame.size.height);
        totalWidth += button.frame.size.width;
    }

    CGFloat horizontalMargin = MAX(1, (frame.size.width-totalWidth)/(buttons.count+1));
    CGFloat x = horizontalMargin;
    CGFloat offsetY = frame.size.height+self.labelButtonVMargin;

    CGRect tempButtonFrame;
    for (UIButton* button in buttons){
        tempButtonFrame = button.frame;
        tempButtonFrame.origin.x = x;
        tempButtonFrame.origin.y = offsetY + (int)((maxHeight - tempButtonFrame.size.height)*.5f);
        button.frame = tempButtonFrame;

        [button addTarget:self action:@selector(hudButtonAction:) forControlEvents:UIControlEventTouchUpInside];

        [view addSubview:button];
        x += tempButtonFrame.size.width + horizontalMargin;
    }

    frame.size.height = offsetY + maxHeight;
    view.autoresizesSubviews = false;
    view.frame = frame;
    [view addSubview:label];

    [self setContent:view animated:self.willAnimateContentChange contentType:GddHudContentTypeDefault];
}

- (NSString *)defaultButtonTitle {
    return @"Ok";
}

-(void) setText:(NSString *)text {
    [self setText:text button:[self defaultButtonTitle] action:^BOOL(GddHud *hud, NSInteger index) {
        return YES;
    }];
}

-(void) setText:(NSString *)text button:(NSString *)buttonTitle action:(GddHudActionBlock)block{
    [self setText:text buttons:@[buttonTitle] defaultButtonIndex:0 action:block];
}

-(void) hudButtonAction:(UIButton*)sender{
    if(_actionBlock){
        if(_actionBlock(self,[sender.superview.subviews indexOfObject:sender])){
            [self dismiss];
        }
    } else {
        [self dismiss];
    }
}

#pragma mark - Theming

- (UIView *)label:(NSString *)text
{
    CGRect frame = CGRectMake(0, 0, 250, 0);
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = self.font;
    label.numberOfLines=0;
    label.textAlignment = NSTextAlignmentCenter;
    
    if (self.textColor == nil) {
        CGFloat r,g,b,a;
        [self.backgroundColor getRed:&r green:&g blue:&b alpha:&a];
        label.textColor = [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
    } else {
        label.textColor = self.textColor;
    }
    
    label.text = text;

    [label sizeToFit];
    frame.size.height = label.frame.size.height;
    label.frame = frame;
    return label;
}

-(UIButton*) button:(NSString *)text{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:text forState:UIControlStateNormal];
    [button setTintColor:self.tintColor];
    [button sizeToFit];
    button.titleLabel.font = self.font;
    return button;
}

- (UIButton *)defaultButton:(NSString *)text
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:text forState:UIControlStateNormal];
    [button setTintColor:self.tintColor];
    [button sizeToFit];
    button.titleLabel.font = self.font;
    return button;
}

@end
