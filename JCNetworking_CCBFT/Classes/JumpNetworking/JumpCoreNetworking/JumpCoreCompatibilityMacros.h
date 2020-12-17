// JumpCoreCompatibilityMacros.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#ifndef JumpCoreCompatibilityMacros_h
#define JumpCoreCompatibilityMacros_h

#ifdef API_UNAVAILABLE
    #define JumpCore_API_UNAVAILABLE(x) API_UNAVAILABLE(x)
#else
    #define JumpCore_API_UNAVAILABLE(x)
#endif // API_UNAVAILABLE

#if __has_warning("-Wunguarded-availability-new")
    #define JumpCore_CAN_USE_AT_AVAILABLE 1
#else
    #define JumpCore_CAN_USE_AT_AVAILABLE 0
#endif

#endif /* JumpCoreCompatibilityMacros_h */
