---
title: "简版在线聊天Websocket | 编程码农"
date: "2020-05-19T21:29:28+08:00"
description: "序言 - What is Webscoket ? - websocket 应用场景 - 简版群聊实现 - 代码例子 - 小结    Webscoket Websokcet 是一种单个TCP连接上进行全双工通信的协议，通过HTTP/1.1 协议的101状态码进行握手。 > http://websock..."
tags:
  - "JavaScript"
  - "Java"
  - "异步编程"
  - "并发编程"
  - "Promise"
categories:
  - "项目实战"
keywords:
  - "JavaScript"
  - "Java"
  - "项目实战"
  - "TCP"
  - "SSL"
  - "并发"
  - "异步编程"
  - "Promise"
author: "编程码农"
draft: false
---

## 序言

- What is Webscoket ?

- websocket 应用场景

- 简版群聊实现

- 代码例子

- 小结

  

## Webscoket

**Websokcet** 是一种单个[TCP](https://baike.baidu.com/item/TCP)连接上进行[全双工](https://baike.baidu.com/item/全双工)通信的协议，通过[HTTP](https://baike.baidu.com/item/HTTP)/1.1 协议的101状态码进行握手。

> http://websocket.org



## Websocket 应用场景

Websocket 和 http 协议都是web通讯协议，两者有何区别？先说Http，它是一种请求响应协议，这种模型决定了，只能客户端请求，服务端被动回答。如果我们有服务端主动推送给客户端的需求怎么办？比如一个股票网站，我们会选择主动轮询，也就是”拉模式“。

大家可以思考下主动轮询带来的问题是什么？

主动轮询其实会产生大量无效请求，增加了服务器压力。

由此，websocket 协议的补充，为我们带来了新的解决思路。



## 简版群聊实现

利用Websocket 实现一个简陋群聊功能，加深一下Websocket 理解。

1. 假设李雷和韩梅梅都登录在线；
2. 李雷通过浏览器发送消息转nginx 代理到Ws服务器；
3. Ws服务器加载所有在线会话广播消息；
4. 韩梅梅接受到消息。

![0_ws](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/0_ws.png)



## 代码例子

**后端（shop-server）**

引入pom.xml 依赖

```
  <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-websocket</artifactId>
  </dependency>
```



配置类

```java
package com.onlythinking.shop.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.server.standard.ServerEndpointExporter;

/**
 * <p> The describe </p>
 *
 * @author Li Xingping
 */
@Slf4j
@Configuration
public class WebSocketConfiguration {

    @Bean
    public ServerEndpointExporter endpointExporter() {
        return new ServerEndpointExporter();
    }

}
```



接受请求端点

```java
package com.onlythinking.shop.websocket;

import com.alibaba.fastjson.JSON;
import com.google.common.collect.Maps;
import com.onlythinking.shop.websocket.handler.ChatWsHandler;
import com.onlythinking.shop.websocket.handler.KfWsHandler;
import com.onlythinking.shop.websocket.handler.WsHandler;
import com.onlythinking.shop.websocket.store.WsReqPayLoad;
import com.onlythinking.shop.websocket.store.WsRespPayLoad;
import com.onlythinking.shop.websocket.store.WsStore;
import com.onlythinking.shop.websocket.store.WsUser;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Component;

import javax.websocket.*;
import javax.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.Map;

/**
 * <p> The describe </p>
 *
 * @author Li Xingping
 */
@Slf4j
@Component
@ServerEndpoint("/ws")
public class WebsocketServerEndpoint {

    private static Map<String, WsHandler> wsHandler = Maps.newConcurrentMap();

    static {
        wsHandler.put("robot", new KfWsHandler());
        wsHandler.put("chat", new ChatWsHandler());
    }

    @OnOpen
    public void onOpen(Session session) {
        log.info("New ws connection {} ", session.getId());
        WsStore.put(session.getId(), WsUser.builder().id(session.getId()).session(session).build());
        respMsg(session, WsRespPayLoad.ok().toJson());
    }

    @OnClose
    public void onClose(Session session, CloseReason closeReason) {
        WsStore.remove(session.getId());
        log.warn("ws closed，reason:{}", closeReason);
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        log.info("accept client messages: {}" + message);
        WsReqPayLoad payLoad = JSON.parseObject(message, WsReqPayLoad.class);
        if (StringUtils.isBlank(payLoad.getType())) {
            respMsg(session, WsRespPayLoad.ofError("Type is null.").toJson());
            return;
        }
        WsUser wsUser = WsStore.get(session.getId());
        if (null == wsUser || StringUtils.isBlank(wsUser.getUsername())) {
            WsStore.put(session.getId(), WsUser.builder()
              .id(session.getId())
              .username(payLoad.getUsername())
              .avatar(payLoad.getAvatar())
              .session(session)
              .build()
            );
        }
        WsHandler handler = wsHandler.get(payLoad.getType());
        if (null != handler) {
            WsRespPayLoad resp = handler.onMessage(session, payLoad);
            if (null != resp) {
                respMsg(session, resp.toJson());
            }
        } else {
            respMsg(session, WsRespPayLoad.ok().toJson());
        }
    }

    @OnError
    public void onError(Session session, Throwable e) {
        WsStore.remove(session.getId());
        log.error("WS Error: ", e);
    }

    private void respMsg(Session session, String content) {
        try {
            session.getBasicRemote().sendText(content);
        } catch (IOException e) {
            log.error("Ws resp msg error {} {}", content, e);
        }
    }
}

```



聊天业务处理器

```java
package com.onlythinking.shop.websocket.handler;

import com.onlythinking.shop.websocket.store.*;
import lombok.extern.slf4j.Slf4j;

import javax.websocket.Session;
import java.util.Date;
import java.util.List;

/**
 * <p> The describe </p>
 *
 * @author Li Xingping
 */
@Slf4j
public class ChatWsHandler implements WsHandler {

    @Override
    public WsRespPayLoad onMessage(Session session, WsReqPayLoad payLoad) {
        // 广播消息
        List<WsUser> allSessions = WsStore.getAll();
        for (WsUser s : allSessions) {
            WsRespPayLoad resp = WsRespPayLoad.builder()
              .data(
                WsChatResp.builder()
                  .username(payLoad.getUsername())
                  .avatar(payLoad.getAvatar())
                  .msg(payLoad.getData())
                  .createdTime(new Date())
                  .self(s.getId().equals(session.getId()))
                  .build()
              )
              .build();
            log.info("Broadcast message {} {} ", s.getId(), s.getUsername());
            s.getSession().getAsyncRemote().sendText(resp.toJson());
        }
        return null;
    }
}

```

**前端（shop-web-mgt）**

引入依赖

```bash
npm install vue-native-websocket --save
```



添加Store

```javascript
import Vue from 'vue'

const ws = {
  state: {
    wsData: {
      hasNewMsg: false,
    },
    socket: {
      isConnected: false,
      message: '',
      reconnectError: false,
    }
  },
  mutations: {
    SET_WSDATA(state, data) {
      state.wsData.hasNewMsg = data.hasNewMsg
    },
    RESET_WSDATA(state, data) {
      state.wsData.hasNewMsg = false
    },
    SOCKET_ONOPEN(state, event) {
      Vue.prototype.$socket = event.currentTarget;
      state.socket.isConnected = true
    },
    SOCKET_ONCLOSE(state, event) {
      state.socket.isConnected = false
    },
    SOCKET_ONERROR(state, event) {
      console.error(state, event)
    },
    // default handler called for all methods
    SOCKET_ONMESSAGE(state, message) {
      state.socket.message = message
    },
    // mutations for reconnect methods
    SOCKET_RECONNECT(state, count) {
      console.info(state, count)
    },
    SOCKET_RECONNECT_ERROR(state) {
      state.socket.reconnectError = true;
    },
  },
  actions: {
    AskRobot({rootGetters}, data) {
      return new Promise((resolve, reject) => {
        console.log('Ask robot msg', data);
        const payLoad = {
          type: 'robot',
          username: rootGetters.loginName,
          data: data
        };
        Vue.prototype.$socket.sendObj(payLoad)
        resolve(1)
      })
    },
    SendChatMsg({rootGetters}, data) {
      return new Promise((resolve, reject) => {
        console.log('Send chat msg', data);
        const payLoad = {
          type: 'chat',
          username: rootGetters.loginName,
          data: data
        };
        Vue.prototype.$socket.sendObj(payLoad)
        resolve(1)
      })
    },
    MessageRead({commit, state}, data) {
      commit('RESET_WSDATA', {})
    },
  }
};

export default ws

```



编写组件

```javascript
<template>
  <div>
    <ot-drawer
      title="聊天"
      :visible.sync="chatVisible"
      direction="rtl"
      :before-close="handleClose">
      <div class="chat-body">
        <div id="msgList" style="margin-bottom: 200px" class="chat-msg">
          <div class="chat-msg-item" v-for="item in msgList">
            <div v-if="!item.self">
              <div class="msg-header">
                <img
                  :src="baseUrl+'/api/insecure/avatar?code='+item.avatar+'&size=64'"
                  class="user-avatar"
                >
                <span class="avatar-name">{{item.username}}</span>&nbsp;&nbsp;
                <div style="display: inline-block; float: right">
                  {{item.createdTime | parseTime('{h}:{i}')}}
                </div>
              </div>
              <div class="msg-body" style="float: left;">
                {{item.msg}}
              </div>
            </div>
            <div v-else>
              <div class="msg-header clearfix">
                <img
                  :src="baseUrl+'/api/insecure/avatar?code='+item.avatar+'&size=64'"
                  class="user-avatar"
                  style="float: right"
                >
              </div>
              <div class="msg-body" style="float: right;background-color: #67C23A">
                {{item.msg}}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="chat-send">
        <el-input
          v-model="text"
          autocomplete="off"
          placeholder="请输入你想说的内容..."
          @keyup.enter.native="handleSendMsg"
        ></el-input>
        <div class="chat-btns">

          <el-button
            class="action-item"
            @click="handleClearMsg"
          >清空
          </el-button>
          <el-button
            type="success"
            class="action-item"
            @click="handleSendMsg"
            v-scroll-to="{ el: '#msgList', offset: 140 }"
          >发送
          </el-button>
        </div>
      </div>
    </ot-drawer>
  </div>
</template>

<script>

  import {mapGetters} from 'vuex'
  import store from '@/store'
  import {config} from '@/utils/config'
  import OtDrawer from '@/components/OtDrawer'
  import Cookies from 'js-cookie'

  export default {
    name: 'UserChat',
    components: {OtDrawer},
    props: {
      visible: {
        type: Boolean,
        default: false
      }
    },
    data() {
      return {
        baseUrl: config.baseUrl,
        text: '',
        msgList: [],
      }
    },
    computed: {
      ...mapGetters([
        'roles', 'isConnected', 'message', 'reconnectError'
      ]),
      chatVisible: {
        get() {
          return this.visible
        },
        set(val) {
          this.$emit('update:visible', val)
        }
      }
    },
    beforeDestroy() {
      if (this.isConnected) {
        this.$disconnect()
      }
    },
    mounted() {
      console.log('Chat mounted.')
      if (!this.isConnected) {
        this.$connect(config.wsUrl, {
          format: 'json',
          store: store
        })
      }
      // 监听消息接收
      this.$options.sockets.onmessage = (res) => {
        const data = JSON.parse(res.data);
        console.log('收到消息', data);
        if (data.code === 0) {
          // 连接建立成功
          if (!data.data.msg) {
            return;
          }
          this.msgList.push(data.data)
        } else if (data.code === 400) {
          this.$message({
            type: 'warning',
            message: data.data
          })
        }
      };
    },
    methods: {
      handleSendMsg() {
        if (!this.text) {
          this.$message({
            type: 'warning',
            message: '请输入内容'
          });
          return;
        }
        this.$store.dispatch('SendChatMsg', this.text).then(data => {
          this.text = ''
        })
      },
      handleClearMsg() {
        this.msgList = [];
        Cookies.remove('chatMsg');
        // 删除
      },
      // 聊天关闭前
      handleClose() {
        // 缓存消息到本地
        Cookies.set('chatMsg', JSON.stringify(this.msgList));
        this.$emit('update:visible', false)
      }
    },
    created() {
      // 加载缓存数据
      const chatMsg = Cookies.get('chatMsg');
      if (chatMsg) {
        this.msgList = JSON.parse(chatMsg);
      }
    }
  }
</script>

<style>
  .el-drawer__body {
    height: 100%;
    box-sizing: border-box;
    overflow-y: auto;
    background-color: rgba(244, 244, 244, 1);
    scroll-snap-type: y proximity;
  }
</style>

<style rel="stylesheet/scss" lang="scss" scoped>

  .user-avatar {
    width: 20px;
    height: 20px;
    border-radius: 4px;
    vertical-align: middle;
  }

  .msg-header {
    font-size: 12px;
    color: rgba(109, 114, 120, 1);
  }

  .avatar-name {
    vertical-align: middle;
  }

  .msg-body {
    text-align: center;
    max-width: 300px;
    min-width: 100px;
    word-wrap: break-word;

    margin: 4px 0;
    padding: 4px;
    line-height: 24px;
    border-radius: 4px;
    background-color: rgba(255, 255, 255, 1);
  }

  .chat-body {
    height: 100%;
    position: relative;
  }

  .chat-msg {
    padding: 10px;

    .chat-msg-item {
      margin-top: 10px;
      height: 65px;
    }
  }

  .chat-send {
    padding: 20px;
    background-color: rgba(255, 255, 255, 1);
    position: absolute;
    left: 50%;
    width: 100%;
    transform: translateX(-50%);
    bottom: 0px;
  }

  .chat-btns {
    text-align: center;
  }

  .action-item {
    margin-top: 10px;
  }
</style>

```



Nginx 代理配置 nginx.conf (如有需要可添加)

```bash
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream websocket {
    server 127.0.0.1:8300;
}

server {
     server_name shop-web-mgt.onlythinking.com;
     listen 443 ssl;
     location / {
         proxy_pass http://websocket;
         proxy_read_timeout 300s;
         proxy_send_timeout 300s;
         
         proxy_set_header Host $host;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
         
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection $connection_upgrade;
     }
    ssl_certificate /etc/data/shop-web-mgt.onlythinking.com/full.pem;
    ssl_certificate_key /etc/data/shop-web-mgt.onlythinking.com/privkey.pem;
}
```



**实现效果图**

界面比较丑，因为不太擅长，请大家别见笑！！

![1_ws](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/1_ws.png)



![2_ws](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/2_ws.png)



![3_ws](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/3_ws.png)



项目地址

> https://github.com/cuteJ/shop-server  (后端)
>
> https://github.com/cuteJ/shop-web-mgt （前端）



项目演示地址

> http://shop-web-mgt.onlythinking.com



## 小结

该篇学习Websocket，以此简单Demo加深印象！