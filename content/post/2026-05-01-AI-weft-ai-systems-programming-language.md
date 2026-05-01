---
title: "Weft：为AI系统而生的编程语言"
date: 2026-05-01
description: "Weft 是一种面向 AI 系统的编程语言，将 LLM、数据库、API 和人类等基元作为一级公民，通过类型系统编排复杂 AI 工作流，编译器在运行前即可检查架构正确性。"
tags: ["AI", "编程语言", "Agent", "工具"]
categories: ["AI"]
keywords: ["Weft", "AI编程语言", "Agent编排", "工作流语言", "MCP"]
draft: false
---

## 背景

2026 年，AI Agent 已从实验走向生产。你可能每天都在用 Claude Code、AutoGen 或 LangGraph 编排复杂的工作流——但你有没有停下来思考，这些框架本质上是什么？

它们本质上是**胶水代码**：用 Python 拼凑 HTTP 调用、状态机、webhook 逻辑，让 AI 执行任务。你花了大量时间写 import、配置 API、处理错误，却把最重要的业务逻辑埋在了 Plumbing（管道工程）里。

这就是 Weft 想要解决的问题。

## 问题：现有的 AI 编排太底层

### 传统方案的困境

当你用 Python 构建一个需要人类审批的 AI 工作流时，可能长这样：

```python
# 一个典型的人类审批流程
import httpx, asyncio, json

async def human_approval_flow():
    task_id = await llm.create_task()
    
    # 人类审批逻辑：需要自己实现状态存储、webhook、轮询
    approval_store = await PostgresStore.create()
    await approval_store.save(task_id, "pending")
    
    # 启动 webhook 服务器等待回调
    server = await start_webhook_server("/approve", handle_approve)
    
    # 轮询直到审批完成（可能需要3天）
    while True:
        status = await approval_store.get(task_id)
        if status == "approved":
            break
        await asyncio.sleep(3600)  # 每小时检查一次
    
    await server.stop()
    result = await llm.resume(task_id)
    return result
```

这里有几个严重问题：
1. **状态管理分散**：审批状态存在 PostgreSQL，但轮询逻辑在 asyncio 里，两边没有天然联系
2. **错误处理复杂**：网络超时、服务器重启、数据库连接断开，每一项都可能让你的工作流永久卡死
3. **类型安全缺失**：task_id 是字符串，status 是字符串，整个系统的正确性依赖人工检查
4. **人类参与困难**：webhook 回调、轮询、状态同步——让一个人参与进来需要几十行代码

### Weft 的解决思路

Weft 的核心理念很简单：**把 AI 工作流中的所有参与者（LLM、人类、API、数据库、消息队列）都作为语言的一级基元**，而不是需要手动配置的外部资源。

看一个等价的 Weft 程序：

```weft
# 项目：诗歌生成器
topic = Text { label: "Topic", value: "the silence between stars" }

llm_config = LlmConfig {
  model: "anthropic/claude-sonnet-4.6"
  systemPrompt: "Write a short, beautiful poem (4-6 lines) about the given topic."
}

poem = LLM { config: llm_config, prompt: topic }
HumanApproval { content: poem, approver: "editor@weavemind.ai" }
```

这就是全部代码。LLM 生成诗歌，人类审批，整个流程的 durable（持久化）执行由 Restate 负责——程序崩溃后重启，精确恢复到崩溃位置，审批等待 3 天和 3 秒没有区别。

## 核心概念

### 节点（Nodes）

Weft 程序由节点组成。每个节点代表一个动作或一个等待：

| 节点类型 | 作用 |
|---------|------|
| `LLM` | 调用大语言模型 |
| `HumanQuery` | 暂停，等待人类输入 |
| `HTTP` | 发送 HTTP 请求 |
| `Code` | 执行 Python/Rust 代码 |
| `Gate` | 条件分支 |
| `Template` | 文本模板 |
| `Discord/Slack/Telegram/Email/X` | 发送消息 |
| `Postgres/Memory/Search` | 数据存储和检索 |

你不需要 import 这些——它们是语言内置的基元。

### 类型化的连接

节点之间通过类型化的端口连接：

```weft
user_input = Text { label: "User Input" }
classified = LLM {
  model: "openai/gpt-4o"
  systemPrompt: "Classify as: support, sales, or feedback"
  prompt: user_input
}

# Gate 根据 LLM 输出路由到不同节点
SupportFlow { issue: classified } when classified == "support"
SalesFlow  { lead: classified } when classified == "sales"
FeedbackArchive { note: classified } when classified == "feedback"
```

编译器在运行前检查每个连接的类型是否匹配——如果 `classified` 的类型与目标节点的期望类型不符，编译失败，而不是运行时崩溃。

### 可折叠子图

100 个节点的复杂系统，可以折叠成 5 个高层的抽象节点：

```weft
# 定义一个子图
OrderProcessing = Graph {
  receive: HTTP { path: "/webhook/order" }
  validate: LLM { model: "claude-sonnet-4.6", prompt: "Validate order data" }
  check_stock: Postgres { query: "SELECT available FROM inventory WHERE sku=$1" }
  ship: Gate { condition: check_stock.available > 0 }
}

# 使用时像一个普通节点
FullSystem = Graph {
  order: OrderProcessing
  notify: Email { to: "ops@company.com" }
  connect order.success -> notify
}
```

在 IDE 中，你可以点击 `OrderProcessing` 展开查看内部细节，也可以在顶层把它当作一个黑盒处理。

### 持久化执行

Weft 程序通过 [Restate](https://restate.dev) 实现 durable execution。Restate 是一个构建在消息队列之上的执行运行时，提供了：

- **精确一次执行**：每条消息只被处理一次，即使程序重启
- ** humaine 暂停**：程序可以在任意节点暂停，等待人类回复，回复后继续精确位置
- **透明度**：你可以在运行时查看任意节点的当前状态

## Quick Start

Weft 需要 Docker（PostgreSQL）和 Node.js（macOS 需 Bash 4+）：

```bash
git clone https://github.com/WeaveMindAI/weft.git
cd weft
cp .env.example .env
# 添加 API keys: OPENROUTER_API_KEY, TAVILY_API_KEY 等

# 终端1：启动后端（自动安装依赖、启动 PostgreSQL 和 Restate）
./dev.sh server

# 终端2：启动 dashboard
./dev.sh dashboard
```

打开 http://localhost:5173，你会看到两个视图：代码视图（面向 AI 开发者）和图形视图（面向人类）。修改其中一个，另一个自动同步——没有「代码生成图形」或「图形导出代码」的割裂感。

## 与现有框架的对比

| 维度 | LangGraph | AutoGen | Weft |
|------|-----------|---------|------|
| 学习曲线 | 中等（Python） | 中等（Python） | 低（图/代码双视图） |
| 类型安全 | 无 | 无 | 完整类型系统 |
| 人类参与 | 手动实现 | 手动实现 | 内置节点 |
| 持久化 | 无 | 无 | Restate 支持 |
| IDE 支持 | 无 | 无 | 可视化 Dashboard |
| 适用场景 | 复杂条件分支 | 多 Agent 协作 | 任意 AI 工作流 |

Weft 并不是要替代 LangGraph 或 AutoGen——它针对的是不同的使用场景：**当你需要严谨的架构、类型安全、以及人类与 AI 深度协作的工作流时**，Weft 提供了开箱即用的基础设施，而不需要你手动构建。

## 适用场景与局限

### 适合用 Weft 的场景
- 需要多个人类审批节点的复杂业务流程
- 需要长期运行的 AI 任务（等待人类回复可能长达数天）
- 对系统架构正确性有强要求的团队（类型系统在编译时捕获连接错误）
- 需要可视化地向非技术人员展示 AI 工作流

### 不适合的场景
- 简单的单次 LLM 调用（直接用 API 更轻量）
- 需要极致定制化的复杂逻辑（Weft 的节点抽象可能不够灵活）
- 生产级项目（Weft 目前仍处于早期，breaking changes 预期会持续一段时间）

> 作者注：Weft 仍处于快速迭代期，根据其 README，「breaking changes are expected while the shape is still settling」。生产使用时建议关注其 Release Notes 和 Migration Guide。

## 总结

Weft 代表了一个新兴方向：**把 AI 系统编排从「用 Python 写胶水代码」升级为「用专门的 DSL 描述架构，编译器负责检查正确性」**。

它的核心理念——把 LLM、人类、API 都作为语言的一级基元，加上类型化的连接和可折叠的子图——在概念上是优雅的。如果你在构建需要人类深度参与的 AI 工作流，或者对系统的架构正确性有较高要求，Weft 值得关注。

当然，作为一个 2026 年才发布的新项目，它的能力边界还在探索中，社区和生态也还需要时间成长。但考虑到它解决的是真实存在的痛点，这个方向值得持续关注。

**相关资源：**
- GitHub: https://github.com/WeaveMindAI/weft
- 文档: https://weavemind.ai/docs
- Discord: https://discord.gg/FGwNu6mDkU