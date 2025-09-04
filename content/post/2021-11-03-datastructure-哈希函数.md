---
title: "哈希函数详解 - 算法与数据结构核心技术 | 编程码农"
date: "2021-11-03T17:49:39+08:00"
description: "哈希函数 在计算机中，函数是一个有输入输出的黑匣子，而哈希函数是其中一类函数。我们通常会接触两类哈希函数。 - 用于哈希表的哈希函数。比如布隆过滤里的哈希函数，HashMap 的哈希函数。 - 用于加密和签名的哈希函数。比如，MD5，SHA-256。 !Function_m 哈希函数通常具有以下特征..."
tags:
  - "Java"
  - "算法"
  - "数据结构"
categories:
  - "算法与数据结构"
keywords:
  - "Java"
  - "算法"
  - "数据结构"
  - "哈希"
  - "树"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

## 哈希函数

在计算机中，**函数**是一个有输入输出的黑匣子，而**哈希函数**是其中一类函数。我们通常会接触两类哈希函数。

- 用于**哈希表**的哈希函数。比如布隆过滤里的哈希函数，`HashMap `的哈希函数。
- 用于加密和签名的哈希函数。比如，MD5，SHA-256。



![Function_m](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/Function_m.png)

哈希函数通常具有以下特征。

- 长度固定。任意的输入一定得到相同的输出长度。
- 确定性。相同的输入一定得到相同的输出。
- 单向性。通过输入得到输出，但是不能通过输出反推输入。



## 哈希函数质量

哈希函数作用是将**一堆数据信息映射到一个简短数据，这个简短数据代表了整个数据信息**。比如身份证号。

如何衡量一个哈希函数质量，主要从考量以下方面

- 哈希值是否分布均匀，呈现出随机性，有利于哈希表空间利用率提升，增加哈希的破解难度；
- 哈希碰撞的概率很低，碰撞概率应该控制在一定范围；
- 是否计算得更快，一个哈希函数计算时间越短效率越高。



## 碰撞概率

什么是碰撞？

当同一个哈希值映射了不同数据时，即产生了碰撞。

碰撞不可避免，只能尽可能减小碰撞概率，而碰撞概率由**哈希长度**和**算法**决定。

碰撞概率如何评估。概率学中有个经典问题**生日问题**，数学规律揭示，23人中存在两人生日相同的概率会大于50%，100人中存在两人生日相同的概率超过99%。这违反直觉经验，所以也叫生日悖论。

![Birthday_Paradox](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/Birthday_Paradox.png)

**生日问题**是碰撞概率的理论指导。密码学中，攻击者根据此理论只需要 2^n/2 次就能找哈希函数碰撞。

下面是不同位哈希的碰撞参考表：

![image-20211108185241796](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211108185241796.png)

另外根据维基上的推导，我们还可以得到以下公式。

指定已有哈希值数量 $n$，估算碰撞概率 $p (n)$

![image-20211108205609361](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211108205609361.png)



指定碰撞概率 $p$ 和哈希范围最大值 $d$，估算达到碰撞概率时需要的哈希数量 $n$

![image-20211108205627456](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211108205627456.png)

指定碰撞概率 $p$ 和哈希范围最大值 $d$，估算碰撞数量 $rn$

![image-20211108205642179](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/image-20211108205642179.png)



```java
// 估算理论碰撞概率
public static double collisionProb(double n, double d) {
	return 1 - Math.exp(-0.5 * (n * (n - 1)) / d);
}
```



```java
//  估算达到碰撞概率时需要的哈希数量
public static long collisionN(double p, double d) {
	return Math.round(Math.sqrt(2 * d * Math.log(1 / (1 - p))) + 0.5);
}
```



```java
// 估算碰撞哈希数量
public static double collisionRN(double n, double d) {
 	return n - d + d * Math.pow((d - 1) / d, n);
}
```



根据上面公式，我们评估一下`String.hashCode()` ，Java里面 `hashCode`() 返回 `int`，所以哈希范围是 $2^{32}$。看下 `String.hashCode()` 在1000万UUID下的表现。

1000万UUID，理论上的碰撞数量为11632.50

```java
collisionRN(10000000, Math.pow(2, 32)) // 11632.50
```



使用下面代码进行测试

```java
private static Map<Integer, Set<String>> collisions(Set<String> values) {
	Map<Integer, Set<String>> result = new HashMap<>();
	for (String value : values) {
		Integer hashCode = value.hashCode();
		Set<String> bucket = result.computeIfAbsent(hashCode, k -> new TreeSet<>());
		bucket.add(value);
	}
	return result;
}

public static void main(String[] args) throws IOException {
        Set<String> uuids = new HashSet<>();
        for (int i = 0; i< 10000000; i++){
            uuids.add(UUID.randomUUID().toString());
        }
        Map<Integer, Set<String>> values = collisions(uuids);

        int maxhc = 0, maxsize = 0;
        for (Map.Entry<Integer, Set<String>> e : values.entrySet()) {
            Integer hashCode = e.getKey();
            Set<String> bucket = e.getValue();
            if (bucket.size() > maxsize) {
                maxhc = hashCode;
                maxsize = bucket.size();
            }
        }

        System.out.println("UUID总数: " + uuids.size());
        System.out.println("哈希值总数: " + values.size());
        System.out.println("碰撞总数: " + (uuids.size() - values.size()));
        System.out.println("碰撞概率: " + String.format("%.8f", 1.0 * (uuids.size() - values.size()) / uuids.size()));
        if (maxsize != 0) {
            System.out.println("最大的碰撞的字符串: " + maxsize + " " + values.get(maxhc));
        }
    }
```

碰撞总数11713非常接近理论值。

```java
UUID总数: 10000000
哈希值总数: 9988287
碰撞总数: 11713
碰撞概率: 0.00117130
```

> 注意，上面测试不足以得出string.hashCode()性能结论，字符串情况很多，无法逐一覆盖。

对于JDK中的`hashCode` 算法的优劣决定了它在哈希表的分布，我们可以通过估算理论值和实测值来不断优化算法。

对于一些有名的哈希算法，比如**FNV-1**，**Murmur2** 网上有个帖子专门对比了它们的碰撞概率，分布情况。

> https://softwareengineering.stackexchange.com/questions/49550/which-hashing-algorithm-is-best-for-uniqueness-and-speed

## 小结

哈希函数是将长信息映射为长度固定的短数据，判断一个哈希函数的好坏考量它的**碰撞概率**和**哈希值的分布情况**。



> https://en.wikipedia.org/wiki/Birthday_problem

