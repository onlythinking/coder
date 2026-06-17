---
title: "小米 MiMo Code：把 OpenCode 改造成 200 步以上任务不掉链的工程级编码 Agent"
date: 2026-06-17
description: "小米开源 MiMo Code：算力换可靠、checkpoint 跨窗口重建、Dream/Distill 跨会话演进。"
tags: ["AI", "Agent", "Claude Code", "开源", "小米"]
categories: ["AI"]
keywords: ["MiMo Code", "Xiaomi", "Coding Agent", "OpenCode", "Claude Code", "200 步任务", "长任务 Agent", "checkpoint", "Max Mode"]
draft: false
toc: true
readingTime: 9 分钟
cover: /images/covers/2026-06-17-AI-xiaomi-mimo-code-200-step-coding-agent_blog.png
wechat_cover: /images/covers/2026-06-17-AI-xiaomi-mimo-code-200-step-coding-agent_wechat.png
wechat_cover_sq: /images/covers/2026-06-17-AI-xiaomi-mimo-code-200-step-coding-agent_wechat_sq.png
---

6 月 11 日，小米 MiMo 团队把内部用了大半年的一套编码 Agent 直接开源：[XiaomiMiMo/MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code)，MIT 协议。

HN 头条挂了 554 分 / 316 条评论，VentureBeat 直接给了个标题：「Xiaomi's agentic AI coding harness MiMo Code beats Claude Code at 200 step tasks」。

一个 fork OpenCode 的项目，怎么就敢跟 Claude Code 摆在一起比？官方那篇 blog《[MiMo Code: Scaling coding agents to long-horizon tasks](https://mimo.xiaomi.com/blog/mimo-code-long-horizon)》把整套思路拆得很清楚。

读完之后我的判断是：MiMo Code 的真正贡献不是「又一个 CLI Agent」，而是把**长任务可靠性**这个问题拆成了三个可独立工程化的主题——**算力、记忆、演进**，每个主题都给出了具体实现路径和 benchmark。

## 为什么「短任务跑得通」不等于「长任务跑得稳」

传统编码 Agent 的基本结构，就是把一个语言模型丢进一个 runtime 里循环调用。模型负责推理，runtime 负责工具调用、状态管理、组装每轮输入。模型本身是无状态的——每次调用都从空白开始，所有连续性都由 runtime 临时凑出来的对话历史承担。

任务短（一般不超过 10 轮）的时候，这套结构完全够用：把整段对话历史塞进上下文，对话本身就是工作记忆。但一旦任务膨胀到几十轮、上百轮，两个问题就同时冒出来：

第一，**上下文窗口迟早会爆**。工具输出、代码片段、错误日志累积到一定量，要么压缩要么丢弃。常规做法是生成摘要替换被丢的内容——但简单压缩会让近处信息不断被强化、远处信息逐渐模糊，最后撞上「有状态、但无法按需回看」这个和 Mamba 这类循环模型一样的本质困境。

第二，**指令遵循能力随输入长度衰减**。上下文越长，模型越难从大量工具输出里捞出「我下一步应该做什么」。有用的约束和意图被工具输出稀释了。

MiMo 团队的观察是：**不同时间尺度上的瓶颈不一样**。单轮决策质量主要卡在算力上；多轮任务连续性主要卡在状态管理上；跨会话的改进主要卡在经验蒸馏机制上。这三件事，分别对应**算力、记忆、演进**三个主题。

## 主题一：算力——用 Max Mode 换可靠性

长任务最直接的杀手是「单步错误率累积」。模型每一步有 5% 的概率判断错，跑 100 步就只剩 0.6% 的端到端成功率——而且长任务里没有外部纠错信号。

MiMo Code 的第一反应是「**在单步层面追加算力**」：

> **Max Mode**：每轮并行生成 N 个候选解（默认 N=5），每个候选独立完成推理和工具调用规划，但**不真的执行**。然后用同一个模型当 judge，对比所有候选的推理过程和行动规划，选最优的去执行。

官方设了 `temperature=1`，所以五次独立采样几乎不会撞结果。多个候选恰好收敛，反而是「这个方向高置信」的信号；候选差异大时，用一个低温 judge 挑最稳健的方案，比单次采样可靠得多。

benchmark 数据：Max Mode 在 SWE-Bench Pro 上比单次采样**提升 10–20%**，代价是大约 **4–5 倍**的 token 消耗。这条曲线非常典型——算力换可靠性，且边际收益递减，但需要的时候它能压住单步错误率。

Max Mode 是试验性功能，需要在配置里手动开启。

### Max Mode 解决「做得对」，Goal 解决「做得完」

长任务还有另一种典型失败：**乐观终止**。模型在后期看到已经有一些进展，就倾向于「差不多得了」或者抛个问题问一下。在自动化执行里这尤其危险——因为没人盯着纠正。

Goal 机制的设计是：用户用自然语言定义一个**停止条件**，比如「所有测试通过且代码已提交」。每次模型想停下来时，系统自动起一个**独立的 verifier 模型**调用，把整段对话历史塞给它，问「这个条件真的满足了吗？」。不满足就把具体缺口反馈回去让 agent 继续；确认无解就标记为不可能。

关键设计点：verifier **不参与实际工作**，所以不会对 agent 已经做完的部分产生对齐偏差——它每次拿到的上下文和 agent 一样，包括真实的工具输出。官方数据：无限循环概率 < 0.5%，系统到上限自动退出；误拦截（条件已满足但 verifier 判否）比误放行更常见，多发生在环境问题导致的测试失败场景。

Max Mode 和 Goal 是 test-time compute 的两个正交方向：Max Mode 是**并行**（同一步花 N 倍算力选最优），Goal 是**串行**（同一任务花更多时间自检和继续执行）。可以同时开。

## 主题二：记忆——让「逻辑会话」无限长

单轮算力堆满后，长任务的核心问题就剩一个：**上下文终究会爆**。MiMo Code 的解法是「**让一个逻辑会话无限长，但每个物理窗口有界**」。

### Checkpoint：20% / 45% / 70% 的固定触发点

最直觉的做法是「快满了再压」。官方明确说**这是反的**：

- 模型能力在高上下文利用率下会退化（论文里叫 "lost in the middle"），越关键的时刻它压缩能力越差
- 压缩本身需要空间——writer 要读历史、做解释、出结构化输出，都在同一个窗口里。95% 利用率下根本没空间思考；30% 利用率下空间充裕

所以 checkpoint 触发在配置预算的 **20%、45%、70%** 这三个远低于上限的点。每次触发都是对前一次的增量更新，不是「一次性总结」。最后接近上限的 rebuild 也不是匆忙压缩，而是「把一路上积累的结构化记录翻成工作上下文」。

### Writer Subagent：单写者不变式

直觉上让主 agent 自己记笔记，但实测在长任务里**扛不住**——让一个正在 debug 棘手 bug 的模型同时维护结构化日志，两件事都做不好。

所以约束是：**主 agent 不维护自己的记忆**。抽取完全挪出主循环，由 runtime 触发，交给一个**独立的 writer subagent**——不共享主 agent 的注意力和 token 预算。

writer 写的是固定结构的 checkpoint 文件（11 个字段：当前意图、下一步动作、工作约束、任务树、当前工作、涉及文件、跨任务发现、错误与修复、运行时状态、设计决策、杂项），需要时更新项目级记忆。每个结构化文件**只允许一个 actor 写**——单写者是最简单的防止并发写冲突的不变式。

### 分层记忆：4 层生命周期

writer 不只写一个文件，而是一套**分层记忆系统**：

| 层级 | 文件 | 生命周期 | 特点 |
|------|------|---------|------|
| L1 | `notes.md` | 会话级 | 主 agent 唯一可写的草稿区 |
| L2 | `checkpoint.md` | 会话级 | 结构化状态快照 |
| L3 | `MEMORY.md` | 项目级 | 跨会话持久化 |
| L4 | `tasks/<id>/progress.md` | 任务级 | 单任务进度 |

关系是**上层更精炼、更持久、更小；下层更完整、更多、更慢**。writer 负责向上蒸馏，history 在下面兜底。

主 agent 对结构化文件**只读**，唯一例外是 `notes.md`——可以随时往里塞零散发现；每个 checkpoint 触发时 writer 会读它、把内容路由到合适的结构化字段、然后清空。这是主 agent **唯一的写通道**。

### Rebuild：物理窗口切换时不丢语义

runtime 执行 rebuild 时：切断当前窗口、开新窗口、用持久化文件作为种子重建上下文。主 agent 在新窗口里「醒过来」，状态已经铺在面前，继续干活。**从模型视角对话从没断过**；**从 runtime 视角开始了一段新的物理窗口**。

rebuild 注入是有顺序的、每段独立 token 上限：任务列表 → 会话 checkpoint → 最近用户消息的逐字切片（防止 writer 改写时偏离用户原意）→ 项目记忆 → 全局记忆 → notes → 可按需读取的索引 → 告诉 agent 下一步做什么的尾部提醒。

即使每段都到上限，总注入也控制在约 **65K tokens**——任何合理上下文窗口都装得下。agent 拿回状态后**直接干活**，不需要重新确认目标、不需要重读已处理过的文件。

## 主题三：演进——跨会话积累经验

前两节解决的是「单轮和单会话内做好」。但真实开发里，一个用户可能跟同一个项目交互几十次、上百次。如果每次会话结束所有经验都丢，agent 永远不能从过去的工作里积累——每次都得重新发现同样的项目约束、重复犯同样的错。

MiMo Code 维护一个**项目级记忆文件**（Markdown 格式），跨会话持久化存储：项目背景、用户明确指定的规则、架构决策及其理由、反复验证过的技术事实。

为什么选**文件而不是纯向量数据库**：一旦记忆影响 agent 后续行为，用户需要能看到系统记了什么、删掉错的、改掉过时的。文件可以用标准读写工具直接操作，不需要为每个维护动作做专用界面。全文索引在文件之上提供快速检索。

记忆会膨胀——不过期条目、重复记录、无效文件引用逐渐累积，信噪比下降。

- **Dream**：每 7 天自动触发。独立 agent 读历史会话和现有记忆文件，做合并、去重、路径有效性验证、压缩——把分散记忆收敛成紧凑的当前状态表示，更新全局记忆
- **Distill**：每 30 天自动触发。也是独立 agent 读历史会话，但重点不是知识而是**过程**——识别反复出现的工作模式，固化成可复用的 skill、CLI 命令、自定义 agent、SOP 文档

官方预测：很多当前用 prompt 形式定义的 skill，会**逐步演化成代码形式的 workflow 脚本**。

## 一个值得单独提的设计：Dynamic Workflow

在「算力」主题下，官方还提到了一个我没在主章节展开的设计——**Dynamic Workflow**。值得单独点一下，因为它是 MiMo Code 对「**模型到底应该管什么**」这个问题的明确表态。

任务规模再大一点（整个项目从一种语言迁到另一种语言、几十上百个并行工作单元需要协调），单 agent 逐轮调工具不够了。传统做法是把流程写进 `SKILL.md`，用自然语言告诉模型「先做 A，再做 B，遇到 C 就做 D」。这在简单场景下能跑，但复杂流程会**系统性失败**：上下文压缩可能吞掉步骤、模型可能跳过某些阶段、分支和重试逻辑依赖模型判断而不是代码保证、同一流程跑两次可能走不同路径。

Dynamic Workflow 的做法是：把编排逻辑从 prompt 搬进代码。

**主 agent 生成一段 JavaScript 脚本，在隔离沙箱里确定性执行**。脚本通过 `agent()` 分发子 agent、通过 `parallel()` / `pipeline()` 控制并发——`if` 不会忘分支，`for` 不会早退，barrier 不会漏子 agent。模型的判断力只用在「应该用的地方」（比如理解和生成代码），不浪费在流程控制上。

实现上**兼容 Anthropic Dynamic Workflow 的核心语义**，并做了扩展：`workflow()` 原语允许脚本调用其他脚本，编排逻辑可以组织成可复用可组合的积木；每次 `agent()` 调用的结果同步落盘，中断后能从日志恢复而不是从头跑；沙箱内可直接读写文件。

官方的判断是：**很多当前用 prompt 形式定义的 skill，会逐步演化成代码形式的 workflow 脚本**。当流程的每一步必须被执行、分支条件必须精确、重试逻辑必须可靠时，应该由代码而不是自然语言来保证。

## 行业判断：门槛已经从「写模型」降到「写运行时」

最有意思的不是技术细节，是这件事本身。

**MiMo Code 是基于 OpenCode fork 的**——核心能力（多 provider、TUI、LSP、MCP、插件）全部继承。它加的「持久化记忆、智能上下文管理、subagent 编排、goal 驱动、compose 工作流、dream/distill 自我改进」全是**runtime 层**的工程。

这意味着：今天做编码 Agent，门槛已经从「训一个 7B/72B 的代码模型」降到了「在 OpenCode 这种成熟 runtime 之上做工程」。

团队有 576 名内测开发者、474 个真实私有仓库、1213 对 A/B 测试数据。内部 A/B 数据显示：**任务执行步数在 200 以内时，MiMo Code 和 Claude Code 胜率接近 50:50；超过 200 步（含多轮用户交互），MiMo Code 胜率升到 65% 以上**。这恰好是「长任务」这个 MiMo Code 主打的场景。

VentureBeat 给的标题「beats Claude Code at 200 step tasks」严格说不算标题党——但要看清是「在 200 步以上的长任务里」，不是「在所有任务上」。

## 上手和局限

安装：

```bash
# 一行安装
curl -fsSL https://mimo.xiaomi.com/install | bash

# 或 npm
npm install -g @mimo-ai/cli

# 运行
mimo
```

首次启动会引导选择模型访问方式：MiMo Auto（限时免费、基于 MiMo-V2.5、支持 1M 上下文）、小米 MiMo 平台 OAuth 登录、从 Claude Code 导入配置、或自定义 model。

几个值得注意的设计选择：
- 工具调用格式：官方说发现「GPT-5.5 系列输出结构化 JSON 错误率较高，XML 略好」，最终选了「受限的命令行语法」——不支持管道、重定向、变量扩展，目标是借 shell 的简洁而不是给模型一个不可控执行环境。**目前 MiMo Code 还没迁移到这种格式**，可能在未来版本逐步替换
- Max Mode 是试验性功能，需要手动开启
- Goal 的 verifier 是独立模型调用，不复用主 agent 的 KV cache，token 成本是真实成本

## 我自己怎么用

如果你已经在用 Claude Code：先别急着切。MiMo Code 的优势在 200 步以上的长任务——日常短任务两者差距没拉开。但**长任务场景里**，比如「把一个项目从 Java 迁到 Kotlin」「实现一个完整功能模块」「跨多文件的 bug 排查」，值得拉过来对比一下。

最直观的复现路径：
1. 装好 mimo CLI
2. 选 MiMo Auto 通道（限时免费、零配置）
3. 找一个 200 步以上的真实任务——别用 demo，要用你正在做的
4. 同样任务用 Claude Code 跑一遍
5. 对比终态、轨迹、diff

如果你的项目记忆跨会话是痛点（每次都得让 agent 重新理解项目结构），MiMo Code 的分层记忆 + Dream/Distill 是真的能省时间。

**8.6 分的判断在写完这篇文章之后我自己的更新**：技术深度 9 / 行业价值 8.5 / 实测可信度 7.5（内部 A/B 数据不等于外部开发者复现）。

---

相关链接：
- GitHub: https://github.com/XiaomiMiMo/MiMo-Code
- 官方 blog: https://mimo.xiaomi.com/blog/mimo-code-long-horizon
- HN 讨论: https://news.ycombinator.com/item?id=48490826
- VentureBeat 报道: https://venturebeat.com/technology/xiaomis-new-open-source-agentic-ai-coding-harness-mimo-code-beats-claude-code-at-ultra-long-200-step-tasks

延伸阅读：
- [《用 Claude Code 写的代码，版权到底归谁》](/post/2026-04-29-ai-who-owns-claude-code-generated-code/) — Agent 生成代码的版权边界

---

*本文基于官方 blog、GitHub README 和 HN 讨论整理。内部 A/B 数据（576 开发者、474 仓库、1213 对比）来自 MiMo 官方披露，未独立复现。*
