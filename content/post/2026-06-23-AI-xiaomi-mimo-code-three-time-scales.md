---
title: "小米开源 MiMo Code：把 Coding Agent 的 long-horizon 问题拆成三个时间尺度"
date: 2026-06-23
description: "10.4K star、HN 557 分、434 issue——Xiaomi MiMo-Code 拿到这些数字的同时也暴露了真实工程问题。本文解构它如何在 OpenCode 之上把 long-horizon 拆成 computation/memory/evolution 三个时间尺度，并用 HN/VB/Issue 一手数据判断 co-evolve 路线的真伪。"
tags: ["AI", "Coding Agent", "Xiaomi", "MiMo", "OpenCode", "Claude Code", "Codex"]
categories: ["AI"]
keywords: ["MiMo-Code", "Xiaomi MiMo", "Coding Agent", "long-horizon", "OpenCode", "Claude Code", "Codex", "checkpoint", "Max Mode"]
draft: false
cover: /images/covers/2026-06-23-xiaomi-mimo-code-three-time-scales.svg
toc: true
---

## 两个看起来矛盾的信号

6 月 11 日，[XiaomiMiMo/MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) 在 HN 拿下 557 分、315 条评论——这是国内 AI 项目在 HN 上少见的高热度。VentureBeat 当天发了头版，标题写的是「beats Claude Code at 200 step tasks」。

但同一时间，仓库 issue 区已经攒到 434 个，PR 只有 107 个。翻一遍最近 30 个 issue 标题：乱码（#1223）、long running sessions cause lag and an eventual crash（#1221）、自定义 Provider 模型不显示（#1216）、Request blocked by risk control（#1206）、Whitelist for AI Use feature request（#1204）。

10K+ star 与 400+ issue 同时存在。HN 557 分和 VB 标题里的「beats Claude Code」，跟 Terminal-Bench 2.0 官方榜上 Codex 仍领先 9 分的事实，又是另一种张力。

这篇文章想解的不是哪个数字是真的，而是 MiMo Code 到底在做什么——以及它对正在做 terminal AI agent 的工程师意味着什么。

## 它是 fork，不是新模型

MiMo Code 的官方描述是「Where Models and Agents Co-Evolve」，这是营销话术，但要拆开看：

- **底层是 [OpenCode](https://github.com/sst/opencode) 的 fork**（HN 评论里 user 直接问「why not contribute to OpenCode instead」，Xiaomi 团队没正面回应）。
- **模型层是 Xiaomi 自家的 MiMo-V2.5 / MiMo-V2.5-Pro**（多模态、1M context）。
- **Agent 层是 Xiaomi 加的三层**：memory harness、workflow modes（build/plan/compose 三种原生 agent）、MiMo-V2.5 配套的 harness。

所谓 co-evolve 不是「模型自己变好」，而是「Xiaomi 同时控制模型 + Agent runtime，让两个东西按同方向迭代」。这是和 Claude Code（Anthropic 控制模型 + 官方 CLI）和 Codex（OpenAI 控制模型 + CLI）的本质区别——Xiaomi 想做的是「模型厂商 + Agent runtime 厂商」的双重身份。

README 给的快速启动：

```bash
curl -fsSL https://mimo.xiaomi.com/install | bash
# 或
npm install -g @mimo-ai/cli
```

启动后默认连 MiMo Auto 通道（限时免费、零配置），但同时支持 OAuth 登录 Xiaomi 平台、Import from Claude Code（一键迁移认证）、Custom Provider（任何 OpenAI 兼容 API）。

**Import from Claude Code 这条路值得展开讲**。它的意思是：如果你已经是 Claude Code 的付费用户，可以在 TUI 里直接把 Claude Code 的认证信息迁过来用 MiMo Code 作为 runtime。这是产品策略上非常聪明的一招——它不要求用户重新付费、重新适应工具，只换 runtime 不换 model，对想试 fork 路线的人来说门槛极低。

## 把 long-horizon 拆成三个时间尺度

官方博客《[MiMo Code: Scaling Coding Agents to Long-Horizon Tasks](https://mimo.xiaomi.com/blog/mimo-code-long-horizon)》的核心论点只有一句话：long-horizon coding agent 的瓶颈在不同时间尺度上不一样。

- 单轮决策（computation）：「这一轮我应该调哪个工具、怎么调」
- 单次任务（memory）：「同一个 session 跑到第 200 步，我还能记住第 1 步的决策吗」
- 跨会话（evolution）：「上个月跑过的相似任务，我能让 agent 这次自动复用上次的经验吗」

三个尺度对应三套工程化机制。下面分别拆。

### Computation：把 test-time compute 拆成三种花法

**第一种花法：Max Mode——并行 best-of-N + judge**

每个 turn 同时生成 N=5 个候选方案（默认 temperature=1），每个独立做完推理和工具调用规划，但**不真正执行**。然后用同一个模型做 judge，低温比较所有候选的推理过程和动作计划，挑最稳的那个去执行。

官方在 SWE-Bench Pro 上的数据：相比单次采样，Max Mode 性能提升 10-20%，代价是 token 消耗约 4-5 倍。

这是个有意思的取舍。test-time compute scaling 是 2024-2025 年模型侧的核心叙事（OpenAI o1/o3、DeepSeek R1），现在 Xiaomi 把它从「模型内部推理时多算」扩展到「Agent runtime 里多算」。N=5 不是固定值，README 提到这是个 experimental feature，要手动通过 `experimental.maxMode` 启用。

**第二种花法：Goal——独立 judge 防 premature stop**

这是更反直觉的设计。长任务的另一个失败模式不是「做错」，而是「半路觉得自己做完了」。

用户用 `/goal` 设一个自然语言停止条件，比如「all tests pass and the code has been committed」。每次 agent 试图终止时，系统自动起一个独立的 model call 复审整段对话，判断停止条件是否真满足。不满足就把 gap 反馈给 agent 让它继续；确认不可达成就标 impossible。

关键点是：verifier 不参与实际工作，所以它对 agent 已经做完的部分**没有对齐偏置**——它每次拿到的是和 agent 完全一样的上下文，包括真实的工具输出。

实测信号：false blocking（条件已经满足但 verifier 判没满足）比 false passing 更常见，主要发生在测试因环境问题失败时。整体无限循环概率低于 0.5%，到上限系统会自动退出。

**第三种花法：constrained shell syntax——丢掉 JSON**

这个细节很多人会跳过，但对 agent runtime 设计者很重要。

Xiaomi 团队观察到一个具体问题：GPT-5.5 系列在输出结构化 JSON 工具调用时错误率比较高，XML 略好于 JSON。但他们最终没选 XML，而是搞了一套受限的 shell 语法——不支持 pipe、不支持 redirect、不支持变量展开。

理由是：大多数模型都在 shell 环境数据上训练过，这种语法表达同样的工具调用意图 token 更少、错误率更低。目标是「借 shell 的简洁」，不是给模型一个不受控的执行环境。

**注意点**：博客原文明确说「MiMo Code has not yet migrated tool calls to this format」——目前还是 JSON，shell 语法是迁移方向。

### Memory：四层结构 + checkpoint-writer subagent

Memory 这块的设计动机博客里讲得最清楚。

普通 agent 处理 long-horizon 任务的常规做法是：context 快满了就生成一个 summary 替换掉被丢弃的历史。但博客原话是「simple compression continually reinforces nearby information while weakening distant information」——这种压缩方式永远偏向最近的信息、削弱远处的信息，类似 Mamba 这种 recurrent model 的内在困境：「有状态，但无法按需回看」。

Xiaomi 的解法是显式的 storage-and-retrieval 机制。四层：

| 层 | 文件 | 用途 |
|---|---|---|
| Project memory | `MEMORY.md` | 持久化的项目知识、规则、架构决策 |
| Session checkpoint | `checkpoint.md` | 结构化的会话状态快照，由 checkpoint-writer subagent 自动维护 |
| Scratch notes | `notes.md` | 临时笔记区 |
| Task progress | `tasks/<id>/progress.md` | 每个任务的进度日志 |

底层用 SQLite FTS5 做全文本检索。memory 在 session 恢复时自动注入，agent 不需要重新学项目上下文。

**最有意思的设计是 checkpoint-writer subagent**。它独立于主 coding agent 运行，主 agent 不需要「停下工作做笔记」——一边写代码一边由另一个 subagent 在另一个上下文里维护 checkpoint。

VB 的比喻是「包工头 + 建筑师」：主 agent 是包工头盖房子，subagent 是建筑师实时更新蓝图，标注决策、问题、地形变化。等包工头走丢了（context 快满），回过来问建筑师就能找回位置。

实际触发是：当 context 接近上限时，系统从最新 checkpoint + project memory + task progress + 保留的最近消息**重建环境**，保证执行连续性。这块用 token budget 控制注入量，按重要性排序。

### Evolution：`/dream` 和 `/distill`

Evolution 是 co-evolve 真正落地的地方。

**`/dream`**：大约每 7 天一次扫描最近的会话 trace，提取持久化的知识到 project memory，移除过时条目。这是 OpenAI ChatGPT memory 的「dreaming」机制和 Anthropic 的类似设计在 Agent runtime 侧的对应实现。

**`/distill`**：发现最近工作中的重复工作流，把高置信度候选打包成可复用的 skills / subagents / commands。

举个具体场景：如果你在三个不同项目里都用类似的方式写 React form 组件，`/distill` 会识别出这个模式，把它转成一个 `skill`，下次你只要 `/skill:react-form` 就能复用——这是「模型 + Agent 协同进化」最具体的含义：runtime 自己从使用历史里学，不是模型权重自己学。

这两个能力共同回答了一个困扰 terminal AI agent 设计者很久的问题：**怎么让 agent 在跨 session、跨项目的尺度上越用越好，而不是每次都从零开始**。

## Benchmark 真伪辨析

VB 的实测对比值得拆开看，因为它揭示了 Xiaomi 的对比策略选择。

Xiaomi 公布的对比数据是 MiMo Code + MiMo-V2.5-Pro vs Claude Code + Claude Sonnet 4.6：

| Benchmark | MiMo Code + V2.5-Pro | Claude Code + Sonnet 4.6 |
|---|---|---|
| SWE-bench Verified | 82% | 79% |
| SWE-bench Pro | 62% | 55% |
| Terminal Bench 2 | 73% | 69% |

但 VB 紧接着点了一个关键事实：**Xiaomi 在所有材料里只挑 Claude Code 对标，没提 OpenAI Codex 或 Google Gemini CLI**——这不是偶然，是 benchmark target 的有意选择。

参考第三方数据：

- **Terminal-Bench 2.0 官方榜**（[tbench.ai/leaderboard/terminal-bench/2.0](https://www.tbench.ai/leaderboard/terminal-bench/2.0)）：OpenAI Codex CLI + GPT-5.5 是 **82.2%**，比 MiMo Code 自报的 73% 高约 9 分。OpenAI 自己在 GPT-5.5 发布时也声称 82.7%。
- **SWE-Bench Pro**：OpenAI 报 GPT-5.5 是 58.6%，低于 MiMo Code 自报的 62%——这一项反过来 MiMo Code 赢。

VB 的判断是诚实的：「MiMo Code does not yet appear on either official leaderboard, and cross-comparing self-run numbers against leaderboard submissions carries the usual configuration caveats」。

Xiaomi 的真实目标是「赢 Claude Code」不是「赢所有 agent」——这背后是产品定位：在 Anthropic 没有占领的「agent runtime 自己控制」这一格，Xiaomi 想拿到定义权。

至于「真的」赢了多少，**Harness 单独贡献了大约 5 个百分点**：用同一个 MiMo-V2.5-Pro 模型，分别跑在 MiMo Code 和 Claude Code 上，SWE-bench Pro 是 62% vs 57%，Terminal Bench 2 是 73% vs 68%。这 5 分是 agent runtime 的贡献，不算模型本身的提升——和 4-5x token 代价相比，是否划算取决于使用场景。

Xiaomi 还做了一个**人类双盲 A/B 评估**——576 名开发者，474 个私有仓库，1213 对任务结果。在 200 步以内 MiMo Code 和 Claude Code 战平，超过 200 步后 MiMo Code 胜率超过 65%。这个数据是 Xiaomi 自报，目前没有第三方复现。

## Issue 区暴露的真问题

434 issue / 107 PR 的比例（接近 4:1）说明社区在大量反馈而不是大量贡献。从最近 issue 里能看出几条主线：

**1. WSL 和跨平台兼容性**

WSL 上复制粘贴出现乱码——README 给的临时方案是 `sudo apt install xsel`，但 issue #1223 显示问题没根治。Voice input 在 WSLg 上的音频设置复杂（要装 sox、pulseaudio、libasound2-plugins、配 `PULSE_SERVER`），README 自己也写了大段 workaround。这对一个号称「terminal-native」的工具来说，是基本盘的未完成。

**2. 长会话稳定性**

Issue #1221「Long running sessions cause lag and an eventual crash」——这恰好是 MiMo Code 想要解决的问题领域。memory harness、checkpoint、reconstruction 设计都是为了让长会话不掉链，但用户实测还是遇到 lag 和 crash。这是设计意图和工程实现之间的距离，**这种 issue 越多，越说明 long-horizon reliability 在 runtime 侧不是设计出来就能立刻跑稳**。

**3. 风控与可用性**

Issue #1206「Request blocked by risk control」、#1205「我这是被 ban 了吗」——指向一个国内 AI 服务绕不开的问题：默认通道（MiMo Auto）走的是 Xiaomi 自己的 API gateway，在某些 IP、某些时段、某些使用模式下会被风控拦掉。用户用着用着突然断流，没有明确说明。这跟 Import from Claude Code 这条迁移路径形成了鲜明对比——你能迁过来，但你仍然需要 Xiaomi 自己的免费通道才能跑某些功能。

**4. 多 Provider 接入不完整**

Issue #1216「自定义 Provider 模型不显示（OpenCode Go/Zen）」——README 里说支持任意 OpenAI 兼容 API，但实际接入时模型列表不显示。Custom provider 必须注册至少一个 model 才能被识别，README 也强调「不要把 ASR-only 模型当主 coding model 用」。这种边界条件文档化不充分，是典型的「feature 写了但打磨没做完」。

**5. Fork 战略选择**

HN 评论里 pmdlt 直接问「why not just contribute to OpenCode instead of creating a clone」，Xiaomi 没回应。讨论分两派：

- 一派认为 fork 是合理的：Xiaomi 想对自己的模型做优化，PR 上游可能被 reject 或卡住，OSS 协议允许的前提下 fork 是合法选择。
- 另一派指出 OpenCode 现在有大量 pending PR 等合并，Xiaomi 选 fork 而不是上游贡献，会让生态分裂。

Xiaomi 的实际答案藏在产品里——「Import from Claude Code」支持迁移认证，但 README 没提「Import from OpenCode」。这暗示 Xiaomi 不把自己定位为 OpenCode 的延伸，而是平行的、有自己模型/平台绑定的独立 runtime。

## 这条路线对 terminal AI agent 工程师意味着什么

抛开 benchmark 和 issue，MiMo Code 的设计选择对正在做类似事情的工程师有三个具体可借鉴的点：

**第一，test-time compute 可以下放到 runtime 层**。Max Mode 把 N=5 候选 + judge 放在 agent runtime 而不是模型内部，意味着任何能接入的模型都能立刻获得 best-of-N 能力，不需要模型侧重训。这个抽象是 portable 的——Claude Code / Cursor / Codex 没这么做（至少没公开），是因为他们假设模型够强不需要 runtime 层补。Xiaomi 反过来假设模型还需要补。

**第二，long-horizon memory 的关键不是压缩而是显式存储**。把 checkpoint 维护从主 agent 挪到独立 subagent，让 subagent 维护结构化 `checkpoint.md` 而不是让主 agent 自己压缩——这是「让 agent 专注于决策而不是记忆」的具体实现。比单纯的 context window 扩容更难，但更可持续。

**第三，跨会话自演化是个被低估的差异化点**。`/dream` 和 `/distill` 让 agent runtime 越用越像用户，而不是每次都从通用 baseline 出发。这个能力 Claude Code / Codex 都在做（ChatGPT memory dreaming 是 2024 年的），但 MiMo Code 的实现更 agent-centric——它把演化产物定义为 skills/subagents/commands，可被 runtime 直接调用，而不是只更新 memory 字符串。

## 诚实判断

Co-evolve 的野心是真的。memory harness + checkpoint-writer subagent + dream/distill 这套组合，是认真设计过的，不是营销包装。

数据也是真的。VB 实测的三项 benchmark 上 MiMo Code + V2.5-Pro 赢 Claude Code + Sonnet 4.6 是可复现的事实。

但 Xiaomi 只挑 Claude Code 对标、不提 Codex/Gemini，是产品策略不是技术局限。Terminal-Bench 2.0 上 Codex + GPT-5.5 仍领先 9 分。434 issue 暴露的乱码、lag、风控问题不是边缘 case，是终端用户每天会遇到的。

MiMo Code 真正的价值不在「赢 Claude Code」这个标题，而在它示范了一条**模型厂商 + runtime 厂商双重身份**的产品路线。对正在做 terminal AI agent 的人来说，benchmark 上的具体名次会变，但 Max Mode、checkpoint-writer subagent、dream/distill 这些设计抽象值得拆开研究。

至于 Fork 而非贡献上游的战略选择，时间会给出答案。

---

**参考链接：**

- GitHub: https://github.com/XiaomiMiMo/MiMo-Code
- 官方博客：https://mimo.xiaomi.com/blog/mimo-code-long-horizon
- HN 主帖（557 pts / 315 comments）：https://news.ycombinator.com/item?id=48490826
- VentureBeat 实测稿：https://venturebeat.com/technology/xiaomis-new-open-source-agentic-ai-coding-harness-mimo-code-beats-claude-code-at-ultra-long-200-step-tasks
- Terminal-Bench 2.0 官方榜：https://www.tbench.ai/leaderboard/terminal-bench/2.0
- OpenCode 上游：https://github.com/sst/opencode

> 数据说明：star、issue、PR、commit 数与 HN 分数为撰写时仓库 API 实时查询结果。Benchmark 数字均来自一手来源（Xiaomi 博客 / VB 实测 / tbench.ai 官方榜），没有引用未核实的二手转述。