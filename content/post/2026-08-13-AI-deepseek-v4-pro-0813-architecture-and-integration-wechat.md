---
title: "0813 跃迁"
date: 2026-08-13
description: "V4 Pro 0813: MIT 开源 + 1M 上下文 + Pro Max 实战"
tags: ["DeepSeek", "V4 Pro", "开源大模型", "Hybrid Attention", "AI 编程"]
categories: ["AI"]
keywords: ["DeepSeek V4 Pro 0813", "Hybrid Attention", "CSA HCA", "Manifold-Constrained Hyper-Connections", "Muon Optimizer", "1M 上下文", "MIT 开源", "OpenRouter", "Pro Max 推理档位", "code agent"]
draft: false
toc: true
readingTime: 11
cover: /images/covers/deepseek-v4-pro-0813-architecture-and-integration.svg
---

DeepSeek 在 2026-08-13 静默推送了 DeepSeek-V4-Pro 0813 更新版，主帖 HN id 49274600 一夜拿下 722 分、274 条讨论，但与 4 月 V4 Pro 初版 那次不同，评论区少了几分"哇这模型变了"的新鲜感，多的是"参数翻 6 倍、KV cache 砍 9 成，这怎么做到的"的技术追问。另一条 "quietly released" 帖 78 分更像是社区在替官方做版本说明。HN 热度没拉满的真相是：这是一次架构重做，不是又一个聊天机器人版本号——它瞄准的是编码 Agent 与长代码仓库这两个还没有被任何开源模型打透的场景。

## 一、和 4 月初版的版本区别

先把版本时间线对齐，否则后面的对比没意义。4 月 25 日写过的 《V4 Pro 初版社区体验》 是 261B 总参 / 41B 激活 / 512K 上下文 / 18.2T 训练 tokens；0813 这个更新版直接把总参推到 1.6T、激活 49B、上下文拉到 1M、训练数据扩到 32T tokens——参数量 6.1 倍、上下文 2 倍、训练数据 1.76 倍，但激活参数只增加约 20%，属于典型的 MoE"扩总参不动激活"思路。

这次更新的核心信号可以归纳为三件事：

- 架构层引入 **Hybrid Attention (CSA + HCA)**、**mHC 残差**、**Muon 优化器**三件套，把 1M 上下文下的推理 FLOPs 压到 V3.2 的 27%、KV cache 压到 V3.2 的 10%。
- 推理档位从两档扩到三档，新增 **Pro Max / Think Max**，在 LiveCodeBench、Codeforces、SWE Verified 上对 Opus-4.6 Max、Gemini-3.1-Pro High 形成编码类领先。
- API 定价从初版 $1.168/M input 直降到 **$0.435/M input、$0.87/M output**，整体降幅约 62.8%（OpenRouter 实测数据，定价以官方为准）。

下面分别展开。

## 二、架构重做：Hybrid Attention + mHC + Muon 三件套

这一节给非架构读者一个通俗解释，给做架构的读者抓三个关键数字。

### 2.1 Hybrid Attention：CSA + HCA 双注意力混合

标准的 Transformer 自注意力的复杂度是 O(n²)，上下文越长显存与计算都吃不消。0813 版模型卡描述的 Hybrid Attention 走的是「同一层里叠两种注意力」路线：

- **CSA（Compressed Sparse Attention，压缩稀疏注意力）**：对长距离上下文做稀疏采样，只保留信息量最高的 key/value 分块。
- **HCA（Heavily Compressed Attention，重压缩注意力）**：在 KV cache 上做更激进的有损压缩，把"有用但可以模糊"的远距离 token 进一步压扁。

把 CSA 当骨架、HCA 当压缩层嵌进去，效果上能做到 1M 上下文下推理 FLOPs 仅 V3.2 的 27%、KV cache 仅 V3.2 的 10%（模型卡披露值）。通俗讲：不是把 1M token 全部塞进标准自注意力，而是先压缩再算稀疏——这是 1M 上下文能真正落地到生产推理的关键，否则光 KV cache 就得吃光 H100 的显存。

### 2.2 mHC：约束在流形上的残差连接

**Manifold-Constrained Hyper-Connections（mHC，约束在流形上的 Hyper-Connections）** 是这次新引入的残差连接改进。Transformer 默认的残差连接 `y = x + f(x)` 在层数堆深之后信号会被稀释或爆炸，mHC 的做法是把残差映射到的残差项约束在一个低维流形上，让每层的输入信号方差可控。这是支撑 1.6T 总参、92+ 层训练收敛稳定的基础设施，否则光初始化噪声就会让 deep ResNet 出现信号坍塌。

### 2.3 Muon Optimizer：用矩阵正交化换收敛速度

第三个组件是 **Muon Optimizer**——一种把 update step 朝正交化方向做约束的优化器（区别于 AdamW 的逐元素自适应）。社区里对它的讨论主要集中在两点：收敛更快、训练更稳，特别适合 MoE 这种激活稀疏的场景。把三件套放在一起：Muon 让训练稳、mHC 让深度信号稳、CSA+HCA 让推理显存省。这就是 0813 版可以做到「总参涨 6 倍、激活只涨 20%、上下文涨 2 倍」同时训练成本没有失控的工程基础。

## 三、Pro Max 推理档位 vs Frontier Models：真实位置

0813 版把推理档位从初版的两档扩到三档：**Non-think（日常快速）、Think High（复杂问题规划）、Think Max / Pro Max（推理极限）**。三档之间的差别主要在「是否启用 thinking tokens」「思考链长度上限」「是否启用自我一致性采样」。下面这张表把 Pro Max 与当前 Frontier 模型在公开 benchmark 上的位置一次摊开（数字均来自各模型公开技术报告，源数据以官方为准）：

| Benchmark | DeepSeek V4 Pro Max | Opus-4.6 Max | GPT-5.4 xHigh | Gemini-3.1-Pro High |
| --- | --- | --- | --- | --- |
| LiveCodeBench Pass@1 | **93.5** | 88.8 | — | 91.7 |
| Codeforces Rating | **3206** | — | 3168 | — |
| SWE Verified Resolved | 80.6 | 80.8 | — | 80.6 |
| SWE Multilingual Resolved | 76.2 | — | — | — |
| Terminal Bench 2.0 | 67.9 | 65.4 | 75.1 | — |
| Toolathlon Pass@1 | 51.8 | — | 54.6 | — |
| HMMT 2026 Feb | 95.2 | — | 97.7 | — |
| IMOAnswerBench | 89.8 | — | 91.4 | — |
| Apex Pass@1 | 38.3 | — | — | 60.9 |
| MRCR 1M MMR | 83.5 | **92.9** | — | — |
| CorpusQA 1M ACC | 62.0 | **71.7** | — | — |
| MCPAtlas Public Pass@1 | 73.6 | 73.8 | — | — |
| GDPval-AA Elo | 1554 | — | 1674 | — |

把表格拆成三个象限更直观：

**编码类领先**：LiveCodeBench 93.5（高于 Opus-4.6 Max 88.8、Gemini-3.1-Pro High 91.7）、Codeforces 3206（高于 GPT-5.4 xHigh 3168）、SWE Verified 80.6 与 Gemini 并列第二、仅落后 Opus 0.2 分。这三项基本对应日常 Code Agent 在「读 PR、写补丁、解竞赛题」三个维度上的能力，Pro Max 已经站在第一梯队。

**数学与逻辑类中规中矩**：HMMT 95.2 vs 97.7、IMOAnswerBench 89.8 vs 91.4，差距 2-3 个百分点——能用，但不像编码类那样跨级领先。

**长上下文检索与复杂 Agentic 类落后**：MRCR 1M 83.5 对 Opus-4.6 Max 的 92.9 差 9.4 分、CorpusQA 1M 62.0 vs 71.7 差 9.7 分、Apex 38.3 vs Gemini 60.9 差 22.6 分。这三项恰恰对应「从百万 token 里精准捞一根针」「多跳多工具的复杂 Agent 任务」——前者是 Hybrid Attention 在远距离压缩上的固有损失，后者是大模型在多步规划上的稳定性差异。换句话说，Pro Max 不是「通杀 Frontier」，它赢在编码、输在长上下文检索与复杂 Agent。

## 四、1M 上下文对开发者的实际意义

把 1M 上下文讲成「能装更多历史」是废话层面。开发者社区真正关心的是它能解锁什么场景：

- **代码仓库级上下文**：一个中型 Python 后端服务（200-500 文件、含文档与配置）token 化后大约 80-300K，普通 200K 上下文的 Sonnet/GPT-5 经常要在「读全文」和「分块 + 检索」之间二选一；1M 上下文让"一次性读整个仓库"成为默认路径，减少分块带来的逻辑断裂。
- **Cursor / Claude Code / Codex 改造方向**：编辑器侧的 IDE context 一直在从 RAG 向「全量注入 + 摘要回收」演进，1M 上下文让"项目级 system prompt"成为可能——把整个 monorepo 的 README、CI 配置、CLAUDE.md、AGENTS.md、tsconfig 一次塞进去，配合 mHC 的信号稳定性，Agent 在跨文件修改时不再频繁"忘记自己在改哪一个模块"。
- **实战案例 DeepClaude**：HN 上 678 分的 aattaran/deepclaude 把多模型串联——DeepSeek 负责长上下文沉淀（读仓库、写 patch）、Claude 负责最终 review——这种分工之所以成立，正是因为 DeepSeek 一边可以把 1M 上下文用 $0.435/M 跑满，一边把"推理极限"的活留给 Claude。

但要注意：1M 不是 100% 等价于"全部进注意力"。CSA 决定了远距离 token 的注意力权重天然稀疏，HCA 会丢弃一些低信息密度 token。1M 是"能装 1M"，不是"能在 1M 上做精细 needle-in-haystack"——这正是 MRCR 1M 上 9.4 分差距的来源。如果你的场景是「找代码里某个特定变量的所有用法」，RAG 仍是更稳的选择；如果你的场景是「给我整个仓库做一次架构 review」，1M 全量注入的体感会好很多。

## 五、定价 $0.435 / M 改变了什么

API 定价数字来自 OpenRouter 实际快照（定价以官方为准）：

| 模型 | Input $/M | Output $/M | 相对 V4 Pro 0813 |
| --- | --- | --- | --- |
| DeepSeek V4 Pro 0813 | **0.435** | **0.87** | 基准 |
| DeepSeek V4 Pro（旧） | 1.168 | 2.336 | 旧版高 168% |
| DeepSeek V4 Flash 0731 | 0.08 | 0.18 | Flash 便宜 81% |
| Opus-4.6 Max（参考） | ~15 | ~75 | 约 35 倍 |
| GPT-5.4 xHigh（参考） | ~5 | ~25 | 约 12 倍 |

定价的改变体现在两个层面：

**自部署 vs API 的临界点后移**。1.6T 总参即便按 INT4 量化、单卡 24GB 显存也需要约 80 张 H100/MI300 级别的卡才能跑推理（实际取决于并行策略与 KV cache 压缩比例）。月均电费 + 折旧大约在 6-8 万美元区间。对一个日均消耗 5000 万 token 的中型 Code Agent 服务，API 成本估算：5000 万 × $0.87 / 100 万 = $43.5/天的纯 output 成本，加 input 大约 $65/天，月 $2000 量级——只有自部署的 1/30。这意味着 ROI 拐点进一步后移，中小团队基本不需要再考虑自部署 1.6T 的版本，配合 OpenRouter 这类聚合网关按需调用更划算。

**编码 Agent 成本结构变化**。Code Agent 的典型场景是「读仓库 + 生成 patch + 跑测试 + 修改」多轮循环，单任务 input/output 比例大约 8:1。在新定价下，单任务成本从旧版的约 $0.13 降到 $0.05，按月跑 10 万次任务年度成本从约 $15.6 万降到 $6 万——这正是 HN 评论里很多人开始认真评估「用 DeepSeek 做主力模型、用 Frontier 做 review 模型」分层方案的财务基础。

## 六、接入指南：Python 实操四段

### 6.1 OpenAI 兼容基础调用

DeepSeek API 兼容 OpenAI SDK，最简单的接入方式是 `openai.OpenAI(base_url=...)`：

```python
from openai import OpenAI

client = OpenAI(
    api_key="<DEEPSEEK_API_KEY>",
    base_url="  # 或 
)

resp = client.chat.completions.create(
    model="deepseek/deepseek-v4-pro-0813",  # OpenRouter ID；官方直连为 deepseek-v4-pro
    messages=[
        {"role": "system", "content": "你是一个严谨的 Python 后端工程师。"},
        {"role": "user", "content": "用 FastAPI 写一个支持分页的 /users 接口。"},
    ],
    temperature=0.2,
    max_tokens=2048,
)
print(resp.choices[0].message.content)
```

### 6.2 三档推理档位切换

0813 版的核心控制参数是 `reasoning_effort`（OpenRouter 与官方 API 都支持），三档分别对应快速、长思考、极限推理：

```python
def ask(prompt: str, effort: str = "medium") -> str:
    """effort: 'low'(Non-think) | 'medium'(Think High) | 'high'(Think Max)"""
    resp = client.chat.completions.create(
        model="deepseek/deepseek-v4-pro-0813",
        messages=[{"role": "user", "content": prompt}],
        reasoning_effort=effort,          # low / medium / high
        temperature=0.2 if effort == "low" else 0.5,
        max_tokens=4096 if effort == "high" else 1024,
    )
    return resp.choices[0].message.content

# 日常对话用 Non-think
print(ask("用两句话解释 MoE 路由", effort="low"))

# 重构任务用 Think High
print(ask("把这段 Python 用依赖注入重构", effort="medium"))

# 复杂 Bug 定位用 Think Max（贵但准）
print(ask("分析我仓库里这段 race condition 的根因", effort="high"))
```

### 6.3 1M 长上下文对话管理

1M 上下文的实际工程难点不是"塞进去"而是"如何不让早期上下文被稀释"。下面这段展示了摘要回收 + 关键 snippet 注入的混合模式：

```python
class LongContextChat:
    """1M 长上下文对话管理：滑动窗口 + 摘要回收 + 关键代码注入。"""

    def __init__(self, repo_root: str, max_tokens: int = 900_000):
        self.client = client
        self.max_tokens = max_tokens
        self.files = self._index_repo(repo_root)        # 读取所有源文件
        self.summary = ""                                 # 历史摘要
        self.key_snippets: list[str] = []                 # 显式关注的代码片段

    def _index_repo(self, root: str) -> dict[str, str]:
        out = {}
        for path in Path(root).rglob("*.py"):
            out[str(path)] = path.read_text()
        return out

    def ask(self, question: str, focus_files: list[str] | None = None) -> str:
        # 1. 显式注入 focus 文件全文
        focus_block = "\n\n".join(
            f"=== {p} ===\n{self.files[p]}" for p in (focus_files or [])
        )

        # 2. 历史摘要 + 当前问题
        msgs = [
            {"role": "system", "content": f"前情摘要：{self.summary}"},
            {"role": "user", "content": f"{focus_block}\n\n---\n\n{question}"},
        ]

        # 3. 用 Think High 跑
        resp = self.client.chat.completions.create(
            model="deepseek/deepseek-v4-pro-0813",
            messages=msgs,
            reasoning_effort="medium",
            max_tokens=4096,
        )
        answer = resp.choices[0].message.content

        # 4. 把本轮压缩成摘要回收
        self.summary = self._summarize(self.summary, question, answer)
        return answer

    def _summarize(self, prev: str, q: str, a: str) -> str:
        # 用 Non-think 做一次摘要回收，避免长期上下文爆炸
        ...
```

### 6.4 流式输出 + 工具调用（Function Calling）

Code Agent 场景里几乎一定要做流式 + 工具调用。下面这段把 SSE 流、tool call 解析、本地工具执行串成一条链：

```python
import json

tools = [
    {
        "type": "function",
        "function": {
            "name": "read_file",
            "description": "读取仓库中指定文件的全文。",
            "parameters": {
                "type": "object",
                "properties": {"path": {"type": "string"}},
                "required": ["path"],
            },
        },
    },
]

def stream_with_tools(prompt: str) -> None:
    stream = client.chat.completions.create(
        model="deepseek/deepseek-v4-pro-0813",
        messages=[{"role": "user", "content": prompt}],
        tools=tools,
        reasoning_effort="high",
        stream=True,
    )

    tool_calls = []
    for chunk in stream:
        delta = chunk.choices[0].delta
        if delta.content:
            print(delta.content, end="", flush=True)
        if delta.tool_calls:
            tool_calls.extend(delta.tool_calls)

    # 解析后执行本地工具
    for call in tool_calls:
        if call.function.name == "read_file":
            args = json.loads(call.function.arguments)
            print(f"\n[tool] read_file({args['path']})")
            print(Path(args["path"]).read_text()[:500])
```

## 七、结论

0813 这次更新的信号不是「又一个版本号」，而是MIT 开源开源前沿模型在编码类任务上已经不输闭源、但长上下文检索与复杂 Agentic 仍有差距——Pro Max 在 LiveCodeBench / Codeforces / SWE Verified 上领先 Frontier，在 MRCR 1M / CorpusQA 1M / Apex 上又明显落后，对开发者来说这意味着分层策略比"找一个通杀模型"更现实：用 DeepSeek V4 Pro 0813 跑主力、用 Opus-4.6 Max / GPT-5.4 xHigh 兜底长上下文检索，用 OpenRouter 这类网关按需调度，是接下来几个月最稳妥的工程组合。

如果你关心编码 Agent 成本结构，或者正在评估把主力模型从闭源换到开源，0813 这版值得认真跑一遍 benchmark 再下结论；如果你的核心场景是百万 token 级的精准检索，至少再等一个版本，等 MRCR 1M 回到 90 分以上再考虑全量切。HN 评论区那句「quietly released」反而是这次最准确的描述——没有什么营销辞藻，而是开源前沿模型一次正常但重要的工程迭代。

---

**参考链接**

- DeepSeek-V4-Pro 模型卡：huggingface.co/deepseek-ai/DeepSeek-V4-Pro
- OpenRouter 模型页：openrouter.ai/deepseek/deepseek-v4-pro-0813
- 主 HN 帖：news.ycombinator.com/item?id=49274600
- quietly released 帖：news.ycombinator.com/item?id=49275114
- 官方 API 文档：api-docs.deepseek.com
- 技术报告 arXiv：arxiv.org/abs/2606.19348

**内链**

- 《V4 Pro 初版社区体验（2026-04-25）》
- 《Kimi K3 拆解：3T 级开源 MoE 量化（2026-08-05）》

**分享到**： Twitter · Hacker News · 微博

---

如果觉得有帮助，欢迎在评论区聊聊你的接入体验。
关注公众号「编程码农」，第一时间收到后续技术解析。
