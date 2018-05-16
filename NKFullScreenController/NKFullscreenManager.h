//
//  NKFullscreenManager.h
//  NKFullscreenManager
//
//  Created by Nam Kennic on 1/8/14.
//  Copyright (c) 2014 Nam Kennic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKFullscreenViewController.h"

@interface NKFullscreenManager : NSObject {
	NSMutableArray *array;
	BOOL			enableRemovingInstanceOnDismissEvent;
}

@property (nonatomic, readonly) NKFullscreenViewController	*topNKFullscreenViewController;
@property (nonatomic, readonly) NSArray						*fullscreenViewControllers;

+ (NKFullscreenManager*) sharedInstance;
+ (void) clearInstance;

- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController;
- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView;
- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView enterBlock:(void (^)(NKFullscreenViewController *sender))enterBlock exitBlock:(void (^)(NKFullscreenViewController *sender))exitBlock;
- (NKFullscreenViewController*) presentFullscreenViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector;

- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view;
- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view animatedFromView:(UIView*)startView;
- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view animatedFromView:(UIView*)startView enterBlock:(void (^)(NKFullscreenViewController *sender))enterBlock exitBlock:(void (^)(NKFullscreenViewController *sender))exitBlock;
- (NKFullscreenViewController*) presentFullscreenView:(UIView*)view animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector;

- (NKFullscreenViewController*) fullscreenViewControllerThatContainsView:(UIView*)view;
- (NKFullscreenViewController*) fullscreenViewControllerThatContainsViewController:(UIViewController*)viewController;

- (void) dismissViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(NKFullscreenViewController *sender))completion;
- (void) dismissView:(UIView *)view animated:(BOOL)animated completion:(void (^)(NKFullscreenViewController *sender))completion;
- (void) dismissAll;

@end
