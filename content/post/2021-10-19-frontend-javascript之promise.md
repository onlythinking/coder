---
title: "Promise详解 - JavaScript异步编程完整指南 | 编程码农"
date: "2021-10-19T18:17:03+08:00"
description: "什么是Promise Promise 是异步编程的一种解决方案。ES6中已经提供了原生Promise对象。一个Promise对象会处于以下几种状态（fulfilled，rejected两种状态一旦确定后不会改变）： - 待定（pending）: 初始状/态，既没有被兑现，也没有被拒绝。 - 已兑现（..."
tags:
  - "JavaScript"
  - "Java"
  - "前端"
  - "异步编程"
  - "Promise"
categories:
  - "前端开发"
keywords:
  - "JavaScript"
  - "Java"
  - "前端开发"
  - "异步编程"
  - "Promise"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

## 什么是Promise

Promise 是异步编程的一种解决方案。ES6中已经提供了原生`Promise`对象。一个`Promise`对象会处于以下几种状态（fulfilled，rejected两种状态一旦确定后不会改变）：

- 待定（pending）: 初始状/态，既没有被兑现，也没有被拒绝。
- 已兑现（fulfilled）: 意味着操作成功完成。
- 已拒绝（rejected）: 意味着操作失败。



![promises](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/promises.png)

## 基本用法

`Promise`对象是一个构造函数，用来创建`Promise`实例，它接收两个参数`resolve`和`reject`。

- `resolve`的作用是将`Promise`对象的状态从`pending`变为`fulfilled`，在异步操作成功时调用，并将异步操作的结果，作为参数传递出去。
- `reject`的作用是将`Promise`对象的状态从`pending`变为`rejected`，在异步操作失败时调用，并将异步操作报出的错误，作为参数传递出去。

```javascript
const promise = new Promise(function(resolve, reject) {
  // ... 
  if (/* 异步操作成功 */){
    resolve(value);
  } else {
    reject(error);
  }
});
```

`Promise`实例生成以后，使用`then`方法分别指定`fulfilled`状态和`rejected`状态的回调函数。

- `then`接收两个参数，第一个是`Promise`对象的状态变为`fulfilled`时的回调函数，第二个是状态变为`rejected`时的回调函数。
- `catch`接收`Promise`对象的状态变为`rejected`时的回调函数。

```javascript
promise.then(function (value){
	// ....
},function (err){
	// .... err
})
  
promise.then(function (value){
	// ....
}).catch(function (err){
    // ....
})
```



## Promise的方法

### Promise.prototype.then() 

`then`方法是定义在原型对象`Promise.prototype`上，前面说过，它接收两个可选参数，第一个参数是`fulfilled`状态的回调函数，第二个参数是`rejected`状态的回调函数。

`then`方法返回的是一个新的`Promise`实例，方便我们采用链式写法。比如`then`后面接着写`then`，当第一个回调函数完成以后，会将返回结果作为参数，传入第二个回调函数。这种链式方式可以很方便的指定一组按照次序调用的回调函数。

```javascript
loadData().then(function (value){
    return 3
}).then(function (num){
    console.log("ok", num) // 3
})
```



### Promise.prototype.catch()

`catch`方法是用于指定发生错误时的回调函数。如果异步操作抛出错误，状态就会变为`rejected`，就会调用`catch()`方法指定的回调函数，处理这个错误。

```javascript
const promise = new Promise(function(resolve, reject) {
  throw new Error('unkonw error'); // 抛出错误状态变为 -> reject
});
const promise = new Promise(function(resolve, reject) {
  reject('unkonw error') // 使用reject()方法将状态变为 -> reject
});
promise.catch(function(error) {
  console.log(error);
});
```

`Promise`对象的错误会一直向后传递，直到被捕获为止。比如下面代码：`catch`会捕获`loadData`和两个`then`里面抛出的错误。

```javascript
loadData().then(function(value) {
  return loadData(value);
}).then(function(users) {
 
}).catch(function(err) {
  // 处理前面三个Promise产生的错误
});
```

如果我们不设置`catch()`，当遇到错误时`Promise`不会将错误抛出外面，也就是不会影响外部代码执行。

```javascript
const promise = new Promise(function(resolve, reject) {
  	resolve(a) // ReferenceError: a is not defined
});
promise.then(function(value) {
  console.log('value is ', value)
});
setTimeout(() => { console.log('code is run') }, 1000); // code is run
```

### Promise.prototype.finally()

`finally()`方法不管 Promise 对象最后状态如何，都会执行的操作。下面是我们使用 Promise 的一个常规结构。

```javascript
promise
.then(result => {···})
.catch(error => {···})
.finally(() => {···});
```

### Promise.all()

`Promise.all()`方法可以将多个 Promise 实例包装成一个新的 Promise 实例返回。

```javascript
const promise = Promise.all([p1, p2, p3]);
```

新`promise`状态来依赖于“传入的`promise`”。

- 只有当所有“传入的`promise`”状态都变成`fulfilled`，它的状态才会变成`fulfilled`，此时“传入的`promise`”返回值组成一个数组，传递给`promise`的回调函数。
- 如果“传入的`promise`”之中有一个被`rejected`，新`promise`的状态就会变成`rejected`，此时第一个被`reject`的`promise`的返回值，会传递给`promise`的回调函数。

```javascript
const promises = [1,2,3,4].map(function (id) {
  return loadData(id);
});

Promise.all(promises).then(function (users) {
  // ...
}).catch(function(err){
  // ...
});
```



### Promise.race()

`Promise.race()`方法同样是将多个 Promise 实例，包装成一个新的 Promise 实例。

`Promise.race()`方法的参数与`Promise.all()`方法一样。

```javascript
const promise = Promise.race([p1, p2, p3]);
```

`Promise.all()` 和 `Promise.race()`对比：

- `Promise.all()` ，如果所有都执行成功则返回所有成功的`promise`值，如果有失败则返回第一个失败的值。
- `Promise.race()`，返回第一个执行完成的`promise` 值，它可能是fulfilled和rejected状态。

这两个方法的使用场景。

**场景一**，用户登录社交网站主页后，会同时异步请求拉取用户信息，关注列表，粉丝列表，我们需要保证所有数据请求成功再进行渲染页面，只要有一个数据不成功就会重定向页面，这里可以使用`Promise.all`。

```javascript
function initUserHome() {
  Promise.all([
  new Promise(getMe),
  new Promise(getFollows),
  new Promise(getFans)
])  
    .then(function(data){
    	// 显示页面
  })
    .catch(function(err){
    // .... 重定向页面
  });
};

initUserHome();
```

**场景二**，假如我们在做一个抢票软件，虽然请求了很多卖票渠道，每次只需返回第一个执行完成的`Promise`，这里可以使用`Promise.race`。

```java
function getTicket() {
  Promise.race([
  new Promise(postASell),
  new Promise(postBSell),
  new Promise(postCSell)
])  
    .then(function(data){
    	// 抢票成功
  })
    .catch(function(err){
    // .... 抢票失败，重试
  });
};

getTicket();
```



### Promise.allSettled()

使用`Promise.all()`时，如果有一个`Promise` 失败后，其它`Promise` 不会停止执行。

```javascript
const requests = [
  fetch('/url1'),
  fetch('/url2'),
  fetch('/url3'),
];

try {
  await Promise.all(requests);
  console.log('所有请求都成功。');
} catch {
  console.log('有一个请求失败，其他请求可能还没结束。');
}
```

有的时候，我们希望等到一组异步操作都结束了，再进行下一步操作。这时就需要使用`Promise.allSettled()`，的它参数是一个数组，数组的每个成员都是一个 Promise 对象，返回一个新的 Promise 对象。它只有等到参数数组的所有 Promise 对象都发生状态变更（不管是`fulfilled`还是`rejected`），返回的 Promise 对象才会发生状态变更。

```javascript
const requests = [
  fetch('/url1'),
  fetch('/url2'),
  fetch('/url3'),
];

await Promise.allSettled(requests);
console.log('所有请求完成后（包括成功失败）执行');

```



### Promise.any()

只要传入的`Promise`有一个变成`fulfilled`状态，新的`Promise`就会变成`fulfilled`状态；如果所有传入的`Promise`都变成`rejected`状态，新的`Promise`就会变成`rejected`状态。

`Promise.any()`和`Promise.race()`差不多，区别在于`Promise.any()`不会因为某个 `Promise` 变成`rejected`状态而结束，必须等到所有参数 `Promise` 变成`rejected` 状态才会结束。

回到`Promise.race()`多渠道抢票的场景，如果我们需要保证要么有一个渠道抢票成功，要么全部渠道都失败，使用`Promise.any()`就显得更合适。

```javascript
function getTicket() {
  Promise.any([
  new Promise(postASell),
  new Promise(postBSell),
  new Promise(postCSell)
])  
    .then(function(data){
    	// 有一个抢票成功
  })
    .catch(function(err){
    // .... 所有渠道都失败了
  });
};

getTicket();
```



### Promise.resolve()

`Promise.resolve()`方法将现有对象转换为`Promise`对象。等价于下面代码：

```javascript
new Promise(resolve => resolve(1))
```

传入的参数不同，处理

1. 参数`Promise` 实例，它将不做任何修改、原封不动地返回这个实例。

2. 参数`thenable`对象，它会将这个对象转为 `Promise` 对象，然后就立即执行`thenable`对象的`then()`方法。

   ```javascript
   let thenable = {
     then: function(resolve, reject) {
       resolve(1);
     }
   };
   ```

3. 参数是普通值，返回一个新的 Promise 对象，状态为`resolved`。

   ```javascript
   const promise = Promise.resolve(1);
   
   promise.then(function (value) {
     console.log(value) // 1
   });
   ```

4. 无参数，直接返回一个`resolved`状态的 Promise 对象。



### Promise.reject()

`Promise.reject(reason)`方法也会返回一个新的 Promise 实例，该实例的状态为`rejected`。

```javascript
const promise = Promise.reject('unkonw error');
// 相当于
const promise = new Promise((resolve, reject) => reject('unkonw error'))

promise.then(null, function (s) {
  console.log(s)
});
// unkonw error
```



## 简单场景

异步加载图片：

```javascript
function loadImageAsync(url) {
  return new Promise(function(resolve, reject) {
	  const image = new Image();
    image.onload  = resolve;
    image.onerror = reject;
    image.src = url;
  });
}
```

请求超时处理：

```javascript
//请求
function request(){
    return new Promise(function(resolve, reject){
      	// code ....
         resolve('request ok')
    })
}

function timeoutHandle(time){
 		return new Promise(function(resolve, reject){
        setTimeout(function(){
            reject('timeout');
        }, time);
    });
}

Promise.race([
    request(),
    timeoutHandle(5000)
])
.then(res=>{
    console.log(res)
}).catch(err=>{
    console.log(err)// timeout
})

```



## 小结

本文归纳了`Promise`相关方法和一些简单用法，欢迎留言交流。
