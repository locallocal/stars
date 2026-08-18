# 智能体模型 Token 用量记录与展示设计

## 1. 背景与目标

Stars 需要记录智能体调用文本模型时由供应商返回的 Token 用量，并在以下位置展示：

- 会话右侧“智能体信息”面板：以每日图表展示当前会话 Token，支持按小时下钻；
- 智能体详情页面：展示该智能体所有历史会话的输入、输出和总 Token。

本设计只记录供应商明确返回的 usage，不使用字符数或词数推算 Token，避免不同模型分词器
造成误导。供应商未返回 usage 时，本次回复的 Token 用量保持为 0。

## 2. 设计原则

1. **按模型回复留存快照**：Token 用量属于一次模型调用，以稳定 `message_id` 独立持久化，
   不依赖可清空的消息正文，也不只维护一个可变累计值。
2. **历史配置可追溯**：每条记录保存调用发生时的模型名；智能体后续切换模型不会改写历史。
3. **幂等**：模型回复使用稳定的 `message_id` upsert，同一次运行重复完成不会重复累计。
4. **真实数据优先**：只接收供应商响应中的 usage；缺失时不做本地估算。
5. **删除语义明确**：清空会话只删除内容并保留用量；删除整个会话时才删除对应 Token 记录。
6. **保持分层边界**：View 只消费领域模型和 ViewModel，不直接查询 SQLite。

## 3. 数据模型

领域对象 `ModelTokenUsage` 包含：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `model` | `String` | 本次调用使用的模型；聚合结果为空 |
| `inputTokens` | `int` | 输入/提示词 Token |
| `outputTokens` | `int` | 输出/补全 Token |
| `totalTokens` | `int` | 供应商返回的总 Token |
| `effectiveTotalTokens` | 计算值 | 有总量时使用总量，否则使用输入与输出之和 |

`Message` 使用不可空的 `tokenUsage`，默认值为全 0。这样用户消息和不提供 usage 的供应商
无需处理 `null`。

### 3.1 SQLite 变更

当前 v18 Schema 的 `messages` 表直接包含：

```sql
token_model TEXT NOT NULL DEFAULT '',
input_token_count INTEGER NOT NULL DEFAULT 0,
output_token_count INTEGER NOT NULL DEFAULT 0,
total_token_count INTEGER NOT NULL DEFAULT 0
```

当前 Schema 同时创建独立事实表 `token_usage_records`：

```sql
message_id TEXT PRIMARY KEY,
chat_id TEXT NOT NULL,
bot_id TEXT NOT NULL,
token_model TEXT NOT NULL,
input_token_count INTEGER NOT NULL,
output_token_count INTEGER NOT NULL,
total_token_count INTEGER NOT NULL,
timestamp INTEGER NOT NULL
```

表上分别建立 `chat_id` 与 `bot_id` 索引。应用不支持历史数据库升级或 usage 回填；后续消息
upsert 与 Token 记录同步在同一事务完成。清空会话仅删除 `messages`，保留
`token_usage_records`；删除整个会话则在同一事务删除两者。

智能体累计用量使用事实表 SQL `SUM` 查询，不把累计值写回 `bots` 表，避免写入重试造成
双写不一致。

## 4. 数据流

```text
供应商流式/非流式响应
        |
        v
Provider.decodeProviderResponse
  - 解码 JSON
  - 兼容常见 usage 字段
        |
        v
AiProvider.onTokenUsage
        |
        v
ChatGenerationViewModel
  - 合并分段 usage
  - 仅接受当前活动 run
        |
        v
终态 assistant Message.tokenUsage
        |
        v
MessageRepository -> SQLite messages + token_usage_records
        |
        +-----------------------------------+
        |                                   |
        v                                   v
按 chat_id 加载并按时间分桶             按 bot_id SQL 聚合
        |                                   |
        v                                   v
智能体信息面板日/小时图表              智能体详情三项图标指标
```

Token usage 与文本、推理、工具调用一样受 run id 保护。终态持久化开始后到达的迟到事件会被
忽略；取消或失败时，如果供应商已返回部分调用的 usage，则随保留的终态消息一并保存。

## 5. 供应商响应兼容

所有 JSON 型 AI 适配器使用统一响应解码入口。解析器兼容以下常见命名：

- OpenAI 兼容：`prompt_tokens`、`completion_tokens`、`total_tokens`；
- Anthropic：`input_tokens`、`output_tokens`；
- Gemini：`promptTokenCount`、`candidatesTokenCount`、`totalTokenCount`；
- Ollama：`prompt_eval_count`、`eval_count`；
- 对应的 camelCase 变体。

部分流式协议会先返回输入 Token，结束时再返回输出 Token。Provider 在单次请求内保留最新
快照并按非零字段合并，再通知上层。OpenAI 请求显式启用
`stream_options.include_usage`。

解析不到 usage 不会令生成失败，也不会影响正文解析。供应商新增字段形态时，只需扩展统一
解析器，不需要改动持久化和 UI。

## 6. 展示设计

### 6.1 会话右侧智能体信息面板

会话内容区不直接展示 Token。用户点击工具栏的“智能体信息”后，在右侧停靠面板或抽屉内
查看当前会话统计：

- 智能体信息面板默认宽度为 360px，可在停靠模式下调整到 280–420px，并始终为会话正文保留最小可读宽度；
- “Token 用量”和“每日用量 / 小时用量”标题不使用前置图标，左侧起点和字体样式与“智能体信息”标题一致；
- 顶部使用无边框的三行图标指标分别展示当前视图总量、输入和输出 Token，字段名与智能体信息行使用相同的左侧基线和字体样式；
- Token 汇总与每日 / 小时图表之间使用横向分隔线，形成两个独立信息区块；
- 单条消息的执行状态头部使用原副标题行依次展示耗时、输入 Token 和输出 Token，不再显示“包含耗时”；三项使用带前置图标的相同字体、行高和文字基线，耗时图标与“执行状态”文字左侧上下对齐，没有明细时不展示 Token 项；
- 执行状态标题、指标、工具/命令/文件详情、推理状态及终态提示均通过 `S` 国际化，并覆盖应用支持的全部 12 种语言；
- “选择一天查看小时用量”提示复用通用设置中“会话执行状态”注释的字体样式，并与每日用量标题左对齐；
- 默认按天聚合，以日期纵向排列的横向条形图展示总 Token，缺少数据的日期保留 0 值条；
- 点击任意日期后进入该日小时横向条形图，包含时间范围内的无用量小时；
- 当选择今天时，小时图仅展示 00:00 至当前小时，尚未到达的小时不生成；历史日期仍展示完整 24 小时；
- 小时视图在“小时用量”标题右侧提供返回按钮，恢复每日视图；
- 横向条形图 Tooltip 和语义标签包含完整输入、输出与总量。

`ChatTokenUsageViewModel` 从 `MessageRepository` 加载当前会话的独立 Token 记录，在 UI 层
按本地时区进行日/小时分桶。它同时监听消息与会话 Repository 的变更流，因此新回复完成、
清空历史或删除操作会触发刷新；清空历史后的刷新仍读取保留的 Token 记录。每日视图的图标
摘要表示整个会话，小时视图的摘要只表示选中的一天。

### 6.2 智能体详情页面

新增“Token 用量”分组，使用三个带图标指标展示：

- Token 总量；
- 输入 Token；
- 输出 Token。

页面通过 `BotTokenUsageViewModel` 调用 `MessageRepository` 聚合，加载过程中显示小型进度
指示器。详情页面没有 `AppScope` 的独立组件测试环境使用 0 值降级，不访问数据层。

## 7. 异常与一致性

- usage 字段缺失、类型不合法或为负数：忽略该字段；
- 只返回输入或输出：总量回退为已知字段之和；
- 当前 Schema 中消息的四个 usage 字段均有默认值；
- 重复终态：稳定 `message_id` upsert，并由生成 ViewModel 的 finalizing 集合阻止重复写入；
- 清空会话：删除消息正文但保留 Token 事实记录，右侧面板刷新后统计不变；
- 删除会话：同时删除消息正文和该会话的 Token 事实记录；
- usage 聚合加载失败：不阻塞智能体配置编辑，保持 0 值展示。

## 8. 测试策略

- 数据库 Schema 测试：验证当前字段、事实表、索引和非当前版本拒绝策略；
- Repository 测试：验证消息 usage 往返序列化、按智能体隔离聚合，以及清空内容后统计保留；
- Provider 测试：验证 usage-only 尾帧既不产生正文错误又能提取用量；
- 生成 ViewModel 测试：验证 usage 只绑定到一条终态消息；
- ViewModel 测试：验证连续日分桶、跨日聚合、24 小时下钻和变更后刷新；
- Widget 测试：验证图标摘要、每日柱状图、点击日期下钻、返回交互和语义标签；
- 全量执行 `dart analyze` 与 `flutter test`，防止厂商适配器统一解码改造产生回归。

## 9. 后续扩展

如果未来需要费用统计，可在每条 usage 事实记录之外增加独立的模型价格版本信息。费用应按
调用发生时的价格计算并持久化，不能使用当前价格回算历史。若需要按模型、日期或供应商分析，
可继续扩展事实表字段与索引，而无需改变本次 UI 契约。
