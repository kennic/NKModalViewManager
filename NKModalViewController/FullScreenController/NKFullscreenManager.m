//
//  NKFullscreenManager.m
//  NKFullscreenManager
//
//  Created by Nam Kennic on 1/8/14.
//  Copyright (c) 2014 Nam Kennic. All rights reserved.
//

#import "NKFullscreenManager.h"


@implementation NKFullscreenManager
@synthesize topNKFullscreenViewController, fullscreenViewControllers;
static NKFullscreenManager *_instance;


+ (NKFullscreenManager*) sharedInstance {
	if (!_instance) _instance = [[NKFullscreenManager alloc] init];
	return _instance;
}

+ (void) clearInstance {
	if (_instance) {
		[_instance dismissAll];
		_instance = nil;
	}
}


#pragma mark - Initialization

- (id) init {
	if ((self = [super init])) {
		enableRemovingInstanceOnDismissEvent = YES;
		array = [NSMutableArray new];
	}
	
	return self;
}


#pragma mark -

- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController {
	return [self presentFullscreenViewController:viewController animatedFromView:nil];
}

- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView {
	return [self presentFullscreenViewController:viewController animatedFromView:startView withDelegate:nil onEnterFullscreen:nil onExitFullscreen:nil];
}

- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView enterBlock:(void (^)(NKFullscreenViewController *sender))enterBlock exitBlock:(void (^)(NKFullscreenViewController *sender))exitBlock {
	NKFullscreenViewController *fullscreenViewController = [[NKFullscreenViewController alloc] init];
	[array addObject:fullscreenViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS object:fullscreenViewController];
	
	fullscreenViewController.enterFullscreenBlock = enterBlock;
	fullscreenViewController.exitFullscreenBlock  = exitBlock;
	[fullscreenViewController presentFullscreenViewController:viewController animatedFromView:startView];
	
	return fullscreenViewController;
}

- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector {
	NKFullscreenViewController *fullscreenViewController = [[NKFullscreenViewController alloc] init];
	[array addObject:fullscreenViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS object:fullscreenViewController];
	
	[fullscreenViewController setDelegate:delegate onEnterFullscreen:onEnterFullscreenSelector onExitFullscreen:onExitFullscreenSelector];
	[fullscreenViewController presentFullscreenViewController:viewController animatedFromView:startView];
	
	return fullscreenViewController;
}



#pragma mark

- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view {
	return [self presentFullscreenView:view animatedFromView:nil];
}

- (NKFullscreenViewController*) presentFullscreenView:(UIView *)view animatedFromView:(UIView *)startView {
	return [self presentFullscreenView:view animatedFromView:startView withDelegate:nil onEnterFullscreen:nil onExitFullscreen:nil];
}

- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view animatedFromView:(UIView*)startView enterBlock:(void (^)(NKFullscreenViewController *sender))enterBlock exitBlock:(void (^)(NKFullscreenViewController *sender))exitBlock {
	NKFullscreenViewController *fullscreenViewController = [[NKFullscreenViewController alloc] init];
	[array addObject:fullscreenViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS object:fullscreenViewController];
	
	fullscreenViewController.enterFullscreenBlock = enterBlock;
	fullscreenViewController.exitFullscreenBlock  = exitBlock;
	[fullscreenViewController presentFullscreenView:view animatedFromView:startView];
	
	return fullscreenViewController;
}

- (NKFullscreenViewController*) presentFullscreenView:(UIView *)view animatedFromView:(UIView *)startView withDelegate:(id)delegate onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector {
	NKFullscreenViewController *fullscreenViewController = [[NKFullscreenViewController alloc] init];
	[array addObject:fullscreenViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS object:fullscreenViewController];
	
	[fullscreenViewController setDelegate:delegate onEnterFullscreen:onEnterFullscreenSelector onExitFullscreen:onExitFullscreenSelector];
	[fullscreenViewController presentFullscreenView:view animatedFromView:startView];
	
	return fullscreenViewController;
}

#pragma mark -

- (NKFullscreenViewController*) fullscreenViewControllerThatContainsView:(UIView*)view {
	for (NKFullscreenViewController *fullscreenViewController in array) {
		if (fullscreenViewController.contentView==view) {
			return fullscreenViewController;
		}
	}
	
	return nil;
}

- (NKFullscreenViewController*) fullscreenViewControllerThatContainsViewController:(UIViewController *)viewController {
	for (NKFullscreenViewController *fullscreenViewController in array) {
		if (fullscreenViewController.contentViewController==viewController) {
			return fullscreenViewController;
		}
	}
	
	return nil;
}

#pragma mark -

- (void) dismissViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(NKFullscreenViewController *sender))completion {
	for (NKFullscreenViewController *fullscreenViewController in array) {
		if (fullscreenViewController.contentViewController==viewController) {
			[fullscreenViewController dismissViewAnimated:animated completion:completion];
			break;
		}
	}
}

- (void) dismissView:(UIView *)view animated:(BOOL)animated completion:(void (^)(NKFullscreenViewController *sender))completion {
	for (NKFullscreenViewController *fullscreenViewController in array) {
		if (fullscreenViewController.contentView==view) {
			[fullscreenViewController dismissViewAnimated:animated completion:completion];
			break;
		}
	}
}

- (void) dismissAll {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	enableRemovingInstanceOnDismissEvent = NO;
	
	for (NKFullscreenViewController *fullscreenViewController in array) {
		[fullscreenViewController dismissViewAnimated:NO completion:nil];
	}
	
	[array removeAllObjects];
	enableRemovingInstanceOnDismissEvent = YES;
	
	[self updateStatusBarPropertiesForCurrentKeyWindow];
}


#pragma mark -

- (void) updateStatusBarPropertiesForCurrentKeyWindow {
	UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
	UIViewController *rootViewController = keyWindow.rootViewController;
	
	if (rootViewController) {
		if ([rootViewController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) [rootViewController setNeedsStatusBarAppearanceUpdate];
	}
}


#pragma mark - Events

- (void) onDismissedNotification:(NSNotification*)notification {
	if (enableRemovingInstanceOnDismissEvent) {
		NKFullscreenViewController *fullscreenViewController = [notification object];
		if (fullscreenViewController) {
			[[NSNotificationCenter defaultCenter] removeObserver:fullscreenViewController];
			[array removeObject:fullscreenViewController];
		}
		
		[self updateStatusBarPropertiesForCurrentKeyWindow];
	}
}


#pragma mark - Properties

- (NSArray*) fullscreenViewControllers {
	return array;
}

- (NKFullscreenViewController*) topNKFullscreenViewController {
	return [array lastObject];
}


#pragma mark -

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[array removeAllObjects];
}

@end
