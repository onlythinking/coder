---
title: "Serena 架构解析：MCP 协议如何驱动 AI 编程 Agent IDE"
date: "2026-04-15"
description: "深入解析 Serena 如何基于 MCP（Model Context Protocol）协议构建 AI 编程 Agent IDE，剖析其语义检索、上下文管理和代码编辑的架构设计与实现原理。"
tags: ["MCP", "AI Agent", "Serena", "编程工具", "LLM"]
categories: ["AI"]
keywords: ["MCP协议", "Model Context Protocol", "Serena", "AI编程工具", "语义检索", "Agent IDE", "MCP Client", "上下文管理", "原子化编辑", "语义索引"]
draft: false
readingTime: 8 分钟
toc: true
---

## 背景

2025 年以来，AI 编程工具从简单的补全进化到能够自主完成复杂任务的 Agent。这个进化过程中，一个关键问题逐渐浮出水面：**AI Agent 如何稳定、标准化地与开发工具交互？**

Hacker News 上 22.9k stars 的开源项目 [Serena](https://github.com/oraios/serena)（oraos/serena）试图回答这个问题。它将自己定位为"AI Agent 的 IDE"，基于 MCP（Model Context Protocol）协议构建了一套完整的语义检索和代码编辑能力。本文深入剖析其架构设计。

## MCP 协议：不止于"USB 接口"

MCP（Model Context Protocol）由 Anthropic 在 2024 年底提出，是一种让 AI 模型与外部工具、数据源交互的标准协议。官方将其比喻为"USB 接口"，但实际上 MCP 的能力远超这个类比——它是一套完整的**有状态会话协议**，包含生命周期管理、工具调用、资源订阅和双向通信。

### 协议架构：三层角色

MCP 的架构包含三个核心角色：

```text
┌─────────────────────────────────────────────────────┐
│                    Host（宿主）                      │
│         Claude Desktop、Serena 等 AI 应用           │
├─────────────────────────────────────────────────────┤
│                  Client（客户端）                    │
│    运行在 Host 进程中，与每个 Server 保持 1:1 连接   │
├─────────────────────────────────────────────────────┤
│  Server A    │   Server B    │   Server C           │
│  文件系统    │    Git        │    数据库             │
└─────────────────────────────────────────────────────┘
```

### JSON-RPC 2.0 消息格式

MCP 底层采用 [JSON-RPC 2.0](https://www.jsonrpc.org/specification) 作为 RPC 协议格式，所有消息均为 JSON：

**请求消息（Request）**：
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "filesystem.read_file",
    "arguments": {
      "path": "/project/src/main.py"
    }
  }
}
```

**响应消息（Response）**：
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "# Python main file\ndef main():\n    ..."
      }
    ],
    "isError": false
  }
}
```

**通知消息（Notification）**——无响应期望，用于事件推送：
```json
{
  "jsonrpc": "2.0",
  "method": "notifications/message",
  "params": {
    "level": "info",
    "data": "索引构建完成，共 1,234 个代码块"
  }
}
```

### 传输层：stdio vs HTTP+SSE

MCP 支持两种传输机制，适用于不同部署场景：

**stdio（标准输入/输出）**：适用于本地进程通信
```bash
# 启动本地 MCP Server
python -m mcp_server.filesystem /project
```
Host 通过子进程 stdin/stdout 收发消息，低延迟但仅限于本地。

**HTTP + SSE（Server-Sent Events）**：适用于远程服务
```json
// HTTP POST 发送请求
POST /mcp/rpc
Content-Type: application/json

// HTTP GET + SSE 接收服务器推送
GET /mcp/events
Accept: text/event-stream
```
Server 通过 SSE 向 Client 推送日志、进度更新、采样回调等事件。

### 核心协议能力

#### 1. 工具调用（tools/list 与 tools/call）

Client 通过 `tools/list` 发现 Server 提供的能力：

```json
// Request
{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }

// Response
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "tools": [
      {
        "name": "filesystem.read_file",
        "description": "读取文件内容",
        "inputSchema": {
          "type": "object",
          "properties": {
            "path": { "type": "string" }
          },
          "required": ["path"]
        }
      },
      {
        "name": "git.log",
        "description": "获取 Git 提交历史",
        "inputSchema": {
          "type": "object",
          "properties": {
            "path": { "type": "string" },
            "maxCount": { "type": "integer", "default": 100 }
          }
        }
      }
    ]
  }
}
```

调用工具通过 `tools/call`：
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/call",
  "params": {
    "name": "filesystem.read_file",
    "arguments": { "path": "/project/src/main.py" }
  }
}
```

#### 2. 资源订阅（Resources）

MCP 的资源模型支持**订阅机制**，Client 可以订阅文件、数据库等资源的变更通知：

```json
// 订阅资源
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "resources.subscribe",
  "params": {
    "uri": "file:///project/src/main.py"
  }
}

// Server 通过 SSE 推送变更
event: resource_changed
data: {"uri": "file:///project/src/main.py", "mtime": 1715001234}
```

#### 3. 采样（Sampling）——最独特的特性

Sampling 允许 MCP Server **回调 AI 完成复杂推理**，这是 MCP 区别于传统工具调用的关键能力。例如，代码检索 Server 可以调用 AI 来判断检索结果的相关性：

```json
// Server 发起采样请求
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "resources/sampling/createMessage",
  "params": {
    "systemPrompt": "你是一个代码分析专家，判断以下检索结果是否匹配用户查询...",
    "messages": [
      {
        "role": "user",
        "content": {
          "type": "text",
          "text": "检索结果: verify_user() 函数定义在 auth.py\n查询: 处理用户登录的逻辑"
        }
      }
    ],
    "maxTokens": 500,
    "temperature": 0.3
  }
}
```

这使得 Server 能够**将 AI 能力二次封装**——例如构建一个"智能代码审查 Server"，内部调用 AI 评估代码质量。

### 连接生命周期

MCP 会话遵循标准的三阶段生命周期：

```
┌──────────────┐    initialize     ┌──────────────┐
│    Client    │ ─────────────────→│    Server     │
│  (初始状态)   │                   │  (就绪状态)    │
└──────────────┘                   └──────────────┘
       │                                   │
       │    ←─── initialized ────         │
       │                                   │
       │      tools/call                   │
       │      resources/*                  │  ← 正常工作阶段
       │      sampling/*                   │
       │                                   │
       │                                 shutdown
       ↓                                   ↓
```

`initialize` 阶段交换协议版本、功能列表；`initialized` 通知表示握手完成；`shutdown` 用于优雅关闭连接。

## Serena 的三层架构

Serena 的架构分为三层：**协议层、检索层、编辑层**。自底向上看，协议层是基础设施，检索层提供"感知"能力，编辑层负责"执行"。

### 协议层：MCP Client 实现

Serena 的 MCP Client 不仅仅是一个 HTTP 客户端，而是一个**完整的状态机**，管理着与多个 Server 的持久连接。

#### 状态机设计

```python
# 伪代码：MCP Client 连接状态机（参考 modelcontextprotocol/python 实现）
class MCPClient:
    class State(Enum):
        INIT = "init"           # 连接未建立
        CONNECTING = "connecting"  # 正在握手
        READY = "ready"          # 正常工作
        ERROR = "error"          # 连接错误
        CLOSED = "closed"        # 连接已关闭

    def __init__(self):
        self.state = self.State.INIT
        self.servers: dict[str, MCPServerConnection] = {}
        self.pending_requests: dict[int, asyncio.Future] = {}
        self.notification_handlers: dict[str, Callable] = {}
        self._receiver_task: asyncio.Task | None = None

    async def connect(self, server_config: ServerConfig):
        """建立与 MCP Server 的连接"""
        self.state = self.State.CONNECTING
        transport = await self._create_transport(server_config)

        # 发送 initialize 请求
        init_response = await self._send_request(
            method="initialize",
            params={
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "roots": {"listChanged": True},
                    "sampling": {}
                },
                "clientInfo": {
                    "name": "serena",
                    "version": "1.0.0"
                }
            }
        )

        # 发送 initialized 通知（不需要响应）
        await self._send_notification("initialized", {})

        self.state = self.State.READY
        self._start_receiver_loop(transport)

    async def _create_transport(self, config: ServerConfig):
        """根据配置创建传输层：stdio 或 HTTP+SSE"""
        if config.transport == "stdio":
            return StdioTransport(
                command=config.command,
                args=config.args,
                env=config.env
            )
        else:  # HTTP+SSE
            return HTTPSSETransport(
                url=config.url,
                headers=config.headers
            )
```

#### 多路复用与请求路由

一个常见的误解是 MCP Client 只能连接一个 Server。实际上，Serena 通过**多路复用**同时连接多个 Server：

```python
# Serena 的 MCP Client 路由逻辑（伪代码）
class SerenaMCPClient:
    def __init__(self):
        self.connections: dict[str, MCPClient] = {}
        # 工具名称格式：server_name.tool_name
        # 例如：filesystem.read_file, git.commit

    async def invoke_tool(self, full_tool_name: str, arguments: dict) -> dict:
        """
        将工具调用路由到正确的 Server
        工具命名遵循: {server_name}.{tool_name}
        """
        if "." not in full_tool_name:
            raise ValueError(f"Invalid tool name: {full_tool_name}")

        server_name, tool_name = full_tool_name.split(".", 1)
        client = self.connections.get(server_name)

        if not client:
            # 动态加载未连接的 Server
            client = await self._auto_connect_server(server_name)
            self.connections[server_name] = client

        return await client.call_tool(tool_name, arguments)

    async def invoke_tool_batch(self, calls: list[ToolCall]) -> list[dict]:
        """并发调用多个 Server 的工具"""
        tasks = [
            self.invoke_tool(call.name, call.arguments)
            for call in calls
        ]
        return await asyncio.gather(*tasks)
```

这种设计使得 Serena 可以在单次对话中协调多个 Server——例如先调用 `filesystem.search` 定位代码，再调用 `git.diff` 查看变更历史。

### 检索层：语义索引与增量查询

Serena 的核心竞争力之一是**语义检索**。它不依赖简单的文件名匹配或正则搜索，而是维护一个增量更新的语义索引。

#### 向量数据库选型

Serena 支持两种主流向量数据库作为后端：

| 特性 | ChromaDB | Qdrant |
|------|----------|--------|
| 部署方式 | 嵌入式（SQLite）/客户端-服务器 | 分布式集群 |
| 适用场景 | 本地开发、单人使用 | 团队协作、多实例 |
| 过滤能力 | 元数据过滤 | 带权重的向量搜索 |
| 扩展性 | 百万级向量 | 十亿级向量 |

典型配置：
```python
# ChromaDB 本地模式（适合个人开发者）
import chromadb
from chromadb.settings import Settings

client = chromadb.PersistentClient(
    path="./.serena/vector_db",
    settings=Settings(anonymized_telemetry=False)
)
collection = client.get_or_create_collection(
    name="code_semantic_index",
    metadata={"hnsw:space": "cosine"}  # 余弦相似度
)

# Qdrant 分布式模式（适合团队）
from qdrant_client import QdrantClient
client = QdrantClient(url="http://localhost:6333", prefer_grpc=True)
```

#### Embedding 模型选择

代码 embedding 的质量直接影响检索精度。Serena 支持多种模型：

```python
# 模型对比（伪代码，基于公开 benchmarks）
EMBEDDING_MODELS = {
    # GraphCodeBERT：考虑代码结构的 SOTA 模型
    "graphcodebert": {
        "model": "microsoft/graphcodebert-base",
        "dimension": 768,
        "max_seq_length": 512,
        "tokenizer": " Roque/GraphCodeBERT-tokenizer"
    },

    # CodeBERT：通用的代码-文本双塔模型
    "codebert": {
        "model": "microsoft/codebert-base",
        "dimension": 768,
        "max_seq_length": 512
    },

    # text-embedding-ada-002：OpenAI API（需联网）
    "openai_ada2": {
        "model": "text-embedding-ada-002",
        "dimension": 1536,
        "api": "openai"
    }
}

# 选型建议：
# - 本地优先：GraphCodeBERT（精度最高，需 GPU）
# - 快速原型：CodeBERT（CPU 可跑）
# - 云端部署：OpenAI Ada-002（延迟最低）
```

#### 增量索引更新策略

全量重建索引在大项目中代价高昂。Serena 采用**事件驱动的增量更新**：

```python
# 伪代码：基于文件系统事件的增量索引
import asyncio
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class IncrementalIndexHandler(FileSystemEventHandler):
    def __init__(self, indexer: "CodeIndexer"):
        self.indexer = indexer
        self.debounce_delay = 2.0  # 防抖：2秒内的变更合并处理
        self.pending_changes: dict[str, asyncio.Task] = {}

    def on_modified(self, event):
        if event.is_directory or not self._is_code_file(event.path):
            return
        self._schedule_update(event.path, "modify")

    def on_created(self, event):
        if event.is_directory or not self._is_code_file(event.path):
            return
        self._schedule_update(event.path, "add")

    def on_deleted(self, event):
        if event.is_directory or not self._is_code_file(event.path):
            return
        asyncio.create_task(self.indexer.delete(event.path))

    def _schedule_update(self, path: str, operation: str):
        """防抖：同一个文件的多次变更合并为一次更新"""
        # 取消已存在的待处理任务
        if path in self.pending_changes:
            self.pending_changes[path].cancel()

        # 创建新的防抖任务
        async def delayed_update():
            await asyncio.sleep(self.debounce_delay)
            if operation in ("add", "modify"):
                await self.indexer.reindex_file(path)
            elif operation == "delete":
                await self.indexer.delete(path)
            del self.pending_changes[path]

        self.pending_changes[path] = asyncio.create_task(delayed_update())

# 启动文件监控
indexer = CodeIndexer()
observer = Observer()
observer.schedule(IncrementalIndexHandler(indexer), path="/project", recursive=True)
observer.start()
```

### 编辑层：原子操作与依赖管理

Serena 的编辑层是其与简单 AI 补全工具的核心差异。它不执行"字符串替换"，而是在**代码结构层面**理解和修改代码。

#### AST 依赖图构建

Serena 使用 tree-sitter 构建代码的 AST 依赖图：

```python
# 伪代码：基于 tree-sitter 的依赖图构建
import tree_sitter_languages
from tree_sitter import Language, Parser

class DependencyGraphBuilder:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.parsers: dict[str, Parser] = {}
        self.graph: nx.DiGraph = nx.DiGraph()  # 有向无环图

    def build_for_file(self, file_path: str):
        """为单个文件构建 AST 并提取依赖"""
        suffix = Path(file_path).suffix
        lang = self._get_language(suffix)

        with open(file_path) as f:
            tree = lang.parse(f.read())

        # 提取函数/类定义和调用
        calls = self._extract_calls(tree.root_node, file_path)
        definitions = self._extract_definitions(tree.root_node, file_path)

        # 添加节点和边
        for node_id, node_info in definitions.items():
            self.graph.add_node(node_id, type="definition", **node_info)

        for caller, callee in calls:
            self.graph.add_edge(caller, callee, type="call")

    def _extract_calls(self, node: Node, file_path: str) -> list[tuple[str, str]]:
        """递归提取函数调用关系"""
        calls = []

        # 遍历所有 Call 节点
        for call_node in node.walk():  # 注：实际应使用 tree-sitter 的 query
            if call_node.type == "call":
                # 获取被调用的函数名
                func_name = self._get_function_name(call_node)
                if func_name:
                    caller = f"{file_path}:{self._get_enclosing_func(node)}"
                    callee = f"{func_name}"  # 后续通过索引解析真实位置
                    calls.append((caller, callee))

        return calls

    def get_impacted_nodes(self, modified_node: str) -> set[str]:
        """获取修改某个节点会影响的所有下游节点"""
        # 使用 BFS 查找所有可达节点
        impacted = set()
        queue = [modified_node]

        while queue:
            current = queue.pop(0)
            for successor in self.graph.successors(current):
                if successor not in impacted:
                    impacted.add(successor)
                    queue.append(successor)

        return impacted
```

#### 编辑验证与回滚

每个编辑操作都经过**语法验证、语义验证、构建验证**三层检查：

```python
# 伪代码：原子编辑执行器
class AtomicEditExecutor:
    def __init__(self, project_root: str, git_client: "GitClient"):
        self.project_root = project_root
        self.git_client = git_client
        self.validator = TreeSitterValidator()

    async def execute(self, edit: CodeEdit) -> EditResult:
        """
        原子化执行编辑：验证 → 备份 → 应用 → 构建验证 → 失败回滚
        """
        file_path = self.project_root / edit.file_path

        # Step 1: 语法验证（tree-sitter）
        if not self.validator.is_syntactically_valid(edit.new_content, file_path.suffix):
            return EditResult(success=False, error="语法错误")

        # Step 2: 语义验证（调用关系检查）
        impacted = self._get_impacted_functions(edit)
        for impacted_func in impacted:
            if not self._verify_interface_compatible(edit, impacted_func):
                return EditResult(
                    success=False,
                    error=f"接口变更影响: {impacted_func}"
                )

        # Step 3: Git 快照（失败时回滚）
        snapshot_id = await self.git_client.create_snapshot(
            message=f"Pre-edit snapshot: {edit.description}"
        )

        # Step 4: 应用编辑
        try:
            original_content = file_path.read_text()
            file_path.write_text(edit.new_content)

            # Step 5: 构建验证
            if not await self._verify_build(file_path):
                raise BuildError("构建失败")

            # Step 6: 增量测试（如果有测试用例）
            if not await self._run_targeted_tests(impacted):
                raise TestError("测试失败")

            return EditResult(success=True, snapshot_id=snapshot_id)

        except (BuildError, TestError) as e:
            # 回滚到快照
            await self.git_client.restore_snapshot(snapshot_id)
            return EditResult(success=False, error=str(e), rolled_back=True)
```

## 为什么 MCP 是关键

如果把 Serena 的检索和编辑能力看作"肌肉"，MCP 协议就是"神经系统"。

**统一接口的价值**：没有 MCP，Serena 每连接一个新工具都需要定制开发——文件操作一套 API、Git 操作一套 API、数据库操作又一套 API。有了 MCP，只需要一个 Client 实现，就能连接任何兼容 MCP 的 Server。

**可组合性的价值**：MCP 的 Sampling 机制使得 Server 可以二次封装 AI 能力。例如，一个"代码审查 Server"可以内部调用 AI 判断代码质量，将结果返回给 Serena，再由 Serena 协调其他 Server 执行修复。

**生态现状**：MCP 生态已覆盖 VSCode 扩展、文件系统、Git、Slack、Redis、数据库等常用工具，Serena 可以直接复用这些 Server，无需重复开发。

## 技术对比

### Serena vs Cursor

| 维度 | Cursor | Serena |
|------|--------|--------|
| **架构哲学** | 规则引擎 + AI 混合 | MCP 协议 + 语义索引 |
| **上下文范围** | 当前文件 + 邻接文件 | 整项目语义图谱 |
| **编辑粒度** | diff 应用（可能破坏结构） | AST 级别（保持语法正确） |
| **工具扩展性** | 插件系统 | MCP Server 生态 |
| **离线能力** | 需联网 | 本地模型可离线 |

Cursor 采用规则引擎处理确定性操作（如自动导入、重命名），AI 处理创意性补全。Serena 则将所有操作都交给 AI，通过 MCP 获取项目级别的上下文。两者代表了不同的设计路线：Cursor 追求**确定性优先**，Serena 追求**通用性优先**。

### Serena vs Copilot

| 维度 | Copilot | Serena |
|------|---------|--------|
| **部署模式** | 云端 API | 本地 + 可选云端 |
| **上下文** | 当前文件 + 开源许可片段 | 整项目语义索引 |
| **交互方式** | 补全（Completions） | 对话 + 工具调用 |
| **编辑控制** | 用户接受/拒绝 | 原子化执行 + 回滚 |

Copilot 本质上是**云端 LLM 的智能补全**，上下文受限于 token 窗口。Serena 是**本地 Agent 系统**，通过 MCP 持久化上下文，通过向量检索突破 token 限制。

### Serena vs LangChain Tool Calling

| 维度 | LangChain | Serena |
|------|-----------|--------|
| **协议** | 自定义 Python API | MCP 标准协议 |
| **工具定义** | 代码定义 | JSON Schema 定义 |
| **调用方式** | 函数调用 | JSON-RPC 请求/响应 |
| **状态管理** | 外部状态 | 协议内建状态 |

LangChain 的工具调用是 Python 函数调用，依赖链式 Python 代码。Serena/MCP 将工具调用**协议化**，任何语言实现的 Client 都可以调用任何语言实现的 Server。

## 当前局限

Serena 仍处于早期阶段，以下挑战有待解决：

1. **语义检索精度**：Embedding 模型对代码结构的理解仍有局限，复杂的多语言项目可能检索到大量噪声。

2. **编辑验证延迟**：每次编辑都运行构建验证，在大型项目中可能耗时数秒，影响交互流畅性。

3. **MCP 生态成熟度**：虽然生态在扩展，但企业级 Server（如 Kubernetes、Terraform）的 MCP 实现仍不完善。

4. **并发控制**：多 Server 并发调用时的竞态条件尚未完全解决。

## 总结

Serena 展示了一种 AI 编程工具的未来形态：以 MCP 协议为神经中枢，以语义检索为感知层，以原子化编辑为执行层，构建出一个真正理解代码结构的 AI Agent IDE。

MCP 协议的价值不仅在于"统一接口"，更在于它定义了**有状态的、可以双向通信的会话协议**。Sampling 机制使得 Server 可以二次封装 AI 能力，这为构建复杂的 Agent 协作系统奠定了基础。

AI 编程工具的下一阶段竞争，将是**协议标准化和上下文管理能力**的竞争。Serena 在这个方向上迈出了重要的一步。

## 相关资源

- [Serena 官方仓库](https://github.com/oraios/serena)
- [MCP 协议规范](https://modelcontextprotocol.io/)
- [Anthropic MCP 博客介绍](https://www.anthropic.com/news/model-context-protocol)
- [modelcontextprotocol/python SDK](https://github.com/modelcontextprotocol/python)

## 相关文章

- [Serena 开源 AI 编程 Agent IDE](/post/serena开源ai编程agent-ide/) — Serena 工具快速上手
- [AgentScope Java: Agent-Oriented Programming for LLM Applications](/post/agentscope-java-agent-oriented-programming-for-llm-applications/) — 另一个 Agent 编程框架

---

*欢迎分享到 [X/Twitter](https://twitter.com/intent/tweet?text=Serena 架构解析：MCP 协议如何驱动 AI 编程 Agent IDE&url=https://www.onlythinking.com/post/serena-mcp-protocol-deep-dive/)*
