//
//  UIViewController+NKModalViewManager.h
//  NKModalViewController
//
//  Created by Nam Kennic on 10/17/15.
//  Copyright © 2015 Nam Kennic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NKModalViewManager.h"

@interface UIViewController (NKModalViewManager)

- (nullable NKModalViewController*) presentingModalViewController; // return modal view controller that contains this view controller (self)

@end
