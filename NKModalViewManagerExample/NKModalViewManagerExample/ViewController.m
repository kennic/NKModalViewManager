//
//  ViewController.m
//  ModalViewManagerExample
//
//  Created by Nam Kennic on 3/14/16.
//  Copyright © 2016 Nam Kennic. All rights reserved.
//

#import "ViewController.h"
#import "ContentViewController.h"
#import "NKModalViewManager.h"
#import "NKFullscreenManager.h"

@interface ViewController ()

@end

@implementation ViewController {
	UIImageView *bgImageView;
	UIButton *button1;
	UIButton *button2;
	UIButton *button3;
	UIButton *button4;
	ContentViewController *testViewController;
}

#pragma mark -

- (void) viewDidLoad {
	[super viewDidLoad];
	
	testViewController = [ContentViewController new];
	
	bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
	bgImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:bgImageView];
	[self.view addSubview:testViewController.view];
	
	button1 = [self createButtonWithTitle:@"Animated from button"];
	button2 = [self createButtonWithTitle:@"Present from center"];
	button3 = [self createButtonWithTitle:@"Present existing"];
	button4 = [self createButtonWithTitle:@"Present fullscreen"];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	bgImageView.frame = self.view.bounds;
	
	CGSize viewSize = self.view.bounds.size;
	CGSize buttonSize = CGSizeMake(200, 40);
	
	CGRect buttonFrame = CGRectMake(roundf(viewSize.width/2 - buttonSize.width/2), viewSize.height - buttonSize.height - 200, buttonSize.width, buttonSize.height);;
	button1.frame = buttonFrame;
	
	buttonFrame.origin.y += buttonFrame.size.height + 20;
	button2.frame = buttonFrame;
	
	buttonFrame.origin.y += buttonFrame.size.height + 20;
	button3.frame = buttonFrame;
	
	buttonFrame.origin.y += buttonFrame.size.height + 20;
	button4.frame = buttonFrame;
	
	if (testViewController.view.superview == self.view) {
		CGSize contentViewSize = [testViewController preferredContentSize];
		testViewController.view.frame = CGRectMake((viewSize.width - contentViewSize.width)/2, 30, contentViewSize.width, contentViewSize.height);
		[testViewController.view setNeedsLayout];
	}
}

- (BOOL) shouldAutorotate {
	return NO;
}


#pragma mark -

- (UIButton*) createButtonWithTitle:(NSString*)title {
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setTitle:title forState:UIControlStateNormal];
	[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[button setBackgroundColor:[UIColor colorWithRed:0.951 green:0.956 blue:0.945 alpha:0.898]];
	button.layer.cornerRadius = 5.0;
	button.showsTouchWhenHighlighted = YES;
	[button addTarget:self action:@selector(onButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
	return button;
}


#pragma mark -

- (void) onButtonSelected:(UIButton*)sender {
	ContentViewController *contentViewController = [ContentViewController new];
	
	if (sender==button1) {
		[[NKModalViewManager sharedInstance] presentModalViewController:contentViewController animatedFromView:sender].enableDragToDismiss = YES;
	}
	else if (sender==button2) {
		[[NKModalViewManager sharedInstance] presentModalViewController:contentViewController animatedFromView:nil].enableDragToDismiss = YES;
	}
	else if (sender==button3) {
		[[NKModalViewManager sharedInstance] presentModalViewController:testViewController animatedFromView:nil].enableDragToDismiss = YES;
	}
	else if (sender==button4) {
		[[NKFullscreenManager sharedInstance] presentFullscreenViewController:testViewController animatedFromView:nil];
	}
}

@end
