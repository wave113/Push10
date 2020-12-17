#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JCConstant.h"
#import "JCNetworking.h"
#import "JumpCoreCompatibilityMacros.h"
#import "JumpCoreHTTPSessionManager.h"
#import "JumpCoreNetworking.h"
#import "JumpCoreNetworkReachabilityManager.h"
#import "JumpCoreSecurityPolicy.h"
#import "JumpCoreURLRequestSerialization.h"
#import "JumpCoreURLResponseSerialization.h"
#import "JumpCoreURLSessionManager.h"
#import "JumpCoreAutoPurgingImageCache.h"
#import "JumpCoreImageDownloader.h"
#import "JumpCoreNetworkActivityIndicatorManager.h"
#import "UIActivityIndicatorView+JumpCoreNetworking.h"
#import "UIButton+JumpCoreNetworking.h"
#import "UIImageView+JumpCoreNetworking.h"
#import "UIKit+JumpCoreNetworking.h"
#import "UIProgressView+JumpCoreNetworking.h"
#import "UIRefreshControl+JumpCoreNetworking.h"
#import "WKWebView+JumpCoreNetworking.h"

FOUNDATION_EXPORT double JCNetworking_CCBFTVersionNumber;
FOUNDATION_EXPORT const unsigned char JCNetworking_CCBFTVersionString[];

