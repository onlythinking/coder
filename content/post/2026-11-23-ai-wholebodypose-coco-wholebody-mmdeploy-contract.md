---
title: "把 133 点全身姿态接进离线分析链路：WholeBodyPose 2.1.0 实测，以及一个会静默清空检测结果的输入契约坑"
date: 2026-11-23
description: "WholeBodyPose 2.1.0 在 2026-11-22 发布，给 RTMW 全身姿态加了 macOS CoreML 后端，v2.0.3 还修掉了一个「装了 CUDA 却静默跑在 CPU 上」的降级。本文用 PyPI 发布包做 wheel 级 diff 核对该修复，在本机跑通 133 点全身姿态并量出「每多一个人多 107 毫秒」的真实成本，同时复现了一个更隐蔽的坑：mmdeploy 导出的 end2end.onnx 输入契约藏在 pipeline.json 里，多除一次 255 会让检测器永远返回空结果。"
tags:
  - WholeBodyPose
  - 全身姿态
  - ONNX Runtime
  - mmdeploy
  - 运动视觉
  - 端侧推理
categories: ["AI"]
keywords: ["WholeBodyPose", "COCO-WholeBody", "RTMW", "ONNX Runtime", "mmdeploy", "end2end.onnx", "pipeline.json", "姿态估计", "脚部关键点", "运动分析", "CoreML", "preload_dlls"]
draft: false
toc: true
---

做运动分析的时候，踝以下是关键点里最要紧的一段。脚跟、脚尖、大脚趾这三个点直接决定「触地」和「离地」发生在哪一帧，也决定落地缓冲的关节角度能不能算出来。

COCO 的 17 点不够用。26 点 Halpe 和 133 点 WholeBody 都补了脚，但**两者的脚部索引顺序不一样**，把两个模型的输出直接拼起来会静默错位——不报错，只是脚踝以下全错。

[WholeBodyPose](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation) 是最近把这件事做干净的一个项目：所有后端统一输出 COCO-WholeBody 的 133 点，**脚部固定在 17–22**（17 左大脚趾、18 左小脚趾、19 左脚跟、20 右大脚趾、21 右小脚趾、22 右脚跟），索引写在 `docs/guide/keypoints.md` 里，可以照着对齐。

本文我在本机装了包、跑了数据，核对到发布包级别。要先说清楚：**官方性能数字是作者自测，我没有在他们的硬件上复现**；我自己量的是另一台机器、另一套输入，两者不可直接比较。

## 一、v2.1.0 到底变了什么

- **发布日期**：GitHub Release `v2.1.0` 发布于 2026-11-22T12:59:40Z，PyPI `wholebodypose` 2.1.0 上传于 2026-11-22T13:04:28Z。同日还有 v2.0.3、v2.0.2、v2.0.1；v2.0.0 是前一天。
- **v2.1.0**：新增 macOS CoreML 后端（`device="coreml"`），`device="auto"` 在 CUDA 之后优先选 CoreML。RTMW 与 YOLOX 都上 CoreML，其中 YOLOX 导出成 ML Program——因为它的 NMS 在 NeuralNetwork 格式下会失败。ViTPose 仍留在 CPU，作者说那里更快。另加 `examples/webcam.py`。
- **v2.0.3**：`wholebodypose video --tracking` 走 MediaPipe VIDEO 模式；新增 `benchmarks/` 目录，把测速脚本、CPU／GPU 原始 JSON 和图表一起提交；`[gpu]` extra 改成装 `onnxruntime-gpu[cuda,cudnn]>=1.21`。
- **v2.0.0 是破坏性更新**：ViTPose 只走 ONNX Runtime，RTMPose 移除 rtmlib 与 OpenCV／OpenVINO 后端，`wholebodypose.models.vitpose.model.onnx_weight_key` 等一批属性被删除。

## 二、一个静默降级：装了 CUDA 却跑在 CPU 上

v2.0.3 的修复项里有一条特别值得记：**用 pip 安装 CUDA 与 cuDNN 包时，请求 CUDA 会静默落到 CPU。** 模型能跑、结果能出、也不报错，只是慢了十几倍。

我按发布包级别核对了这个修复，没有只看源码仓库的 main 分支：

1. 从 PyPI 分别下载 `wholebodypose` 2.0.2 与 2.0.3 的 wheel；
2. 解包对比 `wholebodypose/models/onnx_session.py`；
3. 2.0.2 没有任何预加载逻辑；2.0.3 新增 `_load_cuda_libs()`，在 `providers[0] == "CUDAExecutionProvider"` 时、**创建 InferenceSession 之前**调用 `onnxruntime.preload_dlls()`，并用 `contextlib.suppress(Exception)` 包住，失败不影响建 session；
4. 本机 onnxruntime 1.32.0 确认存在 `preload_dlls` 这个 API。

机制不难理解：pip 装的 CUDA 库躺在 site-packages 里，ONNX Runtime 不会自动去那里找，于是 provider 初始化失败并回落 CPU；`preload_dlls()` 负责告诉它去哪里找。

**教训**：这类降级不会自己暴露。要确认自己在 GPU 上跑，得看 session 的第一个 provider 是什么，而不是看请求参数写了什么。

## 三、官方怎么公布性能（这部分值得学）

`benchmarks/results/` 下的原始 JSON 是直接提交进仓库的，每个文件带一段 meta：设备、线程数、输入图、帧尺寸、帧数、ONNX Runtime 版本、Python 版本。

以 CPU 那份为例：8 线程、640×853 单帧、50 帧、onnxruntime 1.32.0、Python 3.11.17。官方自测的中位数：`rtmpose` lightweight 151.18 ms（6.61 fps）、balanced 276.58 ms、performance 307.21 ms；ViTPose+ huge 配 YOLOX-m 652.81 ms（1.53 fps）；MediaPipe body-only 加 tracking 19.21 ms（52.06 fps）。

**把原始 JSON 一起提交，比贴一张截图有用得多**——读者能自己换机器重跑，也能看到 p10／p90 而不只是中位数。

## 四、我的本机实测：背景里的人数是真实成本

环境：2 核 AMD EPYC 7K62，onnxruntime 1.32.0，只有 CPU provider；后端 `rtmpose` 模式 `lightweight`（YOLOX-tiny 416×416 ＋ RTMW-m 256×192）。

输入是本机项目里 5 张运动帧（476×268）。它们来自一段场地自行车比赛视频 `track_sprint.ogv`（24 fps，2698 帧），我用逐帧解码核对过源帧号：第 120、480、960、1440、1920 帧——**文件名里的 5／20／40／60／80 不是视频帧号**，这个坑我一开始也踩了。

计时边界：**单帧、前向＋后处理、10 次取中位数、另有 3 次预热、不含模型加载**。

| 帧 | 检出人数 | 中位耗时 | 折算 |
| --- | --- | --- | --- |
| sprint_40 | 1 | 292.6 ms | 3.42 fps |
| sprint_60 | 1 | 295.2 ms | 3.39 fps |
| sprint_80 | 1 | 292.7 ms | 3.42 fps |
| sprint_5 | 12 | 1479.1 ms | 0.68 fps |
| sprint_20 | 14 | 1683.8 ms | 0.59 fps |

两点观察：

**第一，每多一个人约多 107 毫秒。** 1 人 292.6 ms，12 人 1479.1 ms，14 人 1683.8 ms，两段区间算出来都是 107～108 ms/人。RTMPose 是 top-down 的，每个人都要单独过一次网络。比赛现场背景里的观众、工作人员、器材手，全都进这个成本。**如果链路只要前景那一个人，先裁 ROI 再送进去，比换模型划算得多。**

**第二，脚部关键点的失败是静默的。** sprint_80 那一帧，主体在画面左缘且运动模糊，输出里左踝、左髋与全部六个脚部点都是 `(0,0)`、分数 0；右踝却有一个坐标 (3.2, 257.8)——x 几乎为 0。也就是说右脚踝也被判定在画外。这不是崩溃，是模型在低质量输入下给出一个「看起来像坐标」的答案。下游如果不检查分数和越界情况，会把 (3.2, 257.8) 当成有效脚踝用进角度计算。

## 五、输入契约不在模型里，在 pipeline.json 里

这一节是本文最想留给读者的一段。

我自己的项目里有一条链路：YOLOX 人体检测 ＋ RTMPose 姿态。在本机那 5 张帧上，它**一帧都没检出东西**。不是阈值太高、不是模型不对——检测器返回的是 1 行全零。

排查过程：

1. 先怀疑阈值和尺度。逐级放大到 3 倍、换帧、换图（一张普通街景），全都不出框。
2. 打印原始输出形状：`(1, 1, 5)`，分数恒为 0.000，框是 `[0,0,0,0]`。
3. 去看模型目录里的 `pipeline.json`。YOLOX 那份的 Preprocess 写着 `Normalize: mean=[0,0,0], std=[1,1,1]`——**恒等变换，即期望原始 0–255**。而我项目里的预处理代码，习惯性地又除了一次 255。

对照实验立刻分开了：

| 输入 | sprint_20 | sprint_5 | 街景图 |
| --- | --- | --- | --- |
| 除以 255（我原来的写法） | 1 行，分数 0.000 | 1 行，分数 0.000 | 1 行，分数 0.000 |
| 原始 0–255 | 84 行，最高 0.774 | 99 行，最高 0.770 | 14 行，最高 0.874 |

**除以 255，等于把整张图压成近乎全黑再喂进去**，模型当然什么也看不到，而且不报错。

怎么确认「原始 0–255」才是对的？三个独立证据：

1. `pipeline.json` 里 mmdeploy 自己写的 Normalize 规格；
2. ONNX 图里没有 Normalize 节点，第一个节点直接是 Conv／Reshape，说明归一化不在图内；
3. **WholeBodyPose 自己 vendored 的 mmdeploy YOLOX 消费代码**（`wholebodypose/models/rtmpose/_onnx/yolox.py`）做的是 `img.transpose(2, 0, 1)`，**不除 255**，而且输出签名（`dets` 的 `Gatherdets_dim_1`）与本地模型完全一致。

把这一处改对之后（只在运行时打补丁，没有改磁盘上的文件），同一条链路从「五帧全部 0 个检出」变成两帧 **12 条与 15 条轨迹**。另外三帧仍然是 0，但原因不同：它们的原始最高分是 0.215、0.164、0.254，**低于 0.3 的检测阈值**——那几帧主体运动模糊且贴近画外，属于模型能力边界，不是配置错误。

顺带核了姿态模型那侧的同类问题。`pipeline.json` 写的是 `to_rgb=True`（均值按 RGB 顺序给 `[123.675, 116.28, 103.53]`），而项目代码没有做 BGR→RGB 转换。我量了实际影响：逐关键点位移**平均 0.34 px、最大 0.86 px**，平均置信度 0.7579（BGR）对 0.7609（RGB）。为了确认这个「几乎没差别」不是测试写错，我做了对照——把输入整体加 5.0，原始 simcc 张量的最大差异是 25.03，而 BGR／RGB 之间的最大差异只有 0.4001。

**所以：同一套导出体系里两处约定不一致，一处致命，一处无害。** 不能靠「pipeline.json 这么写」就推断影响，必须逐个量。

## 六、许可与安装（两个实际会绊人的地方）

- **权重许可不是 Apache-2.0**。代码是 Apache-2.0 AND MIT（PyPI 的 `license_expression` 写的），但权重仓库的 license 字段是 `other`，对应仓库里的 `WEIGHTS_LICENSE.md`；而且权重训练数据涉及 COCO-WholeBody（CC BY-NC）与 MPII（不可商用）等，**商业使用不受保证**。权重未 gate，可以直接下载。
- **Python 版本有上限**。PyPI 上 2.1.0 的 `requires_python` 是 `>=3.10,<3.14`。本机默认 `python3` 是 3.14.9，pip 直接拒装，报的是 “Ignored the following versions that require a different python version”。换 3.12 建环境才装上。

## 七、尚未验证的部分

- **精度没有测**。本机没有人工标注，我没有可比对的全身体标注，所以「RTMW 与现有 RTMPose 在踝／脚跟／脚尖上差多少像素」这个问题**尚未回答**。计划是：先在同一批帧上对两套输出做脚部关键点的配对误差，再单独统计遮挡帧与出画帧的漏检率。
- **GPU 路径完全没跑**。本机只有 CPU provider，官方 A100 与 M4 CoreML 的数字我都没复现；CoreML 后端更是一次都没碰过。
- **Windows 离线链路没验**。本项目最终要跑在 Windows 上，而 CoreML 是 macOS 专用；Windows 上只有 CPU 与 CUDA 两条路。
- **视频级指标没做**。我量的是单帧，没有跑完整视频、没有测端到端 P95，也没有做跨帧的身份连续性评估。
- **多人数成本只在这 5 张帧上量过**。107 ms／人是这两个素材上的数，换场景需要重量。

## 八、一手来源

- [Release - WholeBodyPose v2.1.0](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation/releases/tag/v2.1.0)
- [Changelog](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation/blob/main/CHANGELOG.md)
- [PyPI 元数据 - wholebodypose 2.1.0](https://pypi.org/pypi/wholebodypose/2.1.0/json)
- [官方测速原始 JSON - benchmarks/results/cpu.json](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation/blob/main/benchmarks/results/cpu.json)
- [关键点索引 - docs/guide/keypoints.md](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation/blob/main/docs/guide/keypoints.md)
- [后端与阈值说明 - docs/guide/backends.md](https://github.com/CristianLazoQuispe/WholebodyPoseEstimation/blob/main/docs/guide/backends.md)
- [权重与许可 - huggingface.co/CristianLazoQuispe/wholebodypose-weights](https://huggingface.co/CristianLazoQuispe/wholebodypose-weights)
