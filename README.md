# 🚀 编程码农 - 专业技术博客

[![Hugo](https://img.shields.io/badge/Hugo-0.100+-blue.svg)](https://gohugo.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Website](https://img.shields.io/badge/Website-onlythinking.com-orange.svg)](https://www.onlythinking.com/)

> 专注软件开发技术热点，深度探索前端技术与 Go 语言后端开发

## 🎯 项目简介

**编程码农**是一个专业的技术博客，致力于追踪和分析软件开发领域的最新技术趋势。我们专注于：

- 📱 **前端技术演进** - React、Vue、TypeScript 等现代前端技术栈
- 🔧 **Go 语言后端开发** - Go 并发、微服务、云原生技术实践  
- 🔥 **技术热点解析** - AI/ML、DevOps、开源项目深度分析
- 💡 **实战经验分享** - 真实项目中的技术选型和架构决策

**访问地址**: [https://www.onlythinking.com/](https://www.onlythinking.com/)

## 📚 内容体系

### 前端技术栈
- **框架深度**: React/Vue/Angular 最新特性解析
- **语言进阶**: TypeScript 高级特性和最佳实践  
- **构建工具**: Vite、Webpack、esbuild 性能优化
- **样式方案**: CSS-in-JS、Tailwind CSS、CSS 新特性
- **架构设计**: 微前端、组件库、状态管理
- **性能优化**: 渲染优化、包体积优化、加载策略

### Go 后端技术
- **语言特性**: Go 新版本特性和语法糖
- **并发编程**: Goroutine、Channel、Context 深度实践
- **Web框架**: Gin、Echo、Fiber 框架对比和选型
- **微服务**: gRPC、服务发现、链路追踪
- **数据库**: GORM、SQL优化、Redis 缓存策略
- **云原生**: Docker、Kubernetes、CI/CD 实践

### 技术热点
- **AI集成**: ChatGPT API、机器学习在开发中的应用
- **开源生态**: 热门开源项目分析和贡献指南
- **架构演进**: 分布式系统、事件驱动架构
- **开发效率**: 工具链优化、自动化测试

## ✨ 技术特色

- 🏗️ **Hugo 驱动** - 基于 Hugo 静态网站生成器，构建速度极快
- 🎨 **响应式设计** - 使用 Even 主题，完美适配移动端
- 🔍 **SEO 优化** - 结构化数据、元数据优化，搜索引擎友好
- 💬 **互动评论** - 集成 Gitalk 评论系统，技术讨论活跃
- 📊 **数据统计** - Google Analytics + 百度统计双重分析
- 🧮 **公式支持** - MathJax 支持，算法文章表达更清晰
- 🌈 **代码高亮** - 多语言语法高亮，代码阅读体验佳

## 📁 项目结构

```
coder/
├── content/post/           # 博客文章
│   ├── 前端_*.md          # React、Vue、TypeScript
│   ├── go_*.md            # Go语言技术
│   ├── 架构_*.md          # 系统架构设计  
│   ├── 工具_*.md          # 开发工具效率
│   ├── 热点_*.md          # 技术趋势分析
│   └── 实践_*.md          # 项目实战经验
├── themes/even/            # Even 主题文件
├── config.toml            # Hugo 主配置
├── archetypes/            # 文章模板
│   └── default.md         # 默认文章模板
└── resources/             # 构建资源
```

## 🚀 快速开始

### 环境要求

- Hugo Extended v0.100+ 
- Git 2.0+
- Go 1.19+ (可选，用于主题开发)

### 本地开发

```bash
# 克隆项目
git clone https://github.com/onlythinking/coder.git
cd coder

# 初始化子模块（主题）
git submodule update --init --recursive

# 启动开发服务器
hugo server

# 访问 http://localhost:1313
```

### 创建文章

```bash
# 创建新文章
hugo new post/前端_React18新特性解析.md

# 或者
hugo new post/go_并发编程最佳实践.md
```

## ✍️ 写作规范

### 文章命名
- 格式：`分类_标题.md`
- 示例：`前端_Vue3组合式API深度解析.md`
- 示例：`go_微服务架构设计模式.md`

### Front Matter 模板
```yaml
---
title: "技术标题 - 副标题 | 编程码农"
date: 2024-01-15
description: "文章描述，120-158字符，包含核心关键词"
tags: ["React", "前端开发"]
categories: ["前端技术"] 
keywords: ["React 18", "并发特性", "前端开发"]
author: "编程码农"
---
```

### SEO 优化建议
- 标题包含核心关键词，控制在60字符内
- 描述突出技术价值，包含2-3个关键词
- 合理使用标签和分类，便于内容聚合
- 代码示例完整可运行，增强用户体验

## 🔧 配置说明

### 核心配置项
```toml
# config.toml 重要配置
baseURL = "https://www.onlythinking.com/"
languageCode = "zh-cn"
title = "编程码农 - 专业技术博客 | 前端后端开发指南"

[params]
  # SEO 优化
  keywords = ["编程技术", "前端开发", "Go语言"]
  description = "专注分享高质量编程技术内容"
  
  # 功能开关
  toc = true                # 文章目录
  mathjax = true           # 数学公式
  highlightInClient = true  # 代码高亮
```

## 🚀 部署流程

### 构建站点
```bash
# 构建生产版本
hugo --minify

# 输出到 public/ 目录
```

### CI/CD 建议
```yaml
# GitHub Actions 示例
name: Deploy Hugo
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
      - name: Setup Hugo  
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true
      - name: Build
        run: hugo --minify
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

## 🎨 主题定制

### Even 主题特色
- 简洁现代的设计风格
- 深色/浅色模式切换
- 移动端友好的响应式布局
- 丰富的 shortcode 支持

### 自定义样式
```scss
// 在 assets/sass/custom.scss 中添加自定义样式
.custom-highlight {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
}
```

## 📊 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Hugo | v0.100+ | 静态网站生成器 |
| Even Theme | Latest | 博客主题 |
| Markdown | - | 内容编写格式 |
| Gitalk | v1.7+ | 评论系统 |
| MathJax | v3.0+ | 数学公式渲染 |
| Google Analytics | v4 | 访问统计分析 |

## 📈 内容规划

### 2024年重点方向
- **前端热点**: React 18、Vue 3.4、Svelte 5 深度解析
- **Go语言**: 泛型实践、性能优化、云原生开发
- **AI集成**: ChatGPT API 实战、AI辅助编程工具
- **架构演进**: 微前端、Serverless、边缘计算

### 文章更新频率
- 技术深度文章：每周 1-2 篇
- 热点快讯解析：实时更新
- 项目实战总结：每月 2-3 篇

## 🤝 贡献指南

欢迎各种形式的贡献：

### 内容贡献
- 🐛 发现错误或改进建议
- 💡 技术观点讨论和交流  
- 📝 Guest Post 投稿（高质量技术文章）

### 技术贡献
- 🔧 主题样式优化
- ⚡ 性能优化建议
- 🛠️ 功能扩展开发

### 参与方式
1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📞 联系方式

- 🌐 **博客地址**: [https://www.onlythinking.com/](https://www.onlythinking.com/)
- 📧 **邮箱**: lixingping233@gmail.com
- 🐱 **GitHub**: [@onlythinking](https://github.com/onlythinking)
- 📚 **知乎**: [编程码农](https://www.zhihu.com/people/onlythinking)

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

---

<div align="center">

**🌟 如果这个项目对你有帮助，欢迎给个 Star！🌟**

Made with ❤️ by [编程码农](https://github.com/onlythinking)

</div>