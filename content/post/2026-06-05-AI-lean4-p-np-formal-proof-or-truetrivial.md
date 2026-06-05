---
title: '当 Lean 4 真的「证明」了 P=NP：一次定义级作弊与形式化验证的边界'
date: 2026-06-05
description: '最近 GitHub 上一位作者用 Lean 4 仓库宣称形式化证明了 P=NP，社区第一个 issue 就指出：主定理证的是 `True`，不是 P=NP。本文借这个真实事件，复盘 P=NP 证明史上的 3 次典型伪证、Aaronson 8 Signs 判别框架，以及为什么形式化验证证不了「证错的问题」。'
tags: ["P=NP", "Lean 4", "形式化验证", "计算复杂性", "CS 基础", "GitHub"]
categories: ["theory"]
keywords: ["P=NP", "Lean 4", "形式化证明", "P≠NP 伪证", "Norbert Blum", "Deolalikar", "Scott Aaronson 8 Signs", "Pedigree Polytopes", "TiruArt", "mathlib", "CS 基础"]
draft: false
cover: /images/covers/lean4-p-np-formal-proof.png
readingTime: 11
toc: true
shareTitle: "Lean 4 真的能证明 P=NP 吗？一次定义级作弊的复盘"
---

知乎数学圈最近又在为「P=NP 是不是被解决了」吵得沸沸扬扬。起因不是大牛的论文，而是 **GitHub 上一个 Lean 4 仓库的 issue 区**——仓库作者宣称「用 Lean 4 机器验证了 P=NP」，但社区在 issue #1 标题里就直白写出了漏洞：

> *Main theorem currently proves `True`, not `P = NP`*

这不是段子，是 2026 年 6 月 3 日真实发生的事。我把整个事件复盘一遍，顺便讲清楚三件事：

1. 这位作者到底是怎么「证明」P=NP 的？
2. 为什么形式化验证在这种情况下毫无作用？
3. P=NP 证明史上 3 次典型翻车，给我们留下了什么判别框架？

## 一、事件还原：Lean 4 仓库里的「P=NP 证明」

仓库是 [TiruArt/Pedigree-Polytopes-Lean4](https://github.com/TiruArt/Pedigree-Polytopes-Lean4)，仓库简介原文写着：

> *Lean 4 machine-verified proof that Membership Problem for Pedigree Polytopes, M3P ∈ P and P = NP via properties of Pedigree Polytopes.*

听起来很厉害：M3P（Pedigree Polytope 的成员问题）在 P 里，由此推出 P=NP。Lean 4 机器验证。完美闭环。

但 issue #1 第一行就把底裤揭了。仓库里的核心定义长这样：

```lean
def P_equals_NP : Prop := True
def SAT_in_P    : Prop := True
```

也就是说，作者**直接把 P=NP 和 SAT∈P 这两个命题定义为 `True`**。Lean 4 是个诚实的证明验证器：你说「A 等价于 True」，它就老老实实在类型系统里给你展开成 `True`，然后 `trivial` 一步搞定。

这不是证明，这是**重新定义问题**。形式化验证的所有铁律——类型检查、kernel 验证、kernel 之外不可信——在这里全部失效。验证通过的不是一个数学事实，而是**你写在文件里的定义本身**。

## 二、为什么形式化验证拦不住这种作弊

对不熟悉证明助手的读者，先解释下 Lean 4 这类工具的工作原理。

Lean 4 不是一个「数学真理发现器」，它是一个**证明验证器**。你给它一段声明「A 成立」，再给它一段用 `apply`、`exact`、`intro` 之类 tactic 写的证明脚本，Lean 的 kernel 会**机械地**检查每一步推导是否合法。这个过程是 sound（不会把假命题验证为真）的——**但有一个大前提：你声明的命题本身必须真的表达你想表达的东西**。

把 `def P_equals_NP : Prop := True` 换成「定义：我现在 30 岁」是同构的：定义本身就是真的，不需要任何外部事实支撑。Lean kernel 不会、也没办法判断你的定义是否合理——它不是数学家，它是类型检查器。

这就是 Lean 这类工具的**根本边界**：

| 它能做的 | 它做不了的 |
|---------|----------|
| 验证一段已知证明的每一步合法 | 判断你证明的「命题」本身是否有意义 |
| 告诉你「这段代码类型对了」 | 告诉你「这段代码解决了一个真问题」 |
| 防止 typo、错引理、错用假设 | 防止你用 `:= True` 把答案先写进题目里 |

这跟单元测试有点像：单测能保证你写的代码「按你说的那样跑」，但不能保证你测的函数是「你真正想测的那个函数」。

## 三、P=NP 证明史上的 3 次典型翻车

Lean 4 这个案例不是孤例。事实上，过去 15 年里几乎每隔几年就会冒出一篇「我证明了 P=NP / P≠NP」的论文，结局都是被同行快速证伪。3 个最有名的案例：

### 1. 2010 年 Deolalikar 案（HP 实验室）

Vinay Deolalikar 是 HP 实验室的研究员，2010 年 8 月把一份 66 页的「P≠NP 证明」草稿发给同行评审（包括微软的 Leonid Levin、MIT 的 Scott Aaronson）。这份草稿借鉴了统计物理里的相变理论，声称用描述复杂性（descriptive complexity）刻画了 P 和 NP 在结构上的本质差异。

发布当天就在 Lipton 的博客和 HN 上炸开了锅。Ryan Williams 等人在 24 小时内找到关键漏洞：Deolalikar 用 FO(LFP) 描述 P 的部分实际上不能区分 P 和 NP 的解空间结构。一周内原作者基本承认失败，几个月后正式撤稿。

HN 讨论帖至今还在：[Fatal Flaws in Deolalikar's P ≠ NP Proof?](https://news.ycombinator.com/item?id=1600068)（34 票）以及 [Update on Deolalikar's Proof that P≠NP](https://news.ycombinator.com/item?id=1594283)（95 票）。

### 2. 2017 年 Norbert Blum 案（前 Bonn 大学）

Norbert Blum 是前德国波恩大学数学教授、Theoretical Computer Science 期刊编委。2017 年 8 月，他提交到 arXiv 的论文 [A Solution of the P versus NP Problem](https://arxiv.org/abs/1708.03486) 试图用 Razborov 的自然证明框架证 P≠NP。

论文发布后**两周**内，Boaz Barak（哈佛、ACM 主席）和 Luca Trevisan 等人就在博客和推特上指出：Blum 引用的一个核心引理来自一篇被证伪的论文。Blum 后来撤稿。**整个事件登上了当年的 Quanta Magazine、Nature News 等主流媒体**——这本身就说明了学界对「正经人写错论文」和「民科写错论文」的反应差异。HN 那篇讨论帖 [A Solution of the P versus NP Problem?](https://news.ycombinator.com/item?id=15008076) 拿到了 662 票，是当时 HN 历史上最热的技术讨论之一。

### 3. 2024 年一次「P=NP 解决」传闻（未具名）

2024 年初某个数学论坛流传过一份匿名的「P=NP 证明」PDF，声称用信息论和拓扑论证绕过 NP 完全性。数学圈的反应出奇一致：**没人去认真读它**。因为它没有通过标准的学术发布流程，作者也不是已知的研究者。

这种「无来源 + 重大声明」的组合，几乎是诈骗或妄想的标准特征。

## 四、Aaronson 的 8 Signs：判断 P=NP 伪证的通用框架

Scott Aaronson（UT Austin、量子计算权威）在 2010 年 Deolalikar 案之后，写了一篇至今被反复引用的博客 [Eight Signs A Claimed P≠NP Proof Is Wrong](http://scottaaronson.com/blog/?p=458)。这套判别框架**对 P=NP 任何方向的「证明」都适用**——因为只要声称是证明，都要回答同一组问题。我把 8 个信号整理成 3 类：

### 红旗 A：作者身份与发布流程（最致命的 3 个）

1. **作者不是该领域长期研究者**。Deolalikar 是 HP 实验室做了几十年相变复杂性的，他的失败是「认知边界外推」；匿名数学爱好者的失败通常是「基本概念错位」，两者根本不在一个层次。
2. **没有走正常的同行评审流程**。P=NP 这个级别的问题，不会被某个未具名作者藏在 PDF 附件里悄悄流传。
3. **如果走 arXiv 但很快撤稿，几乎可以确定是错的**。Blum 的案就是典型——一个数学教授级别的人撤稿，说明错得连自己都圆不下去。

### 红旗 B：技术方法论（4 个）

4. **完全没引用 Razborov 1995 年自然证明障碍、Ryan Williams 2010 年代后期一系列「绕过障碍」的非自然证明、Impagliazzo 1995 五大世界**这 3 大方向的任一文献。说明作者要么不知道有这些障碍，要么知道但假装不存在。
5. **声称用到的工具（物理学、拓扑学、AI）跟复杂性类没有现成的 reduction**。Deolalikar 的统计物理相变论证之所以轰动人，是因为有人相信这能 work——但它最终没 work，因为这个 reduction 本身有问题。
6. **关键步骤「手波」（hand-waving）过去**，尤其是「显然可以归约」「显然多项式时间」这种段落。真正的 P=NP 证明 50 年没出来，每一步都很难——如果哪里看起来「显然」，大概率藏着致命漏洞。
7. **没有完整形式化版本**。这一点在 2024 年之前可以理解，但在 Lean 4 / Coq / Isabelle 这些工具成熟的时代，**没有形式化**至少说明作者没让同行能机器验证的意愿。

### 红旗 C：宣传方式（1 个）

8. **通过社交媒体/博客/邮件群发而不是会议或期刊**。社区的反应是「明星作者才配享有的怀疑度」——不是因为势利，是因为**重大声明必须有对应的声誉抵押**。

把这 8 条套到 Lean 4 这次事件上，每一条都中。

## 五、回到「定义级作弊」本身——为什么这次特别值得讲

我之所以挑这件事专门写一篇文章，是因为它有别于上面 3 个案例的**教育价值**：

- **Deolalikar 和 Blum 的失败是「技术错误」**——用对了工具但推理链断了。这些错误是 CS 学术界最重要的养分之一，每次复盘都能加深对复杂性类的理解。
- **TiruArt 这次的失败是「概念错误」**——把数学证明的本质搞反了。`def A : Prop := True` 在 Lean 4 里是完全合法的代码，从**形式化验证的角度**它就是 100% 正确。但它和「P=NP 被证明」之间，隔着整个数学共同体的语义共识。

这其实是形式化方法在科普层面最被误解的一点：**形式化证明验证的是「推导过程是否合法」，不是「你问的问题是否有意义」**。后者是数学家的工作，不能外包给证明助手。

这也是为什么真正的形式化项目（CompCert 编译器、seL4 微内核、Mathlib）要花**几年时间**让领域专家先把「我要证什么」用几十页的自然语言说清楚，再用几百小时的形式化代码把它「钉死」在 kernel 里。任何跳过第一步的尝试——不管包装得多花哨——都只是自欺欺人。

## 写在最后

对开发者的实用建议：

- **如果看到「AI/工具 X 证明/破解了某个长期开放问题」的标题**，先看作者身份，再看发布渠道，再用 Aaronson 那 8 条对一遍。90% 的时候前两步就把这条新闻筛掉了。
- **如果你自己在用 Lean 4 / Coq 做形式化项目**，把核心定义拿给不懂这个工具的同事看一遍——如果他问「这定义不就是把答案写进去了吗」，恭喜你，节省了一周的调试时间。
- **理解工具的能力边界，比会用工具更重要**。这适用于 Lean 4，也适用于所有你正在用的 LLM、IDE 插件、CI 平台。

P=NP 也许永远不会被证明（大多数复杂性理论学家赌 P≠NP），也许下周就有人发出来（虽然概率接近零）。无论哪种情况，能辨别什么是真正的证明、什么是定义上的自欺，是一个 CS 从业者应该有的基本素养。

---

参考链接：

- TiruArt/Pedigree-Polytopes-Lean4 仓库与 issue #1：https://github.com/TiruArt/Pedigree-Polytopes-Lean4/issues/1
- Norbert Blum 2017 P≠NP 论文（已撤稿）：https://arxiv.org/abs/1708.03486
- Scott Aaronson 「Eight Signs A Claimed P≠NP Proof Is Wrong」：http://web.archive.org/web/2025*/scottaaronson.com/blog/?p=458
- HN Deolalikar 案讨论（Fatal Flaws 帖）：https://news.ycombinator.com/item?id=1600068
- HN Deolalikar 案讨论（Update 帖，95 票）：https://news.ycombinator.com/item?id=1594283
- HN Blum 案讨论（662 票）：https://news.ycombinator.com/item?id=15008076
