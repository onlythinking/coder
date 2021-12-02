---
title: JavaScript新特性（ES6）
date: 2021-10-17 09:48:26
description: "JavaScript新特性（ES6）"
tags: ["JavaScript"]
categories: ["前端"]
keywords: ["JavaScript"]
---

## 简介

ES6是一个泛指，含义是 5.1 版以后的 JavaScript 的下一代标准，涵盖了 ES2015、ES2016、ES2017语法标准。

ES6新特性目前只有在一些较新版本浏览器得到支持，老版本浏览器里面运行我们需要将ES6转换为ES5。

> Chrome：51 版起便可以支持 97% 的 ES6 新特性。 
>
> Firefox：53 版起便可以支持 97% 的 ES6 新特性。
>
>  Safari：10 版起便可以支持 99% 的 ES6 新特性。 
>
> IE：Edge 15可以支持 96% 的 ES6 新特性。Edge 14 可以支持 93% 的 ES6 新特性。（IE7~11 基本不支持 ES6）

#### **Babel 转码器**

它是一个广泛使用的 ES6 转码器。

```bash
npm install --save-dev @babel/core
```

配置文件`.babelrc`

```bash
# 最新转码规则
$ npm install --save-dev @babel/preset-env

# react 转码规则
$ npm install --save-dev @babel/preset-react
```



```javascript
// `presets`字段设定转码规则，官方提供以下的规则集，你可以根据需要安装。
  {
    "presets": [
      "@babel/env",
      "@babel/preset-react"
    ],
    "plugins": []
  }
```

#### **polyfill**

Babel默认只是对JavaScript新语法进行了转换，为了支持新API还需要使用polyfill为当前环境提供一个垫片（也就是以前的版本没有，打个补丁）。

比如：`core-js`和`regenerator-runtime`

```bash
$ npm install --save-dev core-js regenerator-runtime
```

```javascript
import 'core-js';
import 'regenerator-runtime/runtime';
```



## let 和 const

#### let

就作用域来说，ES5 只有全局作用域和函数作用域。使用`let`声明的变量只在所在的代码块内有效。

```javascript
if(true){ let a = 1; var b = 2 }
console.log(a)// ReferenceError: a is not defined
console.log(b)// 2
```

看下面的例子，我们预期应该输出`1`，因为全局只有一个变量i，所以for执行完后，i=5，函数打印的值始终是5。

```javascript
var funcs = [];
for (var i = 0; i < 5; i++) {
  funcs.push(function () {
    console.log(i);
  });
}
funcs[1](); // 5
```

修复，将每一次迭代的i变量使用local存储，并使用闭包将作用域封闭。

```javascript
var funcs = [];
for (var i = 0; i < 5; i++) { 
    (function () {
            var local = i
            funcs.push(function () {
                console.log(local);
            });
        }
    )()
}
funcs[1](); // 1
```

使用`let`声明变量i也可以达到同样的效果。

#### const

`const`用于声明一个只读的常量。必须初始化，一旦赋值后不能修改。`const`声明的变量同样具有块作用域。

```javascript
if (true) {
 const PI = 3.141515926;
 PI = 66666 // TypeError: Assignment to constant variable.
}
console.log(PI) // ReferenceError: PI is not defined
```

`const`声明对象

```javascript
const obj = {};
// 为 obj 添加一个属性，可以成功
obj.name = 'hello';

// 将 obj 指向另一个对象，就会报错
obj = {}; // TypeError: "obj" is read-only
```



## 解构

解构字面理解是分解结构，即会打破原有结构。

#### 对象解构

基本用法：

```javascript
let { name, age } = { name: "hello", age: 12 };
console.log(name, age) // hello 12
```

设置默认值

```javascript
let { name = 'hi', age = 12 } = { name : 'hello' };
console.log(name, age) // hello 12
```

rest参数（形式为`...变量名`）可以从一个对象中选择任意数量的元素，也可以获取剩余元素组成的对象。

```javascript
let { name, ...remaining } = { name: "hello", age: 12, gender: '男' };
console.log(name, remaining) // hello {age: 12, gender: '男'}
```

#### 数组解构

rest参数（形式为`...变量名`）从数组中选择任意数量的元素，也可以获取剩余元素组成的一个数组。

```javascript
let [a, ...remaining] = [1, 2, 3, 4];
console.log(a, remaining) // 1 [2, 3, 4]
```

数组解构中忽略某些成员。

```javascript
let [a, , ...remaining] = [1, 2, 3, 4];
console.log(a, remaining) // 1 [3, 4]
```

#### 函数参数解构

数组参数

```javascript
function add([x, y]){
  return x + y;
}
add([1, 2]); // 3
```

对象参数

```javascript
function add({x, y} = { x: 0, y: 0 }) {
  return x + y;
}
add({x:1 ,y : 2});
```

#### 常见场景

在不使用第三个变量前提下，交换变量。

```javascript
let x = 1;
let y = 2;

[x, y] = [y, x];
```

提取JSON数据。

```javascript
let json = {
  code: 0,
  data: {name: 'hi'}
};
let { code, data: user } = json;
console.log(code, user); // 0 {name: 'hi'}
```

遍历Map结构。

```javascript
const map = new Map();
map.set('name', 'hello');
map.set('age', 12);

for (let [key, value] of map) {
  console.log(key + " is " + value);
}
```



## 扩展

#### 字符串扩展

模版字符串，这个很有用。使用反引号（`）标识。它可以当作普通字符串使用，也可以用来定义多行字符串，或者在字符串中嵌入变量。

```javascript
`User ${user.name} is login...`);
```

#### 函数扩展

ES6 允许为函数的参数设置默认值，即直接写在参数定义的后面。

> 一旦设置了参数的默认值，函数进行声明初始化时，参数会形成一个单独的作用域（context）。等到初始化结束，这个作用域就会消失。这种语法行为，在不设置参数默认值时，是不会出现的。

```javascript
function add(x, y = 1) {
	return x + y
}
```

替代apply()写法。

```javascript
// ES5 的写法
Math.max.apply(null, [1, 3, 2])

// ES6 的写法
Math.max(...[1, 3, 2])
```

#### 数组扩展

合并数组

```javascript
// ES5 的写法
var list = [1,2]
list = list.concat([3])

// ES6 的写法
var list = [1,2]
list = [...list, 3]
```

数组新API

Array.from()，Array.of()，find() 和 findIndex()等，参考MDN

> https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array

#### 对象扩展

对象属性，方法简写。

```javascript
data = [1,2]
const resp = {data}; // 属性简写，等同于 {data: data}
const obj = {
  add(x, y) {        // 方法简写，等同于 add: function(x, y){...}
    return x + y;
  }
};
```

扩展属性。

```javascript
const point = {x: 1, y: 2}
const pointD = {...point, z: 3}
console.log(pointD) // {x: 1, y: 2, z: 3}

// 当有重复属性时，注意顺序问题。
const point = {x: 1, y: 2}
const pointD = {...point, x: 4, z: 3}
console.log(pointD) // {x: 4, y: 2, z: 3}

const point = {x: 1, y: 2}
const pointD = {x: 4, z: 3, ...point}
console.log(pointD) // {x: 1, z: 3, y: 2}

```

属性的描述对象

对象的每个属性都有一个描述对象（Descriptor），用来控制该属性的行为。

```javascript
const point = {x: 1, y: 2}
Object.getOwnPropertyDescriptor(point, 'x') 
/**
{	configurable: true
 	enumerable: true // 表示可枚举
	value: 1
	writable: true   // 表示可写
 }
**/
```

属性的遍历

- `for...in`循环：只遍历对象自身的和继承的可枚举的属性。
- `Object.keys()`：返回对象自身的所有可枚举的属性的键名。
- `JSON.stringify()`：只串行化对象自身的可枚举的属性。
- `Object.assign()`： 忽略`enumerable`为`false`的属性，只拷贝对象自身的可枚举的属性。

```javascript
const point = {x: 1, y: 2}
for(let key in point){
  console.log(key)
}
```

对象新增的一些方法：Object.assign()

`Object.assign()`方法实行的是浅拷贝，而不是深拷贝。也就是说，如果源对象某个属性的值是对象，那么目标对象拷贝得到的是这个对象的引用。常见用途：

克隆对象

```javascript
function clone(origin) {
  return Object.assign({}, origin);
}
```

合并对象

```javascript
const merge = (target, ...sources) => Object.assign(target, ...sources);
```

指定默认值

```javascript
const DEFAULT_CONFIG = {
  debug: true,
};

function process(options) {
  options = Object.assign({}, DEFAULT_CONFIG, options);
  console.log(options);
  // ...
}
```



> https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object



#### 运算符扩展

指数运算符

```javascript
2 ** 10 // 1024
2 ** 3 ** 2 // 512 相当于 2 ** (3 ** 2)

let a=10; a **= 3; // 相当于 a = a * a * a
```

链判断运算符

`obj?.prop`判断对象属性是否存在，`func?.(...args)`  函数或对象方法是否存在。

```javascript
const obj = {name: 'job', say(){console.log('hello')}}
obj?.name  // 等于 obj == null ? undefined : obj.name
obj?.say() // 等于 obj == null ? undefined : obj.say()
```

空判断运算符

JavaScript里我们用`||`运算符指定默认值。 当我们希望左边是null和undefined时才触发默认值时，使用`??`。

```javascript
const obj = {name: ''}
obj.name || 'hello' // 'hello'
obj.name ?? 'hello' // ''
```

## for...of

因为`for...in`循环主要是为遍历对象而设计的，因为数组的键名是数字，所以遍历数组时候它返回的是数字，很明显这不能满足开发需求，使用`for...of`可以解决这个问题。

```javascript
const list = ['a', 'b', 'c']
for (let v in list){
  console.log(v) // 0,1,2
}
for (let v of list){
  console.log(v) // a,b,c
}
```

## 小结

本文要点回顾，欢迎留言交流。

- ES6介绍。
- let和const变量。
- 对象数组解构。
- 一些新的扩展。
