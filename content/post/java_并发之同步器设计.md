---
title: Java并发之同步器设计
date: 2020-06-09 18:40:49
tags: ["java并发"]
categories: ["java"]
keywords: ["java并发"]
---



在 [Java并发之内存模型](https://www.onlythinking.com/2020/06/08/java%E5%B9%B6%E5%8F%91%E4%B9%8B%E5%86%85%E5%AD%98%E6%A8%A1%E5%9E%8B/)了解到多进程（线程）读取共享资源的时候存在**竞争条件**。

![0_](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/0_.png)

计算机中通过设计**同步器**来协调进程(线程)之间执行顺序。**同步器**作用就像登机安检人员一样可以协调旅客按顺序通过。

在Java中，**同步器**可以理解为一个对象，它根据自身状态协调线程的执行顺序。比如锁（Lock），信号量（Semaphore），屏障（CyclicBarrier），阻塞队列（Blocking Queue）。

这些同步器在功能设计上有所不同，但是内部实现上有共通的地方。



## 同步器

同步器的设计一般包含几个方面：**状态变量设计（同步器内部状态）**，**访问条件设定**，**状态更新**，**等待方式**，**通知策略**。



![1_](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/1_-1857046.png)





**访问条件**是控制线程是否能执行（访问共享对象）的条件，它往往与状态变量紧密相关。而**通知策略**是**线程释放锁定状态**后通知其它**等待线程**的方式，一般有以下几种情况

1. 通知所有等待的线程。
2. 通知1个随机的N个等待线程。
3. 通知1个特定的N个等待线程

看下面例子，通过**锁**方式的同步器

```java
public class Lock{
  // 状态变量 isLocked
  private boolean isLocked = false; 
  public synchronized void lock() throws InterruptedException{
    // 访问条件 当isLocked=false 时获得访问权限否则等待
    while(isLocked){
      // 阻塞等待
      wait();
    }
    //状态更新 线程获得访问权限
    isLocked = true;
  }
  
  public synchronized void unlock(){
    //状态更新 线程释放访问权限
    isLocked = false;
    // 通知策略 object.notify | object.notifyAll
    notify(); 
  }
}
```

我们用计数**信号量**控制同时执行操作活动数。这里模拟一个连接池。

```java
public class PoolSemaphore {
  	// 状态变量 actives 计数器
    private int actives = 0;
    private int max;
    public PoolSemaphore(int max) {
        this.max = max;
    }
    public synchronized void acquire() throws InterruptedException {
        //访问条件 激活数小于最大限制时，获得访问权限否则等待
        while (this.actives == max) wait();
        //状态更新 线程获得访问权限
        this.actives++;
        // 通知策略 object.notify | object.notifyAll
        this.notify();
    }
    public synchronized void release() throws InterruptedException {
        //访问条件 激活数不为0时，获得访问权限否则等待
        while (this.actives == 0) wait();
         //状态更新 线程获得访问权限
        this.actives--;
        // 通知策略 object.notify | object.notifyAll
        this.notify();
    }
}
```



#### 原子指令

同步器设计里面，最重要的操作逻辑是“如果满足条件，以更新**状态变量**来标志线程**获得**或**释放**访问权限”，该操作应具备**原子性**。

比如**test-and-set** 计算机原子指令，意思是**进行条件判断满足则设置新值**。

```c
function Lock(boolean *lock) { 
    while (test_and_set(lock) == 1); 
}
```

另外还有很多原子指令 **fetch-and-add**  **compare-and-swap**，注意这些指令需硬件支持才有效。

同步操作中，利用计算机原子指令，可以避开锁，提升效率。java中没有 **test-and-set** 的支持，不过 java.util.concurrent.atomic 给我们提供了很多原子类API，里面支持了 **getAndSet** 和**compareAndSet** 操作。

看下面例子，主要在区别是**等待方式**不一样，上面是通过**wait()阻塞等待**，下面是**无阻塞循环**。

```java

public class Lock{
  // 状态变量 isLocked
  private AtomicBoolean isLocked = new AtomicBoolean(false);
  public void lock() throws InterruptedException{
    // 等待方式 变为自旋等待
    while(!isLocked.compareAndSet(false, true));
    //状态更新 线程获得访问权限
    isLocked.set(true);
  }
  
  public synchronized void unlock(){
    //状态更新 线程释放访问权限
    isLocked.set(false);
  }
}
```



#### 关于阻塞扩展说明

阻塞意味着需要将**进程**或**线程**状态进行转存，以便还原后恢复执行。这种操作是昂贵繁重，而线程基于进程之上相对比较轻量。线程的阻塞在不同编程平台实现方式也有所不同，像Java是基于JVM运行，所以它由JVM完成实现。

在《Java Concurrency in Practice》中，作者提到

> 竞争性同步可能需要OS活动，这增加了成本。当争用锁时，未获取锁的线程必须阻塞。 JVM可以通过**旋转等待**（反复尝试获取锁直到成功）来实现阻塞，也可以通过操作**系统挂起阻塞**的线程来实现阻塞。哪种效率更高取决于上下文切换开销与锁定可用之前的时间之间的关系。对于短暂的等待，最好使用自旋等待；对于长时间的等待，最好使用暂停。一些JVM基于对过去等待时间的分析数据来自适应地在这两者之间进行选择，但是大多数JVM只是挂起线程等待锁定。

从上面可以看出JVM实现阻塞两种方式

- 旋转等待（spin-waiting），简单理解是**不暂停执行，以循环的方式等待**，适合短时间场景。
- 通过操作系统挂起线程。

JVM中通过 **-XX: +UseSpinning** 开启旋转等待， **-XX: PreBlockSpi =10**指定最大旋转次数。

![useSpinning](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/useSpinning.png)



## AQS

AQS是AbstractQueuedSynchronizer简称。本节对**AQS**只做简单阐述，并不全面。

java.util.concurrent包中的 ReentrantLock，CountDownLatch，Semaphore，CyclicBarrier等都是基于是AQS同步器实现。

**状态变量** 是用 int state 来表示，状态的获取与更新通过以下API操作。

```java
 	int getState()
	void setState(int newState)
	boolean compareAndSetState(int expect, int update)
```

该状态值在不同API中有不同表示意义。比如*ReentrantLock*中表示*持有锁的线程获取锁的次数*，*Semaphore*表示剩余许可数。

关于**等待方式**和**通知策略**的设计

AQS通过维护一个FIFO同步队列（Sync queue）来进行同步管理。当多线程争用共享资源时被阻塞入队。而线程阻塞与唤醒是通过 **LockSupport.park/unpark** API实现。

它定义了两种资源共享方式。

- Exclusive（独占，只有一个线程能执行，如ReentrantLock）
- Share（共享，多个线程可同时执行，如Semaphore/CountDownLatch）



每个节点包含waitStatus（节点状态），prev（前继），next（后继），thread（入队时线程），nextWaiter（condition队列的后继节点）



![3_](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/3_.png)



**waitStatus** 有以下取值。

- CANCELLED(1) 表示线程已取消。当发生超时或中断，节点状态变为取消，之后状态不再改变。
- SIGNAL(-1) 表示后继节点等待前继的唤醒。后继节点入队时，会将前继状态更新为SIGNAL。  
- CONDITION(-2) 表示线程在Condition queue 里面等待。当其他线程调用了Condition.signal()方法后，CONDITION状态的节点将**从 Condition queue 转移到 Sync queue**，等待获取锁。
- PROPAGATE(-3)  在共享模式下，当前节点释放后，确保有效通知后继节点。
- (0) 节点加入队列时的默认状态。



AQS 几个关键 API 

- tryAcquire(int)  独占方式下，尝试去获取资源。成功返回true，否则false。
- tryRelease(int) 独占方式下，尝试释放资源，成功返回true，否则false。
- tryAcquireShared(int)    共享方式下，尝试获取资源。返回负数为失败，零和正数为成功并表示剩余资源。
- tryReleaseShared(int) 共享方式下，尝试释放资源，如果释放后允许唤醒后续等待节点返回true，否则false。
- isHeldExclusively()  判断线程是否正在独占资源。



**acquire(int arg)**

```java
    public final void acquire(int arg) {
        if (
          // 尝试直接去获取资源，如果成功则直接返回
          !tryAcquire(arg)
            &&
            //线程阻塞在同步队列等待获取资源。等待过程中被中断，则返回true，否则false
            acquireQueued(
              // 标记该线程为独占方式，并加入同步队列尾部。
              addWaiter(Node.EXCLUSIVE), arg) 
           )
            selfInterrupt();
    }
```



**release(int arg)**

```java
    public final boolean release(int arg) {
      	// 尝试释放资源
        if (tryRelease(arg)) {
            Node h = head;
            if (h != null && h.waitStatus != 0)
              // 唤醒下一个线程（后继节点）
              unparkSuccessor(h);
            return true;
        }
        return false;
    }
```



```java
private void unparkSuccessor(Node node) {
		....
  			Node s = node.next; // 找到后继节点
        if (s == null || s.waitStatus > 0) {//无后继或节点已取消
            s = null;
           // 找到有效的等待节点 
            for (Node t = tail; t != null && t != node; t = t.prev)
                if (t.waitStatus <= 0)
                    s = t;
        }
        if (s != null)
            LockSupport.unpark(s.thread); // 唤醒线程
    }
```





## 总结

本文记录并发编程中**同步器**设计的一些共性特征。并简单介绍了Java中的AQS。

欢迎大家留言交流，一起学习分享！！！