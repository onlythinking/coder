---
title: "3.5 万亿 IPO 压顶美股：流动性大考"
date: 2026-06-08
description: "SpaceX、OpenAI、Anthropic 同年 IPO 合计市值 3.5 万亿，单季融资需求吃不下。"
tags: ["SpaceX", "OpenAI", "Anthropic", "IPO", "AI泡沫"]
categories: ["AI"]
keywords: ["SpaceX IPO", "OpenAI IPO 2026", "Anthropic IPO", "AI估值泡沫", "Michael Burry", "Tom Tunguz"]
draft: false
toc: true
cover: /images/covers/2026-06-08-AI-spacex-openai-anthropic-3t-ipo-liquidity-stress-test.png
---

> 知乎一个不到三天就登顶热榜的问题：「SpaceX、OpenAI、Anthropic 扎堆天价 IPO，水分有多大？」 评论区清一色在比 2000 年互联网泡沫，但翻完一手资料后我得出一个不同结论：**这不是估值问题，是流动性问题**。

## 先把事实摆清楚

很多人把这事当成"传闻"在聊，但实际上一手文件已经全部公开：

**SpaceX**（2026 年 5 月 20 日向 SEC 提交 S-1）：
- 2025 年营收 $18.7B，净亏损 $4.9B
- 目标估值 $1.5T-$2T（TechCrunch 报道 $1.5T 目标，市场后续传言提升至 $2T）
- Musk 与内部人保留投票控制权（2026 年 4 月 21 日 Reuters 披露）

**OpenAI**（2025 年 10 月完成 for-profit 重组）：
- 目标 2026 Q4 IPO，估值锚定 $1T（Bloomberg 2025-10 报道）
- Fidji Simo（CEO of Applications）在 2026 年 3 月全员会上公开表态「ChatGPT 必须成为生产力工具」（CNBC 2026-03-17 报道）

**Anthropic**（2026 年 6 月 1 日 confidentially file IPO）：
- 上一轮融资定价 $965B
- 公开上市估值预期更高（Reuters / Business Insider）

也就是说，「扎堆 IPO」不是讨论，是日程表。

三家加起来——按当前估值锚——**合计约 $3.5T**（SpaceX $1.5T + OpenAI $1T + Anthropic $965B）。这个数字本身没有冲击力，毕竟苹果一家就 $3.4 万亿。真正的问题在下面这张表。

## Float 数学：$520B-$693B 从哪里来？

红杉投资人 Tom Tunguz 在他的博客里做了一个简单到刺眼的测算（[原文链接](https://tomtunguz.com/spacex-openai-anthropic-ipo-2026/)）。本文按当前估值（Anthropic 已从 $380B 升级到 $965B）重新算一遍：

| 公司 | 目标市值 | 15% Float | 20% Float |
|------|---------|-----------|-----------|
| SpaceX | $1.5T | $225B | $300B |
| OpenAI | $1.0T | $150B | $200B |
| Anthropic | $965B | $145B | $193B |
| **合计** | **$3.47T** | **$520B** | **$693B** |

历史上 IPO 典型流通比例是 15-25%：

- Facebook 上市流通 15%
- Google 上市流通 19%
- 阿里巴巴上市流通 15%

按这个比例，**这三家要在大致同一个季度从二级市场抽走 $520B-$693B 现金**。

作为对照：**2016 到 2025 整整十年，美国 IPO 市场累计融资 $469B。**

也就是说，**一个季度的资金需求，超过过去十年的总和**。市场吃不下。

## 妥协路径：Tiny Float → 强制再平衡

吃不下就只能压缩流通比例。预期路径是：三家都按 3-8% 的小流通量上市。

这看起来解决了短期吸纳问题，但立刻引出第二个问题——**指数纳入门槛**。

S&P 500 纳入要求公司公开流通量至少 **50%**。按 3-8% 上市，三家**短期都进不了** S&P 500。但这只是延后引爆，不是拆雷。

假设半年到一年内任何一家把流通比例提到 50% 以上（多次增发、内部人解锁减持），符合 S&P 500 纳入条件，连锁反应就开始：

```text
进入 S&P 500 触发条件
    ↓
管理 $20T 的被动指数基金被强制按权重买入新股
    ↓
指数基金不能凭空印钱，必须先卖掉现有持仓
    ↓
卖压传导到 Apple / Microsoft / NVIDIA / Alphabet / Meta
    ↓
现有大盘股跌 → 动量策略加仓做空
    ↓
更多卖压 → 进一步打压指数本身
    ↓
反身性循环（reflexivity loop）启动
```

简单说：**$20T 的被动资金必须给新人腾位置，唯一办法是卖现在的"七姐妹"**。不是预测，是机械。被动指数基金按规则操作，不按观点操作。

SpaceX 如果上市后稳在 $1.5-2T 区间，将与 Meta 争 S&P 500 第 6 位，可能直接挤到 Amazon 后面。这意味着：当它"够格"那天，整个 S&P 500 前 10 的权重都要重新计算，相应地，整个被动资金体系都要重新洗牌。

## Burry 的看空视角：贵不贵，长期值不值

「大空头」Michael Burry 6 月初在 Substack 订阅者讨论里集中开炮（[Business Insider 报道](https://www.businessinsider.com/big-short-michael-burry-spacex-anthropic-ipo-ai-bubble-claude-2026-6)），核心观点翻译整理（综合 BI 报道）：

- **关于 SpaceX**：S-1 里的财务数据与 $1.5-2T 估值没有可对应的支撑逻辑。
- **关于 Anthropic**：开发前沿 AI 模型这门生意"太贵、太依赖蛮力、计算力长期会像互联网一样商品化"——这是 BI 报道里 Burry 引用最直接的一段。
- **关于当前 AI 算力需求**：Burry 认为是"虚假的需求信号"，产能扩张会远超实际需要。

Burry 的逻辑分两层：
1. **短期估值与 S-1 数据严重背离**——SpaceX 营收 $18.7B、净亏损 $4.9B，对应 $1.5-2T 市值，意味着 P/S 倍数 **80-107x**，P/E 短期算不出来。
2. **长期商业模式靠"算力暴政"——一旦算力商品化（像云、像带宽一样），前沿模型公司的溢价就被抽干。**

这套逻辑跟 Tunguz 的流动性视角是互补的：**Tunguz 说"市场吞不下"，Burry 说"就算吞下也消化不良"。**

## 跟 2000 互联网泡沫对照，有用但要小心

知乎评论区主要的类比是 dot-com 泡沫。两者确有相似点：
- 一二级估值倒挂（很多 dot-com 在 IPO 当天就低于上一轮 VC 估值，这次部分公司可能复现）
- 集中行业叙事（互联网 vs AI）
- 普通投资人 FOMO 入场

但**这次有三个根本不同**：

| 维度 | 2000 dot-com | 2026 AI IPO |
|------|--------------|-------------|
| 上市公司财务 | 大量无收入或微收入 | 三家都有显著收入（SpaceX $18.7B，Anthropic / OpenAI ARR 数十亿量级） |
| 市场结构 | 主动管理为主 | 被动指数 + ETF 主导，$20T 体量 |
| 监管视角 | 宽松 | SEC 经历过 2020-2022 SPAC / Crypto，会更严 |

更接近真实风险的类比，不是 dot-com 整体崩盘，而是 **2020 年 Snowflake / DoorDash / Airbnb 集中 IPO 的迷你版**——估值站不站得住另说，但市场短期消化是一定要痛的。区别在于这次的"迷你"放大了 100 倍。

## 怎么看 OpenAI / Anthropic / SpaceX 的估值锚

如果你想自己判断估值合不合理，比起照搬 2000，更值得用三组锚来横向对比：

**1. P/S 与 ARR 倍数**

- 当前 SaaS 龙头（如 Snowflake、Datadog）P/S 大约 12-18x
- Anthropic 按 $965B / 估算 ARR $8-10B ≈ **96-120x P/S**
- OpenAI 按 $1T / 估算 ARR $15-20B ≈ **50-67x P/S**

哪怕给 AI 一个 5x 的"前沿溢价"，按 SaaS 龙头的 3-4 倍上限算，Anthropic 当前估值至少要被打 3-5 折才"传统意义合理"。

**2. 算力成本曲线**

DeepSeek V3 之后，前沿模型训练成本已经被拉低一个数量级（从 $100M+ 量级到 $5-10M 可以做到接近 SOTA）。Burry 说的"算力商品化"在事实层面已经在发生。

**3. 客户集中度**

OpenAI 大客户高度集中（Microsoft、苹果生态、企业 API 头部），Anthropic 大客户在 Amazon、企业开发者。客户集中度高就意味着定价权可能不在自己手里——这是估值打折的硬理由。

## 跟博客已有内容的关联

我之前写过 [SpaceX 收购 Cursor 600B 估值](/post/2026-04-22-ai-spacex-acquires-cursor-600b-valuation/) 的传闻分析，那一篇关注的是「一级市场估值传染」。

今天这篇关注的是「估值到二级市场的传导失灵」。把两件事放一起看：**SpaceX 一边在一级市场用估值收购 AI 公司放大叙事，一边把 $1.5-2T 估值带到 IPO 让二级市场买单**。

一级把估值做高，二级承接的资金池又远远小于一级。如果你是基金经理，这是双重套利窗口；如果你是普通投资人，需要想清楚自己在哪一端接力。

## 结论：把"水分"两个字换成两个具体问题

回到知乎那个原问题——「水分有多大」。这个问法没有可操作性。换成下面两个，反而清晰：

1. **短期（IPO 后 6 个月内）：被动资金能不能把这 $520B-$693B 吃下？** 大概率不能按 15% float，会强行妥协到 5-8% 小流通 → 短期估值会被 hype 撑住，但市场深度极差，少量减持就会暴跌。
2. **长期（IPO 后 2-3 年内）：算力商品化的速度有多快？** 这是 Burry 看空的核心。如果开源模型 + 国产芯片把推理成本再压一个数量级，前沿模型公司的定价权就崩了，估值跟随。

至于"是不是牛市临近尾声"——市场层面的判断超出了我能给的范围。但**从机械学的角度，被动指数体系即将经历一次史无前例的强制再平衡**，这一点是确定的。

> 一个有依据的预判：这三家会按计划上市，估值会按预期"撑住"，但 S&P 500 纳入那一天，是市场真正测压的开始。不是因为它们贵，是因为太大、太集中、太被动。

## 扩展阅读

- [SpaceX 收购 Cursor 600B 估值传闻分析](/post/2026-04-22-ai-spacex-acquires-cursor-600b-valuation/)
- Tom Tunguz: [SpaceX, OpenAI & Anthropic IPOs: A $3 Trillion Stress Test](https://tomtunguz.com/spacex-openai-anthropic-ipo-2026/)
- Business Insider: [Michael Burry says neither SpaceX nor Anthropic is worth $1 trillion](https://www.businessinsider.com/big-short-michael-burry-spacex-anthropic-ipo-ai-bubble-claude-2026-6)
- CNBC: [OpenAI preps for IPO in 2026, says ChatGPT must be productivity tool](https://www.cnbc.com/2026/03/17/openai-preps-for-ipo-in-2026-says-chatgpt-must-be-productivity-tool.html)
- Semafor: [OpenAI completes restructure as for-profit company](https://www.semafor.com/article/10/28/2025/openai-completes-restructure-as-for-profit-company)
- TechCrunch: [SpaceX planning 2026 IPO with $1.5T valuation target](https://techcrunch.com/2025/12/09/spacex-reportedly-planning-2026-ipo-with-1-5t-valuation-target/)
- The Atlantic: [Elon Musk Is Dropping a Boulder in a Kiddie Pool](https://www.theatlantic.com/technology/2026/06/spacex-ipo-anthropic-openai/687443/)

---

*本文不构成任何投资建议。所有估值、营收数据均来自公开报道，最终请以各公司招股书 / 官方披露为准。*
