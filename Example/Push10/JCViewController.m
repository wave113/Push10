//
//  JCViewController.m
//  Push10
//
//  Created by wave113 on 12/17/2020.
//  Copyright (c) 2020 wave113. All rights reserved.
//

#import "JCViewController.h"
#import <Push10/Test.h>

@interface JCViewController ()

@end

@implementation JCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSLog(@"%@", [Test.alloc init]);

}


@end
