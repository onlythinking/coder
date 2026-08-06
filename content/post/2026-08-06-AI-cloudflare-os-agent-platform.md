---
title: "Cloudflare OS：把 Agent 装进 Workers 沙箱，Cloudflare 想重做 SaaS"
date: 2026-08-06
description: "Cloudflare 开源Cloudflare OS,用 Durable Objects+Dynamic Workers做Agent沙箱,Gadgets/Gatekeepers重写SaaS分发."
tags: ["AI", "Agent", "Cloudflare", "Workers", "开源"]
categories: ["AI"]
keywords: ["Cloudflare OS", "Gadgets", "Gatekeepers", "Durable Objects", "Dynamic Workers", "Agent 平台"]
draft: false
toc: true
cover: /images/covers/cloudflare-os-agent-platform.svg
---

Cloudflare 在 8 月 5 日把内部用了两年的 **Cloudflare OS** 开源了，HN 上 24 小时冲到 480+ 分、200 多条讨论。这个项目不是新框架、不是新模型，而是 Cloudflare 的工程师们（包括 Workers 运行时本身的作者）搭出来的一整套 **AI 生产力环境**——文档把它类比为"公司级操作系统"，由三个东西构成：Agent 聊天 UI、沙箱化的应用开发环境、名叫 Gatekeepers 的能力安全层。本文拆开聊聊它到底在做什么、为什么这次开源值得关注，以及 HN 上吵得最凶的几个问题。

## 一句话先讲清楚它是什么

> Cloudflare OS is an "operating system" for AI productivity originally developed for use inside Cloudflare.

按 README 自己的说法，它不是 Linux/macOS 那种传统操作系统，而是 **两层含义**的"OS"：

1. **公司层面**：让全公司（工程、销售、运营……）安全地用 AI 干活的平台，安全团队能睡得着觉；
2. **AI 工作负载层面**：管理 Agent 任务执行的应用运行时，类比传统 OS 管理进程。

它的三大核心：

- **Agent Chat UI**：自带企业知识背景的对话界面
- **沙箱化应用开发**：让 Agent 帮你写"小工具"（Gadgets），并安全分享给别人
- **Gatekeepers 安全框架**：对 Agent 和 Gadget 施加护栏，非技术用户也能"放开手脚"

最重要的设计哲学是 **"不是让你用 Cloudflare OS，而是让你做 *Your Company* OS"**——开源只是起点，企业要在自己的 Cloudflare 账户上部署并定制。

## Gadgets：把 SaaS 拆成"每人一份"

Cloudflare OS 区别于"又一个带连接器的 ChatGPT"的关键，是它引入了一个新概念——**Gadget**（中文可意译为"小器具"）。

当你做一个 PPT，传统流程是：打开 SaaS 服务 → 调它的 API 渲染幻灯片。Cloudflare OS 的做法是：**系统直接给你开了一个专属的 PPT 软件实例**，跑在独立沙箱里，跟别人的 PPT 进程完全隔离。

这带来两个深远影响：

1. **无法出现 SaaS 时代的数据泄露**：传统 SaaS 应用一旦有漏洞，可能导致大规模数据外泄。Gadget 的沙箱由 OS 强制管控，**应用本身就没机会"打电话回家"**，除非你显式授权；
2. **可以随便改代码**：PPT 缺个功能？直接让 Agent 给你加上。**因为第 1 点，这事儿随便干都没事**。

README 把这称作 **"对过去 25 年云架构和 SaaS 范式的重大背离"**——理由是：AI 时代，每个用户都能自己写代码加功能，**集中化软件的意义正在消失**。

## Gatekeepers：能力安全 + 异步审批

MCP（Model Context Protocol）大家都熟了，但 MCP 服务器一旦配置，对所有对话开放所有数据——典型的"宽进宽出"。Cloudflare OS 的 Gatekeepers 是 MCP 的 **能力化升级版**：

- 用 **Cap'n Web RPC** 给外部服务一个干净的 API（套在原生 API 外面）
- 处理 OAuth 等授权
- **强制只暴露你显式授权的那个具体资源**（而不是整个 GitHub 账号）
- 记录 Gadget/Agent 的每一步动作供审计
- **副作用操作时提供人审（human-in-the-loop）**

最后一条是真正的创新。传统人审是同步的：Agent 要做某事 → 停下来等你点"同意" → 你不在它就卡死——结果大家都开"自动批准"或 `--dangerously-skip-permissions`，相当于把人审废了。

Gatekeepers 的解法是：**先模拟执行**。Agent 要做的事，Gatekeeper 在本地模拟一遍，**告诉 Agent "操作成功了"**；Agent 继续推进，可能又走了 10 步。等 Agent 收工后，用户再批量或逐条批准/驳回——**审批异步化、批量化**。

每个 Gatekeeper 实现为一个独立的 Worker。未来设想是 Gatekeeper 服务独立部署运营，但现在还跟 OS 实例绑定在一起发布。

## "OS" 这个词到底是不是噱头

HN 评论区吵得最凶的就是这个：

> Why are companies slapping "OS" in their product naming? it's stupid

> Same reason why grifters adopted web3 when Web 3.0 was already an established term.

批评者认为这是营销话术。但 README 还真给出了一张 **类比传统 OS 的对照表**：

| 传统 OS | Cloudflare OS |
|---------|---------------|
| kernel | packages/workshop-backend |
| device drivers | packages/gatekeeper-* |
| shell | packages/workshop-frontend |
| processes | gadgets |
| executables | blueprints |
| users | users |
| ACLs | shared permissions |
| ??? | agents |

README 还抛出一个更深层的论点：**传统 OS 真的管好了 AI Agent 吗？** 它认为 Agent 不能简单当作"另一种用户"对待——Agent 必须对某个真人负责、但又有自己受限的权限，能在飞行中写代码并立刻执行——**这种工作负载的天然安全模型是能力安全（capability-based），而不是访问控制列表（ACL）**。

这个论点是有说服力的：传统 OS 设计时没有 Agent 这种"半自主代码生成器"作为一等公民。Cloudflare OS 把 Agent 当作 OS 内置的"第七种实体"（kernel/drivers/shell/processes/executables/users/agents），**这其实是一种诚实的承认：传统 OS 缺这块**。

但 HN 也有反驳观点：一个网友提到 [Sandstorm](https://github.com/sandstorm-io/sandstorm)——八年前就做了类似的事情（每个用户跑自己的应用实例），只是没 AI 加持。**"AI 加持的 Sandstorm"**可能是更准确的描述。

## 技术栈：Cloudflare Workers 团队亲生的

Cloudflare OS 是 **Workers 团队自己写的**，不是另起炉灶。这意味着它重度依赖 Cloudflare 自家最前沿的运行时能力：

- 每个 workspace 是一个 **Durable Object**
- 每个 Gadget 跑在 **Dynamic Worker Facet** 里
- Gatekeepers 也作为 Facet 安装到每个 workspace
- 客户端和服务端 Gadget 通过 **Cap'n Web RPC** 通信（`postMessage()` 传给父 frame）

README 直接说：**Dynamic Workers、Facets 等多个特性就是为了支持 Cloudflare OS 才加进 Workers 运行时的**。读它的源码，等于看 Workers 团队自己怎么用 Workers。

部署方式：

```bash
pnpm run-local    # 本地跑在 wrangler + workerd 上，访问 http://localhost:8787
```

或一键部署到自己的 Cloudflare 账户（[os.cloudflare.app/deploy](https://os.cloudflare.app/deploy)）。

仓库 [cloudflare-os](https://github.com/cloudflare/cloudflare-os) 在 GitHub 上 TypeScript 占比 100%，README 自标 **早期访问**——v2 是从 v1 重写来的，2026 年 8 月发布的能力已经够用但仍粗糙。

## 三个值得关注的争议点

**1. "开源"到底有多开放？**

HN 上有人尖锐指出：

> It's open source, but it is so incredibly tied to their platform, that there is no vendor portability, which has made almost every of their product launches post-Workers kind of meh.

确实——README 明确说 workerd 是开源的，**理论上 Cloudflare OS 完全可以跑在你自己的服务器上**，但部署文档还写着 "COMING SOON"。当前只有 Cloudflare 账户一键部署这一条顺畅路径。这跟 Cloudflare 最近几个"开源"项目（EmDash CMS 等）的策略一致：**代码开源、平台绑定**。

**2. 沙箱够安全吗？**

> This can only be correct when the application can't affect anything outside the sandbox. Which would significantly restrict useful applications.

这是工程上的核心张力：Gadget 跑在沙箱里 → 安全；但沙箱越严，能做的事越少。Cloudflare 的解法是 **分层**：

- 服务端 Dynamic Worker 的外网访问默认关闭，只能通过 **Workers Bindings** 访问你显式指定的资源
- 客户端代码跑在沙箱 iframe 里，CSP 拉到最严，只能跟自己的服务端 Cap'n Web RPC 通信

这意味着 Gmail Gadget 默认看不了你邮箱，GitHub Gadget 默认不能 push 代码——除非你显式"介绍"它跟某个具体资源认识。**MCP 服务器的"宽进宽出"被改造成了"按需窄进窄出"**。

**3. "Code Mode" Agent vs Claude Code / Codex**

Cloudflare OS 用的 Agent 是 **Code Mode 架构**——写一段代码就立刻执行，本质是 [Code Mode](https://blog.cloudflare.com/code-mode/) 文章里描述的那套范式。README 声称在同样底层模型下，**Cloudflare OS Agent 比通用编程 Agent 更快、更省 token**——理由是平台和 Agent 紧耦合、工具调用更简洁。

但 HN 也有吐槽："这个跟 Claude Code / ChatGPT 桌面 app 的核心能力有啥本质区别？" **如果你的用例是 '从 Jira 取数据画个图'，用现有的 MCP 编排器就够**。Cloudflare OS 的真正差异点是 **Gadget 模型本身**——你不仅得到答案，还能得到一个**可以被你改、可以分享给他人的独立应用**。

## 总结：值不值得跟进

Cloudflare OS 在三个层面有意义：

- **产品层**：把"AI 应用开发"从 IDE + 终端 + 部署流水线，简化为"在聊天框里说一句话"。这跟 OpenAI Canvas、Anthropic Artifacts、Claude Code 是同一波探索的更激进版本——**它赌的是应用本身应该被 AI 现场生成并私有部署**。
- **架构层**：能力安全 + 异步审批是 Agent 工作流的关键基础设施。Cloudflare 把 Workers 运行时（Dynamic Workers / Facets）的能力推到了新极限，**这是 Workers 团队给自家运行时打的最大广告**。
- **战略层**：Cloudflare 在 AI 时代的定位越来越清晰——**不直接做模型，做模型和应用之间的运行时层**。从 AI Gateway 到 Agents Week 的一系列动作连贯：把 OpenAI/Anthropic 的流量和工具接到 Cloudflare 的边缘网络上。

如果你是 Agent 平台方向的开发者，**这个仓库值得 clone 下来读一遍**——它示范了 Workers 运行时的"正确使用姿势"，以及一个非传统意义上的 OS 应该长什么样。

---

参考资料：
- [Cloudflare OS 官方博客](https://blog.cloudflare.com/cloudflare-os/)
- [GitHub: cloudflare/cloudflare-os](https://github.com/cloudflare/cloudflare-os)
- [HN 讨论（482 分 / 245 评论）](https://news.ycombinator.com/item?id=49182996)
- [Phoronix: Cloudflare Announces Open-Source Cloudflare OS](https://www.phoronix.com/news/Cloudflare-OS)