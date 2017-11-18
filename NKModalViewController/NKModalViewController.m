//
//  NKModalViewController.m
//  NKModalViewController
//
//  Created by Nam Kennic on 1/21/16.
//  Copyright (c) 2016 Nam Kennic. All rights reserved.
//

#import "NKModalViewController.h"

NSString * const MODAL_VIEW_CONTROLLER_WILL_PRESENT				= @"MODAL_VIEW_CONTROLLER_WILL_PRESENT";
NSString * const MODAL_VIEW_CONTROLLER_DID_PRESENT				= @"MODAL_VIEW_CONTROLLER_DID_PRESENT";
NSString * const MODAL_VIEW_CONTROLLER_WILL_DISMISS				= @"MODAL_VIEW_CONTROLLER_WILL_DISMISS";
NSString * const MODAL_VIEW_CONTROLLER_DID_DISMISS				= @"MODAL_VIEW_CONTROLLER_DID_DISMISS";

#define DEFAULT_ANIMATE_DURATION 0.45f
#define DEFAULT_CORNER_RADIUS_VALUE 8.0f
#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)

@interface NKModalViewController ()

@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, assign) CGRect targetFrame;
@property (nonatomic, assign) CGRect bottomViewFrame;

@property (nonatomic, assign) UIInterfaceOrientation lastOrientation;
@property (nonatomic, assign) UIInterfaceOrientation targetOrientation;
@property (nonatomic, assign) CGFloat lastStartViewAlpha;
@property (nonatomic, assign) CGRect lastFrame;
@property (nonatomic, strong) UIView *lastSuperview;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *bottomView;

@property (nonatomic, strong) UIVisualEffectView *blurBackgroundView;
@property (nonatomic, strong) UIView *blurContainerView;

@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL needsRotating;
@property (nonatomic, assign) BOOL needsUpdateStartFrameOnDismiss;

@end

@implementation NKModalViewController


#pragma mark - Helpers

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
	
	// TODO: Get correct screen size when in splited mode or slide-over mode on iPad
	/*
	 CGSize screenSize = [self.class contentSize];
	 return CGRectMake(0, 0, screenSize.width, screenSize.height);
	 */
	
	/*
	 if ([UIDevice isIPHONE]) {
		return [UIScreen mainScreen].bounds;
	 }
	 else {
		CGSize screenSize = [self.class contentSize];
		return CGRectMake(0, 0, screenSize.width, screenSize.height);
	 }
	 */
}

+ (UIViewController*) topPresentedViewController {
	UIViewController *result = [UIApplication sharedApplication].keyWindow.rootViewController;
	
	while (result.presentedViewController!=nil) {
		result = result.presentedViewController;
	}
	
	return result;
}

+ (UIImage*) imageFromView:(UIView*)view {
	if (view.bounds.size.width==0 || view.bounds.size.height==0) return nil;
	
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
	
	if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
		CGRect rect = view.bounds;
		if ([view isKindOfClass:[UIScrollView class]]) {
			UIScrollView *scrollView = (UIScrollView*)view;
			rect.origin.x -= scrollView.contentOffset.x;
			rect.origin.y -= scrollView.contentOffset.y;
		}
		
		[view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
	}
	else {
		[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	}
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}


#pragma mark - Initialization

- (id) init {
	if ((self = [super initWithNibName:nil bundle:nil])) {
		self.tapOutsideToDismiss		= NO;
		self.shouldUseChildViewControllerForStatusBarVisual = YES;
		self.enableKeyboardShifting		= YES;
		self.presentingStyle			= NKModalPresentingStyleFromBottom;
		self.dismissingStyle			= NKModalDismissingStyleToBottom;
		
		tapGesture	= [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
		tapGesture.delegate = self;
		tapGesture.delaysTouchesEnded = NO;
		tapGesture.cancelsTouchesInView = NO;
		
		self.modalTransitionStyle	= UIModalTransitionStyleCrossDissolve;
		self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
		self.view.backgroundColor	= [UIColor clearColor];
		
		[self.view addGestureRecognizer:tapGesture];
		
		self.containerView = [UIView new];
		[self.view addSubview:_containerView];
	}
	
	return self;
}


#pragma mark - Public Methods

- (void) setDelegate:(id)delegateTarget onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector {
	_delegate		= delegateTarget;
	_onEnterModal	= onEnterModalSelector;
	_onExitModal	= onExitModalSelector;
}

- (void) presentModalViewController:(UIViewController*)sourceViewController {
	[self presentModalViewController:sourceViewController animatedFromView:nil];
}

- (void) presentModalViewController:(UIViewController*)sourceViewController animatedFromView:(UIView*)fromView {
	_contentViewController = sourceViewController;
	if ([[self currentContentViewController] respondsToSelector:@selector(willEnterModalViewController:)]) [[self currentContentViewController] performSelector:@selector(willEnterModalViewController:) withObject:self];
	[_contentViewController addObserver:self forKeyPath:@"preferredContentSize" options:NSKeyValueObservingOptionNew context:nil];
	
	[self presentModalView:sourceViewController.view animatedFromView:fromView];
}

- (void) presentModalView:(UIView*)sourceView {
	[self presentModalView:sourceView animatedFromView:nil];
}

- (void) presentModalView:(UIView*)sourceView animatedFromView:(UIView*)fromView {
	if (_isPresenting || _isAnimating) return;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_WILL_PRESENT object:self];
	_contentView	= sourceView;
	_startView		= fromView;
	
	_isPresenting		= YES;
	self.isAnimating	= YES;
	self.lastSuperview	= _contentView.superview;
	self.lastFrame		= _contentView.frame;
	
	UIViewController *presentingViewController = [self.class topPresentedViewController];
	
	UIImageView *capturedStartView = nil;
	UIImageView *capturedContentView = nil;
	
	self.lastOrientation	= [UIApplication sharedApplication].statusBarOrientation;
	self.targetOrientation	= [_contentViewController preferredInterfaceOrientationForPresentation];
	self.needsRotating		= _lastOrientation!=_targetOrientation;
	
	if (_needsRotating) {
		[self forceDeviceRotateToOrientation:_targetOrientation];
		self.view.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-[self rotationDegreesFromOrientation:_lastOrientation toOrientation:_targetOrientation]));
	}
	
	[self updateStartFrame];
	
	CGFloat cornerRadius = [self cornerRadiusValue];
	_containerView.layer.cornerRadius = cornerRadius;
	_containerView.layer.masksToBounds = cornerRadius>0.0;
	
	if (_startView) {
		self.lastStartViewAlpha = _startView.alpha;
		
		UIImage *image = [self.class imageFromView:_startView];
		if (image) {
			capturedStartView = [[UIImageView alloc] initWithImage:image];
			capturedStartView.clipsToBounds = YES;
			capturedStartView.contentMode = UIViewContentModeScaleAspectFit;
			capturedStartView.frame = _startFrame;
			[self.view addSubview:capturedStartView];
		}
		
		if (_contentView.superview==nil) {
			_contentView.frame = [self targetContentFrame];
			image = [self.class imageFromView:_contentView];
			if (image) {
				capturedContentView = [[UIImageView alloc] initWithImage:image];
				capturedContentView.clipsToBounds = YES;
				capturedContentView.contentMode = UIViewContentModeScaleAspectFill;
				capturedContentView.frame = _startFrame;
				capturedContentView.alpha = 0.0;
				capturedContentView.layer.cornerRadius = _containerView.layer.cornerRadius;
				[self.view addSubview:capturedContentView];

			}
		}
		
		if (_needsRotating) {
			capturedStartView.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS([self rotationDegreesFromOrientation:_lastOrientation toOrientation:_targetOrientation]));
			capturedContentView.transform = capturedStartView.transform;
		}
		
		_contentView.alpha = 0.0;
	}
	
	self.bottomView = [self valueFromProtocolConformer:_contentViewController withSelector:@selector(viewAtBottomOfModalViewController:) andObject:self andDefaultValue:nil];
	if (_bottomView) {
		_bottomView.alpha = 0.0;
		
		[self.view insertSubview:_bottomView atIndex:0];
		[self updateBottomViewFrame];
		
		CGRect rect = _bottomViewFrame;
		rect.origin.y = self.view.bounds.size.height;
		_bottomView.frame = rect;
	}
	
	[presentingViewController presentViewController:self animated:NO completion:^{
		self.targetFrame = [self targetContentFrame];
		
		_containerView.frame = _startFrame;
		_contentView.frame = _containerView.bounds;
		[_containerView addSubview:_contentView];
		
		[self setupBlurBackgroundImage];
		
		if (capturedStartView) _startView.alpha = 0.0;
		
		CGAffineTransform transform = CGAffineTransformIdentity;
		
		NKModalPresentingStyle transitionStyle = [self presentStyleValue];
		if (transitionStyle == NKModalPresentingStyleZoomIn) {
			transform = CGAffineTransformMakeScale(0.8, 0.8);
			_containerView.alpha = 0.0;
		}
		else if (transitionStyle == NKModalPresentingStyleZoomOut) {
			transform = CGAffineTransformMakeScale(1.1, 1.1);
			_containerView.alpha = 0.0;
		}
		
		_containerView.transform = transform;
		
		[UIView animateWithDuration:[self animateDuration] delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			self.view.backgroundColor = _blurContainerView ? [UIColor colorWithWhite:0.0 alpha:0.0] : [UIColor colorWithWhite:0.0 alpha:0.8];
			_blurContainerView.alpha = 1.0;
			
			if (_needsRotating) {
				capturedStartView.transform = CGAffineTransformIdentity;
				capturedContentView.transform = CGAffineTransformIdentity;
			}
			_containerView.transform = CGAffineTransformIdentity;
			_containerView.frame = _targetFrame;
			_containerView.alpha = 1.0;
			
			_contentView.frame = _containerView.bounds;
			
			capturedStartView.frame = _targetFrame;
			capturedStartView.alpha = 0;
			
			capturedContentView.frame = _targetFrame;
			capturedContentView.alpha = 1.0;
			
			if (_startView) {
				_startView.alpha = 0.0;
				if (!capturedContentView) _contentView.alpha = 1.0;
			}
			
			if (_bottomView) {
				_bottomView.alpha = 1.0;
				_bottomView.frame = _bottomViewFrame;
			}
		} completion:^(BOOL finished) {
			_isPresenting = NO;
			self.isAnimating = NO;
			[self.view setNeedsLayout];
			
			_contentView.alpha	= 1.0;
			_contentView.frame = _containerView.bounds;
			
			capturedContentView.image = nil;
			[capturedContentView removeFromSuperview];
			
			capturedStartView.image = nil;
			[capturedStartView removeFromSuperview];
			
			if ([[self currentContentViewController] respondsToSelector:@selector(didEnterModalViewController:)]) [[self currentContentViewController] performSelector:@selector(didEnterModalViewController:) withObject:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_DID_PRESENT object:self];
			if (_enterModalBlock) _enterModalBlock(self);
		}];
	}];
}

- (void) dismissWithAnimated:(BOOL)animating completion:(void (^)(void))completion {
	if (_isDismissing || _isAnimating) return;
	
	if ([[self currentContentViewController] respondsToSelector:@selector(willExitModalViewController:)]) [[self currentContentViewController] performSelector:@selector(willExitModalViewController:) withObject:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_WILL_DISMISS object:self];
	
	[self removeObserver];
	
	UIImageView *capturedStartView = nil;
	
	if (_startView) {
		_startView.alpha = _lastStartViewAlpha;
		UIImage *image = [self.class imageFromView:_startView];
		_startView.alpha = 0.0;
		
		if (image) {
			capturedStartView = [[UIImageView alloc] initWithImage:image];
			capturedStartView.clipsToBounds = YES;
			capturedStartView.contentMode = UIViewContentModeScaleAspectFit;
			capturedStartView.frame = _targetFrame;
			capturedStartView.alpha = 0.0;
			[self.view addSubview:capturedStartView];
		}
	}
	
	UIViewController *target = [self currentContentViewController];
	
	if (target != nil) {
		if ([target conformsToProtocol:@protocol(NKModalViewControllerProtocol)] && [target respondsToSelector:@selector(dismissRectForModalViewController:)]) {
			self.startFrame = [((id<NKModalViewControllerProtocol>)target) dismissRectForModalViewController:self];
			_needsUpdateStartFrameOnDismiss = NO;
		}
	}
	
	if (_needsUpdateStartFrameOnDismiss) [self updateStartFrame];
	
	_isDismissing	 = YES;
	self.isAnimating = YES;
	
	[UIView animateWithDuration:animating ? [self animateDuration] : 0.0 delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.view.backgroundColor = [UIColor clearColor];
		_blurContainerView.alpha = 0.0;
		
		CGAffineTransform transform = CGAffineTransformIdentity;
		
		if (_startView) {
			_contentView.alpha = 0.0;
			
			if (_needsRotating) {
				transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS([self rotationDegreesFromOrientation:_lastOrientation toOrientation:_targetOrientation]));
				capturedStartView.transform = transform;
			}
		}
		else {
			NKModalDismissingStyle transitionStyle = [self dismissStyleValue];
			if (transitionStyle == NKModalDismissingStyleZoomIn) {
				transform = CGAffineTransformMakeScale(1.1, 1.1);
				_containerView.alpha = 0.0;
			}
			else if (transitionStyle == NKModalDismissingStyleZoomOut) {
				transform = CGAffineTransformMakeScale(0.8, 0.8);
				_containerView.alpha = 0.0;
			}
		}
		
		capturedStartView.frame = _startFrame;
		capturedStartView.alpha = 1.0;
		
		_containerView.frame = _startFrame;
		_contentView.frame = _containerView.bounds;
		_containerView.transform = transform;
		
		if (_bottomView) {
			_bottomViewFrame.origin.y = self.view.bounds.size.height;
			_bottomView.alpha = 0.0;
			_bottomView.frame = _bottomViewFrame;
		}
	} completion:^(BOOL finished) {
		if (_lastSuperview) {
			[_lastSuperview addSubview:_contentView];
			_containerView.frame = _lastFrame;
			_contentView.frame = _containerView.bounds;
		}
		else {
			_startView.alpha = _lastStartViewAlpha;
		}
		
		capturedStartView.image = nil;
		[capturedStartView removeFromSuperview];
		
		[_blurContainerView removeFromSuperview];
		_blurContainerView = nil;
		
		[_blurBackgroundView removeFromSuperview];
		_blurBackgroundView = nil;
		
		[self dismissViewControllerAnimated:NO completion:^{
			_isDismissing	 = NO;
			self.isAnimating = NO;
			[self.view setNeedsLayout];
			
			if (_needsRotating) {
				[self forceDeviceRotateToOrientation:_lastOrientation];
			}
			
			if ([[self currentContentViewController] respondsToSelector:@selector(didExitModalViewController:)]) [[self currentContentViewController] performSelector:@selector(didExitModalViewController:) withObject:self];
			[[NSNotificationCenter defaultCenter] postNotificationName:MODAL_VIEW_CONTROLLER_DID_DISMISS object:self];
			if (completion) completion();
			if (_exitModalBlock) _exitModalBlock(self);
		}];
	}];
}

- (void) setNeedsLayoutView {
	if (!_isDismissing) [self updatePositionWithAnimated:YES];
}

- (void) updatePositionWithAnimated:(BOOL)animated {
	CGRect rect = [self targetContentFrame];
	[self updateBottomViewFrame];
	
	if (animated) {
		[UIView animateWithDuration:[self animateDuration] delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
			_containerView.frame	= rect;
			_contentView.frame		= _containerView.bounds;
			_bottomView.frame		= _bottomViewFrame;
		} completion:nil];
	}
	else {
		_containerView.frame	= rect;
		_contentView.frame		= _containerView.bounds;
		_bottomView.frame		= _bottomViewFrame;
	}
}

- (UIViewController*) currentContentViewController {
	if ([self.contentViewController conformsToProtocol:@protocol(NKModalViewControllerProtocol)]) {
		return self.contentViewController;
	}
	
	UIViewController *result = nil;
	
	if ([self.contentViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController *navigationController = (UINavigationController*)self.contentViewController;
		result = navigationController.topViewController;
	}
	
	if (!result) result = self.contentViewController;
	return result;
}

- (void) setStartView:(UIView *)startView {
	if (startView!=_startView) {
		_startView = startView;
		[self updateStartFrame];
	}
}


#pragma mark -
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id) valueFromProtocolConformer:(id)target withSelector:(SEL)selector andObject:(id)object andDefaultValue:(id)defaultValue {
	id result = defaultValue;
	
	if (target && [target conformsToProtocol:@protocol(NKModalViewControllerProtocol)]) {
		if ([target respondsToSelector:selector]) {
			result = [target performSelector:selector withObject:object];
		}
	}
	else if ([_contentView conformsToProtocol:@protocol(NKModalViewControllerProtocol)]) {
		if ([_contentView respondsToSelector:selector]) {
			result = [target performSelector:selector withObject:object];
		}
	}
	
	return result;
}

- (CGSize) contentSize {
	CGSize viewSize = self.view.bounds.size;
	UIViewController *target = [self currentContentViewController];
	return target ? [target preferredContentSize] : [_contentView sizeThatFits:viewSize];
}

- (CGRect) targetContentFrame {
	UIViewController *target = [self currentContentViewController];
	
	if ([target conformsToProtocol:@protocol(NKModalViewControllerProtocol)] && [target respondsToSelector:@selector(presentRectForModalViewController:)]) {
		CGRect rect = [((id<NKModalViewControllerProtocol>)target) presentRectForModalViewController:self];
		return rect;
	}
	
	CGSize viewSize = self.view.bounds.size;
	viewSize.height -= keyboardHeight;
	
	CGSize contentSize = _contentViewController ? [_contentViewController preferredContentSize] : [_contentView sizeThatFits:viewSize];
	if (CGSizeEqualToSize(contentSize, CGSizeZero)) contentSize = viewSize;
	
	return CGRectMake(roundf(viewSize.width/2 - contentSize.width/2), roundf(viewSize.height/2 - contentSize.height/2), contentSize.width, contentSize.height);
}


- (void) updateStartFrame {
	if (_startView!=nil) {
		self.startFrame  = [_startView convertRect:_startView.bounds toCoordinateSpace:self.view];
		self.needsUpdateStartFrameOnDismiss = YES;
	}
	else if (_contentView.superview!=nil && _contentView.superview!=_containerView) {
		self.startFrame  = [_contentView convertRect:_contentView.bounds toCoordinateSpace:self.view];
		self.needsUpdateStartFrameOnDismiss = NO;
	}
	else {
		id<NKModalViewControllerProtocol> target = [self protocolTarget];
		
		if ([target respondsToSelector:@selector(startRectForModalViewController:)]) {
			self.startFrame = [target startRectForModalViewController:self];
			return;
		}
		
		CGSize viewSize = self.view.bounds.size;
		CGSize contentSize = [self contentSize];
		
		if (_isPresenting) {
			NKModalPresentingStyle transitionStyle = [self presentStyleValue];
			
			switch (transitionStyle) {
					case NKModalPresentingStyleFromBottom:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, viewSize.height, contentSize.width, contentSize.height);
					break;
					
					case NKModalPresentingStyleFromTop:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, -contentSize.height, contentSize.width, contentSize.height);
					break;
					
					case NKModalPresentingStyleFromLeft:
					self.startFrame = CGRectMake(-contentSize.width, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalPresentingStyleFromRight:
					self.startFrame = CGRectMake(contentSize.width, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalPresentingStyleZoomIn:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalPresentingStyleZoomOut:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
			}
		}
		else if (_isDismissing) {
			NKModalDismissingStyle transitionStyle = [self dismissingStyle];
			
			switch (transitionStyle) {
					case NKModalDismissingStyleToBottom:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, viewSize.height, contentSize.width, contentSize.height);
					break;
					
					case NKModalDismissingStyleToTop:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, -contentSize.height, contentSize.width, contentSize.height);
					break;
					
					case NKModalDismissingStyleToLeft:
					self.startFrame = CGRectMake(-contentSize.width, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalDismissingStyleToRight:
					self.startFrame = CGRectMake(contentSize.width, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalDismissingStyleZoomIn:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
					
					case NKModalDismissingStyleZoomOut:
					self.startFrame = CGRectMake(roundf(viewSize.width - contentSize.width)/2, roundf(viewSize.height - contentSize.height)/2, contentSize.width, contentSize.height);
					break;
			}
		}
		
		self.needsUpdateStartFrameOnDismiss = YES;
	}
}

- (void) updateBottomViewFrame {
	CGSize viewSize = self.view.bounds.size;
	CGSize bottomViewSize = [_bottomView sizeThatFits:viewSize];
	_bottomViewFrame = CGRectMake(roundf(viewSize.width/2 - bottomViewSize.width/2), viewSize.height - bottomViewSize.height - 10, bottomViewSize.width, bottomViewSize.height);
}

- (void) removeObserver {
	if (_contentViewController) {
		@try {
			[_contentViewController removeObserver:self forKeyPath:@"preferredContentSize"];
		}
		@catch (NSException *exception) {
			NSLog(@"Error: %@", exception);
		}
	}
	else {
		@try {
			[_contentView removeObserver:self forKeyPath:@"frame"];
			[_contentView removeObserver:self forKeyPath:@"bounds"];
		}
		@catch (NSException *exception) {
			NSLog(@"Error: %@", exception);
		}
	}
}

- (CGFloat) rotationDegreesFromOrientation:(UIInterfaceOrientation)fromOrientation toOrientation:(UIInterfaceOrientation)toOrientation {
	CGFloat result = 0.0;
	
	if (fromOrientation==UIInterfaceOrientationPortrait) {
		if (toOrientation==UIInterfaceOrientationPortraitUpsideDown) {
			result = 180;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeLeft) {
			result = 90;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeRight) {
			result = -90;
		}
	}
	else if (fromOrientation==UIInterfaceOrientationPortraitUpsideDown) {
		if (toOrientation==UIInterfaceOrientationPortrait) {
			result = 180;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeLeft) {
			result = -90;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeRight) {
			result = 90;
		}
	}
	else if (fromOrientation==UIInterfaceOrientationLandscapeLeft) {
		if (toOrientation==UIInterfaceOrientationPortrait) {
			result = -90;
		}
		else if (toOrientation==UIInterfaceOrientationPortraitUpsideDown) {
			result = 90;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeRight) {
			result = 180;
		}
	}
	else if (fromOrientation==UIInterfaceOrientationLandscapeRight) {
		if (toOrientation==UIInterfaceOrientationPortrait) {
			result = 90;
		}
		else if (toOrientation==UIInterfaceOrientationPortraitUpsideDown) {
			result = -90;
		}
		else if (toOrientation==UIInterfaceOrientationLandscapeLeft) {
			result = 180;
		}
	}
	
	return result;
}

- (void) forceDeviceRotateToOrientation:(UIInterfaceOrientation)orientation {
	UIDevice *currentDevice = [UIDevice currentDevice];
	[UIView setAnimationsEnabled:NO];
	[currentDevice beginGeneratingDeviceOrientationNotifications];
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
	[currentDevice endGeneratingDeviceOrientationNotifications];
	[UIViewController attemptRotationToDeviceOrientation];
	[UIView setAnimationsEnabled:YES];
}

#pragma mark -

- (void) setupBlurBackgroundImage {
	CGFloat blurValue = [self blurValue];
	
	if ((blurValue>0)) {
		if (!_blurContainerView) {
			self.blurContainerView = [UIView new];
			_blurContainerView.userInteractionEnabled = NO;
			_blurContainerView.alpha = 0.0;
			[self.view insertSubview:_blurContainerView atIndex:0];
		}
		
		if (!_blurBackgroundView) {
			BlurEffect *blurEffect = (BlurEffect*)[BlurEffect effectWithStyle:UIBlurEffectStyleDark];
			//	[blurEffect setValue:@(1) forKeyPath:@"effectSettings.blurRadius"];
			
			self.blurBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
			_blurBackgroundView.userInteractionEnabled = NO;
			[_blurContainerView addSubview:_blurBackgroundView];
		}
	}
	else {
		if (_blurBackgroundView) {
			[_blurBackgroundView removeFromSuperview];
			_blurBackgroundView = nil;
		}
		
		if (_blurContainerView) {
			[_blurContainerView removeFromSuperview];
			_blurContainerView = nil;
		}
	}
}

- (CGFloat) cornerRadiusValue {
	CGFloat value = DEFAULT_CORNER_RADIUS_VALUE;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(cornerRadiusValueForModalViewController:)]) {
		value = [target cornerRadiusValueForModalViewController:self];
	}
	
	return value;
}

- (CGFloat) blurValue {
	CGFloat value = 0.0f;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(animateDurationForModalViewController:)]) {
		value = [target backgroundBlurryValueForModalViewController:self];
	}
	
	return value;
}

- (NSTimeInterval) animateDuration {
	NSTimeInterval value = DEFAULT_ANIMATE_DURATION;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(animateDurationForModalViewController:)]) {
		value = [target animateDurationForModalViewController:self];
	}
	
	return value;
}

- (NKModalPresentingStyle) presentStyleValue {
	NKModalPresentingStyle value = _presentingStyle;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(presentingStyleForModalViewController:)]) {
		value = [target presentingStyleForModalViewController:self];
	}
	
	return value;
}

- (NKModalDismissingStyle) dismissStyleValue {
	NKModalDismissingStyle value = _dismissingStyle;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(dismissingStyleForModalViewController:)]) {
		value = [target dismissingStyleForModalViewController:self];
	}
	
	return value;
}

- (BOOL) allowKeyboardAvoiding {
	BOOL value = YES;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(shouldAllowKeyboardShiftingForModalViewController:)]) {
		value = [target shouldAllowKeyboardShiftingForModalViewController:self];
	}
	
	return value;
}

- (BOOL) shouldTapOutsideToDismiss {
	BOOL value = YES;
	id<NKModalViewControllerProtocol> target = [self protocolTarget];
	
	if ([target respondsToSelector:@selector(shouldTapOutsideToDismissModalViewController:)]) {
		value = [target shouldTapOutsideToDismissModalViewController:self];
	}
	
	return value;
}

- (id<NKModalViewControllerProtocol>) protocolTarget {
	UIViewController *activeViewController = [self currentContentViewController];
	
	if (activeViewController && [activeViewController conformsToProtocol:@protocol(NKModalViewControllerProtocol)]) {
		return (id<NKModalViewControllerProtocol>)activeViewController;
	}
	else if ([_contentView conformsToProtocol:@protocol(NKModalViewControllerProtocol)]) {
		return (id<NKModalViewControllerProtocol>)_contentView;
	}
	
	return nil;
}


#pragma mark - Events

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object==_contentViewController) {
		if ([keyPath isEqualToString:@"preferredContentSize"]) {
			if (!self.isAnimating) [self updatePositionWithAnimated:YES];
		}
	}
	else if (object==_contentView) {
		if ([keyPath isEqualToString:@"frame"] || [keyPath isEqualToString:@"bounds"]) {
			if (!self.isAnimating) [self updatePositionWithAnimated:YES];
		}
	}
}


#pragma mark - TapGesture

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if (touch.view==self.view) {
		if (self.tapOutsideToDismiss || [self shouldTapOutsideToDismiss]) {
			[self dismissWithAnimated:YES completion:nil];
			return NO;
		}
	}
	
	return YES;
}


#pragma mark - UIViewControllerDelegate

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.view.exclusiveTouch	= YES;
	self.view.backgroundColor	= [UIColor clearColor];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	if (!_isAnimating) [self updatePositionWithAnimated:NO];
	
	if (_blurBackgroundView) _blurBackgroundView.frame = self.view.bounds;
	if (_blurContainerView) _blurContainerView.frame = self.view.bounds;
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self registerForKeyboardNotifications];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize) preferredContentSize {
	return [self contentSize];
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
	return targetViewController ? [targetViewController prefersStatusBarHidden] : NO;
}

- (UIStatusBarAnimation) preferredStatusBarUpdateAnimation {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController preferredStatusBarUpdateAnimation] : UIStatusBarAnimationFade;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	UIViewController *targetViewController = self.shouldUseChildViewControllerForStatusBarVisual && [_contentViewController isKindOfClass:[UINavigationController class]] ? ((UINavigationController*)_contentViewController).visibleViewController : _contentViewController;
	return targetViewController ? [targetViewController preferredStatusBarStyle] : UIStatusBarStyleLightContent;
}


#pragma mark - Keyboard Handling

- (void) registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) keyboardWillShow:(NSNotification*)notification {
	if (!self.enableKeyboardShifting) return;
	
	NSDictionary *userInfo		= [notification userInfo];
	CGRect endFrame				= [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGFloat duration			= [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve	= [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	CGRect keyboardFrame			= [self.view convertRect:endFrame fromView:self.view.window];
	CGFloat visibleKeyboardHeight	= CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrame);
	
	[self setVisibleKeyboardHeight:visibleKeyboardHeight animationDuration:duration animationOptions:curve << 16];
}

- (void) keyboardWillHide:(NSNotification*)notification {
	if (!self.enableKeyboardShifting) return;
	
	NSDictionary *userInfo		= [notification userInfo];
	CGFloat duration			= [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	UIViewAnimationCurve curve	= [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[self setVisibleKeyboardHeight:0.0 animationDuration:duration animationOptions:curve << 16];
}

- (void) setVisibleKeyboardHeight:(CGFloat)visibleKeyboardHeight animationDuration:(NSTimeInterval)animationDuration animationOptions:(UIViewAnimationOptions)animationOptions {
	dispatch_block_t animationsBlock = ^{
		self.visibleKeyboardHeight = visibleKeyboardHeight;
	};
	
	if (animationDuration == 0.0) {
		animationsBlock();
	}
	else {
		[UIView animateWithDuration:animationDuration
							  delay:0.0
							options:animationOptions | UIViewAnimationOptionBeginFromCurrentState
						 animations:animationsBlock
						 completion:nil];
	}
}

- (void) setVisibleKeyboardHeight:(CGFloat)visibleKeyboardHeight {
	if (keyboardHeight != visibleKeyboardHeight) {
		keyboardHeight = visibleKeyboardHeight;
		
		[self updatePositionWithAnimated:NO];
	}
}


#pragma mark -

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_contentView = nil;
	_contentViewController = nil;
	self.startView = nil;
	
	tapGesture.delegate = nil;
	[self.view removeGestureRecognizer:tapGesture];
}

@end



#pragma mark - BlurEffect
#import <objc/runtime.h>

@interface UIBlurEffect (Protected)

@property (nonatomic, readonly) id effectSettings;

@end

@implementation BlurEffect

+ (instancetype) effectWithStyle:(UIBlurEffectStyle)style {
	id result = [super effectWithStyle:style];
	object_setClass(result, self);
	
	return result;
}

- (id) effectSettings {
	id settings = [super effectSettings];
	[settings setValue:@5 forKey:@"blurRadius"];
	return settings;
}

- (id) copyWithZone:(NSZone*)zone {
	id result = [super copyWithZone:zone];
	object_setClass(result, [self class]);
	return result;
}

@end
