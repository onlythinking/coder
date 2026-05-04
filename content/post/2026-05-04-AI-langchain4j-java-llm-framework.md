---
title: "LangChain4j：Java/JVM 生态的 LLM 应用开发框架"
date: "2026-05-04"
description: "LangChain4j 是 Java/JVM 生态最成熟的 LLM 开发框架，支持 20+ LLM Provider、统一 Tool Calling API、MCP 协议，与 Spring Boot/Quarkus 深度集成。本文系统介绍其核心特性、架构设计与快速上手路径。"
tags: ["Java", "LLM", "LangChain4j", "RAG", "AI Agent", "JVM"]
categories: ["AI"]
keywords: ["LangChain4j", "Java LLM", "JVM AI", "RAG框架", "Spring Boot AI", "Quarkus AI", "Tool Calling", "MCP协议"]
draft: false
cover: /images/covers/2026-05-04-AI-langchain4j.png
---

## 引言

当 Python 开发者用 LangChain 快速搭建 AI 应用时，Java 开发者往往面临一个尴尬的局面：主流 LLM 库几乎都是 Python-first，想要在 Spring Boot 或 Quarkus 项目里接入 GPT、Claude 或国产大模型，要么自己造轮子，要么只能写薄薄一层 SDK 封装。

LangChain4j 正是为解决这一问题而生。

LangChain4j 是一个开源的 Java 库，旨在简化 LLM 集成到 Java 应用程序的过程。它的名字里带着 "LangChain"，但**它并不是 Python LangChain 的 Java 移植版**——从 API 设计到内部实现，都是从零开始围绕 Java 习惯构建的：类型安全、POJO、注解、接口、依赖注入、流式 API。项目始于 2023 年初 ChatGPT 热潮期间，截至目前已在 GitHub 收获 **11,843 Stars** 和 **2,186 Forks**，最新版本为 **1.14.0**（2026-04-30）。

本文系统解析 LangChain4j 的核心设计理念、功能版图与快速上手路径。

<!-- toc -->

## 1. 核心设计理念：Java-First，而非移植

LangChain4j 团队在 README 中明确声明：

> "Despite the name, LangChain4j is not a Java port of LangChain (Python) — it is built for Java, not ported to it."

这意味着它不是简单地将 Python API 翻译成 Java 语法，而是充分尊重 Java 生态的工程习惯：

- **类型安全**：充分利用 Java 泛型和编译时检查，减少运行时异常
- **依赖注入友好**：天然适配 Spring Boot、Quarkus、Helidon、Micronaut 四大主流框架
- **注解驱动**：通过 `@Agent`、`@Tool`、`@SystemMessage` 等注解定义行为，代码即配置
- **流式 API**：支持 Server-Sent Events（SSE）实时流式输出

这种设计让它能够直接融入企业级 Java 项目的现有架构，而不是引入一个"异类"。

## 2. 统一 API：20+ LLM Provider 与 30+ 向量存储

LLM 供应商（OpenAI、Google Vertex AI、Anthropic 等）和向量存储（Pinecone、Milvus、Weaviate 等）各有各的专有 API。如果每个都单独对接，工程量巨大且维护成本极高。

LangChain4j 提供了**统一的抽象层**，让你在切换 Provider 时无需改动业务代码：

### 2.1 支持的 LLM Provider（部分）

| 分类 | 示例 |
|------|------|
| 国际主流 | OpenAI (GPT-4o, o1, o3)、Anthropic Claude、Google Gemini、Azure OpenAI |
| 开源模型 | Llama.cpp、Ollama、LocalAI、HuggingFace Inference |
| 国内大模型 | DeepSeek（通过 OpenAI 兼容接口）、通义千问、百度文心 |
| 企业方案 | AWS Bedrock、Google Vertex AI、Azure AD |

> 具体支持列表请以 [官方集成文档](https://docs.langchain4j.dev/integrations/language-models/) 为准。

### 2.2 支持的向量存储

支持 30+ 向量数据库，包括 Milvus、Pinecone、Weaviate、Chroma、Qdrant、Redis（向量模块）、Elasticsearch 等主流选择。

这意味着你可以先用本地 Chroma 做开发，生产环境平滑切换到 Pinecone 或 Milvus，代码改动极小。

## 3. 核心功能版图

LangChain4j 的功能覆盖了从低阶提示词模板到高阶 Agent 模式的全链路：

### 3.1 提示词管理与模板化

```java
SystemMessage systemMessage = SystemMessage.from("你是一个专业的技术文档助手。");
UserMessage userMessage = UserMessage.from("请解释 {{concept}} 的原理。");
PromptTemplate template = PromptTemplate.from("{{userMessage}}");
Prompt prompt = template.apply(Map.of("userMessage", userMessage.text()));
```

### 3.2 Chat Memory（对话记忆）

支持多种内存实现：基于 Token 数量窗口限制、基于完整历史、基于摘要等。

```java
ChatMemory chatMemory = MessageWindowChatMemory.withMaxMessages(20);
ChatLanguageModel model = OpenAiChatModel.builder()
    .apiKey(System.getenv("OPENAI_API_KEY"))
    .build();
```

### 3.3 Tool Calling 与 MCP 支持

Tool Calling 是 LLM 应用的关键能力。LangChain4j 支持原生 Tool Calling 协议和 **MCP（Model Context Protocol）**[（详见《Serena MCP Protocol 深度解析》](https://www.onlythinking.com/post/2026-04-15-ai-serena-mcp-protocol-deep-dive/)）：

```java
class WeatherTool {

    @Tool("查询城市天气")
    String getWeather(@P("city") String city) {
        // 调用天气 API
        return "北京今天晴，26度";
    }
}

AiServices.builder(Assistant.class)
    .chatLanguageModel(model)
    .tools(new WeatherTool())
    .build();
```

### 3.4 AI Services（高层抽象）

[AI Services（高层抽象）](https://www.onlythinking.com/post/2026-04-27-ai-microsoft-autogen-agentic-ai-framework/)是 LangChain4j 最核心的高层 API——用接口 + 注解定义 AI 能力，实现类完全由框架生成：

```java
interface Assistant {

    @SystemMessage("你是一个乐于助人的助手。")
    String chat(@UserMessage String userMessage);
}

// 框架生成实现类
Assistant assistant = AiServices.create(Assistant.class, model);
String response = assistant.chat("什么是 RAG？");
```

### 3.5 Agent 模式

LangChain4j 内置了 ReAct 风格的 [Agent 模式](https://www.onlythinking.com/post/2026-04-13-ai-agentscope-java-agent-oriented-programming-for-llm-applications/)，支持多工具协作、复杂任务拆解与执行：

```java
Agent agent = Agent.builder()
    .chatLanguageModel(model)
    .chatMemory(chatMemory)
    .tools(weatherTool, searchTool, calculatorTool)
    .build();
```

### 3.6 RAG（检索增强生成）

完整覆盖 RAG 端到端流程：文档加载 → 分块（Chunking）→ 向量化 → 存储 → 检索 → 生成：

```java
DocumentLoader loader = new UrlDocumentLoader(url);
Document document = loader.load();
List<TextSegment> segments = new TextSplitter(200, 50).split(document);

EmbeddingStore<TextSegment> store = new PineconeEmbeddingStore.Builder()
    .apiKey(pineconeApiKey)
    .build();

EmbeddingModel embeddingModel = new AllMiniLmL6V2EmbeddingModel();
new EmbeddingStoreIngestor(embeddingModel, store).ingest(segments);

// 检索
List<Document<TextSegment>> results = store.similaritySearch("查询条件");
```

## 4. 框架深度集成

LangChain4j 对主流 Java 框架都提供了一等公民（First-Class）的集成支持：

| 框架 | 集成方式 | 示例仓库 |
|------|---------|---------|
| **Spring Boot** | `langchain4j-open-ai` + `@Autowired` | [spring-boot-example](https://github.com/langchain4j/langchain4j-examples/tree/main/spring-boot-example) |
| **Quarkus** | `quarkus-langchain4j` 扩展 | [quarkiverse/quarkus-langchain4j](https://github.com/quarkiverse/quarkus-langchain4j) |
| **Helidon** | `io.helidon.integrations.langchain4j` | Helidon 官方示例 |
| **Micronaut** | `micronaut-langchain4j` | Micronaut 官方文档 |

以 Spring Boot 为例，接入 LangChain4j 只需要引入依赖、配置 API Key，即可通过 `@Autowired` 注入使用：

```xml
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-open-ai</artifactId>
    <version>1.14.0</version>
</dependency>
```

```yaml
langchain4j:
  open-ai:
    api-key: ${OPENAI_API_KEY}
    model-name: gpt-4o
```

## 5. 快速上手

### 5.1 环境要求

- JDK 17+（部分功能需要 JDK 21+）
- Maven 或 Gradle

### 5.2 最小示例

```java
public class QuickStart {
    public static void main(String[] args) {
        // 1. 创建模型
        ChatLanguageModel model = OpenAiChatModel.builder()
            .apiKey(System.getenv("OPENAI_API_KEY"))
            .modelName("gpt-4o")
            .build();

        // 2. 定义接口
        interface Assistant {
            String chat(String userMessage);
        }

        // 3. 创建 AI 服务
        Assistant assistant = AiServices.create(Assistant.class, model);

        // 4. 调用
        String response = assistant.chat("用一句话解释什么是 LLM。");
        System.out.println(response);
    }
}
```

这四行代码即完成了一个完整的 LLM 对话调用——没有任何额外的配置负担。

## 6. 适用场景与局限性

### 适用场景

- **企业内部 AI 能力集成**：已有 Spring Boot/Quarkus 技术栈，LLM 能力需平滑接入
- **RAG 系统搭建**：需要对接向量数据库、做文档检索增强的企业知识库
- **多模型切换需求**：测试阶段用 OpenAI，生产环境切换到 DeepSeek 或本地模型
- **Tool Calling 驱动的业务自动化**：需要 LLM 调用外部 API、数据库查询、文件操作的场景

### 局限性

- **Python 生态成熟度差距**：相比 LangChain Python，LangChain4j 的社区规模和第三方插件生态仍有差距
- **部分前沿特性跟进速度**：一些实验性功能可能晚于 Python 版上线
- **文档以英文为主**：中文资料稀缺，需要有一定英文阅读能力

## 7. 总结

LangChain4j 填补了 Java/JVM 生态在 LLM 应用开发框架上的空白。它的核心价值在于：

1. **统一 API**：消除多 Provider 切换的研发成本
2. **Java-First 设计**：类型安全、注解驱动、框架原生集成，工程友好
3. **完整工具链**：从低阶 Prompt 模板到高阶 Agent/RAG，覆盖全场景
4. **企业框架适配**：Spring Boot、Quarkus、Helidon、Micronaut 全部原生支持

对于国内数量庞大的 Java 工程师群体来说，LangChain4j 是将 LLM 能力落地到企业项目的最具实操性的选择。随着 1.14.0 版本的发布和 MCP 协议的引入，它的应用场景还在持续扩展。

如果你正在 Java 项目中评估 LLM 集成方案，LangChain4j 值得优先关注。

---

**参考资料**

- LangChain4j GitHub：https://github.com/langchain4j/langchain4j
- 官方文档：https://docs.langchain4j.dev/
- Spring Boot 集成示例：https://github.com/langchain4j/langchain4j-examples/tree/main/spring-boot-example
- 最新版本 1.14.0：https://github.com/langchain4j/langchain4j/releases/tag/1.14.0
