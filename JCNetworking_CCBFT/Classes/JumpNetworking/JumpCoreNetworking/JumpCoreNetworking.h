// JumpCoreNetworking.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Availability.h>
#import <TargetConditionals.h>

#ifndef _JumpCoreNETWORKING_
    #define _JumpCoreNETWORKING_

    #import "JumpCoreURLRequestSerialization.h"
    #import "JumpCoreURLResponseSerialization.h"
    #import "JumpCoreSecurityPolicy.h"

#if !TARGET_OS_WATCH
    #import "JumpCoreNetworkReachabilityManager.h"
#endif

    #import "JumpCoreURLSessionManager.h"
    #import "JumpCoreHTTPSessionManager.h"

#endif /* _JumpCoreNETWORKING_ */
