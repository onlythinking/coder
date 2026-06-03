---
title: "TypeScript 7 来了：微软官方 tsgo 工具，10倍编译速度真香"
date: 2026-06-03
description: "微软用 Go 重写 TypeScript 编译器为 tsgo，官方公告显示 10倍速度提升。本文给出 npm install + VS Code 集成的完整实操步骤，附官方 benchmark 数据与现状评估。"
tags: ["TypeScript", "tsgo", "Go", "前端工具"]
categories: ["前端工具"]
keywords: ["TypeScript 7", "tsgo", "typescript-go", "10倍编译", "前端性能", "Go 重写", "tsc 替代"]
draft: false
cover: /images/covers/typescript-go-tsgo-10x-compiler.png
toc: true
readingTime: 3
---

`tsc` 编译慢这件事，估计戳中过不少人。我自己手头的项目跑一次 CI 能转个 5-6 分钟，IDE 改个文件也得 1-2 秒才反应过来，等的时候总想去刷杯咖啡。

微软把 TypeScript 编译器用 Go 重写了一遍。官方公告标题直接写「A 10x Faster TypeScript」。项目放在 [microsoft/typescript-go](https://github.com/microsoft/typescript-go) 仓库，目前 25.5k stars，Apache-2.0 协议，最近一次 commit 是 2026-06-03，依然在活跃迭代。

## 一句话定位 tsgo

tsgo 是 TypeScript 编译器的原生（Go 语言）实现版本。包名 `@typescript/native-preview`，bin 入口是 `tsgo`。它不是新语言，不是新语法，你的 `tsconfig.json` 不用改，跑出来的产物与 `tsc` 一致。

它只是把原本用 TypeScript 写的编译器，用 Go 重写后编译成原生二进制。原生程序本身就能避开 V8 启动开销，加上 Go 自带的 goroutine 并发，编译能跑满多核——这大概就是快的原因。

## 上手指南

先装包，一行命令搞定，零依赖：

```bash
npm install @typescript/native-preview
npx tsgo --version
```

装好之后，用 `npx tsgo` 替代 `npx tsc` 就行。Node 版本要求 `>= 16.20`，绝大多数项目都满足。

想让 VS Code 编辑器也走 tsgo 路径（类型检查、补全、跳转），再加两步：

1. 在扩展市场装 [TypeScriptTeam.native-preview](https://marketplace.visualstudio.com/items?itemName=TypeScriptTeam.native-preview)
2. `settings.json` 里加一行：

```json
{
  "js/ts.experimental.useTsgo": true
}
```

重启 VS Code 一次就够，后面再开项目不用重复操作。

## 替代 tsc 的常见场景

| 场景 | 命令 |
| --- | --- |
| 一次性编译检查 | `npx tsgo --noEmit` |
| 完整构建 | `npx tsgo` |
| 单文件类型检查 | `npx tsgo file.ts` |
| CI 跑全量检查 | 把脚本里的 `tsc` 换成 `tsgo` |

大多数场景下，只要把 `package.json` 的 `build` 脚本里的 `tsc` 替换成 `tsgo` 就能立刻见效。

## 官方性能数据（以官方公告为准）

微软在 [TypeScript Native Port 公告](https://devblogs.microsoft.com/typescript/typescript-native-port/) 里放了一张表，直接抄过来给你感受一下：

```text
Codebase        Size (LOC)   Current    Native    Speedup
VS Code         1,505,000    77.8s      7.5s      10.4x
Playwright      356,000      11.1s      1.1s      10.1x
TypeORM         270,000      17.5s      1.3s      13.5x
date-fns        104,000      6.5s       0.7s      9.5x
tRPC (s+c)      18,000       5.5s       0.6s      9.1x
```

平均下来 10x 起跳，大型项目甚至能到 13x。**以上数据均来自微软官方公告，实际项目可能因机器配置、tsconfig 复杂度、第三方类型包规模而不同，以官方公告为准。**

编辑器的项目加载时间也下来了，VS Code 整个工程从 9.6s 降到 1.2s，差不多 8x 提升。

## 现在能用吗？preview 阶段

这是重点：目前还是 preview 阶段，不是 1.0 稳定版。

官方在仓库 README 里明确写「not yet at full feature parity」——意思是还不能完全替代 `tsc`。

**已经可用的（done）：**
- 命令行编译 `tsgo`
- 基础类型检查
- 大多数日常场景
- VS Code 编辑器集成（preview 扩展）

**还在做（in progress / prototype）：**
- LSP（Language Server Protocol）完整支持
- Watch mode（目前只是 prototype）
- 完整的构建 API

**还不能用（not ready）：**
- 对外暴露的 API 还未就绪——如果你写的是 `tsc` 的封装工具、插件、codegen 工具链，先别切。
- 长期路线是合并回 [microsoft/TypeScript](https://github.com/microsoft/TypeScript) 主仓库，届时直接以 TypeScript 7.0 形式发布。

## 注意事项

- **不推荐生产**。`7.0.0-dev.20260602.1` 这种版本号明确告诉你这是 dev 快照，生产构建脚本暂时别切。
- **API 不可用**。需要 `typescript` 包 API 的项目（比如写 transformer、linter、generator）先别动，等官方宣布 API 就绪。
- **类型定义可能漏**。极少数第三方包可能暂时没适配，遇到类型错误先回到 `tsc` 排查。
- **CI 上想尝鲜可以，但要保留回滚方案**——把 `tsgo` 单独放一个 npm script，出问题了切回 `tsc` 一行命令的事。

## 一句话总结

微软用 Go 重写 TypeScript 编译器，官方数据 10x 速度提升，现在就能 `npm install` 装上尝鲜。**preview 阶段，不建议生产，API 还没就绪，但日常 `tsc` 编译场景已经够用。**

想看原生加速这条路能走多远，可以读一下之前写的[《Spinel：Ruby 之父的 AOT 编译器》](https://www.onlythinking.com/post/2026-04-25-tools-spinel-ruby-aot-compiler/)，讲的是同一类思路——用更现代的编译策略换取量级提升。Go 的并发则是 tsgo 能跑满多核的关键，可以参考[《学习 Go 语言并发编程》](https://www.onlythinking.com/post/2024-05-14-golang-%E5%AD%A6%E4%B9%A0go%E8%AF%AD%E8%A8%80%E4%B8%AD%E7%9A%84%E5%B9%B6%E5%8F%91/)。我个人更推荐前者，写 tsgo 之前先看 Spinel 那一篇会更有感觉。

---

**参考链接**
- [官方公告：A 10x Faster TypeScript](https://devblogs.microsoft.com/typescript/typescript-native-port/)
- [GitHub 仓库：microsoft/typescript-go](https://github.com/microsoft/typescript-go)
- [NPM 包：@typescript/native-preview](https://www.npmjs.com/package/@typescript/native-preview)
- [VS Code 扩展：TypeScriptTeam.native-preview](https://marketplace.visualstudio.com/items?itemName=TypeScriptTeam.native-preview)

**分享到**：[X/Twitter](https://twitter.com/intent/tweet?text=TypeScript%207%20%E6%9D%A5%E4%BA%86%EF%BC%9A%E5%BE%AE%E8%BD%AF%E5%AE%98%E6%96%B9%20tsgo%20%E5%B7%A5%E5%85%B7%EF%BC%8C10%E5%80%8D%E7%BC%96%E8%AF%91%E9%80%9F%E5%BA%A6%E7%9C%9F%E9%A6%99&url=https://www.onlythinking.com/post/2026-06-03-tools-typescript-go-tsgo-10x-compiler/&hashtags=TypeScript,tsgo,Go,前端工具)
