---
title: "Qwen 排第二"
date: 2026-08-07
description: "差 0.77 分第二,输出价 1/4,任务成本近半。"
tags: ["Qwen", "Agentic Index", "AI 评测", "LLM"]
categories: ["AI"]
draft: false
toc: false
cover: /images/covers/2026-08-07-AI-qwen3-8-max-agentic-index-second-half-price.png
---

## 昨晚 HN 421 分的帖，标题党差点带偏

昨晚 Hacker News 顶上一条 421 分的帖子，标题是「Qwen3.8 Max now ranked as the best overall model by agentic index」。点进去评论区一片「中国模型登顶了」的欢呼——但自带传播力这件事本身就需要打个问号。

反差在于：标题说「best overall」，Artificial Analysis 实时榜单上 Qwen3.8 Max 实际排在第二，落后 Claude Opus 5 (Max Effort) 约 0.77 分（1.3%）。**不是登顶，但比登顶更值得讨论**——同样的 Agent 综合分，Qwen 拿 1/4 的输出价就能跑出来。

## 实时榜单：Agentic Index 前 5

Artificial Analysis 的 Agentic Index v1.0.1（2026-08-06 更新）：

- 第 1：Claude Opus 5 (Max Effort)，59.17，发布 2026-07-24，定价 $5 / $25，单任务成本 $2.34
- 第 2：Qwen3.8 Max，58.40，发布 2026-08-03，定价 $2 / $6，单任务成本 $1.13
- 第 3：GPT-5.6 Sol (max)，57.78，发布 2026-07-09，定价 $5 / $30
- 第 4：Claude Fable 5，56.59，发布 2026-06-09，定价 $10 / $50
- 第 5：Kimi K3 (max)，54.26，发布 2026-07-16，定价 $3 / $15

> 价格数字会随云厂商调价变化，实际下单以官方定价页为准。

## 1.3% 的差额，以及它真正赢的一项

先算账：

- Agentic Index 差距：(59.17 − 58.40) / 59.17 = **1.3%**
- 输出价：Qwen $6 vs Opus $25，**Opus 贵 4.17 倍**
- 单任务成本：Qwen $1.13 vs Opus $2.34，**Opus 贵 2.07 倍**

但在 Qwen3.8 Max 模型页上，它在 τ³-Banking（智能体业务操作）子 benchmark 上拿到 **0.5134 全榜第一**，比 Opus 5 的 0.4206 高出 22%。这是真正考验 Agent / 工具调用 / 长流程任务能不能稳定完成的指标，不是闲聊意义上的 Agent。

反过来，Opus 5 在 Terminal-Bench v2.1（0.8914 vs Qwen 0.8127）和 HLE（0.5487 vs 0.4305）上明显领先。代码任务与高难度推理 Opus 还是更强。

一个合理的心智模型：跑长流程业务流跑 Qwen，跑 Terminal / 高难度单题跑 Opus。

## 榜单在刷新前后，名次翻转了

这是 HN 帖最有抓点的部分。评论里 d2p（5 回复）原话：

> "I clicked through and it showed Qwen at the top at 55.4 compared to 55.3 for Opus Max. I have a screenshot. Then I clicked away and back, and now it goes Qwen second, with 58.4, to Opus Max at top with 59.2."

不仅名次翻，分数也从 55.4 变成 58.4。quirino（1 回复）补刀：

> "A couple days ago they had published an overall score of 53 for this model, but that was removed and today it returned with a score of 56."

**同一个月里同一模型的分数被悄悄改过两次、刷新前后名次翻转**——这并不是一个稳定的可证事实，更像是 AA 在更新数据时的中间态。把这件事单独拎出来，是因为中文媒体引用 AA 排名时经常不写「截至 X 月 X 日」。读者看到的「第一 / 第二」，很可能是某个刷新瞬间的结果，而不是稳定值。如果你打算把这个数字写进产品宣传、PPT 或者融资材料，建议自己也截一张图存档——榜单不会替你负责。

## 为什么不同榜单名次不同

AA 自己就有两个榜单。HN 帖指向的是 Agentic Index，权重偏向 Agent / 工具调用 / 长流程任务；而 Intelligence Index v4.1.1 更偏知识 / 推理。一个衡量的是「能不能干活」，一个衡量的是「知识有多深」，两者完全可以给出截然不同的排名。

seizethecheese 在 HN 评论里直接点出：在 Intelligence Index 上 Opus 仍是第一，Fable、GPT 5.6、Kimi、Qwen 排后面。所以「Qwen 排第几」这个问题，离开具体榜单没有标准答案。

另一个有意思的声音是 bonoboTP 的：

> "I distrust any benchmark where Opus 5 beats Fable 5."

怀疑论也合理——任何 LLM benchmark 都有自己的取样偏好，单榜排名只是参考。

## 为什么会差 4 倍价

把价格差当结论讲不充分，简单补一个机制背景：Qwen3.8 Max 的输出价能压到 Opus 5 的 24%，不是「Qwen 让利」，而是两家厂商面对的边际成本结构不一样。Opus 5 走的是 Anthropic 的高单价、低毛利、订阅绑定路线，背后是合规、安全、长 prompt 优化这些隐性成本；Qwen 这条线是云厂商规模摊薄 + 开放生态走量，单 token 的推理摊销低。

反映在 Agentic Index 实时榜单上：Top 5 里 Opus 5 / Fable 5 / GPT-5.6 Sol 都是美国闭源高单价，Qwen / Kimi 都是中国云厂商体系下的低单价模型。**这条价差不是营销动作，是结构差**。这也是为什么同一时间点 Cloudflare 发 OS 平台押 Agent 跑量，中国这边押 Agent 单价——两侧做的是同一件事的不同切片。

## 开发者侧该怎么选

三个分支：

**1. 跑 Agent / 工具调用 / 业务流程编排**：Qwen3.8 Max 是性价比首选。τ³-Banking 第一、单任务成本接近一半、响应更快。如果你在做长流程自动化、客服、操作型 agent，Qwen 是合理选择。

**2. 跑 Coding / Terminal / 单题高难度推理**：Opus 5 还是更稳。Terminal-Bench 是它的主场。给单文件 refactor、出 hard 级别算法题、单步 debug 这种「一次答好」的任务，Opus 更值得。

**3. 跑 MoE / 量化 / 长上下文密集任务**：Kimi K3 那条线还是更划算。百万级上下文、长文档分析这种场景，Kimi 是更对口的选择。

**一个建议**：不要按榜单排名选模型，按「任务类型 × 子 benchmark × 价格」三栏交叉选。同样的总分离 1.3% 并不关键，但 τ³-Banking 差 22% 是真的会让跑批数据不同的。如果你的 agent 任务占大头，Qwen 这一档已经值得接进生产了。

**两个提醒**：一是榜单还会继续刷新，今天的排名不要写进长期文档；二是同样的子 benchmark 在不同 prompt template 下会跑出不同结果，**自己在自己的数据上跑一次再决定**，比读 HN 帖更可靠。

## 结语

排名第二、价格四分之一、在真正考验 Agent 的子榜上拿第一——Qwen3.8 Max 这一周的故事不是「登顶」，是「**在 Agent 这一项上，中国大模型把单价砍到了西方玩家不在意的那条线以下**」。这条线一旦被跌破，西方的成本结构就回不去了，因为边际成本不是靠功能补得回来的。

榜单会刷新、分数会改、媒体标题会继续制造 1.3% 的胜利或失败。但开发者打开 terminal 算的那笔账，比榜单诚实。

---

—— 编程码农 @ onlythinking.com

评论区聊聊你正在用的模型组合，看看是不是同一个逻辑。