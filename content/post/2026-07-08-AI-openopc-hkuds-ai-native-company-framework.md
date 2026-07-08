---
title: "OpenOPC：港大开源「AI 原生公司」框架,把 Agent 编排成组织"
date: 2026-07-08
description: "OpenOPC 把 AI 任务封装成「公司」:Self-Built 招人、Self-Run 跑工作流、Self-Grown 沉淀记忆,⭐581+"
tags: ["AI", "Agent", "Multi-Agent", "OpenOPC", "HKUDS", "Python"]
categories: ["AI"]
keywords: ["OpenOPC", "AI Agent 框架", "多智能体协作", "HKUDS", "AI 原生公司"]
draft: false
toc: true
readingTime: 4
cover: /images/covers/openopc-hkuds-ai-native-company.svg
---

港大数据智能实验室（HKUDS）最近一周在 GitHub 上线了一个新项目 **OpenOPC**（Open Open Personal Company），定位相当直接——「Build Your Personal AI-Native Company」。截至今天,仓库已经拿到 ⭐581、Forks 79,项目自描述是「Self-Built、Self-Run、Self-Grown」,把 AI 协作的抽象层级从「多 Agent 对话」直接抬到了「组织运营」。

如果你之前看过 Microsoft AutoGen、OpenAI Agents SDK、AgentScope 这类多 Agent 框架,OpenOPC 的角度明显不同:它不再把 Agent 当成可以互相发消息的协作者,而是当成一家公司里的「员工」,任务来了先建组织、再排流程、最后还要做组织复盘。本文把这个项目拆开讲清楚。

---

## 一、把 Agent 当成「公司」来设计

OpenOPC 的命名就藏着它的世界观:**OPC = Open Personal Company**。整个框架围绕「公司」这个比喻组织了三层机制:

- **🏗️ Self-Built（自建）**:给定一个目标,Recruiter Agent 先草拟组织架构,确定需要哪些角色、汇报关系是什么,然后从「人才池」里挑人——优先复用已有员工（积累过项目经验的）,需要新角色时再 Onboard 新员工。
- **⚙️ Self-Run（自跑）**:公司建好就开始接活。核心是 Work Item 状态机:每条任务有自己的 Kanban 列、负责人、是否可执行的判断。Manager Agent 负责拆解、分配、Review,跨五种模式:execute / delegate / review / integrate / rework。任务之间是 DAG,能并行的并行,有依赖的等前置完成。
- **🌱 Self-Grown（自长）**:每跑完一轮,系统把执行轨迹蒸馏成「经验」,落到每个员工的私有经验档案里;高频经验被提炼成共享 Playbook,新人入职直接继承——这是「组织记忆」概念的工程化实现。

这套设计的潜台词是:真正难的不是让 Agent 完成单个任务,而是**让一群 Agent 协作得能像一支团队**——能有人挂掉、有人顶上来、能从错误里学到东西。

---

## 二、9 大行业场景,不只是写代码

仓库 README 里列了 OpenOPC 覆盖的 9 个垂直方向,从 AI 研究到电商运营,都有现成的「Company Profile」可以套用:

| 方向 | 典型工作项 |
|------|----------|
| 🤖 AI Tech & Research | 模型评测、Agent 开发、LLM 应用 |
| 💻 Software Development | Android App、SaaS MVP、小程序、游戏 |
| 📈 Financial Investment | 投资备忘、市场图谱、尽调、IC 决策包 |
| 🚀 Sales Growth | 外销、Deal Strategy、提案、渠道拓展 |
| 🎬 Content & Media | 视频制作、脚本、分镜、多平台剪辑 |
| 🤝 Industry Assistants | 客服 Copilot、房产、法律、HR |
| 🧾 Accounting & Finance | 记账、税务、预算、风险审查 |
| 🛍️ Brand & E-commerce | 品牌规划、选品、店铺运营、用户增长 |
| 🎓 Education & Training | 课程设计、知识库、学员管理 |

相比之前写过的 [AutoGen](/post/2026-04-27-AI-microsoft-autogen-agentic-ai-framework/) 和 [OpenAI Agents](/post/2026-04-30-AI-openai-agents-python-multi-agent-framework/) 主打「开发者写代码时让多个 LLM 协作」,OpenOPC 把视野扩到了「非程序员也能跑一整套业务」。仓库里放了三个 Demo 视频:视频制作、VC 投研包、游戏原型——都是端到端跑完的真实输出,不是示意。

---

## 三、Quick Start:用 uv 拉起一个公司

OpenOPC 强烈推荐用 [uv](https://docs.astral.sh/uv/) 管理依赖。Python 要求 ≥3.10,Office UI 部分需要 Node.js ≥18。

```bash
# 安装 uv（macOS）
brew install uv
# 或用官方安装脚本
# curl -LsSf https://astral.sh/uv/install.sh | sh

cd /path/to/OpenOPC
uv python install 3.12
uv venv --python 3.12
source .venv/bin/activate

# 安装项目
uv pip install -e .

# 初始化本地配置（memory、skills、projects、workspace）
uv run opc init

# 配置 API Key（在 .opc/config/llm_config.yaml 或用 llm.api_key_env 指定的 env）
```

启起来之后有两种典型模式:

```bash
# 启动浏览器 UI（默认 http://localhost:8765）
uv run opc ui

# 交互式 CLI 跑一个 demo 项目
uv run opc chat -p demo

# Task Mode:单 Agent 模式,可指定底层执行器
uv run opc chat -p demo --mode task --agent codex "重构这个模块并跑测试"

# Company Mode:用内置的 Corporate 架构跑完整流程
uv run opc chat -p demo --mode company --company-profile corporate "规划、实现、Review 并产出文档"
```

Task Mode 支持的执行器包括 OpenOPC Native、Codex、Claude Code、Cursor、OpenCode——也就是说不只是 OpenOPC 自己的模型,可以直接接你已经习惯的编程 Agent。这个设计明显是想降低迁移成本。

---

## 四、和传统多 Agent 框架的核心差异

把 OpenOPC 放到 [AgentScope](/post/2026-04-13-AI-agentscope-java-agent-oriented-programming-for-llm-applications/) 那一类「对话/消息总线」框架里比较,差异主要在三处:

1. **抽象层级不同**。多数框架把 Agent 当成「能调用工具的角色」,核心抽象是消息或对话流;OpenOPC 把 Agent 放进「组织」里,核心抽象是工作项 + 角色 + 汇报关系。这让它能更自然地表达「谁向谁汇报」「哪条任务卡在谁手里」。
2. **可观测性优先**。Self-Run 模块显式渲染了 Kanban 和 Office 视图——你能看到每个 Work Item 现在在哪个阶段、谁在负责、阻塞原因是哪条依赖没解。这点比很多框架只在日志里输出消息流友好得多。
3. **学习闭环内置**。Self-Grown 不是事后写论文的概念,而是直接在每个 Role 的私有经验档案 + 共享 Playbook 里落地。员工积累的经验可以跨项目继承。

代价是复杂度也上去了:你不再只是写几个 Agent 互相调,而是要设计组织架构、定义角色、把任务拆成 DAG。对于「写一个能调工具的 Bot」这种轻量需求,这个抽象明显过重;但对于「帮我跑完一整套业务」这种重型需求,它提供的脚手架省下来的设计成本很可观。

---

## 五、值得关注的几个细节

- **License badge 自标 MIT**(仓库根目录目前未挂 `LICENSE` 文件,实际协议以你 fork 时的最新版本为准):按徽章标注看是 MIT 友好许可,商业可用性需要自行再确认。
- **HKUDS 同一团队**:之前出过不少 Agent 框架相关的高星项目,代码风格偏学术,但 README 写得相当克制,没有营销话术。
- **外部 Agent 接入点**:Task Mode 支持 Codex / Claude Code / Cursor / OpenCode 意味着 OpenOPC 可以作为「调度层」运行在这些工具之上,而不是与之竞争。
- **Quick Start 的外部 Agent 预检**:首次运行会检查外部 Agent CLI 是否安装,用 `opc init --no-external-agent-preflight` 可以跳过。

仓库地址:[github.com/HKUDS/OpenOPC](https://github.com/HKUDS/OpenOPC)

---

## 写在最后

「AI 原生公司」这个提法本身不算新——2025 年下半年开始就陆续有团队在尝试把 Agent 组织成「公司形态」,但多数停在 PPT 阶段。OpenOPC 难得的是给出了一个完整的工程化实现:Self-Built 有 Recruiter Agent,Self-Run 有状态机和 Kanban,Self-Grown 有经验档案和 Playbook——三个环节都串得起来,不是单点概念。

接下来值得观察的是:这套组织抽象在真实业务里能不能扛住「项目复杂度上升」的场景,以及 Self-Grown 沉淀下来的组织记忆是不是真的能跨项目复用——这两个问题不解决,「AI 原生公司」就还是营销概念。

---

## 相关文章

- [Microsoft AutoGen:多 Agent 协作框架实战](/post/2026-04-27-AI-microsoft-autogen-agentic-ai-framework/)
- [OpenAI Agents Python:多 Agent 框架新选择](/post/2026-04-30-AI-openai-agents-python-multi-agent-framework/)
- [AgentScope:面向 LLM 应用的 Agent 编程框架](/post/2026-04-13-AI-agentscope-java-agent-oriented-programming-for-llm-applications/)
- [Goose:Agentic AI 开源基础设施新思路](/post/2026-05-20-AI-goose-agentic-ai-foundation/)