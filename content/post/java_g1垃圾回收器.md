---
title: java中的GC收集器
date: 2020-12-08 13:51:51
tags: ["java"]
categories: ["java"]
keywords: ["java GC"]
---

## GC（**Garbage collection** ）

程序内存管理分手动和自动。

手动内存管理，需要我们编程的时候显式分配和释放空间，但如果忘记释放，会造成严重的**内存泄漏**问题。如下：

```c
 		//申请40MB内存
    int* p = malloc(1024 * 1024 * 10 * sizeof(int));
    //释放内存
    free(p);
```

显式分配和释放很容易就造成内存泄漏。因此我们希望有一种能自动回收内存的方法，这样就可以消除人为造成的错误。我们将这种自动化称为垃圾收集（简称GC）

现代高级编程语言基本上都具备GC功能。



## GC算法

GC算法按照下面两方面内容设计

- 标记出所有活动对象（程序正在使用或者叫可达对象）；
- 删除未使用的对象和重新整理空间。

#### 标记活动对象

java gc 通过追踪活动对象进行标记，未被标记的对象为空闲状态。空闲状态对象将会在清理阶段被回收。

GC标记对象是从GcRoots开始，它是一类特殊对象，分以下几种：

- 当前执行方法中的**局部变量和方法参数**。
- **活动Java线程**。
- **静态变量**由其类引用。不过类本身是可以被垃圾收集，回收时将删除所有引用的静态变量。
- **JNI引用**是本机代码作为JNI调用的一部分创建的Java对象。这样创建的对象将被特别对待，因为JVM不知道本机代码是否正在引用它。

标记开始时，GC会遍历内存中的整个对象树，从那些GC Roots开始，然后是从根到其他对象（例如实例字段）的引用。GC访问的每个对象都 **标记** 为活动对象。

标记结束后，如下图所示，蓝色表示为GCroots仍然在引用的对象，灰色表示为空闲对象等待回收。标记阶段需要注意两方面：

- 标记需要暂停应用程序线程，这很好理解如果应用线程一直在运行对象活动状态就会一直变化，GC就无法进行标记。这种情况称为 **安全点，** 导致 **Stop The World暂停**简述为（STW）。
- 暂停的持续时间受**活动对象**的数量影响，不取决于堆的大小和对象总数 **。** 因此，增加堆大小不会直接影响标记阶段的持续时间。



![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/Java-GC-mark-and-sweep.png)



#### 删除空闲对象

GC删除空闲对象的一般分为三类：清除，压缩，复制。

#### 标记清除（Mark-Sweep）

经历标记阶段后，所有空闲对象占用的空间都可以重新分配新对象了。它会维护一个空闲列表，里面记录的空闲区域的位置和大小。这种方式的缺点很明显一是维护空闲列表增加对象开销，二是空闲区域大小不均匀，可能会遇到分配大对象区域不够存储的情况。

![GC-sweep](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/GC-sweep.png)

#### 清除压缩（**Mark-Sweep-Compact**）

清除压多了一步复制动作弥补**标记清除**的缺点。它将所有活动对象移动到内存区域的开头。不过该方式的缺点是增加复制动作，也就增加了GC暂停时间。



![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/GC-mark-sweep-compact.png)

#### **标记和复制** 

**标记复制**这种方式与上面**标记清除压缩**相似，区别在于它是将活动对象复制到另外一块新的区域（幸存对象区域）。它的好处在于复制动作可以与**标记阶段**同时进行，缺点是需要另外一个存储区域，该存储区域应足够大以容纳幸存的对象。

![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/GC-mark-and-copy-in-Java.png)







## JVM GC

在较旧的JVM GC中（串行，并行，CMS）将堆分成三个部分：固定内存大小的年轻代，年老代和永久代。

JVM使用两种GC算法分别对**年轻代**和**年老代**对象进行回收。年轻代的进行**标记复制**操作，年老代回收进行**标记清除压缩**。

![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/HeapStructure.png)

#### JVM GC事件

我们把GC清除堆不同区域的触发事件分为以下几种：

- **Minor GC** 从年轻代空间回收称为**次要GC**。
- **Major GC** 从年老代空间回收**主要GC**。
- **Full GC** 清理整个堆空间，包括年轻代和年老代。



#### Serial GC

串行GC，年轻代进行**标记复制**，年老代进行**标记清除压缩**。两个GC都是单线程操作，并且触发**STW**，停止所有应用线程。多CPU计算机中基本不会使用这个GC收集器。只有在单CPU的服务器上使用才有意义。

```bash
java -XX:+UseSerialGC 
```



#### Parallel GC

并行GC，年轻代进行**标记复制**，年老代进行**标记清除压缩**。不管是年轻代还是年老代GC时都会触发**STW**，停止所有应用线程。与串行GC的区别在于它是使用多个线程运行标记和复制/压缩，多线程可以缩短GC收集时间。

java8默认GC收集器就是 parallel gc。不过因为它在标记清理阶段仍然需要停止应用线程，所以在要求较低延迟的场景下可能变得不那么适用。

可以通过*-XX:ParallelGCThreads = NNN*指定处理的线程数量 。默认值等于计算机中的内核数。

```bash
java -XX:+UseParallelGC #使用并行垃圾收集进行清理
java -XX:+UseParallelOldGC #将并行垃圾回收用于。启用此选项会自动设置-XX:+ UseParallelGC
java -XX:+UseParallelGC -XX:+UseParallelOldGC 
```



#### Concurrent Mark and Sweep

并发标记扫描（**CMS**），年轻代空间执行并行**标记复制**，年老代空间执行并发**标记清除**。年轻代GC时触**STW**，停止所有应用线程，然后多线程并行收集。年老代并发标记清除不需要暂停应用线程。它的意义在于着避免了**Parallel GC**收集器在年老代GC时的长时间停顿。

默认情况下，此GC方式使用的线程数等于计算机物理内核数的1/4。

```bash
java -XX:+UseConcMarkSweepGC
```

我们看下CMS经历的几个阶段

1. **初始标记**。暂停应用线程，标记年老代中的所有对象，这些对象是GC Roots，和年轻代中的某些活动对象引用的。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-06.png)

2. **并发标记**。GC与应用程序线程并行运行，从**初始标记**中的根对象开始，遍历年老代所有活动对象进行标记。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-07.png)

3. **并行预清除**。与应用线程同时运行，如果某些引用发生了变更，JVM会将变化的区域标记为**脏区域**。预清除阶段就是对这些脏区域进行处理，并标记还在存活的对象，然后空闲对象将被清除。预清除可以减少**重标阶段**的工作量。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-08.png)

4. **并发可中止预清除**。该阶段也与应用线程并行，属于优化。增加这个阶段是为了让我们能控制该阶段结束的时间，也是为了减轻**重标阶段**的工作量。

   ```bash
   # 控制参数
   -XX:CMSScheduleRemarkEdenSizeThreshold=2M
   -XX:CMSScheduleRemarkEdenPenetration=50
   -XX:CMSMaxAbortablePrecleanTime=5000（单位为毫秒）
   ```

   比如在**并发预清理**之后，如果年轻代占用高于CMSScheduleRemarkEdenSizeThreshold，则开始**并发可中止的预清除**并继续进行**预清除**，直到年轻代中达到CMSScheduleRemarkEdenPenetration百分比占用率，之后进入**重标阶段**。如果经过CMSMaxAbortablePrecleanTime时间仍然未达到要求，则直接进入**重标阶段**。

5. **重标阶段**。触发**STW**，暂停所用应用线程。从GCroots 开始扫描标记年老代的所有活动对象。CMS会尝试在年轻代尽可能空的时候运行最后的备注阶段。

6. **并行清理**。与应用线程同时执行。该阶段的目的是删除未使用的对象，并回收它们占用的空间以备将来使用。

7. **并行复位**。并发执行阶段，重置CMS算法的内部数据结构，并为下一个周期做好准备。



注：如上CMS垃圾收集器进行大量工作为的是在年老代回收时不需要暂停应用线程，以减少暂停时间。但是，它存在一些缺点，其中最明显的是年老代碎片，并且在某些情况下，尤其是在大堆上，暂停持续时间缺乏可预测性。



#### G1 –垃圾优先

G1是Java9默认GC收集器。它设计的目标是应用在大内存的多处理器计算机，实现高吞吐量。一般应用堆应该在6GB以上且可预测的暂停时间低于0.5秒。G1作为并发标记扫描收集器（CMS）的替代产品。

G1堆内存与旧GC收集器堆内存管理完全不同。它将堆拆分为多个较小的区域（默认根据堆内存拆分为接近2048份）来存对象。

![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/G1-heap.png)

G1收集器的几个阶段：

1. **初始标记**。触发**STW**，标记出从GC Roots直接访问的所有活动对象。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-01.png)

2. **并发标记**。从已标记的对象开始扫描，并从根开始标记所有可访问的对象。这个阶段可以被年轻一代的垃圾收集打断。

![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-02-8026400-8088813.png)

3. **重新标记**。因为并发标记与应用线程并行，所以可能存在遗漏的更新对象。此阶段触发**STW**，应用线程暂停，完成活动对象最后的标记。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-03.png)

4. **复制/清理阶段**。

   G1选择“活度”最低的区域，这些区域可以被最快地收集。并发标记完成后将进行[GC pause (mixed)]混合GC，年轻代和年老代同时收集。

   

   

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-04.png)

   下图深绿色和深蓝色为清除压缩之后的区域。

   ![](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/g1-05.png)

   G1中几个重要的参数：

   ```bash
   # G1区域的大小。该值为2的幂，范围为1MB至32MB。目标是根据最小Java堆大小具有大约2048个区域。
   -XX:G1HeapRegionSize=n
   
   # 所需的最大暂停时间设置目标值。默认值为200毫秒。
   -XX:MaxGCPauseMillis=200
   
   # 设置要用作年轻代大小的最小值的堆百分比。默认值为Java堆的5％
   -XX:G1NewSizePercent=5
   
   # 设置堆大小的百分比，以用作年轻代大小的最大值。默认值为Java堆的60％。
   -XX:G1MaxNewSizePercent=60
   
   # 设置STW工作线程的值。将n的值设置为逻辑处理器的数量。的值与n逻辑处理器的数量相同，最多为8
   # 如果逻辑处理器多于八个，则将的值设置为逻辑处理器的n大约5/8。在大多数情况下，这n是可行的，但大型SPARC系统的值可能约为逻辑处理器的5/16。
   -XX:ParallelGCThreads=n
   
   # 设置平行标记线的数量。设置n为并行垃圾回收线程数（ParallelGCThreads）的大约1/4 。
   -XX:ConcGCThreads=n
   
   # 设置触发标记周期的Java堆占用阈值。默认占用率为整个Java堆的45％。
   -XX:InitiatingHeapOccupancyPercent=45
   
   # 设置要包含在混合垃圾收集周期中的旧区域的占用阈值。默认占用率为65％。
   -XX:G1MixedGCLiveThresholdPercent=65
   
   # 当可回收百分比小于堆垃圾百分比时，Java HotSpot VM不会启动混合垃圾回收周期。默认值为10％。
   -XX:G1HeapWastePercent=10
   
   # 设置标记周期后混合垃圾回收的目标数量，以收集最多包含G1MixedGCLIveThresholdPercent实时数据的旧区域。默认值为8个混合垃圾回收。混合馆藏的目标是在此目标数量之内。
   -XX:G1MixedGCCountTarget=8
   
   # 设置在混合垃圾收集周期中要收集的旧区域数的上限。缺省值为Java堆的10％。
   -XX:G1OldCSetRegionThresholdPercent=10
   
   # 设置保留内存的百分比以使其保持空闲状态，以减少空间溢出的风险。默认值为10％。当增加或减少百分比时，请确保将总Java堆调整相同的数量。
   -XX:G1ReservePercent=10
   ```

   

## 小结

本文记录GC算法基础和Java中的几种GC收集器。

欢迎大家留言交流，一起学习分享！！！