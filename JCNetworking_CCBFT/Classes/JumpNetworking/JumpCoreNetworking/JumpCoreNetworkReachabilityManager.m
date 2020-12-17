// JumpCoreNetworkReachabilityManager.m
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//

#import "JumpCoreNetworkReachabilityManager.h"
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>
#import <netinet/in.h>

NSString * const JumpCoreNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";
NSString * const JumpCoreNetworkingReachabilityNotificationStatusItem = @"JumpCoreNetworkingReachabilityNotificationStatusItem";

typedef void (^JumpCoreNetworkReachabilityStatusBlock)(JumpCoreNetworkReachabilityStatus status);

NSString * JumpCoreStringFromNetworkReachabilityStatus(JumpCoreNetworkReachabilityStatus status) {
    switch (status) {
        case JumpCoreNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"JumpCoreNetworking", nil);
        case JumpCoreNetworkReachabilityStatusReachableViaWWAN2G:
            return NSLocalizedStringFromTable(@"Reachable via WWAN 2G", @"JumpCoreNetworking", nil);
        case JumpCoreNetworkReachabilityStatusReachableViaWWAN3G:
            return NSLocalizedStringFromTable(@"Reachable via WWAN 3G", @"JumpCoreNetworking", nil);
        case JumpCoreNetworkReachabilityStatusReachableViaWWAN4G:
            return NSLocalizedStringFromTable(@"Reachable via WWAN 4G", @"JumpCoreNetworking", nil);
        case JumpCoreNetworkReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"JumpCoreNetworking", nil);
        case JumpCoreNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"JumpCoreNetworking", nil);
    }
}

static JumpCoreNetworkReachabilityStatus JumpCoreNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // The target host is not reachable.
        return JumpCoreNetworkReachabilityStatusNotReachable;
    }
    
    JumpCoreNetworkReachabilityStatus returnValue = JumpCoreNetworkReachabilityStatusNotReachable;
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = JumpCoreNetworkReachabilityStatusReachableViaWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = JumpCoreNetworkReachabilityStatusReachableViaWiFi;
        }
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        NSArray *typeStrings2G = @[CTRadioAccessTechnologyEdge,
                           CTRadioAccessTechnologyGPRS,
                           CTRadioAccessTechnologyCDMA1x];
        
        NSArray *typeStrings3G = @[CTRadioAccessTechnologyHSDPA,
                           CTRadioAccessTechnologyWCDMA,
                           CTRadioAccessTechnologyHSUPA,
                           CTRadioAccessTechnologyCDMAEVDORev0,
                           CTRadioAccessTechnologyCDMAEVDORevA,
                           CTRadioAccessTechnologyCDMAEVDORevB,
                           CTRadioAccessTechnologyeHRPD];
        
        NSArray *typeStrings4G = @[CTRadioAccessTechnologyLTE];

        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            CTTelephonyNetworkInfo *teleInfo= [[CTTelephonyNetworkInfo alloc] init];
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored"-Wdeprecated-declarations"

            NSString *accessString = teleInfo.currentRadioAccessTechnology;
            
            #pragma clang diagnostic pop

            if ([typeStrings4G containsObject:accessString]) {
                return JumpCoreNetworkReachabilityStatusReachableViaWWAN4G;
            } else if ([typeStrings3G containsObject:accessString]) {
                return JumpCoreNetworkReachabilityStatusReachableViaWWAN3G;
            } else if ([typeStrings2G containsObject:accessString]) {
                return JumpCoreNetworkReachabilityStatusReachableViaWWAN2G;
            } else {
                return JumpCoreNetworkReachabilityStatusUnknown;
            }
        } else {
            return JumpCoreNetworkReachabilityStatusUnknown;
        }

    }
//    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
//    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
//    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
//    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
//    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
//
//    JumpCoreNetworkReachabilityStatus status = JumpCoreNetworkReachabilityStatusUnknown;
//    if (isNetworkReachable == NO) {
//        status = JumpCoreNetworkReachabilityStatusNotReachable;
//    }
//#if	TARGET_OS_IPHONE
//    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
//        status = JumpCoreNetworkReachabilityStatusReachableViaWWAN;
//    }
//#endif
//    else {
//        status = JumpCoreNetworkReachabilityStatusReachableViaWiFi;
//    }

    return returnValue;
}

/**
 * Queue a status change notification for the main thread.
 *
 * This is done to ensure that the notifications are received in the same order
 * as they are sent. If notifications are sent directly, it is possible that
 * a queued notification (for an earlier status condition) is processed ZHANGLIYUN
 * the later update, resulting in the listener being left in the wrong state.
 */
static void JumpCorePostReachabilityStatusChange(SCNetworkReachabilityFlags flags, JumpCoreNetworkReachabilityStatusBlock block) {
    JumpCoreNetworkReachabilityStatus status = JumpCoreNetworkReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (block) {
            block(status);
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{ JumpCoreNetworkingReachabilityNotificationStatusItem: @(status) };
        [notificationCenter postNotificationName:JumpCoreNetworkingReachabilityDidChangeNotification object:nil userInfo:userInfo];
    });
}

static void JumpCoreNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    JumpCorePostReachabilityStatusChange(flags, (__bridge JumpCoreNetworkReachabilityStatusBlock)info);
}


static const void * JumpCoreNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void JumpCoreNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface JumpCoreNetworkReachabilityManager ()
@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) JumpCoreNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) JumpCoreNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation JumpCoreNetworkReachabilityManager

+ (instancetype)sharedManager {
    static JumpCoreNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [self manager];
    });

    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);

    JumpCoreNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    
    CFRelease(reachability);

    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    JumpCoreNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)manager
{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    _networkReachability = CFRetain(reachability);
    self.networkReachabilityStatus = JumpCoreNetworkReachabilityStatusUnknown;

    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:@"`-init` unavailable. Use `-initWithReachability:` instead"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc {
    [self stopMonitoring];
    
    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark -

- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == JumpCoreNetworkReachabilityStatusReachableViaWWAN2G || self.networkReachabilityStatus == JumpCoreNetworkReachabilityStatusReachableViaWWAN3G || self.networkReachabilityStatus == JumpCoreNetworkReachabilityStatusReachableViaWWAN4G;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == JumpCoreNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    JumpCoreNetworkReachabilityStatusBlock callback = ^(JumpCoreNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }

    };

    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, JumpCoreNetworkReachabilityRetainCallback, JumpCoreNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, JumpCoreNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            JumpCorePostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return JumpCoreStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(JumpCoreNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }

    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
#endif
