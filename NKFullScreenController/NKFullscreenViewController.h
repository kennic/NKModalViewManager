//
//  NKFullscreenViewController.h
//  NKFullscreenViewController
//
//  Created by Nam Kennic on 10/8/13.
//  Copyright (c) 2013 Nam Kennic. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const FULLSCREEN_VIEW_CONTROLLER_WILL_PRESENT;
extern NSString * const FULLSCREEN_VIEW_CONTROLLER_DID_PRESENT;
extern NSString * const FULLSCREEN_VIEW_CONTROLLER_WILL_DISMISS;
extern NSString * const FULLSCREEN_VIEW_CONTROLLER_DID_DISMISS;

@class NKFullscreenViewController;
@protocol NKFullscreenViewControllerProtocol <NSObject>

@optional
- (void) willEnterFullscreen:(NKFullscreenViewController*)sender;
- (void) didEnterFullscreen:(NKFullscreenViewController*)sender;
- (void) willExitFullscreen:(NKFullscreenViewController*)sender;
- (void) didExitFullscreen:(NKFullscreenViewController*)sender;

- (void) startFullscreenDragging:(NKFullscreenViewController*)sender; // on start dragging
- (void) endFullscreenDragging:(NKFullscreenViewController*)sender; // on touched up
- (void) endFullscreenDraggingAnimate:(NKFullscreenViewController*)sender; // when back to position on touched up if not dismissed

- (BOOL) enableDraggingToDismiss:(NKFullscreenViewController*)sender;
- (BOOL) enableExitButton:(NKFullscreenViewController*)sender;
- (NSString*) exitButtonTitle:(NKFullscreenViewController*)sender;

- (void) fullscreenViewController:(NKFullscreenViewController*)sender setPreviewImage:(UIImage*)image; // conformed classes should implement this method in order to show this preview image while loading actual image
- (UIImage*) imageForFullscreenPresentation:(NKFullscreenViewController*)sender;
- (CGSize) startInsetSizeForNKFullscreenViewControllerPresentation:(NKFullscreenViewController*)sender;
- (UIViewContentMode) contentModeForNKFullscreenViewControllerPresentation:(NKFullscreenViewController*)sender;

@end


#pragma mark -

@interface NKFullscreenViewController : UIViewController

@property (nonatomic, readonly) UIViewController	*contentViewController;
@property (nonatomic, readonly) UIView				*contentView;

@property (nonatomic, assign)	BOOL				shouldUseChildViewControllerForStatusBarVisual;

@property (nonatomic, copy) void (^enterFullscreenBlock)(NKFullscreenViewController *sender);
@property (nonatomic, copy) void (^exitFullscreenBlock)(NKFullscreenViewController *sender);

- (id) init;
- (void) setDelegate:(id)delegateTarget onEnterFullscreen:(SEL)onEnterFullscreenSelector onExitFullscreen:(SEL)onExitFullscreenSelector;
- (void) presentFullscreenViewController:(UIViewController*)sourceViewController;
- (void) presentFullscreenViewController:(UIViewController*)sourceViewController animatedFromView:(UIView*)fromView;
- (void) presentFullscreenView:(UIView*)sourceView;
- (void) presentFullscreenView:(UIView*)sourceView animatedFromView:(UIView*)fromView; // auto set targetView to main view
- (void) dismissViewAnimated:(BOOL)flag completion:(void (^)(void))completion; // completion does not related to exitFullscreen block

@end
