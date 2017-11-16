//
//  NKModalViewManager.m
//  NKModalViewManager
//
//  Created by Nam Kennic on 2/13/14.
//  Copyright (c) 2014 Nam Kennic. All rights reserved.
//

#import "NKModalViewManager.h"

@implementation NKModalViewManager {
	NSMutableArray<NKModalViewController*>	*array;
	BOOL								enableRemovingInstanceOnDismissEvent;
}

static NKModalViewManager *_instance;


+ (NKModalViewManager*) sharedInstance {
	if (!_instance) _instance = [[NKModalViewManager alloc] init];
	return _instance;
}

+ (void) releaseSharedInstance {
	if (_instance) {
		[_instance dismissAllWithAnimated:NO completion:nil];
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

- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController {
	return [self presentModalViewController:viewController animatedFromView:nil];
}

- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView {
	return [self presentModalViewController:viewController animatedFromView:startView withDelegate:nil onEnterModal:nil onExitModal:nil];
}

- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView enterBlock:(void (^)(NKModalViewController *sender))enterBlock exitBlock:(void (^)(NKModalViewController *sender))exitBlock {
	NKModalViewController *modalViewController = [[NKModalViewController alloc] init];
	[array addObject:modalViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:MODAL_VIEW_CONTROLLER_DID_DISMISS object:modalViewController];
	
	modalViewController.enterModalBlock = enterBlock;
	modalViewController.exitModalBlock  = exitBlock;
	[modalViewController presentModalViewController:viewController animatedFromView:startView];
	
	return modalViewController;
}

- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector {
	NKModalViewController *modalViewController = [[NKModalViewController alloc] init];
	[array addObject:modalViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:MODAL_VIEW_CONTROLLER_DID_DISMISS object:modalViewController];
	
	[modalViewController setDelegate:delegate onEnterModal:onEnterModalSelector onExitModal:onExitModalSelector];
	[modalViewController presentModalViewController:viewController animatedFromView:startView];
	
	return modalViewController;
}



#pragma mark

- (NKModalViewController*) presentModalView:(UIView*)view {
	return [self presentModalView:view animatedFromView:nil];
}

- (NKModalViewController*) presentModalView:(UIView *)view animatedFromView:(UIView *)startView {
	return [self presentModalView:view animatedFromView:startView withDelegate:nil onEnterModal:nil onExitModal:nil];
}

- (NKModalViewController*) presentModalView:(UIView*)view animatedFromView:(UIView*)startView enterBlock:(void (^)(NKModalViewController *sender))enterBlock exitBlock:(void (^)(NKModalViewController *sender))exitBlock {
	NKModalViewController *modalViewController = [[NKModalViewController alloc] init];
	[array addObject:modalViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:MODAL_VIEW_CONTROLLER_DID_DISMISS object:modalViewController];
	
	modalViewController.enterModalBlock = enterBlock;
	modalViewController.exitModalBlock  = exitBlock;
	[modalViewController presentModalView:view animatedFromView:startView];
	
	return modalViewController;
}

- (NKModalViewController*) presentModalView:(UIView *)view animatedFromView:(UIView *)startView withDelegate:(id)delegate onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector {
	NKModalViewController *modalViewController = [[NKModalViewController alloc] init];
	[array addObject:modalViewController];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDismissedNotification:) name:MODAL_VIEW_CONTROLLER_DID_DISMISS object:modalViewController];
	
	[modalViewController setDelegate:delegate onEnterModal:onEnterModalSelector onExitModal:onExitModalSelector];
	[modalViewController presentModalView:view animatedFromView:startView];
	
	return modalViewController;
}

#pragma mark -

- (NKModalViewController*) modalViewControllerThatContainsView:(UIView*)view {
	for (NKModalViewController *modalViewController in array) {
		if (modalViewController.contentView==view) {
			return modalViewController;
		}
	}
	
	return nil;
}

- (NKModalViewController*) modalViewControllerThatContainsViewController:(UIViewController *)viewController {
	for (NKModalViewController *modalViewController in array) {
		if (modalViewController.contentViewController==viewController || modalViewController.contentViewController==viewController.navigationController) {
			return modalViewController;
		}
	}
	
	return nil;
}

#pragma mark -

- (void) dismissViewController:(UIViewController*)viewController {
	[self dismissViewController:viewController animated:YES completion:nil];
}

- (void) dismissViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
	for (NKModalViewController *modalViewController in array) {
		if (modalViewController.contentViewController==viewController) {
			[modalViewController dismissWithAnimated:animated completion:completion];
			break;
		}
		else if (viewController.navigationController) {
			if (modalViewController.contentViewController==viewController.navigationController) {
				[modalViewController dismissWithAnimated:animated completion:completion];
				break;
			}
		}
	}
}

- (void) dismissView:(UIView *)view animated:(BOOL)animated completion:(void (^)(void))completion {
	for (NKModalViewController *modalViewController in array) {
		if (modalViewController.contentView==view) {
			[modalViewController dismissWithAnimated:animated completion:completion];
			break;
		}
	}
}

- (void) dismissAllWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
	enableRemovingInstanceOnDismissEvent = NO;
	
	if ([array count]>0) {
		NKModalViewController *lastOne = [array lastObject];
		for (NKModalViewController *modalViewController in array) {
			[modalViewController dismissWithAnimated:animated completion:^{
				if (modalViewController==lastOne) {
					[self updateStatusBarPropertiesForCurrentKeyWindow];
					if (completion) completion();
				}
			}];
		}
		
		[array removeAllObjects];
	}
	else {
		if (completion) completion();
	}
	
	enableRemovingInstanceOnDismissEvent = YES;
}

- (void) dismissTopModalViewControllerWithAnimated:(BOOL)animated completion:(void (^)(void))completion {
	[[self topModalViewController] dismissWithAnimated:animated completion:completion];
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
		NKModalViewController *modalViewController = [notification object];
		if (modalViewController) {
			[[NSNotificationCenter defaultCenter] removeObserver:modalViewController];
			[array removeObject:modalViewController];
		}
		
		[self updateStatusBarPropertiesForCurrentKeyWindow];
	}
}


#pragma mark - Properties

- (NSArray*) modalViewControllers {
	return array;
}

- (NKModalViewController*) topModalViewController {
	return [array lastObject];
}


#pragma mark -

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[array removeAllObjects];
}

@end
