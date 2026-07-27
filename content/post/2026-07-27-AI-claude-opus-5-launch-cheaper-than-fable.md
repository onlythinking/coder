---
title: "Claude Opus 5 凌晨上线：同价 Opus 4.8、半价 Fable 5，但提示词要重新写"
date: "2026-07-27"
description: "Opus 5同价$5/$25,半价Fable 5。CursorBench近Fable峰值,Frontier-Bench翻倍。提示词指南建议删verify。"
tags: ["AI", "LLM", "Anthropic", "Claude", "Opus5", "大模型", "提示词"]
categories: ["AI"]
keywords: ["Claude Opus 5", "Anthropic", "Opus 4.8", "Fable 5", "AI编程", "提示词工程", "Artificial Analysis"]
draft: false
readingTime: 约10分钟
toc: true
cover: /images/covers/2026-07-27-AI-claude-opus-5-launch-cheaper-than-fable.svg
---

Anthropic 在 7 月 24 日凌晨上线了 Claude Opus 5，HN 当日冲到 1764 分、登顶当日热榜第一。这条消息在中文圈被简化为「Opus 5 比 Opus 4 还便宜」——**这句话是错的**。

正确的版本是：Opus 5 与 Opus 4.8 同价（$5/$25 每百万 token），但比旗舰 Fable 5（$10/$50）便宜一半。**它的真正卖点不是更便宜，而是用一半的钱拿到接近 Fable 5 的能力**。

本文基于 Anthropic 官方公告、System Card、提示词指南、Artificial Analysis 第三方测评，以及 HN 主流评论，扒一扒这次发布到底意味着什么、哪些提示词写法现在该改。

---

## 1. 定价事实：先纠正一下被传歪的说法

cron 当日简报里说「价格比 Opus 4 还便宜」，看官方公告原话：

> "priced at $5 per million input tokens and $25 per million output tokens (**the same as Opus 4.8**)."

也就是说 Opus 5 的 API 定价与上一代 Opus 4.8 完全相同。把它放到 Anthropic 当前的产品矩阵里看更清楚：

| 模型 | 输入/输出（每百万 token） | 相对 Opus 5 |
|---|---|---|
| Claude Sonnet 5 | $2 / $10 | 便宜 2.5× |
| Claude Opus 5 | $5 / $25 | 基准 |
| Claude Opus 4.8 | $5 / $25 | 同价 |
| Claude Fable 5 | $10 / $50 | 贵 2× |

数据来自 [AI Pricing Guru](https://www.aipricing.guru/news/anthropic-claude-opus-5-pricing-impact-july-2026/) 在 7 月 24 日的快照。**正确的口径**是：Opus 5 把 Fable 5 的"接近旗舰"能力打了个对折。

Opus 5 同步上线了 Fast mode，速度 2.5x、定价翻倍（$10/$50），这是给延迟敏感场景的 SKU。

另外，Anthropic 公告里提到两个新的 beta 能力（容易被忽略但很实用）：

- **Mid-conversation tool changes**：在同一会话里动态增减 tool，不用清空 prompt cache。
- **Automatic fallbacks on the API**：被安全分类器拦截的请求自动路由到其他模型，**而不是直接报错**——这条对生产环境意义很大。

---

## 2. 真实能力：Max Effort 下追平 Fable 5

官方公告给的对比图里，最值得看的不是绝对分数，而是**每个 token 的成本下能拿到的能力曲线**。

**软件工程**：
- **Frontier-Bench v0.1**：Opus 5 超过所有其他模型，**比 Opus 4.8 性能翻倍，成本更低**。
- **CursorBench 3.2**（Max Effort）：Opus 5 达到 Fable 5 峰值分数的 0.5% 以内，但**每个 task 成本只有 Fable 5 的一半**。
- AA Coding Agent Index：在更广义的工程任务上同样领先。

**知识工作**：
- **ARC-AGI 3**：Opus 5 得分是**第二名的 3 倍**（这个基准测的是模型面对"全新问题"的能力，3 倍意味着质的差距）。
- **Zapier AutomationBench**：完成率是第二名的 1.5×，**最低 effort 下比其他任何模型的最高 effort 还高**。
- **OSWorld 2.0**：超过 Fable 5 的最佳成绩，但成本只有它的 1/3。

Artificial Analysis 在 [独立测评](https://artificialanalysis.ai/models/claude-opus-5) 里给了更冷静的数据：
- **Intelligence Index: 61**（同类 median 32，处于 top tier）
- **输出速度: 53 tokens/s**（median 77，明确偏慢）
- **生成长度: 100M tokens**（median 63M，**非常啰嗦**）
- 上下文窗口: **1M tokens**

官方和第三方的口径差异很关键——**官方强调"性价比曲线"，第三方强调"绝对慢"**。

---

## 3. 值得专门写一段的提示词变化

这是这次发布里最反直觉、也最容易被踩坑的部分。

Anthropic 在 [提示词指南](https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5) 里写了一段非常明确的话：

> "Claude Opus 5 verifies its own work without being told to. **If your prompt contains explicit verification instructions** ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), **remove them**: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality."

翻译一下：**Opus 5 自带 verify 本能，你提示词里那些"加一步 verify / 用 subagent 验证一下"的写法，反而会导致它过度验证，浪费 token、没收益**。

这跟 Anthropic 工程师 [@trq212](https://twitter.com/trq212/status/2080710971228918066) 在 Twitter 上的公开声明呼应：

> "We removed over 80% of Claude Code's system prompt for Opus 5 and Fable 5"

Claude Code 的 system prompt 砍了 80%——能砍这么多，是因为 Opus 5 自己已经把"该做什么"内化了。

实操建议（如果你正在用 Claude Code / API 调 Opus 5）：

1. **删掉**所有"verify""double-check""use a subagent to validate"这类尾巴指令
2. **删掉**"think step by step"这类 CoT 提示（Opus 5 自带 extended thinking）
3. **删掉**"explain your reasoning"——它默认会解释，多余指令只会让它解释得更多更啰嗦
4. **保留**意图描述（"我想要什么"），而不是步骤描述（"先做 A 再做 B"）

HN 上 [网友 kloud](https://news.ycombinator.com/item?id=49053330) 的总结很到位：

> "Starting with Fable 5, if it goes off the rails, it is more difficult to correct it, because it is overall wrong, but covers its tracks with plausible sounding arguments. So keep the prompts lightweight and focused on intent."

Opus 5 处于同一族，提示词策略可以一起迁移。

---

## 4. 发布 2 天后出现了一次 Elevated Errors

这条不在 cron 摘要里，但开发者要知道。

[Claude Status 页面](https://status.claude.com/incidents/zftg3gqkmv18) 记录：
- 7 月 26 日 09:17 UTC：开始调查
- 09:45 UTC：定位问题
- 10:34 UTC：实施修复
- 10:44 UTC：恢复

影响范围：claude.ai / Claude Console / Claude API / Claude Code / Claude Cowork（全线产品）。

新模型上线后出现这种规模的故障不是新闻——Fable 5 上线时同样出过 [类似事件](https://status.claude.com)。**真正值得留意的是它持续了不到 2 小时就解决了**，且 Anthropic 没有把责任推给"流量高峰"。

---

## 5. 安全护栏：默认回退到 Opus 4.8

延续 Fable 5 的策略（Opus 4.8 时代已经在更窄范围做过类似 fallback），Opus 5 在网络安全的部分任务上护栏更严：

- **二元漏洞扫描**（更可能被恶意使用者利用）默认被拦截
- **渗透测试**和**漏洞利用生成**完全被拦
- **允许**源码中的漏洞发现（良性用例）

被拦截的请求默认 **fallback 到 Opus 4.8**（在 Claude.ai / Claude Code / Claude Cowork 三端），这是新行为。Fable 5 的 fallback 默认回退到 Opus 4.8 时，社区还吵过一轮（详见 [Fable 5 发布解读](https://www.onlythinking.com/post/2026-06-10-ai-anthropic-claude-fable5-mythos5-launch/)）；Opus 5 这次直接沿用，估计是想把争议控制在已熟悉的范围内。

如果你想拿掉 fallback，公告里说可以走 API 配置 + 申请 Anthropic 的 [Cyber Verification Program](https://www.anthropic.com/news/claude-fable-5-mythos-5)（参考 Fable 5 发布公告中的 CVP 说明，Opus 5 沿用同一申请通道）。

生物学方向，Opus 5 是**目前 Anthropic 通用模型里最强的科学研究模型**（Mythos 5 仍是最强，但仅在受控访问范围内）。从这条产品线动作看，Anthropic 正在把"长程自主研究"作为 Opus 5 区别于 Fable 5 的主战场——这一点在 Box / Hebbia 等合作客户的证言里反复出现。

---

## 6. 我的判断：要不要立刻迁移

**如果你正在用 Opus 4.8 做严肃生产工作**：

✅ **建议直接切到 Opus 5**（同价、能力更强），但请：
1. 调用层加 `response.model` 字段断言——万一 fallback 触发，能立刻发现
2. 删掉 verify 相关的 system prompt 尾巴
3. 监控 token 消耗（Opus 5 verbose 倾向明显，Artificial Analysis 数据显示它生成 token 数是同类中位数的 1.6×）

**如果你正在用 Fable 5 做成本敏感的工作**：

Opus 5 + Max Effort 是更便宜的替代，但需要做 benchmark 验证你的具体任务上能接受性能差异。CursorBench 上 0.5% 的差距听起来很小，落到你的任务上可能是另一回事。

**如果你是新接入**：

直接 `claude-opus-5` 起步，比 Sonnet 5 贵 2.5× 但能力跨一个档次，是当前 Anthropic 产品矩阵里性价比最好的位置。

---

## 参考来源

- [Anthropic 官方公告 - Introducing Claude Opus 5](https://www.anthropic.com/news/claude-opus-5)
- [Claude Platform Docs - What's new in Opus 5](https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5)
- [Artificial Analysis - Opus 5 独立测评](https://artificialanalysis.ai/models/claude-opus-5)
- [AI Pricing Guru - Opus 5 定价快照](https://www.aipricing.guru/news/anthropic-claude-opus-5-pricing-impact-july-2026/)
- [Claude Status - Elevated Errors for Opus 5](https://status.claude.com/incidents/zftg3gqkmv18)
- [HN 评论 - Opus 5 提示词策略](https://news.ycombinator.com/item?id=49053330)
- [@trq212 - Claude Code 系统提示砍了 80%](https://twitter.com/trq212/status/2080710971228918066)