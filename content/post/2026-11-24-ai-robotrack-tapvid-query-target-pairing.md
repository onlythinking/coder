---
title: "一个完美跟踪器只能拿 50.93 分：Ai2 RoboTrack 评测配对错误复现，以及它对运动关键点时序评测的迁移"
date: 2026-11-24
description: "Ai2 在 2026-11-23 发布 RoboTrack 点跟踪基准与两个模型，并修复了 AllTracker 已发布评测代码里的一个配对错误。本文用官方标注与官方 TAP-Vid 指标复现这个错误：一个预测完全正确的 oracle 在配对错误时只有 50.93 AJ，而 8 个已发布跟踪器的分数全部落在这个区间内——光看分数无法发现这个 bug。文末给出迁移到运动分析关键点时序评测的具体做法与待验证项。"
tags:
  - 点跟踪
  - TAP-Vid
  - RoboTrack
  - 运动视觉
  - 姿态估计
  - 时序评测
  - 关键点跟踪
categories: ["AI"]
keywords: ["RoboTrack", "RoboTrack-Bench", "RoboTracker", "AllTracker", "TAP-Vid", "Average Jaccard", "AJ", "遮挡准确率", "OA", "查询帧", "配对错误", "脚踝关键点", "触地检测", "运动分析", "点跟踪评测"]
draft: false
toc: true
---

做运动分析的时候，我最怕的不是模型不准，而是**评测脚本算出一个看起来很正常的数字**。

脚踝、脚跟、脚尖这三个点在跑动视频里会拖影、被身体挡住、短暂出画。要评估「这个关键点被遮挡后能不能恢复」，你就得先定义清楚：什么时候开始算、从哪一帧算、遮挡的那几帧算不算错。这些都是评测口径的问题，跟模型没关系。

但口径写错的时候，你不会看到报错。你只会看到一个 AJ 60.2、OKS 0.71 这种正常数字，然后拿它去跟论文里的 0.78 比。

Ai2 在 2026 年 11 月 23 日发布的 [RoboTrack](https://allenai.org/blog/robotrack) 里，恰好提供了一个现成的例子：他们发现 AllTracker **已经发布**的评测代码有一个配对错误，并在自己的仓库里修掉了。本文用官方数据和官方指标把这个错误量出来，再说明它怎么迁移到运动关键点的时序评测。

## 一、这个 bug 的机制

先看 RoboTrack 的仓库怎么读标注。`robotrack/bench.py` 的 `load_clip` 从每个 clip 的 `point_tracks.npz` 里读三个数组：

- `trajs_2d`：`[T, N, 2]`，每个点的像素轨迹
- `visibility`：`[T, N]`，1 表示可见
- `query_frames`：`[N]`，每个点的**首次可见帧**

评测入口 `robotrack/evaluate.py`：

```python
query_frames = clip.visible.argmax(0)
query_xy = clip.tracks[query_frames, np.arange(clip.tracks.shape[1])]
tracks, vis_prob = track(clip.frames, query_xy, query_frames)
scores = tapvid_metrics(query_frames, ~clip.visible.T, clip.tracks.transpose(1, 0, 2),
                        (vis_prob < VIS_THRESHOLD).T, tracks.transpose(1, 0, 2), image_size)
```

关键在 `query_frames[i]` 和 `gt_tracks[i]` 用的是**同一个下标 i**：第 i 个查询点必须配第 i 条真值轨迹。指标 `robotrack/metrics.py` 里也是按 `i` 逐点算的，`after_query = arange(T) > query_frames[:, None]` 把查询帧之前的所有帧排除在外。

那原来的 AllTracker 是怎么错的？我去读了 AllTracker 上游的 `alltracker/tapvid_dataset.py`。在 `mode == 'first'` 分支里：

```python
for i, t in enumerate(self.targets[index]):
    query_frame_id = np.where(~t['occluded'])[0][0]
    query_frame_ids.append(query_frame_id)
    x, y = t['points'][query_frame_id]
    target_points.append(np.array([x, y]))
    target_occluded.append(t['occluded'])
```

`query_frame_ids` 和 `target_occluded` 是按 `self.targets[index]` 的顺序建的，但 `queries` 来自 `self.queries[index]`——**另一个列表**。到了 `alltracker/eval.py` 的 `evaluate()`，两者靠 `zip` 按下标对齐：

```python
for i, (pred, target, query_frame_id, occluded, visibility, area) in enumerate(
    zip(predictions, targets, query_frame_ids, target_occluded, target_visibility, target_area)):
```

只要一个 clip 里各个点的查询帧**不是按递增顺序排的**，查询列表和目标列表的下标就对不上，第 i 个查询点被拿去跟第 i 条**别的点**的轨迹比。

Ai2 自己在两处都写明了这件事：技术报告的注释说「我们修掉了它发布版评测代码里的一个打分 bug，所以我们的 AllTracker 分数和已发布的略有差异」；模型卡也写「AllTracker 原始代码在 clip 的点不按查询帧顺序时会把每个查询配错目标，所以它已发布的 DAVIS 数字和修正后的不同」。

## 二、我怎么把量级做出来

关键难点是：**配对错误到底让分数变了多少**。光说「有 bug」没有用，因为如果这个 bug 只让分数掉 0.3，那不值得写文章。

我的做法是构造一个 **oracle**：让「预测」直接等于真值。配对正确时，这个 oracle 必须拿满分——这是一个可证伪的锚点，如果它不是 100，说明我的实验装置本身有问题。配对错误时，分数的跌幅就**只可能**来自配对，不含任何跟踪误差。

跑法很轻：只下载标注（307 个 clip 一共 7.3 MB），**不需要视频、不需要模型权重、不需要 GPU**，指标直接用仓库里的 `robotrack/metrics.py` 原文件。

```python
gt_tracks = clip.tracks.transpose(1, 0, 2)          # [N, T, 2]
gt_occluded = ~clip.visible.T                       # [N, T]

# 配对正确：第 i 个查询配第 i 条目标
tapvid_metrics(query_frames, gt_occluded, gt_tracks,
               gt_occluded, gt_tracks, image_size)

# 配对错误：查询按查询帧排序（模拟上游的 zip 错位），真值列表保持标注顺序
order = np.argsort(query_frames, kind="stable")
tapvid_metrics(query_frames[order], gt_occluded, gt_tracks,
               gt_occluded[order], gt_tracks[order], image_size)
```

结果（307 个 clip 全量，脚本和输出在 `/home/hermes/sports-pose-eval/tools/robotrack_pairing/`）：

| 评测方式 | AJ | OA | <δ_avg> |
|---|---|---|---|
| oracle，配对正确 | **100.00** | 100.00 | 100.00 |
| oracle，配对错误 | **50.93** | 84.37 | 58.46 |

只在受影响的 clip 上看（199 个）：

| | AJ | <δ_avg> |
|---|---|---|
| 配对正确 | 100.00 | 100.00 |
| 配对错误 | **24.29** | 35.91 |

单个 clip 的跌幅最大能到 100 分（直接归零），最小也有 19.08 分。

触发条件在真实数据上非常普遍：

- 307 个 clip 里，**199 个（64.8%）** 的点不按查询帧顺序排列；
- 每个 clip 平均 8.2 个点、查询帧各不相同，**只有 108 个（35.2%）**恰好是递增的；
- 有 536/2522 个点（21.3%）的首次可见帧不是第 0 帧——它们在片段开头是看不见的。

## 三、最要命的地方：分数看起来很正常

这才是这个 bug 值得写文章的原因。

我拿 RoboTrack-Bench 模型卡上**已发布**的 8 个跟踪器分数，和「配对错误的 oracle」比：

| 模型 | 已发布 AJ |
|---|---|
| TAPNext | 55.06 |
| CoTracker3（离线） | 59.77 |
| BootsTAPNext | 60.15 |
| CoTracker3（在线） | 61.82 |
| AllTracker（已发布） | 62.56 |
| RoboTracker | 63.40 |
| CoWTracker（已发布） | 63.87 |
| RoboTracker-Warp | 65.98 |

**8 个全部落在配对错误 oracle 的分数区间内**（该区间是 0.00–100.00，均值 50.93）。

也就是说：一个预测完全正确的模型，因为配对错了，拿到 50.93 分；而一个真实的、明显有跟踪误差的模型，拿到 60.15 分。**你从分数上看不出哪个是 bug、哪个是模型**。唯一能说明问题的是 oracle 这个参照物——而这恰恰是你在正常评测里不会有的东西。

顺带一个交叉验证：我从标注里独立算出的统计量，和技术报告附录 A 的数字几乎完全一致：

| 指标 | 我从标注算出 | 论文附录 A |
|---|---|---|
| clip 数 | 307 | 307 |
| 每 clip 平均帧数 | 223.0（26–785） | 223（26–785） |
| 每 clip 平均轨迹数 | 8.21 | 8.2 |
| 轨迹总数 | 2,522 | 2,522 |
| 查询帧非第 0 帧的轨迹占比 | 21.3% | 「79% 在首帧被查询」（即 21% 不是） |
| 查询帧后平均被遮挡帧占比 | 22.5% | 22% |
| 消失后重新出现的轨迹占比 | 38.7% | 39% |

所以我的标注加载和统计逻辑是对的，量出来的分数跌幅不是装载错误。

## 四、迁移到运动关键点的时序评测

上面是机器人场景。但运动分析要处理的问题结构是一样的：**一个点（关键点）在时间上的一条轨迹，被一段遮挡打断，之后可能恢复**。

我做了一个运动场景的最小复现（**合成的 60 帧片段，3 个关键点**）：

- `left_ankle`：从第 0 帧可见
- `right_ankle`：从第 12 帧才可见（前面出画）
- `left_knee`：第 25–32 帧被身体挡住

预测**完全等于真值**，用同一个官方指标打分：

| | AJ | OA | <δ_avg> |
|---|---|---|---|
| 配对正确 | **100.00** | 100.00 | 100.00 |
| 配对错误 | **24.18** | 83.64 | 40.41 |

配对错误时，评测把右脚踝的轨迹拿去跟左膝的真值比——三个槽位全部拿 24.18 分。

顺带一个灵敏度对照：配对正确时，预测整体平移 1 像素，AJ 就从 100 掉到 80；平移 16 像素直接归零。这说明指标本身是正常工作的，**分数的崩塌来自配对，不是来自阈值**。

那对运动分析具体意味着什么？三条可以直接抄的做法：

**一、查询帧必须逐点独立算，不能整段共用。**
RoboTrack 的 `query_frames = clip.visible.argmax(0)` 是对**每个点**取首次可见帧。运动场景里对应的是：这个关键点的第一个可信检测出现在哪一帧。如果脚踝在第 0 帧就出画、到第 12 帧才重新出现，那第 12 帧之前根本不该算分——既不该算对，也不该算错。

**二、排序任何一边之前，先确认另一边跟着动了。**
配对错误几乎都长这样：一边 `sorted()` 或 `argsort()` 了，另一边没跟着动。在你的代码里找这类地方：

```python
# 危险写法：只排了一边
tracks = sorted(tracks, key=lambda t: t.query_frame)
gt     = load_gt()                       # 没跟着排
scores = evaluate(tracks, gt)            # 静默错位

# 安全写法：排序时把配对键一起搬
pairs = sorted(zip(tracks, gt), key=lambda p: p[0].query_frame)
scores = evaluate(*zip(*pairs))
```

**三、用 oracle 当自检。**
这是最省事的防线：在你的评测脚本里加一个「预测 = 真值」的分支，它必须拿满分。不满分就说明评测本身有 bug，而不是模型不行。这一步花十几行代码，但它能在每次改动评测逻辑后立刻抓出错位。

**四、遮挡帧单独看，别只看一个总分。**
AJ 会把遮挡预测错误和位置误差混在一个数里。RoboTrack 单独报 OA（遮挡准确率），你这边也应该把「遮挡期间有没有乱画」和「可见时位置准不准」分开报。对运动分析尤其重要：脚踝在触地瞬间被拖影糊掉，和脚踝位置差 3 像素，是两回事。

## 五、局限与待验证

说清楚哪些是我实测的，哪些不是。

**已实测（本机跑通，输出可复现）**：

- 官方标注 + 官方指标下的 oracle 锚点与配对错误跌幅（307 clip 全量，AJ 100.00 / 50.93 / 24.29）；
- 触发率（199/307 clip）、查询帧与遮挡统计，并与论文附录 A 对齐；
- 运动场景合成片段的迁移复现（AJ 100.00 → 24.18）。

**未实测，列为待验证**：

- **没有跑过真实的跟踪器**。我没有下载 `robotracker.pth`，也没有跑 `robotrack.eval_alltracker`。因此「已发布的 8 个分数落在错配 oracle 区间内」是**区间包含关系**，不是「这些模型就是被这个 bug 评出来的」。上游到底错配了哪些 clip、错配比例多少，我没有直接观测。
- **复现的是机制，不是上游那份历史代码的逐行行为**。我按 RoboTrack README 与模型卡的描述，构造了「查询按查询帧排序、真值保持标注顺序」这种错位。我确认了上游 `tapvid_dataset.py` 里 `queries` 与 `targets` 来自两个独立列表、且在 `evaluate()` 里靠 `zip` 对齐，但没有把上游那份代码原样跑一遍来对比每 clip 的分数。
- **合成片段不是真实跑者视频**。运动场景那 60 帧是我构造的，用来说明评测侧的机制；真实跑动视频上的遮挡模式（拖影、半遮挡、离画再入画）比这复杂得多。
- **RoboTrack-Bench 的视频没下载**。它有 42 个 Ego-Exo4D clip 需要单独从 Ego-Exo4D 获取（有许可门槛），所以我全程只用标注，没碰视频。完整跑官方评测时 `bench.list_clips` 会因为缺视频报错，除非加 `--skip-missing-egoexo4d`（但那样分数就不能和论文比了）。
- **RoboTrack-Bench 的完整评测还需要模型权重**：`RoboTracker` 是 Apache-2.0（17M 参数），`RoboTracker-Warp` 是 CC-BY-NC-4.0（非商用，974M 参数）。Warp 还要额外装 CoWTracker 的代码和 `xformers==0.0.34` 等重依赖，本机没装。

**这条选题跟 sport-analysis 的关系**：Hummingbird AI 现在的田径 20 米途中跑和 20 米单视频跳远，评估的都是关键点位置误差（逐关节 RMSE、遮挡分层），还没有做「跨帧身份连续性」这一层。点跟踪这套指标（AJ / OA / <δ_avg>）正好补的是**身份连续性**：一个关键点在被遮挡前后是不是同一个点。这件事对触地／离地检测有直接影响——如果遮挡后认错了点，算出来的 TD/TO 帧就是错的。

**下一步要验证的问题**（还没做）：

1. 在真实的 20 米途中跑视频上，把「脚踝关键点的跨帧身份」用点跟踪的方式跑一遍，看 AJ / OA 落在什么区间，能不能和逐关节 RMSE 对上；
2. 脚踝出画再入画（跑动中常见的遮挡）时，点跟踪的恢复行为和姿态模型的插值行为差多少；
3. 用第 1 条的数据反推：TD/TO 事件的帧定位误差，有多少来自「认错点」而不是「位置偏」。

## 六、这次发布了什么

- **RoboTrack-Bench**：307 个真实操作视频片段，来自 DROID、Ego-Exo4D、MolmoAct 2、EgoVerse，共 2,522 条人工标注点轨迹，每帧标过、双人复核。含 33 对双视角同步片段。
- **RoboTrack-15M**：用 MolmoSpaces 仿真器生成的 3,000 段视频、1,500 万条点轨迹，用于微调。许可证 ODC-By。
- **RoboTracker**：AllTracker（17M 参数）微调，Apache-2.0。
- **RoboTracker-Warp**：CoWTracker（约 974M 参数）微调，CC-BY-NC-4.0，非商用。
- **代码**：`allenai/robotrack`，Apache-2.0（内含 MIT 的 AllTracker 与 FAIR 非商用许可的 CoWTracker）。

官方评测口径是 TAP-Vid 的 "first" 模式：每个点在首次可见帧被查询，只评之后的帧；坐标按 TAP-Vid 归一化到 256×256；可见性阈值 0.6（`vis_prob >= 0.6` 算可见）。

## 一手来源

- [RoboTrack 官方博客 - Ai2](https://allenai.org/blog/robotrack)
- [技术报告 PDF - RoboTrack: Point Tracking for Real-World Robotic Manipulation](https://allenai.org/papers/robotrack)
- [代码仓库 - allenai/robotrack](https://github.com/allenai/robotrack)
- [官方评测与指标 - robotrack/metrics.py 与 robotrack/evaluate.py](https://github.com/allenai/robotrack/blob/main/robotrack/metrics.py)
- [RoboTrack-Bench 数据集卡 - 含已发布分数表与评测协议](https://huggingface.co/datasets/allenai/RoboTrack-Bench)
- [RoboTracker 模型卡 - 含协议与许可说明](https://huggingface.co/allenai/RoboTracker)
- [RoboTracker-Warp 模型卡 - 非商用许可与参数对比](https://huggingface.co/allenai/RoboTracker-Warp)
- [RoboTrack-15M 数据集卡](https://huggingface.co/datasets/allenai/RoboTrack-15M)
- [上游 AllTracker TAP-Vid 评测脚本 - test_dense_on_sparse.py](https://github.com/aharley/alltracker/blob/master/test_dense_on_sparse.py)
- [上游 AllTracker TAP-Vid 指标实现 - utils/misc.py 的 compute_tapvid_metrics](https://github.com/aharley/alltracker/blob/master/utils/misc.py)
- [TAP-Vid 指标参考实现 - google-deepmind/tapnet](https://github.com/google-deepmind/tapnet)
