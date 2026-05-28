---
title: 'browser-use 进阶实战：用 AI Agent 操控浏览器完成真实任务'
date: 2026-05-28
description: '深入探索 browser-use 进阶用法：复用 Chrome 登录状态、多场景实战案例（求职申请、电商购物、PC DIY）、Cloud API 的 stealth browser 与 CAPTCHA 解决，以及与 Cursor/Claude Code 的集成。'
tags: ["AI", "Agent", "浏览器自动化", "Python", "browser-use", "实战"]
categories: ["工具使用"]
keywords: ["browser-use", "AI Agent", "浏览器自动化", "Python", "stealth browser", "CAPTCHA", "Chrome profile"]
draft: false
readingTime: 12
toc: true
cover: /images/covers/browser-use-advanced.png
---

# browser-use 进阶实战：用 AI Agent 操控浏览器完成真实任务

在[上一篇文章](https://www.onlythinking.com/post/2026-05-09-tools-browser-use-ai-agent-website-automation/)中，我们介绍了 browser-use 的基本概念和安装方法。今天我们深入进阶，探索几个**真实场景**中必须掌握的高级技巧。

## 复用登录状态：不必每次重新登录

AI Agent 每次全新启动浏览器都要面对登录墙，这是生产级应用最大的痛点之一。browser-use 提供了两种优雅的解法。

### 方法一：复用本地 Chrome Profile

browser-use 可以直接连接你本地已登录的 Chrome 浏览器，复用所有 cookies 和会话：

```python
from browser_use import Agent, Browser, ChatGoogle

# 列出所有本地 Chrome Profile
profiles = Browser.list_chrome_profiles()
for p in profiles:
    print(p["name"], p["directory"])

# 连接到指定的 Profile
browser = Browser.from_system_chrome(profile_directory="/path/to/profile")
agent = Agent(
    llm=ChatGoogle(model="gemini-3-flash-preview"),
    task="帮我订一张明天北京到上海的高铁票",
    browser=browser
)
await agent.run()
```

这样 Agent 可以直接使用你浏览器中已保存的登录态，不需要反复认证。

### 方法二：云端 Profile 同步

如果你希望在云端浏览器环境中复用本地的认证状态，browser-use 提供了同步脚本：

```bash
curl -fsSL https://browser-use.com/profile.sh | \
  BROWSER_USE_API_KEY=your_api_key sh
```

脚本会将本地浏览器的 cookies 和认证信息同步到 Browser Use Cloud 的远程浏览器实例中，适合需要**远程执行 + 本地登录态**的场景。

## 实战案例

### 案例一：自动填写求职申请表

browser-use 官方仓库提供了一个完整的求职申请自动化示例，演示了如何用 Agent 上传简历、填写复杂表单：

```python
from browser_use import Agent, Browser, ChatOpenAI, Tools
from browser_use.tools.views import UploadFileAction

async def apply_to_job(info: dict, resume_path: str):
    tools = Tools()

    @tools.action(description="上传简历文件")
    async def upload_resume(browser_session):
        params = UploadFileAction(path=resume_path, index=0)
        return "Ready to upload resume"

    browser = Browser(cross_origin_iframes=True)
    agent = Agent(
        llm=ChatOpenAI(model="o3"),
        task=f"""填写罗切斯特地区医疗的职位申请表：
        - 姓名：{info['first_name']} {info['last_name']}
        - 邮箱：{info['email']}
        - 电话：{info['phone']}
        - 上传简历：调用 upload_resume""",
        browser=browser,
        tools=tools
    )
    await agent.run()
```

这段代码展示了两个关键能力：
- **文件上传**：通过自定义 Tool 将本地文件注入到浏览器文件输入框
- **跨域 iframe**：`cross_origin_iframes=True` 解决了现代网页中常见的嵌套 iframe 问题

### 案例二：Instacart 购物自动化

用自然语言让 Agent 完成购物清单到电商网站的自动映射和下单：

```python
agent = Agent(
    task="将以下购物清单添加到我的 Instacart 账户：牛奶、面包、鸡蛋、黄油",
    llm=ChatAnthropic(model="claude-sonnet-4-6"),
    browser=browser
)
await agent.run()
```

Agent 会自主完成：打开网站 → 搜索商品 → 加入购物车 → 结账全流程。

### 案例三：PC DIY 配置助手

这个案例来自官方示例，展示了如何让 Agent 作为智能助手帮用户筛选和配置 PC 硬件：

```python
agent = Agent(
    task="帮我查找一套性价比最高的游戏 PC 配置，预算 8000 元以内",
    llm=ChatGoogle(model="gemini-3-flash-preview"),
    browser=browser
)
await agent.run()
```

Agent 会在 Newegg、PCPartPicker 等电商网站自主搜索、对比并给出推荐方案。

## Browser Use Cloud：生产级自动化的秘密武器

本地浏览器在生产环境中有几个致命弱点：

| 问题 | Cloud 解决方案 |
|------|--------------|
| CAPATCHA 拦截 | 内置 reCAPTCHA / hCaptcha 自动识别 |
| IP 被封禁 | 住宅代理轮换（Residential Proxies） |
| 浏览器指纹被检测 | Stealth Browser 指纹模拟 |
| 并发能力不足 | 云端并行扩展，支持大规模任务 |
| 需要维护浏览器环境 | 完全托管，无需服务器 |

Cloud API 的核心优势是让 Agent 在**无头（headless）云端浏览器**中运行，具备真实用户的指纹特性和反检测能力。

### Cloud API 快速上手

```python
from browser_use import Agent, Browser, ChatBrowserUse

browser = Browser(use_cloud=True)  # 启用云端 stealth 浏览器
agent = Agent(
    task="帮我抓取某电商平台的所有商品评论",
    llm=ChatBrowserUse(),  # 使用 Browser Use 内置 LLM 接口
    browser=browser
)
await agent.run()
```

一条参数切换，瞬间获得 stealth browser + 代理轮换 + CAPTCHA 解决能力。

## 与 AI 编码工具的集成

browser-use 官方推荐将 AI 编码助手（Coding Agent）直接指向 Agents.md 文档，让 Cursor、Claude Code 等工具直接通过自然语言操控浏览器：

1. 用 VS Code / Cursor 打开 `Agents.md` 文件（browser-use 项目根目录）
2. 在 AI 助手中粘贴你的任务描述，例如"帮我填写这份表格，上传我的简历"
3. AI 助手读取 Agents.md 中的 LLM 接口规范，自动构造调用

这种集成方式让 **AI 编码助手和 browser-use 形成主从关系**——编码助手负责推理和规划，browser-use 负责执行浏览器操作，分工清晰。

## BU Bench：各模型自动化能力对比

browser-use 官方提供了 BU Bench V1 基准测试，评估不同大模型在浏览器自动化任务上的成功率。从测试结果来看，Anthropic 的 Claude 系列和 Google 的 Gemini 表现最为突出，部分任务达到了 **80%+** 的成功率。

值得注意的是，这个测试是**直接操控真实浏览器**而非模拟环境，结果更具参考价值。

## 进阶配置：init 命令

browser-use 提供了交互式初始化命令，快速生成配置模板：

```bash
uvx browser-use init --template advanced --output my_agent.py
```

可用模板：
- `default`：最小配置，快速上手
- `advanced`：完整配置选项，带详细注释
- `tools`：自定义工具扩展示例

```bash
# CLI 交互式操作演示
browser-use open https://example.com   # 打开网页
browser-use state                        # 查看可交互元素
browser-use click 5                      # 点击第5个元素
browser-use type "Hello"                 # 输入文本
browser-use screenshot page.png          # 截图
browser-use close                        # 关闭浏览器
```

这套 CLI 工具在开发和调试阶段非常有用，可以逐条验证 Agent 的每一步操作。

## 总结

browser-use 的真正价值在于将 AI Agent 的推理能力与真实浏览器环境连接起来。通过复用登录态、Cloud API 的 stealth 能力、以及与 Coding Agent 的集成，它为**端到端自动化工作流**提供了坚实基础。

如果你正在构建需要操控网站的 AI 应用，browser-use 是目前最成熟的开源方案。趁 Star 突破 95k 的大势，现在是好时机深入研究和落地。

---

**相关链接：**
- GitHub：https://github.com/browser-use/browser-use
- 官方文档：https://docs.browser-use.com
- 官方博客：https://browser-use.com/posts