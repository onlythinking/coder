---
title: "Cougar-CLI: 轻量级命令行AI编程Agent的架构与实践"
date: 2026-04-19
description: "Cougar-CLI是一款开源的命令行AI编程Agent，支持OpenRouter、OpenAI、Claude、智谱等多种LLM后端，通过自然语言指令自动完成代码生成、调试和重构任务。本文深入解析其任务编排架构、多Provider集成设计与本地部署实战用法。"
tags: ["AI", "Agent", "CLI", "编程工具", "LLM", "TypeScript"]
categories: ["tools"]
keywords: ["Cougar-CLI", "AI编程Agent", "命令行工具", "LLM集成", "任务编排", "OpenRouter", "Ollama本地部署", "TypeScript"]
draft: false
cover: /images/covers/cougar-cli-ai-programming-agent.png
readingTime: 3 分钟
toc: true
---

## 背景

随着大语言模型（LLM）能力的飞速提升，AI辅助编程已从代码补全进化到自主Agent时代。以Cursor、Claude Code为代表的图形化/IDE集成工具已经相当成熟，但在**轻量终端场景**（远程服务器、无头部署、SSH连接的开发环境）下，开发者仍然缺乏一款顺手的选择。

[Cougar-CLI](https://github.com/dulikaifazr/Cougar-CLI)正是填补这一空白的产品：它是一个完全基于命令行的AI编程Agent，支持TypeScript/JavaScript为主的多语言，通过自然语言指令完成代码编写、调试和重构任务。本文基于其开源实现（Apache 2.0协议），深入解析其核心架构和实战用法。

## 核心架构

Cougar-CLI的架构可以用一句话概括：**CLI终端作为交互界面，LLM作为大脑，文件系统作为手脚**。

```
┌─────────────────────────────────────┐
│           CLI Interface             │
│  (命令解析 / 流式输出 / 交互确认)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Task Orchestrator           │
│  (任务分解 / 上下文管理 / 状态机)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    LLM Integration Layer             │
│  (多Provider支持 / Prompt模板 / 工具调用) │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Tool Executor                    │
│  (文件读写 / 执行命令 / 代码搜索)    │
└─────────────────────────────────────┘
```

### 1. CLI界面层

Cougar-CLI使用Node.js构建交互式终端，支持三种工作模式：

- **交互模式**（默认）：启动后进入REPL风格的对话界面
- **单次指令模式**：`node dist/index.js "explain this function"`
- **文件批处理模式**：`node dist/index.js --files src/*.ts --task "refactor"`

流式输出（Streaming）是其亮点——LLM的响应会逐token显示在终端，类似于Claude Code的体验。

### 2. 任务编排层

核心是一个基于状态机的任务管理器：

```typescript
enum TaskState {
  IDLE = 'idle',
  PLANNING = 'planning',    // LLM分析任务
  EXECUTING = 'executing',  // 执行子步骤
  AWAITING_CONFIRM = 'awaiting_confirm',  // 等待用户确认
  DONE = 'done',
  ERROR = 'error'
}
```

每收到一条指令，Orchestrator会：
1. 将指令转化为任务描述
2. 调用LLM生成执行计划（Plan）
3. 将Plan拆解为可执行的Tool Calls
4. 按顺序执行并收集结果
5. 将结果反馈给LLM判断是否需要下一步

### 3. LLM集成层

Cougar-CLI通过统一的Provider接口支持多种LLM后端：

```typescript
interface LLMProvider {
  chat(messages: Message[], tools?: Tool[]): Promise<LLMResponse>;
  getModel(): string;
}

class OpenAIProvider implements LLMProvider { ... }
class AnthropicProvider implements LLMProvider { ... }
class OpenRouterProvider implements LLMProvider { ... }
class ZhipuProvider implements LLMProvider { ... }
class LocalProvider implements LLMProvider { ... }  // OpenAI API兼容接口（如Ollama、vLLM等）
```

支持的Provider包括：**OpenRouter**、**OpenAI**、**Anthropic Claude**、**智谱（Zhipu）**，以及任何**OpenAI API兼容**的端点（如本地部署的Ollama、vLLM）。配置文件通常位于项目根目录：

```json
{
  "provider": "openai",
  "model": "gpt-4o",
  "apiKey": "sk-..."
}
```

工具调用（Tool Use）通过JSON Schema定义，支持的核心工具包括：

| 工具 | 功能 |
|------|------|
| `read_file` | 读取指定文件内容 |
| `write_file` | 创建或覆盖文件 |
| `edit_file` | 对文件进行精确修改 |
| `run_command` | 执行Shell命令 |
| `grep_search` | 代码全文搜索 |

### 4. 工具执行层

Tool Executor负责安全地执行LLM调用的工具。其中`run_command`是最关键也是最危险的工具——它允许Agent执行任意Shell命令。Cougar-CLI对此做了两级防护：

```typescript
// 第一级：危险命令黑名单
const DANGEROUS_COMMANDS = ['rm -rf /', 'dd', ':(){:|:&};:', '> /dev/sda'];

// 第二级：执行前需要用户确认（可配置跳过）
async function executeCommand(cmd: string): Promise<string> {
  if (isDangerous(cmd)) {
    const confirmed = await promptConfirmation(cmd);
    if (!confirmed) throw new Error('Command rejected by user');
  }
  return childProcess.exec(cmd);
}
```

## 实战用法

### 安装与配置

```bash
# 从源码克隆并构建
git clone https://github.com/dulikaifazr/Cougar-CLI.git
cd Cougar-CLI
npm install
npm run build

# 配置API Key（编辑配置文件）
# 支持 OpenRouter / OpenAI / Anthropic / 智谱
```

### 基础任务

**代码解释：**

```bash
$ node dist/index.js "explain src/utils/auth.ts"

正在分析文件...
✓ 已理解 `auth.ts` 的核心逻辑：
  - JWT token的生成与验证
  - 基于bcrypt的密码哈希
  - 中间件式的权限校验链
```

**代码生成：**

```bash
$ node dist/index.js "create a REST API for user management with Express"

正在生成代码...
✓ 生成文件：
  - src/routes/users.ts (路由定义)
  - src/controllers/userController.ts (控制器)
  - src/models/User.ts (数据模型)
  - src/middleware/auth.ts (认证中间件)

? 是否需要添加单元测试？ [Y/n]
```

**代码重构：**

```bash
$ node dist/index.js --files src/*.ts --task "convert callback to async/await"

正在分析 12 个文件...
✓ 重构完成：
  - 全部转换为 async/await 模式
  - 保留了错误处理的完整性
  - 添加了类型声明
```

### 多后端配置示例

**使用 OpenRouter（聚合多个模型）：**

```json
{
  "provider": "openrouter",
  "model": "anthropic/claude-sonnet-4-20250514",
  "apiKey": "sk-or-v1-..."
}
```

**使用本地 Ollama（需启用Ollama的OpenAI兼容API）：**

```bash
# Ollama 服务端（默认端口11434）
# 确保已启动：ollama serve

# 本地配置文件：
{
  "provider": "local",
  "model": "llama3",
  "apiKey": "not-needed",
  "baseURL": "http://localhost:11434/v1"
}
```

**使用智谱 GLM：**

```json
{
  "provider": "zhipu",
  "model": "glm-4",
  "apiKey": "your-zhipu-api-key"
}
```

## 与同类工具的对比

| 特性 | Cougar-CLI | Claude Code | GitHub Copilot CLI |
|------|-----------|-------------|-------------------|
| 平台 | 跨平台 | 跨平台 | 跨平台 |
| 安装方式 | 源码构建 | npm | npm |
| 多文件重构 | ✅ | ✅ | ✅ |
| 命令执行 | ✅ | ✅ | ❌ |
| 本地模型支持 | ✅（OpenAI兼容接口） | ❌ | ❌ |
| 多Provider | ✅（5种） | ❌ | ❌ |
| 交互确认 | ✅ | ✅ | ❌ |
| 项目感知 | 基础 | 强 | 强 |
| 价格 | 自带API Key | Claude API | Copilot订阅 |

Cougar-CLI最大的差异化优势是**完全本地化**：不依赖任何云服务，数据不离开本地机器。这对于处理内部代码库隐私要求严格的企业场景尤为重要。

## 局限性与注意事项

1. **上下文窗口限制**：单次任务最大处理文件数受LLM上下文限制，大型重构任务需要分批次执行。

2. **安全风险**：`run_command`工具本质上是给Agent赋予了执行任意命令的能力，生产环境中务必开启确认模式。

3. **代码质量依赖LLM能力**：生成的代码质量直接受底层模型影响，对复杂业务逻辑仍需人工审核。

4. **TypeScript/JavaScript为主**：对Python、Rust等语言的支持不如JS生态完善。

5. **无npm包分发**：目前只能从源码构建后使用，不如Claude Code的npm安装方便。

## 总结

Cougar-CLI代表了AI编程工具的一个有趣方向——**轻量、无头、本地优先**。在Cursor和GitHub Copilot主导的市场中，它瞄准的是远程开发、服务器运维、低配置环境等细分场景。如果你经常在SSH环境下工作，或对数据隐私有严格要求，Cougar-CLI是一个值得关注的实验性选择。

## 相关资源

- [Cougar-CLI GitHub 仓库](https://github.com/dulikaifazr/Cougar-CLI)
- [OpenRouter 多模型聚合平台](https://openrouter.ai/)
- [Ollama 本地模型支持](https://ollama.com/)
- 延伸阅读：[《Qwen3-6-35B-A3B: 本地Coding Agent的新选择》](https://www.onlythinking.com/post/2026-04-17-ai-qwen3-6-35b-a3b-local-coding-agent/)

---

*首发于 [编程码农](https://www.onlythinking.com)，如需转载，请注明出处。*

## 分享与讨论

如果你觉得这篇文章有帮助，欢迎分享：

- **X/Twitter**: [Cougar-CLI: 轻量级命令行AI编程Agent](https://twitter.com/intent/tweet?text=Cougar-CLI:%20%E8%BD%BB%E9%87%8F%E7%BA%A7%E5%91%BD%E4%BB%A4%E8%A1%8CAI%E7%BC%96%E7%A8%8BAgent%E7%9A%84%E6%9E%B6%E6%9E%84%E4%B8%8E%E5%AE%9E%E8%B7%B5&url=https://www.onlythinking.com/post/2026-04-19-tools-cougar-cli-ai-programming-agent/)
- **微信**: 扫码分享到朋友圈或技术群

> 欢迎在评论区分享你使用的AI编程工具，以及对命令行Agent的看法！
