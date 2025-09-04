---
title: "JavaScript中的class | 编程码农"
date: "2021-10-19T09:53:14+08:00"
description: "类 类是用于创建对象的模板。JavaScript中生成对象实例的方法是通过构造函数，这跟主流面向对象语言（java，C）写法上差异较大，如下： `javascript function Point(x, y) {   this.x = x;   this.y = y; } Point.prototy..."
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

## 类

类是用于创建对象的模板。JavaScript中生成对象实例的方法是通过构造函数，这跟主流面向对象语言（java，C#）写法上差异较大，如下：

```javascript
function Point(x, y) {
  this.x = x;
  this.y = y;
}

Point.prototype.toString = function () {
  return '(' + this.x + ', ' + this.y + ')';
};

var p = new Point(1, 1);
```

ES6 提供了更接近Java语言的写法，引入了 Class（类）这个概念，作为对象的模板。通过`class`关键字，可以定义类。

如下：`constructor()`是构造方法，而`this`代表实例对象：

```javascript
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  toString() {
    return '(' + this.x + ', ' + this.y + ')';
  }
}
```

类的数据类型就是函数，它本身就是指向函数的构造函数：

```javascript
// ES5 函数声明
function Point() {
	//...
}

// ES6 类声明
class Point {
  //....
  constructor() {
  }
}
typeof Point // "function"
Point === Point.prototype.constructor // true
```

在类里面定义的方法是挂到`Point.prototype`，所以类只是提供了语法糖，本质还是原型链调用。

```javascript
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  toString() {
    return '(' + this.x + ', ' + this.y + ')';
  }
}

Point.prototype = {
  //....
  toString()
}
var p = new Point(1, 1);
p.toString() // (1,1)
```

类的另一种定义方式**类表达式**

```javascript
// 未命名/匿名类
let Point = class {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
};
Point.name // Point
```

> 函数声明和类声明有个重要区别，函数声明会提升，类声明不会提升。
>
> ```javascript
> let p = new Point(); // 被提升不会报错
> function Point() {}
> 
> let p = new Point(); // 报错，ReferenceError
> class Point {}
> ```

### constructor()

`constructor()`方法是类的默认方法，`new`生成实例对象时会自动调用该方法。

一个类必须有`constructor()`方法，如果没有显式定义，引擎会默认添加一个空的`constructor()`。

`constructor()`方法默认返回实例对象（即`this`）。

```javascript
class Point {
}

// 自动添加
class Point {
  constructor() {}
}
```

### getter和setter

与 ES5 一样，在类的内部可以使用`get`和`set`关键字，对某个属性设置存值函数和取值函数，拦截该属性的存取行为。

```javascript
class User {
  constructor(name) {
    this.name = name;
  }

  get name() {
    return this.name;
  }

  set name(value) {
    this.name = value;
  }
}

```



### this

类的方法内部的`this`，它默认指向类的实例，在调用存在`this`的方法时，需要使用 `obj.method()`方式，否则会报错。

```javascript
class User {
  constructor(name) {
    this.name = name;
  }
  printName(){
    console.log('Name is ' + this.name)
  }
}
const user = new User('jack')
user.printName() // Name is jack
const { printName } = user;
printName()     // 报错 Cannot read properties of undefined (reading 'name')
```

如果要单独调用又不报错，一种方法可以在构造方法里调用`bind(this)`。

```javascript
class User {
  constructor(name) {
    this.name = name;
    this.printName = this.printName.bind(this);
  }
  printName(){
    console.log('Name is ' + this.name)
  }
}
const user = new User('jack')
const { printName } = user;
printName()     // Name is jack
```

> **`bind(this)`** 会创建一个新函数，并将传入的`this`作为该函数在调用时上下文指向。

另外可以使用箭头函数，因为箭头函数内部的`this`总是指向定义时所在的对象。

```javascript
class User {
  constructor(name) {
    this.name = name;
  }
  printName = () => {
    console.log('Name is ' + this.name)
  }
}
const user = new User('jack')
const { printName } = user;
printName()     // Name is jack
```

### 静态属性

静态属性指的是类本身的属性，而不是定义在实例对象`this`上的属性。

```javascript
class User {
}

User.prop = 1;
User.prop // 1
```



### 静态方法

可以在类里面定义静态方法，该方法不会被对象实例继承，而是直接通过类来调用。

静态方法里使用`this`是指向类。

```javascript
class Utils {
  static printInfo() {
     this.info();
  }
  static info() {
     console.log('hello');
  }
}
Utils.printInfo() // hello
```

关于方法的调用范围限制，比如：私有公有，ES6暂时没有提供，一般是通过约定，比如：在方法前面加下划线`_print()`表示私有方法。



## 继承

Java中通过`extends`实现类的继承。ES6中类也可以通过`extends`实现继承。

继承时，子类必须在`constructor`方法中调用`super`方法，否则新建实例时会报错。

```javascript
class Point3D extends Point {
  constructor(x, y, z) {
    super(x, y); // 调用父类的constructor(x, y)
    this.z = z;
  }

  toString() {
    return super.toString() + '  ' + this.z ; // 调用父类的toString()
  }
}
```

父类的静态方法，也会被子类继承。

```javascript
class Parent {
  static info() {
    console.log('hello world');
  }
}

class Child extends Parent {
}

Child.info()  // hello world

```

### super关键字

在子类的构造函数必须执行一次`super`函数，它代表了父类的构造函数。

```javascript
class Parent {}

class Child extends Parent {
  constructor() {
    super();
  }
}
```

在子类普通方法中通过`super`调用父类的方法时，方法内部的`this`指向当前的子类实例。

```javascript
class Parent {
  constructor() {
    this.x = 1;
    this.y = 10
  }
  printParent() {
    console.log(this.y);
  }
  print() {
    console.log(this.x);
  }
}

class Child extends Parent {
  constructor() {
    super();
    this.x = 2;
  }
  m() {
    super.print();
  }
}

let c = new Child();
c.printParent() // 10
c.m() // 2
```



### `_proto_`和`prototype`

初学JavaScript时，`_proto_`和`prototype` 很容易混淆。首先我们知道每个JS对象都会对应一个原型对象，并从原型对象继承属性和方法。

- `prototype` 一些内置对象和函数的属性，它是一个指针，指向一个对象，这个对象的用途就是包含所有实例共享的属性和方法（我们把这个对象叫做原型对象）。

- `_proto_` 每个对象都有这个属性，一般指向对应的构造函数的`prototype`属性。

下图是一些拥有`prototype`内置对象。



![image-20211019153401235](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211019153401235.png)

根据上面描述，看下面代码

```javascript
var obj = {} // 等同于 var obj = new Object()

// obj.__proto__指向Object构造函数的prototype
obj.__proto__ === Object.prototype // true 

// obj.toString 调用方法从Object.prototype继承
obj.toString === obj.__proto__.toString // true

// 数组
var arr = []
arr.__proto__ === Array.prototype // true 
```

对于function对象，声明的每个function同时拥有`prototype`和`__proto__`属性，创建的对象属性`__proto__`指向函数`prototype`，函数的`__proto__`又指向内置函数对象（Function）的`prototype`。

```javascript
function Foo(){}
var f = new Foo();
f.__proto__ === Foo.prototype // true
Foo.__proto__ === Function.prototype // true

```

### 继承中的`__proto__`

类作为构造函数的语法糖，也会同时有`prototype`属性和`__proto__`属性，因此同时存在两条继承链。

1. 子类的`__proto__`属性，表示构造函数的继承，总是指向父类。
2. 子类`prototype`属性的`__proto__`属性，表示方法的继承，总是指向父类的`prototype`属性。

```javascript
class Parent {
}

class Child extends Parent {
}

Child.__proto__ === Parent // true
Child.prototype.__proto__ === Parent.prototype // true
```



### 继承实例中的`__proto__`

子类实例的`__proto__`属性，指向子类构造方法的`prototype`。

子类实例的`__proto__`属性的`__proto__`属性，指向父类实例的`__proto__`属性。也就是说，子类的原型的原型，是父类的原型。

```javascript
class Parent {
}

class Child extends Parent {
}

var p = new Parent();
var c = new Child();

c.__proto__ === p.__proto__ // false
c.__proto__ === Child.prototype // true
c.__proto__.__proto__ === p.__proto__ // true

```



## 小结

JavaScript中的Class更多的还是语法糖，本质上绕不开原型链。欢迎大家留言交流。
