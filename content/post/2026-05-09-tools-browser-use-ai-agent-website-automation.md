---
title: "browser-use: 让AI Agent真正「操控」任意网站的开源框架"
date: 2026-05-09
description: "browser-use 是一个开源的 AI Agent 网页自动化框架，支持任意网站的表单填写、点击交互、数据抓取等操作，让 AI 真正操控浏览器而非仅能分析页面。"
tags: ["AI", "Agent", "浏览器自动化", "Python", "开源"]
categories: ["工具使用"]
keywords: ["browser-use", "AI Agent", "网页自动化", "Python", "浏览器控制"]
draft: false
---

# browser-use: 让AI Agent真正「操控」任意网站的开源框架

## 简介

[browser-use](https://github.com/browser-use/browser-use) 是一款开源的 AI Agent 网页自动化框架，GitHub 星标数已突破 **93k**，成为当前最热门的浏览器 AI 操控工具之一。

它让大语言模型（LLM）能够真正「操作」浏览器——填写表单、点击按钮、滚动页面、截图等，而不仅仅是读取页面内容。

## 快速开始

### 安装

```bash
uv init
uv add browser-use
uv sync
```

> 要求 Python >= 3.11

### 基本使用

```python
from browser_use import Agent, Browser
from browser_use import ChatBrowserUse  # 或 ChatGoogle, ChatAnthropic
import asyncio

async def main():
    browser = Browser()
    agent = Agent(
        task="Find the number of stars of the browser-use repo",
        llm=ChatBrowserUse(),
        browser=browser,
    )
    await agent.run()

asyncio.run(main())
```

就这么简单——只需描述任务，AI Agent 就会自动操控浏览器完成。

## 多 LLM 支持

browser-use 支持多种 LLM 后端，灵活切换：

| 提供商 | 模型 | 配置方式 |
|--------|------|----------|
| **BrowserUse Cloud** | 官方优化版 | `browser-use` 平台账号 |
| **Google Gemini** | Gemini 系列 | `langchain-google-genai` |
| **Anthropic Claude** | Claude 系列 | `langchain-anthropic` |
| **OpenAI** | GPT-4o 等 | `langchain-openai` |
| **本地模型** | 支持 Ollama | `langchain-ollama` |

## CLI 工具

browser-use 提供了便捷的命令行工具：

```bash
# 打开指定 URL
browser-use open https://example.com

# 查看页面当前状态
browser-use state

# 点击页面元素
browser-use click "登录按钮"

# 输入文本
browser-use type "用户名输入框" "my_username"

# 截图
browser-use screenshot
```

## Claude Code 技能

browser-use 还提供了 Claude Code 集成技能，可以直接在 Claude Code 中调用浏览器自动化能力，实现更自然的人机协作工作流。

## 基准测试

官方在 **100 个真实浏览器任务** 上进行了基准测试，涵盖：
- 表单填写
- 数据搜索
- 内容抓取
- 购物操作
- 求职申请

测试结果显示，browser-use 在复杂多步骤网页任务中的成功率处于领先水平。

## 云端版本

如果不想配置本地环境，browser-use 还提供 **云端托管版本**，无需安装配置，直接在浏览器中体验 AI 操控网页的便捷。

## 应用场景

browser-use 的典型使用场景包括：

- **表单自动填写**： RPA 流程自动化
- **网页数据抓取**： 比传统爬虫更智能
- **在线购物**： 自动下单、比价
- **求职申请**： 自动填写 job board 申请表单
- **测试自动化**： 端到端 UI 测试
- **内容聚合**： 多站点的内容整合采集

## 总结

browser-use 将 AI Agent 与浏览器自动化完美结合，让开发者可以用自然语言指令操控任意网页。随着 93k+ 星标的社区认可，它已成为网页自动化领域最具潜力的开源方案之一。

如果你厌倦了繁琐的 Selenium/Playwright 脚本，想要用更直观的方式让 AI 替你操作网页，browser-use 值得一试。

---

**项目地址**: https://github.com/browser-use/browser-use
