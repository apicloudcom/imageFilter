/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzimageFilter.utils;

import java.io.IOException;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.media.ExifInterface;

public class BitmapToolkit {
	
	/**
     * 读取图片属性：旋转的角度
     * @param path 图片绝对路径
     * @return degree旋转的角度
     */
    public static int readPictureDegree(String path) {
        int degree  = 0;
        try {
                ExifInterface exifInterface = new ExifInterface(path);
                int orientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
                switch (orientation) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                        degree = 90;
                        break;
                case ExifInterface.ORIENTATION_ROTATE_180:
                        degree = 180;
                        break;
                case ExifInterface.ORIENTATION_ROTATE_270:
                        degree = 270;
                        break;
                }
        } catch (IOException e) {
                e.printStackTrace();
        }
        return degree;
    }
    
    
   /**
    * 旋转图片 
    * @param angle 
    * @param bitmap 
    * @return Bitmap 
    */ 
   public static Bitmap rotaingImageView(int angle , Bitmap bitmap) {
	   if(bitmap == null){
		   return null;
	   }
       //旋转图片 动作   
       Matrix matrix = new Matrix();
       matrix.postRotate(angle);
       // 创建新的图片   
       Bitmap resizedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);  
       return resizedBitmap; 
   }
   
   /**
    * 旋转图片 
    * @param angle 
    * @param bitmap 
    * @return Bitmap 
    */ 
   public static Bitmap scaleBitmap(float scale , Bitmap bitmap) {
	   if(bitmap == null){
		   return null;
	   }
	   
	   //旋转图片 动作   
       Matrix matrix = new Matrix();
       matrix.postScale(scale, scale);
       
       // 创建新的图片   
       Bitmap resizedBitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(),matrix ,false);  
       return resizedBitmap;
   }
   
   
   public static Bitmap scaleBitmapWithSize(Bitmap bitmap ,int width ,int height){
	   
	   if(bitmap == null){
		   return null;
	   }
	   
	   if(width > bitmap.getWidth() || height > bitmap.getHeight()){
		   return null;
	   }
       
       // 创建新的图片  
       Bitmap resizedBitmap = Bitmap.createScaledBitmap(bitmap, width, height, false);
       return resizedBitmap;
   }
   
}
