package com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Main;

import android.app.Activity;
import android.app.ProgressDialog;
import android.graphics.Bitmap;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.uzmap.pkg.uzmodules.uzimageFilter.blur.EasyBlur;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.IImageFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Image;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.exception.OOMException;

public class ProcessImageTask extends AsyncTask<Void, Void, Bitmap> {
	private IImageFilter filter;
	private ProgressDialog dialog;
	private Activity a;
	private Bitmap bitmap;
	private String type;
	private int value;

	public ProcessImageTask(Activity activity, Bitmap bitmap, IImageFilter imageFilter, String type, int value) {
		this.filter = imageFilter;
		this.a = activity;
		this.bitmap = bitmap;
		this.type = type;
		this.value = value;
	}

	@Override
	protected void onPreExecute() {
		super.onPreExecute();
		dialog = ProgressDialog.show(a, "", "处理中...");
	}

	public Bitmap doInBackground(Void... params) {
		if (TextUtils.equals(type, "blur")) {
			int radius = 25 * value / 100;
			if (radius == 0) {
				radius = 1;
			}
			Bitmap finalBitmap = EasyBlur.with(a).bitmap(bitmap).radius(radius).scale(1).blur();
			return finalBitmap;
		}
		Image img = null;
		try {
			img = new Image(bitmap);
			if (filter != null) {
				img = filter.process(img);
				img.copyPixelsFromBuffer();
			}
			return img.getImage();
		} catch (OOMException e) {
			dialog.cancel();

			new Handler(Looper.getMainLooper()).post(new Runnable() {
				@Override
				public void run() {
					Toast.makeText(a, "图片太大，处理失败", Toast.LENGTH_LONG).show();
				}
			});

			Log.e("ProcessImageTask", "图片太大，图片处理失败");
			return null;
		} catch (Exception e) {
			System.out.println("process failed!");
			if (img != null && img.destImage.isRecycled()) {
				img.destImage.recycle();
				img.destImage = null;
				System.gc();
			}
		} finally {
			if (img != null && img.image.isRecycled()) {
				img.image.recycle();
				img.image = null;
				System.gc();
			}
		}
		return null;
	}

	@Override
	protected void onPostExecute(Bitmap result) {
		if (result != null) {
			super.onPostExecute(result);
			if (callBack != null) {
				callBack.onResultCallback(result);
			}
		}

		if (dialog != null && dialog.isShowing()) {
			dialog.cancel();
		}
	}

	private ImageProcessCallback callBack;

	public void setCallback(ImageProcessCallback callBack) {
		this.callBack = callBack;
	}
}