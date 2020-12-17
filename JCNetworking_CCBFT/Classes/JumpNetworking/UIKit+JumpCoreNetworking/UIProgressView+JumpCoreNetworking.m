// UIProgressView+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//

#import "UIProgressView+JumpCoreNetworking.h"

#import <objc/runtime.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import "JumpCoreURLSessionManager.h"

static void * JumpCoreTaskCountOfBytesSentContext = &JumpCoreTaskCountOfBytesSentContext;
static void * JumpCoreTaskCountOfBytesReceivedContext = &JumpCoreTaskCountOfBytesReceivedContext;

#pragma mark -

@implementation UIProgressView (JumpCoreNetworking)

- (BOOL)JumpCore_uploadProgressAnimated {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(JumpCore_uploadProgressAnimated)) boolValue];
}

- (void)JumpCore_setUploadProgressAnimated:(BOOL)animated {
    objc_setAssociatedObject(self, @selector(JumpCore_uploadProgressAnimated), @(animated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)JumpCore_downloadProgressAnimated {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(JumpCore_downloadProgressAnimated)) boolValue];
}

- (void)JumpCore_setDownloadProgressAnimated:(BOOL)animated {
    objc_setAssociatedObject(self, @selector(JumpCore_downloadProgressAnimated), @(animated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)jc_setProgressWithUploadProgressOfTask:(NSURLSessionUploadTask *)task
                                   animated:(BOOL)animated
{
    if (task.state == NSURLSessionTaskStateCompleted) {
        return;
    }
    
    [task addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptions)0 context:JumpCoreTaskCountOfBytesSentContext];
    [task addObserver:self forKeyPath:@"countOfBytesSent" options:(NSKeyValueObservingOptions)0 context:JumpCoreTaskCountOfBytesSentContext];

    [self JumpCore_setUploadProgressAnimated:animated];
}

- (void)jc_setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task
                                     animated:(BOOL)animated
{
    if (task.state == NSURLSessionTaskStateCompleted) {
        return;
    }
    
    [task addObserver:self forKeyPath:@"state" options:(NSKeyValueObservingOptions)0 context:JumpCoreTaskCountOfBytesReceivedContext];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:(NSKeyValueObservingOptions)0 context:JumpCoreTaskCountOfBytesReceivedContext];

    [self JumpCore_setDownloadProgressAnimated:animated];
}

#pragma mark - NSKeyValueObserving

- (void)jc_observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(__unused NSDictionary *)change
                       context:(void *)context
{
    if (context == JumpCoreTaskCountOfBytesSentContext || context == JumpCoreTaskCountOfBytesReceivedContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesSent))]) {
            if ([object countOfBytesExpectedToSend] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesSent] / ([object countOfBytesExpectedToSend] * 1.0f) animated:self.JumpCore_uploadProgressAnimated];
                });
            }
        }

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
            if ([object countOfBytesExpectedToReceive] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesReceived] / ([object countOfBytesExpectedToReceive] * 1.0f) animated:self.JumpCore_downloadProgressAnimated];
                });
            }
        }

        if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
            if ([(NSURLSessionTask *)object state] == NSURLSessionTaskStateCompleted) {
                @try {
                    [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];

                    if (context == JumpCoreTaskCountOfBytesSentContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))];
                    }

                    if (context == JumpCoreTaskCountOfBytesReceivedContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))];
                    }
                }
                @catch (NSException * __unused exception) {}
            }
        }
    }
}

@end

#endif
