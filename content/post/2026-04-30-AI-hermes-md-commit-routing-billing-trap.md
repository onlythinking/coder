---
title: "小心！Claude Code 的 HERMES.md 关键词可能在悄悄增加你的账单"
date: 2026-04-30
description: "深度分析 Claude Code 最新爆出的 HERMES.md 路由计费争议——commit message 中包含特定文本可能触发额外计费，附真实案例和防范指南。"
tags: ["Claude Code", "AI编程", "安全", "计费", "工具"]
categories: ["AI"]
keywords: ["Claude Code计费", "HERMES.md", "AI工具安全", "编程Agent计费陷阱", "Claude Code使用成本"]
draft: false
toc: true
readingTime: 8 分钟
cover: /images/covers/hermes-md-commit-routing-billing-trap.png
---

## 背景

最近 GitHub 上一个 Issue 引发了 AI 编程工具圈的热议：[anthropics/claude-code#53262](https://github.com/anthropics/claude-code/issues/53262)。标题原文为：

> **HERMES.md in commit messages causes requests to route to extra usage billing**

一位开发者在使用 Claude Code 时发现，自己的 commit message 中包含特定文本后，请求被悄悄路由到了会产生额外费用的服务端点。**而这个行为没有在 CLI 输出或文档中明确告知用户。**

这个问题的核心在于 **HERMES.md 文件**——当 commit message 出现特定关键词时，会触发一个隐藏的路由逻辑，将请求发送到一个可能产生更高费用的后端服务。

## 问题始末

### Issue 来源

该 Issue 在 Hacker News 上获得了 972 分，触发了不少开发者的共鸣。Issue 的核心描述很直接：

1. 用户在 commit message 中使用了 "HERMES" 相关的词汇（例如 `docs: update HERMES configuration`）
2. 之后发现 Claude Code 的 API 调用费用出现异常峰值
3. 进一步追踪发现，请求被路由到了一种"额外计费"的后端

### 社区反馈

该 Issue 下的评论揭示了更多细节：

- **多名开发者报告了类似经历**：均在 commit message 中提到 HERMES 相关词汇后出现账单异常
- **路由行为是静默的**：没有任何日志、警告或确认提示告知用户路由已变更
- **触发门槛低**：不只是 "HERMES"，"hermes-gateway"、"hermes-config" 等组合词也可能触发
- **文档中没有说明**：官方文档没有提到 commit message 内容会影响计费路由

有开发者评论：

> 如果银行悄悄把你的账户余额转入高利率理财，你也会觉得没问题吗？

也有不同意见：

> 这是内部实现的正常逻辑，高级路由可能对应不同的 SLA 或功能，不告知用户也合理。

### 影响范围

根据社区报告，以下场景可能触发路由变更：

| 场景 | 是否可能触发 |
|------|------------|
| commit message 含 "HERMES" | ✅ 可能 |
| commit message 含 "hermes-gateway" | ✅ 可能 |
| commit message 含 "hermes-config" | ✅ 可能 |
| 代码注释中含上述词汇 | ❌ 不触发 |
| 普通功能描述 | ❌ 不触发 |

理论上，所有在 commit message 中使用相关词汇的开发者都可能受影响。

## 技术分析

### HERMES.md 的作用

HERMES.md 是 Claude Code 内部使用的一个配置文件（类似于 CLAUDE.md 但用于内部路由策略），用于定义请求路由规则和服务端点。

当 commit message 匹配到特定模式时，请求会被路由到"额外使用量计费"的端点——这个端点可能提供不同的功能或 SLA，但**费率确实与标准端点不同**。

### 关键问题：透明度

无论这种路由机制的初衷是什么，有一点是明确的：**用户没有被告知**。

Claude Code 在以下方面存在信息缺失：

- **无提示**：路由切换时不输出任何警告
- **无日志**：默认日志不显示实际路由目的地
- **无文档**：官方文档未说明 commit message 内容会影响计费
- **无配置项**：用户无法主动指定使用哪个路由端点

### 风险评估

| 风险维度 | 评估 |
|---------|------|
| 影响范围 | 广泛（任何用 Claude Code 写 commit 的开发者） |
| 严重程度 | 中（费用增加幅度尚不明确，可能 2-5x） |
| 可发现性 | 低（无提示，需要查账单才能发现） |
| 恶意意图 | 可能无，但用户信任受损是确定的 |

## 如何验证和防范

### 检查方法

如果你想确认自己是否受到影响，可以：

**方法一：回顾 commit message 内容**

检查你最近的 Claude Code 使用记录，看 commit message 是否包含 "HERMES"、"hermes-gateway"、"hermes-config" 等词汇。

**方法二：对比账单**

如果你使用的是 Claude Code 的 API 模式，对比触发前后的 API 调用量，看是否有异常增长。

**方法三：查看 Claude Code 日志**

尝试使用 verbose 模式查看详细日志（注意：以下命令为推测，实际情况可能不同）：

```bash
claude-code --verbose 2>&1 | grep -i "route\|billing\|endpoint"
```

### 临时规避方案

**方案一：避免 HERMES 关键词**

在 commit message 中使用替代词：

```bash
# 替代方案
git commit -m "docs: update routing configuration"
git commit -m "fix: message gateway settings"
git commit -m "chore: internal service config"
```

**方案二：配置用量上限**

在 Claude Code 的配置中设置每月最大预算，防止意外超支。

**方案三：等待官方修复**

该 Issue 目前已被标记为需要关注，预计官方会在后续版本中增加透明度的改进。

## 长期思考：AI 工具的成本透明度

这个案例揭示了 AI 编程工具领域的一个深层问题：**成本模型的复杂性带来的透明度挑战**。

现代 AI 编程工具的计费模式往往包含：
- 不同端点的不同费率
- 基于请求内容的动态路由
- 隐藏的"高级"或"额外"服务

这些复杂性在带来灵活性的同时，也侵蚀了用户的信任。**当用户无法预测自己的使用成本时，工具的价值主张就会打折扣。**

对于 AI 工具开发者而言，无论路由机制的细节如何设计，**任何可能影响用户成本的决策都应该对用户可见**。这不仅是道德要求，也是产品长期成功的必要条件。

## 总结

HERMES.md 路由计费争议的核心不在于"是否应该收费"，而在于**透明度**。用户有权知道自己的请求被路由到哪里，以及这意味着什么样的费用。

建议开发者：
1. **检查**自己的 Claude Code 近期使用记录和账单，看是否有异常
2. **规避**在 commit message 中使用 HERMES 相关关键词（作为临时方案）
3. **关注**官方对该 Issue 的后续回应和修复

建议 AI 工具开发者：
1. **公示**所有可能影响计费的路由规则
2. **增加**路由切换时的用户提示
3. **提供**用户可控的路由选择

---

**相关资源**
- [GitHub Issue #53262](https://github.com/anthropics/claude-code/issues/53262)
- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)
- [Anthropic 定价页面](https://www.anthropic.com/pricing)

---

**分享到**

- [X/Twitter](https://twitter.com/intent/tweet?text=小心！Claude%20Code%20的%20HERMES.md%20关键词可能在悄悄增加你的账单&url=https://www.onlythinking.com/post/hermes-md-commit-routing-billing-trap/)
