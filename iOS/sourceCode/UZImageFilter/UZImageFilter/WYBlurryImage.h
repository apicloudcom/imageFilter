//
//  WYBlurryImage.h
//  UZImageFilter
//
//  Created by wei on 2018/7/6.
//  Copyright © 2018年 starweald. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WYBlurryImage : UIImageView

+(UIImage *)boxblurImage:(UIImage *)image withBlurNumber:(CGFloat)blur;
+(UIImage *)coreBlurImage:(UIImage *)image withBlurNumber:(CGFloat)blur;
@end
