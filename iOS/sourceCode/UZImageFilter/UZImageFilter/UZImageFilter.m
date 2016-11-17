/**
  * APICloud Modules
  * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */


#import "UZImageFilter.h"
#import "UZAppUtils.h"
#import "NSDictionaryUtils.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImageUtil.h"

static int number = 1;

@interface UZImageFilter ()
{
    UIView *coverView;
    NSInteger cbId;
    int openId;
    NSString *code;
    BOOL status;
    NSInteger filtercbId;
    NSInteger savecbId;
    UIImageView *imageView;        //暂时添加用于展示的ImageView
    UIImage *thumnailImage;        //处理后的缩略图
    UIImage *defaultImage;         //原始得到图片
    UIImage *result;               //滤镜后的结果image
    UIImage *finalResult;          //最终结果
    CIContext *_context;           //Core Image上下文
    CIImage *defaultCIImage;       //我们要编辑的图像
    CIImage *_outputImage;         //处理后的图像
    CIFilter *_colorControlsFilter;//滤镜
    NSMutableDictionary *_allImage;
}

@property  (nonatomic,assign) float filterValue;
@property (nonatomic, strong) NSOperationQueue *transPathQueue;

@end

@implementation UZImageFilter

- (id)initWithUZWebView:(UZWebView *)webView {
    self = [super initWithUZWebView:webView];
    if (self != nil) {
        _allImage = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dispose {
    if (cbId == -1) {
        [self deleteCallback:cbId];
    }
    if (filtercbId == -1) {
        [self deleteCallback:filtercbId];
    }
    if (savecbId == -1) {
        [self deleteCallback:savecbId];
    }
    if (self.transPathQueue) {
        [self.transPathQueue cancelAllOperations];
        self.transPathQueue = nil;
    }
}

- (NSOperationQueue *)transPathQueue {
    if (!_transPathQueue) {
        _transPathQueue = [[NSOperationQueue alloc]init];
        NSInteger maxOperation = 1;
        [_transPathQueue setMaxConcurrentOperationCount:maxOperation];
    }
    return _transPathQueue;
}


#pragma mark-
#pragma mark interface
#pragma mark - open 方法

//打开图片过滤器
- (void)open:(NSDictionary *)paraDic {
    cbId = [paraDic integerValueForKey:@"cbId" defaultValue:-1];
    NSString *imgPath = [paraDic objectForKey:@"imgPath"];
    if (!imgPath) {
        code = @"0";              //imgPath为空
        status = false;
    }else {
        NSString *realPath = [self getPathWithUZSchemeURL:imgPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isHaveFile = [fileManager fileExistsAtPath:realPath];
        if (isHaveFile) {
            NSData *data = [fileManager contentsAtPath:realPath];
            defaultImage = [UIImage imageWithData:data];
            if (defaultImage) {
                _context = [CIContext contextWithOptions:nil];
                [_allImage setObject:defaultImage forKey:[NSNumber numberWithInt:number]];
                openId = number;
                number ++;
                code = @"";       //图片读取成功
                status = true;
            } else {
                code = @"2";      //图片读取失败/非图片
                status = false;
            }
        } else {
            code = @"1";          //imgPath路径下的图片不存在
            status = false;
        }
    }
    NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [returnDic setObject:[NSNumber numberWithInt:openId] forKey:@"id"];
    [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
    [errDict setObject:code forKey:@"code"];
    [self sendResultEventWithCallbackId:cbId dataDict:returnDic errDict:errDict doDelete:YES];
}

#pragma mark -
#pragma mark filter 方法
#pragma mark -

//设置图片滤镜效果
- (void)filter:(NSDictionary *)paraDic {
    int filterOpenId = 0;
    NSString *filterType;
    UIImage *filterResultImage;
    BOOL isRightOpenId = true;//拿到的OpenId是否相同
    if (paraDic) {//default
        filterType = [paraDic stringValueForKey:@"type" defaultValue:@"default"];
        _filterValue = [paraDic floatValueForKey:@"value" defaultValue:60.0];
        filterOpenId = (int)[paraDic integerValueForKey:@"id" defaultValue:0];
        filtercbId = [paraDic integerValueForKey:@"cbId" defaultValue:-1];
        if (!_filterValue) {
            status = true;
        }else {
            if (_filterValue < 0 | _filterValue >100) {
                code = @"1";//非法
                status = false;
            } else {
                status = true;
            }
        }
        
        if (status) {//判断支持的滤镜名
            if (!filterType) {
                filterType = @"default";
            } else if ([filterType isEqualToString:@"default"] || [filterType isEqualToString:@"black_white"] || [filterType isEqualToString:@"blur"] || [filterType isEqualToString:@"emerald"] || [filterType isEqualToString:@"bright"] || [filterType isEqualToString:@"color_pencil"] || [filterType isEqualToString:@"dream"] || [filterType isEqualToString:@"autumn"] || [filterType isEqualToString:@"film"] || [filterType isEqualToString:@"lemo"] || [filterType isEqualToString:@"ancient"] || [filterType isEqualToString:@"gothic"] || [filterType isEqualToString:@"sharpColor"] || [filterType isEqualToString:@"elegant"] || [filterType isEqualToString:@"redWine"] || [filterType isEqualToString:@"lime"] ||[filterType isEqualToString:@"romantic"] || [filterType isEqualToString:@"halo"]  || [filterType isEqualToString:@"blues"] ||[filterType isEqualToString:@"nightScene"]) {
                code = @"";
                status = true;
            } else {
                code = @"0";
                status = false;
            }
        }
        //判断id
        if (status) {
            if (!filterOpenId) {
                isRightOpenId = false;
                code = @"2";//id不存在
                status = false;
            } else if (filterOpenId != openId) {
                isRightOpenId = false;
                code = @"-1";//id不相等 TODO
                status = false;
            } else {
                status = true;
            }
        }
    }

    if (isRightOpenId) {//status
        UIImage *superImg = [_allImage objectForKey:[NSNumber numberWithInt:filterOpenId]];
        filterResultImage = [self filteredImage:superImg withFilterName:filterType withValue:_filterValue filter:filterOpenId];
        //取50x50大小的缩略图
        UIImage *img = [self reSizeImage:filterResultImage toSize:CGSizeMake(200, 200)];
        //将初步滤镜后的缩略图图片(50x50)存储至    Document/imageFilter 文件夹下
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileName = [NSString stringWithFormat:@"%@.png",[self timeStamp]];
        NSString *imagePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *filePath = [imagePath  stringByAppendingPathComponent:@"imageFilter"];
        if(![fileManager fileExistsAtPath:filePath]) {
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSData *data;
        if (UIImagePNGRepresentation(img) == nil) {
            data = UIImageJPEGRepresentation(img, 1);
        }else {
            data = UIImagePNGRepresentation(img);
        }
        if ([_allImage objectForKey:[NSNumber numberWithInt:filterOpenId]]) {
            [_allImage removeObjectForKey:[NSNumber numberWithInt:filterOpenId]];
        }
        [_allImage setObject:img forKey:[NSNumber numberWithInteger:filterOpenId]];
            
        //创建路径
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *returnThumnailPath = [NSString stringWithFormat:@"%@/%@",filePath,fileName];
        NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
        
        //创建文件
        if (data) {
            [fileManager createFileAtPath:[filePath stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]] contents:data attributes:nil];
            [returnDic setObject:returnThumnailPath forKey:@"path"];
        }
        //需要返回的缩略图路径
        [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
        [errDict setObject:code forKey:@"code"];
        [self sendResultEventWithCallbackId:filtercbId dataDict:returnDic errDict:errDict doDelete:YES];
    }else {
        NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
        [errDict setObject:code forKey:@"code"];
        [self sendResultEventWithCallbackId:filtercbId dataDict:returnDic errDict:errDict doDelete:YES];
    }
}

//等比率缩放
- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize {
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

//自定长宽
- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize {
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return reSizeImage;
}

/**
 *  返回时间戳
 */
-(NSString *)timeStamp {
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Beijing"];
    [formatter setTimeZone:timeZone];
    NSString *timeString = [NSString stringWithFormat:@"%@", [formatter stringFromDate:date]];
    return timeString;
}

#pragma mark -
#pragma mark 返回滤镜的处理结果
#pragma mark -

//根据给的名字返回滤镜的处理结果
- (UIImage*)filteredImage:(UIImage*)imaged withFilterName:(NSString*)filterName withValue:(NSInteger)value filter:(int)filterId {
    if ([filterName isEqualToString:@"default"]||!_filterValue) {
        return defaultImage;
    }
    
    //  1-黑白:CIPhotoEffectNoir   无value
    //  2-模糊:CIGaussianBlur     inputRadius 0~100  越大越模糊
    UIImage *filterImage = imaged;
    defaultCIImage = [CIImage imageWithCGImage:imaged.CGImage];
    if ([filterName isEqualToString:@"black_white"]) {
        //    黑白:CIPhotoEffectNoir   无value
        _colorControlsFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
    }
    if ([filterName isEqualToString:@"blur"]) {
        //    高斯模糊:CIGaussianBlur   inputRadius 0~100  越大越模糊
        _colorControlsFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value] forKey:@"inputRadius"];
    }
    if ([filterName isEqualToString:@"film"]) {
        //    胶片:CIVignette   inputIntensity -1~1   inputRadius 0~2
        _colorControlsFilter = [CIFilter filterWithName:@"CIVignette"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
        
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/25] forKey:@"inputIntensity"];//  0~2
        
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/25] forKey:@"inputRadius"];// 0~2
    }
    if ([filterName isEqualToString:@"color_pencil"]) {
        //    颜色控制:CIColorControls   inputBrightness -1~1   inputContrast 0~4
        //                              inputSaturation 0~2
        _colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
        
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/100] forKey:@"inputBrightness"];//  -1~1
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/50] forKey:@"inputSaturation"];// 0~2
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/25] forKey:@"inputContrast"];// 0~4
    }
    if ([filterName isEqualToString:@"autumn"]) {
        //    滤镜名:CISepiaTone   inputIntensity 0~1
        _colorControlsFilter = [CIFilter filterWithName:@"CISepiaTone"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
        [_colorControlsFilter setValue:[NSNumber numberWithInteger:value/100] forKey:@"inputIntensity"];// 0~4
    }
    if ([filterName isEqualToString:@"emerald"]) {
        //    滤镜名:CIPhotoEffectProcess   无value
        _colorControlsFilter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
    }
    if ([filterName isEqualToString:@"bright"]) {
        //    褪色:CIPhotoEffectFade  无value
        _colorControlsFilter = [CIFilter filterWithName:@"CIPhotoEffectFade"];
        [_colorControlsFilter setValue:defaultCIImage forKey:kCIInputImageKey];
    }
    _filterValue = _filterValue / 100.0;
    
    //LOMO
    float colormatrix_lomo[] = {
        1.7f,  0.1f, 0.1f, 0, -73.1f,
        0,  1.7f, 0.1f, 0, -73.1f,
        0,  0.1f, 1.6f, 0, -73.1f,
        0,  0, 0, _filterValue, 0 };
    //复古
    float colormatrix_huaijiu[] = {
        0.2f,0.5f, 0.1f, 0, 40.8f,
        0.2f, 0.5f, 0.1f, 0, 40.8f,
        0.2f,0.5f, _filterValue, 0, 40.8f,
        0, 0, 0, 1, 0 };
    
    //哥特
    float colormatrix_gete[] = {
        1.9f,-0.3f, -0.2f, 0,-87.0f,
        -0.2f, 1.7f, -0.1f, 0, -87.0f,
        -0.1f,-0.6f, 2.0f, 0, -87.0f,
        0, 0, 0, _filterValue, 0 };
    
    //锐化
    float colormatrix_ruise[] = {
        4.8f,-1.0f, -0.1f, 0,-388.4f,
        -0.5f,4.4f, -0.1f, 0,-388.4f,
        -0.5f,-1.0f, 5.2f, 0,-388.4f,
        0, 0, 0, _filterValue, 0 };
    
    //淡雅
    float colormatrix_danya[] = {
        0.6f,0.3f, 0.1f, 0,73.3f,
        0.2f,0.7f, 0.1f, 0,73.3f,
        0.2f,0.3f, 0.4f, 0,73.3f,
        0, 0, 0, _filterValue, 0 };
    
    //酒红
    float colormatrix_jiuhong[] = {
        1.2f,0.0f, 0.0f, 0.0f,0.0f,
        0.0f,0.9f, 0.0f, 0.0f,0.0f,
        0.0f,0.0f, 0.8f, 0.0f,0.0f,
        0, 0, 0, _filterValue, 0 };
    
    //清宁
    float colormatrix_qingning[] = {
        0.9f, 0, 0, 0, 0,
        0, 1.1f,0, 0, 0,
        0, 0, 0.9f, 0, 0,
        0, 0, 0, _filterValue, 0 };
    
    //浪漫
    float colormatrix_langman[] = {
        0.9f, 0, 0, 0, 63.0f,
        0, 0.9f,0, 0, 63.0f,
        0, 0, 0.9f, 0, 63.0f,
        0, 0, 0, _filterValue, 0 };
    
    //光晕
    float colormatrix_guangyun[] = {
        0.9f, 0, 0,  0, 64.9f,
        0, 0.9f,0,  0, 64.9f,
        0, 0, 0.9f,  0, 64.9f,
        0, 0, 0, _filterValue, 0 };
    //蓝调
    float colormatrix_landiao[] = {
        2.1f, -1.4f, 0.6f, 0.0f, -31.0f,
        -0.3f, 2.0f, -0.3f, 0.0f, -31.0f,
        -1.1f, -0.2f, 2.6f, 0.0f, -31.0f,
        0.0f, 0.0f, 0.0f, _filterValue, 0.0f
    };
    //梦幻
    float colormatrix_menghuan[] = {
        0.8f, 0.3f, 0.1f, 0.0f, 46.5f,
        0.1f, 0.9f, 0.0f, 0.0f, 46.5f,
        0.1f, 0.3f, 0.7f, 0.0f, 46.5f,
        0.0f, 0.0f, 0.0f, _filterValue, 0.0f
    };
    //夜色
    float colormatrix_yese[] = {
        1.0f, 0.0f, 0.0f, 0.0f, -66.6f,
        0.0f, 1.1f, 0.0f, 0.0f, -66.6f,
        0.0f, 0.0f, 1.0f, 0.0f, -66.6f,
        0.0f, 0.0f, 0.0f, _filterValue, 0.0f
    };
    //lomo
    if ([filterName isEqualToString:@"lemo"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_lomo];
    }
    //复古
    if ([filterName isEqualToString:@"ancient"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_huaijiu];
    }
    //哥特
    if ([filterName isEqualToString:@"gothic"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_gete];
    }
    //锐色
    if ([filterName isEqualToString:@"sharpColor"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_ruise];
    }
    //淡雅
    if ([filterName isEqualToString:@"elegant"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_danya];
    }
    //酒红
    if ([filterName isEqualToString:@"redWine"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_jiuhong];
    }
    //青柠
    if ([filterName isEqualToString:@"lime"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_qingning];
    }
    //浪漫
    if ([filterName isEqualToString:@"romantic"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_langman];
    }
    //光晕
    if ([filterName isEqualToString:@"halo"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_guangyun];
    }
    //蓝调
    if ([filterName isEqualToString:@"blues"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_landiao];
    }
    //梦幻
    if ([filterName isEqualToString:@"dream"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_menghuan];
    }
    //夜色
    if ([filterName isEqualToString:@"nightScene"]) {
        filterImage = [ImageUtil imageWithImage:imaged withColorMatrix:colormatrix_yese];
    }
    
    //拿到处理后的结果
    CIImage *outputImage= [_colorControlsFilter outputImage];//取得输出图像
    CGImageRef temp=[_context createCGImage:outputImage fromRect:[outputImage extent]];
    result = [UIImage imageWithCGImage:temp];//转化为CGImage显示在界面中
    finalResult = result;
    CGImageRelease(temp);//释放CGImage对象
    if ([filterName isEqualToString:@"bright"]|[filterName isEqualToString:@"black_white"]|[filterName isEqualToString:@"emerald"]|[filterName isEqualToString:@"color_pencil"]|[filterName isEqualToString:@"film"]|[filterName isEqualToString:@"blur"]|[filterName isEqualToString:@"autumn"]) {
        return result;
    }else {
        return filterImage;
    }
}

#pragma mark -
#pragma mark save 方法
#pragma mark -
/**
 *  保存最终处理结果
 */
-(void)save:(NSDictionary *)paraDic {
    __block NSMutableDictionary *errDic = [NSMutableDictionary dictionaryWithCapacity:1];
    BOOL isAlbum = [paraDic boolValueForKey:@"album" defaultValue:false];
    savecbId = [paraDic integerValueForKey:@"cbId" defaultValue:-1];
    
    NSString *fileName = [paraDic objectForKey:@"imgName"];
    NSString *filePath = [paraDic objectForKey:@"imgPath"];
    NSInteger saveOpenId = [paraDic integerValueForKey:@"id" defaultValue:-1];
    UIImage *saveImage = [_allImage objectForKey:[NSNumber numberWithInteger:saveOpenId]];
    __block BOOL flag = YES;
    __block BOOL statusErr;//打开相册权限值
    if (isAlbum) {//保存到相册
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
        __block NSError *blockErr = nil;
        __block NSString *msgErr;
        [library writeImageToSavedPhotosAlbum:saveImage.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            blockErr = error;
            if (error) {
                msgErr = @"0";//保存到相册失败，无操作相册权限
                statusErr = false;
            }else{
                msgErr = @"";//保存到相册成功
                statusErr = true;
            }
            [errDic setObject:[NSNumber numberWithBool:statusErr] forKey:@"statusErr"];
            NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
            [returnDic setObject:[NSNumber numberWithBool:statusErr] forKey:@"status"];
            [errDict setObject:msgErr forKey:@"code"];
            if (flag) {
                [self sendResultEventWithCallbackId:savecbId dataDict:returnDic errDict:errDict doDelete:NO];
            }
        }];
    }

    //保存至filePath
    if (filePath && fileName && saveOpenId){//有filePath&&fileName则保存
        NSString *str = [self getPathWithUZSchemeURL:filePath];
        if (!([fileName.lowercaseString hasSuffix:@"png"]|[fileName.lowercaseString hasSuffix:@"jpg"])) {
            fileName = [NSString stringWithFormat:@"%@.png",fileName];
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:filePath]){
        } else {
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSData *data;
        if (UIImagePNGRepresentation(saveImage) == nil) {
            data = UIImageJPEGRepresentation(saveImage, 0.1);
        } else {
            data = UIImagePNGRepresentation(saveImage);
        }
        //创建路径
        [fileManager createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
        //创建文件
        if (data) {
            [fileManager createFileAtPath:[str stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]] contents:data attributes:nil];
            code = @"";
            status = true;
        } else {
            code = @"-1";
            status = false;
        }
    } else {//filePath为空则取消保存
        code = @"1";//保存到到指定路径失败，无指定保存图片路径
        status = false;
    }
    NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
    [errDict setObject:code forKey:@"code"];
    if (flag) {
        if (isAlbum && fileName && filePath) {
            flag = NO;
        }
        [self sendResultEventWithCallbackId:savecbId dataDict:returnDic errDict:errDict doDelete:NO];
    }
}

#pragma mark -
#pragma mark compress 方法
#pragma mark -
/**
 *  图片压缩方法
 */
- (void)compress:(NSDictionary *)params_ {
    NSInteger compressId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *img = [params_ stringValueForKey:@"img" defaultValue:nil];
    //@"assets-library://asset/asset.JPG?id=BAEA459C-7D20-4A5E-8F55-7A4FBAE87043&ext=JPG";
    UIImage *image = [UIImage imageWithContentsOfFile:[self getPathWithUZSchemeURL:img]];
    if (!image) {//相册内的图片压缩，先读取再压缩保存
        NSURL *url = [[NSURL alloc] initWithString:img];
        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
        
        __weak UZImageFilter *wealSelf = self;
        __block UIImage *imageAss;
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset) {
            //imageAss = [UIImage imageWithCGImage:iref];
            //使用fullResoulutionImage时需传入方向和缩放比例，否则方向和尺寸都不对
            imageAss = [UIImage imageWithCGImage:myasset.defaultRepresentation.fullResolutionImage
                                           scale:myasset.defaultRepresentation.scale
                                     orientation:(UIImageOrientation)myasset.defaultRepresentation.orientation];
            //图片旋转
            imageAss = [wealSelf imageCorrectedForCaptureOrientation:imageAss];
            //创建NSBlockOperation 来执行每一次转换，图片复制等耗时操作
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                [wealSelf compressSave:imageAss saveDict:params_];
            }];
            [self.transPathQueue addOperation:operation];
        };
        ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror) {
            if (!imageAss) {
                NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
                NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
                [returnDic setObject:[NSNumber numberWithBool:NO] forKey:@"status"];
                [errDict setObject:[NSNumber numberWithInt:-1] forKey:@"code"];
                [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
                return;
            }
        };
        [assetslibrary assetForURL:url resultBlock:resultblock failureBlock:failureblock];
    } else {
        __weak UZImageFilter *wealSelf = self;
        //创建NSBlockOperation 来执行每一次转换，图片复制等耗时操作
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [wealSelf compressSave:image saveDict:params_];
        }];
        [self.transPathQueue addOperation:operation];
    }
}

- (void)compressSave:(UIImage *)image saveDict:(NSDictionary *)params_ {
    NSInteger compressId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSDictionary *saveInfo = [params_ dictValueForKey:@"save" defaultValue:nil];
    CGFloat quality = [params_ floatValueForKey:@"quality" defaultValue:0.5];
    if (!image) {//图片读取失败
        NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [returnDic setObject:[NSNumber numberWithBool:NO] forKey:@"status"];
        [errDict setObject:[NSNumber numberWithInt:-1] forKey:@"code"];
        [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
        return;
    }
    NSString *fileName = [saveInfo objectForKey:@"imgName"];
    NSString *filePath = [self getPathWithUZSchemeURL:[saveInfo objectForKey:@"imgPath"]];
    
    //压缩后的大小
    NSDictionary *size = [params_ dictValueForKey:@"size" defaultValue:nil];
    
    //等比例缩放
    float scale = [params_ floatValueForKey:@"scale" defaultValue:1];
    if (!size) {//大小设置优先级高，若无size则以scale为准
        image = [self scaleImage:image toScale:scale];
    } else {
        CGSize reSize = CGSizeMake([size floatValueForKey:@"w" defaultValue:0], [size floatValueForKey:@"h" defaultValue:0]);
        image = [self reSizeImage:image toSize:reSize];
    }
    
    //开始压缩压缩
    NSData *photo = UIImageJPEGRepresentation(image,quality);
    image = [UIImage imageWithData:photo];
    
    //保存到系统相册
    __block BOOL isYes = YES;
    __block BOOL flag = YES;
    if ([saveInfo boolValueForKey:@"album" defaultValue:false]) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
        __block NSError *blockErr = nil;
        __block NSString *msgErr;
        if (image) {
            [library writeImageToSavedPhotosAlbum:image.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
                blockErr = error;
                if (error) {
                    if (filePath && fileName) {
                        msgErr = @"0";//保存到相册失败(无操作相册权限)
                        isYes = false;
                    } else {
                        msgErr = @"2";//保存到相册失败，保存到指定路径失败
                        isYes = false;
                    }
                }else {
                    if (!(filePath && fileName)) {
                        msgErr = @"1";//保存到到指定路径失败，无指定保存图片路径
                        isYes = false;
                    } else {
                        msgErr = @"";//保存到相册成功
                        isYes = true;
                    }

                }
                //回调
                NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
                NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
                [returnDic setObject:[NSNumber numberWithBool:isYes] forKey:@"status"];
                [errDict setObject:msgErr forKey:@"code"];
                if (flag) {
                    [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
                }
            }];
        } else {
            //回调
            NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
            [returnDic setObject:[NSNumber numberWithBool:NO] forKey:@"status"];
            [errDict setObject:[NSNumber numberWithInt:-1] forKey:@"code"];
            [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
        }
    }
    
    //保存至filePath
    if (filePath && fileName) {//有filePath&&fileName则保存
        NSString *str = [self getPathWithUZSchemeURL:filePath];
        if (!([fileName.lowercaseString hasSuffix:@"png"]|[fileName.lowercaseString hasSuffix:@"jpg"]|[fileName.lowercaseString hasSuffix:@"jpeg"])) {
            fileName = [NSString stringWithFormat:@"%@.png",fileName];
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:filePath]){
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        //创建路径
        [fileManager createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
        //创建文件
        if (photo) {
            [fileManager createFileAtPath:[str stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]] contents:photo attributes:nil];
            code = @"";
            status = true;
        }else {
            code = @"-1";
            status = false;
            
            NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
            NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
            [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
            [errDict setObject:code forKey:@"code"];
            [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
        }
    }
    else {//filePath为空则取消保存
        code = @"1";//保存到到指定路径失败，无指定保存图片路径
        status = false;
    }
    if(![saveInfo boolValueForKey:@"album" defaultValue:false]) {
        NSMutableDictionary *returnDic = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary *errDict = [NSMutableDictionary dictionaryWithCapacity:1];
        [returnDic setObject:[NSNumber numberWithBool:status] forKey:@"status"];
        [errDict setObject:code forKey:@"code"];
        [self sendResultEventWithCallbackId:compressId dataDict:returnDic errDict:errDict doDelete:NO];
    }
}

//旋转图片
- (UIImage *)imageCorrectedForCaptureOrientation:(UIImage *)anImage {
    if (anImage.imageOrientation == UIImageOrientationUp) {
        return anImage;
    }
    float rotation_radians = 0;
    bool perpendicular = false;
    switch ([anImage imageOrientation]) {
        case UIImageOrientationDown :
        case UIImageOrientationDownMirrored :
            rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;
            
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);
    
    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - getAttr -
- (void)getAttr:(NSDictionary *)params_ {
    NSString *path = [params_ stringValueForKey:@"path" defaultValue:nil];
    NSInteger getCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    
    if (path.length) {
        UIImage *image = [UIImage imageWithContentsOfFile:[self getPathWithUZSchemeURL:path]];
        float width = image.size.width;
        float height = image.size.height;
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:4];
        [sendDict setObject:[NSNumber numberWithFloat:width] forKey:@"width"];
        [sendDict setObject:[NSNumber numberWithFloat:height] forKey:@"height"];
        [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
        NSData *imageData = [NSData dataWithContentsOfFile:[self getPathWithUZSchemeURL:path]];
        [sendDict setObject:[NSNumber numberWithInteger:imageData.length] forKey:@"size"];
        
        [self sendResultEventWithCallbackId:getCbId dataDict:sendDict errDict:nil doDelete:YES];
    } else {
        NSMutableDictionary *sendDict = [NSMutableDictionary dictionaryWithCapacity:4];
        [sendDict setObject:[NSNumber numberWithBool:NO] forKey:@"status"];
        [self sendResultEventWithCallbackId:getCbId dataDict:sendDict errDict:nil doDelete:YES];
    }
}

@end
