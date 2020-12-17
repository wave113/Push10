// UIActivityIndicatorView+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import "UIActivityIndicatorView+JumpCoreNetworking.h"
#import <objc/runtime.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import "JumpCoreURLSessionManager.h"

@interface JumpCoreActivityIndicatorViewNotificationObserver : NSObject
@property (readonly, nonatomic, weak) UIActivityIndicatorView *activityIndicatorView;
- (instancetype)initWithActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView;

- (void)jc_setAnimatingWithStateOfTask:(NSURLSessionTask *)task;

@end

@implementation UIActivityIndicatorView (JumpCoreNetworking)

- (JumpCoreActivityIndicatorViewNotificationObserver *)JumpCore_notificationObserver {
    JumpCoreActivityIndicatorViewNotificationObserver *notificationObserver = objc_getAssociatedObject(self, @selector(JumpCore_notificationObserver));
    if (notificationObserver == nil) {
        notificationObserver = [[JumpCoreActivityIndicatorViewNotificationObserver alloc] initWithActivityIndicatorView:self];
        objc_setAssociatedObject(self, @selector(JumpCore_notificationObserver), notificationObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return notificationObserver;
}

- (void)jc_setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    [[self JumpCore_notificationObserver] jc_setAnimatingWithStateOfTask:task];
}

@end

@implementation JumpCoreActivityIndicatorViewNotificationObserver

- (instancetype)initWithActivityIndicatorView:(UIActivityIndicatorView *)activityIndicatorView
{
    self = [super init];
    if (self) {
        _activityIndicatorView = activityIndicatorView;
    }
    return self;
}

- (void)jc_setAnimatingWithStateOfTask:(NSURLSessionTask *)task {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidCompleteNotification object:nil];
    
    if (task) {
        if (task.state != NSURLSessionTaskStateCompleted) {
            UIActivityIndicatorView *activityIndicatorView = self.activityIndicatorView;
            if (task.state == NSURLSessionTaskStateRunning) {
                [activityIndicatorView startAnimating];
            } else {
                [activityIndicatorView stopAnimating];
            }

            [notificationCenter addObserver:self selector:@selector(JumpCore_startAnimating) name:JumpCoreNetworkingTaskDidResumeNotification object:task];
            [notificationCenter addObserver:self selector:@selector(JumpCore_stopAnimating) name:JumpCoreNetworkingTaskDidCompleteNotification object:task];
            [notificationCenter addObserver:self selector:@selector(JumpCore_stopAnimating) name:JumpCoreNetworkingTaskDidSuspendNotification object:task];
        }
    }
}

#pragma mark -

- (void)JumpCore_startAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView startAnimating];
    });
}

- (void)JumpCore_stopAnimating {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicatorView stopAnimating];
    });
}

#pragma mark -

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidCompleteNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidSuspendNotification object:nil];
}

@end

#endif
