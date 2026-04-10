---
title: "Serena：让 AI 编程 Agent 拥有 IDE 级别的代码理解能力"
date: 2026-04-11
description: "Serena 是一个基于 MCP 协议的开源编程工具包，为 AI Agent 提供符号级代码检索、编辑和重构能力，支持 40+ 编程语言，可接入 Claude Code、Cursor 等主流 AI 编程工具"
tags: ["工具", "AI编程", "MCP", "开源"]
categories: ["工具"]
keywords: ["Serena", "AI编程", "MCP协议", "代码检索", "编程工具", "Claude Code", "vibe coding"]
draft: false
readingTime: 5 分钟
---

## 目录

{{< toc >}}

## 背景

GitHub 上有一个增长极快的新项目 [Serena](https://github.com/oraios/serena)，发布两个月 star 数突破 2.3 万。它的核心定位很清晰：**给 AI 编程 Agent 提供和人类开发者使用 IDE 时一样的代码理解能力**。

这听起来不新鲜，但实际做起来很难。传统 AI 编程工具本质上是"大海捞针"——让 LLM 读取整个文件再理解。这种方式在小项目里没问题，但在大型代码库里，token 消耗大、定位不准确、上下文窗口很快被撑满。

Serena 试图解决这个问题。

## 核心能力

Serena 提供了一套语义级的代码查询和编辑工具，可以理解为给 AI Agent 用的"IDE 导航功能"：

**代码检索**
- 按符号（函数、类、变量）搜索，而不是全文关键词匹配
- 查看符号的引用关系——谁调用了这个函数，谁修改了这个变量
- 在项目依赖中搜索，不只是当前源码

**代码编辑**
- 理解代码结构后的精准编辑，而不是替换字符串
- 支持重构操作（重命名符号、提取方法等）

**多语言支持**
Serena 有两种后端模式：

| 后端 | 支持语言数 | 特点 |
|------|-----------|------|
| Language Server (LSP) | 40+ | 开源免费，默认模式 |
| JetBrains 插件 | JetBrains 全家桶覆盖的所有语言 | 需要付费许可，有免费试用 |

LSP 模式支持的语言包括：Go、Python、Java、JavaScript、TypeScript、Rust、C/C++、Ruby、Swift、Kotlin，以及 Haskell、Erlang、Clojure、Solidity 等小众语言。

## 技术原理：MCP 协议

Serena 基于 **Model Context Protocol（MCP）** 工作。MCP 是 Anthropic 提出的标准协议，让 AI 模型与外部工具和数据源交互。Serena 作为一个 MCP Server，可以接入任何支持 MCP 的 AI 客户端：

**支持的客户端**
- 终端工具：Claude Code、Codex、OpenCode、Gemini-CLI
- IDE 插件：VSCode、Cursor、JetBrains 系列
- 桌面/网页应用：Claude Desktop、OpenWebUI

接入方式也很简单：给客户端提供一个启动命令，让它自动启动 Serena MCP Server；或者手动以 HTTP 模式启动 Server，客户端通过 URL 连接。

## 安装使用

```bash
# 安装
pip install serena

# 方式1：stdio 模式（默认）
serena

# 方式2：HTTP 模式，支持远程连接
serena --http --port 8080
```

接入 Claude Code 时，只需在 `settings.json` 中配置 MCP 服务器地址，具体参考[官方文档](https://oraios.github.io/serena/)。

## 和传统方案的对比

| 能力 | 全文搜索 | 普通 AI 编程 | Serena |
|------|---------|-------------|--------|
| 语义理解 | 无 | 依赖 prompt | 有 |
| 跨文件关系 | 无 | 弱 | 有 |
| 符号定位 | 无 | 无 | 有 |
| 重构支持 | 无 | 有限 | 有 |
| 多语言 | 无 | 无 | 40+ |

在大型代码库里，这种差异会更明显。比如你要修改一个被十几文件引用的函数，全文搜索会返回所有匹配行，但 Serena 能直接告诉你这个函数的调用图，AI 理解起来更准确。

## 实际场景

Serena 适合以下场景：

**大型代码库维护**
几百个文件的 monorepo，靠读文件理解代码效率很低。Serena 可以快速帮你定位相关代码。

**AI 编程工作流**
用 Claude Code 或 Cursor 编程时，Serena 提供了更可靠的代码理解底层，AI 生成的修改更准确。

**多语言混合项目**
比如一个项目同时有 Go 后端、TypeScript 前端、Python 脚本，LSP 后端统一支持。

## 局限

需要客观看待 Serena 的定位：

1. **它不生成代码**——Serena 提供工具，实际编程仍由 AI 完成
2. **LSP 后端依赖语言服务器**——部分小众语言可能没有成熟的 LSP 实现
3. **JetBrains 插件需要付费**——不过有免费试用期

## 总结

Serena 是一个解决实际问题的开源工具。它不是又一个 AI 聊天界面，而是专注于**让 AI 编程 Agent 真正理解代码**。如果你在用 Claude Code、Cursor 或其他 AI 编程工具，接入 Serena 能明显提升代码理解的准确性。

GitHub：[oraios/serena](https://github.com/oraios/serena)（MIT 协议，⭐ 23k+）

## 相关文章

- [2025年 Vibe Coding 元年：AI 重新定义开发者工作方式](https://www.onlythinking.com/post/2025-09-26-热点_2025年vibe-coding元年ai重新定义开发者工作方式/)
- [2025年 Python AI Agent 开发完全指南](https://www.onlythinking.com/post/2025-09-29-热点_2025年python-ai-agent开发完全指南从框架选择到实战应用/)
- [2025多智能体系统实战指南](https://www.onlythinking.com/post/2025-10-04-热点_2025多智能体系统实战指南用python构建企业级ai-agent协作平台/)

---

> 如果觉得有帮助，欢迎分享！
> [X/Twitter](https://twitter.com/intent/tweet?text=Serena：让AI编程Agent拥有IDE级别的代码理解能力&url=https://www.onlythinking.com/post/2026-04-11-tools-serena开源ai编程agent-ide/&hashtags=AI编程,MCP,vibe-coding) | [微信分享](#) | [Hacker News](https://news.ycombinator.com/submitlink?u=https://www.onlythinking.com/post/2026-04-11-tools-serena开源ai编程agent-ide/&t=Serena：让AI编程Agent拥有IDE级别的代码理解能力)
