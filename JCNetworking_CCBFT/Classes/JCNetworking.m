//
//  JCNetworking.m
//  StatisticReporter
//
//  Created by 繁小繁 on 2019/12/26.
//  Copyright © 2019 ccbft. All rights reserved.
//

#import "JCNetworking.h"
#import "JumpCoreNetworkActivityIndicatorManager.h"
#import "JumpCoreNetworking.h"
#import "JumpCoreHTTPSessionManager.h"

#import <CommonCrypto/CommonDigest.h>
#import "JumpCoreNetworkReachabilityManager.h"

@interface NSString (md5)

+ (NSString *)jc_networking_md5:(NSString *)string;

@end

@implementation NSString (md5)

+ (NSString *)jc_networking_md5:(NSString *)string {
  if (string == nil || [string length] == 0) {
    return nil;
  }
  
  unsigned char digest[CC_MD5_DIGEST_LENGTH], i;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

  CC_MD5([string UTF8String], (int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], digest);
#pragma clang diagnostic pop
    
  NSMutableString *ms = [NSMutableString string];
  
  for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [ms appendFormat:@"%02x", (int)(digest[i])];
  }
  
  return [ms copy];
}

@end

static NSString *sg_privateNetworkBaseUrl = nil;
static BOOL sg_isEnableInterfaceDebug = NO;
static BOOL sg_shouldAutoEncode = NO;
static NSDictionary *sg_httpHeaders = nil;
static ResponseType sg_responseType = kResponseTypeJSON;
static RequestType  sg_requestType  = kRequestTypeJSON;
static JCNetworkStatus sg_networkStatus = kNetworkStatusReachableViaWiFi;
static NSMutableArray *sg_requestTasks;
static BOOL sg_cacheGet = YES;
static BOOL sg_cachePost = NO;
static BOOL sg_shouldCallbackOnCancelRequest = YES;
static NSTimeInterval sg_timeout = 60.0f;
static BOOL sg_shoulObtainLocalWhenUnconnected = NO;
static BOOL sg_isBaseURLChanged = YES;
static JumpCoreHTTPSessionManager *sg_sharedManager = nil;
static NSUInteger sg_maxCacheSize = 0;

@implementation JCNetworking

+ (JumpCoreHTTPSessionManager *)shareAFNManager {
    static JumpCoreHTTPSessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [JumpCoreHTTPSessionManager manager];
    });
    
    return manager;
}

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // 尝试清除缓存
    if (sg_maxCacheSize > 0 && [self totalCacheSize] > 1024 * 1024 * sg_maxCacheSize) {
      [self clearCaches];
    }
  });
}

+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize {
  sg_maxCacheSize = mSize;
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost {
  sg_cacheGet = isCacheGet;
  sg_cachePost = shouldCachePost;
}

+ (void)updateBaseUrl:(NSString *)baseUrl {
  if (![baseUrl isEqualToString:sg_privateNetworkBaseUrl] && baseUrl && baseUrl.length) {
    sg_isBaseURLChanged = YES;
  } else {
    sg_isBaseURLChanged = NO;
  }
  
  sg_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
  return sg_privateNetworkBaseUrl;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
  sg_timeout = timeout;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain {
  sg_shoulObtainLocalWhenUnconnected = shouldObtain;
  if (sg_shoulObtainLocalWhenUnconnected && (sg_cacheGet || sg_cachePost)) {
    [self detectNetwork];
  }
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
  sg_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
  return sg_isEnableInterfaceDebug;
}

static inline NSString *cachePath() {
  return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
}

+ (void)clearCaches {
    NSString *directoryPath = cachePath();
  
    //拿到path路径的下一级目录的子文件夹
    NSArray *subPathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    
    NSString *filePath = nil;
    
    NSError *error = nil;
    
    for (NSString *subPath in subPathArr)
    {
        filePath = [directoryPath stringByAppendingPathComponent:subPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && [[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            //删除子文件夹
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"Networking clear caches error: %@", error);
            } else {
                NSLog(@"Networking clear caches ok");
            }
        }
    }
}

+ (void)clearCachesSuccess:(ActionSuccess)success fail:(ActionFail)fail {
    
    NSString *directoryPath = cachePath();
    
    //拿到path路径的下一级目录的子文件夹
    NSArray *subPathArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:nil];
    
    NSString *filePath = nil;
    
    NSError *error = nil;
    
    for (NSString *subPath in subPathArr)
    {
        filePath = [directoryPath stringByAppendingPathComponent:subPath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] && [[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            //删除子文件夹
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"Networking clear caches error: %@", error);
                if (fail) {
                    fail(error);
                }

            } else {
                NSLog(@"Networking clear caches ok");
                if (success) {
                    success();
                }
                
            }
        }
    }
}

+ (unsigned long long)totalCacheSize {
    NSString *directoryPath = cachePath();
    BOOL isDir = NO;
    unsigned long long total = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *error = nil;
            NSArray *array = [[NSFileManager defaultManager] subpathsAtPath:directoryPath];
            
            if (error == nil) {
                for (NSString *subpath in array) {
                    NSString *path = [directoryPath stringByAppendingPathComponent:subpath];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path] && [[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
                        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:path
                                                                                              error:&error];
                        if (!error) {
                            total += [dict fileSize]/1024.f;
                        }
                        
                    }
                }
            }
        }
    }
    
    return total;
}

+ (NSMutableArray *)allTasks {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (sg_requestTasks == nil) {
      sg_requestTasks = [[NSMutableArray alloc] init];
    }
  });
  
  return sg_requestTasks;
}

+ (void)cancelAllRequest {
  @synchronized(self) {
    [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
      if ([task isKindOfClass:[URLSessionTask class]]) {
        [task cancel];
      }
    }];
    
    [[self allTasks] removeAllObjects];
  };
    
}

+ (void)cancelRequestWithURL:(NSString *)url {
  if (url == nil) {
    return;
  }
  
  @synchronized(self) {
    [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
      if ([task isKindOfClass:[URLSessionTask class]]
          && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
        [task cancel];
        [[self allTasks] removeObject:task];
        return;
      }
    }];
  };
}

+ (void)cancelAllRequestWithExceptionURL:(NSString *)url {
    @synchronized(self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task isKindOfClass:[URLSessionTask class]] && ![task.currentRequest.URL.absoluteString containsString:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
            }
        }];
    };
}

+ (void)configRequestType:(RequestType)requestType
             responseType:(ResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
  sg_requestType = requestType;
  sg_responseType = responseType;
  sg_shouldAutoEncode = shouldAutoEncode;
  sg_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (BOOL)shouldEncode {
  return sg_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
  sg_httpHeaders = httpHeaders;
}

+ (URLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(ResponseSuccess)success
                             fail:(ResponseFail)fail {
  return [self getWithUrl:url
             refreshCache:refreshCache
                   params:nil
                  success:success
                     fail:fail];
}

+ (URLSessionTask *)getWithUrl:(NSString * __nullable)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary * __nullable)params
                          success:(ResponseSuccess __nullable)success
                             fail:(ResponseFail __nullable)fail {
  return [self getWithUrl:url
             refreshCache:refreshCache
                   params:params
                 progress:nil
                  success:success
                     fail:fail];
}

+ (URLSessionTask *)getWithUrl:(NSString * __nullable)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary * __nullable)params
                         progress:(GetProgress __nullable)progress
                          success:(ResponseSuccess __nullable)success
                             fail:(ResponseFail __nullable)fail {
  return [self _requestWithUrl:url
                  refreshCache:refreshCache
                     httpMedth:1
                        params:params
                       headers:nil
                      progress:progress
                       success:success
                          fail:fail];
}

+ (URLSessionTask *)getWithUrl:(NSString *)url
                  refreshCache:(BOOL)refreshCache
                       headers:(NSDictionary *)headers
                       success:(ResponseSuccess)success
                          fail:(ResponseFail)fail {
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:1
                          params:nil
                         headers:headers
                        progress:nil
                         success:success
                            fail:fail];

}

+ (URLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(ResponseSuccess)success
                              fail:(ResponseFail)fail {
  return [self postWithUrl:url
              refreshCache:refreshCache
                    params:params
                  progress:nil
                   success:success
                      fail:fail];
}

+ (URLSessionTask *)postWithUrl:(NSString * __nullable)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary * __nullable)params
                          progress:(PostProgress __nullable)progress
                           success:(ResponseSuccess __nullable)success
                              fail:(ResponseFail __nullable)fail {
  return [self _requestWithUrl:url
                  refreshCache:refreshCache
                     httpMedth:2
                        params:params
                       headers:nil
                      progress:progress
                       success:success
                          fail:fail];
}

+ (URLSessionTask *)postWithUrl:(NSString *)url
                   refreshCache:(BOOL)refreshCache
                         params:(NSDictionary *)params
                        headers:(NSDictionary *)headers
                        success:(ResponseSuccess)success
                           fail:(ResponseFail)fail{
    
    return [self _requestWithUrl:url
                    refreshCache:refreshCache
                       httpMedth:2
                          params:params
                         headers:headers
                        progress:nil
                         success:success
                            fail:fail];
}

+ (URLSessionTask *)_requestWithUrl:(NSString *)url
                          refreshCache:(BOOL)refreshCache
                             httpMedth:(NSUInteger)httpMethod
                                params:(NSDictionary *)params
                               headers:(NSDictionary *)headers
                              progress:(DownloadProgress)progress
                               success:(ResponseSuccess)success
                                  fail:(ResponseFail)fail {
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }

  JumpCoreHTTPSessionManager *manager = [self manager];
        
  NSString *absolute = [self absoluteUrlWithPath:url];
  
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    NSURL *absoluteURL = [NSURL URLWithString:absolute];
    
    if (absoluteURL == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
    
    if (headers) {
        [manager.requestSerializer setValue:[headers valueForKey:@"value"] forHTTPHeaderField:[headers valueForKey:@"name"]];
    }
    
  URLSessionTask *session = nil;
  
  if (httpMethod == 1) {
    if (sg_cacheGet) {
      if (sg_shoulObtainLocalWhenUnconnected) {
        if (sg_networkStatus == kNetworkStatusNotReachable ||  sg_networkStatus == kNetworkStatusUnknown ) {
          id response = [JCNetworking cahceResponseWithURL:absolute
                                                 parameters:params];
          if (response) {
            if (success) {
              [self successResponse:response callback:success];
              
              if ([self isDebug]) {
                [self logWithSuccessResponse:response
                                         url:absolute
                                      params:params];
              }
            }
            return nil;
          }
        }
      }
      if (!refreshCache) {// 获取缓存
        id response = [JCNetworking cahceResponseWithURL:absolute
                                               parameters:params];
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
          return nil;
        }
      }
    }
    
    session = [manager GET:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if (sg_cacheGet) {
        [self cacheResponseObject:responseObject request:task.currentRequest parameters:params];
      }
      
      [[self allTasks] removeObject:task];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:absolute
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      [[self allTasks] removeObject:task];
        if (!refreshCache) {
            id response = [JCNetworking cahceResponseWithURL:absolute
                                                parameters:params];
            if (response) {
                if (success) {
                    [self successResponse:response callback:success];
                    
                    if ([self isDebug]) {
                        [self logWithSuccessResponse:response
                                                 url:absolute
                                              params:params];
                    }
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:params];
                }
            }
            
        }

//      if ([error code] < 0 && sg_cacheGet) {// 获取缓存
//        id response = [Networking cahceResponseWithURL:absolute
//                                               parameters:params];
//        if (response) {
//          if (success) {
//            [self successResponse:response callback:success];
//
//            if ([self isDebug]) {
//              [self logWithSuccessResponse:response
//                                       url:absolute
//                                    params:params];
//            }
//          }
//        } else {
//          [self handleCallbackWithError:error fail:fail];
//
//          if ([self isDebug]) {
//            [self logWithFailError:error url:absolute params:params];
//          }
//        }
//      } else {
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
          [self logWithFailError:error url:absolute params:params];
        }
//      }
    }];
  } else if (httpMethod == 2) {
    if (sg_cachePost ) {// 获取缓存
      if (sg_shoulObtainLocalWhenUnconnected) {
        if (sg_networkStatus == kNetworkStatusNotReachable ||  sg_networkStatus == kNetworkStatusUnknown ) {
          id response = [JCNetworking cahceResponseWithURL:absolute
                                                 parameters:params];
          if (response) {
            if (success) {
              [self successResponse:response callback:success];
              
              if ([self isDebug]) {
                [self logWithSuccessResponse:response
                                         url:absolute
                                      params:params];
              }
            }
            return nil;
          }
        }
      }
      if (!refreshCache) {
        id response = [JCNetworking cahceResponseWithURL:absolute
                                               parameters:params];
        if (response) {
          if (success) {
            [self successResponse:response callback:success];
            
            if ([self isDebug]) {
              [self logWithSuccessResponse:response
                                       url:absolute
                                    params:params];
            }
          }
          return nil;
        }
      }
    }
    
    session = [manager POST:absolute parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
      if (progress) {
        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
      }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self successResponse:responseObject callback:success];
      
      if (sg_cachePost) {
        [self cacheResponseObject:responseObject request:task.currentRequest  parameters:params];
      }
      
      [[self allTasks] removeObject:task];
      
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:absolute
                              params:params];
      }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
      [[self allTasks] removeObject:task];
      
//      if ([error code] < 0 && sg_cachePost) {// 获取缓存
//        id response = [Networking cahceResponseWithURL:absolute
//                                               parameters:params];
//
//        if (response) {
//          if (success) {
//            [self successResponse:response callback:success];
//
//            if ([self isDebug]) {
//              [self logWithSuccessResponse:response
//                                       url:absolute
//                                    params:params];
//            }
//          }
//        } else {
//          [self handleCallbackWithError:error fail:fail];
//
//          if ([self isDebug]) {
//            [self logWithFailError:error url:absolute params:params];
//          }
//        }
//      } else {
        [self handleCallbackWithError:error fail:fail];
        
        if ([self isDebug]) {
          [self logWithFailError:error url:absolute params:params];
        }
//      }
    }];
  }
  
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (URLSessionTask *)getCacheWithUrl:(NSString *)url
                            success:(ResponseSuccess)success
                               fail:(ResponseFail)fail {
    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    if ([self baseUrl] == nil) {
        if ([NSURL URLWithString:url] == nil) {
            AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    } else {
        NSURL *absoluteURL = [NSURL URLWithString:absolute];
        
        if (absoluteURL == nil) {
            AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
            return nil;
        }
    }
    
    URLSessionTask *session = nil;
    NSError * error = nil;
    if (sg_cacheGet) {
        id response = [JCNetworking cahceResponseWithURL:absolute
                                            parameters:nil];
        if (response) {
            if (success) {
                [self successResponse:response callback:success];
                
                if ([self isDebug]) {
                    [self logWithSuccessResponse:response
                                             url:absolute
                                          params:nil];
                }
            } else {
                [self handleCallbackWithError:error fail:fail];
                
                if ([self isDebug]) {
                    [self logWithFailError:error url:absolute params:nil];
                }
                
            }
            return nil;
        } else {
            [self handleCallbackWithError:error fail:fail];
            
            if ([self isDebug]) {
                [self logWithFailError:error url:absolute params:nil];
            }
            return nil;
        }
    }

    return session;
}

+ (URLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(UploadProgress)progress
                                 success:(ResponseSuccess)success
                                    fail:(ResponseFail)fail {
  if ([NSURL URLWithString:uploadingFile] == nil) {
    AppLog(@"uploadingFile无效，无法生成URL。请检查待上传文件是否存在");
    return nil;
  }
  
  NSURL *uploadURL = nil;
  if ([self baseUrl] == nil) {
    uploadURL = [NSURL URLWithString:url];
  } else {
    uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
  }
  
  if (uploadURL == nil) {
    AppLog(@"URLString无效，无法生成URL。可能是URL中有中文或特殊字符，请尝试Encode URL");
    return nil;
  }
  
  JumpCoreHTTPSessionManager *manager = [self manager];
  NSURLRequest *request = [NSURLRequest requestWithURL:uploadURL];
  URLSessionTask *session = nil;
  
  [manager uploadTaskWithRequest:request fromFile:[NSURL URLWithString:uploadingFile] progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
    [[self allTasks] removeObject:session];
    
    [self successResponse:responseObject callback:success];
    
    if (error) {
      [self handleCallbackWithError:error fail:fail];
      
      if ([self isDebug]) {
        [self logWithFailError:error url:response.URL.absoluteString params:nil];
      }
    } else {
      if ([self isDebug]) {
        [self logWithSuccessResponse:responseObject
                                 url:response.URL.absoluteString
                              params:nil];
      }
    }
  }];
  
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (URLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(UploadProgress)progress
                               success:(ResponseSuccess)success
                                  fail:(ResponseFail)fail {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  NSString *absolute = [self absoluteUrlWithPath:url];
  
  JumpCoreHTTPSessionManager *manager = [self manager];
  URLSessionTask *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<JumpCoreMultipartFormData>  _Nonnull formData) {
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    
    NSString *imageFileName = filename;
    if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      NSString *str = [formatter stringFromDate:[NSDate date]];
      imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
    }
    
    // 上传图片，以文件流的格式
    [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:mimeType];
  } progress:^(NSProgress * _Nonnull uploadProgress) {
    if (progress) {
      progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
    }
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    [[self allTasks] removeObject:task];
    [self successResponse:responseObject callback:success];
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject
                               url:absolute
                            params:parameters];
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    [[self allTasks] removeObject:task];
    
    [self handleCallbackWithError:error fail:fail];
    
    if ([self isDebug]) {
      [self logWithFailError:error url:absolute params:nil];
    }
  }];
  
  [session resume];
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

+ (URLSessionTask *)uploadWithData:(NSData *)data
                               url:(NSString *)url
                          filename:(NSString *)fileName
                              name:(NSString *)name
                            header:(NSDictionary *)header
                          mimeType:(NSString *)mimeType
                        parameters:(NSDictionary *)parameters
                          progress:(UploadProgress)progress
                           success:(ResponseSuccess)success
                              fail:(ResponseFailWithCode)fail {
    if ([self baseUrl] == nil) {
      if ([NSURL URLWithString:url] == nil) {
        AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
        return nil;
      }
    } else {
      if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
        AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
        return nil;
      }
    }
    
    if ([self shouldEncode]) {
      url = [self encodeUrl:url];
    }
    
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    NSError *error = nil;

    NSMutableURLRequest *request = [[JumpCoreHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:url parameters:parameters constructingBodyWithBlock:^(id<JumpCoreMultipartFormData> formData) {
        [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
        
    } error:&error];
    
    if (error) {
        AppLog(@"JumpEngineMP upload file fail: %@", error);
        return nil;
    }
    
    // 设置header
    if (header) {
        [header enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString *  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    request.HTTPMethod = @"POST";
    
    JumpCoreURLSessionManager *manager = [[JumpCoreURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    JumpCoreHTTPResponseSerializer *response = manager.responseSerializer;
    response.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json",@"text/javascript",@"text/html",@"text/plain", @"text/xml",
                                                                                   @"image/*", nil];
    
    __block NSURLSessionUploadTask *session = [manager uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
      if (progress) {
        progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
      }
    }  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSInteger statusCode = 404;
        NSHTTPURLResponse  *httpResponse = (NSHTTPURLResponse *)response;
        if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = httpResponse.statusCode;
        }
        
        if (responseObject) {
            // 留给h5来做json解析 我们返回json字符串
            AppLog(@"JumpRequest response:%@", responseObject);
            if (success) {
                [[self allTasks] removeObject:session];
                [self successResponse:responseObject callback:success];
                
                if ([self isDebug]) {
                  [self logWithSuccessResponse:responseObject
                                           url:absolute
                                        params:parameters];
                }
            }

        } else {
            [[self allTasks] removeObject:session];
            
            [self handleCallbackWithError:error statusCode:statusCode fail:fail];
            
            if ([self isDebug]) {
              [self logWithFailError:error url:absolute params:nil];
            }
        }
    }];
    
    [session resume];
    if (session) {
      [[self allTasks] addObject:session];
    }

    return session;
}

+ (URLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(DownloadProgress)progressBlock
                               success:(ResponseSuccess)success
                               failure:(ResponseFail)failure {
  if ([self baseUrl] == nil) {
    if ([NSURL URLWithString:url] == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  } else {
    if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
      AppLog(@"URLString无效，无法生成URL。可能是URL中有中文，请尝试Encode URL");
      return nil;
    }
  }
  
  NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
  JumpCoreHTTPSessionManager *manager = [self manager];
  
  URLSessionTask *session = nil;
  
  session = [manager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
    if (progressBlock) {
      progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
    }
  } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
    return [NSURL fileURLWithPath:saveToPath];
  } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
    [[self allTasks] removeObject:session];
    
    if (error == nil) {
      if (success) {
        success(filePath.absoluteString);
      }
      
      if ([self isDebug]) {
        AppLog(@"Download success for url %@",
                  [self absoluteUrlWithPath:url]);
      }
    } else {
      [self handleCallbackWithError:error fail:failure];
      
      if ([self isDebug]) {
        AppLog(@"Download fail for url %@, reason : %@",
                  [self absoluteUrlWithPath:url],
                  [error description]);
      }
    }
  }];
  
  [session resume];
  if (session) {
    [[self allTasks] addObject:session];
  }
  
  return session;
}

#pragma mark - Private
+ (JumpCoreHTTPSessionManager *)manager {
  @synchronized (self) {
    // 只要不切换baseurl，就一直使用同一个session manager
//    if (sg_sharedManager == nil || sg_isBaseURLChanged) {
      // 开启转圈圈
      [JumpCoreNetworkActivityIndicatorManager sharedManager].enabled = YES;
      
      JumpCoreHTTPSessionManager *manager = nil;;
      if ([self baseUrl] != nil) {
        manager = [[JumpCoreHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
      } else {
        manager = [JCNetworking shareAFNManager];
      }
    
      switch (sg_requestType) {
        case kRequestTypeJSON: {
          manager.requestSerializer = [JumpCoreJSONRequestSerializer serializer];
          break;
        }
        case kRequestTypePlainText: {
          manager.requestSerializer = [JumpCoreHTTPRequestSerializer serializer];
          break;
        }
        default: {
          break;
        }
      }
      
      switch (sg_responseType) {
        case kResponseTypeJSON: {
          manager.responseSerializer = [JumpCoreJSONResponseSerializer serializer];
          break;
        }
        case kResponseTypeXML: {
          manager.responseSerializer = [JumpCoreXMLParserResponseSerializer serializer];
          break;
        }
        case kResponseTypeData: {
          manager.responseSerializer = [JumpCoreHTTPResponseSerializer serializer];
          break;
        }
        default: {
          break;
        }
      }
      
      manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
      
      
      for (NSString *key in sg_httpHeaders.allKeys) {
        if (sg_httpHeaders[key] != nil) {
          [manager.requestSerializer setValue:sg_httpHeaders[key] forHTTPHeaderField:key];
        }
      }
      
      manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                @"text/html",
                                                                                @"text/json",
                                                                                @"text/plain",
                                                                                @"text/javascript",
                                                                                @"text/xml",
                                                                                @"image/*"]];
      
      manager.requestSerializer.timeoutInterval = sg_timeout;
      
      // 设置允许同时最大并发数量，过大容易出问题
      manager.operationQueue.maxConcurrentOperationCount = 20;
      sg_sharedManager = manager;
    }
//  }
  
  return sg_sharedManager;
}

+ (void)detectNetwork {
  JumpCoreNetworkReachabilityManager *reachabilityManager = [JumpCoreNetworkReachabilityManager sharedManager];
  
  [reachabilityManager startMonitoring];
  [reachabilityManager setReachabilityStatusChangeBlock:^(JumpCoreNetworkReachabilityStatus status) {
    if (status == JumpCoreNetworkReachabilityStatusNotReachable){
      sg_networkStatus = kNetworkStatusNotReachable;
    } else if (status == JumpCoreNetworkReachabilityStatusUnknown){
      sg_networkStatus = kNetworkStatusUnknown;
    } else if (status == JumpCoreNetworkReachabilityStatusReachableViaWWAN2G ||
               status == JumpCoreNetworkReachabilityStatusReachableViaWWAN3G ||
               status == JumpCoreNetworkReachabilityStatusReachableViaWWAN4G){
      sg_networkStatus = kNetworkStatusReachableViaWWAN;
    } else if (status == JumpCoreNetworkReachabilityStatusReachableViaWiFi){
      sg_networkStatus = kNetworkStatusReachableViaWiFi;
    }
  }];
}

+ (void)setReachabilityStatusChangeBlock:(nullable void (^)(JCNetworkStatus status))block {
    JumpCoreNetworkReachabilityManager *manager = [JumpCoreNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(JumpCoreNetworkReachabilityStatus status) {
        switch (status) {
            case JumpCoreNetworkReachabilityStatusReachableViaWiFi:
                block(kNetworkStatusReachableViaWiFi);
                break;
            case JumpCoreNetworkReachabilityStatusReachableViaWWAN2G:
                block(kNetworkStatusReachableViaWWAN2G);
                break;
            case JumpCoreNetworkReachabilityStatusReachableViaWWAN3G:
                block(kNetworkStatusReachableViaWWAN3G);
                break;
            case JumpCoreNetworkReachabilityStatusReachableViaWWAN4G:
                block(kNetworkStatusReachableViaWWAN4G);
                break;
            case JumpCoreNetworkReachabilityStatusNotReachable:
                block(kNetworkStatusNotReachable);
                break;
            case JumpCoreNetworkReachabilityStatusUnknown:
                block(kNetworkStatusUnknown);
                break;
            default:
                block(kNetworkStatusUnknown);
                break;
        }
        
    }];
    [manager startMonitoring];
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
  AppLog(@"\n");
  AppLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
            [self generateGETAbsoluteURL:url params:params],
            params,
            [self tryToParseData:response]);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
  NSString *format = @" params: ";
  if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
    format = @"";
    params = @"";
  }
  
  AppLog(@"\n");
  if ([error code] == NSURLErrorCancelled) {
    AppLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              format,
              params);
  } else {
    AppLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
              [self generateGETAbsoluteURL:url params:params],
              format,
              params,
              [error localizedDescription]);
  }
}

// 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
  if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
    return url;
  }
  
  NSString *queries = @"";
  for (NSString *key in params) {
    id value = [params objectForKey:key];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
      continue;
    } else if ([value isKindOfClass:[NSArray class]]) {
      continue;
    } else if ([value isKindOfClass:[NSSet class]]) {
      continue;
    } else {
      queries = [NSString stringWithFormat:@"%@%@=%@&",
                 (queries.length == 0 ? @"&" : queries),
                 key,
                 value];
    }
  }
  
  if (queries.length > 1) {
    queries = [queries substringToIndex:queries.length - 1];
  }
  
  if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
    if ([url rangeOfString:@"?"].location != NSNotFound
        || [url rangeOfString:@"#"].location != NSNotFound) {
      url = [NSString stringWithFormat:@"%@%@", url, queries];
    } else {
      queries = [queries substringFromIndex:1];
      url = [NSString stringWithFormat:@"%@?%@", url, queries];
    }
  }
  
  return url.length == 0 ? queries : url;
}


+ (NSString *)encodeUrl:(NSString *)url {
  return [self _URLEncode:url];
}

+ (id)tryToParseData:(id)responseData {
  if ([responseData isKindOfClass:[NSData class]]) {
    // 尝试解析成JSON
    if (responseData == nil) {
      return responseData;
    } else {
      NSError *error = nil;
      NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&error];
      
      if (error != nil) {
        return responseData;
      } else {
        return response;
      }
    }
  } else {
    return responseData;
  }
}

+ (void)successResponse:(id)responseData callback:(ResponseSuccess)success {
  if (success) {
    success([self tryToParseData:responseData]);
  }
}

+ (NSString *)_URLEncode:(NSString *)url {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

  return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
#pragma clang diagnostic pop
  // 采用下面的方式反而不能请求成功
//  NSString *newString =
//  CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                            (CFStringRef)url,
//                                                            NULL,
//                                                            CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
//  if (newString) {
//    return newString;
//  }
//
//  return url;
}

+ (id)cahceResponseWithURL:(NSString *)url parameters:params {
  id cacheData = nil;
  
  if (url) {
    // Try to get datas from disk
    NSString *directoryPath = cachePath();
    NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
    NSString *key = [NSString jc_networking_md5:absoluteURL];
    NSString *path = [directoryPath stringByAppendingPathComponent:key];
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    if (data) {
      cacheData = data;
      AppLog(@"Read data from cache for url: %@\n", url);
    }
  }
  
  return cacheData;
}

+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request parameters:params {
  if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
    NSString *directoryPath = cachePath();
    
    NSError *error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
      [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:&error];
      if (error) {
        AppLog(@"create cache dir error: %@\n", error);
        return;
      }
    }
    
    NSString *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
    NSString *key = [NSString jc_networking_md5:absoluteURL];
    NSString *path = [directoryPath stringByAppendingPathComponent:key];
    NSDictionary *dict = (NSDictionary *)responseObject;
    
    NSData *data = nil;
    if ([dict isKindOfClass:[NSData class]]) {
      data = responseObject;
    } else {
      data = [NSJSONSerialization dataWithJSONObject:dict
                                             options:NSJSONWritingPrettyPrinted
                                               error:&error];
    }
    
    if (data && error == nil) {
      BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
      if (isOk) {
//        AppLog(@"cache file ok for request: %@\n", absoluteURL);
      } else {
//        AppLog(@"cache file error for request: %@\n", absoluteURL);
      }
    }
  }
}

+ (NSString *)absoluteUrlWithPath:(NSString *)path {
  if (path == nil || path.length == 0) {
    return @"";
  }
  
  if ([self baseUrl] == nil || [[self baseUrl] length] == 0) {
    return path;
  }
  
  NSString *absoluteUrl = path;
  
  if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
    if ([[self baseUrl] hasSuffix:@"/"]) {
      if ([path hasPrefix:@"/"]) {
        NSMutableString * mutablePath = [NSMutableString stringWithString:path];
        [mutablePath deleteCharactersInRange:NSMakeRange(0, 1)];
        absoluteUrl = [NSString stringWithFormat:@"%@%@",
                       [self baseUrl], mutablePath];
      } else {
        absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
      }
    } else {
      if ([path hasPrefix:@"/"]) {
        absoluteUrl = [NSString stringWithFormat:@"%@%@",[self baseUrl], path];
      } else {
        absoluteUrl = [NSString stringWithFormat:@"%@/%@",
                       [self baseUrl], path];
      }
    }
  }
  
  return absoluteUrl;
}

+ (void)handleCallbackWithError:(NSError *)error fail:(ResponseFail)fail {
  if ([error code] == NSURLErrorCancelled) {
    if (sg_shouldCallbackOnCancelRequest) {
      if (fail) {
        fail(error);
      }
    }
  } else {
    if (fail) {
      fail(error);
    }
  }
}

+ (void)handleCallbackWithError:(NSError *)error statusCode:(NSInteger)statusCode fail:(ResponseFailWithCode)fail {
  if ([error code] == NSURLErrorCancelled) {
    if (sg_shouldCallbackOnCancelRequest) {
      if (fail) {
        fail(error, statusCode);
      }
    }
  } else {
    if (fail) {
      fail(error, statusCode);
    }
  }
}

@end
