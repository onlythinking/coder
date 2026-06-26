---
title: "OpenKnowledge"
date: 2026-06-26
author: "编程码农"
cover: /images/covers/2026-06-26-AI-openknowledge-ai-native-markdown-editor.svg
tags: ["AI", "知识管理", "Claude Code", "开源"]
categories: ["AI"]
keywords: ["OpenKnowledge", "LLM Wiki", "AI-native 编辑器"]
draft: false
---

上周 HN 上一条 Show HN 静悄悄冲到 195 分——OpenKnowledge，一个把自己定位为「AI-native markdown editor and LLM Wiki」的项目。它没有去和 Obsidian 比插件数量，也没有在 Notion 的协作赛道上抢位置。它做的事情更激进：把 Claude、Codex、Cursor 这些 Agent 当作 Markdown 文件的一等写入者，让本地仓库变成多个 LLM 都能挂载的 Wiki。

23 天，329 stars，195 HN 分。这种「不靠功能堆叠、靠范式迁移」的开源开局，在 2026 年的 AI 工具赛道已经相当少见了。

## 一、项目定位

打开 README，第一行就是「beautiful, local-first markdown editor and LLM wiki with integrations for Claude, Codex, and other harnesses」。后半句才是重点——它对位的不是 Typora，也不是 Bear，而是「Agent 协作时的共享记忆层」。

从 GitHub 仓库的 topics 可以看出作者的真实意图：`2nd-brain`、`agent-skills`、`llm-wiki`、`second-brain`、`agent-second-brain`。传统 PKM 工具的核心抽象是「文件 / 块 / 标签」，而 OpenKnowledge 的核心抽象是「Wiki 页 / 知识节点 / Agent skills」。

换句话说，它的首要用户不是「正在写文章的人」，而是「正在被 Agent 读、写、改的知识库」。

## 二、关键能力拆解

### 2.1 WYSIWYG + 协作式 AI 改写

README 里强调的「Full WYSIWYG, so that editing markdown files feels like editing a Google Doc or Notion page」是入口体验。但紧接着那句才是关键能力：「Collaborative AI-editing with Claude, Codex, and Cursor desktop apps. Can be used with any harness/agent via MCP/CLI」。

技术上的实现路径是：本地启动一个 Web 编辑器，在同一个文件上同时跑人类的光标和 Agent 的光标。Agent 不再是「吐一整段 diff 让你手动合并」的旁观者，而是一个可以实时改写同一个段落、然后人类接着改下一句的协作写作者。

这套机制的本质，是把「提示词 → 输出」的串行流程，重构成了「共享编辑会话 → 并行修改 → diff 收敛」的并行流程。

### 2.2 MCP + Skills + Agentic Search

第二个亮点是 out-of-the-box 的 MCP、skills、agentic search。具体而言：

- MCP server：本地起一个 MCP server，让任何支持 MCP 的 Agent 都能把当前 Wiki 当作挂载点；
- Skills：项目里直接内置了一组 agent-skills，Agent 调用时不需要重新理解项目结构；
- Agentic search：Wiki 内部的链接结构是 Agent 友好的，Agent 可以沿引用关系自动展开相关章节，而不是像传统搜索那样靠关键词匹配。

这一套组合拳的工程意义在于：它把「让 Agent 理解你的知识库」从「自己写 RAG、自己写检索 prompt」降级成了一条命令。

### 2.3 No-code Team Sharing + Git 同步

第三个常被忽略的能力是「No-code Team Sharing and Auto-sync powered by git/GitHub under the hood」。

它的协作链路是：本地 Markdown 文件 → Git 仓库 → GitHub 同步给队友。看似朴素，实际上绕开了 Notion /飞书文档最大的痛点——你的知识库就是你的代码仓库，可以走 PR、可以走 Code Review、可以走 CI 校验。

这意味着 OpenKnowledge 的协作单位不是「文档」而是「commit」。一篇 Wiki 的修改记录、一次 Agent 自动改写的来源、一个人类最终接受 diff 的决定，全部沉淀在 git log 里。对 AI 时代的内容资产来说，这种可追溯性是 Notion 给不了的。

## 三、安装与上手

安装路径分两种：

```bash
# macOS：直接下载 DMG
# Linux / Windows / Intel Mac：CLI 起 Web app（需要 Node.js 24+）
npm install -g @inkeep/open-knowledge
cd your-project
ok init          # 初始化项目 + 接入 Claude Code、Cursor、Codex
ok start --open  # 起本地服务并打开浏览器
```

ok init 做的事情相当于：扫描当前目录 → 生成配置 → 自动在 Claude Code / Cursor / Codex 里挂载对应的 MCP server 和 skill。整个过程不需要手动改 JSON。

## 四、和 Obsidian / Notion 的本质差异

把这三件事摆在一起看，差异会更清楚：

- Obsidian 的核心抽象是「文件 + 链接」；
- Notion 的核心抽象是「block + 数据库」；
- OpenKnowledge 的核心抽象是「Wiki 节点 + Agent session」。

这种抽象层级的迁移，本质上对应了内容生产主体的迁移——当 Agent 才是知识库的主要写作者时，「文件」这个粒度就太粗了，「Wiki 节点 + 每次 Agent 改写都是一个 commit」才合适。

## 五、对工作流的影响

如果你日常在用 Claude Code + Obsidian 这套组合，OpenKnowledge 实际上补上了中间缺失的一环：让 Agent 的写入结果直接沉淀到本地知识库，而不是停留在聊天记录里。

一个典型的工作流可以是：

1. 在 OpenKnowledge 里写一篇文章的初稿；
2. 触发 Claude Code 改写某一节（直接调 CLI 或者走 MCP）；
3. Agent 改完的 diff 在编辑器里实时显示，你接着改下一段；
4. 写完后 git push，团队成员的 Agent 也可以直接挂载这个仓库读最新版本。

这个流程里最关键的体验升级是：Agent 不再是「单次对话的工具」，而是一个「有持久记忆的同事」。它的「记忆」就是你的本地 Wiki，而 Wiki 又由 git 同步给所有相关 Agent。

## 六、一些值得关注的局限

23 天 329 stars 并不意味着产品形态已经稳定。几个值得观察的点：

- MCP 兼容性依赖客户端：Claude Desktop / Cursor / Codex 各自的 MCP 协议实现细节还在演进，跨客户端的行为差异可能成为早期用户的踩坑源；
- GPL-3.0 协议：商业团队接入前需要评估 copyleft 对二次分发的影响；
- 并发冲突：两个人类 + 多个 Agent 同时改同一段 Markdown 时，diff 合并的语义仍是模糊地带；
- 生态还很早期：相比 Obsidian 1000+ 社区插件，OpenKnowledge 几乎所有能力都要靠官方内置。

## 七、为什么这件事值得关注

过去两年，AI 知识管理工具的演进路径大致是「传统 PKM 工具 + AI 插件」（Notion AI、Obsidian Copilot 等）。OpenKnowledge 反过来：先想清楚 Agent 是主要写作者，再倒推编辑器应该长什么样。

这种「AI-first 范式」正从「加 AI 插件」转向「AI 为中心重构」——OpenKnowledge 把 Wiki 节点、Agent skills、MCP 接入作为一等公民，直接对位 Obsidian/Notion 的传统文件夹+块结构。HN 195 分意味着海外开发者社区已经认可这一方向。

对于已经在用 Claude Code / Cursor 这类 Agentic IDE 的团队，OpenKnowledge 可能不是「又一个笔记软件」，而是「把 Agent 真正变成团队成员的最后一公里」。

## 数据点说明

文中数据点（329 stars、HN 195 分、23 天、Node.js 24+）均来自 GitHub API 与 HN 实时查询，发布日 2026-06-26。开源协议以仓库 LICENSE 文件为准。

欢迎在评论区聊聊你日常用 Claude Code / Cursor 协作时，怎么处理 Agent 的「持久记忆」问题。点击关注「编程码农」，不错过下一期 AI 工具实战。
