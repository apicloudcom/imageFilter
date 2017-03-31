# **概述**

图片过滤模块（内含iOS和android）

APICloud 的 imageFilter 模块是一个图片滤镜。本模块有图片过滤、图片压缩及获取图片信息的功能。

# **模块接口文档**

<p style="color: #ccc; margin-bottom: 30px;">来自于：APICloud 官方</p>

<ul id="tab" class="clearfix">
	<li class="active"><a href="#method-content">Method</a></li>
	<li><a href="#const-content">Constant</a></li>
</ul>

<div class="outline">

[open](#open)
[filter](#filter)
[save](#save)
[compress](#compress)
[getAttr](#getAttr)

</div>

# **模块概述**

imageFilter 模块封装了对图片按照指定效果过滤的功能，过滤后的图片可保存到指定目录。另外通过本模块的 getAttr 接口可获取制定图片的大小等信息，compress 接口可实现压缩图片的相关功能。

![图片说明](http://docs.apicloud.com/img/docImage/imageFilter.jpg)

<div id="open"></div>

# **open**

打开图片过滤器

open({params}, callback(ret, err))

## params

imgPath：

- 类型：字符串
- 默认值：无
- 描述：原图片路径，支持 fs，widget 等本地协议

## callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
	status:       //操作成功状态值
	id:          //打开图片对象的 id
}
```

err：

- 类型：JSON 对象
- 内部字段：

```js
{
	code:       	//错误描述，取值范围如下：
					-1：		//未知错误
					0：			//imgPath 为空
					1：			//imgPath 路径下的图片不存在
					2：			//图片读取失败
}
```

## 示例代码

```js
var imageFilter = api.require('imageFilter');
imageFilter.open({
    imgPath: 'widget://res/img/apicloud.png'
}, function(ret, err) {
    if (ret.status) {
        alert(JSON.stringify(ret));
    } else {
        alert(JSON.stringify(err));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="filter"></div>

# **filter**

设置图片滤镜效果

filter({params}, callback(ret, err))

## params

type：

- 类型：字符串
- 默认值：default
- 描述：（可选项）要设置的图片滤镜效果，详情参考[滤镜效果](#filterresult)

value：

- 类型：数字类型
- 默认值：60
- 描述：（可选项）要设置的图片滤镜效果程度，取值范围1-100

id：

- 类型：数字类型
- 默认值：无
- 描述：要操作的图片的 id

## callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
	status:              //操作成功状态值
	path:                //初步滤镜后的缩略图图片路径，字符串类型缩略图大小为50*50
}
```

err：

- 类型：JSON 对象
- 内部字段：

```js
{
	code:      	   		//错误描述，取值范围如下:
						-1:			    //未知错误
						0：		            //type不支持
						1：		            //value非法
						2：		            //图片过滤器尚未open初始化
						3:                          //id不存在
}
```

## 示例代码

```js
var imageFilter = api.require('imageFilter');
imageFilter.filter({
    id: 1,
    type: 'autumn'
}, function(ret, err) {
    if (ret.status) {
        alert(JSON.stringify(ret));
    } else {
        alert(JSON.stringify(err));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="save"></div>

# **save**

保存最终处理结果

save({params}, callback(ret, err))

## params

album：

- 类型：布尔类型
- 默认值：false
- 描述：（可选项）是否保存到系统相册

imgPath：

- 类型：字符串类型
- 默认值：无
- 描述：（可选项）保存的图片路径，若路径不存在文件夹则创建此目录
- 备注：不传或传空则不保存

imgName：

- 类型：字符串类型
- 默认值：无
- 描述：（可选项）保存的图片名字，支持 png 和 jpg 格式，若不指定格式，则默认 png
- 备注：不传或传空则不保存

id：

- 类型：数字类型
- 默认值：无
- 描述：要操作的图片的 id

## callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
	{
		status:              //操作成功状态值
	}
```

err：

- 类型：JSON 对象
- 内部字段：

```js
{
	code:               //错误描述，取值范围如下：
						-1:				//未知错误
						0：				//保存到相册失败，无权限访问系统相册
						1：				//保存到指定路径失败，无指定保存路径
						2：				//id不存在
}
```

## 示例代码

```js
var imageFilter = api.require('imageFilter');
imageFilter.save(function(ret, err) {
    if (ret.status) {
        alert(JSON.stringify(ret));
    } else {
        alert(JSON.stringify(err));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="compress"></div>

# **compress**

图片压缩处理

compress({params}, callback(ret, err))

## params

img：

- 类型：字符串
- 描述：要压缩图片的路径，支持 widget、fs 等本地路径

quality：

- 类型：数字
- 默认值：0.5
- 描述：（可选项）压缩程度，取值范围：0-1

scale：

- 类型：数字
- 默认值：1
- 描述：（可选项）压缩后的图片缩放比例，取值范围大于0，
- 备注：若 size 参数有值，则忽略本参数

size：

- 类型：JSON 对象
- 描述：（可选项）压缩后的图片的大小
- 备注：若本参数有值，则忽略scale
- 内部字段：

```js
  {
    w：    		//压缩后的图片的宽，数字类型，无默认值
    h:    		//压缩后的图片的高，数字类型，无默认值
  }
  ```

save：

- 类型：JSON 对象
- 默认值：见内部字段
- 描述：（可选项）压缩后的图片保存位置
- 内部字段：

```js
{
       album:            	//(可选项)布尔值，是否保存到系统相册，默认 false 
       imgPath:          	//(可选项)保存的文件路径,字符串类型，无默认值,不传或传空则不保存，若路径不存在文件夹则创建此目录
       imgName:         	//(可选项)保存的图片名字，支持 png 和 jpg 格式，若不指定格式，则默认 png，字符串类型，无默认值,不传或传空则不保存
                           
}
```

## callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
	{
		status:              //操作成功状态值
	}
```

err：

- 类型：JSON 对象
- 内部字段：

```js
{
	code:              //错误描述，取值范围如下：
	                     -1://未知错误
	                      0：//保存到相册失败
	                      1：//保存到指定路径失败
	                      2：//保存到相册和指定路径失败
}
```

## 示例代码

```js
var imageFilter = api.require('imageFilter');
imageFilter.compress({
    img: 'widget://res/img/apicloud.png',
    quality: 0.1
}, function(ret, err) {
    if (ret.status) {
        alert(JSON.stringify(ret));
    } else {
        alert(JSON.stringify(err));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="getAttr"></div>

# **getAttr**

获取指定路径下的图片信息

getAttr({params}, callback(ret))

## params

path：

- 类型：字符串
- 描述：目标图片的路径，支持 fs 等本地路径

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
	{
		status:        //布尔类型；操作成功状态值
		width:         //数字类型；获取的图片的宽
		height:        //数字类型；获取的图片的高
		size:          //数字类型；获取的图片文件的大小，单位：byte
	}
```

##示例代码

```js
var imageFilter = api.require('imageFilter');
imageFilter.getAttr({
    path: 'widget://res/img/apicloud.png'
}, function(ret, err) {
    if (ret.status) {
        alert(JSON.stringify(ret));
    } else {
        alert(JSON.stringify(err));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="filterresult"></div>

# **滤镜效果**

图片过滤的效果类型。字符串类型

## 取值范围：

- black_white   //黑白
- blur          //模糊
- default       //原图效果

**android特有效果：**

- color_pencil  //
- dream         //
- engrave       //
- film          //
- fresh         //
- rainbow       //

**iOS特有效果：**

- emerald        	//绿宝石(无value)
- bright       		//光亮(无value)
- color_pencil  	//彩色
- dream         	//梦幻
- autumn       		//秋色
- film          	//电影
- lemo			   	//柠檬
- ancient			//复古
- gothic			//哥特
- sharpColor		//锐色
- elegant			//淡雅
- redWine			//酒红
- lime				//青柠
- romantic			//浪漫
- halo				//光晕
- blues				//蓝调
- nightScene		//夜色
