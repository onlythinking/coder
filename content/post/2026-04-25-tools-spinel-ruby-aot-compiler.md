---
title: "Spinel：Ruby 之父的 AOT 编译器 — 写出比 CRuby 快 11.6 倍的程序"
date: 2026-04-25
description: "深入解析 Ruby 语言之父 Matz 发布的实验性 AOT 编译器 Spinel，剖析其全程序类型推断、自举编译管线、与 C 代码生成的完整工作原理，并附真实性能基准数据。"
tags: ["Ruby", "AOT编译", "编译器", "性能优化", "Prism", "Matz"]
categories: ["tools"]
keywords: ["Ruby AOT编译器", "Spinel编译器", "Matz Ruby", "Prism解析器", "Ruby性能优化", "自举编译", "全程序类型推断"]
draft: false
cover: /images/covers/spinel-ruby-aot-compiler.png
readingTime: 5 分钟
toc: true
---

## 背景

2026 年 3 月 25 日，Ruby 语言之父 Yukihiro Matsumoto（后文称 Matz）在 GitHub 上悄然发布了一个名为 **Spinel** 的开源项目。与其说这是一个"版本"，不如说这是一次对 Ruby 未来的实验性押注：让 Ruby 源码不经虚拟机直接编译为原生可执行文件。

对 Ruby 社区而言，这条消息的重量不亚于当年 MRI 解释器的诞生。Spinel 不是一个 Ruby 运行时，而是一个** Ahead-of-Time（AOT）编译器**——它把 Ruby 代码先编译成 C 代码，再用标准 C 编译器（`cc -O2`）编译成机器码，最终产物是一个**零运行时依赖的独立二进制文件**。

本文从原理、工作流、性能表现三个维度，剖析 Spinel 的设计思路与工程价值。

## 问题：Ruby 为何需要 AOT 编译？

Ruby 的执行效率一直是社区的痛点。CRuby（MRI）基于字节码解释器，程序运行时边解析边执行，大量 CPU 时间消耗在了解释器的 dispatch loop 上。即便是 YJIT、MJIT 等 JIT 方案，在冷启动阶段和短生命周期程序上收益也有限。

一个更彻底的思路是：**在运行前就把整个程序编译成机器码**。这正是 AOT 编译的核心逻辑。传统 AOT 路线有两条：

1. **自举编译**：写一个编译器，用这门语言自己编译自己（例如 GCC 自举）。工程量巨大，门槛极高。
2. **嵌入式虚拟机**：把整个 Ruby 虚拟机编译进产物，例如 TruffleRuby，产物体积和复杂度都不小。

Spinel 选择了一条更务实、更优雅的第三条路：**把 Ruby 编译成 C 代码，再借助成熟的标准 C 工具链完成编译**。

## 原理：Spinel 是如何工作的

Spinel 的编译管线分为三个阶段，每一阶段职责明确：

```text
Ruby 源码 (.rb)
    │
    ▼ 阶段一：解析（spinel_parse）
Ruby ──→ Prism 解析器 ──→ AST 文本文件
（使用 Prism 语法分析器，将 Ruby 代码解析为抽象语法树并序列化）

    │
    ▼ 阶段二：代码生成（spinel_codegen）
AST 文本文件 ──→ 类型推断 + C 代码生成 ──→ C 源码 (.c)
（自举实现：编译器本身也用 Ruby 编写，编译后成为原生二进制）

    │
    ▼ 阶段三：系统编译
C 源码 (.c) + libspinel 运行时 ──→ cc -O2 -Ilib -lm ──→ 原生可执行文件
（依赖标准 C 编译器和数学库，无其他运行时依赖）
```

### 阶段一：Prism 解析器

Spinel 使用 **Prism**（Ruby 官方标准语法解析器）将 Ruby 源码解析为 AST。Prism 由 Ruby 核心团队维护，替代了此前的 Ripper，成为 Ruby 3.4+ 的默认解析器。Spinel 不重复造解析器的轮子，而是直接利用 Prism 的成果，这体现了 Matz 一贯的务实风格。

解析阶段会生成一个 AST 的文本序列化文件，包含了所有节点类型和位置信息。

### 阶段二：自举式代码生成

这是 Spinel 最有趣的部分。`spinel_codegen.rb` 是用 Ruby 写成的全程序类型推断和 C 代码生成器。它接受 AST 输入，执行**全程序级别（whole-program）的类型推断**，推断出每个变量的静态类型，再生成对应的 C 代码。

自举（Self-hosting）是编译器工程中的经典技巧：先用宿主语言（这里用 CRuby）编译出 `spinel_codegen` 的第一版原生二进制（`bin1`），再用这个二进制编译自己生成 `gen2.c`，最后用 `gen2.c` 编译出的 `bin2` 再次编译，得到 `gen3.c`。当 `gen2.c == gen3.c` 时，自举环闭合，说明编译器是自洽的。

```text
CRuby + spinel_codegen.rb  →  bin1（第一代编译器）
bin1 + spinel_codegen.rb  →  gen2.c
gen2.c 编译              →  bin2（第二代编译器）
bin2 + spinel_codegen.rb  →  gen3.c
gen2.c == gen3.c  ✅ 自举闭合
```

### 阶段三：C 编译与运行时

生成的 C 代码调用 `libspinel` 运行时库，其中包含了 Ruby 对象的内存表示（Value/Tagged Pointer 方案）、字符串、数组、哈希表的基本实现，以及一个精简的 GC（主要基于前面表中的分代 GC 数据）。整个运行时只有头文件形式，没有额外的动态链接依赖。

最终产物通过标准 `cc` 编译，Linux/macOS/Windows 的 GCC/Clang/MSVC 均可使用。

## 实践：上手 Spinel

### 安装依赖

```bash
git clone https://github.com/matz/spinel
cd spinel
make deps    # 拉取 libprism 依赖
make         # 编译完整工具链
```

### 编译一个 Ruby 程序

```bash
cat > hello.rb <<'RUBY'
def fib(n)
  if n < 2
    n
  else
    fib(n - 1) + fib(n - 2)
  end
end

puts fib(34)
RUBY

./spinel hello.rb    # 编译为 ./hello
./hello              # 输出 5702887，毫秒级完成
```

### 查看生成的 C 代码

```bash
./spinel hello.rb -S    # 将 C 代码输出到 stdout
./spinel hello.rb -c    # 生成 hello.c 文件
```

### 编译选项

| 选项 | 作用 |
|------|------|
| `./spinel app.rb` | 编译为 `./app` |
| `./spinel app.rb -o myapp` | 指定输出为 `./myapp` |
| `./spinel app.rb -c` | 仅生成 C 代码，不编译 |
| `./spinel app.rb -S` | 将 C 代码打印到 stdout |

## 性能：真实数据说话

Spinel 的 README 提供了完整的基准测试数据。对比基准是 CRuby 的 `miniruby`（Ruby 4.1.0dev，不含内置 gems，比系统 `ruby 3.2.3` 更快），几何平均提速约 **11.6 倍**。

### 计算密集型

| 基准测试 | Spinel | miniruby | 提速比 |
|---------|--------|----------|-------|
| Conway 生命游戏 | 20 ms | 1,733 ms | **86.7x** |
| Ackermann | 5 ms | 374 ms | **74.8x** |
| Mandelbrot 分形 | 25 ms | 1,453 ms | **58.1x** |
| 递归 Fibonacci | 17 ms | 581 ms | **34.2x** |
| N 皇后问题 | 10 ms | 304 ms | **30.4x** |
| Tarai 函数 | 16 ms | 461 ms | **28.8x** |
| 矩阵乘法 | 13 ms | 313 ms | **24.1x** |

### 数据结构与 GC

| 基准测试 | Spinel | miniruby | 提速比 |
|---------|--------|----------|-------|
| 红黑树 | 24 ms | 543 ms | **22.6x** |
| 伸展树 | 14 ms | 195 ms | **13.9x** |
| Huffman 编码 | 6 ms | 59 ms | **9.8x** |
| GC 基准 | 1,845 ms | 3,641 ms | **2.0x** |

这些数据揭示了一个重要规律：**Spinel 的收益与程序的计算密度正相关**。对于大量数值计算、递归、内存分配的纯计算任务，提速可以高达数十倍；而 GC 密集型任务（对象分配/回收频繁）收益则相对有限，GC 基准仅 2 倍提速。

## 局限与挑战

Spinel 目前仍处于非常早期的阶段（README 标注 74 个测试通过，55 个基准测试通过），工程上的局限值得关注：

1. **不支持完整标准库**：目前 Spinel 仅支持 Ruby 语言核心子集，许多内置类（如 `File`、`Socket`）尚未实现。用 `puts` 输出字符串可以，但想写一个文件读取程序，暂时还做不到。
2. **自举依赖 CRuby**：编译 `spinel_codegen.rb` 本身需要 CRuby 环境，这不是严格意义上的"从源码完全自举"。
3. **调试困难**：生成的 C 代码可读性有限，出错时调试体验远不如原生 Ruby。
4. **仅支持静态类型子集**：Ruby 是动态类型语言，全程序类型推断只能覆盖可以被推断出类型的变量子集，无法做到 Ruby 3.x RBS 那种静态类型的全面保障。

## 总结

Spinel 是 Matz 对 Ruby 性能问题的一次严肃的实验性回答。它没有选择重写一个虚拟机，也没有选择 TruffleRuby 那种图编译的重型路线，而是用**编译到 C** 这种"老派但可靠"的方式，证明了 Ruby 代码在 AOT 编译下的性能潜力。

11.6 倍的几何平均提速，即便扣掉基准测试的偏倚成分，依然是惊人的。对于那些**计算密集但不需要 IO/网络/系统库的 Ruby 程序**（算法竞赛、科研计算、嵌入式脚本），Spinel 已经具备实用价值。

更重要的是，Spinel 的出现为 Ruby 社区打开了一扇新的门：Ruby 源码可以成为一种**中间表示（IR）**，通过编译到不同后端（wasm、native、gpu）来满足不同场景的需求。这是比性能本身更有价值的探索。

---

**相关资源**

- GitHub: https://github.com/matz/spinel
- Prism 解析器: https://github.com/ruby/prism

**相关文章**

- [Java JIT 编译器：它是如何工作的以及为什么它对您的应用程序的性能很重要](https://www.onlythinking.com/post/java-jit-compiler/) — 了解 JIT 与 AOT 的对比
- [Serena：让 AI 编程 Agent 拥有 IDE 级别的代码理解能力](https://www.onlythinking.com/post/tools-serena/) — AI 编程工具链的另一条路

<!-- 社交分享 -->
> 欢迎分享到 X/Twitter、微博、微信等平台，如有问题或建议可在评论区交流！

