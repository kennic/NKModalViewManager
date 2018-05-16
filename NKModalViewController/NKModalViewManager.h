//
//  NKModalViewManager.h
//  NKModalViewManager
//
//  Created by Nam Kennic on 2/13/14.
//  Copyright (c) 2014 Nam Kennic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NKModalViewController.h"

@interface NKModalViewManager : NSObject

@property (nonatomic, readonly) NKModalViewController			*topModalViewController;
@property (nonatomic, readonly) NSArray<NKModalViewController*>	*modalViewControllers;

+ (NKModalViewManager*) sharedInstance;
+ (void) releaseSharedInstance;

- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController;
- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView;
- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView enterBlock:(void (^)(NKModalViewController *sender))enterBlock exitBlock:(void (^)(NKModalViewController *sender))exitBlock;
- (NKModalViewController*) presentModalViewController:(UIViewController*)viewController animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector;

- (NKModalViewController*) presentModalView:(UIView*)view;
- (NKModalViewController*) presentModalView:(UIView*)view animatedFromView:(UIView*)startView;
- (NKModalViewController*) presentModalView:(UIView*)view animatedFromView:(UIView*)startView enterBlock:(void (^)(NKModalViewController *sender))enterBlock exitBlock:(void (^)(NKModalViewController *sender))exitBlock;
- (NKModalViewController*) presentModalView:(UIView*)view animatedFromView:(UIView*)startView withDelegate:(id)delegate onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector;

- (NKModalViewController*) modalViewControllerThatContainsView:(UIView*)view;
- (NKModalViewController*) modalViewControllerThatContainsViewController:(UIViewController*)viewController;

- (void) dismissViewController:(UIViewController*)viewController;
- (void) dismissViewController:(UIViewController*)viewController animated:(BOOL)animated completion:(void (^)(void))completion;
- (void) dismissView:(UIView*)view animated:(BOOL)animated completion:(void (^)(void))completion;
- (void) dismissAllWithAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void) dismissTopModalViewControllerWithAnimated:(BOOL)animated completion:(void (^)(void))completion;

@end
