# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于 Hugo 静态网站生成器的中文技术博客项目，名为"编程码农"。博客内容涵盖前端、后端、算法、数据结构、工具使用等编程相关主题。

## 技术架构

- **静态网站生成器**: Hugo
- **主题**: even 主题 (位于 themes/even/)
- **内容语言**: 中文 (zh-cn)
- **文章格式**: Markdown (.md)
- **配置文件**: config.toml

## 常用命令

### 开发服务器
```bash
hugo server
```
本地开发服务器，默认端口 1313

### 构建站点
```bash
hugo
```
构建静态网站到 public/ 目录

### 创建新文章
```bash
hugo new post/文章标题.md
```
基于 archetypes/default.md 模板创建新文章

## 项目结构

- `content/post/` - 博客文章，按分类命名（如：前端_、数据结构_、算法_、工具_等）
- `config.toml` - Hugo 主配置文件，包含站点信息、菜单配置、评论系统等
- `archetypes/default.md` - 新文章的模板
- `themes/even/` - 使用的主题，包含布局和样式
- `resources/` - Hugo 生成的资源文件
- `static/` - 静态资源（如果存在）

## 文章命名规范

文章文件名采用两种格式：

### 标准格式（推荐）
`YYYY-MM-DD-分类-标题.md`

**分类标识符**：
- `frontend` - 前端技术
- `java` - Java 相关
- `datastructure` - 数据结构
- `algorithm` - 算法
- `tools` - 工具使用
- `project` - 项目实践
- `theory` - 理论知识
- `programming` - 编程基础
- `redis` - Redis 相关
- `blockchain` - 区块链
- `network` - 网络技术
- `golang` - Go 语言
- `solution` - 解决方案
- `interview` - 面试相关
- `reading` - 读书笔记
- `news` - 新闻资讯

**示例**：
- `2021-10-19-frontend-javascript之promise.md`
- `2021-11-09-datastructure-哈希表.md`
- `2022-05-20-algorithm-通用缓存算法.md`
- `2024-06-07-tools-frp实现远程本地调试.md`
- `2020-05-19-project-简版在线聊天websocket.md`

### 新格式（2025年开始使用）
`YYYY-MM-DD-分类_标题.md`

**分类标识符**：
- `教程类` - 教程文档
- `热点` - 热点话题

**示例**：
- `2025-09-04-教程类_pythonyibubianchengxiangjielilunyushizhanjiehe.md`
- `2025-09-26-热点_2025年Vibe Coding元年AI重新定义开发者工作方式.md`

## Front Matter 配置

每篇文章的 front matter 包含：
- `title`: 文章标题
- `date`: 发布日期
- `description`: 文章描述
- `tags`: 标签数组
- `categories`: 分类数组
- `keywords`: SEO 关键词数组
- `draft`: 草稿状态 (true/false)

## 配置要点

- 使用中文语言配置 (`languageCode = "zh-cn"`)
- 启用了 gitalk 评论系统
- 配置了百度统计和 Google Analytics
- 支持 MathJax 数学公式渲染
- 启用了语法高亮和代码围栏
- 配置了多种社交媒体链接

## 内容管理

- 文章主要存放在 `content/post/` 目录
- 支持中文文件名和路径
- 使用 Markdown 格式编写
- 支持图片、代码块、数学公式等富文本内容