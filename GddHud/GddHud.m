//
//  GddHud.m
//  MAUtils
//
//  Created by Gui on 7/30/14.
//  Copyright (c) 2014 Manina Bella. All rights reserved.
//

#import "GddHud.h"

#define kHudTransitionDuration .5

#import <QuartzCore/QuartzCore.h>

//================================================================================================
//  _HudViewController Interface
//================================================================================================

@interface _HudViewController : UIViewController
{
@private
    /**
     * This view simply contains the hud so that it can receive transforms for when the keyboard is displayed without modifying
     */
    __weak UIView* _hudKeyboardContainer;
}

@property (nonatomic, strong, readonly) GddHud *hud;

-(id) initWithHud:(GddHud *)hud;

@end

//================================================================================================
//  Hud Manager Interface
//================================================================================================

@interface _HudManager : NSObject
{
@protected
    __strong NSMutableArray* _hudsToBeDisplayed;

    __strong NSTimer* _hudsToBeDisplayedTimer;

    __weak UIWindow* _keyWindow;

    __strong UIWindow* _hudWindow;
}

-(UIViewController*) keyWindowRootViewController;

+(id) instance;

-(NSArray*) hudsToBeDisplayed;

-(void) showHud:(GddHud*)hud;
-(void) dismissCurrentHud;

-(GddHud*) currentHud;

@end

//================================================================================================
//  Hud Implementation
//================================================================================================

@implementation GddHud

@dynamic isDisplayed, willAnimateContentChange;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super initWithFrame:CGRectZero];
    if(self) {

        _contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);

        UIView* contentContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:contentContainerView];
        _contentContainerView = contentContainerView;

        _contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentContainerView.autoresizesSubviews = NO;

        _coverView = [UIView new];
    }
    return self;
}

#pragma mark - Getters

+ (instancetype)displayedHud
{
    return [[_HudManager instance] currentHud];
}

#pragma mark - Appearance

- (void)setCoverColor:(UIColor *)coverColor
{
    _coverColor = coverColor;
    self.coverView.backgroundColor = coverColor;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;

    for (NSLayoutConstraint *c in self.constraints) {
        if (c.secondItem == _contentContainerView) {
            switch (c.secondAttribute) {
                case NSLayoutAttributeLeading:
                    c.constant = _contentInsets.left;
                    break;
                case NSLayoutAttributeTrailing:
                    c.constant = _contentInsets.right;
                    break;
                case NSLayoutAttributeTop:
                    c.constant = _contentInsets.top;
                    break;
                case NSLayoutAttributeBottom:
                    c.constant = _contentInsets.bottom;
                    break;
                default:
                    break;
            }
        }
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;

    self.layer.cornerRadius = cornerRadius;
    if (cornerRadius > 0) {
        self.clipsToBounds = YES;
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    if (self.contentType == GddHudContentTypeDefault) {
        for (UIView *view in self.contentView.subviews) {
            view.tintColor = tintColor;
        }
    }
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    
    if (self.contentType == GddHudContentTypeDefault) {
        for (UIView *view in self.contentView.subviews) {
            if ([view respondsToSelector:@selector(setTextColor:)]) {
                [view performSelector:@selector(setTextColor:) withObject:textColor];
            }
        }
    }
}

- (void)setFont:(UIFont *)font {
    _font = font;
    
    if (self.contentType == GddHudContentTypeDefault) {
        for (UIView *view in self.contentView.subviews) {
            if ([view isKindOfClass:[UIButton class]]) {
                ((UIButton *)view).titleLabel.font = font;
            } else if ([view respondsToSelector:@selector(setFont:)]) {
                [view performSelector:@selector(setFont:) withObject:font];
            }
        }
    }
}

#pragma mark - Constraints

- (void)_addConstraints
{
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-left-[container(width)]-right-|"
                                                                 options:0
                                                                 metrics:@{@"left":@(_contentInsets.left),
                                                                           @"right":@(_contentInsets.right),
                                                                           @"width":@(CGRectGetWidth(self.contentView.bounds))}
                                                                   views:@{@"container":_contentContainerView}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[container(height)]-bottom-|"
                                                                 options:0
                                                                 metrics:@{@"top":@(_contentInsets.top),
                                                                           @"bottom":@(_contentInsets.bottom),
                                                                           @"height":@(CGRectGetHeight(self.contentView.bounds))}
                                                                   views:@{@"container":_contentContainerView}]];
}


#pragma mark Handling content

- (void)resizeForContent:(UIView *)content
{
    for (NSLayoutConstraint *constraint in self.constraints) {
        switch (constraint.firstAttribute) {
            case NSLayoutAttributeWidth:
                NSAssert(constraint.firstItem == _contentContainerView, @"ARG");
                constraint.constant = CGRectGetWidth(content.bounds);
                break;
            case NSLayoutAttributeHeight:
                NSAssert(constraint.firstItem == _contentContainerView, @"ARG");
                constraint.constant = CGRectGetHeight(content.bounds);
                break;
            default:
                break;
        }
    }
}

- (void)animateTransitionToContent:(UIView *)content
{
    [UIView animateWithDuration:kHudTransitionDuration*.25f delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         _contentContainerView.alpha=0;
                     } completion:^(BOOL finished) {
                         if(content != _contentView){//animation was replaced
                             return;
                         }
                         
                         for (UIView *view in _contentContainerView.subviews) {
                             [view removeFromSuperview];
                         }

                         [self resizeForContent:content];
                         [UIView animateWithDuration:kHudTransitionDuration*.5f
                                               delay:0
                                             options:UIViewAnimationOptionBeginFromCurrentState
                                          animations:^{
                                              [self setNeedsLayout];
                                              [self layoutIfNeeded];
                                          } completion:^(BOOL finished) {
                                              if(content != _contentView){//animation was replaced
                                                  return;
                                              }
                                              [_contentContainerView addSubview:content];
                                              [UIView animateWithDuration:kHudTransitionDuration*.25f delay:0
                                                                  options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowAnimatedContent
                                                               animations:^{
                                                                   _contentContainerView.alpha=1;
                                                               } completion:^(BOOL finished) {
                                                                   if(!finished){//animation was replaced
                                                                       NSLog(@"Hud Third Animation did not finish");
                                                                       return;
                                                                   }
                                                               }];
                                          }];
                     }];
}

- (BOOL)willAnimateContentChange {
    return self.superview != nil;
}

- (void)setContent:(UIView *)content
{
    [self setContent:content animated:self.willAnimateContentChange];
}

- (void)setContent:(UIView *)content animated:(BOOL)animated
{
    [self setContent:content animated:animated contentType:GddHudContentTypeCustom];
}

- (void)setContent:(UIView *)content animated:(BOOL)animated contentType:(GddHudContentType)contentType {
    _contentView = content;
    _contentType = contentType;
    if(animated){
        [self animateTransitionToContent:content];
    }else{
        
        for (UIView *view in _contentContainerView.subviews) {
            [view removeFromSuperview];
        }
        
        [self resizeForContent:content];
        [_contentContainerView addSubview:content];
    }
}

- (BOOL)isLoading
{
    return self.contentType == GddHudContentTypeLoading;
}

- (void)setActivityIndicatorColor:(UIColor *)activityIndicatorColor
{
    _activityIndicatorColor = activityIndicatorColor;
    if (self.contentType == GddHudContentTypeLoading && [self.contentView isKindOfClass:[UIActivityIndicatorView class]]) {
        ((UIActivityIndicatorView *)self.contentView).color = activityIndicatorColor;
    }
}

- (void)setLoading
{
    UIActivityIndicatorView* aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    aiv.color = self.activityIndicatorColor;
    [aiv startAnimating];
    [self setContent:aiv animated:self.willAnimateContentChange contentType:GddHudContentTypeLoading];
}

- (void)setDismissesOnCoverTap {
    self.coverTapActionBlock = ^(GddHud *hud, NSInteger index){
        return YES;
    };
}

#pragma mark Default method implementation

- (void)animateShowWithCompletion:(void (^)(BOOL))completion
{
    self.alpha=0;
    self.coverView.alpha=0;
    [UIView animateWithDuration:.3f animations:^{
        self.alpha=1;
        self.coverView.alpha=1;
    } completion:^(BOOL finished) {
        if(completion){
            completion(finished);
        }
    }];
}
- (void)animateDismissWithCompletion:(void (^)(BOOL))completion
{
    [UIView animateWithDuration:.3f animations:^{
        self.alpha=0;
        self.coverView.alpha=0;
    } completion:^(BOOL finished) {
        if(completion){
            completion(finished);
        }
    }];
}

#pragma mark - Showing and Dismissing

- (BOOL)isDisplayed {
    return self == [[_HudManager instance] currentHud];
}

- (void)showIfNeeded {
    if (!self.isDisplayed) {
        [self show];
    }
}

- (void)show
{
    [[_HudManager instance] showHud:self];
}
- (void)dismiss
{
    [[_HudManager instance] dismissCurrentHud];
}

@end

//================================================================================================
//  _HudManager Implementation
//================================================================================================

@implementation _HudManager

-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIViewController *)keyWindowRootViewController {
    return _keyWindow.rootViewController;
}

+(id) instance{
    static _HudManager* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [_HudManager new];
    });
    return manager;
}

-(id) init{
    self = [super init];
    if(self){
        _hudsToBeDisplayed = [NSMutableArray new];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

-(_HudViewController*) hudViewController{
    return (_HudViewController*)_hudWindow.rootViewController;
}

-(GddHud*) currentHud{
    return [self hudViewController].hud;
}

#pragma mark Show Hud

-(void) showHud:(GddHud *)hud{
    if([self currentHud]){
        [self addHudToBeDisplayed:hud];
    }else{
        _keyWindow = [UIApplication sharedApplication].keyWindow;

        UIWindow* window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        window.windowLevel = UIWindowLevelNormal;//TODO: change this to display below alerts
        window.backgroundColor = [UIColor clearColor];

        [_keyWindow endEditing:YES];

        _HudViewController* controller = [[_HudViewController alloc] initWithHud:hud];
        window.rootViewController = controller;
        [window makeKeyAndVisible];
        _hudWindow = window;
    }
}

- (void)coverTap
{
    GddHud *hud = [self currentHud];
    GddHudActionBlock actionBlock = hud.coverTapActionBlock;
    if (actionBlock) {
        if (actionBlock(hud, -1)) {
            [self dismissCurrentHud];
        }
    }
}

-(void) dismissCurrentHud{
    GddHud* hud = [self currentHud];
    [_hudWindow endEditing:YES];
    if(hud){
        [hud animateDismissWithCompletion:^(BOOL finished) {
            [_keyWindow makeKeyAndVisible];
            _keyWindow = nil;
            _hudWindow = nil;
            [self startHudsToBeDisplayedTimerIfRequired];
        }];
    }else{
        NSLog(@"Tried to dismiss hud but there was not current hud");
    }
}

#pragma mark Huds To Be Displayed
-(NSArray*) hudsToBeDisplayed{
    return [[NSArray alloc] initWithArray:_hudsToBeDisplayed];
}
-(void) addHudToBeDisplayed:(GddHud*)hud{
    [_hudsToBeDisplayed addObject:hud];
    [self startHudsToBeDisplayedTimerIfRequired];
}
-(GddHud*) popHudToDisplay{
    if(_hudsToBeDisplayed.count){
        GddHud* hud = [_hudsToBeDisplayed objectAtIndex:0];
        [_hudsToBeDisplayed removeObjectAtIndex:0];
        return hud;
    }else{
        return nil;
    }
}

-(void) startHudsToBeDisplayedTimerIfRequired{
    if(!_hudsToBeDisplayedTimer&&_hudsToBeDisplayed.count){
        _hudsToBeDisplayedTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hudsToBeDisplayedTimerFired:) userInfo:nil repeats:NO];
    }
}

-(void) stopHudsToBeDisplayedTimer{
    if([_hudsToBeDisplayedTimer isValid]){
        [_hudsToBeDisplayedTimer invalidate];
    }
    _hudsToBeDisplayedTimer = nil;
}

-(void) hudsToBeDisplayedTimerFired:(NSTimer*)timer{
    [self stopHudsToBeDisplayedTimer];
    if([self currentHud]){
        [self startHudsToBeDisplayedTimerIfRequired];
    }else{
        [self showHud: [self popHudToDisplay]];
    }
}

#pragma mark Entered background
-(void) applicationDidEnterBackground:(NSNotification*)notif{
    [self stopHudsToBeDisplayedTimer];
}
-(void) applicationWillEnterForeground:(NSNotification*)notif{
    [self startHudsToBeDisplayedTimerIfRequired];
}

@end


//================================================================================================
//  _HudViewController Implementation
//================================================================================================

@implementation _HudViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithHud:(GddHud *)hud
{
    self = [super initWithNibName:nil bundle:nil];
    if(self){
        _hud = hud;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    _hud.translatesAutoresizingMaskIntoConstraints = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:0
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                           constant:CGRectGetWidth(self.view.bounds)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:0
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:CGRectGetHeight(self.view.bounds)]];


    // Keyboard container, adding hud now so that the appearance kicks in
    UIView* view = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:view];
    _hudKeyboardContainer = view;
    [_hudKeyboardContainer addSubview:_hud];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:@{@"view":_hudKeyboardContainer}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_hudKeyboardContainer}]];

    // Cover
    if (_hud.coverView) {
        [self.view insertSubview:_hud.coverView belowSubview:_hudKeyboardContainer];
        _hud.coverView.frame = self.view.bounds;

        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:0 metrics:nil views:@{@"view":_hud.coverView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":_hud.coverView}]];
    }

    [_hudKeyboardContainer addConstraint:[NSLayoutConstraint constraintWithItem:_hud
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_hudKeyboardContainer
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.f constant:0.f]];
    [_hudKeyboardContainer addConstraint:[NSLayoutConstraint constraintWithItem:_hud
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:_hud.superview
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.f constant:0.f]];
    [_hud _addConstraints];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_hud animateShowWithCompletion:nil];
}

-(UIStatusBarStyle) preferredStatusBarStyle{
    return [[[_HudManager instance] keyWindowRootViewController] preferredStatusBarStyle];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [[[_HudManager instance] keyWindowRootViewController] supportedInterfaceOrientations];
}

- (UIViewAnimationOptions)__optionForCurve:(UIViewAnimationCurve)curve {
    switch (curve) {
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
        default:
            return UIViewAnimationOptionCurveEaseInOut;
    }
}

-(void) keyboardWillShow:(NSNotification*)notification{
    CGRect frameInWindow = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    UIViewAnimationOptions curve = [self __optionForCurve:[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];

    CGAffineTransform t = _hudKeyboardContainer.transform;
    _hudKeyboardContainer.transform = CGAffineTransformIdentity;
    CGRect frameInView = [_hudKeyboardContainer convertRect:frameInWindow fromView:nil];
    _hudKeyboardContainer.transform = t;

    CGFloat keyboardHeightToConsider = MIN(frameInView.size.height, frameInView.size.width);

    [UIView animateWithDuration:duration
                          delay:0
                        options:curve|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _hudKeyboardContainer.transform = CGAffineTransformMakeTranslation(0, -keyboardHeightToConsider*.5);
                     } completion:nil];
}

-(void) keyboardWillHide:(NSNotification*)notification{
    NSTimeInterval duration = [[notification.userInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions curve = [self __optionForCurve:[[notification.userInfo valueForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];

    [UIView animateWithDuration:duration
                          delay:0
                        options:curve|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _hudKeyboardContainer.transform = CGAffineTransformMakeTranslation(0, 0);
                     } completion:nil];
}



-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(!CGRectContainsPoint(_hud.bounds, [[touches anyObject] locationInView:_hud])){
        [[_HudManager instance] coverTap];
    }
}

@end