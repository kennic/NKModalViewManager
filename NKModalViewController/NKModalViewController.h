//
//  NKModalViewController.h
//  NKModalViewController
//
//  Created by Nam Kennic on 1/21/16.
//  Copyright (c) 2016 Nam Kennic. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const MODAL_VIEW_CONTROLLER_WILL_PRESENT;
extern NSString * const MODAL_VIEW_CONTROLLER_DID_PRESENT;
extern NSString * const MODAL_VIEW_CONTROLLER_WILL_DISMISS;
extern NSString * const MODAL_VIEW_CONTROLLER_DID_DISMISS;

extern NSString * const MODAL_VIEW_CONTROLLER_SIZE_UPDATE_REQUESTED; // post this notification to update size (after setting size in preferredContentSize)

typedef NS_ENUM(NSInteger, NKModalPresentingStyle) {
	NKModalPresentingStyleFromBottom,
	NKModalPresentingStyleFromTop,
	NKModalPresentingStyleFromLeft,
	NKModalPresentingStyleFromRight,
	NKModalPresentingStyleZoomIn,
	NKModalPresentingStyleZoomOut,
};

typedef NS_ENUM(NSInteger, NKModalDismissingStyle) {
	NKModalDismissingStyleToBottom,
	NKModalDismissingStyleToTop,
	NKModalDismissingStyleToLeft,
	NKModalDismissingStyleToRight,
	NKModalDismissingStyleZoomIn,
	NKModalDismissingStyleZoomOut,
};

@class NKModalViewController;
@protocol NKModalViewControllerProtocol <NSObject>

@optional
- (void) willEnterModalViewController:(NKModalViewController*)sender;
- (void) didEnterModalViewController:(NKModalViewController*)sender;
- (void) willExitModalViewController:(NKModalViewController*)sender;
- (void) didExitModalViewController:(NKModalViewController*)sender;

- (BOOL) shouldTapOutsideToDismissModalViewController:(NKModalViewController*)modalViewController;
- (BOOL) shouldAllowDragToDismissForModalViewController:(NKModalViewController*)modalViewController;
- (BOOL) shouldAllowKeyboardShiftingForModalViewController:(NKModalViewController*)modalViewController;

- (NKModalPresentingStyle) presentingStyleForModalViewController:(NKModalViewController*)modalViewController;
- (NKModalDismissingStyle) dismissingStyleForModalViewController:(NKModalViewController*)modalViewController;

- (NSTimeInterval) animateDurationForModalViewController:(NKModalViewController*)modalViewController;
- (UIColor*) backgroundColorForModalViewController:(NKModalViewController*)modalViewController;
- (CGFloat) backgroundBlurryValueForModalViewController:(NKModalViewController*)modalViewController;
- (CGFloat) cornerRadiusValueForModalViewController:(NKModalViewController*)modalViewController;
- (UIView*) viewAtBottomOfModalViewController:(NKModalViewController*)modalViewController;
- (UIViewController*) viewControllerForPresentingModalViewController:(NKModalViewController*)modalViewController;

- (CGRect) presentRectForModalViewController:(NKModalViewController*)modalViewController;
- (CGRect) startRectForModalViewController:(NKModalViewController*)modalViewController; // target rect for start presenting, only used when animatedFromView is nil
- (CGRect) dismissRectForModalViewController:(NKModalViewController*)modalViewController; // target rect for dismissing, only used when animatedFromView is nil

- (void) startDraggingFromModalViewController:(NKModalViewController*)modalViewController;
- (void) endDraggingFromModalViewController:(NKModalViewController*)modalViewController;
- (void) didCancelDraggingFromModalViewController:(NKModalViewController*)modalViewController;

@end


#pragma mark -

@interface NKModalViewController : UIViewController <UIGestureRecognizerDelegate> {
	UITapGestureRecognizer	*tapGesture;
	NSInteger	keyboardHeight;
}

@property (nonatomic, readonly) UIViewController	*contentViewController;
@property (nonatomic, readonly) UIView				*contentView;
@property (nonatomic, strong) UIView				*startView;

@property (nonatomic, readonly) BOOL isPresenting;
@property (nonatomic, readonly) BOOL isDismissing;

@property (nonatomic, assign) BOOL	enableKeyboardShifting;
@property (nonatomic, assign) BOOL	tapOutsideToDismiss;
@property (nonatomic, assign) BOOL	enableDragToDismiss;
@property (nonatomic, assign) BOOL	shouldUseChildViewControllerForStatusBarVisual; // set to YES to migrate preferredStatusBarStyle & prefersStatusBarHidden & preferredStatusBarUpdateAnimation from UINavigationController to its visible viewController
@property (nonatomic, assign) NKModalPresentingStyle presentingStyle;
@property (nonatomic, assign) NKModalDismissingStyle dismissingStyle;

@property (nonatomic, assign) id	delegate;
@property (nonatomic, assign) SEL	onEnterModal;
@property (nonatomic, assign) SEL	onExitModal;

@property (nonatomic, copy) void (^enterModalBlock)(NKModalViewController *sender);
@property (nonatomic, copy) void (^exitModalBlock)(NKModalViewController *sender);

- (void) setDelegate:(id)delegateTarget onEnterModal:(SEL)onEnterModalSelector onExitModal:(SEL)onExitModalSelector;

- (void) presentModalViewController:(UIViewController*)sourceViewController;
- (void) presentModalViewController:(UIViewController*)sourceViewController animatedFromView:(UIView*)fromView;
- (void) presentModalView:(UIView*)sourceView;
- (void) presentModalView:(UIView*)sourceView animatedFromView:(UIView*)fromView;

- (void) dismissWithAnimated:(BOOL)flag completion:(void (^)(void))completion;

- (void) setNeedsLayoutView; // call this when you made change to your modal view controller size (preferredContentSize)

@end


#pragma mark -

@interface BlurEffect : UIBlurEffect

@end

@interface NKContainerViewController : UIViewController

@property (nonatomic, assign) BOOL shouldUseChildViewControllerForStatusBarVisual;
@property (nonatomic, weak) UIViewController *contentViewController;

@end
