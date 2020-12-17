// UIKit+JumpCoreNetworking.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>

#ifndef _UIKIT_JumpCoreNETWORKING_
    #define _UIKIT_JumpCoreNETWORKING_

#if TARGET_OS_IOS
    #import "JumpCoreAutoPurgingImageCache.h"
    #import "JumpCoreImageDownloader.h"
    #import "JumpCoreNetworkActivityIndicatorManager.h"
    #import "UIRefreshControl+JumpCoreNetworking.h"
#endif

    #import "UIActivityIndicatorView+JumpCoreNetworking.h"
    #import "UIButton+JumpCoreNetworking.h"
    #import "UIImageView+JumpCoreNetworking.h"
    #import "UIProgressView+JumpCoreNetworking.h"
#endif /* _UIKIT_JumpCoreNETWORKING_ */
#endif
