---
title: "Weft：面向AI系统的Rust编程语言"
date: 2026-04-22T12:40:00+08:00
description: "Weft是一种专为AI系统设计的Rust编程语言，将LLM、人类、API和基础设施作为基础组件，通过类型系统验证架构，自動生成可视化程序图。本文深入解析其设计理念、核心特性和实战用法。"
tags: ["AI编程", "Rust", "编程语言", "AI Agent", "Weft", "大语言模型"]
categories: ["AI"]
keywords: ["Weft编程语言", "AI系统编程", "Rust AI框架", "AI Agent开发", "持久化执行", "类型化AI工作流"]
draft: false
toc: true
readingTime: 8
---

## 引言

2026年，软件系统正在经历根本性变革。LLM的调用、数据库的启动、人机交互的协调、网页浏览和Agent编排，这些能力正在成为程序的基础组件。然而，开发者仍然在导入各种库，为本应简单的事情编写大量胶水代码。

**Weft** 是一种专门为AI系统设计的编程语言，基于Rust生态系统构建。它的核心理念是将LLM、人类、API和基础设施作为语言的一等公民，让开发者通过节点和连接来构建程序，由编译器验证架构，并自动生成可视化程序图。

## Weft的核心设计理念

### 从胶水代码到一等公民

传统编程范式中，调用LLM需要编写大量样板代码：API客户端初始化、请求序列化、响应解析、错误重试、超时处理。Weft将这些能力直接内置为语言级节点。

```weft
topic = Text {
  label: "Topic"
  value: "the silence between stars"
}

llm_config = LlmConfig {
  label: "Config"
  model: "anthropic/claude-sonnet-4.6"
  systemPrompt: "Write a short, beautiful poem (4-6 lines) about the given topic."
  temperature: "0.8"
}

poet = LlmInference -> (response: String) {
  label: "Poet"
}
poet.prompt = topic.value
poet.config = llm_config.config

output = Debug { label: "Poem" }
output.data = poet.response
```

上述代码仅用四个节点就完成了LLM调用：接收输入文本、配置模型参数、执行推理、输出结果。编译器在运行前就验证了每个连接的类型兼容性。

### 双向视图：代码与图形等价

Weft程序可以同时呈现为面向AI开发者的密集代码视图，和面向人类的图形化视图。编辑其中任意一个，另一个会自动同步更新。这种设计让技术和非技术背景的团队成员都能参与AI系统的构建和审核。

### 递归可折叠性

任何一组节点都可以折叠为单个节点，只需定义其接口。百节点的系统在顶层仍然呈现为五个模块。这种递归可折叠性让复杂AI工作流的复杂度始终处于可控范围。

## 类型系统与架构验证

### 端到端类型检查

Weft继承了Rust的类型系统特性，包括泛型、联合类型、类型变量和空值传播。这不仅确保了运行时安全，更能在编译期捕获缺失的连接、类型不匹配和架构问题。

```weft
# 类型化的连接示例
user_input = HumanQuery {
  label: "用户输入"
  formTemplate: "请提供您的需求描述"
}

validated = Gate -> (approved: Boolean) {
  label: "内容审核"
}

# 编译器验证：user_input.response -> validated.input 的类型兼容性
validated.input = user_input.response
```

### 架构级别的验证

与普通类型检查不同，Weft的编译器还能验证组件之间的架构关系。例如，当一个节点需要外部API密钥而未提供时，编译器会提前报错，而非等到运行时才发现问题。

## 持久化执行与状态管理

### Durability保证

Weft程序通过Restate实现持久化执行。程序可以承受崩溃和重启：需要人工审批的三天流程和执行一次的三秒流程使用完全相同的代码范式。

```weft
approval_flow = HumanQuery -> (result: ApprovalResult) {
  label: "经理审批"
  timeout: "72h"  # 三天超时
  notification: Email { to: "manager@company.com" }
}

# 即使服务重启，流程也会从中断处恢复
result = approval_flow.submit(request)
```

### 状态自动管理

传统AI工作流需要开发者手动管理状态：保存中间结果、处理断点续传、处理并发冲突。Weft的持久化执行模型自动处理这些复杂性，开发者只需关注业务逻辑本身。

## 内置节点生态

### AI与推理节点

- **LlmConfig**: 配置大语言模型参数（模型选择、系统提示、温度等）
- **LlmInference**: 执行LLM推理，返回结构化响应

### 通信节点

- **HumanQuery**: 暂停程序，向人类发送表单并等待回复，支持邮件、Slack、Telegram、WhatsApp、Discord等多种渠道
- **Email/X/Discord/Slack/Telegram/WhatsApp**: 各类消息渠道集成

### 数据与存储节点

- **Postgres**: 数据库操作节点
- **Memory**: 内存存储
- **Text/Number/Dict/List**: 基础数据类型处理

### 流程控制节点

- **Gate**: 条件分支和审批流程
- **Trigger/Cron**: 定时任务和 webhook 触发
- **Template**: 模板渲染

### 外部服务节点

- **WebSearch**: 网页搜索（通过Tavily）
- **Apollo**: 数据丰富化
- **SpeechToText**: 语音转文本（通过ElevenLabs）

## 快速上手指南

### 环境要求

- Docker（用于PostgreSQL）
- Node.js
- macOS需要Bash 4+

### 安装步骤

```bash
# 克隆仓库
git clone https://github.com/WeaveMindAI/weft.git
cd weft

# 复制环境配置
cp .env.example .env
# 编辑.env添加API密钥

# 启动后端（自动安装依赖、启动PostgreSQL和Restate）
./dev.sh server

# 另一个终端启动前端
./dev.sh dashboard
```

访问 http://localhost:5173 即可开始构建第一个项目。

### 可选API密钥

```bash
OPENROUTER_API_KEY=***      # LLM节点（支持多种模型）
TAVILY_API_KEY=***          # 网页搜索节点
ELEVENLABS_API_KEY=***       # 语音转文本节点
DISCORD_BOT_TOKEN=***        # Discord集成
APOLLO_API_KEY=***           # 数据丰富化
```

## 项目架构解析

### 目录结构

```
weft/
├── catalog/              # 节点定义（真理来源）
│   ├── ai/               #   LLM配置和推理
│   ├── code/              #   Python执行
│   ├── communication/      #   Discord、Slack、电报、邮件等
│   ├── data/              #   基础数据类型
│   ├── enrichment/         #   数据丰富化
│   ├── flow/              #   流程控制
│   └── storage/           #   Postgres存储
├── crates/
│   ├── weft-core/          # 类型系统、编译器、执行器
│   ├── weft-nodes/         # 节点trait和注册表
│   ├── weft-api/           # REST API
│   └── weft-orchestrator/  # Restate服务编排器
└── dashboard/             # SvelteKit前端
```

### 节点扩展机制

每个节点由两个文件组成：

- `backend.rs`: Rust实现（实现Node trait）
- `frontend.ts`: 前端UI定义（端口、配置字段、图标）

添加新节点只需在一个文件夹下创建这两个文件，体现了Weft对扩展性的重视。

## 与传统方案的对比

| 特性 | 传统方案 | Weft |
|------|----------|------|
| LLM调用 | 编写胶水代码 | 内置节点，一行调用 |
| 状态管理 | 手动保存/恢复 | 持久化执行自动管理 |
| 类型检查 | 仅变量类型 | 架构级别验证 |
| 可视化 | 需第三方工具 | 语言内置 |
| 人机交互 | Webhook/轮询 | 内置HumanQuery节点 |
| 错误处理 | 分散各处 | 编译器+运行时双重保障 |

## 适用场景与局限

### 理想场景

- 多Agent协作系统
- 需要人工审核的AI工作流
- 复杂的人机交互流程
- 需要持久化保证的生产系统
- 跨多个服务和API的集成场景

### 当前局限

Weft仍处于早期阶段（开源仅两个月），存在以下局限：

- 节点目录较小（仅数十个节点）
- 破坏性变更可能发生
- 自定义节点功能尚未完善
- 文档和示例需要补充

**注意**：生产环境使用请将其视为构建基础而非完整产品。

## 总结

Weft代表了AI系统编程的一种新范式：将LLM、人类、API和基础设施提升为一等公民，通过类型系统确保架构正确性，内置持久化执行能力。它试图回答一个根本问题：在AI时代，什么应该是编程语言的基础组件？

如果你正在构建需要协调LLM、人类和各种服务的复杂系统，Weft值得一试。访问官方文档 https://weavemind.ai/docs 获取更多信息。

---

**参考链接**：

- GitHub仓库：https://github.com/WeaveMindAI/weft
- 官方文档：https://weavemind.ai/docs
- 设计理念：https://weavemind.ai/blog/future-of-programming

*免责声明：本文涉及的API定价信息可能随时间变化，请以官方最新公告为准。*
