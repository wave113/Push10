// WKWebView+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import "WKWebView+JumpCoreNetworking.h"

#import <objc/runtime.h>

#if TARGET_OS_IOS

#import "JumpCoreHTTPSessionManager.h"
#import "JumpCoreURLResponseSerialization.h"
#import "JumpCoreURLRequestSerialization.h"

@interface WKWebView (_JumpCoreNetworking)
@property (readwrite, nonatomic, strong, setter = JumpCore_setURLSessionTask:) NSURLSessionDataTask *JumpCore_URLSessionTask;
@end

@implementation WKWebView (_JumpCoreNetworking)

- (NSURLSessionDataTask *)JumpCore_URLSessionTask {
    return (NSURLSessionDataTask *)objc_getAssociatedObject(self, @selector(JumpCore_URLSessionTask));
}

- (void)JumpCore_setURLSessionTask:(NSURLSessionDataTask *)JumpCore_URLSessionTask {
    objc_setAssociatedObject(self, @selector(JumpCore_URLSessionTask), JumpCore_URLSessionTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation WKWebView (JumpCoreNetworking)

@dynamic jc_sessionManager;

- (JumpCoreHTTPSessionManager  *)jc_sessionManager {
    static JumpCoreHTTPSessionManager *_JumpCore_defaultHTTPSessionManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _JumpCore_defaultHTTPSessionManager = [[JumpCoreHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _JumpCore_defaultHTTPSessionManager.requestSerializer = [JumpCoreHTTPRequestSerializer serializer];
        _JumpCore_defaultHTTPSessionManager.responseSerializer = [JumpCoreHTTPResponseSerializer serializer];
    });

    return objc_getAssociatedObject(self, @selector(jc_sessionManager)) ?: _JumpCore_defaultHTTPSessionManager;
}

- (void)jc_setSessionManager:(JumpCoreHTTPSessionManager *)jc_sessionManager {
    objc_setAssociatedObject(self, @selector(jc_sessionManager), jc_sessionManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JumpCoreHTTPResponseSerializer <JumpCoreURLResponseSerialization> *)jc_responseSerializer {
    static JumpCoreHTTPResponseSerializer <JumpCoreURLResponseSerialization> *_JumpCore_defaultResponseSerializer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _JumpCore_defaultResponseSerializer = [JumpCoreHTTPResponseSerializer serializer];
    });

    return objc_getAssociatedObject(self, @selector(responseSerializer)) ?: _JumpCore_defaultResponseSerializer;
}

- (void)jc_setResponseSerializer:(JumpCoreHTTPResponseSerializer<JumpCoreURLResponseSerialization> *)jc_responseSerializer {
    objc_setAssociatedObject(self, @selector(jc_responseSerializer), jc_responseSerializer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)jc_loadRequest:(NSURLRequest *)request
           progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
            success:(NSString * (^)(NSHTTPURLResponse *response, NSString *HTML))success
            failure:(void (^)(NSError *error))failure
{
    [self jc_loadRequest:request MIMEType:nil textEncodingName:nil progress:progress success:^NSData *(NSHTTPURLResponse *response, NSData *data) {
        NSStringEncoding stringEncoding = NSUTF8StringEncoding;
        if (response.textEncodingName) {
            CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)response.textEncodingName);
            if (encoding != kCFStringEncodingInvalidId) {
                stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
            }
        }

        NSString *string = [[NSString alloc] initWithData:data encoding:stringEncoding];
        if (success) {
            string = success(response, string);
        }

        return [string dataUsingEncoding:stringEncoding];
    } failure:failure];
}

- (void)jc_loadRequest:(NSURLRequest *)request
           MIMEType:(NSString *)MIMEType
   textEncodingName:(NSString *)textEncodingName
           progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress
            success:(NSData * (^)(NSHTTPURLResponse *response, NSData *data))success
            failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(request);

    if (self.JumpCore_URLSessionTask.state == NSURLSessionTaskStateRunning || self.JumpCore_URLSessionTask.state == NSURLSessionTaskStateSuspended) {
        [self.JumpCore_URLSessionTask cancel];
    }
    self.JumpCore_URLSessionTask = nil;

    __weak __typeof(self)weakSelf = self;
    __block NSURLSessionDataTask *dataTask;
    dataTask = [self.jc_sessionManager
                dataTaskWithRequest:request
                uploadProgress:nil
                downloadProgress:nil
                completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nullable error) {
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (error) {
                        if (failure) {
                            failure(error);
                        }
                    } else {
                        if (success) {
                            success((NSHTTPURLResponse *)response, responseObject);
                        }
                        [strongSelf loadData:responseObject MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:[dataTask.currentRequest URL]];
                        
                        if ([strongSelf.navigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
                            [strongSelf.navigationDelegate webView:self didFinishNavigation:nil];
                        }
                    }
                }];
    self.JumpCore_URLSessionTask = dataTask;
    if (progress != nil) {
        *progress = [self.jc_sessionManager downloadProgressForTask:dataTask];
    }
    [self.JumpCore_URLSessionTask resume];

    if ([self.navigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.navigationDelegate webView:self didStartProvisionalNavigation:nil];
    }
}

@end

#endif
