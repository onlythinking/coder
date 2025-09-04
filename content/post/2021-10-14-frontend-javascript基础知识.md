---
title: "JavaScript 基础知识 | 编程码农"
date: "2021-10-14 17:50:43"
description: "什么是JavaScript？ JavaScript ( JS ) 是一种具有函数优先的轻量级，解释型或即时编译型的编程语言。 > 函数优先：编程语言中的函数可以被当作参数传递给其他函数，可以作为另一个函数的返回值，还可以被赋值给一个变量。 > > 解释型：对标编译型语言，编译型需预先将源码编成中间码..."
tags:
  - "JavaScript"
  - "Java"
  - "前端"
  - "Class"
  - "ES6"
categories:
  - "前端开发"
keywords:
  - "JavaScript"
  - "Java"
  - "前端开发"
  - "ES6"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

# 什么是JavaScript？

**JavaScript (** **JS** ) 是一种具有**函数优先**的轻量级，解释型或即时编译型的编程语言。

> **函数优先**：编程语言中的函数可以被当作参数传递给其他函数，可以作为另一个函数的返回值，还可以被赋值给一个变量。
>
> **解释型**：对标**编译型**语言，编译型需预先将源码编成中间码，再由解释器解释运行。解释型不需要预先编译，在程序在运行时才由解释器翻译运行。

JavaScript 的标准是**ECMAScript**截至 2012 年，所有的**现代浏览器**都完整的支持 ECMAScript 5.1，旧版本的浏览器至少支持 ECMAScript 3 标准。

我们所熟知的**ES6**是在2015年6月17日，由ECMA国际组织发布的ECMAScript 的第六版，该版本正式名称为 ECMAScript 2015。

> https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Language_Resources

## 使用场景

互联网的兴起，JavaScript的使用范围已经超出了浏览器。

1. **浏览器平台**。HTML5的出现，浏览器本身的功能越来越强，JavaScript 因此得以调用许多系统功能，如操作本地文件、操作图片、调用摄像头和麦克风，可以开发更多富客户端产品。
2. **服务端应用**。node的出现使得 JavaScript 可以用于开发服务器端应用，也使得JavaScript成为一门可以同时开发前后端的语言。
3. **移动应用**。js也正在成为手机应用的开发语言，比如：React Native 项目则是将 JavaScript 写的组件，编译成原生组件。
4. **桌面应用**。JavaScript甚至可以开发桌面应用，比如electronjs。
5. **数据库操作**。在一些Nosql数据都是支持JavaScript作为操作语言，像mongodb。



# 基本语法

## 变量

变量是对值的引用，JavaScript 的变量名区分大小写，`A`和`a`是两个不同的变量。

```javascript
var total; // 未赋值的变量是 undefined，它是个特殊的值，表示无定义。
total = 1;
var a,b; // 一个var后可以声明多个变量。
```

## **变量提升**

你可能很奇怪，执行下面代码没有报错。由于JavaScript引擎工作方式是先解析代码，获取所有被声明的变量，换句话说就是所有的变量的声明语句，都被提升到代码的头部。

```javascript
console.log(a);
var a = 1;
```

## **变量规则**

- 第一个字符任意 Unicode 字母（包括英文字母和其他语言的字母），以及美元符号（`$`）和下划线（`_`）

- 第二个字符及后面的字符，除了 Unicode 字母、美元符号和下划线，还可以用数字`0-9`。

> 另外中文也可以声明变量，下面保留字除外
>
> arguments、break、case、catch、class、const、continue、debugger、default、delete、do、else、enum、eval、export、extends、false、finally、for、function、if、implements、import、in、instanceof、interface、let、new、null、package、private、protected、public、return、static、super、switch、this、throw、true、try、typeof、var、void、while、with、yield。

## 语句

JavaScript程序的执行单位行，一般情况一行就是一条语句，如果一行要写多个语句我们使用`;`表示语句结束。

```javascript
var total = 1 + 1; // 声明了一个变量total，然后将1+1的运算结果赋值给它。
```

## **注释**

```javascript
// 这是单行注释

/*
 这是
 多行
 注释
*/
```

## **区块**

JavaScript使用大括号将多条语句包裹起来表示一个区块，注意`var`声明的变量不构成单独的作用域，这里区别于java。

```javascript
{
  var a = 1;
}
a // 1
```

## **条件语句**

```javascript
// if结构
if (m === 1){ // 往往由一个条件表达式产生的
	console.log('ok')
}
// 或者
if (bool) console.log('ok');

// if/else结构
if (m === 1){
  语句;
}else{
	语句;  
} 

// if/else if.../else 结构 m==1 m==2 其它
if (m === 1) {
} else if(m === 2){
}else {
}
```



**switch 结构**

```javascript
switch (m) {
  case 1:
    // ...
    break;
  case 2:
    // ...
    break;
  default:
    // ...
}
```



> 注意区别 **==与===**
>
> 使用==比较两个变量时，会发生隐式类型转换，例如，自动将字符串类型转换为数字类型。
>
> 为了避免隐式转换带来的问题，我们都是用=== 进行严格进行比较。



**三元运算符**

三元运算符也可以用于逻辑判断。

```javascript
(条件) ? 表达式1 : 表达式2
```



**循环语句**

```javascript
var i = 0;
while (i < 100) {
  console.log('i 当前为：' + i);
  i = i + 1;
}
// 区别上面，它至少会执行一次
var i = 0;
do {
  console.log('i 当前为：' + i);
} while (i < 100);
```



**for循环语句**

- 初始化表达式：确定循环变量的初始值，只在循环开始时执行一次。
- 条件表达式：每轮循环开始时，都要执行这个条件表达式，只有值为真，才继续进行循环。
- 递增表达式：每轮循环的最后一个操作，通常用来递增循环变量。

```javascript
for (初始化表达式; 条件; 递增表达式) {
  语句
}
```

**break 和 continue**

`break`语句用于跳出代码块或循环，`continue`是结束当前循环，跳到下一次。



# 数据类型

## **null和undefined**

● 变量没有初始化：undefined。

● 变量不可用：null。

## **数值**

整数和浮点数，JavaScript 内部，所有数字都是以64位浮点数形式储存，即使整数也是如此。

```javascript
1 === 1.0 // true
```

数值精度：根据国际标准 IEEE 754，JavaScript 浮点数的64个二进制位，从最左边开始，是这样组成的。

- 第1位：符号位，`0`表示正数，`1`表示负数
- 第2位到第12位（共11位）：指数部分
- 第13位到第64位（共52位）：小数部分（即有效数字）

数值范围：64位浮点数的指数部分的长度是11个二进制位，意味着指数部分的最大值是2047（2的11次方减1）超出的范围不能表示。

数值进制：

- 十进制：没有前导0的数值。
- 八进制：有前缀`0o`或`0O`的数值，或者有前导0、且只用到0-7的八个阿拉伯数字的数值。
- 十六进制：有前缀`0x`或`0X`的数值。
- 二进制：有前缀`0b`或`0B`的数值。

## **NaN**

`NaN`是 JavaScript 的特殊值，表示“非数字”（Not a Number），主要出现在将字符串解析成数字出错的场合。

## **字符串**

由单双引号包裹在一起的字符，就是字符串。

单引号字符串的内部，可以使用双引号。双引号字符串的内部，可以使用单引号。

```javascript
'abc' "abc" "'a'" // 字符串

// 字符串换行
var str = 'String \
String \
String';
```

转义符：

- `\0` ：null（`\u0000`）
- `\b` ：后退键（`\u0008`）
- `\f` ：换页符（`\u000C`）
- `\n` ：换行符（`\u000A`）
- `\r` ：回车键（`\u000D`）
- `\t` ：制表符（`\u0009`）
- `\v` ：垂直制表符（`\u000B`）
- `\'` ：单引号（`\u0027`）
- `\"` ：双引号（`\u0022`）
- `\\` ：反斜杠（`\u005C`）

字符集：javaScript 使用 Unicode 字符集。JavaScript 引擎内部，所有字符都用 Unicode 表示。

## **对象**

```javascript
var obj = { // 对象声明
  a: '1',
  b: '2'
};

// 对象属性读取
obj.a 
obj['a']

// 删除对象属性
delete obj.a

// 判断属性是否存在
'a' in obj 

//对象遍历
for (var i in obj) {
  console.log('键名：', i);
  console.log('键值：', obj[i]);
}
```

## **函数**

function 关键字声明。

```javascript
function foo(s) {
  console.log(s);
}
// 表达式形式
var foo = function(s) {
  console.log(s);
};
```

Function 构造函数

```javascript
var add = new Function(
  'x',
  'y',
  'return x + y'
);

// 等同于
function add(x, y) {
  return x + y;
}
```



函数名提升：JavaScript 引擎将函数名视同变量名，所以采用`function`命令声明函数时，整个函数会像变量声明一样，被提升到代码头部。

```javascript
foo();
function foo() {console('ok')}
```

> JavaScript函数知识点还是蛮多的，后面针对函数这一块单独整理。

## **数组**

数组属于一种特殊的对象。

```javascript
typeof [1, 2, 3] // "object"
```

length：JavaScript 使用一个32位整数，保存数组的元素个数。这意味着，数组成员最多只有 4294967295 个（2^32 - 1）个，也就是说`length`属性的最大值就是 4294967295。

数组遍历

```javascript
var a = [1, 2, 3];
for (var i in a) {
  console.log(a[i]);
}
```



# 小结

本文要点回顾，欢迎留言交流。

- JavaScript介绍。
- JavaScript基本语法。
- 数据类型。
