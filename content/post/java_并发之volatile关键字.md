---
title: java并发之volatile
date: 2020-06-19 16:20:49
tags: ["java并发"]
categories: ["java"]
keywords: ["java并发"]
---



Java面试中经常会涉及关于**volatile**的问题。本文梳理下volatile关键知识点。

volatile字意为“易失性”，在Java中用做修饰对象变量。它不是Java特有，在C，C++，C#等编程语言也存在，只是在其它编程语言中使用有所差异，但总体语义一致。比如使用volatile 能阻止编译器对变量的读写优化。简单说，如果一个变量被修饰为volatile，相当于告诉系统说我容易变化，编译器你不要随便优化（重排序，缓存）我。



## **Happens-before**

规范上，Java内存模型遵行**happens-before**。

volatile变量在多线程中，写线程和读线程具有happens-before关系。也就是写值的线程要在读取线程之前，并且读线程能完全看见写线程的相关变量。

> happens-before：如果两个有两个动作AB，A发生在B之前，那么A的顺序应该在B前面并且A的操作对B完全可见。
>
> happens-before  具有传递性，如果A发生在B之前，而B发生在C之前，那么A发生在C之前。



## 如何保证可见性

多线程环境下counter变量的更新过程。线程1先从主存拷贝副本到CPU缓存，然后CPU执行counter=7，修改完后写入CPU缓存，等待时机同步到主存。在线程1同步主存前，线程2读到counter值依然为0。此时已经发生内存一致性错误（对于相同的共享数据，多线程读到视图不一致）。因为线程2看不见线程1操作结果，也将这个问题称为**可见性问题**。

```java
public class SharedObject {
    public int counter = 0;
}
```

因为多了缓存优化导致，导致可见性问题。所以volatile通过消除缓存（描述可能不太准确）来避免。例如当使用volatile修饰变量后，操作该变量读写直接与主存交互，跳过缓存层，保证其它读线程每次获取的都是最新值。

```java
    public volatile int counter = 0;
```

![java-volatile-2](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/java-volatile-2.png)



volatile 不单只消除修饰的变量的缓存。事实上与之相关的变量在读写时也会消除缓存，如同使用了volatile一样。

如下 years，months，days 三个变量中只有days是volatile，但是对years，months读写操作也和days时也会跳过缓存，其它线程每次读到的都是最新值。

```Java
public class MyClass {
    private int years;
    private int months
    private volatile int days;
    public int totalDays() {
        int total = this.days;
        total += months * 30;
        total += years * 365;
        return total;
    }
    public void update(int years, int months, int days){
        this.years  = years;
        this.months = months;
        this.days   = days;
    }
}
```

这是为什么？我们分析一下。

一个写线程调用 update，读线程调用totalDays。单线程中，对于update方法，wa与wb存在happens-before关系，  `wa`在 `wb` 之前执行并对`wb`可见。

多线程中rc与wb存在happens-before关系，`wb`在`rc`之前执行并对`rc`可见。根据 happens-before传递性，`wa`需要在`rc`前先执行并对`rc`可见。

因为`wb`是volatile变量，所以`rc`获取的years，months也是最新值。

![hp](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/hp.png)

我们知道出于性能原因，JVM和CPU会对程序中的指令进行重新排序。如果update方法里面`wa`和`wb`顺序被重排，那它们的happens-before关系将不在成立。

![hp_2](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/hp_2.png)

为了避免这个问题，volatile对重排序做了保证 **对于发生在volatile变量操作前的其他变量的操作不能重新排序**。 

由此我们得到volatile通过**消除缓存**和**防止重排**保证线程的可见性。



## volatile保证线程安全？

讨论线程安全，大家都会提及**原子性**，**顺序性**，**可见性**。volatile侧重于保证可见性，也就是当写的线程更新后，读线程总能获得最新值。在只有一个线程写，多个线程读的场景下，volatile能满足线程安全。可如果多个线程同时写入volatile变量时，则需要引入同步语义才能保证线程安全。

模拟10个线程同时写入volatile变量，一个线程读counter，执行完后正确结果应该是counter=10。

```java
    public static class WriterTask implements Runnable {
        private final ShareObject share;
        private final CountDownLatch countDownLatch;
        public WriterTask(ShareObject share, CountDownLatch countDownLatch) {
            this.share = share;
            this.countDownLatch = countDownLatch;
        }
        @Override
        public void run() {
            countDownLatch.countDown();
            share.increase();
        }
    }
    
    public class ShareObject {
        private volatile int counter;
        public void increase() {
            this.counter++;
        }
    }
```

执行结果出现counter=5或6 错误结果。

![vv_1](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/vv_1.png)

![vv_2](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/vv_2.png)



通过 synchronized，Lock或AtomicInteger 原子变量保证了结果的正确。

![vv_3](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/vv_3.png)



> 完整demo https://gist.github.com/onlythinking/ba7ca7aa5faf00a58f4cedae474fa6f6



## volatile性能

volatile变量带来可见性的保证，访问volatile变量还防止了指令重排序。不过这一切是以牺牲优化（消除缓存，直接操作主存开销增加）为代价，所以不应该滥用volatile，仅在确实需要增强变量可见性的时候使用。



## 总结

本文记录了volatile变量通过消除缓存，防止指令重排序来保证线程可见性，并且在多线程写入的变量的场景下，不保证线程安全。

欢迎大家留言交流，一起学习分享！！！