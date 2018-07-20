package com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.Main;

import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.BlackWhiteFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.FilmFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.GammaFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.HslModifyFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.IImageFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.LensFlareFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.RainBowFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.ReliefFilter;
import com.uzmap.pkg.uzmodules.uzimageFilter.imageFilter.ZoomBlurFilter;

public class FilterFactory {
	
	public static IImageFilter createFilter(String filterName , int value){
		if("black_white".equals(filterName)){
			return new BlackWhiteFilter();
		} else if("autumn".equals(filterName)){
			return new BlackWhiteFilter();
		} else if("color_pencil".equals(filterName)){
			return new LensFlareFilter();
		} else if("dream".equals(filterName)){
			return new GammaFilter(value);
		} else if("engrave".equals(filterName)){
			return new ReliefFilter();
		} else if("film".equals(filterName)){
			return new FilmFilter(value);
		} else if("fresh".equals(filterName)){
			return new HslModifyFilter(value);
		} else if("rainbow".equals(filterName)){
			return new RainBowFilter();
		} else if("blur".equals(filterName)){
			return new ZoomBlurFilter(value);
		}
		return null;
	}
}
