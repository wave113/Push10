// UIActivityIndicatorView+JumpCoreNetworking.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import <UIKit/UIKit.h>

/**
 This category adds methods to the UIKit framework's `UIActivityIndicatorView` class. The methods in this category provide support for automatically starting and stopping animation depending on the loading state of a session task.
 */
@interface UIActivityIndicatorView (JumpCoreNetworking)

///----------------------------------
/// @name Animating for Session Tasks
///----------------------------------

/**
 Binds the animating state to the state of the specified task.

 @param task The task. If `nil`, automatic updating from any previously specified operation will be disabled.
 */
- (void)jc_setAnimatingWithStateOfTask:(nullable NSURLSessionTask *)task;

@end

#endif
