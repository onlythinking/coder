---
title: "把 Claude Design 跑在本地：baoyu-design Agent Skill 拆解"
date: 2026-06-21
description: "JimLiu/baoyu-design 把 claude.ai/design 的设计引擎封装成可移植 Agent Skill,在 Cursor/Claude Code/Codex 等本地 Agent 里复刻官方设计能力。本文解析其架构、安装方式与适用场景。"
tags: ["AI", "Claude", "Agent Skill", "设计工具", "开源项目"]
categories: ["AI"]
keywords: ["baoyu-design", "Claude Design", "Agent Skill", "Claude Code", "Cursor", "UI 设计"]
draft: false
cover: /images/covers/baoyu-design-claude-design-local-skill.png
toc: true
---

## 一句话总结

[baoyu-design](https://github.com/JimLiu/baoyu-design) 把 Anthropic 官方 [claude.ai/design](https://claude.ai/design) 的设计引擎拆成 Markdown + JSX 脚手架,装进 Cursor / Claude Code / Codex 等本地 Agent,产出物直接落到 `designs/` 目录,无需访问 claude.ai。

## 为什么这个项目值得拆

claude.ai/design 上线后,设计师和 PM 圈讨论最多的两件事是:

1. **网页形态的设计工具用起来顺手,但产物归属感弱** —— 你给网页交底稿,网页吐 HTML,中间过程你既看不到也改不动。
2. **订阅/账号/网络条件** —— 部分场景(企业内网、保密项目、批量生产)网页版用不顺手。

baoyu-design 的解法是把网页版背后的"设计方法论 + 工艺标准 + 组件脚手架"打成一个**纯本地、零运行时依赖**的 Agent Skill。Skill 的载体是 Markdown + 几个 JSX/JS 组件,没有构建步骤,没有独立运行时。

仓库 5 天前创建,目前 1.6K stars(实测 GitHub API 数据),pushed 2 天前,作者 JimLiu,描述里直接写了 "Best with Opus 4.8",推荐使用 Opus 4.8 模型。

## 它能做什么

按 README 的清单,核心能力分四类:

| 能力域 | 内置 Skill |
|---|---|
| 核心设计 | Hi‑fi 设计 · 交互原型 · 线框图 · 前端美学方向 |
| 演示与移动端 | Make a deck · Speaker notes · Mobile prototype · 动画视频 · 音效 |
| 设计系统 | Create / Use / Preview Design System · Design Components (`.dc.html`) · Make tweakable |
| 导入与导出 | Figma `.fig` 离线解码 · GitHub 仓库 · 既有 HTML/CSS → 独立 HTML · PDF · PPTX(可编辑/截图) · MP4 · 推送到 Figma/Canva |

底层逻辑和官方 claude.ai/design 一致 —— 先问澄清问题 → 收齐设计上下文 → 产出 HTML → 在 `localhost` 预览并验证。

## 安装方式

README 给了两条路:

**推荐路径:** 用 Vercel Labs 的 `skills` CLI 安装:

```bash
# 装到当前项目,自动识别 Agent 类型
npx skills add JimLiu/baoyu-design

# 或全局安装,所有项目生效
npx skills add JimLiu/baoyu-design -g

# 显式指定 Agent
npx skills add JimLiu/baoyu-design --agent claude-code
npx skills add JimLiu/baoyu-design --agent cursor
npx skills add JimLiu/baoyu-design --agent codex

# 先看看仓库里有什么
npx skills add JimLiu/baoyu-design --list
```

默认安装路径:Claude Code 装到 `.claude/skills/`,Cursor/Codex 类装到 `.agents/skills/`,加 `-g` 装到用户级目录。

**轻量路径:** 不装任何东西,直接把 URL 丢给 Agent 让它自己拉:

> Read https://github.com/JimLiu/baoyu-design and follow its `skills/baoyu-design/SKILL.md` to design a settings screen for a meditation app.

Agent 会自己 clone 或 fetch 仓库,加载 SKILL.md 后开工。适合一次性场景。

## 项目结构

```
skills/baoyu-design/
├── SKILL.md              # 入口文件,串起整个流程
├── system-prompt.md      # 设计方法论与工艺标准(真理之源)
├── references/
│   ├── claude.md         # Claude Code 的工具映射
│   ├── cursor.md         # Cursor 的工具映射
│   └── codex.md          # Codex Agent 的工具映射
├── built-in-skills/      # 专门化 prompt(deck / mobile / import / export…)
└── starter-components/   # 设备框、deck 舞台、canvas、动画引擎等
```

`SKILL.md` 负责编排流程,`system-prompt.md` 是不随 Agent 变化的"工艺规则真理之源",`references/*` 解决"同一个 Skill 在不同 Agent 里工具名不同"的问题(Cursor 的 Browser、Claude Code 的 Preview、Codex 的 Browser 各自怎么截图、怎么提问)。

`starter-components/` 是给 Agent 省去重复劳动的预制组件:iOS / Android / macOS / 浏览器框架、画布、deck 舞台、动画时间线引擎、Tweaks 面板、可填图槽位。

## 跑起来长什么样

装好 Skill 后,自然语言触发:

> Design 3 hi-fi variations of a settings screen for a meditation app.

Claude Code 里也可以显式 `/baoyu-design`,Codex 里用 `$baoyu-design`。Agent 会问几个澄清问题(保存位置、用哪个设计系统),然后在 `designs/<项目名>/` 下产出 HTML,在 `localhost` 上开预览。

**预览服务器**(多文件原型 `file://` 加载不全,需要 HTTP):

```bash
python3 -m http.server 4311 --directory designs
# 浏览器打开 http://localhost:4311/<project>/<file>.html
```

预览起来后,关键的工作流优势是**第二阶段改稿可以指着说**:Cursor Browser / Claude Preview / Codex Browser 这些 Agent 自带的能力,可以在 live preview 上点元素、说"按钮再大点 / 间距再松点",Agent 直接改底层 source —— 比网页版"重打一遍 prompt"快。

## 设计系统不是装饰

很多人会把 Skill 类的工具当成一次性 demo 生成器,baoyu-design 在 README 里花了一整段讲 **Design System 是 binding visual contract**,不是松散建议:

- 每个项目下放一个 `_d_meta.json`,记录绑定了哪些设计系统、谁是主系统
- 主系统拥有整体外观,token 冲突时它赢
- 副系统只贡献特定组件
- 项目文件夹 `_ds/<slug>/` 存**自包含版本固定**的副本,不联网
- 可以从 Figma `.fig` 离线解码导入

这条工作流解决了一个常被忽略的问题:**换一个 Agent、换一台机器、几个月后再打开,设计风格不会漂**。

## 适用场景与边界

**适合用 baoyu-design 的场景:**

- 你已经在用 Cursor / Claude Code / Codex 等本地 Agent 做开发,想让设计输出**和代码同处一个 git 仓库**
- 需要在多个设计变体间快速迭代(hi-fi × 3 同屏对比)
- 项目对**隐私/合规**有要求(本地执行、产物本地、零上传)
- 已经在用某个 Design System(Fluent 2、Material、Ant Design 等),希望严格遵守

**不太适合的场景:**

- 一次性营销页、临时活动页 —— 上 claude.ai/design 更省事
- 复杂后端应用的功能设计 —— Skill 的优化目标是视觉/原型,不是状态机/数据流
- 模型不是 Opus 4.8 的话输出质量会打折扣 —— README 自己也承认这点("Best with Opus 4.8")

## 和"自己写 Skill"的对比

如果你已经在用 Claude Code / Cursor,完全可能想"我自己攒一个设计 Skill"。区别在哪:

- **方法论沉淀**:`system-prompt.md` 里是一整套打磨过的工艺标准,包括色调、间距、字体阶梯、组件规约 —— 自己攒通常只到"能跑"
- **跨 Agent 适配**:`references/` 三个文件解决了同一套工艺规则在 Claude Code / Cursor / Codex 三种环境下的工具映射差异,自己写通常只适配一个
- **组件库**:device frames、deck stage、tweaks panel、animation engine 这些 starter components 不是几十行能写完的

如果你只是想"在 Cursor 里让 Claude 出个 mockup",baoyu-design 显然过头了。如果你已经在 Agent 工作流里做产品设计、并且受够了网页版的归属感和网络依赖,这是一个值得一试的方案。

---

**链接:**

- 仓库:https://github.com/JimLiu/baoyu-design
- 设计原站:https://claude.ai/design
- 安装 CLI:https://github.com/vercel-labs/skills

> 数据说明:星标数为文章撰写时 GitHub API 实时查询结果,后续会随仓库更新变化。