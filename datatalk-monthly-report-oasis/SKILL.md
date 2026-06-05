---
name: 绿洲看板月度报告
description: "绿洲业务灯塔DataTalk看板月度报告生成与推送。通过DataTalk MCP拉取指定看板数据，生成结构化监控月报（离线号码包监控、人工配额监控），并推送至企业微信群机器人。触发词：绿洲看板、灯塔监控、DataTalk看板总结、看板推送、绿洲月报。"
agent_created: true
---

# 灯塔 DataTalk 看板监控总结

## Purpose

通过 DataTalk MCP 工具定期拉取 Beacon 灯塔看板数据，自动生成结构化的监控月报，并通过企业微信群机器人 Webhook 推送至指定群。

## 监控看板

| 看板 | pageId | bizId | 说明 |
|------|--------|-------|------|
| 绿洲_离线号码包监控 | 319689 | ic_pcg_social | 监控离线号码包上传量、分布、操作人 |
| 绿洲_虚拟金配额 | 307333 | ic_pcg_social | 监控人工配额、虚拟金入账、现金入账 |

## When to Use

- 用户要求生成灯塔看板监控总结
- 用户要求推送 DataTalk 看板数据到企微群
- 每月定期自动执行（通过 automation）
- 用户提到"灯塔"、"beacon"、"DataTalk"、"看板总结"、"监控推送"

## Prerequisites

### 必需配置（存储在 config.json）

1. **企微群机器人 Webhook URL**：在目标群 → 群机器人 → 添加机器人 → 获取 Webhook 地址
2. **看板配置**：已预填 pageId 和 bizId

### 配置文件路径

```
~/.workbuddy/skills/beacon-datatalk-monitor/config.json
```

## Workflow

### Step 1: 加载配置

1. 读取 `~/.workbuddy/skills/beacon-datatalk-monitor/config.json`
2. 校验 `wecom_webhook_url` 是否已配置
3. 如未配置，提示用户补充后重试

### Step 2: 确认查询时间范围

**必须由用户指定查询年月**（格式：`2026-05`），不能自行假设。

询问用户："请指定要查询的年月（如 2026-05），我将拉取该月数据生成监控报告。"

获得年月后，构造时间变量：
- `select_fldhc73a_value`（319689 指标卡月份变量）：值如 `"2026-05"`
- `timeRange_6zkxb5xl_value`（319689 表格时间范围）：值如 `"2026-05-01 00:00:00,2026-05-31 23:59:59"`
- `timeRange_mlzlll81_value`（307333 表格时间范围）：值如 `"2026-05-01 00:00:00,2026-05-31 23:59:59"`

### Step 3: 通过 DataTalk MCP 拉取看板数据

**必须使用司内部署模型调用 DataTalk MCP 工具**（外部模型会被拒绝）。

#### 3.1 看板 319689（绿洲_离线号码包监控）

**数据来源图卡：**

| cardId | 名称 | 用途 |
|--------|------|------|
| `indexCardUltra_3zwza917` | 当月离线号码包上传数量 | 核心指标：总数+环比 |
| `table_k4eaxvn0` | 明细表格 | 操作人/游戏/crowd_name 明细，用于判断用途 |

**查询步骤：**

1. 查 `indexCardUltra_3zwza917`，传入 `select_fldhc73a_value="2026-05"` 获取当月总数和环比
2. 查 `table_k4eaxvn0`，传入 `timeRange_6zkxb5xl_value="2026-05-01 00:00:00,2026-05-31 23:59:59"` 获取明细
3. 从 `table_k4eaxvn0` 结果中统计：游戏分布、crowd_name 用途判断

**用途判断规则（基于 crowd_name）：**
- 含 `测试`/`test` → 测试人群
- 含 `补发`/`reissue`/`Q币` → 补发/补偿
- 含 `lookalike`/`拓展`/`expand` → Lookalike 拓展
- 含 `exclude`/`排除` → 排除人群
- 其他 → 生产人群

#### 3.2 看板 307333（绿洲_虚拟金配额）— 人工菜单

**只看"人工"菜单**，核心回答两个问题：
1. 人工配额虚拟金/现金的量级是多少？较上月环比变动（结果为空=0）
2. 人工配额到哪些游戏上了？原因（从"备注"字段判断）是啥？

**数据来源图卡：**

| cardId | 名称 | 用途 |
|--------|------|------|
| `indexCardUltra_3zm562t4` | 本月人工配额总量级 | 核心指标：虚拟金/现金总量+环比 |
| `table_rtwwu7h7` | 明细表格 | 含 detail_quota_amount、detail_desc、account_type、game_name |
| `barHorizontal_dg2wwkdn` | 人工配额量级Top游戏 | 游戏分布 |

**关键变量：**
- `timeRange_mlzlll81_value`：时间范围，格式 `"2026-05-01 00:00:00,2026-05-31 23:59:59"`
- `radio_5v1tfm7p_value`：account_type，`"1"`=虚拟金，`"2"`=现金

**查询步骤：**

1. 查 `table_rtwwu7h7`，`radio_5v1tfm7p_value="1"`（虚拟金），获取 查询月 明细
2. 查 `table_rtwwu7h7`，`radio_5v1tfm7p_value="2"`（现金），获取 查询月 明细
3. 查 `table_rtwwu7h7`，`radio_5v1tfm7p_value="1"`，获取 上月 明细（用于环比）
4. 查 `table_rtwwu7h7`，`radio_5v1tfm7p_value="2"`，获取 上月 明细（用于环比）
5. 汇总：虚拟金总量、现金总量、游戏分布（按 account_type 分别统计）

**备注判断规则（基于 detail_desc）：**
- 备注含 `测试`/`test` → 测试用途
- 备注含 `补发`/`reissue` → 补发/补偿
- 其他 → 按备注原文判断，结论写在报告里

**金额单位：万元**（原始值/10000，保留整数或1位小数）

### Step 4: 生成报告（暂不推送）

**两条报告都生成完毕后，再进入 Step 5 统一推送。**

每个看板生成一条独立消息，存入变量（如 `report_319689`、`report_307333`），**不立即推送**。

#### 报告格式（看板 319689 — 离线号码包监控）

```
🗓️ 离线号码包监控 - YYYY年M月

💡 概况
> • **离线包总数**：N个（上月N个，环比±X%）
> • **游戏分布**：游戏A(N, X%)、游戏B(N, X%)...

🔎 观察
> • **结论（加粗，结论先行）**。具体数据和分析。
> • **结论（加粗，结论先行）**。具体数据和分析。

🔗 [查看看板](https://beacon.woa.com/datatalk/ic_pcg_social/dashboard/319689?menuIds=menu_t5lqd02c)
```

**格式要点（企微 Markdown 限制）：**
- 标题（🗓️）和 `💡 概况` 之间**无空行**（直接换行）
- `💡 概况` 和引用 bullet 之间**无空行**（`>` 紧跟在 `💡 概况` 下一行）
- 每个引用块结束后用 `\n\n`（双换行）断开，使下一个标题（如 `🔎 观察`）不在引用块内
- **不要用 `---` 分割线**（企微不渲染）、**不要用表格**（企微 Markdown 不支持）
- 观察部分：**结论加粗放最前**，后面跟具体数据/分析（结论先行）
- 游戏分布格式：`游戏名(数量, 占比%)`，多个用 `、` 分隔
- **概况部分只包含「离线包总数」和「游戏分布」两项，禁止添加「上传时间分布」或其他额外字段**

#### 报告格式（看板 307333 — 人工配额监控）

```
🗓️ 人工配额监控 - YYYY年M月

💡 概况
> **「虚拟金」**
> **配额总量**：N万元（上月N万元，环比±X%）
> **游戏分布**：游戏A(N万元, X%)、游戏B(N万元, X%)...
> 
> **「现金」**
> **配额总量**：N万元（上月N万元，环比±X%）
> **游戏分布**：游戏A(N万元, X%)...

🔎 观察
> • **虚拟金：结论（加粗，结论先行）**。备注"xxx"→判断理由。
> • **现金：结论（加粗，结论先行）**。备注"xxx"→判断理由。

🔗 [查看看板](https://beacon.woa.com/datatalk/ic_pcg_social/dashboard/307333)
```

**格式要点（企微 Markdown 限制）：**
- 概况部分：`「虚拟金」`/`「现金」` 和 `**配额总量**`/`**游戏分布**` 均加粗
- `「虚拟金」` 和 `「现金」` 之间加一行空引用（`> `）作为分隔
- 观察部分：每条结论加粗，并**标明是虚拟金还是现金**，避免混淆
- 金额单位：**万元**（原始值/10000）
- 游戏分布格式：`游戏名(金额万元, 占比%)`
- 备注判断：结论直接写（如 `备注"测试"→测试用途`），不要把备注原文丢给用户判断

### Step 5: 推送企微（两条连续发送）

**两条报告都准备好后，用同一个 Python 脚本连续发送两条消息**，避免时间差导致顺序混乱。

推送脚本模板（同时发送两条）：

```python
import json, urllib.request

# 报告内容（已从 Step 4 生成）
report_319689 = "🗓️ 离线号码包监控 - 2026年5月\n💡 概况\n> • **离线包总数**：4个（上月20个，环比-80%）\n> • **游戏分布**：元梦之星(3, 75%)、合金弹头：觉醒(1, 25%)\n\n🔎 观察\n> • **5月上传4个包均为测试/补发用途，无生产业务人群包**。crowd_name 含「测试」「补发」等字样，判断为非生产用途。\n> • **3个包集中在05-27上传，存在月末集中操作**。建议日常分散上传，避免月末扎堆。\n\n🔗 [查看看板](https://beacon.woa.com/datatalk/ic_pcg_social/dashboard/319689?menuIds=menu_t5lqd02c)"

report_307333 = "🗓️ 人工配额监控 - 2026年5月\n💡 概况\n> **「虚拟金」**\n> **配额总量**：0万元（上月2万元，环比-100%）\n> **游戏分布**：无\n> \n> **「现金」**\n> **配额总量**：0万元\n> **游戏分布**：无\n\n🔎 观察\n> • **虚拟金：5月无配额数据，上月（4月）也无虚拟金配额记录**。\n> • **现金：5月无配额数据**，上月（4月）也无现金配额记录。\n\n🔗 [查看看板](https://beacon.woa.com/datatalk/ic_pcg_social/dashboard/307333)"

webhook_url = config["wecom_webhook_url"]

# 第一条：319689 离线号码包监控
payload1 = json.dumps({"msgtype": "markdown", "markdown": {"content": report_319689}}, ensure_ascii=False).encode()
req1 = urllib.request.Request(webhook_url, data=payload1, headers={"Content-Type": "application/json; charset=utf-8"})
resp1 = urllib.request.urlopen(req1)
print("319689:", resp1.read().decode())

# 第二条：307333 人工配额监控（紧接第一条，无间隔）
payload2 = json.dumps({"msgtype": "markdown", "markdown": {"content": report_307333}}, ensure_ascii=False).encode()
req2 = urllib.request.Request(webhook_url, data=payload2, headers={"Content-Type": "application/json; charset=utf-8"})
resp2 = urllib.request.urlopen(req2)
print("307333:", resp2.read().decode())
```

**关键点：**
- 两条消息在**同一个脚本、同一次执行**中连续发送
- 先发 319689，再发 307333，中间无额外操作
- 如任意一条推送失败，记录错误后继续发第二条，不中断流程

### Step 6: 存档

将生成的总结保存到本地存档：
```
~/Library/Mobile Documents/com~apple~CloudDocs/[Bobooo]/output/beacon-monitor/YYYY-MM-DD.md
```

## Error Handling

- DataTalk MCP 调用失败（模型不支持）→ 提示用户切换至司内部署模型（混元系列）
- 看板数据为空 → 在总结中标注"无数据"
- 企微 Webhook 推送失败 → 记录错误，保存总结到本地
- 时间变量构造失败 → 使用默认数据并在总结中标注"数据时间范围可能不完整"

## Automation

配合 WorkBuddy automation 设置每月执行：
- 频率：每月 1 日
- 推荐 RRULE：`FREQ=MONTHLY;BYMONTHDAY=1`
- Prompt 模板：`执行 beacon-datatalk-monitor skill，查询 {YYYY-MM} 看板数据生成监控总结并推送至企微群`

## Notes

- DataTalk MCP 工具仅在**司内部署模型**下可用，外部模型（Claude/GPT）会被拒绝
- `_llmModel` 参数必须传入当前实际使用的模型名称
- 看板 319689 的 `menuIds=menu_t5lqd02c` 是 URL 中的菜单参数，查询时不需要传入
- 看板 307333 包含三个菜单（人工/虚拟金/现金），**本 skill 只看"人工"菜单**
- 企微 Markdown 消息限制 4096 字节，如总结超长需分段推送
- **企微 Markdown blockquote 断开关键**：用 `\n\n`（双换行）才能真正断开引用块；用 `\n \n`（空格行）会把空格行保留在引用内，引用不会断开
