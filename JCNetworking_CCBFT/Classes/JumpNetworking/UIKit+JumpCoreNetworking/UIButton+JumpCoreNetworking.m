// UIButton+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import "UIButton+JumpCoreNetworking.h"

#import <objc/runtime.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import "UIImageView+JumpCoreNetworking.h"
#import "JumpCoreImageDownloader.h"

@interface UIButton (_JumpCoreNetworking)
@end

@implementation UIButton (_JumpCoreNetworking)

#pragma mark -

static char JumpCoreImageDownloadReceiptNormal;
static char JumpCoreImageDownloadReceiptHighlighted;
static char JumpCoreImageDownloadReceiptSelected;
static char JumpCoreImageDownloadReceiptDisabled;

static const char * JumpCore_imageDownloadReceiptKeyForState(UIControlState state) {
    switch (state) {
        case UIControlStateHighlighted:
            return &JumpCoreImageDownloadReceiptHighlighted;
        case UIControlStateSelected:
            return &JumpCoreImageDownloadReceiptSelected;
        case UIControlStateDisabled:
            return &JumpCoreImageDownloadReceiptDisabled;
        case UIControlStateNormal:
        default:
            return &JumpCoreImageDownloadReceiptNormal;
    }
}

- (JumpCoreImageDownloadReceipt *)JumpCore_imageDownloadReceiptForState:(UIControlState)state {
    return (JumpCoreImageDownloadReceipt *)objc_getAssociatedObject(self, JumpCore_imageDownloadReceiptKeyForState(state));
}

- (void)JumpCore_setImageDownloadReceipt:(JumpCoreImageDownloadReceipt *)imageDownloadReceipt
                           forState:(UIControlState)state
{
    objc_setAssociatedObject(self, JumpCore_imageDownloadReceiptKeyForState(state), imageDownloadReceipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

static char JumpCoreBackgroundImageDownloadReceiptNormal;
static char JumpCoreBackgroundImageDownloadReceiptHighlighted;
static char JumpCoreBackgroundImageDownloadReceiptSelected;
static char JumpCoreBackgroundImageDownloadReceiptDisabled;

static const char * JumpCore_backgroundImageDownloadReceiptKeyForState(UIControlState state) {
    switch (state) {
        case UIControlStateHighlighted:
            return &JumpCoreBackgroundImageDownloadReceiptHighlighted;
        case UIControlStateSelected:
            return &JumpCoreBackgroundImageDownloadReceiptSelected;
        case UIControlStateDisabled:
            return &JumpCoreBackgroundImageDownloadReceiptDisabled;
        case UIControlStateNormal:
        default:
            return &JumpCoreBackgroundImageDownloadReceiptNormal;
    }
}

- (JumpCoreImageDownloadReceipt *)JumpCore_backgroundImageDownloadReceiptForState:(UIControlState)state {
    return (JumpCoreImageDownloadReceipt *)objc_getAssociatedObject(self, JumpCore_backgroundImageDownloadReceiptKeyForState(state));
}

- (void)JumpCore_setBackgroundImageDownloadReceipt:(JumpCoreImageDownloadReceipt *)imageDownloadReceipt
                                     forState:(UIControlState)state
{
    objc_setAssociatedObject(self, JumpCore_backgroundImageDownloadReceiptKeyForState(state), imageDownloadReceipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation UIButton (JumpCoreNetworking)

+ (JumpCoreImageDownloader *)jc_sharedImageDownloader {

    return objc_getAssociatedObject(self, @selector(jc_sharedImageDownloader)) ?: [JumpCoreImageDownloader defaultInstance];
}

+ (void)jc_setsharedImageDownloader:(JumpCoreImageDownloader *)imageDownloader {
    objc_setAssociatedObject(self, @selector(jc_sharedImageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)jc_setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
{
    [self jc_setImageForState:state withURL:url placeholderImage:nil];
}

- (void)jc_setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self jc_setImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)jc_setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(nullable UIImage *)placeholderImage
                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
{
    if ([self jc_jc_isActiveTaskURLEqualToURLRequest:urlRequest forState:state]) {
        return;
    }

    [self jc_cancelImageDownloadTaskForState:state];

    JumpCoreImageDownloader *downloader = [[self class] jc_sharedImageDownloader];
    id <JumpCoreImageRequestCache> imageCache = downloader.imageCache;

    //Use the image from the image cache if it exists
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) {
        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            [self setImage:cachedImage forState:state];
        }
        [self JumpCore_setImageDownloadReceipt:nil forState:state];
    } else {
        if (placeholderImage) {
            [self setImage:placeholderImage forState:state];
        }

        __weak __typeof(self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        JumpCoreImageDownloadReceipt *receipt;
        receipt = [downloader
                   downloadImageForURLRequest:urlRequest
                   withReceiptID:downloadID
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf JumpCore_imageDownloadReceiptForState:state].receiptID isEqual:downloadID]) {
                           if (success) {
                               success(request, response, responseObject);
                           } else if(responseObject) {
                               [strongSelf setImage:responseObject forState:state];
                           }
                           [strongSelf JumpCore_setImageDownloadReceipt:nil forState:state];
                       }

                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf JumpCore_imageDownloadReceiptForState:state].receiptID isEqual:downloadID]) {
                           if (failure) {
                               failure(request, response, error);
                           }
                           [strongSelf  JumpCore_setImageDownloadReceipt:nil forState:state];
                       }
                   }];

        [self JumpCore_setImageDownloadReceipt:receipt forState:state];
    }
}

#pragma mark -

- (void)jc_setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
{
    [self jc_setBackgroundImageForState:state withURL:url placeholderImage:nil];
}

- (void)jc_setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self jc_setBackgroundImageForState:state withURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)jc_setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(nullable UIImage *)placeholderImage
                           success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                           failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
{
    if ([self jc_isActiveBackgroundTaskURLEqualToURLRequest:urlRequest forState:state]) {
        return;
    }

    [self jc_cancelBackgroundImageDownloadTaskForState:state];

    JumpCoreImageDownloader *downloader = [[self class] jc_sharedImageDownloader];
    id <JumpCoreImageRequestCache> imageCache = downloader.imageCache;

    //Use the image from the image cache if it exists
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) {
        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            [self setBackgroundImage:cachedImage forState:state];
        }
        [self JumpCore_setBackgroundImageDownloadReceipt:nil forState:state];
    } else {
        if (placeholderImage) {
            [self setBackgroundImage:placeholderImage forState:state];
        }

        __weak __typeof(self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        JumpCoreImageDownloadReceipt *receipt;
        receipt = [downloader
                   downloadImageForURLRequest:urlRequest
                   withReceiptID:downloadID
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf JumpCore_backgroundImageDownloadReceiptForState:state].receiptID isEqual:downloadID]) {
                           if (success) {
                               success(request, response, responseObject);
                           } else if(responseObject) {
                               [strongSelf setBackgroundImage:responseObject forState:state];
                           }
                           [strongSelf JumpCore_setBackgroundImageDownloadReceipt:nil forState:state];
                       }

                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([[strongSelf JumpCore_backgroundImageDownloadReceiptForState:state].receiptID isEqual:downloadID]) {
                           if (failure) {
                               failure(request, response, error);
                           }
                           [strongSelf  JumpCore_setBackgroundImageDownloadReceipt:nil forState:state];
                       }
                   }];

        [self JumpCore_setBackgroundImageDownloadReceipt:receipt forState:state];
    }
}

#pragma mark -

- (void)jc_cancelImageDownloadTaskForState:(UIControlState)state {
    JumpCoreImageDownloadReceipt *receipt = [self JumpCore_imageDownloadReceiptForState:state];
    if (receipt != nil) {
        [[self.class jc_sharedImageDownloader] cancelTaskForImageDownloadReceipt:receipt];
        [self JumpCore_setImageDownloadReceipt:nil forState:state];
    }
}

- (void)jc_cancelBackgroundImageDownloadTaskForState:(UIControlState)state {
    JumpCoreImageDownloadReceipt *receipt = [self JumpCore_backgroundImageDownloadReceiptForState:state];
    if (receipt != nil) {
        [[self.class jc_sharedImageDownloader] cancelTaskForImageDownloadReceipt:receipt];
        [self JumpCore_setBackgroundImageDownloadReceipt:nil forState:state];
    }
}

- (BOOL)jc_jc_isActiveTaskURLEqualToURLRequest:(NSURLRequest *)urlRequest forState:(UIControlState)state {
    JumpCoreImageDownloadReceipt *receipt = [self JumpCore_imageDownloadReceiptForState:state];
    return [receipt.task.originalRequest.URL.absoluteString isEqualToString:urlRequest.URL.absoluteString];
}

- (BOOL)jc_isActiveBackgroundTaskURLEqualToURLRequest:(NSURLRequest *)urlRequest forState:(UIControlState)state {
    JumpCoreImageDownloadReceipt *receipt = [self JumpCore_backgroundImageDownloadReceiptForState:state];
    return [receipt.task.originalRequest.URL.absoluteString isEqualToString:urlRequest.URL.absoluteString];
}


@end

#endif
