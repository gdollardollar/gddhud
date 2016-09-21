//
//  GddHud.h
//  MAUtils
//
//  Created by Gui on 7/30/14.
//  Copyright (c) 2014 Manina Bella. All rights reserved.
//

@import UIKit;

FOUNDATION_EXPORT double GddHudVersionNumber;

//! Project version string for GddHud.
FOUNDATION_EXPORT const unsigned char GddHudVersionString[];

@class GddHud;

typedef BOOL(^GddHudActionBlock)(GddHud *hud, NSInteger index);//returns true if should hide

typedef NS_ENUM(NSUInteger, GddHudContentType) {
    GddHudContentTypeNone,
    GddHudContentTypeDefault,
    GddHudContentTypeLoading,
    GddHudContentTypeCustom,
};

@interface GddHud : UIView <UIAppearance>
    {
        @protected
        __weak UIView* _contentContainerView;
        __strong GddHudActionBlock _actionBlock;
    }
    
    /**
     *  Returns the currently displayed Hud. nil if there is none
     */
+ (instancetype)displayedHud;
    
    /**
     *  User set identifier
     */
    @property (nonatomic,assign) int identifier;
    
    /**
     *  User set info
     */
    @property (nonatomic,strong) id userInfo;
    
    /**
     *  Does not work if set after hud is displayed.
     *  Defaults to view with <code>coverColor</code>
     */
    @property (nonatomic, strong) UIView *coverView;
    
    /**
     *  The action that is called when the cover is tapped.
     */
    @property (nonatomic, strong) GddHudActionBlock coverTapActionBlock;
    
- (void)setDismissesOnCoverTap;
    
    //  ============================================
    //  Setting content
    //  ============================================
    
    @property (nonatomic, assign, readonly) BOOL willAnimateContentChange;
    
    @property (nonatomic, weak, readonly) UIView *contentView;
    
    @property (nonatomic, assign, readonly) GddHudContentType contentType;
    
- (void)setContent:(UIView *)content;
    
    /**
     *  Base method for setting content.
     *  All other content method use this one.
     */
- (void)setContent:(UIView *)content animated:(BOOL)animated;
    
- (void)setContent:(UIView *)content animated:(BOOL)animated contentType:(GddHudContentType)contentType;
    
    @property (nonatomic, assign, readonly, getter=isLoading) BOOL loading;
    
- (void)setLoading;
    
    //  ============================================
    //  Show / Dismiss
    //  ============================================
    
    @property (nonatomic, assign, readonly) BOOL isDisplayed;
    
- (void)showIfNeeded;
    
- (void)show;
    
- (void)dismiss;
    
    //  ============================================
    //  UIAppearance Theming
    //  ============================================
    
    @property (nonatomic, assign) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
    
    @property (nonatomic, copy) UIColor *coverColor UI_APPEARANCE_SELECTOR;
    
    @property (nonatomic, assign) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;
    
    @property (nonatomic, copy) UIColor *activityIndicatorColor UI_APPEARANCE_SELECTOR;
    
    @property (nonatomic, copy) UIColor *textColor UI_APPEARANCE_SELECTOR;
    
    @property (nonatomic, copy) UIFont *font UI_APPEARANCE_SELECTOR;
    
    //  ============================================
    //  Override this for custom theming
    //  ============================================
    
- (void)animateShowWithCompletion:(void(^)(BOOL finished))completion;
    
- (void)animateDismissWithCompletion:(void(^)(BOOL finished))completion;
    
    //  ============================================
    //  Show
    //  ============================================
    
+ (instancetype)loader;
    
+ (instancetype)showText:(NSString *)text;
    
@end

@interface GddHud(DefaultContent)
    
    //  ============================================
    //  Default Content
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
