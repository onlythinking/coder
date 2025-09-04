---
title: "java并发之synchronized | 编程码农"
date: "2020-06-18T11:10:44+08:00"
description: "Java为我们提供了隐式（synchronized声明方式）和显式（java.util.concurrentAPI编程方式）两种工具来避免线程争用。 本章节探索Java关键字synchronized。主要包含以下几个内容。 - synchronized关键字的使用； - synchronized背后..."
tags:
  - "Java"
  - "并发编程"
  - "Class"
  - "HTML"
categories:
  - "Java开发"
keywords:
  - "Java"
  - "并发"
  - "ES6"
  - "synchronized"
  - "volatile"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

Java为我们提供了隐式（synchronized声明方式）和显式（java.util.concurrentAPI编程方式）两种工具来避免线程争用。

本章节探索Java关键字synchronized。主要包含以下几个内容。

- synchronized关键字的使用；
- synchronized背后的Monitor(管程)；
- synchronized保证可见性和防重排序；
- 使用synchronized注意嵌套锁定。



## 使用方式

synchronized 关键字有以下四种使用方式。

1. 实例方法
2. 静态方法
3. 实例方法中的代码块
4. 静态方法中的代码块

```java
// 实例方法同步和实例方法代码块同步
public class SynchronizedTest {
    private int count;
    public void setCountPart(int num) {
        synchronized (this) {
            this.count += num;
        }
    }
    public synchronized void setCount(int num) {
        this.count += num;
    }
}
```

```Java
// 静态方法同步和静态方法代码块同步
public class SynchronizedTest {
    private static int count;
    public static void setCountPart(int num) {
        synchronized (SynchronizedTest.class) {
            count += num;
        }
    }
    public static synchronized void setCount(int num) {
        count += num;
    }
}
```

使用关键字synchronized实现同步是在JVM内部实现处理，对于应用开发人员来说它是隐式进行的。

每个Java对象都有一个与之关联的monitor。

当线程调用实例同步方法时，会自动获取实例对象的monitor。

当线程调用静态同步方法时，会自动获取该类`Class`实例对象的monitor。

> Class实例：JVM为每个加载的class创建了对应的Class实例来保存class及interface的所有信息；



## Monitor（管程）

Monitor 直译为监视器，中文圈里称为**管程**。它的作用是让**线程互斥**，保护**共享数据**，另外也可以向其它线程**发送满足条件的信号**。

如下图，线程通过入口队列（Entry Queue）到达访问共享数据，若有线程占用转移等待队列（Wait Queue），线程访问共享数据完后触发通知或转移到信号队列（Signal Queue）。

![monitor](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/monitor.jpg)

**关于管程模型**

网上查询很多文章，大多数罗列 “ *Hasen 模型、Hoare 模型和 MESA模型* ”这些名词，看过之后我还是一知半解。本着对知识的求真，查找溯源，找到了以下资料。

为什么会有这三种模型？

假设有两个线程A和B，线程B先进入monitor执行，线程A处于等待。**当线程A执行完准备退出的时候，是先退出monitor还是先唤醒线程A？**这时就出现了*Mesa语义, Hoare语义和Brinch Hansen语义* 三种不同版本的处理方式。

#### **Mesa Semantics**

Mesa模型中 线程只会出现在WaitQueue，EntryQueue，Monitor。

当线程B发出信号告知线程A时，线程A从WaitQueue 转移到EntryQueue并等待线程B退出Monitor之后再进入Monitor。也就是先通知再退出。

![monitor_mesa](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/monitor_mesa.jpg)

#### 



#### **Brinch Hanson Semantics**

Brinch Hanson模型和Mesa模型类似区别在于仅允许线程B退出Monitor后才能发送信号给线程A。也就是先退出再通知。

![monitor_bh](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/monitor_bh.jpg)



#### **Hoare Semantics**

Hoare模型中 线程会分别出现在WaitQueue，EntryQueue，SignalQueue，Monitor中。

当线程B发出信号告知线程A并且退出Monitor转移到SignalQueue，线程A进入Monitor。当线程A离开Monitor后，线程B再次回到Monitor。

![monitor_hoare](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/monitor_hoare-2465373.jpg)

> https://www.andrew.cmu.edu/course/15-440-kesden/applications/ln/lecture6.html
>
> https://cseweb.ucsd.edu/classes/sp17/cse120-a/applications/ln/lecture8.html



Java里面monitor是如何处理？

我们通过反编译class文件看下Synchronized工作原理。

```Java
public class SynchronizedTest {
    private int count;
    public void setCountPart(int num) {
        synchronized (this) {
            this.count += num;
        }
    }
}
```

编译和反编译命令

```bash
javac SynchronizedTest.java
javap -v SynchronizedTest
```

我们看到两个关键指令 **monitorenter** 和 **monitorexit**

![jvm_syn](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/jvm_syn.png)



#### **monitorenter**

> Each object has a monitor associated with it. The thread that executes *monitorenter* gains ownership of the monitor associated with *objectref*. If another thread already owns the monitor associated with *objectref*, the current thread ......

每个对象都有一个关联monitor。

线程执行 monitorenter 时尝试获取关联对象的monitor。

获取时如果对象的monitor被另一个线程占有，则等待对方释放monitor后再次尝试获取。

如果获取成功则monitor计数器设置为1并将当前线程设为monitor拥有者，如果线程再次进入计数器自增，以表示进入次数。

#### **monitorexit**

> The current thread should be the owner of the monitor associated with the instance referenced by *objectref*......

线程执行monitorexit 时，monitor计数器自减，当计数器变为0时释放对象monitor。

> 原文：https://docs.oracle.com/javase/specs/jvms/se6/html/Instructions2.doc9.html





## 可见性和重排序

在介绍[Java并发之内存模型](https://www.onlythinking.com/2020/06/08/java%E5%B9%B6%E5%8F%91%E4%B9%8B%E5%86%85%E5%AD%98%E6%A8%A1%E5%9E%8B/)的时候，我们提到过<u>线程访问共享对象时会先拷贝副本到CPU缓存，修改后返回CPU缓存，然后等待时机刷新到主存。这样一来另外线程读到的数据副本就不是最新，导致了数据的不一致，一般也将这种问题称为**线程可见性问题**</u>。

不过在使用synchronized关键字的时候，情况有所不同。线程在进入synchronized后会同步该线程可见的所有变量，退出synchronized后，会将所有修改的变量直接同步到主存，可视为跳过了CPU缓存，这样一来就避免了可见性问题。

另外Java编译器和Java虚拟机为了达到优化性能的目的会对代码中的指令进行重排序。但是重排序会导致多线程执行出现意想不到的错误。使用synchronized关键字可以消除对**同步块共享变量**的重排序。



## 局限与性能

synchronized给我们提供了同步处理的便利，但是它在某些场景下也存在局限性，比如以下场景。

- 读多写少场景。读动作其实是安全，我们应该严格控制写操作。替代方案使用读写锁readwritelock。如果只有一个线程进行写操作，可使用volatile关键字替代。
- 允许多个线程同时进入场景。synchronized限制了每次只有一个线程可进入。替代方案使用信号量semaphore。
- 需要保证抢占资源公平性。synchronized并不保证线程进入的公平性。替代方案公平锁FairLock。

关于性能问题。进入和退出同步块操作性能开销很小，但是*过大范围设置同步*或者*在频繁的循环中使用同步*可能会导致性能问题。

可重入，在monitorenter指令解读中，可以看出synchronized是可重入，重入一般发生在同步方法嵌套调用中。不过要防止嵌套monitor死锁问题。

比如下面代码会直接造成死锁。

```java
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();
    public void method1()   {
        synchronized (lock1) {
            synchronized (lock2) {
            }
        }
    }
    public void method2()   {
        synchronized (lock2) {
            synchronized (lock1) {
            }
        }
    }
```

现实情况中，开发一般都不会出现以上代码。但在使用 wait() notify() 很可能会出现阻塞锁定。下面是一个模拟锁的实现。

1. 线程A调用lock()，进入锁定代码执行。
2. 线程B调用lock()，得到monitorObj的monitor后等待线程B唤醒。
3. 线程A执行完锁定代码后，调用unlock()，在尝试获取monitorObj的monitor时，发现有线程占用，也一直挂起。
4. 这样线程A B 就互相干瞪眼！

```java
public class Lock{
protected MonitorObj monitorObj = new MonitorObj();
    protected boolean isLocked = false;
    public void lock() throws InterruptedException{
        synchronized(this){
            while(isLocked){
                synchronized(this.monitorObj){
                    this.monitorObj.wait();
                }
            }
            isLocked = true;
        }
    }
    public void unlock(){
        synchronized(this){
            this.isLocked = false;
            synchronized(this.monitorObj){
                this.monitorObj.notify();
            }
        }
    }
}
```



## 总结

本文记录Java并发编程中synchronized相关的知识点。

欢迎大家留言交流，一起学习分享！！！