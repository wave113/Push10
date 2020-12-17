// UIRefreshControl+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import "UIRefreshControl+JumpCoreNetworking.h"
#import <objc/runtime.h>

#if TARGET_OS_IOS

#import "JumpCoreURLSessionManager.h"

@interface JumpCoreRefreshControlNotificationObserver : NSObject
@property (readonly, nonatomic, weak) UIRefreshControl *refreshControl;
- (instancetype)initWithActivityRefreshControl:(UIRefreshControl *)refreshControl;

- (void)jc_setRefreshingWithStateOfTask:(NSURLSessionTask *)task;

@end

@implementation UIRefreshControl (JumpCoreNetworking)

- (JumpCoreRefreshControlNotificationObserver *)JumpCore_notificationObserver {
    JumpCoreRefreshControlNotificationObserver *notificationObserver = objc_getAssociatedObject(self, @selector(JumpCore_notificationObserver));
    if (notificationObserver == nil) {
        notificationObserver = [[JumpCoreRefreshControlNotificationObserver alloc] initWithActivityRefreshControl:self];
        objc_setAssociatedObject(self, @selector(JumpCore_notificationObserver), notificationObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return notificationObserver;
}

- (void)jc_setRefreshingWithStateOfTask:(NSURLSessionTask *)task {
    [[self JumpCore_notificationObserver] jc_setRefreshingWithStateOfTask:task];
}

@end

@implementation JumpCoreRefreshControlNotificationObserver

- (instancetype)initWithActivityRefreshControl:(UIRefreshControl *)refreshControl
{
    self = [super init];
    if (self) {
        _refreshControl = refreshControl;
    }
    return self;
}

- (void)jc_setRefreshingWithStateOfTask:(NSURLSessionTask *)task {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidResumeNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidSuspendNotification object:nil];
    [notificationCenter removeObserver:self name:JumpCoreNetworkingTaskDidCompleteNotification object:nil];

    if (task) {
        UIRefreshControl *refreshControl = self.refreshControl;
        if (task.state == NSURLSessionTaskStateRunning) {
            [refreshControl beginRefreshing];

            [notificationCenter addObserver:self selector:@selector(JumpCore_beginRefreshing) name:JumpCoreNetworkingTaskDidResumeNotification object:task];
            [notificationCenter addObserver:self selector:@selector(JumpCore_endRefreshing) name:JumpCoreNetworkingTaskDidCompleteNotification object:task];
            [notificationCenter addObserver:self selector:@selector(JumpCore_endRefreshing) name:JumpCoreNetworkingTaskDidSuspendNotification object:task];
        } else {
            [refreshControl endRefreshing];
        }
    }
}

#pragma mark -

- (void)JumpCore_beginRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
    });
}

- (void)JumpCore_endRefreshing {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
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
