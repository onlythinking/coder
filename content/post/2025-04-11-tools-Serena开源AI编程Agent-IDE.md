---
title: "Serena，开源的 AI 编程 Agent IDE"
date: 2025-04-11
description: "Serena 是一个基于 MCP 协议的语义编程工具包，为 AI 编程 Agent 提供符号级的代码检索、编辑和重构能力，支持 40+ 编程语言"
tags: ["工具", "AI", "编程"]
categories: ["工具"]
keywords: ["AI编程", "MCP", "Serena", "代码检索", "编程工具"]
draft: false
---

# Serena，开源的 AI 编程 Agent IDE

最近 GitHub 上出现了一个增长极快的开源项目——[Serena](https://github.com/oraios/serena)，短短几周时间 star 数突破 2 万。它解决了一个很实际的问题：**让 AI 编程 Agent 拥有和人类开发者一样的代码理解和编辑能力**。

## 解决的问题

传统的 AI 编程工具，比如直接让 LLM 读取文件做修改，在大型代码库里效率很低——文件大、关系复杂、上下文窗口很快被撑满。Serena 提供了**语义级的代码查询和编辑能力**，类似于 IDE 给人类开发者提供的代码导航：

- **符号搜索**：按函数、类、变量名搜索，而不是全文关键词匹配
- **引用查找**：找到某个符号被哪些地方引用了
- **类型层级**：查看类的继承关系
- **依赖搜索**：在项目依赖中搜索，而不只是源码

## 核心技术：MCP 协议

Serena 基于 **Model Context Protocol（MCP）** 工作。MCP 是 Anthropic 提出的模型上下文协议，让 AI 模型可以和外部工具/数据源交互。Serena 作为一个 MCP Server，可以接入任何支持 MCP 的 AI 客户端：

- **终端工具**：Claude Code、Codex、OpenCode、Gemini-CLI
- **IDE 插件**：VSCode、Cursor、JetBrains 系列
- **桌面/网页客户端**：Claude Desktop、OpenWebUI

## 支持的语言

使用 Language Server Protocol（LSP）作为后端时，Serena **默认支持 40+ 编程语言**，包括：Go、Python、Java、JavaScript、TypeScript、Rust、C/C++、Ruby、Swift、Kotlin 等主流语言，以及一些相对小众的如 Haskell、Erlang、Clojure、Solidity 等。

如果使用 JetBrains 插件版，则天然支持 JetBrains 全家桶覆盖的所有语言和框架。

## 实际效果

根据官方文档的介绍，Serena 的设计哲学是 **agent-first tool design**——不是简单地把 IDE 功能包装一下，而是从 AI 编程工作流的角度重新思考哪些能力是真正需要的。

这带来的实际好处是：即使在很大的代码库里，AI Agent 也能快速定位到正确的上下文，准确理解代码结构，然后做正确的修改。相比暴力读取整个文件再让 LLM 理解，这种方式更快、更准、更省 token。

## 快速上手

Serena 可以通过命令行快速启动，也可以手动以 HTTP 模式运行。

```bash
# 安装
pip install serena

# 启动 MCP Server（默认stdio模式）
serena

# 或者 HTTP 模式，供远程客户端连接
serena --http --port 8080
```

接入 Claude Code 的方式是在 `~/.claude/settings.json` 中配置 MCP 服务器地址，官方文档有详细说明。

## 和现有方案的对比

| 能力 | 传统全文搜索 | 普通 AI 编程 | Serena |
|------|------------|-------------|--------|
| 语义理解 | 无 | 依赖 prompt | 有 |
| 跨文件关系 | 无 | 弱 | 有 |
| 符号定位 | 无 | 无 | 有 |
| 重构支持 | 无 | 有限 | 有 |
| 40+ 语言 | 无 | 无 | 有 |

## 适用场景

- 已有代码库的维护和重构
- AI 编程工作流中提升代码理解准确度
- 大型 monorepo 的代码导航
- 多语言混合项目的开发辅助

## 总结

Serena 是一个很实际的开源工具，它不是又一个 AI 聊天界面，而是专注于**给 AI 编程 Agent 提供真正有用的代码理解和编辑能力**。如果你在用 Claude Code、Cursor 或其他 AI 编程工具，Serena 值得一试。

GitHub 地址：[oraios/serena](https://github.com/oraios/serena)，Star 2.3 万，持续增长中。
