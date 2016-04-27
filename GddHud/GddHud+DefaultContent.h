//
//  GddHud+DefaultContent.h
//  GddUtils
//
//  Created by Gui on 9/23/14.
//  Copyright (c) 2014 gdd. All rights reserved.
//

#import <GddHud/GddHud.h>

@interface GddHud (DefaultContent)

//  ============================================
//  Text and buttons
//  ============================================

- (NSString *)defaultText;

- (NSString *)defaultButtonTitle;

- (CGFloat)labelButtonVMargin;

- (UIView *)label:(NSString *)text;

- (UIButton *)button:(NSString *)text;

- (UIButton *)defaultButton:(NSString *)text;

/**
 * @note Animates if the superview of the hud is not nil
 */
- (void)setText:(NSString *)text buttons:(NSArray *)buttonTitles defaultButtonIndex:(int)index
         action:(GddHudActionBlock)block;

/**
 * @note Animates if the superview of the hud is not nil
 */
- (void)setText:(NSString *)text button:(NSString *)buttonTitle action:(GddHudActionBlock)block;

/**
 * Uses setText:button:action: with @"Ok" as a button title and dismiss as the action
 * @note Animates if the superview of the hud is not nil
 */
- (void)setText:(NSString *)text;

@end
