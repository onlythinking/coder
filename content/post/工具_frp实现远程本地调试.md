---
title: "解锁远程办公自由：FRP简易指南快速实现本地服务远程调用"
date: 2024-06-07T08:23:46+08:00
description: "掌握远程办公的秘诀！本指南详细介绍了如何使用FRP（Fast Reverse Proxy）工具快速设置远程访问本地服务。无论你是开发者、设计师还是远程团队的一员，本文将指导你通过简单的步骤实现无缝的远程工作体验。从基础配置到高级技巧，我们为你提供了全面的FRP使用指南，帮助你解锁远程办公的自由，提高工作效率。"
tags: ["frp"]
categories: ["工具"]
keywords: [
  "远程办公",
  "FRP",
  "远程调用",
  "本地服务",
  "内网穿透",
  "快速部署",
  "简易指南",
  "工作自由",
  "远程工作",
  "网络配置",
  "开发者工具",
  "远程协作",
  "访问控制",
  "网络安全",
  "远程访问解决方案",
  "FRP实现远程访问本地开发环境",
  "使用FRP简化远程办公流程",
  "FRP快速配置本地服务远程调用",
  "远程办公自由与FRP技术",
  "快速实现FRP远程访问本地应用",
  "FRP作为远程办公的网络解决方案",
  "远程访问本地服务的最佳实践",
  "FRP工具在远程工作中的应用",
  "远程办公技术：使用FRP实现自由访问",
  "从零开始学习FRP远程服务调用"
]
draft: false
---



# 背景

分享一个开发中很有用的工具frp。我们平时**远程开发协作**和**处理支付回调**时都需要远程调用本地进行来进行代码调试，这时就需要一个内网穿透工具。今天我们使用一个很热门的穿透工具frp，关于frp安装可以查看官方文档。



> 官网：https://gofrp.org/zh-cn
>
> github： https://github.com/fatedier/frp
>
> frp 是一个专注于内网穿透的高性能的反向代理应用，支持 TCP、UDP、HTTP、HTTPS 等多种协议，且支持 P2P 通信。可以将内网服务以安全、便捷的方式通过具有公网 IP 节点的中转暴露到公网。



# 应用架构

简单说下我的应用构成和部署架构。应用包含三个项目：

- 小程序，技术栈：uniapp
- 管理后台，技术栈：vue3 + ant-design-vue
- 后端API，技术栈：springboot + spring data jpa 

生产部署架构如下，比较简单，通过nginx代理管理后台和后端API：

![image-20240607094225264](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406070942227.png)

# 实现自定义域名远程调用本地

实现使用自定义域名远程调用本地，需要先准备一台外网服务器，然后将 `dev.domain.com` 自己的域名 A 记录解析到服务器的 IP 地址 `x.x.x.x`。



根据不同的系统环境下载对应的frp工具，解压后包含两个工具服务端(frps)和客户端(frpc)。我演示的服务器是 linux(centos7)  ，本地（macos）。

![image-20240607102412953](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071024419.png)

配置frp服务端 frps.toml

```toml
bindPort = 7000
auth.token = "666"
vhostHTTPPort = 80

webServer.addr = "0.0.0.0"
webServer.port = 7500
# dashboard 用户名密码，可选，默认为空
webServer.user = "admin"
webServer.password = "admin"
```

启动

```bash
./frps -c frps.toml
```



配置frp客户端 frpc.toml

```toml
# 服务器外网IP
serverAddr = "x.x.x.x"
auth.token = "666"
serverPort = 7000

[[proxies]]
name = "web"
type = "http"
localPort = 3100
customDomains = ["dev.domain.com"]
locations = ["/"]

[[proxies]]
name = "api"
type = "http"
localPort = 8081
customDomains = ["dev.domain.com"]
locations = ["/api"]
```

启动

```bash
./frpc -c frpc.toml
```

下图展示了frp代理本地项目的大体流程

![image-20240607101114422](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071011704.png)



不出意外的话，启动后就可以直接访问 http://dev.domain.com 。

还是出意外了，此时发现系统加载时会一直刷新，vite 一直在 ping。

![image-20240607104224078](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071042526.png)



**分析原因**

因为本地启动项目是开启 Vite  HMR。HMR简单理解就是服务端(dev-server)和客户端(浏览器)会建立一个WebSocket连接，然后服务端就可以向客户端实时推送模块更新信息，这样我们开发过程中，修改完代码不用刷新浏览器就能实时更新看到效果。

这个webScoket 默认地址为 **ws://本地地址或外网地址:本地端口** 或**wss://本地地址或外网地址:本地端口**。

我这里本地启动端口是3100，所以当我们访问 http://localhost:3100 时webscoket连接为 ws://localhost:3100 ，这时没啥问题。而当访问http://dev.domain.com 时webscoket连接为 ws://dev.domain.com:3100 ，但是frp代理端口是80，预期端口不一致导致连接失败，就一直重试刷新页面。

找到原因就有办法解决

1. 将frp 代理端口改为3100和本地端口保持一致，此时访问变为http://dev.domain.com:3100，能顺利连接。

2. 更改vite hmr clientPort ，在vite.config.js或vite.config.ts 添加下面配置

   ```js
       server: {
         hmr: {
           clientPort: 80,
         },
       },
   ```

   > 此功能的requestPull：https://github.com/vitejs/vite/pull/3578
   >
   > 官方配置说明：https://cn.vitejs.dev/config/server-options#server-hmr



# 小程序Https问题

上面配置是通过http协议进行访问，有些情况下我们需要使用https，比如小程序访问就要求https。可以到云商申请免费的SSL，证书签发之后下载到本地。

![image-20240607120547737](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071205566.png)

然后配置frp服务端 frps.toml

```toml
bindPort = 7000
auth.token = "666"
vhostHTTPPort = 80  # http 代理端口
vhostHTTPSPort = 443 # https 代理端口
```



配置frp客户端 frpc_https.toml，使用https2http插件将本地http开启https。

```toml
serverAddr = "x.x.x.x"
serverPort = 7000
auth.token = "666"

[[proxies]]
name = "api"
type = "https"
localPort = 8081
customDomains = ["dev.domain.com"]

[proxies.plugin]
type = "https2http"
localAddr = "127.0.0.1:8081"

crtPath = "./dev.xxxx.com.public.crt"
keyPath = "./dev.xxxx.com.key"
hostHeaderRewrite = "127.0.0.1"
requestHeaders.set.x-from-where = "frp"
```

启动后访问 https://dev.domain.com，浏览器显示连接是安全的，也可以查看证书，说明没问题。

![image-20240607121707178](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071217139.png)



但是在小程序真机上访问报错！但是有点奇怪为什么浏览器都是绿的，小程序却把我红了。

```json
{"errno":600001,"errMsg":"request:fail errcode:-202 cronet_error_code:-202 error_msg:net::ERR_CERT_AUTHORITY_INVALID"}
```

查看小程序对Https的要求，怀疑就是证书信任链条不完整。

![image-20240607122252874](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071222656.png)

> https://developers.weixin.qq.com/miniprogram/dev/framework/ability/network.html#HTTPS-%E8%AF%81%E4%B9%A6



我们用这个网站检测一下 https://myssl.com。实锤了，就是证书链不完整。

![image-20240607122910094](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071229109.png)

可以在这里下载完整的证书链保存，重启frps。

![image-20240607123156161](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406071231443.png)

完善证书链后重新测试，评级达到A了，小程序访问也正常了。

![image-20240607083147597](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/202406070831668.png)

# 总结

- frp工具包含服务端(frps)和客户端(frpc)，它支持TCP、UDP、HTTP、HTTPS 等多种协议。
- frp 代理 vite 时，要么本地端口与代理端口保持一致，要么使用clinetPort参数修改为代理端口，不然页面会一致刷新。
- 小程序对Https的校验较浏览器强，要求证书链条完整。
