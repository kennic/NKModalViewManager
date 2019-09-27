//
//  NKFullscreenViewController.m
//  NKFullscreenViewController
//
//  Created by Nam Kennic on 10/8/13.
//  Copyright (c) 2013 Nam Kennic. All rights reserved.
//

#import "NKFullscreenViewController.h"

#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)
#define ANIMATE_DURATION 0.4f

NSString * const FULLSCREEN_VIEW_CONTROLLER_WILL_PRESENT	= @"FULLSCREEN_VIEW_CONTROLLER_WILL_PRESENT";
NSString * const FULLSCREEN_VIEW_CONTROLLER_DID_PRESENT		= @"FULLSCREEN_VIEW_CONTROLLER_DID_PRESENT";
NSString * const FULLSCREEN_VIEW_CONTROLLER_WILL_DISMISS	= @"FULLSCREEN_VIEW_CONTROLLER_WILL_DISMISS";
NSString * const FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS		= @"FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS";


@interface NKFullscreenViewController ()

@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, assign) CGRect targetFrame;
@property (nonatomic, strong) UIView *startFromView;

@property (nonatomic, strong) UIWindow					*window;
@property (nonatomic, strong) UIWindow					*lastWindow;
@property (nonatomic, strong) UIViewController			*lastPresentedViewController;
@property (nonatomic, strong) UIView					*lastSuperview;
@property (nonatomic, assign) CGRect					lastContentFrame;
@property (nonatomic, assign) UIInterfaceOrientation	lastOrientation;
@property (nonatomic, assign) BOOL needsRotating;

@end

@implementation NKFullscreenViewController


#pragma mark -

+ (CGSize) screenSize {
	CGSize screenSize = [UIScreen mainScreen].bounds.size;
	if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
		screenSize = CGSizeMake(screenSize.height, screenSize.width);
	}
	
	return screenSize;
}

+ (CGSize) contentSize {
	CGSize result;
	
	UIWindow *baseWindow = [UIApplication sharedApplication].keyWindow;
	
	if (baseWindow && baseWindow.rootViewController) {
		result = baseWindow.rootViewController.view.bounds.size;
	}
	else {
		result = [self.class screenSize];
	}
	
	return result;
}

+ (CGRect) mainBounds {
	return [UIScreen mainScreen].bounds;
	
	/*
	CGSize screenSize = [self.class contentSize];
	return CGRectMake(0, 0, screenSize.width, screenSize.height);
	*/
	
	/*
	UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
	if ((UIInterfaceOrientationIsPortrait(interfaceOrientation) && screenSize.width>screenSize.height) || (UIInterfaceOrientationIsLandscape(interfaceOrientation) && screenSize.height>screenSize.width)) {
		return CGRectMake(0, 0, screenSize.height, screenSize.width);
	}
	else {
		return CGRectMake(0, 0, screenSize.width, screenSize.height);
	}
	*/
}

#pragma mark - Initialization

- (id) init {
	if ((self = [super initWithNibName:nil bundle:nil])) {
		self.modalTransitionStyle	= UIModalTransitionStyleCrossDissolve;
		self.modalPresentationStyle = UIModalPresentationFullScreen;
		self.view.backgroundColor	= [UIColor clearColor];
		
		self.shouldUseChildViewControllerForStatusBarVisual = YES;
	}
	
	return self;
}


#pragma mark - Public Methods

- (void) setDelegate:(id)delegateTarget onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector {
	
}

- (void) presentFullscreenViewController:(UIViewController*)sourceViewController {
	[self presentFullscreenViewController:sourceViewController animatedFromView:nil];
}

- (void) presentFullscreenViewController:(UIViewController*)sourceViewController animatedFromView:(UIView*)fromView {
	_contentViewController = [sourceViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)sourceViewController).visibleViewController : sourceViewController;
	[self presentFullscreenView:sourceViewController.view animatedFromView:fromView];
}

- (void) presentFullscreenView:(UIView*)sourceView {
	[self presentFullscreenView:sourceView animatedFromView:sourceView];
}

- (void) presentFullscreenView:(UIView*)sourceView animatedFromView:(UIView*)fromView {
	[[NSNotificationCenter defaultCenter] postNotificationName:FULLSCREEN_VIEW_CONTROLLER_WILL_PRESENT object:self];
	_contentView	= sourceView;
	_startFromView	= fromView;
	
	UIView *viewForStartFrame			= fromView ?: sourceView;
	self.lastWindow						= [UIApplication sharedApplication].keyWindow;
	self.lastPresentedViewController	= self.lastWindow.rootViewController;
	self.lastContentFrame				= self.lastPresentedViewController.view.frame;
	self.lastOrientation				= [UIApplication sharedApplication].statusBarOrientation;
	self.lastSuperview					= sourceView.superview;
	BOOL isCurrentlyPortrait			= UIInterfaceOrientationIsPortrait(_lastOrientation);
	
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_window.rootViewController = self;
	_window.windowLevel = UIWindowLevelNormal + 1;
	[_window makeKeyAndVisible];
	
	self.startFrame  = [self.view convertRect:viewForStartFrame.frame fromView:viewForStartFrame.superview ?: viewForStartFrame];//[viewForStartFrame.superview convertRect:viewForStartFrame.frame toView:self.view];
	self.targetFrame = self.view.bounds;
	
	UIInterfaceOrientation targetOrientation = [_contentViewController preferredInterfaceOrientationForPresentation];
	BOOL isTargetPortrait		= UIInterfaceOrientationIsPortrait(targetOrientation);
	self.needsRotating			= isCurrentlyPortrait!=isTargetPortrait;
	
	if (_needsRotating) {
		_contentView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(targetOrientation==UIInterfaceOrientationLandscapeLeft ? 90 : -90));
	}
	
	[self.view addSubview:_contentView];
	_contentView.frame = _startFrame;
	
	_startFromView.hidden = YES;
	
	typeof(self) __weak weakSelf = self;
	[UIView animateWithDuration:ANIMATE_DURATION delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
		if (weakSelf.needsRotating) weakSelf.contentView.transform = CGAffineTransformIdentity;
		
		weakSelf.contentView.frame = weakSelf.targetFrame;
		[weakSelf.contentView layoutIfNeeded];
	} completion:^(BOOL finished) {
		[weakSelf setNeedsStatusBarAppearanceUpdate];
		[[NSNotificationCenter defaultCenter] postNotificationName:FULLSCREEN_VIEW_CONTROLLER_DID_PRESENT object:weakSelf];
		if (weakSelf.enterFullscreenBlock) weakSelf.enterFullscreenBlock(weakSelf);
	}];
}

- (void) dismissViewAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[[NSNotificationCenter defaultCenter] postNotificationName:FULLSCREEN_VIEW_CONTROLLER_WILL_DISMISS object:self];
	
//	if (_startFromView != nil) {
//		_startFrame = [self.view convertRect:_startFromView.frame fromView:_startFromView];
//	}
//	else {
//		_startFrame = _lastContentFrame;
//	}
	
	typeof(self) __weak weakSelf = self;
	[UIView animateWithDuration:ANIMATE_DURATION delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		weakSelf.view.backgroundColor = [UIColor clearColor];
		
		if (weakSelf.needsRotating) {
			UIInterfaceOrientation targetOrientation = [weakSelf.contentViewController preferredInterfaceOrientationForPresentation];
			weakSelf.contentView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(targetOrientation==UIInterfaceOrientationLandscapeLeft ? 90 : -90));
		}
		
		weakSelf.contentView.frame = weakSelf.startFrame;
		[weakSelf.contentView layoutIfNeeded];
		
		UIDevice *currentDevice = [UIDevice currentDevice];
//		[UIView setAnimationsEnabled:NO];
		[currentDevice beginGeneratingDeviceOrientationNotifications];
//		[[UIApplication sharedApplication] setStatusBarOrientation:weakSelf.lastOrientation animated:NO];
		[UIApplication sharedApplication].statusBarOrientation = weakSelf.lastOrientation;
		[currentDevice setValue:[NSNumber numberWithInteger:weakSelf.lastOrientation] forKey:@"orientation"];
		[currentDevice endGeneratingDeviceOrientationNotifications];
		
		[UIViewController attemptRotationToDeviceOrientation];
//		[UIView setAnimationsEnabled:YES];
		
	} completion:^(BOOL finished) {
		weakSelf.startFromView.hidden = NO;
		
		if (weakSelf.lastSuperview) [weakSelf.lastSuperview addSubview:weakSelf.contentView];
		weakSelf.contentView.transform = CGAffineTransformIdentity;
		weakSelf.contentView.frame = weakSelf.lastContentFrame;
		
		[weakSelf.lastWindow makeKeyAndVisible];
		
		[weakSelf.window.rootViewController resignFirstResponder];
		weakSelf.window.rootViewController = nil;
		[weakSelf.window removeFromSuperview];
		weakSelf.window = nil;

		
		
		[weakSelf.lastPresentedViewController becomeFirstResponder];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS object:weakSelf];
		if (weakSelf.exitFullscreenBlock) weakSelf.exitFullscreenBlock(weakSelf);
		if (completion) completion();
	}];
}


#pragma mark - UIResponder

- (BOOL) isFirstResponder {
	return self.currentFirstResponder ? [self.currentFirstResponder isFirstResponder] : [super isFirstResponder];
}

- (BOOL) canBecomeFirstResponder {
	return self.currentFirstResponder ? [self.currentFirstResponder canBecomeFirstResponder] : [super canBecomeFirstResponder];
}

- (BOOL) canResignFirstResponder {
	return self.currentFirstResponder ? [self.currentFirstResponder canResignFirstResponder] : [super canResignFirstResponder];
}

- (BOOL) becomeFirstResponder {
	return self.currentFirstResponder ? [self.currentFirstResponder becomeFirstResponder] : [super becomeFirstResponder];
}

- (BOOL) resignFirstResponder {
	return self.currentFirstResponder ? [self.currentFirstResponder resignFirstResponder] : [super resignFirstResponder];
}

- (UIResponder*) currentFirstResponder {
	return self.contentViewController ? self.contentViewController : (self.contentView ? self.contentView : nil);
}


#pragma mark - Private Methods

- (UIImage*) imageFromContentView:(UIView*)view {
	UIImage *contentImage = nil;
	
	if ([view conformsToProtocol:@protocol(NKFullscreenViewControllerProtocol)]) {
		if ([view respondsToSelector:@selector(imageForFullscreenPresentation:)]) {
			contentImage = [view performSelector:@selector(imageForFullscreenPresentation:) withObject:self];
			if (contentImage) return contentImage;
		}
	}
	
	return contentImage;
}


#pragma mark - Rotation Handling

- (BOOL) shouldAutorotate {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController shouldAutorotate] : YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController preferredInterfaceOrientationForPresentation] : [UIApplication sharedApplication].statusBarOrientation;
}

#ifdef __IPHONE_9_0
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}
#else
- (NSUInteger) supportedInterfaceOrientations {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}
#endif


#pragma mark - Status Bar Handling

- (BOOL) prefersStatusBarHidden {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController prefersStatusBarHidden] : YES;
}

- (UIStatusBarAnimation) preferredStatusBarUpdateAnimation {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController preferredStatusBarUpdateAnimation] : UIStatusBarAnimationFade;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController preferredStatusBarStyle] : UIStatusBarStyleLightContent;
}


#pragma mark -

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_contentView = nil;
	_contentViewController = nil;
	self.startFromView = nil;
	
	self.enterFullscreenBlock	= nil;
	self.exitFullscreenBlock	= nil;
}

@end
