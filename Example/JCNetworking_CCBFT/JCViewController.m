//
//  JCViewController.m
//  JCNetworking_CCBFT
//
//  Created by qinzixin on 10/27/2020.
//  Copyright (c) 2020 qinzixin. All rights reserved.
//

#import "JCViewController.h"
#import <JCNetworking_CCBFT/JCNetworking.h>

@interface JCViewController ()

@end

@implementation JCViewController

- (void)viewDidLoad
{

    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
	
    // 初始化
    [JCNetworking configRequestType:kRequestTypeJSON responseType:kResponseTypeJSON shouldAutoEncodeUrl:YES callbackOnCancelRequest:YES];
    [JCNetworking setTimeout:20.f];
    
    // 发送请求
    [JCNetworking getWithUrl:@"https://m.ccb.com"
                    refreshCache:YES
                         success:^(id  _Nonnull response) {
        }
                            fail:^(NSError * _Nonnull error) {
    }];
    
    // 上传文件
    [JCNetworking uploadWithData:[NSData data] url:@"https://m.ccb.com" filename:@"test" name:@"1000121" header:@{@"name":@"test"} mimeType:@"image/jpeg" parameters:@{} progress:^(int64_t bytesWritten, int64_t totalBytesWritten) {
            
           } success:^(id  _Nonnull response) {
             
           } fail:^(NSError * _Nonnull error, NSInteger statusCode) {
             
    }];
    
    // 下载文件
    [JCNetworking downloadWithUrl:@"https://m.ccb.com" saveToPath:@"" progress:^(int64_t bytesRead, int64_t totalBytesRead) {
                
            } success:^(id  _Nonnull response) {
                
            } failure:^(NSError * _Nonnull error) {
                
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
