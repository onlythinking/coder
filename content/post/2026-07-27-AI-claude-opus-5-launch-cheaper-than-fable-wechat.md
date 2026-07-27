---
title: "Opus 5 上线"
date: "2026-07-27"
description: "同Opus 4.8价,半价Fable 5,提示词要重写。"
tags: ["AI", "Anthropic", "Opus5"]
categories: ["AI"]
cover: /images/covers/2026-07-27-AI-claude-opus-5-launch-cheaper-than-fable.svg
---

Anthropic 在 7 月 24 日凌晨上线了 Claude Opus 5，HN 当日冲到 1764 分登顶当日热榜第一。

这条消息在中文圈被简化为「Opus 5 比 Opus 4 还便宜」——**这句话是错的**。

正确的版本是：Opus 5 与 Opus 4.8 同价，但比旗舰 Fable 5 便宜一半。它的真正卖点不是更便宜，而是**用一半的钱拿到接近 Fable 5 的能力**。

本文扒一扒这次发布到底意味着什么、哪些提示词写法现在该改。

---

## 一、先纠正被传歪的定价

官方公告原话：定价 $5 每百万输入 token、$25 每百万输出 token（与 Opus 4.8 完全相同）。

把它放到 Anthropic 当前的产品矩阵里看：

- Claude Sonnet 5：$2 / $10（比 Opus 5 便宜 2.5 倍）
- Claude Opus 5：$5 / $25（基准）
- Claude Opus 4.8：$5 / $25（同价）
- Claude Fable 5：$10 / $50（贵 2 倍）

**正确的口径**：Opus 5 把 Fable 5 的「接近旗舰」能力打了个对折。

具体定价以 Anthropic 官网为准。

Opus 5 同步上线了 Fast mode，速度 2.5 倍、定价翻倍（$10/$50），给延迟敏感场景用。

---

## 二、真实能力：Max Effort 下追平 Fable 5

官方公告里最值得看的不是绝对分数，而是**每个 token 的成本下能拿到的能力曲线**。

软件工程：
- **Frontier-Bench v0.1**：Opus 5 超过所有其他模型，**比 Opus 4.8 性能翻倍、成本更低**。
- **CursorBench 3.2**（Max Effort）：Opus 5 达到 Fable 5 峰值分数的 0.5% 以内，但**每个 task 成本只有 Fable 5 的一半**。
- AA Coding Agent Index：在更广义的工程任务上同样领先。

知识工作：
- **ARC-AGI 3**：Opus 5 得分是**第二名的 3 倍**。
- **Zapier AutomationBench**：完成率是第二名的 1.5 倍，**最低 effort 下比其他任何模型的最高 effort 还高**。
- **OSWorld 2.0**：超过 Fable 5 的最佳成绩，成本只有它的三分之一。

Artificial Analysis 给了更冷静的数据：
- Intelligence Index 61（同类 median 32，处于 top tier）
- 输出速度 53 tokens/s（median 77，明确偏慢）
- 生成长度 100M tokens（median 63M，**非常啰嗦**）
- 上下文窗口 1M tokens

官方强调「性价比曲线」，第三方强调「绝对慢」——两个口径都要看。

---

## 三、最反直觉的提示词变化

这是这次发布里最容易踩坑的部分。

Anthropic 提示词指南原文：

> Claude Opus 5 verifies its own work without being told to. **If your prompt contains explicit verification instructions** ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), **remove them**: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality.

翻译一下：**Opus 5 自带 verify 本能，你提示词里那些「加一步 verify / 用 subagent 验证一下」的写法，反而会导致它过度验证，浪费 token、没收益**。

Anthropic 工程师公开声明：Claude Code 的 system prompt 砍了 80%。

实操建议（如果你正在用 Claude Code / API 调 Opus 5）：

1. **删掉**所有「verify」「double-check」「use a subagent to validate」这类尾巴指令
2. **删掉**「think step by step」这类 CoT 提示（Opus 5 自带 extended thinking）
3. **删掉**「explain your reasoning」——它默认会解释，多余指令只会让它解释得更多更啰嗦
4. **保留**意图描述（我要什么），而不是步骤描述（先做 A 再做 B）

---

## 四、发布 2 天后出现了一次 Elevated Errors

Claude Status 页面记录：

- 7 月 26 日 09:17 UTC：开始调查
- 09:45 UTC：定位问题
- 10:34 UTC：实施修复
- 10:44 UTC：恢复

影响范围：claude.ai / Claude Console / Claude API / Claude Code / Claude Cowork（全线产品）。持续不到 2 小时就解决。

---

## 五、要不要立刻迁移

**如果你正在用 Opus 4.8 做严肃生产工作**：

建议直接切到 Opus 5（同价、能力更强），但请：

1. 调用层加 response.model 字段断言——万一 fallback 触发，能立刻发现
2. 删掉 verify 相关的 system prompt 尾巴
3. 监控 token 消耗（Opus 5 verbose 倾向明显）

**如果你正在用 Fable 5 做成本敏感的工作**：

Opus 5 + Max Effort 是更便宜的替代，但需要做 benchmark 验证你的具体任务上能接受性能差异。

**如果你是新接入**：

直接 claude-opus-5 起步，比 Sonnet 5 贵 2.5 倍但能力跨一个档次，是当前 Anthropic 产品矩阵里性价比最好的位置。

---

本文所有数据均基于 Anthropic 官方公告、System Card、提示词指南、Artificial Analysis 第三方测评、HN 主流评论。具体价格以 Anthropic 官网最新公告为准。

想看更详细的官方公告解读，可以在公众号后台回复「Opus 5」获取博客完整版链接。