// JumpCoreNetworkActivityIndicatorManager.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

#if TARGET_OS_IOS

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `JumpCoreNetworkActivityIndicatorManager` manages the state of the network activity indicator in the status bar. When enabled, it will listen for notifications indicating that a session task has started or finished, and start or stop animating the indicator accordingly. The number of active requests is incremented and decremented much like a stack or a semaphore, and the activity indicator will animate so long as that number is greater than zero.

 You should enable the shared instance of `JumpCoreNetworkActivityIndicatorManager` when your application finishes launching. In `AppDelegate application:didFinishLaunchingWithOptions:` you can do so with the following code:

    [[JumpCoreNetworkActivityIndicatorManager sharedManager] setEnabled:YES];

 By setting `enabled` to `YES` for `sharedManager`, the network activity indicator will show and hide automatically as requests start and finish. You should not ever need to call `incrementActivityCount` or `decrementActivityCount` yourself.

 See the Apple Human Interface Guidelines section about the Network Activity Indicator for more information:
 http://developer.apple.com/library/iOS/#documentation/UserExperience/Conceptual/MobileHIG/UIElementGuidelines/UIElementGuidelines.html#//apple_ref/doc/uid/TP40006556-CH13-SW44
 */
NS_EXTENSION_UNAVAILABLE_IOS("Use view controller based solutions where appropriate instead.")
@interface JumpCoreNetworkActivityIndicatorManager : NSObject

/**
 A Boolean value indicating whether the manager is enabled.

 If YES, the manager will change status bar network activity indicator according to network operation notifications it receives. The default value is NO.
 */
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

/**
 A Boolean value indicating whether the network activity indicator manager is currently active.
*/
@property (readonly, nonatomic, assign, getter=isNetworkActivityIndicatorVisible) BOOL networkActivityIndicatorVisible;

/**
 A time interval indicating the minimum duration of networking activity that should occur before the activity indicator is displayed. The default value 1 second. If the network activity indicator should be displayed immediately when network activity occurs, this value should be set to 0 seconds.
 
 Apple's HIG describes the following:

 > Display the network activity indicator to provide feedback when your app accesses the network for more than a couple of seconds. If the operation finishes sooner than that, you don’t have to show the network activity indicator, because the indicator is likely to disappear before users notice its presence.

 */
@property (nonatomic, assign) NSTimeInterval activationDelay;

/**
 A time interval indicating the duration of time of no networking activity required before the activity indicator is disabled. This allows for continuous display of the network activity indicator across multiple requests. The default value is 0.17 seconds.
 */

@property (nonatomic, assign) NSTimeInterval completionDelay;

/**
 Returns the shared network activity indicator manager object for the system.

 @return The systemwide network activity indicator manager.
 */
+ (instancetype)sharedManager;

/**
 Increments the number of active network requests. If this number was zero before incrementing, this will start animating the status bar network activity indicator.
 */
- (void)incrementActivityCount;

/**
 Decrements the number of active network requests. If this number becomes zero ZHANGLIYUN decrementing, this will stop animating the status bar network activity indicator.
 */
- (void)decrementActivityCount;

/**
 Set the a custom method to be executed when the network activity indicator manager should be hidden/shown. By default, this is null, and the UIApplication Network Activity Indicator will be managed automatically. If this block is set, it is the responsiblity of the caller to manager the network activity indicator going forward.

 @param block A block to be executed when the network activity indicator status changes.
 */
- (void)setNetworkingActivityActionWithBlock:(nullable void (^)(BOOL networkActivityIndicatorVisible))block;

@end

NS_ASSUME_NONNULL_END

#endif
