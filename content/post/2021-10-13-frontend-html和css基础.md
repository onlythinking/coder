---
title: "Html和Css基础 | 编程码农"
date: "2021-10-13T10:52:46+08:00"
description: "HTML（网页） Web领域的一些基本概念。 WEB Web（World Wide Web）叫全球广域网，俗称万维网（www）。 W3C W3C（World Wide Web Consortium）叫万维网联盟，是国际最著名的标准化组织，制定了web标准。 WEB标准 一个网页包含了html元素 C..."
tags:
  - "JavaScript"
  - "Java"
  - "前端"
  - "Class"
  - "HTML"
categories:
  - "前端开发"
keywords:
  - "JavaScript"
  - "Java"
  - "前端开发"
  - "ES6"
  - "Git"
  - "排序"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

# HTML（网页）

Web领域的一些基本概念。

**WEB**

Web（World Wide Web）叫全球广域网，俗称万维网（www）。

**W3C**

W3C（World Wide Web Consortium）叫万维网联盟，是国际最著名的标准化组织，制定了web标准。

## WEB标准

一个网页包含了html元素 Css JavaScript，Html元素决定了网页结构，Css进行了修饰美化，JavaScript控制了交互行为和动态效果。

web标准包含了下面三个方面：

- 结构标准（HTML）：用于对网页元素进行整理和分类。
- 表现标准（CSS）：用于设置网页元素的版式、颜色、大小等外观样式。
- 行为标准（JavaScript）：用于定义网页的交互和行为。

## HTML定义

Html不是一种编程语言，而是描述性的**标记语言**，主要作用是定义内容的结构。

2014年10月万维网联盟（W3C）完成了**HTML5**标准制定，是目前最新的HTM版本。

HTML5的出世，标志着web进入一个**富客户端**（具有很强的**交互性**和体验的客户端程序）时代，像APP网页，小程序都是HTML5的应用场景。

Html5新特性：

- 用于绘画的 canvas 元素。
- 用于媒介回放的 video 和 audio 元素。
- 对本地离线存储的更好的支持。
- 新的特殊内容元素，比如 article、footer、header、nav、section。
- 新的表单控件，比如 calendar、date、time、email、url、search。

**页面基本结构**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"> <!--字符集-->
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  	<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
  	<meta name="Author" content="">
    <meta name="Keywords" content="关键词" />
    <meta name="Description" content="页面描述" />
    <title>页面标题</title>
</head>
<body>

</body>
</html>
```

## 关于viewport

viewport用户网页的可视区域，一个针对移动网页优化的页面 viewport meta 标签如下：

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

- width：控制 viewport 的大小，可以指定的一个值，如 600，或者特殊的值，如 device-width 为设备的宽度（单位为缩放为 100% 时的 CSS 的像素）。
- height：和 width 相对应，指定高度。
- initial-scale：初始缩放比例，也即是当页面第一次 load 的时候缩放比例。
- maximum-scale：允许用户缩放到的最大比例。
- minimum-scale：允许用户缩放到的最小比例。
- user-scalable：用户是否可以手动缩放。

## 常见元素

head区域元素：meta title style link script base。

body区域元素：

- div、section、article、aside、header、footer
- p
- span、em、strong
- table、thead、tbody、tr、td
- ul、ol、dl、dt、dd
- a
- form、input、select、textarea、button

## 元素分类

**块级元素**：每个元素都是独占一行

- address – 地址
- blockquote – 块引用
- center – 举中对齐块
- dir – 目录列表
- div – 常用块级容易，也是css layout的主要标签
- dl – 定义列表
- fieldset – form控制组
- form – 交互表单
- h1-h6 – 标题
- hr – 水平分隔线
- isindex – input prompt
- menu – 菜单列表
- noframes – frames可选内容，（对于不支持frame的浏览器显示此区块内容）
- noscript – ）可选脚本内容（对于不支持script的浏览器显示此内容）
- ol – 排序表单
- p – 段落
- pre – 格式化文本
- table – 表格
- ul – 非排序列表

**行内元素**：元素在同一行水平排列

- a – 锚点
- abbr – 缩写
- acronym – 首字
- b – 粗体
- big – 大字体
- br – 换行
- em – 强调
- font – 字体设定(不推荐)
- i – 斜体
- img – 图片
- input – 输入框
- label – 表格标签
- s – 中划线(不推荐)
- select – 项目选择
- small – 小字体文本
- span – 常用内联容器，定义文本内区块
- strike – 中划线
- strong – 粗体强调
- sub – 下标
- sup – 上标
- textarea – 多行文本输入框
- tt – 电传文本
- u – 下划线
- var – 定义变量

**inline-block**：元素可以排列在同一行显示，并且可以设置一些块元素属性

通过Css：display:inline-block 改变元素。

## 元素默认样式

很多元素都自带了默认样式，不同浏览器下默认样式表现不一致，为了统一或者满足一些需求我们需求将所有默认样式清空，这种处理方式又称为 **Css Reset**，比如：

```css
*{
    margin: 0;
    padding: 0;
}
```

另外一种方案使用**normalize.css**，它将不同浏览器下的默认样式进行了统一，

> https://github.com/necolas/normalize.css



# CSS（层叠样式表）

## Css的单位

html中的单位是像素px

**绝对单位**

- in：英寸，1in = 2.54cm = 96px
- pc：皮卡，1皮卡 = 1/16英寸
- pt：点，1点 = 1/72英寸
- px：像素，1点 = 1/96英寸

**相对单位**

- em：font-size中相对于父元素的字体大小，在元素属性中使用是相对于自身字体大小
- rem：根元素的字体大小，在元素属性中使用是相对于根元素字体大小
- 1h：元素的line-height
- vw：视窗宽度的1%
- vh：视窗高度的1%
- vmin：视窗较小尺寸的1%
- vmax：视图大尺寸的1%

## 字体属性

属性：字体、行高、颜色、大小、背景、边框、滚动、换行、修饰属性（粗体、斜体、下划线）

```css
p{
	font-size: 20px; 		/*字体大小*/
	line-height: 30px;      /*行高*/
	font-family: PingFang SC; 	/*字体类型：显示PingFang SC，没有就显示默认*/
	font-style: italic ;		/*italic表示斜体，normal表示不倾斜*/
	font-weight: bold;	/*粗体或写（400｜500｜600）*/
	font-variant: small-caps;  /*小写变大写*/
}
```

**行高（line-height）**

一般约定**行高、字号都是偶数**，这样保证它们的差一定偶数除2得到整数，如下图所示：

![line-height-large](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/line-height-large.png)

**文本垂直居中**

对于单行文本可以设置**行高 = 盒子高度**。

对于多行元素的垂直对齐，我们可以使用**vertical-align: middle**属性，不过**vertical-align** 仅适用inline、inline-block 和 table-cell 元素。

![phVHDUa](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/phVHDUa.png)

```css
vertical-align: baseline;
vertical-align: sub;
vertical-align: super;
vertical-align: text-top;
vertical-align: text-bottom;
vertical-align: middle;
vertical-align: top;
vertical-align: bottom;
/* 指定长度值 */
vertical-align: 10em;
vertical-align: 4px;
/* 使用百分比 */
vertical-align: 20%;
/* 全局值 */
vertical-align: inherit;
vertical-align: initial;
vertical-align: revert;
vertical-align: unset;
```

## 文本属性

- `letter-spacing: 0.5em ;` 单个字母之间的间距。
- `word-spacing: 1em;` 单词之间的间距。
- `text-decoration: none;` none 去掉下划线、underline 下划线、line-through 中划线、overline 上划线。
- `color:red;` 字体颜色。
- `text-align: center;` 文字对齐方式，属性值可以是：left、right、center、justify。
- `text-transform: lowercase;` uppercase（大写）、lowercase（小写）capitalize（首字母大写）。
- `text-indent:10px;` 文本首行缩进。
- `text-shadow:2px 2px #ff0000;` 文字阴影效果。
- `white-space: normal;` 设置元素空白处理，normal，nowrap，break-spaces。

## Overflow属性

内容溢出处理

- `visible`：默认值，多余的内容会全部显示出来。
- `hidden`：超过元素的内容隐藏。
- `auto`：内容超出显示滚动条。
- `scroll`：Windows总是显示滚动条。Mac和`auto` 属性相同。

## 滤镜

```css
filter:gray()
```

## 背景属性

- `background-color:#fff;` 设置背景颜色。
- `background-image:url(img.png);` 设置图像为背景。
- `background-repeat: no-repeat;` `no-repeat`不要平铺，`repeat-x`横向平铺；`repeat-y`纵向平铺。
- `background-position:center top;` 设置背景图片在容器的位置，top，bottom，left，right，center。
- `background-attachment:scroll;` 设置背景图片随滚动条移动，scroll（跟随滚动），fixed（固定）。
- `background-origin:border-box;` css3，border-box（背景相对于边框框定位），padding-box（背景相对于填充框定位），content-box（背景相对于内容框定位）。
- `background-clip:border-box;` css3，背景裁切。
- `background-size:cover;`  css3，调整尺寸，
  - contain（在不裁剪或拉伸图像的情况下，在其容器内尽可能大地缩放图像），
  - cover（尽可能大地缩放图像以填充容器，必要时拉伸图像。），
  - auto（在相应的方向上缩放背景图像，以保持其固有比例。）。

## 优先级

**理解优先级很重要，有助于我们排查一些问题。**浏览器将优先级分为两部分：HTML的行内样式和选择器的样式。

**行内样式** 

行内样式是直接作用在元素，它的优先级高于选择器样式，使用**！important**可以提高样式表的优先级。

```html
<div style="font-size:16px">
</div>
```

**选择器样式**

```html
<style type="text/css">
    p{
      font-size: 16px;
    }
</style>
<link rel="stylesheet" href="style/app.css">
```

优先级规则如下：

- 如果选择器的ID数量最多的胜出。
- 如果ID数量一致，那么拥有最多类的选择器胜出。
- 如果以上两次比较都一致，那么拥有最多标签名的选择器胜出。

![image-20211014154431363](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211014154431363.png)



我们通过下图这种标记方式，就可以判断出选择器的优先级。

![album_temp_1631516058](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/album_temp_1631516058.PNG)



**两条经验法则**

1.  尽量不要使用ID选择器，因为它会大幅提升优先级。当需要覆盖这个选择器时，通常找不到另一个有意义的ID，于是就需要复制原来的选择器加上另一个类来让它区别于想要覆盖的选择器。
2. 不要使用！important。它比ID更难覆盖，一旦用了它，想要覆盖原先的声明，就需要再加上一个！important，而且依然要处理优先级的问题。

# CSS 选择器

## 基础选择器

- 类型或标签选择器，匹配目标元素的标签名，如 ：p，input[type=text]，优先级（0，0，1）。
- 类选择器，匹配class属性中有指定类名的元素，如：.box，优先级（0，1，0）。
- ID选择器，匹配拥有指定ID属性的元素，如：#id， 优先级（1，0，0）。
- 通用选择器（*），匹配所有元素 ，优先级（0，0，0）。

## 组合选择器

由多个基础选择器组合成的复杂选择器。

- 后代组合器（单个空格（` `）表示），比如 .nav li，表示li是一个拥有nav类的元素的后代。
- 子组合器（>），匹配的元素是直接后代，.parent > .child。
- 相邻兄弟组合器（+），匹配的元素紧跟在后面其它元素后面，div + p。
- 通用兄弟组合器（~），匹配所有跟随在指定元素之后的兄弟元素，它不会选中目标元素之前的兄弟元素，li.active ~ li。

## 复合选择器

多个基础选择器连起来（中间没有空格）组成一个复合选择器（如：ul.nav）。复合选择器选中的元素将匹配其全部基础选择器，.box.nav 可以选中 class="box nav" ，但是不能选中 class="box"。

## 伪类选择器

用于选中某种特定状态的元素，优先级（0，1，0）。

- :first-child——匹配的元素是其父元素的第一个子元素。
-  :last-child——匹配的元素是其父元素的最后一个子元素。
- :only-child——匹配的元素是其父元素的唯一一个子元素（没有兄弟元素）。
-  :nth-child(an+b)——匹配的元素在兄弟元素中间有特定的位置。公式an+b里面的a和b是整数，该公式指定要选中哪个元素。要了解一个公式的工作原理，请从0开始代入n的所有整数值。公式的计算结果指定了目标元素的位置。下表给出了一些例子。

![image-20211014141822246](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211014141822246.png)

- :nth-last-child(an+b)——类似于：nth-child()，但不是从第一个元素往后数，而是从最后一个元素往前数。括号内的公式与：nth-child()里的公式的规则相同。
-  :first-of-type——类似于：first-child，但不是根据在全部子元素中的位置查找元素，而是根据拥有相同标签名的子元素中的数字顺序查找第一个元素。
- :last-of-type——匹配每种类型的最后一个子元素。
-  :only-of-type——该选择器匹配的元素是满足该类型的唯一一个子元素。
-  :nth-of-type(an+b)——根据目标元素在特定类型下的数字顺序以及特定公式选择元素，类似于：nth-child。

- :nth-last-of-type(an+b)——根据元素类型以及特定公式选择元素，从其中最后一个元素往前算，类似于：nth-last-child。
- :not(`<selector>`)——匹配的元素不匹配括号内的选择器。括号内的选择器必须是基础选择器，它只能指定元素本身，无法用于排除祖先元素，同时不允许包含另一个排除选择器。
- :focus——匹配通过鼠标点击、触摸屏幕或者按Tab键导航而获得焦点的元素。
- :hover——匹配鼠标指针正悬停在其上方的元素。
-  :root——匹配文档根元素。对HTML来说，这是html元素，但是CSS还可以应用到XML或者类似于XML的文档上，比如SVG。在这些情况下，该选择器的选择范围更广。还有一些表单域相关的伪类选择器。
- :disabled——匹配已禁用的元素，包括input、select以及button元素。
- :enabled——匹配已启用的元素，即那些能够被激活或者接受焦点的元素。
- :checked——匹配已经针对选定的复选框、单选按钮或选择框选项。
- :invalid——根据输入类型中的定义，匹配有非法输入值的元素。例如，当<inputtype="email">的值不是一个合法的邮箱地址时，该元素会被匹配。

> 更多参考：https://developer.mozilla.org/zh-CN/docs/Web/CSS



## 伪元素选择器

伪元素选择器可以向HTML标记中未定义的地方插入内容，优先级（0，0，1）。

- ::before——创建一个伪元素，使其成为匹配元素的第一个子元素。该元素默认是行内元素，可用于插入文字、图片或其他形状。必须指定content属性才能让元素出现，如：.nav::before。
- ::after——创建一个伪元素，使其成为匹配元素的最后一个子元素。该元素默认是行内元素，可用于插入文字、图片或其他形状。必须指定content属性才能让元素出现，如：.nav::after。
- ::first-letter——用于指定匹配元素的第一个文本字符的样式，如：h1::first-letter。
- ::first-line——用于指定匹配元素的第一行文本的样式。
- ::selection——用于指定用户使用鼠标高亮选择的任意文本的样式。通常用于改变选中文本的background-color。只有少数属性可以使用，包括color、background-color、cursor、text-decoration。

## 属性选择器

属性选择器用于根据HTML属性进行匹配元素，优先级（0，1，0）。

- [attr]——匹配的元素拥有指定属性attr，无论属性值是什么，如：input[disabled]。
- [attr="value"]——匹配的元素拥有指定属性attr，且属性值等于指定的字符串值，如：input[type="radio"]。
- [attr^="value"]——“开头”属性选择器。该选择器匹配的元素拥有指定属性attr，且属性值的开头是指定的字符串值，例如：a[href^="https"]。
- [attr＊="value"]——“包含”属性选择器。该选择器匹配的元素拥有指定属性attr，且属性值包含指定的字符串值，如：[class＊="sprite-"]。
- [attr~="value"]——“空格分隔的列表”属性选择器。该选择器匹配的元素拥有指定属性attr，且属性值是一个空格分隔的值列表，列表中的某个值等于指定的字符串值，如：a[rel="author"]。
- [attr|="value"]——匹配的元素拥有指定属性attr，且属性值要么等于指定的字符串值，要么以该字符串开头且紧跟着一个连字符（-）。



## 小结

本文要点回顾，欢迎留言交流。

- Web中的一些基本概念介绍。
- Html页面结构，元素分类。
- Css优先级。
- Css选择器，（基础选择器，组合选择器，复合选择器，伪类选择器，伪元素选择器，属性选择器）。
