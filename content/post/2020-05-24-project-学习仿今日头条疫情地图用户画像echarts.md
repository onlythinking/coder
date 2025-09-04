---
title: "Echarts实现中国疫情地图和今日头条用户画像 | 编程码农"
date: "2020-05-24 16:42:13"
description: "新型冠状病毒肺炎疫情目前最新情况，12月16日0—24时，31个省（自治区、直辖市）和新疆生产建设兵团报告新增确诊病例7例，均为境外输入病例（上海6例，广东1例）；无新增死亡病例；新增疑似病例1例，为本土病例（在黑龙江）。 Echarts Chartjs 前端图表框架也比较多，这里介绍两款。 - A..."
tags:
  - "JavaScript"
  - "Java"
  - "HTML"
  - "Git"
categories:
  - "项目实战"
keywords:
  - "JavaScript"
  - "Java"
  - "开发工具"
  - "项目实战"
  - "Git"
  - "树"
  - "技术博客"
  - "编程码农"
author: "编程码农"
draft: false
---

新型冠状病毒肺炎疫情目前最新情况，12月16日0—24时，31个省（自治区、直辖市）和新疆生产建设兵团报告新增确诊病例7例，均为境外输入病例（上海6例，广东1例）；无新增死亡病例；新增疑似病例1例，为本土病例（在黑龙江）。

## Echarts Chartjs

前端图表框架也比较多，这里介绍两款。

- Apache Echarts
- Chartjs

Apache Echarts 涵盖各行业图表，满足各种需求，功能相当丰富。而后起之秀chartjs以其简单灵活特性，也深得开发设计人员喜爱。

>  https://echarts.apache.org （Echarts）
>
> https://www.chartjs.org (Charts)



两者都是开源项目，托管在Github

> https://github.com/apache/incubator-echarts
>
> https://github.com/chartjs/Chart.js

两者社区活跃简单对比

![Apache Echarts](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/0_eh.png)



![Chartjs](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/1_eh.png)



看上去Chartjs似乎更活跃。



## 疫情地图

使用echarts map 来实现。

```bash
npm install echarts --save
```

导入地图数据

ECharts 中提供了Javascript和Json两种格式的地图数据

> 从Github项目文件下载 https://github.com/apache/incubator-echarts/tree/master/map
>
> 从阿里提供地址下载  http://datav.aliyun.com/tools/atlas/#
>
> 百度网盘 链接: https://pan.baidu.com/s/1fHfW-qft_M58o2eQglwelw 提取码: 6fu5



项目代码片段

```javascript
echarts.registerMap("china", chinaMap);

series: [
            {
              name: '确诊数',
              type: 'map',
              mapType: 'china',
              roam: false,
              label: {
                show: true,
                color: 'rgb(63, 63, 63)'
              },
              data: actualData
            }
          ]
```

配置 visualMap

对照配置文档调整相应的参数即可，也很简单。

> https://echarts.apache.org/zh/option.html#series-map

疫情数据来源 《腾讯新闻》

![2_eh](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/2_eh.png)



## 用户画像

仿照今日头条简版粉丝画像图。

![3_eh](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/3_eh.png)



## IP来源查询

![4_eh](https://blogs-on.oss-cn-beijing.aliyuncs.com/imgs/4_eh.png)



## 小结

该篇主要是对Echarts map 整理。欢迎分享学习交流。

项目地址

> https://github.com/cuteJ/shop-server  (后端)
>
> https://github.com/cuteJ/shop-web-mgt （前端）



项目演示地址

> http://shop-web-mgt.onlythinking.com