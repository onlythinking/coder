---
title: "Kimi K3 拆解：国内首个 3T 级开源模型，把 MoE 和量化做到了什么程度"
date: 2026-08-05
description: "月之暗面开源Kimi K3：2.8T总参/104B激活MoE，KDA+AttnRes架构，MXFP4量化感知训练，1M上下文"
tags: ["Kimi", "Moonshot", "开源大模型", "MoE", "量化训练"]
categories: ["AI"]
keywords: ["Kimi K3", "KDA", "AttnRes", "MXFP4", "Stable LatentMoE", "月之暗面", "3T 开源模型", "vLLM"]
draft: false
toc: true
readingTime: 8
cover: /images/covers/2026-08-05-AI-kimi-k3-open-3t-moe-quantization.svg
---

8 月初，月之暗面（Moonshot AI）在 GitHub 开源了 [Kimi K3](https://github.com/MoonshotAI/Kimi-K3) 仓库，一周内拿到 8K star。和上次 K2 的开源节奏不同，这次仓库直接挂的是「Open Frontier Intelligence」的标签——官方把它定位成「世界首个开源 3T 级模型」。3T 参数全量开放这件事在国内大模型圈子里是不常见的，所以我们拆开看看到底把哪些东西开源了，架构上和 K2 拉开了什么差距。

## 一、模型本体：2.8T 总参，激活 104B 的 MoE

按仓库 README 给出的 Model Summary，K3 的几个关键参数：

- **架构**：Mixture-of-Experts（MoE）
- **总参数**：2.8T
- **激活参数**：104B
- **层数**：93 层（1 个 Dense 层 + 92 个 MoE 层）
- **专家配置**：896 个专家，每 token 选 16 个，外加 2 个共享专家
- **注意力层组合**：69 层 KDA + 24 层 Gated MLA
- **隐藏维度**：7168（Attention）/ 3584（Latent MoE）/ 3072（per Expert）
- **注意力头数**：96
- **词表**：160K
- **上下文**：1,048,576 tokens（1M）
- **视觉编码器**：MoonViT-V2，401M 参数
- **量化方案**：MXFP4 权重 / MXFP8 activations（量化感知训练）
- **激活函数**：SiTU-GLU
- **模态**：Text + Image（原生多模态）

这一串数字里有三件事值得拎出来讲。第一是「激活 104B / 总参 2.8T」的比例——激活参数只有 3.7%，比典型的 MoE 模型更稀疏。第二是注意力层里 69 KDA + 24 Gated MLA 的混合配比，这是一个新的设计，README 里没有给完整的混合动机解释，但把 Delta Attention 放在大多数层、用 Gated MLA 在特定层兜底，说明 K3 是在「线性注意力效率」和「全注意力表现」之间找平衡。第三是 1M 上下文 + 401M 视觉编码器的原生多模态，1M 上下文在 2026 年的开源模型里已经不算稀奇，但配合量化感知训练之后推理成本会显著下降。

## 二、架构创新：KDA + Attention Residuals + Stable LatentMoE

K3 在架构上的核心改动不是参数堆叠，而是三个组件组合：

### 2.1 Kimi Delta Attention（KDA）

Delta Attention 是 K2 那一代就开始用的线性注意力变体，K3 在此基础上迭代。线性注意力的本质是用矩阵分解把 softmax(QK^T)V 的复杂度从 O(n²) 降到 O(n)，代价是表达能力受限。KDA 在 DeltaNet 的基础上对衰减项做了调整，让长程依赖的衰减曲线更平缓，这是 K3 处理 1M 上下文的关键。

### 2.2 Attention Residuals（AttnRes）

AttnRes 是 K3 新增的机制。它在 KDA 层之间插入 Gated MLA 层（24 层），让全注意力的表达能力对线性注意力做「残差补偿」。类比 Transformer 的残差连接思路——只不过 K3 不是把信号残差回去，而是把全注意力的特征隔几层注入一次。这个设计在仓库的 README 里没有展开公式，需要等完整技术报告 `k3_tech_report.pdf` 才能看细节，但官方说法是相比 K2 整体 scaling efficiency 提升了约 2.5 倍。

### 2.3 Stable LatentMoE

K3 用 Stable LatentMoE 框架管理 896 专家 / 选 16 的稀疏路由。和 DeepSeek-V3 的 aux-loss-free 路由不同，K3 没有公开具体的负载均衡策略，只在 README 里用了「Stable」这个前缀——大概率是某种对路由噪声做平滑处理的变体。160K 词表 + 1M 上下文 + 896 专家的组合，对路由稳定性要求很高，这是 Stable 这个词的实际指向。

把 KDA + AttnRes + Stable LatentMoE 三件套放在一起，K3 的架构哲学是「用线性注意力压住推理成本，用 AttnRes 周期性地把全注意力注入回去补偿质量，用 Stable LatentMoE 保证稀疏路由在大规模下不崩」。

## 三、MXFP4 量化感知训练：工程层面最值得关注的点

K3 的 README 第四节直接用「Native MXFP4 Quantization」做标题，这是仓库想强调的重点：

> Kimi K3 applies quantization-aware training from the SFT stage onward, using MXFP4 weights with MXFP8 activations for broad hardware compatibility.

几个关键含义：

1. **量化感知训练从 SFT 阶段就开始**，不是后训练量化（PTQ）。这意味着模型在训练时已经「知道」自己会被量化到 MXFP4，权重分布被调整过，避免了 PTQ 常见的精度坍塌问题。
2. **MXFP4 是 Open Compute Project 推动的微缩浮点格式**，4 bit 浮点。比 INT4 多了符号位、指数位和尾数位的组合，对模型权重的动态范围更友好。NVIDIA Hopper/Blackwell 架构对 MXFP 有原生硬件支持，理论上推理速度会比 INT4 快。
3. **MXFP8 activations** 比常见的 BF16/FP16 activations 还激进，这意味着前向传播时中间激活值也用 8 位浮点，显存压力显著下降。
4. **Broad hardware compatibility**——官方没有点名具体硬件，但 MXFP 的硬件支持正在快速扩展，NVIDIA H100/B100 之后的 GPU 基本都覆盖。

把 2.8T 总参的模型压到 MXFP4，权重体积大约在 1.4 TB 左右（2.8 × 10¹² × 4 bits ÷ 8 ≈ 1.4 TB），相比 BF16 的 5.6 TB 节省了 75% 显存。这对单机部署 8×H100/B100 节点来说门槛大幅降低——这也是 K3 在 README 第五节列出 vLLM / SGLang / TokenSpeed 三个推理引擎支持的原因。

## 四、Agentic 编码：1M 上下文怎么用起来

K3 在 README 第一节的 Key Features 里专门把 Long-Horizon Coding 拎出来讲：

> Operating with minimal human oversight, Kimi K3 sustains long engineering sessions, navigates massive repositories, and orchestrates terminal tools — from GPU kernel optimization and compiler development to vision-in-the-loop game dev, CAD, and even chip design.

这段话对应的不是单一 benchmark，而是一组 agentic 编码 benchmark（README 第三节）。K3 的几个关键 benchmark 成绩（按 README 表格，reasoning effort 设为 max）：

- **Terminal-Bench 2.1**：88.3（用 Kimi Code harness）
- **SWE-Marathon**：42.0（用 Claude Code harness）
- **BrowseComp**：91.2（300K tokens 触发的 context compaction 策略）
- **OSWorld-Verified**：84.8
- **AutomationBench**：30.8（600-task public subset）
- **AA-Briefcase**：1548 Elo

需要注意的是，README 的 footnote 里明确说了部分 benchmark 是用 H20 GPU 跑的（不是 H100），不同模型用的 harness 也不统一（K3 用 Kimi Code harness，Claude 系用 Claude Code harness，GPT 系用 Codex harness）——同榜单下不同模型跑出来的分数不能直接做绝对公平的比较，只能看相对趋势。但即使带着这些 caveat，K3 在 Terminal-Bench 2.1 上 88.3 这个数字确实跑赢了 Claude Opus 4.8（84.6）和 GPT-5.5（83.4），略输 GPT-5.6 Sol（88.8）。

K3 推荐用 [Kimi Code CLI](https://www.kimi.com/code) 作为 Agent 框架，通过 `/model` 命令切换。技术细节里有一个值得注意的设计：**K3 训练时用了「preserved thinking history mode」**，多轮对话必须把 `reasoning_content` 和 `tool_calls` 完整传回去，不能只传 `content`——这意味着 K3 的 CoT 是显式的、可审计的，对 Agent 框架的开发者来说意味着更高的可控性，但同时意味着对话 history 的 token 开销会显著放大。

## 五、开源策略：3T 级模型全量开放的产业意义

K3 这次开源有三件事值得专门讲：

### 5.1 自定义 Kimi K3 License

仓库既不是 MIT 也不是 Apache 2.0，而是自定义的 [Kimi K3 License](https://huggingface.co/moonshotai/Kimi-K3/blob/main/LICENSE)。HF 模型卡上的 `license_name` 字段写的是 `kimi-k3`。具体条款需要读 LICENSE 文件确认，但仓库 description 「Open Frontier Weights」和「making frontier intelligence openly available for research, deployment, and further innovation」的措辞说明月之暗面这次的态度是「真开源」而不是「象征性开源」。

### 5.2 推理引擎全链路支持

README 第五节明确列出了三个推理引擎的接入指南：

- [vLLM](https://recipes.vllm.ai/moonshotai/Kimi-K3)
- [SGLang](https://docs.sglang.io/cookbook/autoregressive/Moonshotai/Kimi-K3)
- [TokenSpeed](https://lightseek.org/tokenspeed)

vLLM 和 SGLang 是开源推理引擎的两个事实标准，TokenSpeed 是较新的轻量级引擎。三家同步出 recipes 比只给「理论支持」要更有诚意——开发者直接 clone recipes 就能跑起来。

### 5.3 API 兼容 OpenAI / Anthropic 协议

[platform.kimi.ai](https://platform.kimi.ai) 上可以直接选 `kimi-k3` 调用，API 兼容 OpenAI 和 Anthropic 协议。这意味着 Claude Code / Codex / Cursor 等 IDE 工具可以直接把 K3 接入替换底层模型，对国内开发者来说，这才是 K3 真正降低使用门槛的地方——不用学新 API 就能用上 3T 级开源模型。

### 5.4 国内大模型开源格局的拐点

把 K3 放在 2026 年的开源大模型坐标系里看：

- **DeepSeek-V3 / V4**：总参 ~670B / 1.6T，激活 ~37B，MIT 协议
- **Qwen3**：从 0.6B 到 235B 全尺寸开源，Apache 2.0 协议
- **Kimi K3**：2.8T 总参，Kimi K3 License

K3 的总参规模是 DeepSeek-V4 的近 2 倍，是 Qwen3-235B 的 12 倍。「国内首个开源 3T 级模型」这个标签意味着 K3 把开源旗舰模型的规模上限又往上推了一个台阶——对学术圈来说是研究样本，对工业圈来说是工程参考系。

## 一些不确定的地方

按写作惯例把没有完全核实的信息列出来：

- **KDA + AttnRes + Stable LatentMoE 的完整数学推导**：README 没给公式，需要看仓库里的 `k3_tech_report.pdf`。我没有下载这个 PDF（5MB+），上面的描述是基于 README 的定性总结，公式层面的细节可能不准确。
- **Kimi K3 License 的具体条款**：仓库 LICENSE 文件没有逐条读过。如果有商用限制、衍生模型条款、再分发条款，需要按 LICENSE 文本确认。
- **H20 vs H100 benchmark 差异**：README footnote 写得很清楚 K3 的部分 benchmark 是在 H20 GPU 上跑的（不是 H100），所以同榜单下 K3 和其他模型的直接对比需要打折看。
- **权重是否真的全部开源**：仓库 size 只有 5017 KB（GitHub API 元数据），这说明 GitHub 仓库本身只放了 README、PDF 和 logo，模型权重实际托管在 HuggingFace `moonshotai/Kimi-K3` 上。下载和分发需要按 HF 的条款走。

## 小结

K3 这次开源的真正信号不是「3T 参数」这个数字本身，而是三件事同时落地：

1. **架构上**用 KDA + AttnRes + Stable LatentMoE 给线性注意力 + MoE 找到了一个新的工程组合，scaling efficiency 比 K2 提升 2.5 倍。
2. **工程上**从 SFT 阶段就做 MXFP4 量化感知训练，让 2.8T 模型在 H100/B100 上的单机部署门槛降到合理范围。
3. **生态上**vLLM / SGLang / TokenSpeed 同步支持、API 兼容 OpenAI/Anthropic、Kimi Code CLI 同步发布——这意味着 K3 不是「发了就完了」，而是完整生态一起放出来。

对国内开源大模型圈来说，K3 的真正价值是把「3T 级模型全量开源 + 量化感知训练 + 多推理引擎支持」这三件事第一次组合在一起做到了工程可用的程度。

## 参考

- [MoonshotAI/Kimi-K3 (GitHub)](https://github.com/MoonshotAI/Kimi-K3)
- [moonshotai/Kimi-K3 (Hugging Face)](https://huggingface.co/moonshotai/Kimi-K3)
- [Kimi K3 Tech Blog](https://www.kimi.com/blog/kimi-k3)
- [Kimi K3 License](https://huggingface.co/moonshotai/Kimi-K3/blob/main/LICENSE)
- [vLLM Kimi K3 Recipes](https://recipes.vllm.ai/moonshotai/Kimi-K3)
- [SGLang Kimi K3 Cookbook](https://docs.sglang.io/cookbook/autoregressive/Moonshotai/Kimi-K3)