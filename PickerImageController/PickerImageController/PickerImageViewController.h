//
//  PickerImageViewController.h
//  PickerImageController
//
//  Created by Jane on 16/6/27.
//  Copyright © 2016年 许珍珍. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PickerImageViewController;

@protocol imagePickDelegate <NSObject>

/**
 *  已经选定了图片
 *
 *  @param photos 已经选定的图片数组，存放UIImage
 */
- (void)imagePick:(PickerImageViewController *)picker DidFinishedPickingWithArray:(NSMutableArray *)photos;

@end

@interface PickerImageViewController : UIViewController

/**
 *  图片选择代理
 */
@property (nonatomic, assign) id <imagePickDelegate> delegate;
/**
 *  选择图片限制数,默认选择一张图片
 */
@property (nonatomic, assign) NSInteger maxNumLimit;
/**
 *  导航栏背景,默认颜色RGB(56, 67, 94)
 */
@property (nonatomic, strong) UIColor *navigationBarColor;
/**
 *  相册列表背景色,默认颜色RGB(56, 67, 94)
 */
@property (nonatomic, strong) UIColor *mainColor;
/**
 *  是否为队徽
 */
@property (nonatomic, assign)BOOL  isBadge;

@end
