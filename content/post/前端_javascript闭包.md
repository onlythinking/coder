---
title: JavaScript 作用域和运行分析
date: 2021-10-23 14:55:17
description: "JavaScript 作用域和运行分析"
tags: ["JavaScript"]
categories: ["前端"]
keywords: ["JavaScript"]
---

## 作用域

JavaScript中的作用域分为**全局作用域**，**函数作用域**，**块作用域**。

### 全局作用域

对于全局范围内声明的变量，可以在任何地方访问。

```javascript
var messge = 'Hello'
function say(){
  console.log(message)
}
say(); // Hello
```

### 函数作用域

在函数内声明的变量，只能从该函数内部访问。

```javascript
function say() {
  var messge = 'Hello';
  console.log(messge);
}
say(); // Hello
console.log(greeting); // ReferenceError: messge is not defined
```

### 块作用域

ES6 引入了`let`和`const` 关键字，它们声明的变量只能从该代码块内访问。

```javascript
{
  let messge = 'Hello';
  console.log(messge);
}
console.log(messge); // ReferenceError: messge is not defined
```

### 静态作用域

在词法分析时（编译时）确定。

```javascript
let number = 42;
function printNumber() {
  console.log(number);
}
function log() {
  let number = 54;
  printNumber();
}

log(); // 42
```

### 作用域链

JavaScript运行时，引擎首先会在当前范围内查找变量，如果找不到，会向父作用域查一层一层向上查找，一直找到顶层全局作用域，如果还是找不到就返回`undefined`。

```javascript
var g = 'Global hello'
function f1() {
    var g1 = 'G1 hello';
    function f2() {
        var g2 = 'G2 hello'
        function f3() {
            console.log(g, g1, g2)
        }
      	f3()
    }
  	f2();
}
f1(); // Global hello G1 hello G2 hello

```



![image-20211024201823243](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211024201823243.png)



## 运行分析

### 执行上下文

**执行上下文**是执行一段 JavaScript 的环境，它存储了执行代码的一些必要信息。执行上下文分**全局执行上下文**和**函数执行上下文**。

- **全局执行上下文**，一个程序中只会有一个，函数之外的代码都在**全局执行上下文**中运行。

- **函数执行上下文**，函数在每次调用时都会创建一个对应的**函数执行上下文**。

执行上下文的包含**变量环境**（`Variable environment`），**作用域链**（`Scope chain`），`this` 指向。

- 变量环境，函数内部所有的变量和对象引用和调用参数。
- 作用域链，当前函数之外的变量的引用组成。
- `this` 指向。



从JavaScript运行时的内存结构来看，调用栈就是存储**执行上下文**的集合。

![image-20211024174139675](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211024174139675.png)



### 案例

案例一

这是一个普通的JavaScript例子，运行流程分析：

```javascript
var msg = 'Global hello'

function say() {
    var msg = 'Hello'
  	return msg;
}

var s = say();
console.log(message) // Hello

```

1. 创建**全局执行上下文**，然后入调用栈。
2. 调用函数`say()`，创建`say()`的**函数执行上下文**，并入调用栈。
3. 执行完`say()`函数将结果返回，更新全局执行上下文里的`s` 变量。
4. 将`say` 函数的执行上下文弹出栈。

![image-20211024184307452](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211024184307452.png)

![image-20211024184942127](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211024184942127.png)

案例二

这个例子跟上面不同的是返回值是函数，这个匿名函数也称闭包，它访问了函数外部的变量，即使外部**函数执行上下文**被弹出栈后，它依然可以持有外部变量的引用。运行分析如下：

```javascript
var msg = 'Global hello'

function say() {
    var msg = 'Hello'
    return function() {
        console.log(msg)
    };
}

var s = say();
s()

```

1. 创建**全局执行上下文**，然后入调用栈。
2. 调用函数`say()`，创建`say()`的**函数执行上下文**，并入调用栈。
3. 执行完`say()`函数将结果返回，更新全局执行上下文里的`s` 变量，`s` 是函数类型，它依然持有`say` `var = msg` 引用。
4. 将`say` 函数的执行上下文弹出栈。
5. 执行 `s()` ，创建`s()`的**函数执行上下文**。
6. 将 `s()` 函数的执行上下文弹出栈。

![image-20211024191627578](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211024191627578.png)



## 思考题

在脑海里动态执行下面代码。

题目一：

```javascript
var msg = 'Global hello'

function getMsgFunc() {
    var msg = 'Hello';
    function getMsg() {
        return msg;
    }
    return getMsg();
}
console.log(getMsgFunc());
```

题目二：

```javascript
var msg = 'Global hello'

function getMsgFunc() {
    var msg = 'Hello';
    function getMsg() {
        return msg;
    }
    return getMsg;
}
console.log(getMsgFunc()());
```

题目三：

```javascript
	 var msg = 'Global hello'

　　var obj = {
　　　　msg : 'Hello',

　　　　getMsgFunc : function(){
　　　　　　return function(){
　　　　　　　　return this.msg;
　　　　　　};
　　　　}
　　};
　　console.log(obj.getMsgFunc()());
```

题目四：

```javascript
	 var msg = 'Global hello'

　　var obj = {
　　　　msg : 'Hello',

　　　　getMsgFunc : function(){
      		var that = this
　　　　　　return function(){
　　　　　　　　return that.msg;
　　　　　　};
　　　　}
　　};
　　console.log(obj.getMsgFunc()());
```

