---
title: JavaScript的反射和代理
date: 2021-10-18 11:33:34
description: "JavaScript的反射和代理"
tags: ["JavaScript"]
categories: ["前端"]
keywords: ["JavaScript"]
---

## 什么是反射

反射这个概念在很多编程语言中都存在，像Java，C#。

在面向对象编程中，一般会先将类和方法定义好，然后创建对象显式调用方法，比如下面的例子：

```java
public class User{
   private String name;
   private Date birthday;
       //....
   public int calculateAgeByBirthday(){
            // .....
   }
}
// 调用    
User u = new User("jack", new Date());
u.calculateAgeByBirthday();
```

上面这种调用方式我们比较熟悉，不过当你想编写一些抽象框架时（框架又需要与业务定义的类进行互操作），由于你不知道业务类的成员和方法，这时反射动态获取成员变量或调用方法。

下面例子，我们利用反射将json转换为Java对象。

```java
public static class User {
	private String name;
	public String getName() {
    return name;
	}
   public void setName(String name) {
     this.name = name;
   }
}

// 使用反射调用对象setter方法。
public static <T> T fill(Class<T> userClass, Map<String, Object> json) throws Exception {
        Field[] fields = userClass.getDeclaredFields();
        T user = userClass.newInstance();
        for (Field field : fields) {
            // 首字母大写
            String name = field.getName();
            char[] arr = name.toCharArray();
            arr[0] = Character.toUpperCase(arr[0]);
            System.out.println(new String(arr));
            Method method = userClass.getDeclaredMethod("set" + new String(arr), field.getType());
            Object returnValue = method.invoke(user, json.get(name));
        }
        return user;
}

```



# JavaScript中Reflect

JavaScript在ES6提供了反射内置对象`Reflect`，但JavaScript里面的反射和Java反射有所不同。先看下`Reflect`提供的13个静态方法。

- Reflect.apply(target, thisArg, args)
- Reflect.construct(target, args)
- Reflect.get(target, name, receiver)
- Reflect.set(target, name, value, receiver)
- Reflect.defineProperty(target, name, desc)
- Reflect.deleteProperty(target, name)
- Reflect.has(target, name)
- Reflect.ownKeys(target)
- Reflect.isExtensible(target)
- Reflect.preventExtensions(target)
- Reflect.getOwnPropertyDescriptor(target, name)
- Reflect.getPrototypeOf(target)
- Reflect.setPrototypeOf(target, prototype)

### Reflect.get(target, name, receiver)

`Reflect.get`方法查找并返回`target`对象的`name`属性，如果没有该属性，则返回`undefined`。

```javascript
const obj = {
  name: 'jack',
  age: 12,
  get userInfo() {
    return this.name + ' age is ' + this.age;
  }
}

Reflect.get(obj, 'name') // jack
Reflect.get(obj, 'age') // 12
Reflect.get(obj, 'userInfo') // jack age is 12

// 如果传递了receiver参数，在调用userInfo()函数时，this是指向receiver对象。
const receiverObj = {
  name: '小明',
  age: 22
};

Reflect.get(obj, 'userInfo', receiverObj) // 小明 age is 22
```

### Reflect.set(target, name, value, receiver)

```javascript
const obj = {
  name: 'jack',
  age: 12,
  set updateAge(value) {
    return this.age = value;
  },
}
Reflect.set(obj, 'age', 22);
obj.age // 22

// 如果传递了receiver参数，在调用updateAge()函数时，this是指向receiver对象。
const receiverObj = {
  age: 0
};

Reflect.set(obj, 'updateAge', 10, receiverObj) // 
obj.age         // 22
receiverObj.age // 10
```

### Reflect.has(obj, name)

`Reflect.has`方法相当于`name in obj`里面的`in`运算符。

```javascript
const obj = {
  name: 'jack',
}
obj in name // true
Reflect.has(obj, 'name') // true
```

### Reflect.deleteProperty(obj, name)

`Reflect.deleteProperty`方法相当于`delete obj[name]`，用于删除对象的属性。如果删除成功，或者被删除的属性不存在，返回`true`；删除失败，被删除的属性依然存在，返回`false`。

```javascript
const obj = {
  name: 'jack',
}
delete obj.name 
Reflect.deleteProperty(obj, 'name')
```

### Reflect.construct(target, args)

`Reflect.construct`方法等同于`new target(...args)`。

```javascript
function User(name){
  this.name = name;
}
const user = new User('jack');
Reflect.construct(User, ['jack']);
```

### Reflect.getPrototypeOf(obj)

`Reflect.getPrototypeOf`方法用于读取对象的`__proto__`属性。

### Reflect.setPrototypeOf(obj, newProto)

`Reflect.setPrototypeOf`方法用于设置目标对象的原型（prototype）。返回一个布尔值，表示是否设置成功。

```javascript
const obj = {
  name: 'jack',
}
Reflect.setPrototypeOf(obj, Array.prototype);
obj.length // 0 
```

### Reflect.apply(func, thisArg, args) 

`Reflect.apply`方法相当于`Function.prototype.apply.call(func, thisArg, args)`，用于绑定`this`对象后执行给定函数。

```javascript
const nums = [1,2,3,4,5];
const min = Math.max.apply(Math, nums);
// 通过 Reflect.apply 调用
const min = Reflect.apply(Math.min, Math, nums);
```

### Reflect.defineProperty(target, propertyKey, attributes) 

`Reflect.defineProperty`方法相当于`Object.defineProperty`，用来为对象定义属性。

```javascript
const obj = {};
Object.defineProperty(obj, 'property', {
  value: 0,
  writable: false
});

Reflect.defineProperty(obj, 'property', {
  value: 0,
  writable: false
});
```

### Reflect.getOwnPropertyDescriptor(target, propertyKey)

获取指定属性的描述对象。

### Reflect.isExtensible (target)

返回一个布尔值，表示当前对象是否可扩展。

### Reflect.preventExtensions(target) 

用于让一个对象变为不可扩展。它返回一个布尔值，表示是否操作成功。

### Reflect.ownKeys (target)

`Reflect.ownKeys`方法用于返回对象的所有属性。

```javascript
const obj = {
  name: 'jack',
  age: 12,
  get userInfo() {
    return this.name + ' age is ' + this.age;
  }
}
Object.getOwnPropertyNames(obj)
Reflect.ownKeys(obj) // ['name', 'age', 'userInfo']
```



## JavaScript中Proxy

代理在编程中很有用，它可以在目标对象之前增加一层“拦截”实现一些通用逻辑。

Proxy 构造函数 `Proxy(target, handler)` 参数：

- target：代理的目标对象，它可以是任何类型的对象，包括内置的数组，函数，代理对象。
- handler：它是一个对象，它的属性提供了某些操作发生时的处理函数。

```javascript
const user = {name: 'hello'}
const proxy = new Proxy(user, {
  get: function(target, property) { // 读取属性时触发
    return 'hi';
  }
});
proxy.name // 'hi'

```

#### Proxy中支持的拦截操作

- handler.get(target, property, receiver)
- handler.set(target, property, value, receiver)
- handler.has(target, property)
- handler.defineProperty(target, property, descriptor)
- handler.deleteProperty(target, property)
- handler.getOwnPropertyDescriptor(target, prop)
- handler.getPrototypeOf(target)
- handler.setPrototypeOf(target, prototype)
- handler.isExtensible(target)
- handler.ownKeys(target)
- handler.preventExtensions(target)

- handler.apply(target, thisArg, argumentsList)
- handler.construct(target, argumentsList, newTarget)

### get()

用于拦截某个属性的读取操作，可以接受三个参数，依次为目标对象、属性名和 proxy 实例本身，其中最后一个参数可选。

```javascript
const user = {
  name: 'jack'
}
// 只有属性存在才返回值，否则抛出异常。
const proxy = new Proxy(user, {
  get: function(target, property) {
    if (!(property in target)) {
       throw new ReferenceError(`${property} does not exist.`);
    }
    return target[property];
  }
});
proxy.name // jack
proxy.age // ReferenceError: age does not exist.
```

我们可以定义一些公共代理对象，然后让子对象继承。

```javascript
// 只有属性存在才返回值，否则抛出异常。
const proxy = new Proxy({}, {
  get: function(target, property) {
    if (!(property in target)) {
       throw new ReferenceError(`${property} does not exist.`);
    }
    return target[property];
  }
});
let obj = Object.create(proxy);
obj.name = 'hello'
obj.name // hello
obj.age // ReferenceError: age does not exist.
```

### set()

用来拦截某个属性的赋值操作，可以接受四个参数，依次为目标对象、属性名、属性值和 Proxy 实例本身，其中最后一个参数可选。

```javascript
// 字符类型的属性长度校验
let sizeValidator = {
  set: function(target, property, value, receiver) {
    if (typeof value == 'string' && value.length > 5) {
       throw new RangeError('Cannot exceed 5 character.');
    }
    target[property] = value;
    return true;
  }
};

const validator = new Proxy({}, sizeValidator);
let obj = Object.create(validator);
obj.name = '123456' // RangeError: Cannot exceed 5 character.
obj.age = 12 				// 12
```

### has()

用来拦截`HasProperty`操作，即判断对象是否具有某个属性时，这个方法会生效。如`in`运算符。

它接受两个参数，分别是目标对象、需查询的属性名。

```javascript
const handler = {
  has (target, key) {
    if (key[0] === '_') {
      return false;
    }
    return key in target;
  }
};
var target = { _prop: 'foo', prop: 'foo' };
var proxy = new Proxy(target, handler);
'_prop' in proxy // false
```



### defineProperty()

`defineProperty()`方法拦截了`Object.defineProperty()`操作。

### deleteProperty()

用于拦截`delete`操作，如果这个方法抛出错误或者返回`false`，当前属性就无法被`delete`命令删除。

### getOwnPropertyDescriptor()

`getOwnPropertyDescriptor()`方法拦截`Object.getOwnPropertyDescriptor()`，返回一个属性描述对象或者`undefined`。

### getPrototypeOf() 

主要用来拦截获取对象原型，拦截的操作如下：

- Object.getPrototypeOf()
- Reflect.getPrototypeOf()
- `__proto__`
- Object.prototype.isPrototypeOf()
- instanceof

```javascript
const obj = {};
const proto = {};
const handler = {
    getPrototypeOf(target) {
        console.log(target === obj);   // true
        console.log(this === handler); // true
        return proto;
    }
};

const p = new Proxy(obj, handler);
console.log(Object.getPrototypeOf(p) === proto);    // true
```

### setPrototypeOf() 

主要用来拦截`Object.setPrototypeOf()`方法。

```javascript
const handlerReturnsFalse = {
    setPrototypeOf(target, newProto) {
        return false;
    }
};

const newProto = {}, target = {};

const p1 = new Proxy(target, handlerReturnsFalse);
Object.setPrototypeOf(p1, newProto); // throws a TypeError
Reflect.setPrototypeOf(p1, newProto); // returns false

```

### isExtensible()

方法拦截`Object.isExtensible()`操作。

```javascript
const p = new Proxy({}, {
  isExtensible: function(target) {
    console.log('called');
    return true;//也可以return 1;等表示为true的值
  }
});

console.log(Object.isExtensible(p)); // "called"
                                     // true
```

### ownKeys()

用来拦截对象自身属性的读取操作。具体来说，拦截以下操作。

- `Object.getOwnPropertyNames()`
- `Object.getOwnPropertySymbols()`
- `Object.keys()`
- `for...in`循环。

```javascript
const p = new Proxy({}, {
  ownKeys: function(target) {
    console.log('called');
    return ['a', 'b', 'c'];
  }
});

console.log(Object.getOwnPropertyNames(p)); // "called"
```

### preventExtensions()

用来拦截`Object.preventExtensions()`。该方法必须返回一个布尔值，否则会被自动转为布尔值。

这个方法有一个限制，只有目标对象不可扩展时（即`Object.isExtensible(proxy)`为`false`），`proxy.preventExtensions`才能返回`true`，否则会报错。

```javascript
const p = new Proxy({}, {
  preventExtensions: function(target) {
    console.log('called');
    Object.preventExtensions(target);
    return true;
  }
});

console.log(Object.preventExtensions(p)); // "called"
                                          // false
```

### apply()

`apply`方法拦截以下操作。

- `proxy(...args)`
- `Function.prototype.apply()` 和 `Function.prototype.call()`
- `Reflect.apply()`

它接受三个参数，分别是目标对象、目标对象的上下文对象（`this`）和目标对象的参数数组。

```javascript
const handler = {
  apply (target, ctx, args) {
    return Reflect.apply(...arguments);
  }
};
```

例子

```javascript
const target = function () { };
const handler = {
  apply: function (target, thisArg, argumentsList) {
    console.log('called: ' + argumentsList.join(', '));
    return argumentsList[0] + argumentsList[1] + argumentsList[2];
  }
};

const p = new Proxy(target, handler);
p(1,2,3) // "called: 1, 2, 3" 6
```

### construct()

用于拦截`new`命令，下面是拦截对象的写法：

```javascript
const handler = {
  construct (target, args, newTarget) {
    return new target(...args);
  }
};
```

它方法接受三个参数。

- `target`：目标对象。
- `args`：构造函数的参数数组。
- `newTarget`：创造实例对象时，`new`命令作用的构造函数。

注意：方法返回的必须是一个对象，目标对象必须是函数，否则就会报错。

```javascript
const p = new Proxy(function() {}, {
  construct: function(target, argumentsList) {
    return 0;
  }
});

new p() // 返回值不是对象，报错

const p = new Proxy({}, {
  construct: function(target, argumentsList) {
    return {};
  }
});
new p() //目标对象不是函数，报错
```



## 观察者模式

观察者是一种很常用的模式，它的定义是当一个对象的状态发生改变时，所有依赖于它的对象都得到通知并被自动更新。

我们使用Proxy 来实现一个例子，当观察对象状态变化时，让观察函数自动执行。

观察者函数，包裹观察目标，添加观察函数。

- `observable`包裹观察目标，返回一个Proxy对象。
- `observe` 添加观察函数到队列。

```javascript
const queuedObservers = new Set();

const observe = fn => queuedObservers.add(fn);
const observable = obj => new Proxy(obj, {set});
// 属性改变时，自动执行观察函数。
function set(target, key, value, receiver) {
  const result = Reflect.set(target, key, value, receiver);
  queuedObservers.forEach(observer => observer());
  return result;
}
```

例子

```javascript
const user = observable({
  name: 'jack',
  age: 20
});

function userInfo() {
  console.log(`${user.name}, ${user.age}`)
}

observe(userInfo);
user.name = '小明'; // 小明, 20
```



## 小结

本文要点回顾，欢迎留言交流。

- JavaScript中的内置Reflect。
- JavaScript中的内置Proxy。
- Proxy实现观察者模式。
