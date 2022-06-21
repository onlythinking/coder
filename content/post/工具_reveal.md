---
title: "如何利用 revealjs 快速写出漂亮的 PPT"
date: 2022-06-20T18:18:38+08:00
description: "教你快速做出好看的 PPT"
tags: ["revealjs","PPT"]
categories: ["工具"]
keywords: ["PPT","reveal.js","revealjs","reveal-md"]
draft: false
---

# 背景

日常工作汇报、演讲经常需要制作PPT，一般使用这些标准工具 **Microsoft PowerPoint**、**Apple Keynote** 或 **Google Slides** 。但这些工具对我来说过于繁琐，我希望有一个简单且支持 markdown 的工具，很幸运我找到了[RevealJS](https://github.com/hakimel/reveal.js/)，它是一个开源的 HTML 幻灯片框架，制作出精美的PPT，对于web开发人员来说更是首选。



# 入门

reveal.js 使用 nodejs 构建，需要提前安装好 nodejs。下载启动访问`http://localhost:8000` 就可以看到一个演示PPT。

```bash
git clone git@github.com:hakimel/reveal.js.git
mv reveal.js slides-demo
cd slides-demo
npm install
npm start
```

使用 Vscode 打开 index.html 制作，一个 `section` 就是一页幻灯片。

```html
<div class="reveal">
  <div class="slides">
    <section>Slide 1</section>
    <section>Slide 2</section>
  </div>
</div>
```

每张幻灯片是从左到右线性切换，如果需要在同一页垂直过渡切换，可以嵌套`section` 。

```html
		<div class="reveal">
			<div class="slides">
				<section>Slide 1</section>
				<section>
						<p>这里有一些内容</p>
						<section>1</section>
						<section>2</section>
						<section>2</section>
				</section>
			</div>
		</div>
```

添加 `data-background` 可以给幻灯片添加一个背景。

```html
<section data-background="https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202206201857325.jpeg">
  <h2>来吧！展示</h2>
</section>
```



添加 `fragment` 设置内容动画，每次展示一个内容。比如以此呈现列表，只需添加一个 `class="fragment"`.

```html
<section>
  <h2>片段顺序</h2>
  <ul>
    <li class="fragment">第一个</li>
    <li class="fragment">第二个</li>
    <li class="fragment">最后一个</li>
  </ul>
</section>
```

添加图片，在项目里创建 `assets` 目录存放图片，然后引入。

```html
<section>
  <h2>插入</h2>
  <img src="assets/img.png" alt="img">
</section>
```



# Reveal-md

直接编辑 Html 比较麻烦，我还是习惯在 markdown 里编辑内容。使用[reveal-md](https://github.com/webpro/reveal-md) 可以将 markdown 转换成 Html，或导出PDF。

## 安装

```bash
npm install -g reveal-md
```

npm 6.x 版本安装会出现权限错误，需要添加 `--unsafe-perm=true` 

```bash
sudo npm install -g reveal-md --unsafe-perm=true
```

> --unsafe-perm=true：“false if running as root, true otherwise”，大体意思是 npm 的安全限制，root身份运行时不会查询 root 的上下文，所以 sudo 运行时还需要指定 --unsafe-perm=true 忽略这种限制。



## 相关命令

```bash
# 启动
reveal-md slides.md -w 
# 生成 Html 默认目录_static
reveal-md slides.md --static
# 生成 Html 默认目录_static，指定图片目录 assets
reveal-md slides.md --static --static-dirs=assets
# 导出PDF
reveal-md slides.md --print slides.pdf
reveal-md slides.md --print slides.pdf --print-size 1024x768
reveal-md slides.md --print slides.pdf --print-size A4
```

## 幻灯片主题

**默认主题**

| 名称      | 效果                                 |
| :-------- | ------------------------------------ |
| black     | 黑色背景，白色文本，蓝色链接（默认） |
| white     | 白色背景，黑色文本，蓝色链接         |
| league    | 灰色背景，白色文字，蓝色链接         |
| beige     | 米色背景，深色文字，棕色链接         |
| sky       | 蓝色背景，细暗文本，蓝色链接         |
| night     | 黑色背景，厚白色文字，橙色链接       |
| serif     | 卡布奇诺背景，灰色文本，棕色链接     |
| simple    | 白色背景，黑色文本，蓝色链接         |
| solarized | 高分辨率照片                         |
| blood     | 深色背景，厚白文字，红色链接         |
| moon      | 高分辨率照片                         |

**自定义主题**

1. 下载 reveal `git clone git@github.com:hakimel/reveal.js.git` ；
2. 在 /css/theme/coder.scss 中复制一个文件；
3. 运行  `npm run build -- css-themes` 生成css dist/coder.css；
4. 运行指定主题 `reveal-md slides.md -w --theme theme/coder.css`。



## 切换时动画

| 名称    | 效果                                         |
| :------ | -------------------------------------------- |
| none    | 瞬间切换背景                                 |
| fade    | 交叉淡入淡出 - *背景转换的默认值*            |
| slide   | 在背景之间滑动 — *幻灯片过渡的默认设置*      |
| convex  | 以凸角滑动                                   |
| concave | 以凹角滑动                                   |
| zoom    | 向上缩放传入的幻灯片，使其从屏幕中心向内扩展 |



## 配置

我们可以在Markdown文件里通过 yaml 进行配置

```yaml
title: Slides # 幻灯片名称
theme: solarized # 幻灯片主题
highlightTheme: github # 代码高亮主题
revealOptions: 
  transition: 'convex' # 动画效果
```

reveal 其它配置项 

```json
{
  // 显示控制箭头
  controls: true,
  // 循环播放
  loop: false
  // 更多参考 https://revealjs.com/config/
}
```

reveal-md 其它配置项

```json
{
  // 幻灯片横行切割标志
  "separator": "^\n\n\n",
  // 幻灯片垂直切割标志
  "verticalSeparator": "^\n\n"
}
```



## 用法

当需要在 section 中添加属性时，Markdown 的写法如下

```javascript
<!-- .slide: 属性=属性值 -->
```

当需要在其它元素插入属性时，Markdown 的写法如下

```javascript
<!-- .element: 属性=属性值 -->
```

一些例子，设置背景色或背景图

```markdown
<!-- .slide: data-background="#fff" -->
<!-- .slide: data-background="./bg.png" -->
<!-- .slide: data-background-image="https://xxx.jpg" data-background-opacity=.1 data-background-repeat="no-repeat" -->
```

设置 fragment

```markdown
- Item1 <!-- .element: class="fragment" data-fragment-index="1" -->
- Item2 <!-- .element: class="fragment fade-in-then-out" data-fragment-index="2" -->
```

指定代码的高亮顺序

~~~markdown
```js [1-2|3|4|5]
let a = 1;
let b = 2;
let c = x => 1 + 2 + x;
c(3);
c(2);
```
~~~

地址跳转

```markdown
<!-- .slide: id=0 -->
[跳转0](#/0)
```



# 部署到Netlify

我喜欢将一些静态html托管到netlify，它免费比较好用。先在 Github 创建一个仓库 [coder_slides](https://github.com/onlythinking/coder_slides)，然后创建如下目录

```goat
├── README.md
└── content
    ├── assets
    │   └── bg.jpeg
    ├── template
    │   ├── listing.html
    │   └── reveal.html
    └── coder.md
```

- content 放MD文件集合；
- assets 本地图片资源；
- template 是渲染后的 HTML 模版，包含列表页面和详情页面，可以自行修改。

默认的 listing.html

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>{{pageTitle}}</title>
    <link rel="stylesheet" href="{{{themeUrl}}}" id="theme" />
  </head>

  <body>
    <ul>
      {{#files}}
      <li>
        <a href="{{filePath}}" title="{{title}}">
          {{#title}}{{.}} ({{filePath}}){{/title}}{{^title}}{{filePath}}{{/title}}
        </a>
      </li>
      {{/files}}
    </ul>
  </body>
</html>
```

默认的 reveal.html

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />

    <title>{{{title}}}</title>
    {{#absoluteUrl}}
    <meta property="og:title" content="{{{title}}}" />
    <meta property="og:type" content="website" />
    <meta property="og:image" content="{{{absoluteUrl}}}/featured-slide.jpg" />
    <meta property="og:url" content="{{{absoluteUrl}}}" />
    {{/absoluteUrl}}
    <link rel="shortcut icon" href="{{{base}}}/favicon.ico" />
    <link rel="stylesheet" href="{{{base}}}/dist/reset.css" />
    <link rel="stylesheet" href="{{{base}}}/dist/reveal.css" />
    <link rel="stylesheet" href="{{{themeUrl}}}" id="theme" />
    <link rel="stylesheet" href="{{{base}}}{{{highlightThemeUrl}}}" />

    {{#cssPaths}}
    <link rel="stylesheet" href="{{{.}}}" />
    {{/cssPaths}}

    {{#watch}}

    <script>
      document.write(
        '<script src="http://' +
          (location.host || 'localhost').split(':')[0] +
          ':35729/livereload.js?snipver=1"></' +
          'script>'
      );
    </script>
    {{/watch}}
  </head>
  <body>
    <div class="reveal">
      <div class="slides">{{{slides}}}</div>
    </div>

    <script src="{{{base}}}/dist/reveal.js"></script>

    <script src="{{{base}}}/plugin/markdown/markdown.js"></script>
    <script src="{{{base}}}/plugin/highlight/highlight.js"></script>
    <script src="{{{base}}}/plugin/zoom/zoom.js"></script>
    <script src="{{{base}}}/plugin/notes/notes.js"></script>
    <script src="{{{base}}}/plugin/math/math.js"></script>
    <script>
      function extend() {
        var target = {};
        for (var i = 0; i < arguments.length; i++) {
          var source = arguments[i];
          for (var key in source) {
            if (source.hasOwnProperty(key)) {
              target[key] = source[key];
            }
          }
        }
        return target;
      }

      // default options to init reveal.js
      var defaultOptions = {
        controls: true,
        progress: true,
        history: true,
        center: true,
        transition: 'default', // none/fade/slide/convex/concave/zoom
        plugins: [
          RevealMarkdown,
          RevealHighlight,
          RevealZoom,
          RevealNotes,
          RevealMath
        ]
      };

      // options from URL query string
      var queryOptions = Reveal().getQueryHash() || {};

      var options = extend(defaultOptions, {{{revealOptionsStr}}}, queryOptions);
    </script>

    {{#scriptPaths}}
    <script src="{{{.}}}"></script>
    {{/scriptPaths}}

    <script>
      Reveal.initialize(options);
    </script>
  </body>
</html>
```

运行本地调试

```bash
reveal-md content/ --template template/reveal.html --listing-template template/listing.html
```

![list](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202206211348181.png)

如何部署部署到netlify？

注册一个[netlify](https://app.netlify.com/)，然后创建一个站点关联上github仓库。

在配置/部署里面添加构建命令

```bash
npm install -g reveal-md && reveal-md content/ --static --static-dirs=content/assets --template template/reveal.html --listing-template template/listing.html
```

然后在域名管理添加一个自己的域名

![image-20220621143050693](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202206211430922.png)

配置成功如下

> https://slides.onlythinking.com



# 参考

> https://github.com/hakimel/reveal.js
>
> https://github.com/webpro/reveal-md
>
> https://revealjs.com/
>
> https://app.netlify.com/
>





