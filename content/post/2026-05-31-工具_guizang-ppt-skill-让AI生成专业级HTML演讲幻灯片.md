---
title: "案例拆解 | guizang-ppt-skill: 让 AI Agent 生成专业级 HTML 演讲幻灯片"
date: 2026-05-31
description: "一个将 AI Agent 与 HTML PPT 生成深度结合的 Skill，支持电子杂志风和瑞士国际主义双视觉系统，适合不想被 PowerPoint 束缚的开发者。"
categories: ["工具", "AI"]
tags: ["PPT", "AI工具", "Claude Code", "HTML", "演示"]
keywords: ["PPT工具", "AI Agent", "Claude Code Skill", "HTML幻灯片", "瑞士设计"]
draft: false
---

## 痛点：为什么 AI 生成 PPT 总差一口气

用 AI 生成 PPT 已经不是什么新鲜事了。大部分工作流是：写一段 prompt → AI 生成一套 Markdown → 渲染成幻灯片。但出来的结果总差一口气——要么排版粗糙、要么字体单调、要么动画卡顿，更别说生成配图和封面了。

根本问题在于：**传统 PPT 工具（PowerPoint/Keynote）是给人类设计师用的，AI 很难精准干预细节**。但如果换一种思路——用 HTML 作为载体，让 AI 直接操控排版引擎——情况就不一样了。

今天要拆解的 **guizang-ppt-skill**，就是这个思路的最佳实践。

## 核心功能：双视觉系统

这个 Skill 内置了两套视觉系统，分别对应不同的表达场景：

### Style A：电子杂志 × 电子墨水

灵感来自 Monocle 杂志的排版美学，适合**叙事型演讲**。特点：

- 10 种布局：封面、章节、数据大字报、图文、图片网格、Pipeline、对比等
- 5 套电子墨水主题色
- 保留叙事感，适合个人风格表达

### Style B：瑞士国际主义

这是重点。瑞士国际主义风格（Swiss International Style）是 20 世纪平面设计史上影响力最大的流派之一，核心理念是**网格至上、极简化、功能性**。

guizang-ppt-skill 把这套体系搬进了 HTML：

- **22 个具名版式**：S01 Cover、S02 Statement、S03 KPI Tower、S04 Loop Diagram、S05 Duo Compare……每个版式都是固定的，不能临时发明
- **4 套锚点色**：克莱因蓝 IKB、柠檬黄、柠檬绿、安全橙
- **16 列网格**：直角色块、1px 发丝线、无阴影、无渐变、无圆角
- **版式校验器**：可运行脚本检查居中标题、实验版式、SVG 内写字、图片脱离槽位等常见错误

### 一个技能，覆盖多种输出

| 输出类型 | 说明 |
|----------|------|
| 横向翻页 PPT | 键盘 ← → / 滚轮 / 触屏滑动 / 底部圆点 / ESC 索引 |
| PPT 配图 | 用 GPT-Image 2.0 / GPT-M 2.0 生成纪实照片、信息图、流程图 |
| 多平台封面 | 公众号 21:9、1:1 分享卡、小红书 3:4、视频号横版 |
| 截图再设计 | 把原始截图适配到模板比例 |

## 为什么是 HTML PPT

这是理解这个工具的关键。选 HTML 而不是 PowerPoint，有五个原因：

1. **AI 可精准操控**：HTML/CSS 是纯文本，AI 能直接读、改、验证，不需要通过 COM 接口间接操作
2. **表现力更高**：精细排版、空间定位、动画、交互、响应式封面，Markdown 做不到的 HTML 可以
3. **交付更轻**：单文件 HTML 直接发、演示、截图，不需要安装任何软件
4. **质量控制更容易**：瑞士风可以用脚本校验版式对齐，PowerPoint 做不到
5. **视觉内容链路统一**：同一套主题规则覆盖 PPT、配图、封面、截图再设计四个场景

## 快速上手

安装只需要一行命令：

```bash
npx skills add https://github.com/op7418/guizang-ppt-skill --skill guizang-ppt-skill
```

或者把这段话发给 Claude Code / Codex：

> 帮我安装 guizang-ppt-skill。请把 https://github.com/op7418/guizang-ppt-skill 克隆到 ~/.claude/skills/guizang-ppt-skill，安装完成后检查 SKILL.md、assets/、references/ 是否存在。

装好后直接说：

```
帮我基于这篇文章做一份瑞士风 PPT，控制在 7 页左右，需要 2-3 张配图。
```

Agent 会自动执行完整工作流：选择风格 → 需求澄清 → 拷贝模板 → 填充内容 → 可选配图 → 自检 → 预览 → 迭代。

## 适合与不适合的场景

**适合**：线下分享、行业内部讲话、私享会、AI 产品发布、demo day、带强烈个人风格的演讲。

**不适合**：大段表格数据（信息密度不够）、培训课件（需要多人协作编辑，静态 HTML 做不到）。

## 平台支持

| 平台 | 状态 |
|------|------|
| Claude Code | 原生支持 |
| Codex | 原生支持 |
| Cursor / 其他本地 Agent | 可用 |
| 普通 Chatbot | 不推荐（缺文件系统） |

## 小结

guizang-ppt-skill 解决的核心问题是：**让 AI 生成的 PPT 不再是"凑合能看"，而是"拿得出手"**。通过 HTML 载体 + 双视觉系统 + 版式校验，它把 AI 生成演示文稿的质量天花板提高了一大截。

如果你经常需要做技术分享、产品演示，或者在 AI Agent 环境中需要生成可交付的幻灯片，这个 Skill 值得一试。GitHub 上已有 13.5k Stars（还在增长），说明社区对这个方向的认可度相当高。

---

> 项目地址：https://github.com/op7418/guizang-ppt-skill  
> 由 歸藏 在多场"一人公司"线下分享中沉淀，开源，部分由真格 Token Grant 资助。