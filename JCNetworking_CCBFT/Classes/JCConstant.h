//
//  JCConstant.h
//  JCNetworking
//
//  Created by 繁小繁 on 2020/8/12.
//  Copyright © 2020 ccbft. All rights reserved.
//

#ifndef JCConstant_h
#define JCConstant_h

#ifdef DEBUG
#define AppLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define AppLog(s, ... )
#endif


#endif /* JCConstant_h */
