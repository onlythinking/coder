---
title: "OpenAI Agents SDK：轻量级多 Agent 框架实战指南"
date: 2026-04-30
description: "OpenAI 官方推出的 Python 多 Agent 框架 openai-agents-python，主打轻量、手动协调模式，支持 Handoffs、Guardrails、 Sandbox Agents 等实用模式。相比 AutoGen 偏研究导向，该框架更贴近工程落地。"
tags: ["AI", "Agent", "Python", "OpenAI", "多智能体"]
categories: ["AI"]
keywords: ["openai-agents-python", "多智能体框架", "Agent Handoffs", "AI Agent 开发", "Python Agent", "OpenAI Agents SDK", "Sandbox Agents"]
draft: false
toc: true
cover: /images/covers/openai-agents-python.png
readingTime: 12
---

# OpenAI Agents SDK：轻量级多 Agent 框架实战指南

当多 Agent 系统的论文逐步走出实验室，工程落地成为更多开发者关心的核心问题。OpenAI 近期开源的 [openai-agents-python](https://github.com/openai/openai-agents-python)（Star 25,569）给出了一个不同于 AutoGen 的答案——**轻量、手动协调、贴近工程**。本文从核心概念、代码示例、实操步骤三个维度，完整解析这个框架的设计哲学与使用方法。

## 为什么需要另一个多 Agent 框架？

目前开源社区已有多个多 Agent 框架：微软的 AutoGen 侧重研究级实验，LangChain Agents 强调通用性，CrewAI 以角色化设计见长。这些框架各有优势，但在实际工程项目中，开发者常常面临一个共同困境：**框架太重、学习曲线陡峭、或者设计过于抽象，难以直接映射到业务逻辑**。

OpenAI Agents SDK 的设计目标截然不同：不做"大而全"的通用平台，而是提供一套**轻量、明确、可控**的多 Agent 协调机制。框架作者在 README 中明确表示，该库**Provider Agnostic**（提供商无关），除了支持 OpenAI Responses 和 Chat Completions API，还通过 any-llm 和 LiteLLM 支持 100+ 其他大模型。这种设计让它既保留了 OpenAI 的技术积累，又不被单一提供商绑定。

## 核心概念

OpenAI Agents SDK 的架构围绕以下几个核心概念展开：

### 1. Agent（智能体）

Agent 是框架的基本执行单元。每个 Agent 由以下组件构成：

- **Instructions（指令）**：定义 Agent 的角色和行为规则
- **Tools（工具）**：Agent 可以调用的函数、MCP 工具或托管工具
- **Guardrails（护栏）**：输入输出的安全校验机制
- **Handoffs（交接）**：将控制权转交给其他 Agent 的能力

```python
from agents import Agent, Runner

agent = Agent(
    name="Assistant",
    instructions="You only respond in haikus.",
)

result = await Runner.run(agent, "Tell me about recursion in programming.")
print(result.final_output)
# Function calls itself,
# Looping in smaller pieces,
# Endless by design.
```

### 2. Handoffs（交接机制）

Handoffs 是该框架最实用的特性之一。当一个 Agent 需要将任务委托给另一个专业 Agent 时，Handoffs 提供了显式的控制流。与隐式的工具调用不同，Handoffs 意味着**完整的上下文转移**——被委托的 Agent 接收完整的对话历史，并拥有独立的指令体系。

```python
from agents import Agent, Runner
from agents.sandbox import SandboxAgent, SandboxRunConfig
from agents.sandbox.sandboxes.unix_local import UnixLocalSandboxClient

# 执行层 Agent：不直接接触文件，只负责将信息整理成内部备忘录
account_manager = Agent(
    name="Account Executive Assistant",
    instructions=(
        "将沙箱审查结果转换为包含标题、主要风险和建议后续步骤的简短内部更新。"
    ),
)

# 沙箱 Agent：可以检查工作空间，完成后将结果移交给 account_manager
sandbox_reviewer = SandboxAgent(
    name="Onboarding Packet Reviewer",
    instructions=(
        "检查沙箱中的 onboard 文档，验证事实，然后将结果移交给 "
        "account executive assistant 来起草最终备忘录。不要直接回答用户。"
    ),
    handoffs=[account_manager],  # 关键：这里定义了交接目标
    capabilities=[WorkspaceShellCapability()],
)

# 起始 Agent：决定何时将任务移入沙箱处理
intake_agent = Agent(
    name="Deal Desk Intake",
    instructions=(
        "对内部请求进行分类。如果请求依赖于附件文档，立即移交给 "
        "onboarding packet reviewer。"
    ),
    handoffs=[sandbox_reviewer],
)
```

整个流程由框架自动协调，开发者只需定义好 Agent 之间的交接关系，无需手动管理状态传递。

### 3. Guardrails（护栏）

Guardrails 提供了并行于 Agent 执行的安全检查机制，可以在不打断主流程的情况下对输入输出进行校验：

```python
from pydantic import BaseModel
from agents import Agent, Runner, RunContextWrapper, GuardrailFunctionOutput, TResponseInputItem, input_guardrail

class MathHomeworkOutput(BaseModel):
    reasoning: str
    is_math_homework: bool

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="检查用户是否在让你做数学作业。",
    output_type=MathHomeworkOutput,
)

@input_guardrail
async def math_guardrail(context, agent, input_data) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, input_data, context=context.context)
    output = result.final_output_as(MathHomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=output,
        tripwire_triggered=output.is_math_homework,
    )

agent = Agent(
    name="Customer support agent",
    instructions="你是客服助手，帮助客户解答问题。",
    input_guardrails=[math_guardrail],  # 接入护栏
)
```

Guardrails 支持**动态触发**——可以根据参数内容决定是否需要人工审批（Human-in-the-loop），这在需要对敏感操作进行人工审核的生产环境中非常有用。

### 4. Sandbox Agents（沙箱 Agent）

0.14.0 版本新增的 Sandbox Agents 是该框架的一个亮点。与普通 Agent 不同，Sandbox Agent 工作在一个**隔离的计算机环境**中，可以执行文件系统操作、运行命令、跨长时间任务保持工作区状态：

```python
from agents import Runner, RunConfig
from agents.sandbox import Manifest, SandboxAgent, SandboxRunConfig
from agents.sandbox.entries import GitRepo
from agents.sandbox.sandboxes import UnixLocalSandboxClient

agent = SandboxAgent(
    name="Workspace Assistant",
    instructions="在回答问题之前先检查沙箱工作空间。",
    default_manifest=Manifest(
        entries={
            "repo": GitRepo(repo="openai/openai-agents-python", ref="main"),
        }
    ),
)

result = Runner.run_sync(
    agent,
    "检查仓库 README 并总结这个项目的用途。",
    run_config=RunConfig(sandbox=SandboxRunConfig(client=UnixLocalSandboxClient())),
)
print(result.final_output)
```

Sandbox Agent 的能力非常适合**代码审查、数据分析、文档处理**等需要实际操作文件的场景。

### 5. Sessions 与 Tracing

框架内置了会话管理和链路追踪能力：

- **Sessions**：自动管理跨 Agent 运行时的对话历史，支持多种后端存储（SQLite、Redis、OpenAI Conversations API 等）
- **Tracing**：内置追踪机制，可以查看、调试和优化 Agent 工作流

## 与 AutoGen 的核心区别

| 维度 | OpenAI Agents SDK | AutoGen |
|------|-------------------|---------|
| 设计导向 | 工程落地优先 | 研究实验优先 |
| 协调模式 | 手动显式 Handoffs | 多种自动协调策略 |
| 代码复杂度 | 轻量简洁 | 功能丰富但复杂度高 |
| Provider 支持 | OpenAI + 100+ LLMs | 多提供商 |
| 社区定位 | 官方维护，持续活跃 | 微软研究主导 |
| 学习曲线 | 低，上手快 | 中等 |

如果你的目标是**快速构建可靠的多 Agent 生产系统**，OpenAI Agents SDK 的显式协调机制能让你对 Agent 之间的控制流有更清晰的掌握；如果你需要**探索多 Agent 的各种协调策略和自动优化机制**，AutoGen 更适合作为研究平台。

## 安装与快速开始

```bash
# venv 方式
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install openai-agents

# uv 方式（更推荐）
uv init
uv add openai-agents

# 语音支持
uv add 'openai-agents[voice]'

# Redis 会话支持
uv add 'openai-agents[redis]'
```

环境要求：**Python 3.10+**，需要设置 `OPENAI_API_KEY` 环境变量。

## 实战场景：客户支持多 Agent 系统

以下示例展示如何组合使用 Handoffs 和 Guardrails 构建一个客户支持工作流：

```python
from agents import Agent, Runner

# 通用 Agent：处理非专业问题
general_agent = Agent(
    name="General Assistant",
    instructions="处理一般性问题和其他 Agent 无法解决的复杂问题。",
)

# 专业 Agent：处理不同类型的客户问题
billing_agent = Agent(
    name="Billing Specialist",
    instructions="处理账单和付款相关问题。无法解决时转给 General Assistant。",
    handoffs=[general_agent],
)

technical_agent = Agent(
    name="Technical Support",
    instructions="处理技术故障排查和配置问题。无法解决时转给 General Assistant。",
    handoffs=[general_agent],
)

# 入口 Agent：根据问题类型分发给专业 Agent
triage_agent = Agent(
    name="Support Triage",
    instructions=(
        "分析客户问题类型，将账单相关问题转给 Billing Specialist，"
        "技术问题转给 Technical Support，其他问题转给 General Assistant。"
    ),
    handoffs=[billing_agent, technical_agent, general_agent],
)

# 运行工作流
result = await Runner.run(
    triage_agent,
    "我的订阅被错误扣费了，怎么处理？",
)
```

## 总结

OpenAI Agents SDK 的核心价值在于**将多 Agent 系统的复杂度降到工程可接受的范围内**。它的 Handoffs 机制让 Agent 之间的协作变得透明可控，Sandbox Agents 解决了需要实际文件操作的场景需求，而 Guardrails 则为生产环境的安全合规提供了基础保障。

目前该框架在 GitHub 上已获得超过 25,000 Star，活跃的社区和持续的版本迭代（有 Sandbox Agents 等新特性持续加入）表明这并非一个"占位"项目。如果你正在评估 Python 多 Agent 框架，openai-agents-python 值得作为重点候选——特别是当你更关心**生产落地**而非**学术探索**时。

**官方资源**：
- GitHub：https://github.com/openai/openai-agents-python
- 文档：https://openai.github.io/openai-agents-python/
- 示例代码：https://github.com/openai/openai-agents-python/tree/main/examples

---

*你之前用过哪个多 Agent 框架？踩过哪些坑？欢迎在评论区分享。*
