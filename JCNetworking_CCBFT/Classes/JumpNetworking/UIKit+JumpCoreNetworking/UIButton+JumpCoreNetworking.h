// UIButton+JumpCoreNetworking.h
//
//  Created by ccbft on 2020/5/6.
//  Copyright © 2020 ccbft. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class JumpCoreImageDownloader;

/**
 This category adds methods to the UIKit framework's `UIButton` class. The methods in this category provide support for loading remote images and background images asynchronously from a URL.

 @warning Compound values for control `state` (such as `UIControlStateHighlighted | UIControlStateDisabled`) are unsupported.
 */
@interface UIButton (JumpCoreNetworking)

///------------------------------------
/// @name Accessing the Image Downloader
///------------------------------------

/**
 Set the shared image downloader used to download images.

 @param imageDownloader The shared image downloader used to download images.
*/
+ (void)jc_setsharedImageDownloader:(JumpCoreImageDownloader *)imageDownloader;

/**
 The shared image downloader used to download images.
 */
+ (JumpCoreImageDownloader *)jc_sharedImageDownloader;

///--------------------
/// @name Setting Image
///--------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

  If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the image request.
 */
- (void)jc_setImageForState:(UIControlState)state
                 withURL:(NSURL *)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the button will not change its image until the image request finishes.
 */
- (void)jc_setImageForState:(UIControlState)state
                 withURL:(NSURL *)url
        placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The image to be set initially, until the image request finishes. If `nil`, the button will not change its image until the image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 */
- (void)jc_setImageForState:(UIControlState)state
          withURLRequest:(NSURLRequest *)urlRequest
        placeholderImage:(nullable UIImage *)placeholderImage
                 success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                 failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure;


///-------------------------------
/// @name Setting Background Image
///-------------------------------

/**
 Asynchronously downloads an image from the specified URL, and sets it as the background image for the specified state once the request is finished. Any previous background image request for the receiver will be cancelled.

 If the background image is cached locally, the background image is set immediately, otherwise the specified placeholder background image will be set immediately, and then the remote background image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the background image request.
 */
- (void)jc_setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url;

/**
 Asynchronously downloads an image from the specified URL, and sets it as the background image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 @param state The control state.
 @param url The URL used for the background image request.
 @param placeholderImage The background image to be set initially, until the background image request finishes. If `nil`, the button will not change its background image until the background image request finishes.
 */
- (void)jc_setBackgroundImageForState:(UIControlState)state
                           withURL:(NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholderImage;

/**
 Asynchronously downloads an image from the specified URL request, and sets it as the image for the specified state once the request is finished. Any previous image request for the receiver will be cancelled.

 If the image is cached locally, the image is set immediately, otherwise the specified placeholder image will be set immediately, and then the remote image will be set once the request is finished.

 If a success block is specified, it is the responsibility of the block to set the image of the button before returning. If no success block is specified, the default behavior of setting the image with `setBackgroundImage:forState:` is applied.

 @param state The control state.
 @param urlRequest The URL request used for the image request.
 @param placeholderImage The background image to be set initially, until the background image request finishes. If `nil`, the button will not change its background image until the background image request finishes.
 @param success A block to be executed when the image data task finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the image created from the response data of request. If the image was returned from cache, the response parameter will be `nil`.
 @param failure A block object to be executed when the image data task finishes unsuccessfully, or that finishes successfully. This block has no return value and takes three arguments: the request sent from the client, the response received from the server, and the error object describing the network or parsing error that occurred.
 */
- (void)jc_setBackgroundImageForState:(UIControlState)state
                    withURLRequest:(NSURLRequest *)urlRequest
                  placeholderImage:(nullable UIImage *)placeholderImage
                           success:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, UIImage *image))success
                           failure:(nullable void (^)(NSURLRequest *request, NSHTTPURLResponse * _Nullable response, NSError *error))failure;


///------------------------------
/// @name Canceling Image Loading
///------------------------------

/**
 Cancels any executing image task for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)jc_cancelImageDownloadTaskForState:(UIControlState)state;

/**
 Cancels any executing background image task for the specified control state of the receiver, if one exists.

 @param state The control state.
 */
- (void)jc_cancelBackgroundImageDownloadTaskForState:(UIControlState)state;

@end

NS_ASSUME_NONNULL_END

#endif
