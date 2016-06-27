//
//  AlbumTableViewCell.m
//  qiuding
//
//  Created by appel on 15/11/25.
//  Copyright © 2015年 eims. All rights reserved.
//

#import "AlbumTableViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define X(width) width/375.0*ScreenWidth
#define Y(height) height/667.0*ScreenHeight
//适配水平方向
#define AutoSizeScaleX (ScreenHeight > 480 ? ScreenWidth/320:1.0)
//适配竖直方向
#define AutoSizeScaleY (ScreenHeight > 480 ? ScreenHeight/568 : 1.0)

#define CGRectMaked(x, y,width,height)  CGRectMake(X(x), Y(y) ,X(width),Y(height))
#define CGRectMake1(x, y,width,height)  CGRectMake(x * AutoSizeScaleX, y * AutoSizeScaleY,width * AutoSizeScaleX,height * AutoSizeScaleY)
#define CGRectMakeX(x, y,width,height)  CGRectMake(x * AutoSizeScaleX, y ,width * AutoSizeScaleX,height)
// 屏幕的物理高度
#define  ScreenHeight  [UIScreen mainScreen].bounds.size.height
// 屏幕的物理宽度
#define  ScreenWidth   [UIScreen mainScreen].bounds.size.width


@interface AlbumTableViewCell ()
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *numLabel;
@end

@implementation AlbumTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self creatContentView];
    }
    return self;
}

- (void)creatContentView{
    self.icon = [[UIImageView alloc] initWithFrame:CGRectMaked(15, 10, 72, 72)];
    [self.contentView addSubview:self.icon];
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMaked(CGRectGetMaxX(self.icon.frame)+15, 25, 200, 16)];
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.font = [UIFont systemFontOfSize:16];
    self.nameLabel.textColor = [UIColor colorWithWhite:0.075 alpha:1.000];
    [self.contentView addSubview:self.nameLabel];
    
    self.numLabel = [[UILabel alloc] initWithFrame:CGRectMaked(CGRectGetMaxX(self.icon.frame)+15, 56, 200, 14)];
    self.numLabel.textAlignment = NSTextAlignmentLeft;
    self.numLabel.font = [UIFont systemFontOfSize:14];
    self.numLabel.textColor = [UIColor colorWithWhite:0.624 alpha:1.000];
    [self.contentView addSubview:self.numLabel];
}

- (void)getDataFromAssetsGroup:(ALAssetsGroup *)group{
    self.icon.image = [UIImage imageWithCGImage:[group posterImage]];
    self.nameLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    self.numLabel.text = [NSString stringWithFormat:@"%ld张",(long)[group numberOfAssets]];
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
