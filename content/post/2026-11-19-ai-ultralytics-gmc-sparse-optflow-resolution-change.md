---
title: "Ultralytics 的相机运动补偿会永久卡死：分辨率一变，BoT-SORT 的 GMC 再也不工作"
date: 2026-11-19
description: "PR #27270 用一行条件修复了一个静默失效：GMC 的稀疏光流在帧尺寸变化后抛出 OpenCV 断言，缓存的上一帧永远不更新，此后每一帧都失败，运动补偿永久退化成单位矩阵。修复已在 2026-11-20 发布的 8.4.216 中进入 PyPI。本文用真实上游源码与两个 PyPI 发布包在修复前后复现，给出可运行的复现脚本、版本状态与运动分析链路的实际影响。"
tags:
  - Ultralytics
  - BoT-SORT
  - 目标跟踪
  - 运动视觉
  - 相机运动补偿
categories: ["AI"]
keywords: ["Ultralytics", "BoT-SORT", "GMC", "稀疏光流", "相机运动补偿", "calcOpticalFlowPyrLK", "PR 27270", "视频跟踪"]
draft: false
toc: true
---

用 Ultralytics 的 BoT-SORT 跑一段视频，中途画面分辨率变了一次（比如拼接了不同分辨率的片段，或者相机切换了档位）。**跟踪照常跑完，ID 不跳、框不丢、也不报任何错——但相机运动补偿从那一刻起就永久失效了。**

原因是一行条件判断。PR [#27270](https://github.com/ultralytics/ultralytics/pull/27270) 在 2026-11-19 00:55 UTC 合并，用 `self.prevFrame.shape != frame.shape` 给稀疏光流加了一道尺寸检查。这个修复只有一行，但它修的是一个**静默且不可自愈**的失效路径。

下面用真实上游源码在修复前后两个 commit 上复现，给出可运行的复现脚本、版本状态，以及这条链路对运动视频分析意味着什么。

## 失效点在哪

BoT-SORT 的 GMC（Generalized Motion Compensation）负责估计相邻帧之间的相机运动，用一个 2×3 仿射矩阵把轨迹坐标补偿到统一坐标系。默认配置 `ultralytics/cfg/trackers/botsort.yaml` 里写的是：

```yaml
gmc_method: sparseOptFlow # Global motion compensation: sparseOptFlow|orb|sift|ecc|none
```

也就是走稀疏光流。这条路径在 `ultralytics/trackers/utils/gmc.py`：

```python
def apply_sparseoptflow(self, raw_frame: np.ndarray) -> np.ndarray:
    height, width, c = raw_frame.shape
    frame = cv2.cvtColor(raw_frame, cv2.COLOR_BGR2GRAY) if c == 3 else raw_frame
    H = np.eye(2, 3)

    if self.downscale > 1.0:
        frame = cv2.resize(frame, (width // self.downscale, height // self.downscale))

    keypoints = cv2.goodFeaturesToTrack(frame, mask=None, **self.feature_params)

    # 修复前：只判断「有没有初始化过」
    if not self.initializedFirstFrame or self.prevKeyPoints is None:
        self.prevFrame = frame.copy()
        self.prevKeyPoints = copy.copy(keypoints)
        self.initializedFirstFrame = True
        return H

    matchedKeypoints, status, _ = cv2.calcOpticalFlowPyrLK(self.prevFrame, frame, self.prevKeyPoints, None)
    ...
    # 走到这里才会更新缓存
    self.prevFrame = frame.copy()
    self.prevKeyPoints = copy.copy(keypoints)
    return H
```

关键在于 `calcOpticalFlowPyrLK` 要求前后两帧**尺寸一致**。尺寸不一致时，OpenCV 抛的是断言：

```
OpenCV(5.0.0) /io/opencv/modules/video/src/lkpyramid.cpp:1185: error: (-215:Assertion failed)
prevPyr[level * lvlStep1].size() == nextPyr[level * lvlStep2].size() in function 'calc'
```

这个异常向上抛到跟踪器：

```python
# ultralytics/trackers/byte_tracker.py
try:
    warp = self.gmc.apply(img, results_high.xyxy)
except Exception as e:
    LOGGER.warning(f"GMC failed, falling back to identity: {e}")
    warp = np.eye(2, 3)
```

**异常被吞掉，降级为单位矩阵，运动继续。**但真正致命的是上面那段代码的位置：`self.prevFrame = frame.copy()` 写在 `calcOpticalFlowPyrLK` **之后**。一旦抛异常，这两行永远不会执行——缓存里的 `prevFrame` 永远停留在旧尺寸。

于是形成死循环：

1. 尺寸变了 → `calcOpticalFlowPyrLK` 抛断言 → 异常被捕获 → 降级为单位矩阵；
2. 缓存的 `prevFrame` 没更新，还是旧尺寸；
3. **下一帧尺寸还是新的**，和旧尺寸的 `prevFrame` 依然不匹配 → 再抛断言 → 再降级；
4. 如此往复，**每一帧都失败，直到视频结束**。

不是「跳过一帧」，是「从此再也不工作」。跟踪器不会崩、不会抛错，只是日志里反复出现同一行 `GMC failed, falling back to identity`。

## 复现：直接用真实上游源码

复现不需要装 ultralytics——只需要 `gmc.py` 这一个文件和 OpenCV。我拉了修复前后的两个 commit，只把 `ultralytics.utils.LOGGER` 换成一个打印用的桩：

```python
import importlib.util, sys, types
import numpy as np, cv2

ultra = types.ModuleType("ultralytics")
utils = types.ModuleType("ultralytics.utils")
class _Log:
    def warning(self, *a, **k): print("[tracker log]", str(a[0])[:90])
    def info(self, *a, **k): pass
utils.LOGGER = _Log()
sys.modules["ultralytics"] = ultra
sys.modules["ultralytics.utils"] = utils

def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

OLD = load("gmc_old.py", "gmc_old")   # 27cf3175a9aff96e12a65b86813d0a98bf7b1b92
NEW = load("gmc_new.py", "gmc_new")   # ad8aebe5cd7c  (PR #27270 merge commit)
```

测试序列：两帧 320×240，然后三帧 400×300（分辨率在第 3 帧变化），`downscale=2`（BOTSORT 的默认构造参数）。每帧用 `cv2.warpAffine` 做已知平移，光流估计出的平移量可以直接和真值对照。

修复前（`27cf3175`）：

```
  f0 320x240 dx= 0.0 | GMC   OK  | tx=   0.00 | prevFrame=(120, 160)
  f1 320x240 dx= 2.0 | GMC   OK  | tx=   2.00 | prevFrame=(120, 160)
  f2 400x300 dx= 5.0 | GMC  FAIL | tx=   0.00 | prevFrame=(120, 160) error
  f3 400x300 dx= 2.0 | GMC  FAIL | tx=   0.00 | prevFrame=(120, 160) error
  f4 400x300 dx= 2.0 | GMC  FAIL | tx=   0.00 | prevFrame=(120, 160) error
```

修复后（`ad8aebe5`）：

```
  f0 320x240 dx= 0.0 | GMC   OK  | tx=   0.00 | prevFrame=(120, 160)
  f1 320x240 dx= 2.0 | GMC   OK  | tx=   2.00 | prevFrame=(120, 160)
  f2 400x300 dx= 5.0 | GMC   OK  | tx=   0.00 | prevFrame=(150, 200)
  f3 400x300 dx= 2.0 | GMC   OK  | tx=  -3.00 | prevFrame=(150, 200)
  f4 400x300 dx= 2.0 | GMC   OK  | tx=   0.00 | prevFrame=(150, 200)
```

对照数字很清楚：

- **GMC 失败次数**：修复前 3/5 帧，修复后 0/5 帧；
- **缓存的 `prevFrame`**：修复前停在 `(120, 160)`（旧尺寸，永不更新），修复后推进到 `(150, 200)`（新尺寸）；
- **估计精度**：修复后 f3 估出 `tx=-3.00`，真值是 `2.0 - 5.0 = -3.0`；f4 估出 `0.00`，真值 `0.0`。**逐帧对得上**。

注意 f2（尺寸变化的那一帧）返回的是单位矩阵 `tx=0.00`——这是修复的设计取舍：那一帧没有可用的历史，直接返回单位阵，下一帧恢复正常估计。PR 作者在说明里写明了这一点，我实测的结果与之一致。

### 一个补充测试：尺寸变回去会怎样

如果分辨率变化后又变回原尺寸呢？我又跑了一组序列（320×240 → 400×300 → 320×240）：

```
--- B PRE-FIX  (size changes back) ---
  f0 320x240 | GMC  OK  | tx=  0.00 | prevFrame=(120, 160)
  f1 320x240 | GMC  OK  | tx=  2.00 | prevFrame=(120, 160)
  f2 400x300 | GMC FAIL | tx=  0.00 | prevFrame=(120, 160) error
  f3 400x300 | GMC FAIL | tx=  0.00 | prevFrame=(120, 160) error
  f4 320x240 | GMC  OK  | tx=  0.00 | prevFrame=(120, 160)
  f5 320x240 | GMC  OK  | tx=  0.00 | prevFrame=(120, 160)
```

修复前在 f4 恢复了——因为缓存的 `prevFrame` 恰好还是 320×240 的旧尺寸，和新帧又匹配上了。**但代价是中间那几帧的补偿完全丢失，而且 f4 恢复时拿到的 `prevFrame` 是两帧之前的陈旧画面**，估计出来的 `tx=0.00` 其实不对（真值是 2.0）。所以「尺寸变回去就自动好了」并不成立，丢掉的补偿和错乱的估计都留在轨迹里。

### 其他 GMC 方法不受影响

PR 说明里提到 "Other GMC methods are unchanged"。我实测确认了这一点：把 `gmc_method` 换成 `orb`、`sift`、`ecc`，在同样的尺寸变化序列下**都不抛异常**。原因是这些路径的实现方式不同——`apply_features`（orb/sift）每次都重新提特征点、按自己的逻辑处理描述子匹配，不依赖 `calcOpticalFlowPyrLK` 的等尺寸前置条件。

所以**受影响的只有 `sparseOptFlow`，而它恰好是 BoT-SORT 的默认配置**。

## 版本状态

- PR [#27270](https://github.com/ultralytics/ultralytics/pull/27270)「Recover sparse optical flow after frame size changes」，合并于 **2026-11-19 00:55:28 UTC**，提交 `ad8aebe5cd7c`，作者 `AhmetMert01`。
- **修复已在 2026-11-20 进入正式发布版本 8.4.216。** PR 合并后先只在 `main` 分支上（本文最初核对于 11-19，PyPI 最新版是 8.4.215）；**v8.4.216 于 2026-11-20 03:30:18 UTC 发布**，PyPI 同日 03:31:39 上传 `ultralytics-8.4.216-py3-none-any.whl`，现为最新版。用 GitHub compare API 核对 `v8.4.215...v8.4.216`：`ahead_by` 是 **49** 个提交、`behind_by` 是 **0**，其中包含本修复。**现在 `pip install -U ultralytics` 就能拿到修复，不需要从 `main` 分支构建。**
- 也就是说：**8.4.215 及更早的版本都还有这个 bug，8.4.216 起已修复。**

## 对运动分析链路意味着什么

**先说清楚适用范围。** 我本地这套 `sportpose` 链路是 ONNX Runtime + RTMPose + YOLOX，**不经过 Ultralytics 跟踪器，所以这些数字不会直接砸到现有链路上**。但下面几点是真正值得记的：

**1. 失效的隐蔽性比失效本身更值得警惕。** 这条路径的特点是「不报错」。跟踪继续、ID 继续、结果看起来完全正常——唯一线索是日志里反复出现的 `GMC failed, falling back to identity`。如果你的日志级别把 WARNING 过滤掉了，这个失效**在数据里没有任何痕迹**。而 GMC 的作用是相机运动补偿：机位移动的体育视频正是它的适用场景，补偿失效会直接把整批轨迹位置一起带偏（轨迹仍按原始像素坐标走，没有被换算到统一坐标系），下游的速度、步长、位移计算全部跟着偏。

**2. 「多分辨率拼接」在体育素材里并不罕见。** 同一场比赛的不同机位、不同摄像机位、或者手机视频经过不同转码路径，分辨率可能不一致；把多个片段拼成一个视频喂给跟踪器，就会命中这个条件。素材入库时值得加一道检查：**拼接前统一分辨率**，或者在拼接后核对首帧与末帧尺寸是否一致。

**3. 尺寸不变的常见场景同样要小心。** 我的测试证明了这个 bug 的触发条件**只有尺寸变化**，不是「任何异常」。普通单分辨率视频不受影响。所以它不是日常噪声，而是「特定素材才会踩」的那类问题——恰恰是这类问题最容易在生产里长期潜伏。

**4. 如果要临时绕过。** 三种办法：把 `botsort.yaml` 里的 `gmc_method` 改成 `none`（明确放弃补偿，知道自己在放弃）；改成 `orb` 或 `sift`（不走稀疏光流路径）；或者升级到 `ultralytics>=8.4.216`（本文写作时已发布，见「版本状态」）。第三种最贴近上游行为。

**5. 同一批修复里还有两个同类的「缓存没跟着输入变」问题。** 8.4.216 同时收录了 PR [#27283](https://github.com/ultralytics/ultralytics/pull/27283)（`Heatmap` 与 `TrackZone` 在帧尺寸变化时因按第一帧尺寸建立的缓冲区不匹配而崩溃，改为尺寸变化时重建缓冲区）和 PR [#27222](https://github.com/ultralytics/ultralytics/pull/27222)（验证时逐图指标用裸文件名做键，同名文件在不同子目录会互相覆盖，改为用相对 `label_root` 的完整路径）。**三个修复的失效条件是同一个形状：某个缓存或键与输入的某个属性绑定，而这个属性变了。** GMC 缓存上一帧、Heatmap 缓存累加器、validator 缓存文件名词典。审这类代码时值得专门看一眼：**有没有哪条路径会在输入属性变化时跳过缓存重建。**

**6. 这个失效模式本身值得记住。** 它的通用形状是：**「状态更新写在可能抛异常的调用之后」→ 一次异常让状态永久停在旧值 → 后续每次都撞同一个错**。这不是 Ultralytics 特有的问题，任何带缓存状态的流式处理都有这个坑（GMC 缓存的是上一帧，检测器缓存的是上一次推理的尺寸，编解码器缓存的是上一段的采样率）。审代码时值得专门看一眼：**有没有哪条路径会在异常时跳过状态推进。**

## 待验证与局限

诚实说明这一轮**没有**做到的部分：

- **没有跑真实的 BoT-SORT 端到端跟踪。** 本机 venv 里没装 `ultralytics`（`/home/hermes/sports-pose-eval/.venv` 只有 numpy/opencv/onnxruntime/scipy 等），也**没有下载 `yolo11n.pt` 权重**（PR 作者用的是它）。我复现的是 GMC 类本身的行为，不是「跟踪器在视频上的表现」。PR 作者自己写了 "Run as a reproduction; the PR adds no test"——上游没有为这个修复加测试。
- **只测了 OpenCV 5.0.0 与 5.1.0。** PR 作者在 OpenCV 4.10 上验证。不同 OpenCV 版本的断言触发点和错误信息可能不同（5.0.0 下报错落在 `lkpyramid.cpp:1185`，5.1.0 下落在 `:1354`，另一个测试场景落在 `:1051`，取决于哪一层先检查）。
- **复现用的是源码 commit，不是发布包。** 上面的对照跑在修复前后的两个 commit 上（`27cf3175a9aff96e12a65b86813d0a98bf7b1b92` 与 `ad8aebe5cd7c`）。**v8.4.216 发布后，我改用 PyPI 上的真实 wheel 重跑了一遍**（`pip download ultralytics==8.4.215` 与 `==8.4.216`，解包后各取 `ultralytics/trackers/utils/gmc.py`，其余不变）：**8.4.215 从第 3 帧起每帧都抛断言、缓存 `prevFrame` 停在 `(120, 160)`；8.4.216 零失败、缓存推进到 `(150, 200)`，平移估计 f3=`-3.02`（真值 `-3.0`）、f4=`0.00`（真值 `0.0`）**。两个 wheel 的 `gmc.py` 之间**只有一处差异**，就是第 316 行新增的 `or self.prevFrame.shape != frame.shape`。这次跑的 OpenCV 是 5.1.0（断言落在 `lkpyramid.cpp:1354`）。
- **只测了 `downscale=2` 和 `sparseOptFlow`。** 其他 `downscale` 取值、其他 GMC 方法（orb/sift/ecc 我测了「不抛异常」，但没逐一验证估计精度）没有展开。
- **没有在真实运动素材上量化影响。** 项目自己的 `track_sprint.ogv` 是单分辨率，不会触发这个 bug。要拿到真实数字，需要构造一段**中途变分辨率**的运动视频，量 GMC 失效前后轨迹坐标的偏差——**这一项没做**。
- **没有验证 GPU / Windows 路径。** 全程 CPU / Linux。
- **`persist=True` 跨视频的行为没测。** `ultralytics/trackers/track.py` 里 `on_predict_postprocess_end` 只在 `not persist` 且视频路径变化时调 `tracker.reset()`，而 `BOTSORT.reset()` 会一并 `self.gmc.reset_params()`。也就是说 **`persist=True` 时切换视频，GMC 状态**不会**被重置**——如果新旧视频分辨率不同，这正是触发路径。这个组合关系我只从源码推断，没有实测。

## 一手链接

- PR：https://github.com/ultralytics/ultralytics/pull/27270
- 修复提交：https://github.com/ultralytics/ultralytics/commit/ad8aebe5cd7c
- 上游文件：https://github.com/ultralytics/ultralytics/blob/main/ultralytics/trackers/utils/gmc.py
- 最新 Release（**已含此修复**）：https://github.com/ultralytics/ultralytics/releases/tag/v8.4.216
- 上一版（尚不含此修复）：https://github.com/ultralytics/ultralytics/releases/tag/v8.4.215
- BoT-SORT 默认配置：https://github.com/ultralytics/ultralytics/blob/main/ultralytics/cfg/trackers/botsort.yaml
