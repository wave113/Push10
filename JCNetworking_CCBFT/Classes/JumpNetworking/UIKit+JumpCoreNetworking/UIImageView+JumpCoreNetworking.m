// UIImageView+JumpCoreNetworking.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import "UIImageView+JumpCoreNetworking.h"

#import <objc/runtime.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import "JumpCoreImageDownloader.h"

@interface UIImageView (_JumpCoreNetworking)
@property (readwrite, nonatomic, strong, setter = JumpCore_setActiveImageDownloadReceipt:) JumpCoreImageDownloadReceipt *JumpCore_activeImageDownloadReceipt;
@end

@implementation UIImageView (_JumpCoreNetworking)

- (JumpCoreImageDownloadReceipt *)JumpCore_activeImageDownloadReceipt {
    return (JumpCoreImageDownloadReceipt *)objc_getAssociatedObject(self, @selector(JumpCore_activeImageDownloadReceipt));
}

- (void)JumpCore_setActiveImageDownloadReceipt:(JumpCoreImageDownloadReceipt *)imageDownloadReceipt {
    objc_setAssociatedObject(self, @selector(JumpCore_activeImageDownloadReceipt), imageDownloadReceipt, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark -

@implementation UIImageView (JumpCoreNetworking)

+ (JumpCoreImageDownloader *)jc_sharedImageDownloader {
    return objc_getAssociatedObject(self, @selector(jc_sharedImageDownloader)) ?: [JumpCoreImageDownloader defaultInstance];
}

+ (void)jc_setsharedImageDownloader:(JumpCoreImageDownloader *)imageDownloader {
    objc_setAssociatedObject(self, @selector(jc_sharedImageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -

- (void)jc_setImageWithURL:(NSURL *)url {
    [self jc_setImageWithURL:url placeholderImage:nil];
}

- (void)jc_setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self jc_setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)jc_setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure
{
    
    if ([urlRequest URL] == nil) {
        self.image = placeholderImage;
        if (failure) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
            failure(urlRequest, nil, error);
        }
        return;
    }
    
    if ([self jc_jc_isActiveTaskURLEqualToURLRequest:urlRequest]){
        return;
    }
    
    [self jc_cancelImageDownloadTask];

    JumpCoreImageDownloader *downloader = [[self class] jc_sharedImageDownloader];
    id <JumpCoreImageRequestCache> imageCache = downloader.imageCache;

    //Use the image from the image cache if it exists
    UIImage *cachedImage = [imageCache imageforRequest:urlRequest withAdditionalIdentifier:nil];
    if (cachedImage) {
        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }
        [self jc_clearActiveDownloadInformation];
    } else {
        if (placeholderImage) {
            self.image = placeholderImage;
        }

        __weak __typeof(self)weakSelf = self;
        NSUUID *downloadID = [NSUUID UUID];
        JumpCoreImageDownloadReceipt *receipt;
        receipt = [downloader
                   downloadImageForURLRequest:urlRequest
                   withReceiptID:downloadID
                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                       if ([strongSelf.JumpCore_activeImageDownloadReceipt.receiptID isEqual:downloadID]) {
                           if (success) {
                               success(request, response, responseObject);
                           } else if(responseObject) {
                               strongSelf.image = responseObject;
                           }
                           [strongSelf jc_clearActiveDownloadInformation];
                       }

                   }
                   failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                       __strong __typeof(weakSelf)strongSelf = weakSelf;
                        if ([strongSelf.JumpCore_activeImageDownloadReceipt.receiptID isEqual:downloadID]) {
                            if (failure) {
                                failure(request, response, error);
                            }
                            [strongSelf jc_clearActiveDownloadInformation];
                        }
                   }];

        self.JumpCore_activeImageDownloadReceipt = receipt;
    }
}

- (void)jc_cancelImageDownloadTask {
    if (self.JumpCore_activeImageDownloadReceipt != nil) {
        [[self.class jc_sharedImageDownloader] cancelTaskForImageDownloadReceipt:self.JumpCore_activeImageDownloadReceipt];
        [self jc_clearActiveDownloadInformation];
     }
}

- (void)jc_clearActiveDownloadInformation {
    self.JumpCore_activeImageDownloadReceipt = nil;
}

- (BOOL)jc_jc_isActiveTaskURLEqualToURLRequest:(NSURLRequest *)urlRequest {
    return [self.JumpCore_activeImageDownloadReceipt.task.originalRequest.URL.absoluteString isEqualToString:urlRequest.URL.absoluteString];
}

@end

#endif
