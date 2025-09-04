---
title: "什么是viewport | 编程码农"
date: "2021-10-27 15:34:10"
description: "设备像素和CSS像素 设备像素（device pixels）也叫做设备物理像素是一个具体可测量的物理单位。 CSS 像素是与设备无关的像素，这一类像素也叫做独立设备像素（Device-independent pixel），它们是应用程序的抽象单位。当应用程序运行时，底层图形系统会按照一定的比例（设备..."
tags:
  - "前端"
  - "HTML"
  - "CSS"
categories:
  - "前端开发"
keywords:
  - "前端开发"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

## 设备像素和CSS像素

**设备像素**（device pixels）也叫做**设备物理像素**是一个具体可测量的物理单位。

CSS 像素是与设备无关的像素，这一类像素也叫做**独立设备像素**（Device-independent pixel），它们是应用程序的抽象单位。当应用程序运行时，底层图形系统会按照**一定的比例**（设备物理像素和设备独立像素比）将应用程序的抽象像素转换为适用于设备的物理像素。

**设备物理像素**和**设备独立像素**的比例，$dp$ 设备物理像素，$dips$ 设备独立像素。
$$
dpr = \frac{dp}{dips}
$$
将 CSS 布局中的`px`是相对于物理像素的单位，在大多数浏览器中，通过 `window.devicePixelRatio` 可以得到物理像素与它的比率。比如在 iPhone6 上分辨率750x1334，它的`window.devicePixelRatio=2` 所以它屏幕宽度为375px，共有750个物理像素，即1px代表两个物理像素。

下面是 `window.devicePixelRatio` 浏览器的兼容性。

![image-20211029145641205](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211029145641205.png)



## 视口(Viewport)

浏览器中的 **viewport **和`<html>`区域相同，可以看作是`<html>`上层的包含块。在大多数移动设备中，浏览器是全屏的，所以 viewport 是整个屏幕的大小。

![image-20211029172011616](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211029172011616.png)



视口中经常需要区分**布局视口（layout viewport），视觉视口（visual viewport）和理想视口（ideal viewport）**

**布局视口**可以看作是CSS布局时的画布，**视觉视口**是当前显示的页面区域，**理想视口**是页面在设备最佳的呈现。



![image-20211029233119890](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211029233119890.png)



理想的呈现方式是终极目标，可以使用户体验大大提升，特别是在非PC设备上，理想的状态意味着：

- 布局视口宽度 = 视觉视口宽度 = 设备宽度。

如果**布局视口宽度 ≠ 视觉视口宽度**， 出现的情况就是内容过宽，用户可能就需要缩放来查看内容，缩小后，看起来费劲，放大后需要左右滑动查看。



### 移动设备

移动浏览器和桌面浏览器最大的区别是屏幕宽度小很多，对于很多针对PC设计的网页会因为宽度变窄而显示错乱。

因为移动设备浏览器认为自己必须能让所有的网站都正常显示，这包括了很多PC端网站，所以各移动浏览器厂商统一将设备默认**布局视口**设置为 980px。

![image-20211030140613162](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211030140613162.png)

比如在宽 375px 的 iphone6 上显示一个宽为 980px 的页面，大多数浏览器为了让页面显示全而缩小页面。

![image-20211030004356844](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211030004356844.png)

我们可以使用`meta viewport`让浏览器**布局视区**等于屏幕宽度也就是375px，这样显示出来就是理想效果。

```html
 <meta name="viewport" content="width=device-width"/>
```



![image-20211030005300665](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211030005300665.png)

下面这个`meta`是我们在开发移动设备的网站最常用的。

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
```

该`meta`标签的作用是让当前**布局视口**的宽度等于设备的宽度，同时不允许用户手动缩放。

`meta viewport` 标签首先是由苹果公司在其`safari`浏览器中引入的，目的就是解决移动设备的`viewport`问题。后来安卓以及各大浏览器厂商也都纷纷效仿，引入对`meta viewport`的支持，事实也证明这个东西还是非常有用的。

下面是一些设备的分辨率和视口大小：

| 设备                           | **视口大小 （宽x高）** | **设备分辨率（宽x高）** |
| :----------------------------- | :--------------------- | :---------------------- |
| iPhone 12                      | 390 x 844              | 1170 x 2532             |
| iPhone 12 Mini                 | 360 x 780              | 1080 x 2340             |
| iPhone 12 Pro                  | 390 x 844              | 1170 x 2532             |
| iPhone 12 Pro Max              | 428 x 926              | 1248 x 2778             |
| iPhone SE                      | 214 x 379              | 640 x 1136              |
| iPhone 11 Pro Max              | 414 x 896              | 1242 x 2688             |
| iPhone 11 Xs Max               | 414 x 896              | 1242 x 2688             |
| iPhone 11                      | 414 x 896              | 828 x 1792              |
| iPhone 11 Xr                   | 414 x 896              | 828 x 1792              |
| iPhone 11 Pro                  | 375 x 812              | 1125 x 2436             |
| iPhone 11 X                    | 375 x 812              | 1125 x 2436             |
| iPhone 11 Xs                   | 375 x 812              | 1125 x 2436             |
| iPhone X                       | 375 x 812              | 1125 x 2436             |
| iPhone 8 Plus                  | 414 x 736              | 1080 x 1920             |
| iPhone 8                       | 375 x 667              | 750 x 1334              |
| iPhone 7 Plus                  | 414 x 736              | 1080 x 1920             |
| iPhone 7                       | 375 x 667              | 750 x 1334              |
| iPhone 6s Plus                 | 414 x 736              | 1080 x 1920             |
| iPhone 6s                      | 375 x 667              | 750 x 1334              |
| iPhone 6 Plus                  | 414 x 736              | 1080 x 1920             |
| iPhone 6                       | 375 x 667              | 750 x 1334              |
| iPad Pro                       | 1024 x 1366            | 2048 x 2732             |
| iPad Third & Fourth Generation | 768 x 1024             | 1536 x 2048             |
| iPad Air 1 & 2                 | 768 x 1024             | 1536 x 2048             |
| iPad Mini                      | 768 x 1024             | 768 x 1024              |
| iPad Mini 2 & 3                | 768 x 1024             | 1536 x 2048             |
| Nexus 6P                       | 411 x 731              | 1440 x 2560             |
| Nexus 5X                       | 411 x 731              | 1080 x 1920             |
| Google Pixel                   | 411 x 731              | 1080 x 1920             |
| Google Pixel XL                | 411 x 731              | 1440 x 2560             |
| Google Pixel 2                 | 411 x 731              | 1080 x 1920             |
| Google Pixel 2 XL              | 411 x 823              | 1440 x 2880             |
| Samsung Galaxy Note 5          | 480 x 853              | 1440 x 2560             |
| LG G5                          | 360w x 640             | 1440 x 2560             |
| LG G4                          | 360w x 640             | 1440 x 2560             |
| LG G3                          | 360w x 640             | 1440 x 2560             |
| One Plus 3                     | 480 x 853              | 1080 x 1920             |
| Samsung Galaxy S9              | 360 x 740              | 1440 x 2960             |
| Samsung Galaxy S9+             | 360 x 740              | 1440 x 2960             |
| Samsung Galaxy S8              | 360 x 740              | 1440 x 2960             |
| Samsung Galaxy S8+             | 360 x 740              | 1440 x 2960             |
| Samsung Galaxy S7              | 360 x 640              | 1440 x 2560             |
| Samsung Galaxy S7 Edge         | 360 x 640              | 1440 x 2560             |
| Nexus 7 (2013)                 | 600 x 960              | 1200 x 1920             |
| Nexus 9                        | 768 x 1024             | 1536 x 2048             |
| Samsung Galaxy Tab 10          | 800 x 1280             | 800 x 1280              |
| Chromebook Pixel               | 1280 x 850             | 2560 x 1700             |

> https://experienceleague.adobe.com/docs/target/using/experiences/vec/mobile-viewports.html?lang=zh
>
> https://viewportsizes.com



## 一些长宽属性

### screen

- `screen.width` ：返回屏幕宽度。
- `screen.height` ：返回屏幕高度。
- `screen.availWidth` ：返回屏幕可用宽度。即屏幕宽度减去左右任务栏后的宽度，可表示为软件最大化时的宽度。
- `screen.availHeight` ：返回屏幕可用高度。即屏幕高度减去上下任务栏后的高度，可表示为软件最大化时的高度。

### window

- `window.outerWidth` ：返回浏览器宽度。
- `window.outerHeight` ：返回浏览器高度。
- `window.innerWidth` ：浏览器内页面可用宽度，包含了垂直滚动条的宽度。
- `window.innerHeight` ：浏览器内页面可用高度，包含水平滚动条的高度。
- `window.pageXOffset`：浏览器内页面的水平滚动偏移量。
- `window.pageYOffset`：浏览器内页面的垂直滚动偏移量。

### body

- `document.body.offsetWidth` ：body总宽度。
- `document.body.offsetHeight` ：body总高度。
- `document.body.clientWidth` ：body展示的宽度；表示body在浏览器内显示的区域宽度。
- `document.body.clientHeight` ：body展示的高度；表示body在浏览器内显示的区域高度。



![docs](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/docs.png)

