# NKModalViewManager
`NKModalViewManager` allows you to present modal view controller easily and beautifully with animation.

![Demo Gif](Screenshots/demo1.gif)

## Installation

NKModalViewManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NKModalViewManager'
```


## Usage
```objc
#import "NKModalViewManager.h"

// Presenting
[[NKModalViewManager sharedInstance] presentModalViewController:myViewController animatedFromView:nil];

// Dismissing
[[NKModalViewManager sharedInstance] dismissViewController:myViewController animated:YES completion:nil];
```

## Examples

Example project provided in NKModalViewManagerExample folder.

## Requirements

* iOS 8+
* Objective-C or Swift, ARC
* Xcode 7 and iOS 8+ SDK
