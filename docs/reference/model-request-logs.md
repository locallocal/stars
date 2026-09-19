# 模型请求日志

在「会话详情 → 模型请求日志」开启。每个会话默认关闭，开关独立持久化；可复制本会话日志目录或通过系统文件管理器打开。关闭后该会话停止写入，已有文件保留。“我的 → 帮助与支持”不再提供全局开关。

日志位于应用文档目录下的 `Stars/logs/models/conversations/<会话 ID 的 SHA-256>/`，会话详情显示当前会话的完整路径。路径组件使用固定长度摘要，避免特殊会话 ID 越界或超过文件系统长度限制；每条日志中的 `chat_id` 保留原始会话 ID。

- 当前文件：`model-requests.jsonl`，每行是一个独立 JSON 对象。
- 轮转文件：`model-requests.1.jsonl` 至 `model-requests.4.jsonl`，编号越小越新。
- 每个文件上限 10 MiB，每个会话独立保留 5 个日志文件。
- 每个会话目录中的 `settings.json` 仅保存该会话开关，不保存模型密钥。

旧版根目录中的全局 `settings.json` 不再生效，也不会自动开启所有会话；旧日志保留。会话重命名、更换智能体不改变配置，后台任务重启恢复后仍按任务所属会话读取开关。未绑定会话的模型目录查询、智能体调试等调用不写入会话日志。

## 记录内容

每次实际 HTTP 请求生成独立的 `request_id`，重试、工具结果回传后的下一轮请求都会生成新 ID。公共字段包括 `schema_version`、UTC 时间、`chat_id`、`bot_id`、厂商、模型及 `operation`。

| 事件 | 内容 |
| --- | --- |
| `request` | 请求方法、脱敏 URL/请求头、请求正文（模型参数、消息上下文、工具定义、工具结果） |
| `response_headers` | HTTP 状态码、脱敏响应头、收到响应头的耗时 |
| `response` | 响应正文、总耗时、字节数、是否截断，以及 `completed` / `cancelled` / `stream_error` |
| `transport_error` | 未获得响应时的传输异常 |
| `stream_error` | 读取响应流时的异常；随后仍记录已收到的响应内容 |
| `request_interrupted` | 媒体工作进程被取消、超时或意外终止；关联尚未完成的请求 |

`completed` 表示响应流读取结束，HTTP 成功与否仍看 `status_code` 和正文。模型返回的工具调用、推理字段、token 用量等会按原响应结构保留。SSE 的 `data:` 行解析为 JSON 数据，NDJSON 按行解析；不会再调用模型生成日志摘要。

OpenAI、Anthropic 和 Moonshot 的会话会标记 `skill_activation`、`foreground_routing` 或 `model` 阶段；独立 HTTP 操作默认标记 `model`，部分模型目录查询标记 `model_catalog`。日志通过 `chat_id` 和 `request_id` 关联；当前不包含后台任务 ID。

## 数据与性能边界

日志包含对话正文。接口密钥、认证头、Cookie、常见凭据字段、URL 用户信息和查询参数会脱敏；图片、音频等附件的二进制和常见 Base64 字段省略，multipart 只保留字段和文件元数据。任意自由文本中的私人信息不保证被识别，分享日志前仍需检查正文。

单次请求或响应正文最多捕获 2 MiB。超出限制的普通 JSON 正文省略，SSE 保留限制内完整的行，均标记 `body_truncated`。无法可靠解析的残缺 JSON 省略，防止将未完成的凭据或附件数据写入磁盘。响应头即时记录，响应正文在读取完成、错误或取消时记录；进程异常退出前尚未完成的正文不保证落盘。

每个会话的队列最多保留 8 MiB 待写数据，超限会丢弃条目，并在下次接受的条目中附上 `dropped_entries`。磁盘写入异常在设置页显示，不传播到模型请求。日志是排障记录，不是事务审计存储。

## 实现与验证

`ProviderLoggingClient` 包装 HTTP 客户端，原样转发响应字节、暂停、恢复及取消，不等待整个响应才交给调用者。`Provider` 提供统一的客户端包装及一次性请求入口，保留注入的测试客户端和既有客户端关闭语义。

`AiProviderRepositoryImpl.forConversation(chatId)` 创建绑定会话的仓库，`FileConversationModelLogRepository` 为每个会话提供共享写入器。前台路由、技能激活、上下文压缩、任务模型轮次、进度/终态润色和媒体生成均显式传入原始会话 ID，不依赖当前打开的页面或智能体 ID。媒体 isolate 只发送已经脱敏的事件，通过同一端口按顺序返回主 isolate，由 `FileModelLogRepository` 串行写入，避免多个执行进程交错写同一个文件。

设置视图使用 `ShadSwitch`、`ShadButton` 和主题文字颜色，窄屏操作按钮自动换行。`ModelLogViewModel` 绑定会话 ID，负责加载、持久化、忙碌状态和错误反馈，界面不直接执行文件操作。

测试覆盖请求/响应关联、技能激活多轮调用、密钥与附件脱敏、SSE 分块和 UTF-8、取消、传输错误、日志故障隔离、文件轮转、设置持久化、媒体 isolate、同一智能体并发会话隔离、切换会话时的开关状态以及宽屏/窄屏布局。
