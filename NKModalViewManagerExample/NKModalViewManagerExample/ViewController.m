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

@interface ViewController ()

@end

@implementation ViewController {
	UIImageView *bgImageView;
	UIButton *button1;
	UIButton *button2;
}

#pragma mark -

- (void) viewDidLoad {
	[super viewDidLoad];
	
	bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
	bgImageView.contentMode = UIViewContentModeScaleAspectFill;
	[self.view addSubview:bgImageView];
	
	button1 = [self createButtonWithTitle:@"Animated from button"];
	button2 = [self createButtonWithTitle:@"Show from bottom"];
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	bgImageView.frame = self.view.bounds;
	
	CGSize viewSize = self.view.bounds.size;
	CGSize buttonSize = CGSizeMake(200, 40);
	
	CGRect buttonFrame = CGRectMake(roundf(viewSize.width/2 - buttonSize.width/2), viewSize.height - buttonSize.height - 100, buttonSize.width, buttonSize.height);;
	button1.frame = buttonFrame;
	
	buttonFrame.origin.y += buttonFrame.size.height + 20;
	button2.frame = buttonFrame;
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
		[[NKModalViewManager sharedInstance] presentModalViewController:contentViewController animatedFromView:sender].tapOutsideToDismiss = YES;
	}
	else if (sender==button2) {
		[[NKModalViewManager sharedInstance] presentModalViewController:contentViewController animatedFromView:nil].tapOutsideToDismiss = YES;
	}
}

@end
