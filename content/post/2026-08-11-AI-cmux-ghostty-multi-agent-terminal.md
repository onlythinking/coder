---
title: "跑 5 个 Claude Code session 之后，我换上了 cmux"
date: 2026-08-11
description: "cmux 是基于 Ghostty 的 macOS 终端，原生支持垂直标签与通知，专为并行跑多个 AI Agent 设计。"
tags: ["AI", "Claude Code", "终端", "开发工具"]
categories: ["AI"]
keywords: ["cmux", "Claude Code", "Ghostty", "多 Agent", "终端", "AI 编程", "macOS"]
draft: false
toc: true
readingTime: 6
cover: /images/covers/cmux-multi-agent-terminal.svg
---

上周有一天我同时开了 5 个 Claude Code session：一个在重构 auth 模块，一个在跑 Codex 做 code review，一个在调试 Gemini CLI 写的脚本，剩下两个分别在不同的 repo 写新功能。Ghostty 的 split pane 排成两行三列，五个 tab 标题全部是同一个项目的缩写。系统通知弹出来的时候，body 永远是那一句「Claude is waiting for your input」——我得切到对应窗口才知道具体在问什么；如果我正戴着耳机改另一段代码，往往要弹三四个通知才会意识到其中一个其实卡了一个小时没回。

这种体验不是我一个人有。Show HN 那条 [cmux - Ghostty-based terminal with vertical tabs and notifications](https://news.ycombinator.com/item?id=47079718) 一周内拿了 198 分、77 条评论，作者 lawrencechen 在帖子里讲的动机基本就是我自己这段经历的原话：tabs 一多看不清标题、通知没有上下文、试过几个 orchestrator 又都是 Electron/Tauri 写的、性能让他不舒服。所以他自己用 Swift/AppKit 写了一个原生 macOS app，调 libghostty 渲染，复用现有 Ghostty 配置的主题、字体、颜色。仓库 [manaflow-ai/cmux](https://github.com/manaflow-ai/cmux) 从 2026-01-28 创建到现在大约半年，已经攒到 25,914 stars、2,188 forks，open issues 4,174——热度是真的高，最近一个 release v0.64.22 就在 2026-08-03。

## cmux 到底是什么

一句话定位：cmux 是一个**为并行跑多个 AI 编程 Agent 而设计的原生 macOS 终端**。它不是 tmux 替代品（虽然 sidebar 长得像），也不是 orchestrator（它不下发任务），它做的是「让你同时盯一堆 Agent 的时候，知道每一个 Agent 的状态在哪、需不需要你、需要你做什么」。底层用 Swift/AppKit 写，渲染交给 libghostty（Ghostty 作者 Mitchell Hashimoto 开出来的那套），所以主题、字体、配色全部走你已有的 Ghostty config，迁过去零成本。

它的 topics 也透露了定位：`claude-code, codex, gemini, opencode, coding-agents, ghostty, macos, multiplexer, parallel-agents, terminal-multiplexer, tmux, workspace-manager`——把 AI CLI 和传统 multiplexer 放在同一组标签里。HN 评论里 [johnthedebs] 直接说 Mitchell 把 libghostty 开出来是终端用户近年的「激动人心的时刻」，因为终于有人能在不重写渲染层的前提下做 GUI 编排了。

## 四个让我决定留下来的特性

我把 README 里六块功能都过了一遍，下面这四个是真用得上的，其他算是锦上添花。

**第一是 Notification rings**。每个 pane 周围会有一圈蓝色光环，只有当 Agent 真的需要你介入时才亮；sidebar 里对应 tab 也会高亮。这是 cmux 解决「通知无上下文」问题的核心招数：我不需要点进 tab 就知道哪个 session 在等我，需要我的时候 tab 是亮的、不需要的时候是灰的。光环颜色按状态分级——需要输入是蓝色、报错是红色、思考中是淡灰——这比 macOS 原生通知那种纯文本通知密度高太多。

**第二是 Notification panel**。所有未处理的通知会聚到一个面板里，`Cmd+Shift+U` 直接跳到最新未读那条。这意味着我即使戴耳机写代码，也能用全局快捷键把当前需要我处理的 Agent 一个一个过一遍，不会漏掉哪个卡住的 session。配合 Ghostty 自己的快速搜索，回完一个直接 `Cmd+Shift+U` 跳下一个，节奏很顺。

**第三是 In-app browser**。这是 cmux 最让我意外的部分。它内置了一个浏览器，基于 vercel-labs 的 agent-browser，能被 Agent 脚本化——snapshot a11y tree、click、fill、eval JS、read console。Claude Code 在本地需要验证 UI 改动时，不再需要我手动复制粘贴 curl 命令或者截图给它，直接在 cmux 的浏览器 pane 里跑就行。对做前端 + 自动化测试组合的工程师，这一项基本能抵回整个迁移成本。

**第四是 Claude Code Teams 的一键启用**。`cmux claude-teams` 直接拉起 Claude Code 的 teammate 模式（这是 Anthropic 在 Claude Code 里提供的多 Agent 协作功能，不是 cmux 发明），每个 teammate 作为原生 split 启动，带 sidebar metadata 和 notification ring，不需要套 tmux。对我这种习惯让一组 Agent 并行干活、互相 review 的人，这是「少配一层胶水」级别的便利。

SSH 那块也值得一提：`cmux ssh user@remote` 一条命令拉起远端 workspace，`--command 'omp "investigate auth"'` 首次自动执行任务，浏览器 pane 走远端网络所以 localhost 直接可用，拖图片到远端 session 会自动 scp 上传。对要在云开发机跑 Claude Code 的人，这是个完整方案，但我日常主要在本地跑，所以这一项还没深度用上。

## 和同类工具的差异

HN 评论里 [bdbz] 提到他在做 [tabby](https://github.com/brendandebeasi/tabby)，基于 tmux、可多设备持久化 session、对 CLI 有 needs input / thinking 状态指示——路线接近但走的是「不绑 GUI、用 tmux 后端」的路子，好处是 SSH 上去 session 不掉，代价是 sidebar metadata 没 GUI 工具丰富。[blorenz] 自己用 Tauri 2 + xterm.js 撸了一个，每项目有 resumable session——性能比 Electron 好但相对原生 Swift/AppKit 差一截，他自己那句「用 Claude 帮它开发自己」也间接说明 GUI orchestrator 的复杂度。[behrlich] 在做 [wingthing.ai](https://wingthing.ai)，从 sandbox 演化到 remote access，也想 mux session——「多 Agent 状态可视化」是同一时段大家在啃的同一个问题。

cmux 的差异点有三个：**原生 Swift/AppKit 的性能**（不是 Electron 也不是 Tauri，渲染走 libghostty），**sidebar 把 git branch / PR 状态 / 监听端口 / 最新通知文本全部塞进 tab 标题**（tabs 一眼就能区分），**Notification rings 是 pane 级的视觉信号**而不只是系统通知的改写。代价也很明确：仅 macOS、不持久化 session（关掉就退出了，作者认为这是「Agent 无状态、状态在 git 里」的有意设计）、协议是 AGPL——这三条后面单独讲。

## 十分钟跑起来

我用的是 Homebrew 安装：

```bash
brew tap manaflow-ai/cmux
brew install --cask cmux
```

或者直接下 DMG：[cmux-macos.dmg](https://github.com/manaflow-ai/cmux/releases/latest/download/cmux-macos.dmg)。装完启动之后，配置文件直接复用 `~/.config/ghostty/config`——主题、字体、颜色全部继承，我连配色都没调。

启动后第一个建议先按 `Cmd+Shift+U` 跳到最新未读通知（README 明示的功能），其他 workspace / split / 浏览器面板相关的快捷键在 [官方快捷键表](https://cmux.com/docs/keyboard-shortcuts) 里全列着。终端本身的 keybinding（光标移动、滚动、复制粘贴）走你 `~/.config/ghostty/config` 里 Ghostty 的配置；cmux 自己的快捷键可以在 Settings 里改键，不用 fork。我自己用得最多的是开 sidebar 之后每个 tab 不再是光秃秃的路径，而是会显示当前 git branch、关联的 PR 编号/状态、工作目录、监听的端口、以及最后一条 Agent 输出。前两个 session 不需要看 sidebar 也能从 tab 标题分清楚，效率比之前手动 `git branch` + 切浏览器看 PR 高出一截。

## 我的判断和局限

优势说完了，讲讲我用了几天之后觉得要注意的地方。

**协议是 AGPL**。GitHub API 上 LICENSE 字段返回 NOASSERTION，仓库根目录没单独挂 LICENSE 文件——但 README 和作者在 HN 帖里都明确说是 AGPL。如果你所在公司对 copyleft 协议敏感（不少中大型互联网公司 IT 合规清单上 AGPL 是红线），先和法务/合规对一下再引入。我个人项目无所谓，公司项目我会先沟通。HN 评论里也有人拿这条问，作者没改口径。

**仅 macOS**。README 和话题标签都是 `macos`，没提 Linux/Windows。底层是 Swift/AppKit 不是跨平台框架，所以短期内看不到 Linux 版本的承诺。如果你主力在 Linux 上工作，可以先观望或者临时用 tabby 这种基于 tmux 的方案。我自己是 macOS 工作站，这个限制对我没影响。

**session 不持久化是设计选择**。关掉 cmux，正在跑的 Agent session 就退出了，不会像 tmux / tabby 那样 server 端保持。这和 cmux 的整体定位一致——Agent 的状态在 git 和 PR 评论里，不在终端的 scrollback buffer 里。但如果你习惯了 `tmux attach` 那种「下班关电脑、上班 ssh 上去接着干」的体感，cmux 是反过来的。HN 评论里 [sltr] 提了一个相关吐槽：他希望禁用 tab group 的自动重排，因为 cmux 默认把「通知最新的 tab 排到顶」，导致他用快捷键绑定的 conversation 位置一直在变。这个我在用的时候没遇到（我习惯按 `Cmd+Shift+U` 跳，不靠固定位置），但如果你依赖固定 tab 顺序，需要提前知道这个行为。

**生态刚起步**。4,174 个 open issues 不是坏事，但说明大量功能还在路上；nightly build 从 2026-02-15 之后一直在更，release 节奏稳定（最近是 v0.64.22, 2026-08-03），但生产环境用建议钉一个稳定版本而不是追 main。

## 我现在的工作流

回到开头那个「5 个 Claude Code session」的下午——我用 cmux 重做了一遍：5 个 session 全部开在 cmux 里，sidebar 显示每个 session 的 git branch、监听端口、最新一条 Agent 输出。改 auth 的 session 卡住问权限问题，蓝色光环一亮我立刻看到；Codex 跑完 code review 自动停掉，tab 变灰；Gemini 那个调试 session 还在跑，光环是淡灰。我戴着耳机改另一段代码的时候，`Cmd+Shift+U` 一按，最近一条需要我处理的通知直接跳出来，回完一个再按一次跳下一个。这种「眼睛不在屏幕上也能跟得上 Agent 节奏」的体验，是 cmux 真正解决的问题——不是让你跑得更快，是让你跑得多的时候不至于漏掉关键状态。

如果你也在每天并行跑 3 个以上 AI 编程 Agent，cmux 是目前 macOS 上最值得装的一个工具。不是因为它功能多，是因为它用对了渲染层（libghostty）、用对了 GUI 框架（Swift/AppKit）、用对了交互模型（pane 级的 Notification rings + sidebar metadata）。装一个试试，至少你会知道 tab 标题里那个项目缩写到底跑在哪个 session。

---

相关阅读：[Kimi K3 拆解：国内首个 3T 级开源模型](/post/2026-08-05-AI-kimi-k3-open-3t-moe-quantization/) 和 [Claude Opus 5 上线：比 Fable 5 更便宜这件事](/post/2026-07-27-AI-claude-opus-5-launch-cheaper-than-fable/)——前者是 3T 级 MoE + MXFP4 量化感知训练的工程向拆解，后者讲 Opus 5 在 Agentic Index 上仍排第一但价格更激进，是 cmux 这类工具正在崛起的供给侧背景。