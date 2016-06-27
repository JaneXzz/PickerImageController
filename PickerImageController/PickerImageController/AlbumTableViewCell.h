//
//  AlbumTableViewCell.h
//  qiuding
//
//  Created by appel on 15/11/25.
//  Copyright © 2015年 eims. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AlbumTableViewCell : UITableViewCell
- (void)getDataFromAssetsGroup:(ALAssetsGroup *)group;
@end
