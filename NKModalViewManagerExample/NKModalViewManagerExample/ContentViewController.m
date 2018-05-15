//
//  ContentViewController.m
//  ModalViewManagerExample
//
//  Created by Nam Kennic on 3/14/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

#import "ContentViewController.h"

@implementation ContentViewController {
	UIImageView			*imageView;
	UIVisualEffectView	*effectView;
	UIButton			*closeButton;
	UIButton			*showButton;
	UILabel				*titleLabel;
	UITextField			*textField;
	UIWindow *window;
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
	if ([[NKModalViewManager sharedInstance] modalViewControllerThatContainsViewController:self]) {
		// if this view controller was presented by ModalViewManager
		[[NKModalViewManager sharedInstance] dismissViewController:self animated:flag completion:completion];
	}
	else {
		// if this was presented by standard method:
		// [self presentViewController:content animated:YES completion:nil];
		[super dismissViewControllerAnimated:flag completion:completion];
	}
}

#pragma mark -

- (void) viewDidLoad {
    [super viewDidLoad];
	
	self.view.clipsToBounds = YES;
	self.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
	
	imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:imageView];
	
	effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
	[self.view addSubview:effectView];
	
	titleLabel = [UILabel new];
	titleLabel.text = @"Test Dialog";
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:24];
	titleLabel.textColor = [UIColor blackColor];
	[self.view addSubview:titleLabel];
	
	textField = [UITextField new];
	textField.delegate = self;
	textField.returnKeyType = UIReturnKeyDone;
	textField.layer.cornerRadius = 5.0;
	textField.layer.borderWidth = 1.0;
	textField.layer.borderColor = [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor];
	textField.placeholder = @"Tap here to show the keyboard";
	textField.font = [UIFont fontWithName:@"Helvetica" size:16];
	[self.view addSubview:textField];
	
	showButton = [UIButton buttonWithType:UIButtonTypeCustom];
	showButton.titleLabel.font = [UIFont systemFontOfSize:14];
	[showButton setTitle:@"Present another" forState:UIControlStateNormal];
	[showButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[showButton setBackgroundColor:[UIColor colorWithRed:0.178 green:0.179 blue:0.177 alpha:0.898]];
	showButton.layer.cornerRadius = 5.0;
	showButton.showsTouchWhenHighlighted = YES;
	[showButton addTarget:self action:@selector(onButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:showButton];
	
	closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	closeButton.titleLabel.font = [UIFont systemFontOfSize:16];
	[closeButton setTitle:@"Close" forState:UIControlStateNormal];
	[closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[closeButton setBackgroundColor:[UIColor colorWithRed:0.178 green:0.179 blue:0.177 alpha:0.898]];
	closeButton.layer.cornerRadius = 5.0;
	closeButton.showsTouchWhenHighlighted = YES;
	[closeButton addTarget:self action:@selector(onButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:closeButton];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	effectView.frame = self.view.bounds;
	imageView.frame  = self.view.bounds;
	
	CGSize viewSize = self.view.bounds.size;
	CGSize buttonSize = CGSizeMake(120, 40);
	
	CGRect buttonFrame = CGRectMake(roundf(viewSize.width/2 - buttonSize.width/2), viewSize.height - buttonSize.height - 90, buttonSize.width, buttonSize.height);;
	showButton.frame = buttonFrame;
	
	buttonFrame.origin.y += buttonFrame.size.height + 10;
	closeButton.frame = buttonFrame;
	
	CGSize labelSize = [titleLabel sizeThatFits:viewSize];
	titleLabel.frame = CGRectMake(roundf(viewSize.width/2 - labelSize.width/2), 10, labelSize.width, labelSize.height);
	
	textField.frame = CGRectMake(20, 80, viewSize.width - 40, 40);
}

- (CGSize) preferredContentSize {
	// when you make this size changed on-the-fly, call [self.presentingModalViewController setNeedsLayoutView] to update it
	return CGSizeMake(360, 300); // return CGSizeZero for fullScreen
}


// Uncomment these lines to show how it react to orientation changed
 
- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden {
	return NO;
}

- (BOOL) shouldAutorotate {
	return YES;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
	return UIInterfaceOrientationLandscapeLeft;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskLandscapeLeft;
}



#pragma mark - Events

- (void) onButtonSelected:(UIButton*)sender {
	if (sender==closeButton) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else if (sender==showButton) {
		ContentViewController *viewController = [ContentViewController new];
		[[NKModalViewManager sharedInstance] presentModalViewController:viewController animatedFromView:sender];
	}
}


#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender {
	[sender resignFirstResponder]; // dismiss keyboard when user press Done
	return YES;
}


#pragma mark - ModalViewControllerProtocol
	
- (CGFloat) backgroundBlurryValueForModalViewController:(NKModalViewController *)modalViewController {
	return 5.0;
}

- (UIView*) viewAtBottomOfModalViewController:(NKModalViewController *)modalViewController {
	UILabel *label = [UILabel new];
	label.text = @"Tap outside to dismiss";
	label.textColor = [UIColor whiteColor];
	return label;
}

- (NKModalPresentingStyle) presentingStyleForModalViewController:(NKModalViewController *)modalViewController {
	return NKModalPresentingStyleZoomIn;
}

- (NKModalDismissingStyle) dismissingStyleForModalViewController:(NKModalViewController *)modalViewController {
	return NKModalDismissingStyleZoomOut;
}

- (BOOL) shouldTapOutsideToDismissModalViewController:(NKModalViewController *)modalViewController {
	return YES;
}

- (BOOL) shouldAllowDragToDismissForModalViewController:(NKModalViewController *)modalViewController {
	return YES;
}

@end
