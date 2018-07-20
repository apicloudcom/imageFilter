/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.uzimageFilter;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.text.TextUtils;
import android.util.Log;

import com.uzmap.pkg.uzcore.UZCoreUtil;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzkit.UZUtility;
import com.uzmap.pkg.uzmodules.uzimageFilter.blur.EasyBlur;
import com.uzmap.pkg.uzmodules.uzimageFilter.compress.Compressor;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.IImageFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Main.FilterFactory;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Main.ImageProcessCallback;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Main.ProcessImageTask;
import com.uzmap.pkg.uzmodules.uzimageFilter.utils.BitmapSize;
import com.uzmap.pkg.uzmodules.uzimageFilter.utils.BitmapToolkit;

public class uzimageFilter extends UZModule {

	public static final int OPEN_UNKNOWN = -1;
	public static final int OPEN_PATH_NULL = 0;
	public static final int OPEN_PATH_INEXISTENCE = 1;
	public static final int OPEN_IMAGE_FAILED = 2;

	public static final int FILTER_UNKNOWN = -1;
	public static final int FILTER_TYPE_UNSUPPORT = 0;
	public static final int FILTER_VALUE_INVAILED = 1;
	public static final int FILTER_NO_INIT = 2;
	public static final int FILTER_ID_INEXISTENCE = 3;
	
	public static final int SAVE_UNKNOWN = -1;
	public static final int SAVE_ALBUM_FAILED = 0;
	public static final int SAVE_FAILED = 1;
	public static final int SAVE_ID_INEXISTENCE = 2;

	public static final int CALLBACK_FOR_OPEN = 0;
	public static final int CALLBACK_FOR_FILTER = 1;
	public static final int CALLBACK_FOR_SAVE = 2;

	public static final int THUMNAIL_WIDTH = 50;
	public static final int THUMNAIL_HEIGHT = 50;

	private HashMap<Integer, Bitmap> bitmaps;

	private final String THUMNAIL_PATH = "fs://uzCache";

	private static String[] types = {
		
		"black_white", 
		"color_pencil", 
		"dream", 
		"engrave",
		"film", 
		"fresh",
		"rainbow", 
		"blur", 
		"default"
		
	};

	@SuppressLint("UseSparseArrays")
	public uzimageFilter(UZWebView webView) {
		super(webView);
		bitmaps = new HashMap<Integer, Bitmap>();
	}

	public void jsmethod_getAttr(UZModuleContext uzContext) {
		String imgPath = uzContext.optString("path", null);
		if (TextUtils.isEmpty(imgPath)) {
			failedCallback(uzContext);
			return;
		}
		InputStream input = null;
		File file = new File(imgPath);
		long size = 0;
		if (file.exists()) {
			try {
				input = new FileInputStream(file);
				size = file.length();
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		} else {
			String realPath = makeRealPath(imgPath);
			try {
				input = UZUtility.guessInputStream(realPath);
				size = input.available();
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		if (null == input) {
			failedCallback(uzContext);
			return;
		}
		try {
			BitmapFactory.Options opts = new BitmapFactory.Options();
			opts.inJustDecodeBounds = true;
			BitmapFactory.decodeStream(input, null, opts);
			int width = opts.outWidth;
			int height = opts.outHeight;
			JSONObject ret = new JSONObject();
			ret.put("status", true);
			ret.put("size", size);
			ret.put("width", width);
			ret.put("height", height);
			uzContext.success(ret, false);
		} catch (Exception e) {
			e.printStackTrace();
			failedCallback(uzContext);
		} finally {
			try {
				input.close();
			} catch (IOException e) {
				;
			}
		}
	}


	public void failedCallback(UZModuleContext uzContext) {
		JSONObject err = new JSONObject();
		try {
			err.put("status", false);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		uzContext.success(err, false);
	}
	
	@SuppressLint("NewApi")
	public void jsmethod_open(final UZModuleContext moduleContext) {

		if (moduleContext.isNull("imgPath")) {
			createErrorCallback(moduleContext, OPEN_PATH_NULL,
					CALLBACK_FOR_OPEN);
			return;
		}

		final String imagePath = moduleContext.optString("imgPath");
		if (TextUtils.isEmpty(imagePath)) {
			createErrorCallback(moduleContext, OPEN_PATH_INEXISTENCE,
					CALLBACK_FOR_OPEN);
			return;
		}

		new Thread(new Runnable() {

			@SuppressWarnings("deprecation")
			@Override
			public void run() {
				
				String realPath = makeRealPath(imagePath);
				Bitmap bitmap = null;
				InputStream input = null;
				try {
					input = UZUtility.guessInputStream(realPath);
				} catch (IOException e) {
					return;
				}

				BitmapFactory.Options newOpts = new BitmapFactory.Options();
				newOpts.inJustDecodeBounds = true;
				bitmap = BitmapFactory.decodeStream(input, null, newOpts);

				newOpts.inJustDecodeBounds = false;
				int w = newOpts.outWidth;
				int h = newOpts.outHeight;
				float hh = 800f;//
				float ww = 480f;//
				int be = 1;
				if (w > h && w > ww) {
					be = (int) (newOpts.outWidth / ww);
				} else if (w < h && h > hh) {
					be = (int) (newOpts.outHeight / hh);
				}
				if (be <= 0)
					be = 1;
				newOpts.inSampleSize = be;

				newOpts.inPreferredConfig = Config.ARGB_8888;
				newOpts.inPurgeable = true;
				newOpts.inInputShareable = true;

				InputStream inputNext = null;
				try {
					inputNext = UZUtility.guessInputStream(realPath);
				} catch (IOException e) {
					return;
				}
				
				bitmap = BitmapFactory.decodeStream(inputNext, null, newOpts);
				if (bitmap == null) {
					createErrorCallback(moduleContext, OPEN_IMAGE_FAILED, CALLBACK_FOR_OPEN);
					return;
				}
				Bitmap bitmap1 = UZUtility.getLocalImage(realPath);
				
				int id = bitmap1.hashCode();
				bitmaps.put(id, bitmap1);
				createSuccessCallback(moduleContext, id, "", CALLBACK_FOR_OPEN);
			}

		}).start();
	}

	private FileOutputStream outStream;

	public void jsmethod_filter(final UZModuleContext moduleContext) {
		String type = moduleContext.optString("type");
		int value = moduleContext.optInt("value");
		final int id = moduleContext.optInt("id");
		if (TextUtils.isEmpty(type)) {
			type = "default";
		}
		String mType = checkType(type);
		if (!TextUtils.isEmpty(mType)) {

			final Bitmap bitmap = bitmaps.get(id);
			if (bitmap != null) {
				if (value < 0 || value > 100) {
					createErrorCallback(moduleContext, FILTER_VALUE_INVAILED,
							CALLBACK_FOR_FILTER);
					return;
				}
				if (type.equals("default")) {
					File savePath = new File(generatePath(THUMNAIL_PATH));
					if (!savePath.exists()) {
						savePath.mkdirs();
					}
					File saveFile = new File(savePath, "thumnail.png");
					try {
						outStream = new FileOutputStream(saveFile);
						Bitmap thumnail = ThumbnailUtils.extractThumbnail(
								bitmap, THUMNAIL_WIDTH, THUMNAIL_HEIGHT);
						thumnail.compress(CompressFormat.PNG, 100, outStream);
						createSuccessCallback(moduleContext, 0,
								savePath.getAbsolutePath(), CALLBACK_FOR_FILTER);
					} catch (FileNotFoundException e) {
						createErrorCallback(moduleContext, FILTER_UNKNOWN,
								CALLBACK_FOR_FILTER);
						e.printStackTrace();
					}
					return;
				}
				
				Activity activity = (Activity) moduleContext.getContext();
				IImageFilter filter = FilterFactory.createFilter(mType, value);
				ProcessImageTask task = new ProcessImageTask(activity, bitmap, filter, type, value);
				task.setCallback(new ImageProcessCallback() {
					@Override
					public void onResultCallback(Bitmap tmpbitmap) {
						if (tmpbitmap != null) {
							if (bitmap != null && !bitmap.isRecycled()) {
								//bitmap.recycle();
							}
							bitmaps.put(id, tmpbitmap);

							File savePath = new File(
									generatePath(THUMNAIL_PATH));
							if (!savePath.exists()) {
								savePath.mkdirs();
							}
							File saveFile = new File(savePath, "thumnail.png");
							try {
								outStream = new FileOutputStream(saveFile);
								Bitmap thumnail = ThumbnailUtils
										.extractThumbnail(tmpbitmap,
												THUMNAIL_WIDTH, THUMNAIL_HEIGHT);
								thumnail.compress(CompressFormat.PNG, 100,
										outStream);
								createSuccessCallback(moduleContext, 0,
										saveFile.getAbsolutePath(),
										CALLBACK_FOR_FILTER);
							} catch (FileNotFoundException e) {
								createErrorCallback(moduleContext,
										FILTER_UNKNOWN, CALLBACK_FOR_FILTER);
								e.printStackTrace();
							}
						}
					}
				});
				task.execute();
			} else {
				createErrorCallback(moduleContext, FILTER_ID_INEXISTENCE,
						CALLBACK_FOR_FILTER);
			}
		} else {
			createErrorCallback(moduleContext, FILTER_TYPE_UNSUPPORT,
					CALLBACK_FOR_FILTER);
		}
	}

	public void jsmethod_save(final UZModuleContext moduleContext) {

		final boolean album = moduleContext.optBoolean("album");
		final String imgPath = generatePath(moduleContext.optString("imgPath"));
		final String imgName = moduleContext.optString("imgName");
		int id = moduleContext.optInt("id");

		final Bitmap bitmap = bitmaps.get(id);

		if (bitmap != null) {
			if (album) {
				final File mediaStorageDir = new File(
						Environment
								.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
								+ "/Camera");
				if (!mediaStorageDir.exists()) {
					mediaStorageDir.mkdirs();
				}
				new Thread(new Runnable() {

					@Override
					public void run() {
						Bitmap finalBitmap = EasyBlur.with(context()).bitmap(bitmap).radius(25).scale(1).blur();
						saveImage(moduleContext, finalBitmap, mediaStorageDir,
								UZCoreUtil.formatDate(System.currentTimeMillis()) + ".png", true);
					}
				}).start();

			}
			
			if (!TextUtils.isEmpty(imgPath) && !TextUtils.isEmpty(imgName)) {

				final File path = new File(imgPath);
				if (!path.exists()) {
					path.mkdirs();
				}
				new Thread(new Runnable() {
					@Override
					public void run() {
						Bitmap finalBitmap = EasyBlur.with(context()).bitmap(bitmap).radius(25).scale(1).blur();
						saveImage(moduleContext, finalBitmap, path, imgName, false);
					}
				}).start();

			} else {
				createErrorCallback(moduleContext, SAVE_FAILED,
						CALLBACK_FOR_SAVE);
			}
		} else {
			createErrorCallback(moduleContext, SAVE_ID_INEXISTENCE,
					CALLBACK_FOR_SAVE);
		}
	}
	

	public void jsmethod_compress(final UZModuleContext context) {

		new Thread(new Runnable() {
			@Override
			public void run() {
				String imgPath = context.optString("img");
				if (TextUtils.isEmpty(imgPath)) {
					createErrorCallback(context, 3, -1);
					return;
				}
				final double quality = context.optDouble("quality", 0.1);
				float scale = -1;
				if (!context.isNull("scale") && context.isNull("size")) {
					scale = (float) context.optDouble("scale", 1.0);
				}
				BitmapSize mSize = null;
				if (!context.isNull("size")) {
					JSONObject sizeObj = context.optJSONObject("size");
					if (sizeObj != null) {
						int w = sizeObj.optInt("w");
						int h = sizeObj.optInt("h");
						mSize = new BitmapSize(w, h);
					}
				}
				final JSONObject saveObj = context.optJSONObject("save");
				Bitmap bitmap = null;
				String saveImgPath = null;
				boolean album = false;
				String imgName = null;

				if (saveObj != null) {
					
					album = saveObj.optBoolean("album");
					saveImgPath = context.makeRealPath(saveObj.optString("imgPath"));
					imgName = saveObj.optString("imgName");
					bitmap = getBitmap(context, imgPath);

				} else {
					createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
					return;
				}

				int degree = BitmapToolkit.readPictureDegree(generatePath(imgPath));
				bitmap = BitmapToolkit.rotaingImageView(degree, bitmap);
				if (bitmap == null) {
					createErrorCallback(context, 3, -1);
					return;
				}
				compressImage(context, bitmap, saveImgPath, imgName, quality,
						scale, album, mSize);
			}
		}).start();

	}
	
	
	public void jsmethod_compress1(UZModuleContext moduleContext) {
		try {
			File file = new Compressor(context())
					.setDestinationDirectoryPath("/storage/emulated/0/Music/")
					.setQuality(75)
					.setMaxWidth(150)
		            .setMaxHeight(150)
		            .setCompressFormat(Bitmap.CompressFormat.PNG)
					.compressToFile(new File("/storage/emulated/0/qq.png"));
			Log.e("TAG", file.getAbsolutePath());
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public void compressImage(UZModuleContext context, Bitmap image,
			String path, String imgName, double quality, float scale,
			boolean saveAlbum, BitmapSize mSize) {

		if (TextUtils.isEmpty(imgName)) {
			imgName = "" + System.currentTimeMillis() + ".jpg";
		}

		if (!TextUtils.isEmpty(imgName)
				&& (!imgName.endsWith(".jpg") && !imgName.endsWith(".png") && !imgName
						.endsWith(".jpeg"))) {
			imgName = imgName + ".jpg";
		}

		// post scale
		if (scale >= 0) {
			image = BitmapToolkit.scaleBitmap(scale, image);
		}
		// post scale with size
		if (mSize != null) {
			image = BitmapToolkit.scaleBitmapWithSize(image, mSize.width,
					mSize.height);
			if (image == null) {
				createErrorCallBack(context, "params invalidate size ！");
				return;
			}
		}

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		if (quality == 1) {
			quality -= 0.1;
		}
		int options = (int)(quality * 100);

		// int maxSize = (int) (1024 * quality);
		
		if (image == null) {
			return;
		}
		
		if (imgName.endsWith(".jpg") || imgName.endsWith(".jpeg")) {
			image.compress(Bitmap.CompressFormat.JPEG, options, baos);
		} else {
			image.compress(Bitmap.CompressFormat.PNG, options, baos);
		}
		
		if (saveAlbum) {
			final File mediaStorageDir = new File(
					Environment
							.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
							+ "/Camera");
			if (!mediaStorageDir.exists()) {
				mediaStorageDir.mkdirs();
			}
			File savePath = new File(mediaStorageDir, imgName);
			try {
				FileOutputStream fos = new FileOutputStream(savePath);
				fos.write(baos.toByteArray());
				fos.flush();
				fos.close();

				createSuccessCallback(context, 0, "", CALLBACK_FOR_SAVE);
			} catch (FileNotFoundException e) {
				createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
				e.printStackTrace();
			} catch (IOException e) {
				createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
				e.printStackTrace();
			}
		}
		
		if(TextUtils.isEmpty(path)){
			return;
		}

		File saveToSDcardPath = new File(path);
		if(!saveToSDcardPath.exists()){
			saveToSDcardPath.mkdirs();
		}
		File realSavePath = new File(saveToSDcardPath, imgName);
		
		try {
			FileOutputStream fos = new FileOutputStream(realSavePath);
			fos.write(baos.toByteArray());
			fos.flush();
			fos.close();

			if(!saveAlbum){
				createSuccessCallback(context, 0, "", CALLBACK_FOR_SAVE);
			}
		} catch (FileNotFoundException e) {
			createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
			e.printStackTrace();
		} catch (IOException e) {
			createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
			e.printStackTrace();
		}
	}
	

	public void saveImage(UZModuleContext context, Bitmap bitmap, File path,
			String imgName, boolean callback) {

		FileOutputStream outStream;
		try {
			File savePath;
			if (imgName != null && imgName.endsWith(".jpg")) {

				savePath = new File(path, imgName);
				outStream = new FileOutputStream(savePath);
				bitmap.compress(CompressFormat.JPEG, 100, outStream);

			} else if (imgName != null && imgName.endsWith(".png")) {

				savePath = new File(path, imgName);
				outStream = new FileOutputStream(savePath);
				bitmap.compress(CompressFormat.PNG, 100, outStream);

			} else {
				if (imgName.endsWith(".")) {
					imgName += "png";
				} else {
					imgName += ".png";
				}
				savePath = new File(path, imgName);
				outStream = new FileOutputStream(savePath);
				bitmap.compress(CompressFormat.PNG, 100, outStream);
			}
			
			if (callback) {
				if (imgName.endsWith(".")) {
					imgName += "png";
				} else {
					imgName += ".png";
				}
				sendBradcase(savePath);
			}

			if (outStream != null) {
				outStream.close();
			}
			createSuccessCallback(context, 0, "", CALLBACK_FOR_SAVE);

		} catch (FileNotFoundException e) {
			createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
		} catch (IOException e) {
			createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
		}
	}
	
	private void sendBradcase(File file) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
			sendBroadcastUpKitkat(file);
		} else {
			sendBroadcastDownKitkat();
		}
	}
	
	private void sendBroadcastUpKitkat(File file) {
		Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
		Uri contentUri = Uri.fromFile(file);
		mediaScanIntent.setData(contentUri);
		context().sendBroadcast(mediaScanIntent);
	}

	private void sendBroadcastDownKitkat() {
		context().sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED,
				Uri.parse("file://" + Environment.getExternalStorageDirectory())));
	}
	
	public static void copyfile(File fromFile, File toFile) {
		if (!fromFile.exists()) {
			return;
		}
		if (!fromFile.isFile()) {
			return;
		}
		if (!fromFile.canRead()) {
			return;
		}
		if (!toFile.getParentFile().exists()) {
			toFile.getParentFile().mkdirs();
		}
		if (toFile.exists()) {
			toFile.delete();
		}
		try {
			FileInputStream fosfrom = new FileInputStream(fromFile);
			FileOutputStream fosto = new FileOutputStream(toFile);
			byte[] bt = new byte[1024];
			int c;
			while ((c = fosfrom.read(bt)) > 0) {
				fosto.write(bt, 0, c);
			}
			fosfrom.close();
			fosto.close();
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	public String checkType(String type) {
		if (TextUtils.isEmpty(type)) {
			return null;
		}
		for (String mType : types) {
			if (type.trim().equals(mType)) {
				return mType;
			}
		}
		return null;
	}

	public String generatePath(String pathname) {
		if(new File(pathname).exists()){
			return pathname;
		}
		String path = makeRealPath(pathname);
		String tmpPath = path.replaceFirst("file://", "");
		return tmpPath;
	}

	public void createErrorCallback(UZModuleContext moduleContext,
			int errorCode, int type) {

		JSONObject retJson = new JSONObject();
		JSONObject errJson = new JSONObject();

		try {
			retJson.put("status", false);
			if (type == CALLBACK_FOR_OPEN) {
				retJson.put("id", "" + -1);
			}
			if (type == CALLBACK_FOR_FILTER) {
				retJson.put("path", "");
			}
			errJson.put("code", errorCode);
		} catch (JSONException e) {
			e.printStackTrace();
		}

		moduleContext.error(retJson, errJson, false);
	}

	public void createSuccessCallback(UZModuleContext moduleContext, int id,
			String path, int type) {
		JSONObject retJson = new JSONObject();

		try {
			retJson.put("status", true);
			if (type == CALLBACK_FOR_OPEN) {
				retJson.put("id", id);
			}
			if (type == CALLBACK_FOR_FILTER) {
				retJson.put("path", path);
			}
			if (type == CALLBACK_FOR_SAVE) {

			}
		} catch (JSONException e) {
			e.printStackTrace();
		}

		moduleContext.success(retJson, false);
	}

	@Override
	protected void onClean() {
		super.onClean();
		for (Integer key : bitmaps.keySet()) {
			Bitmap bitmap = bitmaps.get(key);
			if (bitmap != null && !bitmap.isRecycled()) {
				bitmap.recycle();
			}
		}
	}

	public String createThumnailImage(UZModuleContext context, Bitmap bitmap,
			String path) {
		Bitmap thumnail = ThumbnailUtils.extractThumbnail(bitmap,
				THUMNAIL_WIDTH, THUMNAIL_HEIGHT);
		String thumnailPath = generatePath(path);
		File file = new File(thumnailPath);
		if (!file.exists()) {
			file.mkdirs();
		}
		saveImage(context, thumnail, file, "thumnail.png", false);
		return new File(file, "thumnail.png").getAbsolutePath();
	}

	
	public Bitmap getBitmap(final UZModuleContext context, String imgPath) {

		if (TextUtils.isEmpty(imgPath)) {
			createErrorCallback(context, SAVE_FAILED, CALLBACK_FOR_SAVE);
			return null;
		}

		File imageFile = new File(imgPath);

		Bitmap bitmap = null;
		InputStream input = null;

		if (imageFile.exists()) {

			try {
				input = new FileInputStream(imageFile);
				bitmap = BitmapFactory.decodeStream(input);
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}

		} else {
			bitmap = UZUtility.getLocalImage(context.makeRealPath(imgPath));
		}

		if (input != null) {
			try {
				input.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		return bitmap;
	}

	public void createErrorCallBack(UZModuleContext context, String msg) {
		JSONObject retObj = new JSONObject();
		try {
			retObj.put("msg", msg);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		context.success(retObj, false);
	}
}