---
title: "Godot 4.8 beta 4 的纹理流送实测：功能默认关闭、兼容性渲染器不支持，而「属性访问快 1.6 倍」这个官方数字我复现不出来"
date: 2026-11-24
description: "Godot 4.8 beta 4 带来了按 mip 逐级流送的纹理系统，官方说能大幅降显存；本文用 4.8-beta4 与 4.7.2 两个官方二进制实测：功能确实存在且默认关闭，兼容性渲染器直接不支持。但官方那条「Object 属性访问快 1.6 倍」的说法，我在自己机器上只测到 1.4 倍左右，且只在按名字动态 get/set 时成立——直接访问反而变慢了。"
tags:
  - Godot 4.8
  - 纹理流送
  - VRAM 优化
  - GDScript
  - 渲染后端
  - 性能实测
categories: ["AI"]
keywords: ["Godot 4.8", "Godot 4.8 beta 4", "TextureStreaming", "StreamedTexture2D", "mip 流送", "VRAM", "GDScript", "属性访问", "GDType", "ClassDB", "Forward+", "兼容性渲染器", "纹理内存预算"]
draft: false
toc: true
---

做游戏项目的人都被同一个问题追着跑：场景里贴图越塞越多，显存就一路涨，最后卡在低端机上动不了。引擎给出的常见答案是「用 LOD」「控制贴图分辨率」「分块加载」——都是手工活，美术和策划要配合，做不好。

Godot 4.8 往这个方向推了一步：**纹理流送（texture streaming）**。引擎自己决定每张贴图当前该用哪一级 mip，用不到的高分辨率层就留在磁盘上不占显存。我把 4.8-beta4 的官方二进制拉下来跑了一遍，想搞清楚这个功能到底怎么工作、能不能用、以及官方宣传的收益有多少是真的。

顺便还撞见另一件事：4.8 的发布说明里有一条「Object 属性访问加速 1.6 倍」。我用同一套脚本跑了对照实验，**没复现出 1.6 倍**。

## 一、先说清楚我测的是什么

版本和口径先钉死，避免后面看数字时对不上：

| 项目 | 值 |
| --- | --- |
| 被测版本 A | `Godot_v4.8-beta4_linux.x86_64`，自报 `4.8.beta4.official.b070e63b1` |
| 被测版本 B | `Godot_v4.7.2-stable_linux.x86_64`，自报 `4.7.2.stable.official.ed1daf0bf` |
| 下载来源 | `godotengine/godot-builds` 官方 Release（4.8-beta4 发布于 2026-11-18 22:01:47 UTC） |
| 运行方式 | `--headless --path <空工程> --script <脚本>.gd`，无窗口、无 GPU |
| 硬件 | AMD EPYC 7K62，**2 vCPU 可见**，约 2 GB 内存 |
| 图形 | 本机**无 Vulkan ICD**（`/usr/share/vulkan` 不存在），所有渲染相关数字都测不到 |

最后一行的限制很重要，请先记住：**这台机器没有 Vulkan 驱动，Godot 的渲染后端跑不起来**。所以本文**没有任何帧时间、draw call、显存占用数字**。能测的是 CPU 侧的东西：API 是否存在、默认值是多少、属性访问有多快。这是一篇 CPU 侧的稿子，不是渲染性能稿。

## 二、纹理流送：它是怎么工作的

我读了 4.8 源码里新增的 `modules/texture_streaming/`，机制大致是这样：

**1. 靠 shader 反馈决定分辨率。** 引擎给场景着色器加了一个 `STREAMING_LOD` 内建量（在 `scene_shader_forward_clustered.cpp` 和 `forward_mobile` 里都能看到 `actions.renames["STREAMING_LOD"] = "streaming_lod"`），片元着色器把自己的屏幕占用反馈回引擎。引擎据此决定这张贴图该保持哪一级 mip。源码注释写得很直白：「far from the camera or not currently visible have their higher-resolution mipmap levels unloaded」。

**2. 反馈走 GPU buffer 回读，且被限流。** 反馈数据写进一个 storage buffer，引擎用 `buffer_get_data_async` 异步取回。关键是限流——源码里 `if (current_ticks - feedback_buffer_last_submit_ticks < 30) { return; }`，**每 30 毫秒才提交一次**。这意味着从「物体进入视野」到「贴图真的升到高分辨率」之间，最坏情况下有 30 ms 的延迟，乘上贴图 I/O 时间。这不是 bug，是设计上的取舍：流送是后台渐进式的，不追求瞬时。

**3. 有内存预算，也会自动降级。** 项目设置里有 `rendering/textures/streaming/memory_budget_enabled`（默认 **false**）和 `memory_budget_mb`（默认 **512**）。超预算时按「最近使用 + 屏幕占比」决定谁先降分辨率。另外 `inactivity_decay_rate_ms`（默认 **5000**）控制不可见贴图多久降一级 mip——官方注释举例：默认值下，一张 10 秒没被看到的贴图会降 2 级。

**4. mip 范围有硬上限。** `max_lod` 默认 **3**，源码注释直接写明「3 ≈ 128px for 8K texture」。也就是说，即使开了流送，8K 贴图最差也只降到大约 128px 那一级，不会无限往下掉。`min_lod` 默认 0（满分辨率）。

## 三、我在 4.8-beta4 里实际跑出来的默认值

这些不是从文档抄的，是用 `--script` 在 4.8-beta4 二进制里调 `ProjectSettings.get_setting()` 打出来的：

```
rendering/textures/streaming/enabled                    = false
rendering/textures/streaming/min_lod                    = 0
rendering/textures/streaming/max_lod                    = 3
rendering/textures/streaming/memory_budget_enabled      = false
rendering/textures/streaming/memory_budget_mb           = 512
rendering/textures/streaming/inactivity_decay_rate_ms   = 5000
```

同一套脚本在 4.7.2 上跑，`ProjectSettings.has_setting("rendering/textures/streaming/enabled")` 返回 **false**——设置项在 4.7 里根本不存在。

API 层面我逐个查了 `ClassDB`：

- `TextureStreaming` 单例：**4.8 有，4.7.2 没有**（`Engine.has_singleton("TextureStreaming")` 分别为 true / false）
- `StreamedTexture2D` 类：4.8 有，4.7.2 没有
- `ResourceImporterStreamedTexture` 导入器：4.8 有，4.7.2 没有
- `Performance.RENDER_STREAMING_TEXTURE_MEM_USED` 监视器：4.8 有（枚举常量值为 59，`MONITOR_MAX` 从 59 提到 60）。在 4.7.2 上引用这个常量，脚本直接**解析失败**——`Cannot find member "RENDER_STREAMING_TEXTURE_MEM_USED" in base "Performance"`。这是 4.7 与 4.8 的硬边界。
- `TextureStreaming` 公开方法：`flush_texture_streaming`、`get_memory_budget_bytes_used`，以及 `min_lod_override` / `max_lod_override` / `memory_budget_mb_override` 三个运行时覆写属性。

## 四、三个必须先知道的限制

**限制一：默认是关的，而且要手动改导入设置。** `rendering/textures/streaming/enabled` 默认 `false`。更关键的是，官方类文档写明：「textures must be imported with streaming support to use this feature」——贴图得用 `ResourceImporterStreamedTexture` 导入。**光开项目设置不够**，你已有的贴图不会自动变成流送贴图，得重新导入。这是最容易踩空的一步。

**限制二：兼容性渲染器（Compatibility / gl_compatibility）直接不支持。** 源码里 `_start_streaming()` 开头就拦：

```cpp
const String rendering_method = OS::get_singleton()->get_current_rendering_method();
if (rendering_method == "gl_compatibility") {
    WARN_PRINT("Texture streaming is not supported with the Compatibility renderer.");
    return;
}
```

而且 `drivers/gles3/storage/texture_storage.h` 里 `texture_2d_attach_streaming_state` 是个**空实现**（`override {}`），dummy 渲染器同样是空的。也就是说，OpenGL 兼容后端和 headless 跑批都拿不到流送。**这个功能只在 Forward+ 和 Mobile（基于 RenderingDevice 的）后端上可用。**

**限制三：`flush_texture_streaming()` 存在，说明流送是渐进的。** 这个方法的作用是「强制所有待处理的流送操作立即完成」，官方描述的用途是「loading screens or when teleporting the player」——加载界面和传送时用。**平时不调它，贴图就是慢慢变的。** 玩家瞬移后看到糊贴图再慢慢变清晰，是预期行为，不是 bug。

## 五、那个「1.6 倍」：我测出来是 1.4 倍左右

4.8 发布说明里有这么一条：「Accelerate `Object` property access 1.6x」。实现上，4.8 把属性表从 `ClassDB` 挪到了新的 `GDType`（PR #122596、#122751），`Object::set` / `Object::get` 改成先查 `get_gdtype().get_property_map()`。

我写了两个对照实验，脚本在 4.8-beta4 和 4.7.2 上**跑完全相同的代码**：

**实验 A —— 按名字动态 get/set（走新路径）。** 2000 个脚本类实例，每个 16 个 int 属性，用 `o.set("name", v)` / `o.get("name")` 访问，跑 20 轮共 64 万次操作：

| 版本 | 每次操作耗时 | 中位数 |
| --- | --- | --- |
| 4.8-beta4 | 263.16 – 356.27 ns | **≈ 270 ns** |
| 4.7.2-stable | 373.56 – 391.78 ns | **≈ 376 ns** |

比值 ≈ **1.39 倍**。五次交替跑，两版机器状态和负载一致。**1.6 倍复现不出来**，我稳定测到的是 1.4 倍上下。

**实验 B —— 直接属性访问（不走新路径）。** 同样的对象，改成 `o.a = r` 这种静态字段访问：

| 版本 | 每次操作耗时 |
| --- | --- |
| 4.8-beta4 | ≈ 39.8 ns |
| 4.7.2-stable | ≈ 43.3 ns |

这里 4.8 反而略快一点，但差距只有 3 ns，在 2 vCPU 的抖动范围内，**我不认为这构成有意义的差异**。

**这个 1.39 倍说明什么？** 官方那条 1.6 倍大概率是在**原生 C++ 属性访问**口径下测的，而我测的是 GDScript 里的 `set()` / `get()` 调用——这中间还隔着 GDScript 层的字符串到 `StringName` 转换、`Variant` 装箱，以及脚本调用本身的固定开销。这些固定开销在两版之间不变，会把比值往 1 拉近。所以「1.6 倍」和「1.39 倍」两个数字**可能都是对的，只是口径不同**。

给实际用的人一句结论：**如果你在 GDScript 里用 `obj.set("prop", v)` 这种按名字的写法，4.8 的收益是真实存在但比宣传值小的（我测 1.4 倍）；如果你直接写 `obj.prop = v`，基本感觉不到差别。** 官方那条 1.6 倍别直接拿来当自己的预期。

顺带一个反直觉的数据点：**4.8 的静态内存占用比 4.7.2 高**。空工程 headless 启动后，`OS.get_static_memory_usage()` 分别是 43.5 MB（4.8）和 23.7 MB（4.7.2），进程 RSS 约 115 MB 对 98 MB。这不矛盾于「省 12 MB 运行时 RAM」的说法——那条讲的是 `GDType` 合并后**属性表自身**的开销（PR #122751），而整个引擎基线变大是别的原因（新增模块、更多内置类等）。我另外测了「动态创建 400 个脚本类」的场景，内存增量是 5.56 MB（4.8）对 5.86 MB（4.7.2）——**每个类少占约 0.75 KB**，这才是「省 RAM」那句话在类多的时候的样子。**类少的小项目，这笔账基本看不出来。**

## 六、我没做的事（以及为什么）

这一节是本文最该被认真读的部分。

**没测任何渲染数字。** 本机无 Vulkan ICD，Godot 的 Forward+ / Mobile 后端起不来，也就没有帧时间、draw call、显存占用、mip 切换卡顿这些数据。**Godot 官方关于「VRAM 显著下降」的说法我一个字都没验证。** 我只验证了机制存在、默认值、API 边界。

**没验证流送的实际视觉效果。** 没跑过一个真实的 3D 场景，没看过贴图在远近移动时的清晰度变化，没测过流送引入的 I/O 卡顿落在哪一帧。

**没验证不同驱动的差异。** PR #113429 改了 `drivers/d3d12/rendering_device_driver_d3d12.cpp`（新增 `_data_format_is_compressed`），改了 `drivers/gles3/`（兼容性渲染器的空实现），但**没有碰 `drivers/vulkan/`**。流送走的是 `RenderingDevice` 这一层（`servers/rendering/renderer_rd/storage_rd/texture_storage.cpp` 里 `texture_2d_attach_streaming_state` 有真实实现），所以 Vulkan 和 D3D12 应该共享同一条 RD 路径。但我在 4.8-beta4 的 Vulkan 驱动里 grep 不到 `texture_update` 的 mip 级更新接口，**Vulkan 后端下流送是否真的能逐级换 mip，我没法确认**——这是一个需要在真机上验证的疑点，不是我可以直接断言的结论。

**顺带查了 Godot 的 Vulkan 版本口径，供跨期跟踪用。** 4.8-beta4 的 `rendering_context_driver_vulkan.cpp` 里，`app_info.apiVersion` 写死为 `VK_API_VERSION_1_2`（1.0 时用 1.0），代码注释说明这个值「only used by validation layers to warn us about version issues」。我在整个 Vulkan 驱动里 grep `vkCmdBeginRendering` 和 `vkCmdPipelineBarrier2`，**都是 0 次**——也就是说 Godot 目前仍走传统 render pass 和旧的 barrier 路径，**没有采用 Vulkan 1.3 的 dynamic rendering，也没有用 sync2 的 `vkCmdPipelineBarrier2`**。这与 Khronos 那边「Vulkan 1.4 已在生产驱动普及」的大环境形成对比：**Godot 作为最热门的开源引擎之一，对 Vulkan 1.3/1.4 核心特性的吸收是滞后的。** 这不影响功能正确性（1.2 + 旧 barrier 完全可用），但对想跟进 Vulkan 1.4 生态的开发者是个明确的现状。

## 七、接下来该验证什么

如果你手上有带独显的机器，下面这几件事是真正该做的（**我一条都没做**）：

1. **VRAM 到底降了多少。** 造一个大场景（几百张 4K/8K 贴图），开 `rendering/textures/streaming/enabled` 并用 `ResourceImporterStreamedTexture` 重新导入，用 `Performance.RENDER_STREAMING_TEXTURE_MEM_USED` 监视器采样显存曲线，和关闭状态对比。**注意监视器统计的是「当前加载的 mip 层级下的 VRAM 占用」，不是磁盘上的完整贴图体积**——这两个数别混。

2. **流送的延迟到底能不能被感知。** 30 ms 的反馈提交间隔 + 贴图 I/O，在快速移动的第一人称视角下，会不会看到糊贴图？建议做法：固定路线匀速跑，记录每帧的贴图清晰度与掉帧。

3. **预算机制会不会误伤。** 把 `memory_budget_mb` 设成一个小值（比如 256 MB），看「最近使用 + 屏幕占比」的优先级会不会让刚进视野的贴图被降级到 128px（`max_lod=3` 那条线）。

4. **Vulkan 后端的逐级 mip 替换是否真的工作。** 用 Vulkan 驱动（Linux + Vulkan，或 Windows + D3D12 对照），确认换 mip 时没有黑帧或材质丢失。

5. **4.8 beta 的属性访问加速在你自己的项目里是多少。** 拿你自己的热点函数（如果大量用 `set()` / `get()` 按名字访问）做同样的对照，别用我这里的合成基准。

## 八、一手来源

- [Dev snapshot: Godot 4.8 beta 4（2026-11-18）](https://godotengine.org/article/dev-snapshot-godot-4-8-beta-4/)
- [Dev snapshot: Godot 4.8 beta 1（2026-10-15，4.8 全特性汇总，含 mip 级纹理流送、multi-bounce AO、compatibility 渲染器 decal 支持）](https://godotengine.org/article/dev-snapshot-godot-4-8-beta-1/)
- [官方二进制 4.8-beta4](https://github.com/godotengine/godot-builds/releases/tag/4.8-beta4)
- [官方二进制 4.7.2-stable](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
- [纹理流送主 PR #113429（新增 `modules/texture_streaming/`、`StreamedTexture2D`、`TextureStreaming` 单例）](https://github.com/godotengine/godot/pull/113429)
- [属性表迁移到 `GDType` PR #122596（官方「1.6 倍」的出处之一）](https://github.com/godotengine/godot/pull/122596) 与 [PR #122751](https://github.com/godotengine/godot/pull/122751)
- [纹理流送模块源码（master）](https://github.com/godotengine/godot/tree/master/modules/texture_streaming)
- [Vulkan 后端现状（`app_info.apiVersion` 与 render pass 路径）](https://github.com/godotengine/godot/blob/master/drivers/vulkan/rendering_context_driver_vulkan.cpp)

---

**本文的边界声明**：文中所有 Godot 版本号、构建 commit、发布时刻均来自官方 Release 元数据与二进制自报；所有项目设置默认值、类与单例的存在性、`Performance` 常量编号，均由我在 4.8-beta4 与 4.7.2 两个官方二进制上实跑脚本得到（脚本与命令见正文）；「1.39 倍」「43.5 MB vs 23.7 MB」「每类少 0.75 KB」等数字是我在 AMD EPYC 7K62 / 2 vCPU / 无 GPU 的 headless 环境下测得的，**不是官方数据，也不是通用结论**；第五节的属性访问对照实验只覆盖 GDScript 按名访问与直接访问两条路径，未覆盖原生 C++ 扩展；第六节所有渲染相关的「没做」事项均为事实陈述，不是对功能的负面判断——功能可能在有 GPU 的机器上表现完全不同。
