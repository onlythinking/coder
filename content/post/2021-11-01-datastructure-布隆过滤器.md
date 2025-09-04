---
title: "布隆过滤器详解 - 算法与数据结构核心技术 | 编程码农"
date: "2021-11-01T13:22:56+08:00"
description: "布隆过滤器 布隆过滤器是一种由位数组和多个哈希函数组成概率数据结构，返回两种结果 可能存在 和 一定不存在。 布隆过滤器里的一个元素由多个状态值共同确定。位数组存储状态值，哈希函数计算状态值的位置。 根据它的算法结构，有如下特征： - 使用有限位数组表示大于它长度的元素数量，因为一个位的状态值可以同..."
tags:
  - "Java"
  - "Redis"
  - "数据结构"
  - "缓存"
categories:
  - "算法与数据结构"
keywords:
  - "Java"
  - "Redis"
  - "数据结构"
  - "缓存"
  - "哈希"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

## 布隆过滤器

布隆过滤器是一种由**位数组**和**多个哈希函数**组成概率数据结构，返回两种结果 **可能存在** 和 **一定不存在**。

布隆过滤器里的一个元素由多个**状态值**共同确定。位数组存储**状态值**，哈希函数计算**状态值**的位置。

根据它的算法结构，有如下特征：

- 使用有限位数组表示大于它长度的元素数量，因为一个位的**状态值**可以同时标识多个元素。
- 不能删除元素。因为一个位的**状态值**可能同时标识着多个元素。
- 添加元素永远不会失败。只是随着添加元素增多，误判率会上升。
- 如果判断元素不存在，那么它一定不存在。



比如下面，X,Y,Z 分别由 3个**状态值**共同确定元素是否存在，**状态值**的位置通过3个哈希函数分别计算。

![bloom](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/bloom.png)

## 数学关系

### 误判概率

关于误判概率，因为每个位的**状态值**可能同时标识多个元素，所以它存在一定的误判概率。如果位数组满，当判断元素是否存在时，它会始终返回`true`，对于不存在的元素来说，它的误判率就是100%。

那么，误判概率和哪些因素有关，已添加元素的数量，布隆过滤器长度（位数组大小），哈希函数数量。

根据维基百科推理**误判概率** $P_{fp}$ 有如下关系：

![image-20211102190151378](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211102190151378.png)

- $m$ 是位数组的大小；
- $n$ 是已经添加元素的数量；
- $k$  是哈希函数数量；
- $e$ 数学常数，约等于2.718281828。

由此可以得到，当添加元素数量为0时，误报率为0；当位数组全都为1时，误报率为100%。

不同数量哈希函数下，$ P_{fp}$ 和 $ n$ 的关系如下图：

![Bloom_filter_fp_probability](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/Bloom_filter_fp_probability.png)



根据误判概率公式可以做一些事

- 估算最佳布隆过滤器长度。
- 估算最佳哈希函数数量。



### **最佳布隆过滤器长度**

当 $n$ 添加元素和 $P_{fp}$误报概率确定时，$m$ 等于：

![image-20211102190718863](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211102190718863.png)

### **最佳哈希函数数量**

当 $n$ 和 $P_{fp}$ 确定时，$k$ 等于：

![image-20211102190732623](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211102190732623.png)


当 $n$ 和 $m$ 确定时，$k$ 等于：

![image-20211102190745057](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211102190745057.png)


## 实现布隆过滤器

使用**布隆过滤器**前，我们一般会评估两个因素。

- 预期添加元素的最大数量。
- 业务对错误的容忍程度。比如1000个允许错一个，那么误判概率应该在千分之一内。

很多布隆过滤工具都提供了**预期添加数量**和**误判概率**配置参数，它们会根据配置的参数计算出**最佳的长度**和**哈希函数数量**。

Java中有一些不错的布隆过滤工具包。

-  `Guava` 中 `BloomFilter`。
- `redisson` 中 `RedissonBloomFilter` 可以redis 中使用。

看下 `Guava` 中 `BloomFilter` 的简单实现，创建前先计算出**位数组长度**和**哈希函数数量**。

```java
 static <T> BloomFilter<T> create(
      Funnel<? super T> funnel, long expectedInsertions, double fpp, Strategy strategy) {
    /**
     * expectedInsertions：预期添加数量
     * fpp：误判概率
     */
    long numBits = optimalNumOfBits(expectedInsertions, fpp);
    int numHashFunctions = optimalNumOfHashFunctions(expectedInsertions, numBits);
    try {
      return new BloomFilter<T>(new BitArray(numBits), numHashFunctions, funnel, strategy);
    } catch (IllegalArgumentException e) {
      throw new IllegalArgumentException("Could not create BloomFilter of " + numBits + " bits", e);
    }
  }
```

根据**最佳布隆过滤器长度**公式，计算最佳位数组长度。

```java

static long optimalNumOfBits(long n, double p) {
    if (p == 0) {
      p = Double.MIN_VALUE;
    }
    return (long) (-n * Math.log(p) / (Math.log(2) * Math.log(2)));
  }
```

根据**最佳哈希函数数量**公式，计算最佳哈希函数数量。

```java
static int optimalNumOfHashFunctions(long n, long m) {
    return Math.max(1, (int) Math.round((double) m / n * Math.log(2)));
  }
```

在`redisson` 中 `RedissonBloomFilter` 计算方法也是一致。

```java
    private int optimalNumOfHashFunctions(long n, long m) {
        return Math.max(1, (int) Math.round((double) m / n * Math.log(2)));
      }

    private long optimalNumOfBits(long n, double p) {
        if (p == 0) {
            p = Double.MIN_VALUE;
        }
        return (long) (-n * Math.log(p) / (Math.log(2) * Math.log(2)));
    }
```



## 内存占用

设想一个手机号去重场景，每个手机号占用`22 Byte`，估算逻辑内存如下。

| expected | HashSet  | fpp=0.0001 | fpp=0.0000001 |
| -------- | -------- | ---------- | ------------- |
| 100万    | 18.28MB  | 2.29MB     | 4MB           |
| 1000万   | 182.82MB | 22.85MB    | 40MB          |
| 1亿      | 1.78G    | 228.53MB   | 400MB         |

> 注：实际物理内存占用大于逻辑内存。

**误判概率** $p$ 和**已添加的元素** $n$，**位数组长度**  $m$，**哈希函数数量** $k$ 关系如下：

![image-20211102163237419](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211102163237419.png)





## 应用场景



1.  弱密码检测；
2. 垃圾邮件地址过滤。
3. 浏览器检测钓鱼网站；
4. 缓存穿透。



### 弱密码检测

维护一个哈希过弱密码列表。当用户注册或更新密码时，使用布隆过滤器检查新密码，检测到提示用户。

### 垃圾邮件地址过滤

维护一个哈希过垃圾邮件地址列表。当用户接收邮件，使用布隆过滤器检测，检测到标识为垃圾邮件。

### 浏览器检测钓鱼网站

使用布隆过滤器来查找钓鱼网站数据库中是否存在某个网站的 URL。

### 缓存穿透

缓存穿透是指**查询一个根本不存在的数据**，缓存层和数据库都不会命中。当缓存未命中时，查询数据库

1. 数据库不命中，空结果不会写回缓存并返回空结果。
2. 数据库命中，查询结果写回缓存并返回结果。

一个典型的攻击，模拟大量请求查询不存在的数据，所有请求落到数据库，造成数据库宕机。

其中一种解决方案，将**存在的缓存**放入布隆过滤器，在请求前进行校验过滤。

![cache_req](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/cache_req.png)

## 小结

对于千万亿级别的数据来说，使用布隆过滤器具有一定优势，另外根据业务场景合理评估**预期添加数量**和**误判概率**是关键。



参考

> https://en.wikipedia.org/wiki/Bloom_filter
>
> https://hur.st/bloomfilter
