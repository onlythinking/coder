---
title: "Agentic Index 第二名 Qwen3.8 Max：拿 1/4 价格打到了 99% 的分数"
date: 2026-08-07
description: "Qwen3.8 Max 差 0.77 分排 Agentic Index 第二,输出价是 Opus 5 24%,τ³-Banking 第一,任务成本近半。"
tags: ["Qwen", "Agentic Index", "Artificial Analysis", "Claude Opus 5", "AI 评测", "LLM"]
categories: ["AI"]
keywords: ["Qwen3.8 Max", "Agentic Index", "Artificial Analysis", "Claude Opus 5", "AI 性价比"]
draft: false
toc: true
cover: /images/covers/2026-08-07-AI-qwen3-8-max-agentic-index-second-half-price.png
---

## 一个 421 分的 HN 帖，标题党差点把我们带偏

昨晚 Hacker News 顶上一条 421 分的帖子，标题是「Qwen3.8 Max now ranked as the best overall model by agentic index」。点进去评论区一片「中国模型登顶了」的欢呼，HN 标题自带传播力，但自带传播力这件事本身就需要打个问号。

但这里有个反差：标题说「best overall」，AA 实时榜单上 Qwen3.8 Max 实际排在**第二**，落后 Claude Opus 5 (Max Effort) 约 0.77 分（1.3%）。

不是登顶，但比登顶更值得讨论。因为价格差得有点离谱——同样的 Agent 综合分，Qwen 拿 1/4 的输出价就能跑出来。这件事一旦被「第一」的标题盖过去，反而没人看。这是这周中文 AI 圈最值得拆的一件事。

## 实时榜单：Agentic Index 前 5

Artificial Analysis 的 [Agentic Index v1.0.1](https://artificialanalysis.ai/?intelligence=agentic-index)（2026-08-06 更新）：

| 排名 | 模型 | Agentic Index | 发布日期 | 定价（in/out, /M tok）| 单任务成本 |
|---|---|---|---|---|---|
| 1 | Claude Opus 5 (Max Effort) | 59.17 | 2026-07-24 | $5 / $25 | $2.34 |
| 2 | Qwen3.8 Max | 58.40 | 2026-08-03 | $2 / $6 | **$1.13** |
| 3 | GPT-5.6 Sol (max) | 57.78 | 2026-07-09 | $5 / $30 | — |
| 4 | Claude Fable 5 | 56.59 | 2026-06-09 | $10 / $50 | — |
| 5 | Kimi K3 (max) | 54.26 | 2026-07-16 | $3 / $15 | — |

前 5 里有 4 个非美国模型。如果把视野拉到 Top 10，会看到越来越多中国玩家挤进第一梯队。

## 1.3% 的差额，以及它真正赢的一项

先算账：

- Agentic Index 差距：（59.17 − 58.40）/ 59.17 = **1.3%**
- 输出价：Qwen $6 vs Opus $25，**Opus 贵 4.17 倍**
- 单任务成本：Qwen $1.13 vs Opus $2.34，**Opus 贵 2.07 倍**
- 端到端响应：Qwen 39.6s vs Opus 65.9s

但 Agentic Index 是一个综合分，不能只看总分。在 [Qwen3.8 Max 模型页](https://artificialanalysis.ai/models/qwen3-8-max)上，它在 **τ³-Banking（智能体业务操作）** 子 benchmark 上拿到 **0.5134 全榜第一**，比 Opus 5 的 0.4206 高出 22%。这是一个真正在 Agent / 工具调用 / 长流程任务上能用的指标——τ³-Banking 测的就是模型能不能稳定完成多步业务操作，不是闲聊意义上的 Agent。

反过来，Opus 5 在 Terminal-Bench v2.1（0.8914 vs Qwen 0.8127）和 HLE（0.5487 vs 0.4305）上明显领先。**代码任务与高难度推理 Opus 还是更强**，这是 Qwen 在写产品时绕不开的事实。

一个合理的开发者心智模型是：跑长流程业务流跑 Qwen，跑 Terminal / 高难度单题跑 Opus。综合分差 1.3% 不重要，但子榜差 20%+ 是另一回事。

> 价格数字会随云厂商调价变化，**实际下单以官方定价页为准**。

## 榜单在刷新前后，名次翻转了

这是 HN 帖最有抓点的部分。评论里 [d2p（5 回复）](https://news.ycombinator.com/item?id=49200652) 原话：

> "I clicked through and it showed Qwen at the top at 55.4 compared to 55.3 for Opus Max. I have a screenshot. Then I clicked away and back, and now it goes Qwen second, with 58.4, to Opus Max at top with 59.2."

不仅名次翻，分数也从 55.4 变成 58.4。**[quirino（1 回复）](https://news.ycombinator.com/item?id=49200652) 补刀**：

> "A couple days ago they had published an overall score of 53 for this model, but that was removed and today it returned with a score of 56."

**同一个月里同一模型的分数被悄悄改过两次、刷新前后名次翻转**——这并不是一个稳定的可证事实，更像是 AA 在更新数据时的中间态。AA 官方没说原因，但效果是：截屏为证、和现在看到的结论不一致。

把这件事单独拎出来，是因为中文媒体引用 AA 排名时经常不写「截至 X 月 X 日」。读者看到的「第一 / 第二」，很可能是某个刷新瞬间的结果，而不是稳定值。如果你打算把这个数字写进产品宣传、PPT 或者融资材料，建议自己也截一张图存档——榜单不会替你负责。

## 为什么不同榜单名次不同

**AA 自己就有两个榜单**。HN 帖指向的是 Agentic Index，权重偏向 Agent / 工具调用 / 长流程任务；而另一个更广为人知的 [Intelligence Index v4.1.1](https://artificialanalysis.ai/?intelligence=agentic-index) 更偏知识 / 推理。一个衡量的是「能不能干活」，一个衡量的是「知识有多深」，两者完全可以给出截然不同的排名。

**[seizethecheese 在 HN 评论](https://news.ycombinator.com/item?id=49200652) 里直接点出**：

> 在 Intelligence Index 上 Opus 仍是第一，Fable、GPT 5.6、Kimi、Qwen 排后面。

所以「Qwen 排第几」这个问题，离开具体榜单没有标准答案。HN 帖标题只引用 Agentic Index 是不够的——如果换成 Intelligence Index 的口径，Qwen 还要往后数。

另一个有意思的声音是 [bonoboTP](https://news.ycombinator.com/item?id=49200652) 的：

> "I distrust any benchmark where Opus 5 beats Fable 5."

怀疑论也合理——任何 LLM benchmark 都有自己的取样偏好，单榜排名只是参考。这恰好印证了上面那条「换榜单名次会变」的观察。

## 为什么会差 4 倍价

把价格差当结论讲不充分，简单补一个机制背景：Qwen3.8 Max 的输出价能压到 Opus 5 的 24%，不是「Qwen 让利」，而是**两家厂商面对的边际成本结构不一样**。Opus 5 走的是 Anthropic 的高单价、低毛利、订阅绑定路线，背后是合规、安全、长 prompt 优化这些隐性成本；Qwen 这条线是云厂商规模摊薄 + 开放生态走量，单 token 的推理摊销低。

反映在 [Agentic Index 实时榜单](https://artificialanalysis.ai/?intelligence=agentic-index) 上：Top 5 里 Opus 5 / Fable 5 / GPT-5.6 Sol 都是美国闭源高单价，Qwen / Kimi 都是中国云厂商体系下的低单价模型。**这条价差不是营销动作，是结构差**。

这也是为什么看 [Cloudflare 那一周发 OS 平台](https://www.onlythinking.com/post/2026-08-06-AI-cloudflare-os-agent-platform/) 的稿子时几乎同一时间点——海外在押 Agent 跑量，中国在押 Agent 单价。两侧做的是同一件事的不同切片。

另一个佐证是 [Kimi K3 那条线的 3T 量化策略](https://www.onlythinking.com/post/2026-08-05-AI-kimi-k3-open-3t-moe-quantization/)：把 MoE 模型通过激进量化降到消费级显存可跑，进一步把成本往下打。这跟 Qwen 这次榜单上的价格位置是同一条线的延伸——单价的边际还在往下走。

## 开发者侧该怎么选

回到工程视角，三个分支：

**1. 跑 Agent / 工具调用 / 业务流程编排**：Qwen3.8 Max 是性价比首选。τ³-Banking 第一、单任务成本接近一半、响应更快，[Cloudflare 那边的 Agent 平台](https://www.onlythinking.com/post/2026-08-06-AI-cloudflare-os-agent-platform/) 也是同一逻辑：基础设施便宜、模型便宜，Agent 才有跑得动的边际。如果你在做长流程自动化、客服、操作型 agent，Qwen 是合理选择。

**2. 跑 Coding / Terminal / 单题高难度推理**：Opus 5 还是更稳。这点 [Opus 5 发布那周的稿子](https://www.onlythinking.com/post/2026-07-27-AI-claude-opus-5-launch-cheaper-than-fable/) 里也说过，Terminal-Bench 是它的主场。给单文件 refactor、出 hard 级别算法题、单步 debug 这种「一次答好」的任务，Opus 还是更值得。

**3. 跑 MoE / 量化 / 长上下文密集任务**：[Kimi K3 Open 3T](https://www.onlythinking.com/post/2026-08-05-AI-kimi-k3-open-3t-moe-quantization/) 那条线还是更划算，而且 Top 5 里 Kimi 是另一个 1/4 价格段的选项。百万级上下文、长文档分析这种场景，Kimi 是更对口的选择。

**一个建议**：不要按榜单排名选模型，按「任务类型 × 子 benchmark × 价格」三栏交叉选。同样的总分离 1.3% 并不关键，但 τ³-Banking 差 22% 是真的会让跑批数据不同的。如果你的 agent 任务占大头，Qwen 这一档已经值得接进生产了。

**两个提醒**：一是榜单还会继续刷新，今天的排名不要写进长期文档；二是同样的子 benchmark 在不同 prompt template 下会跑出不同结果，**自己在自己的数据上跑一次再决定**，比读 HN 帖更可靠。

## 结语

排名第二、价格四分之一、在真正考验 Agent 的子榜上拿第一——Qwen3.8 Max 这一周的故事不是「登顶」，是「**在 Agent 这一项上，中国大模型把单价砍到了西方玩家不在意的那条线以下**」。这条线一旦被跌破，西方的成本结构就回不去了，因为边际成本不是靠功能补得回来的。

榜单会刷新、分数会改、媒体标题会继续制造 1.3% 的胜利或失败。但开发者打开 terminal 算的那笔账，比榜单诚实。

—— 编程码农 @ onlythinking.com
