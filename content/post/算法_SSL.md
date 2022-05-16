---
title: "我们应该使用 TLS1.3 吗"
date: 2022-05-12T18:04:10+08:00
description: "TLS 作用是保证客户端和服务端之间能安全通讯"
tags: ["TLS","SSL","AES-256-GCM"]
categories: ["算法"]
keywords: ["TLS","SSL","AES-256-GCM"]
draft: false
---

# 概述

SSL（Socket Layer Security）和 TLS（Transport Layer Security） 都是属于安全协议，主要作用是保证客户端和服务端之间能安全通讯。SSL是较早的协议，TLS 是 SSL的替代者。

SSL 版本 1.0、2.0 和 3.0，TLS 版本 1.0、1.2 和 1.3。SSL协议和TLS1.0 由于已过时被禁用，目前TLS 1.3 是互联网上部署最多的安全协议，它是TLS最新版本 ，它增强了过时的安全性，并增加了更多的触控性。通过下面几点可以有个简单认识：

- 最新 TLS1.3 的优点
- 什么向前保密
- 为什么选择 GCM 加密

# TLS 1.3

现代浏览器支持 TLS 1.2 和 TLS 1.3 协议，但 1.3 版本要好得多。 TLS 1.3 对早期版本进行了多项改进，最明显的是简化了TLS握手操作，使得握手时间变短、网站性能得以提升、改善了用户体验，另外支持的密码套件更安全和简单。



![img](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202205121822719.png)



**密码套件**

TLS/SSL 使用一种或多种密码套件。 密码套件是身份验证、加密和消息身份验证的算法组合。TLS 1.2 版使用的算法存在一些弱点和安全漏洞。在 TLS 1.3 中删除了这些算法：

- SHA-1
- RC4
- DES
- 3DES
- AES-CBC
- MD5

另外一个很重要的更新是TLS1.3 支持 **perfect-forward-secrecy** （PFS）算法。



# 向前保密

**向前保密**（PFS）是特定密钥协商协议的一项功能，如果一个长周期的会话密钥被泄露，黑客就会截获大量数据，我们可以为每个会话生成唯一的会话密钥，单个会话密钥的泄露不会影响该会话之外的任何数据。

TLS在早期版本的握手期间可以使用两种机制之一交换密钥：静态 RSA密钥和 Diffie-Hellman 密钥。 在 TLS1.3 中，RSA 以及所有静态（非 PFS）密钥交换已被删除，只保留了DHE、ECDHE

- 临时 Diffie-Hellman (DHE)
- 临时椭圆曲线 Diffie-Hellman (ECDHE)

可以查看网站的安全详情来确认它是否使用"ECDHE"或"DHE"。

![image-20220516142354607](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202205161423689.png)



# 为什么选择GCM

**AES** (Advanced Encryption Standard) 对称加密，它是**高级加密**标准。早期的加密标准DES(Data Encryption Standard) 已被弃用。

AES选择合适的**加密模式**很重要，应用比较多的两种模式 CBC 和 GCM。

**CBC 密码分组链接模式**

明文分块，第一个块使用初始化向量，后面的每个明文块在加密前与前一个密文块进行异或运算。

![密码块链接 (CBC) 模式加密](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202205161542689.png)



这种模式存在的问题：

- 如果一个明文块的出现错误将影响后面的所有块。
- 不能并行处理，限制了吞吐量。
- 缺乏内置身份验证，会受到一些攻击，如：选择明文攻击 (CPA)，选择密文攻击 (CCA) 等。



**CTR 计数模式**

明文分块按顺序编号，通过加密"计数器"的连续值来生成下一个密钥流块。CTR 模式非常适合在多核处理器上运行，明文块可以并行加密。

![CTR](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202205161543919.png)



**GCM 伽罗瓦/计数器模式**

GCM = CTR + Authentication。其加密过程，明文块是按顺序编号的，然后这个块号与初始向量 组合并使用块密码E加密，然后将此加密的结果与明文进行异或以生成密文。



![GCM加密操作](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202205161545068.png)

简单来说，GCM 是 CTR 身份验证的组合，它更快、更安全。它将接受流水线和并行化实现，并具有最小的计算延迟，所以它的应用更加广泛。



# Nginx配置

## 支持TLS1.2

客户端最低版本

- Supports Firefox 27+
- Android 4.4.2+
- Chrome 31+
- Edge, IE 11 on Windows 7 or above
- Java 8u31
- OpenSSL 1.0.1
- Opera 20+
- Safari 9+



```nginx
server {
    listen 443 ssl http2;
    server_name www.xxx.com xxx.biz
 
    # Path to certs
    ssl_certificate /etc/nginx/ssl/xxx.com.csr;
    ssl_certificate_key /etc/nginx/ssl/xxx.com.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MySSL:10m;
    ssl_session_tickets off;
    ssl_dhparam /etc/nginx/ssl/xxx.com.dhparam.pem;
 
    ssl_protocols TLSv1.2;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
 
    # 严格传输安全是一种策略机制，保护网站免受协议降级攻击和cookie 劫持等中间人攻击。
    add_header Strict-Transport-Security "max-age=63072000" always;
 
    # 是检查X.509 数字证书吊销状态的标准
    ssl_stapling on;
    ssl_stapling_verify on;
 
    # 使用根 CA 和中间证书验证 OCSP 响应的信任链
    ssl_trusted_certificate /etc/nginx/ssl/fullchain.pem;
 
    # DNS
    resolver 8.8.8.8 valid=10s;;
}
```



## 支持TLS1.3

客户端最低版本

- Firefox 63+
- Android 10.0+
- Chrome 70+
- Edge 75
- Java 11
- OpenSSL1.1.1
- Opera 57
- Safari 12.1

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server www.xxx.com;
 
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SharedNixCraftSSL:10m; 
    ssl_session_tickets off;
 
    # TLS 1.3 only
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;
 
   # 严格传输安全是一种策略机制，保护网站免受协议降级攻击和cookie 劫持等中间人攻击。
    add_header Strict-Transport-Security "max-age=63072000" always;
 
    # 是检查X.509 数字证书吊销状态的标准
    ssl_stapling on;
    ssl_stapling_verify on;
 
    # 使用根 CA 和中间证书验证 OCSP 响应的信任链
    ssl_trusted_certificate /etc/nginx/ssl/fullchain.pem;
 
    # DNS
    resolver 8.8.8.8 valid=10s;;
}
```

一般建议同时兼容1.2和1.3

```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
```



## 测试

测试是否支持 TLS 1.2

```bash
curl -I -v --tlsv1.2 --tls-max 1.2 https://www.xxx.com/
```

测试是否支持 TLS 1.3

```bash
curl -I -v --tlsv1.3 --tls-max 1.3 https://www.xxx.com/
```

