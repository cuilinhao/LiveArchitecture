//
//  ViewController.m
//  MOBStreamingPusherDemo
//
//  Created by wkx on 2018/9/26.
//  Copyright © 2018年 testDemo. All rights reserved.
//

#import "ViewController.h"
#import "MSPLivePreview.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view addSubview:[[MSPLivePreview alloc] initWithFrame:self.view.bounds]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscape;
//}
//
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
//{
//    return YES;
//}

@end
