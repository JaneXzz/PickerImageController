//
//  PickerImageViewController.m
//  PickerImageController
//
//  Created by Jane on 16/6/27.
//  Copyright © 2016年 许珍珍. All rights reserved.
//

#import "PickerImageViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AlbumTableViewCell.h"
#define COUNT self.albumArray.count

#define X(width) width/375.0*ScreenWidth
#define Y(height) height/667.0*ScreenHeight

// 屏幕的物理高度
#define  ScreenHeight  [UIScreen mainScreen].bounds.size.height
// 屏幕的物理宽度
#define  ScreenWidth   [UIScreen mainScreen].bounds.size.width

#define RGB0X(rgbValue) [UIColor colorWithRed: ((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green: ((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue: ((float)(rgbValue & 0xFF)) / 255.0 alpha: 1.0]

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
//适配水平方向
#define AutoSizeScaleX (ScreenHeight > 480 ? ScreenWidth/320:1.0)
//适配竖直方向
#define AutoSizeScaleY (ScreenHeight > 480 ? ScreenHeight/568 : 1.0)

#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

@interface PickerImageViewController ()<UITableViewDataSource, UITableViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    BOOL dismiss;
    NSThread *thread;
    NSString *albumName; // 相机胶卷相册名称
    UIImageView *_mainImgView;
    UIScrollView *_myScrollView;
    UIButton *backBtn; // 返回按钮
    UILabel *_navLabel; // 导航文字
    UIImageView *_upDownImage; // 上下箭头
    BOOL isAppearence; // 相册选择tableView是否已经出现
    UIImageView *navView;
    ALAsset *alaset;  // 单选选中的
    int numOfChoosed; // 已经选择了几张照片
    int indexOfCaremaAlbum; // 相机胶卷在albumArray的索引
    UIView *bottom;// 底部“”你还可以选择4张背景
}

@property (nonatomic, assign) NSInteger numOfAlbum; // 当前是第几个相册
@property (nonatomic, strong) UITableView *tableView; // 选择相册的tableView
@property (nonatomic, strong) NSMutableArray *imageArray; // 展示的  UIImage
@property (nonatomic, strong) UIView *grayCover; // 蒙版
@property (nonatomic, strong) NSMutableArray *albumArray; // 相册数组 ALAssetsGroup
@property (nonatomic, strong) ALAssetsLibrary *library; // 获取系统相册数据
@property (nonatomic, strong) NSMutableDictionary *aLAssetDictionary; // 已经选中相册的所有ALAsset,key:相册名,value:NSArray--UIImage
@property (nonatomic, strong) NSMutableArray *choosedArray; // 当前选中相册的所有ALAsset
@property (nonatomic, strong) NSMutableArray *resultArray;  // 多选选中的图片
@property (nonatomic, assign) BOOL first;
@property (nonatomic, assign) BOOL camera;
@property (nonatomic, strong) UILabel *bottomClueLabel; // 底部提示label

@end

@implementation PickerImageViewController
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self createBottomClueLabel];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self createCustomNavigationBar];
    [self createMainView];
    [self createTableView];
    [self getAllInfo];
    if (!self.maxNumLimit||self.maxNumLimit == 0) {
        self.maxNumLimit = 1;
    }
}

- (void)createBottomClueLabel{
    if (self.bottomClueLabel==nil) {
        bottom = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight-49, ScreenWidth, 49)];
        bottom.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
        bottom.alpha = 0.9;
        self.bottomClueLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, ScreenWidth-10, 49)];
        self.bottomClueLabel.backgroundColor = [UIColor whiteColor];
        self.bottomClueLabel.textAlignment = NSTextAlignmentLeft;
        
        NSMutableAttributedString *attributeString1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"你还可以选择 %ld 张",self.numOfAlbum] attributes:[NSDictionary dictionaryWithObject:RGB0X(0x111111) forKey:NSForegroundColorAttributeName]];
        NSMutableAttributedString *attributeString2 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",self.maxNumLimit] attributes:[NSDictionary dictionaryWithObject:RGB0X(0x16b558) forKey:NSForegroundColorAttributeName]];
        [attributeString1 replaceCharactersInRange:NSMakeRange(7, 1) withAttributedString:attributeString2];
        self.bottomClueLabel.attributedText = attributeString1;
        self.bottomClueLabel.font = [UIFont systemFontOfSize:16];
        [bottom addSubview:self.bottomClueLabel];
        UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
        [window addSubview:bottom];
    }
}
//创建主视图 copy过来的
- (void) createMainView
{
    _mainImgView = [[UIImageView alloc] init];
    //判断版本
    _mainImgView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    _mainImgView.userInteractionEnabled = YES;
    [self.view insertSubview:_mainImgView atIndex:0];
    _myScrollView = [[UIScrollView alloc] init];
    _myScrollView.frame = CGRectMake(0, 64, ScreenWidth, [UIScreen mainScreen].bounds.size.height-64);
    if (self.mainColor) {
        _myScrollView.backgroundColor = _mainColor;
    } else{
        _myScrollView.backgroundColor = RGB(56, 67, 94);
    }
    _myScrollView.scrollEnabled = YES;
    _myScrollView.contentSize = CGSizeMake(ScreenWidth, 620);
    [self.view addSubview:_myScrollView];
}

#pragma mark -- 自定义custom
- (void) createCustomNavigationBar
{
    CGRect navViewRect = CGRectZero;
    navViewRect = CGRectMake(0, 0, self.view.frame.size.width, 64);
    navView = [[UIImageView alloc] initWithFrame:navViewRect];
    if (self.navigationBarColor) {
        navView.backgroundColor = _navigationBarColor;
    } else{
        navView.backgroundColor = RGB(56, 67, 94);
    }
    navView.userInteractionEnabled = YES;
    [self.view addSubview:navView];
    backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 20, 60, 44);
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:backBtn];
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(12, 16, 14, 14)];
    imgV.image = [UIImage imageNamed:@"quxiao28"];
    [backBtn addSubview:imgV];
    _navLabel = [[UILabel alloc] init];
    _navLabel.backgroundColor = [UIColor clearColor];
    _navLabel.frame = CGRectMake(60*AutoSizeScaleX, 20, 200*AutoSizeScaleX, 44);
    _navLabel.text = @"选择照片";
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changePhotos:)];
    _navLabel.userInteractionEnabled = YES;
    [_navLabel addGestureRecognizer:tap];
    _navLabel.textColor = [UIColor whiteColor];
    _navLabel.textAlignment = NSTextAlignmentCenter;
    _navLabel.font = [UIFont systemFontOfSize:18];
    [navView addSubview:_navLabel];
    _upDownImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(navView.frame)-9, 10, 5)];
    _upDownImage.center = CGPointMake(_navLabel.center.x, _upDownImage.center.y);
    _upDownImage.image = [UIImage imageNamed:@"xuanzexiangce"];
    [navView addSubview:_upDownImage];
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sendBtn.frame = CGRectMake(ScreenWidth-60, 20, 60, 44);
    [sendBtn setTitle:@"确定" forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    sendBtn.backgroundColor = [UIColor clearColor];
    [sendBtn addTarget:self action:@selector(sendBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:sendBtn];
    [self.view addSubview:navView];
}
#pragma mark - 照片选择完毕，点击确定
- (void)sendBtnClick{ // 获取选中的高清图
    if (self.maxNumLimit == 1) { // 如果是单选
        if (!alaset) { // 如果没选
            [self showNoPhotoAlert];
            return;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePick:DidFinishedPickingWithArray:)]) {
            [self.delegate imagePick:self DidFinishedPickingWithArray:[NSMutableArray arrayWithObject:[UIImage imageWithCGImage:[alaset.defaultRepresentation fullResolutionImage] scale:[alaset.defaultRepresentation scale] orientation: (UIImageOrientation)[alaset.defaultRepresentation orientation]]]];
            [bottom removeFromSuperview];
        }
    } else if (self.maxNumLimit >1){
        if (self.resultArray.count == 0) { // 如果没选
            [self showNoPhotoAlert];
            return;
        }
        NSMutableArray *array = [NSMutableArray array];
        for (ALAsset *alasset in self.resultArray) {
            [array addObject:[UIImage imageWithCGImage:[alasset.defaultRepresentation fullResolutionImage] scale:[alasset.defaultRepresentation scale] orientation: (UIImageOrientation)[alasset.defaultRepresentation orientation]]];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePick:DidFinishedPickingWithArray:)]) {
            [self.delegate imagePick:self DidFinishedPickingWithArray:array];
            [bottom removeFromSuperview];
        }
    }
}
#pragma mark -- 如果没有选择照片就点击了确定
- (void)showNoPhotoAlert{
    [[[UIAlertView alloc] initWithTitle:@"提示" message:@"至少选择一张图片" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
}
#pragma mark -- 返回按钮
- (void)backBtnClick
{
    dismiss = YES;
    [bottom removeFromSuperview];
    [self dismissViewControllerAnimated:YES completion:nil];
}
// 切换相册
- (void)changePhotos:(UITapGestureRecognizer*)tap{
    if (isAppearence) {
        [self takeBackTableView];
    } else if (!isAppearence){
        [self takeOutTableView];
    }
}
// 弹出选项
- (void)takeOutTableView{
    isAppearence = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.frame = CGRectMake(0, 64, ScreenWidth, COUNT*Y(92));
        _upDownImage.transform = CGAffineTransformMakeRotation(M_PI);
        [_myScrollView addSubview:self.grayCover];
    }];
}
// 回收选项
- (void)takeBackTableView{
    isAppearence = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.frame = CGRectMake(0, 64, ScreenWidth, 0);
        _upDownImage.transform = CGAffineTransformMakeRotation(M_PI*2);
        [self.grayCover removeFromSuperview];
    }];
}
// 获取相册名称封面数量
- (void)getAllInfo{
    if (ALAssetsLibrary.authorizationStatus==2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"未被允许访问系统相册" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        [bottom removeFromSuperview];
        alert.tag = 9527;
        
        return;
    }
    self.library = [[ALAssetsLibrary alloc] init];
    __block int i = 0;
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if (![self.albumArray containsObject:group]&&[group numberOfAssets]!=0) {
                if ([[group valueForProperty:ALAssetsGroupPropertyType] isEqual:@16]) {
                    indexOfCaremaAlbum = i;
                    self.numOfAlbum = indexOfCaremaAlbum+1;
                    albumName = [group valueForProperty:ALAssetsGroupPropertyName];
                } else {i++;}
                [self.albumArray addObject:group];
            }} else{
                [self.tableView reloadData];
                if (self.albumArray.count != 0) {
                    [self createImageViewWith:self.albumArray[indexOfCaremaAlbum] WithIndex:10000*indexOfCaremaAlbum];
                }
            }
    } failureBlock:nil];
}
#pragma mark - 未被允许访问系统相册,回到原VC
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 9527) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
#pragma mark -创建下来弹窗菜单
- (void)createTableView{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, 0)];
    [self.view insertSubview:self.tableView aboveSubview:_navLabel];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return COUNT;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[AlbumTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    [cell getDataFromAssetsGroup:self.albumArray[indexPath.row]];
    if (indexPath.row == indexOfCaremaAlbum&&!self.first) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gouxuan"]];
        self.first = YES;
    }
    return cell;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return Y(92);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    for (int i = 0; i<self.albumArray.count; i++) {
        AlbumTableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        cell.accessoryView = [[UIView alloc] init];
    }
    AlbumTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gouxuan"]];
    [self createImageViewWith:self.albumArray[indexPath.row]WithIndex:(indexPath.row+1)*10000];
    self.numOfAlbum = indexPath.row+1;
    [self takeBackTableView];
}
// 创建相册列表
- (void)createImageViewWith:(ALAssetsGroup *)group WithIndex:(NSInteger)index{
    _navLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    for (UIView *view in _myScrollView.subviews) {
        if (view.tag >= 10086) {
            [view removeFromSuperview];
        }
    }
    self.imageArray = [NSMutableArray arrayWithObject:[UIImage imageNamed:@"paishezhaopian"]];
    self.choosedArray = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop){
            if (result) {              //       aspectRatioThumbnail
                if (![self.imageArray containsObject:[UIImage imageWithCGImage:result.thumbnail]]) {
                    [self.imageArray addObject:[UIImage imageWithCGImage:result.thumbnail]];
                    [self.choosedArray addObject:result];
                }
            }
        }];
        if(self.choosedArray.count == [group numberOfAssets]){
            CGFloat width = (ScreenWidth-Y(36))/3;
            for (int i=0; i<self.imageArray.count; i++) {
                [self performSelectorOnMainThread:@selector(loadImage:) withObject:[NSString stringWithFormat:@"%d",i] waitUntilDone:NO];
                _myScrollView.contentOffset = CGPointMake(0, 0);
                _myScrollView.contentSize = CGSizeMake(ScreenWidth, (Y(9)+width)*((self.imageArray.count+2)/3)+49);
            }
        }
    });
}
- (UIImage *)imageWithImage:(UIImage*)image
               scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage *img = [UIImage imageWithData:UIImageJPEGRepresentation(newImage, 0.8)];
    return img;
}
- (void)loadImage:(NSString *)index{
    int i = [index intValue];
    CGFloat width = (ScreenWidth-Y(36))/3;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(Y(9)+i%3*(Y(9)+width), Y(9)+i/3*(Y(9)+width), width, width)];
    imageView.userInteractionEnabled = YES;
    imageView.image = self.imageArray[i];
    imageView.tag = 10086+i;
    UIImageView *circle = [[UIImageView alloc] initWithFrame:CGRectMake(width-Y(30), Y(5), Y(25), Y(25))];
    circle.image = [UIImage imageNamed:@"weixuanzhong_zhaopian"];
    circle.userInteractionEnabled = YES;
    if (i!=0) { // 选照片
        [imageView addSubview:circle];
        UITapGestureRecognizer *chooseTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chooseThisOne:)];
        [imageView addGestureRecognizer:chooseTap];
    } else if (i==0){ // 照相去
        UITapGestureRecognizer *chooseTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(takePhoto:)];
        [imageView addGestureRecognizer:chooseTap];
    }
    NSMutableArray *array = self.aLAssetDictionary[_navLabel.text];
    if ([array containsObject:[NSString stringWithFormat:@"%ld", self.numOfAlbum*10000+imageView.tag-10087]]) {
        [self markThisPhotoWithImageView:imageView withChoose:YES];
    }
    [_myScrollView addSubview:imageView];
    // 创建之后，增加或替换新值
    if (self.camera) {
        if (self.maxNumLimit == 1 && self.choosedArray.count == [self.albumArray[indexOfCaremaAlbum] numberOfAssets]) { // 如果是单选,替换
            alaset = self.choosedArray[0];
            [self sendBtnClick];
        }
        if (self.maxNumLimit > 1 && self.choosedArray.count == [self.albumArray[indexOfCaremaAlbum] numberOfAssets]){ // 如果是多选
            [self.resultArray addObject:self.choosedArray[0]];
        }
    }
    self.camera = NO;
    //    [self performSelectorOnMainThread:@selector(updateUI:) withObject:imageView waitUntilDone:NO];
}
- (void)updateUI:(UIImageView *)imageView{
    // 创建之后，增加或替换新值
    if (self.camera) {
        if (self.maxNumLimit == 1 && self.choosedArray.count == [self.albumArray[indexOfCaremaAlbum] numberOfAssets]) { // 如果是单选,替换
            alaset = self.choosedArray[0];
            [self sendBtnClick];
        }
        if (self.maxNumLimit > 1 && self.choosedArray.count == [self.albumArray[indexOfCaremaAlbum] numberOfAssets]){ // 如果是多选
            [self.resultArray addObject:self.choosedArray[0]];
        }
    }
    self.camera = NO;
}
#pragma mark 打开照相机  以及其代理
-(void)takePhoto:(UITapGestureRecognizer *)tap
{
    [bottom removeFromSuperview];
    self.bottomClueLabel = nil;
    [self animationbegin:tap.view];
    if (numOfChoosed==self.maxNumLimit) {
        [self overLimitAlert];
        return;
    }
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = sourceType;
        picker.allowsEditing = NO;
        
        [self presentViewController:picker animated:YES completion:^{
        }];
    }
}
- (void)animationbegin:(UIView *)view
{
    // 设定为缩放
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    // 动画选项设定
    animation.duration = 0.1; // 动画持续时间
    animation.repeatCount = -1; // 重复次数
    animation.autoreverses = YES; // 动画结束时执行逆动画
    // 缩放倍数
    animation.fromValue = [NSNumber numberWithFloat:1.0]; // 开始时的倍率
    animation.toValue = [NSNumber numberWithFloat:0.9]; // 结束时的倍率
    // 添加动画
    [view.layer addAnimation:animation forKey:@"scale-layer"];
}

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    [self.library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"Save image fail：%@",error);
        }else{
            [self didFinishSaving];
            self.camera = YES;
        }
    }];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)didFinishSaving{
    NSMutableArray *array = self.aLAssetDictionary[albumName];
    for (int i = 0; i < array.count; i++) {
        NSString *savedIndex = array[i];
        NSString *newString = [NSString stringWithFormat:@"%ld", savedIndex.integerValue+1];
        array[i] = newString;
    }
    if (self.maxNumLimit == 1) { // 如果是单选
        numOfChoosed=1;
        self.aLAssetDictionary = [NSMutableDictionary dictionaryWithObject:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d",(indexOfCaremaAlbum+1)*10000]] forKey:albumName];
    } else if (self.maxNumLimit>1){ // 如果是多选
        if ([self.aLAssetDictionary[albumName] count]!=0) {
            NSMutableArray *array = self.aLAssetDictionary[albumName];
            numOfChoosed++;
            [array addObject:[NSString stringWithFormat:@"%d",(indexOfCaremaAlbum+1)*10000]];
        } else{
            numOfChoosed++;
            [self.aLAssetDictionary setValue:[NSMutableArray arrayWithObject:[NSString stringWithFormat:@"%d",(indexOfCaremaAlbum+1)*10000]] forKey:albumName];
        }
    }
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfCaremaAlbum inSection:0]];
    
}

#pragma mark - 选中某一张
- (void)chooseThisOne:(UITapGestureRecognizer *)tap{
    NSString *chooseIndex = [NSString stringWithFormat:@"%ld", tap.view.tag-10087 + self.numOfAlbum*10000];
    if (self.maxNumLimit == 1) {  // 单选
        numOfChoosed=1;
        if ([self.aLAssetDictionary.allKeys containsObject:_navLabel.text]&&[self.aLAssetDictionary[_navLabel.text] containsObject:chooseIndex]) { // 如果点的是同一张
            return;
        } else{ // 如果点的是另一张
            NSMutableArray *savedArray = self.aLAssetDictionary[_navLabel.text];
            for (UIView *view in _myScrollView.subviews) {
                if (savedArray&&view.tag == [savedArray.firstObject intValue]-self.numOfAlbum*10000+10087) {
                    [self markThisPhotoWithImageView:(UIImageView *)view withChoose:NO];
                }
            }
            alaset = self.choosedArray[tap.view.tag-10087];
            [self markThisPhotoWithImageView:(UIImageView *)tap.view withChoose:YES];
            self.aLAssetDictionary = [NSMutableDictionary dictionaryWithObject:[NSMutableArray arrayWithObject:chooseIndex] forKey:_navLabel.text];
        }
    } else if (self.maxNumLimit >1){// 多选
        if ([self.aLAssetDictionary.allKeys containsObject:_navLabel.text]) { // 如果选过这个相册
            NSMutableArray *array = self.aLAssetDictionary[_navLabel.text];
            if (![array containsObject:chooseIndex]) { // 如果没有选择这张
                if (numOfChoosed==self.maxNumLimit) {
                    [self overLimitAlert];
                    return;
                }
                [self.resultArray addObject:self.choosedArray[tap.view.tag-10087]];
                [array addObject:chooseIndex];
                numOfChoosed++;
                [self markThisPhotoWithImageView:(UIImageView *)tap.view withChoose:YES];
            } else{ // 如果已经选择了
                [array removeObject:chooseIndex];
                if (array.count == 0) {
                    [self.aLAssetDictionary removeObjectForKey:_navLabel.text];
                }
                [self.resultArray removeObject:self.choosedArray[tap.view.tag-10087]];
                numOfChoosed--;
                [self markThisPhotoWithImageView:(UIImageView *)tap.view withChoose:NO];
            }
        } else{ // 如果没选过这个相册
            if (numOfChoosed==self.maxNumLimit) {
                [self overLimitAlert];
                return;
            }
            [self.resultArray addObject:self.choosedArray[tap.view.tag-10087]];
            numOfChoosed++;
            [self.aLAssetDictionary setValue:[NSMutableArray arrayWithObject:chooseIndex] forKey:_navLabel.text];
            [self markThisPhotoWithImageView:(UIImageView *)tap.view withChoose:YES];
        }
    }
}
#pragma mark - 超过限制警告
- (void)overLimitAlert{
    [[[UIAlertView alloc] initWithTitle:@"提示" message:[NSString stringWithFormat:@"你最多选择%ld张", (long)self.maxNumLimit] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
}
#pragma mark - 对勾变绿(YES)或变灰(NO)
- (void)markThisPhotoWithImageView:(UIImageView *)imageView withChoose:(BOOL)choose{
    for (UIView *view in imageView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat width = imageView.frame.size.width;
    UIImageView *circle = [[UIImageView alloc] initWithFrame:CGRectMake(width-Y(30), Y(5), Y(25), Y(25))];
    UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    if (choose) {
        cover.backgroundColor = RGBACOLOR(255, 255, 255, 0.3);
        [imageView addSubview:cover];
        circle.image = [UIImage imageNamed:@"xuanzhong_zhaopian"];
    } else {
        circle.image = [UIImage imageNamed:@"weixuanzhong_zhaopian"];
    }
    [self animationbegin:circle];
    circle.userInteractionEnabled = YES;
    [imageView addSubview:circle];
    
    NSMutableAttributedString *attributeString1 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"你还可以选择 %ld 张",self.numOfAlbum] attributes:[NSDictionary dictionaryWithObject:RGB0X(0x111111) forKey:NSForegroundColorAttributeName]];
    NSMutableAttributedString *attributeString2 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",self.maxNumLimit-numOfChoosed] attributes:[NSDictionary dictionaryWithObject:RGB0X(0x16b558) forKey:NSForegroundColorAttributeName]];
    [attributeString1 replaceCharactersInRange:NSMakeRange(7, 1) withAttributedString:attributeString2];
    self.bottomClueLabel.attributedText = attributeString1;
}
- (UIView *)grayCover{
    if (!_grayCover) {
        _grayCover = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _grayCover.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35];
        UITapGestureRecognizer *removeGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeCover)];
        [_grayCover addGestureRecognizer:removeGesture];
    }
    return _grayCover;
}
- (void)removeCover{
    [self takeBackTableView];
}
- (NSMutableArray *)albumArray{
    if (!_albumArray) {
        _albumArray = [NSMutableArray array];
    }
    return _albumArray;
}

- (NSMutableArray *)choosedArray{
    if (!_choosedArray) {
        _choosedArray = [NSMutableArray array];
    }
    return _choosedArray;
}
- (NSMutableDictionary *)aLAssetDictionary{
    if (!_aLAssetDictionary) {
        _aLAssetDictionary = [NSMutableDictionary dictionary];
    }
    return _aLAssetDictionary;
}
- (NSMutableArray *)resultArray{
    if (!_resultArray) {
        _resultArray = [NSMutableArray array];
    }
    return _resultArray;
}
@end