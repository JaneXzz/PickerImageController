//
//  ViewController.m
//  PickerImageController
//
//  Created by Jane on 16/6/27.
//  Copyright © 2016年 许珍珍. All rights reserved.
//

#import "ViewController.h"
#import "PickerImageViewController.h"


@interface ViewController ()<imagePickDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)pickerImageController:(id)sender {
    PickerImageViewController *imagePicker = [[PickerImageViewController alloc] init];
    imagePicker.delegate = self;
    imagePicker.maxNumLimit = 1;
//    [self.navigationController showDetailViewController:imagePicker sender:nil];
    [self presentViewController:imagePicker animated:YES completion:nil];

}
- (void)imagePick:(PickerImageViewController *)picker DidFinishedPickingWithArray:(NSMutableArray *)photos
{
    NSLog(@"nihao");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
