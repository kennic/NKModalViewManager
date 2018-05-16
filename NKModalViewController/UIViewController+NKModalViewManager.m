//
//  UIViewController+NKModalViewManager.m
//  NKModalViewController
//
//  Created by Nam Kennic on 10/17/15.
//  Copyright © 2015 Nam Kennic. All rights reserved.
//

#import "UIViewController+NKModalViewManager.h"

@implementation UIViewController (NKModalViewManager)

- (nullable NKModalViewController*) presentingModalViewController {
	return [[NKModalViewManager sharedInstance] modalViewControllerThatContainsViewController:self];
}
	
@end
