---
title: "CrabTrap: 用 HTTP 代理给 AI Agent 套上安全缰绳"
date: "2026-04-22"
description: "CrabTrap 是 Brex 开源的 LLM-as-a-judge HTTP 代理，通过静态规则和 LLM 判断双重机制为 AI Agent 提供运行时安全防护，解决 Agent 越权访问外部 API 的安全问题，支持 SSRF 防护与 Prompt 注入检测"
tags: ["AI", "Agent", "安全", "代理", "LLM"]
categories: ["AI"]
keywords: ["CrabTrap", "AI Agent安全", "HTTP代理", "LLM judge", "SSRF防护", "Prompt注入"]
readingTime: 9 分钟
toc: true
draft: false
cover: /images/covers/crabtrap-http-proxy-ai-agent-security.png
---

## 背景

当 AI Agent 开始帮你发邮件、操作 GitHub、调用 Slack API——它实际上成了一台拥有互联网访问权限的自动化程序。传统 API 调用链是确定性的：写什么代码、调什么接口、返回什么结果，开发者了然于胸。但 Agent 时代，这个链条被 LLM 的不确定性打破了：Agent 可能调用错误的 API、访问不该访问的内部服务，甚至因为 Prompt 注入攻击而执行恶意操作。

这时候需要一个**安全代理层**，在 Agent 的每一次对外请求真正发出之前，替它做一次检查和决策。Brex 开源的 **CrabTrap** 正是这样一套解决方案。

## 问题：Agent 失控的三大风险

在实际部署 Agent 时，外部 API 调用面临三类核心风险：

**1. 越权访问（Over-privileged Access）**
Agent 被授予了某个 OAuth token（如 Gmail 读/写权限），但正常任务只需要读取权限。缺乏约束的 Agent 可能会执行删除、发送等超额操作。

**2. Prompt 注入攻击**
恶意的输入（邮件正文、网页内容）包含隐藏的 Prompt 注入指令，Agent 在处理这些内容时不知不觉执行了第三方注入的命令。

**3. SSRF（服务端请求伪造）**
Agent 在调用外部 API 时，可能被诱导向内部服务（如 `http://169.254.169.254/` 获取云元数据）发起请求，造成数据泄露。

传统方案（如 IAM 权限最小化、网络隔离）效果有限，因为 Agent 的行为空间远大于普通程序，且 LLM 的输出不可预测。

## 原理：CrabTrap 的双层决策引擎

CrabTrap 是一个运行在 Agent 和外部 API 之间的 HTTP/HTTPS 正向代理。它的核心是一个**双层请求决策引擎**：

### 第一层：静态规则（Static Rules）

静态规则是最快的判断路径——基于 URL 模式（前缀匹配、精确匹配、Glob 模式）和可选的 HTTP 方法过滤器做确定性决策。命中 Deny 规则的请求直接返回 403；命中 Allow 规则的请求直接放行。

```bash
# 示例：禁止 Agent 访问 AWS 元数据端点
static_rules:
  - pattern: "http://169.254.169.254/**"
    action: deny
  - pattern: "https://*.github.com/api/v3/**"
    action: allow
    methods: ["GET", "POST"]
```

静态规则的优势是**零延迟、零成本**——不需要调用任何 LLM，命中规则立即决策。

### 第二层：LLM Judge

无法被静态规则覆盖的请求，会被送到 LLM Judge。LLM Judge 用自然语言安全策略来评估每一条请求：

```yaml
llm_judge:
  provider: openai        # 支持 OpenAI / Anthropic / 本地模型
  model: gpt-4o-mini
  fallback_mode: deny      # LLM 不可用时默认拒绝
  policy: "只允许访问工作相关的外部 API，禁止访问私人账户、金融操作类接口"
```

LLM Judge 的输入包括：
- 请求的完整信息（URL、Method、 Headers、Body）
- Agent 的自然语言安全策略
- 历史行为摘要

输出是 `{ "decision": "allow" | "deny", "reason": "..." }`。

CrabTrap 还内置了**熔断器（Circuit Breaker）**：连续 5 次 LLM 调用失败后自动熔断，10 秒后重试，避免 LLM 服务故障导致 Agent 完全挂死。

### TLS 中间人拦截

CrabTrap 作为 HTTPS 代理，需要对流量进行 TLS 终结。它会为每个目标主机动态生成由自签名 CA 签发的证书，从而解密 HTTPS 请求进行检查。要使 Agent 信任这些证书，只需将 CrabTrap 的 CA 证书导入 Agent 的信任存储：

```bash
docker compose cp crabtrap:/app/certs/ca.crt ./ca.crt
# 将 ca.crt 添加到系统或应用的 CA 证书存储
```

## 实践：5 分钟快速上手

### 环境要求

- Docker 与 Docker Compose
- PostgreSQL（CrabTrap 用它存储审计日志）

### 启动

```bash
# 1. 启动 CrabTrap + PostgreSQL
docker compose up -d

# 2. 导出 CA 证书
docker compose cp crabtrap:/app/certs/ca.crt ./ca.crt

# 3. 创建管理员账户
admin_token=$(docker compose exec -it crabtrap ./gateway create-admin-user test-admin | tail -n1 | cut -d" " -f2)

# 4. 配置 Agent 使用代理（Linux/macOS）
export HTTP_PROXY="http://localhost:8080"
export HTTPS_PROXY="http://localhost:8080"

# 5. 信任 CA 证书（Linux）
cp ca.crt /usr/local/share/ca-certificates/crabtrap.crt
update-ca-certificates

# 6. 验证
curl --cacert ca.crt https://httpbin.org/get
```

如果一切正常，你应该看到 `httpbin.org` 的 JSON 响应。如果配置了 Deny 规则访问 `169.254.169.254`，则返回 403。

### 配置安全策略

通过 Admin UI（`http://localhost:8081`）或 YAML 配置文件定义静态规则和 LLM 安全策略：

```yaml
approval:
  mode: llm                    # llm | passthrough
  timeout: 30s

llm_judge:
  provider: openai
  model: gpt-4o-mini
  fallback_mode: deny

proxy:
  port: 8080
  rate_limit: 50 req/s
  burst: 100
```

## 安全边界与局限性

CrabTrap 文档明确列出了它**不做什么**，了解这些对于正确使用至关重要：

| 不做的 | 说明 |
|--------|------|
| 非入站防火墙 | CrabTrap 是正向（出站）代理，不检查进入服务的请求 |
| 数据脱敏 | 请求内容（Header、Body）在代理层是明文可见的，信任边界在代理本身 |
| 人工审批 | 没有审批队列，所有决策自动完成 |
| 响应检查 | 只检查出站请求，不检查 API 返回的内容 |
| WebSocket 检查 | 只评估 WebSocket 升级请求，升级后的帧不检查 |

## 审计与合规

CrabTrap 将每一次请求、决策和响应完整记录到 PostgreSQL：

```sql
SELECT timestamp, agent_id, method, url, decision, reason
FROM audit_log
WHERE decision = 'deny'
ORDER BY timestamp DESC
LIMIT 20;
```

这对于 SOC 2、ISO 27001 等合规框架下的 API 操作审计非常有价值。

此外，CrabTrap 提供了一个**策略构建器（Policy Builder）**——分析历史流量日志，自动生成初始安全策略建议，再用 LLM 迭代优化。

## 总结

CrabTrap 解决了一个真实且紧迫的问题：当 LLM Agent 开始操作真实世界的外部服务时，如何在不影响工作效率的前提下，给它套上可控的安全缰绳。它的双层决策架构（静态规则 + LLM Judge）在安全性和灵活性之间找到了很好的平衡点，熔断器设计和详尽的审计日志则让它适合生产环境使用。

如果你正在构建或部署 AI Agent，特别是那些需要调用外部 API（邮件、日历、GitHub、Slack 等）的场景，CrabTrap 值得加入你的安全工具箱。

## 相关资源

- GitHub: [https://github.com/brexhq/CrabTrap](https://github.com/brexhq/CrabTrap)
- 官方文档: [https://www.brex.com/crabtrap](https://www.brex.com/crabtrap)
- 架构设计: [DESIGN.md](https://github.com/brexhq/CrabTrap/blob/main/DESIGN.md)
- 配置参考: [gateway.yaml.example](https://github.com/brexhq/CrabTrap/blob/main/config/gateway.yaml.example)

---

> 如果觉得这篇文章有帮助，欢迎分享：
> 
> - **X/Twitter**: [https://x.com/intent/tweet?text=CrabTrap%3A%20%E7%94%A8%20HTTP%20%E4%BB%A3%E7%90%86%E7%BB%99%20AI%20Agent%20%E5%A5%97%E4%B8%8A%E5%AE%89%E5%85%A8%E7%BB%87%E7%BB%95&url=https%3A%2F%2Fwww.onlythinking.com%2Fpost%2Fcrabtrap-http-proxy-ai-agent-security%2F](X/Twitter)
> - **微信**: 扫码分享或搜索公众号「编程码农」
