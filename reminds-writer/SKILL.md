# reminds-writer

Reminds 笔记写入工具 - 通过 HTTP API 直接写入 fleeting note 到 Reminds，无需 MCP 连接器。

## 触发条件

当用户要求"写入 reminds"、"发送到 reminds"、"保存到 reminds"、"记录到 reminds" 时使用此 skill。

## 可用操作

### 1. 创建 fleeting note

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/create_fleeting.sh "<HTML内容>"
```

内容必须是 **HTML 格式**（Reminds API 要求）。

支持的 HTML 格式：
- `<b>粗体</b>`
- `<i>斜体</i>`
- `<ul><li>列表</li></ul>`
- `<a href="url">链接</a>`
- `<h1>`~`<h3>` 标题
- `<blockquote>引用</blockquote>`
- `<hr>` 分割线
- `<br>` 换行

**不支持**: `<mark>`高亮、`==`语法、原生 Markdown

### 2. 搜索笔记

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/search_notes.sh "<查询内容>" [limit] [mode]
```

- mode: "qa"（精确问答）或 "retrieval"（广泛检索，默认）

### 3. 获取笔记内容

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/get_notes.sh <gid1> [gid2] [gid3...]
```

### 4. 获取 fleeting note

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/get_fleeting.sh <id>
```

## 卡片笔记格式规范

写入 Reminds 时，应遵循以下格式：

1. **标题**: 不超过10字，带 emoji
2. **结构**: 金字塔总分结构（去掉顶层核心论点，直接分点）
3. **标签**: 分两类
   - 出处标签(1-2个): `#书名` 或 `#来源`
   - 内容标签(2-5个): `#关键词`
4. **格式化**:
   - 用 `<b>` 粗体突出核心概念
   - 用 `<blockquote>` 引用定义或原文
   - 用 `<hr>` 分割不同层级内容
   - 用列表组织分点

## 示例

写入一条关于"助推理论"的卡片笔记：

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/create_fleeting.sh '<h2>🧠 助推理论</h2><p>#Nudge #行为经济学 #塞勒 #选择架构 #决策</p><hr><blockquote>在不禁止任何选项、不改变经济激励的前提下，通过改变<b>选择架构</b>来引导行为。</blockquote><ul><li><b>默认选项</b>：器官捐献 opt-out → 捐献率90%+</li><li><b>环境设计</b>：食堂健康食物前置 → 选择率↑</li><li><b>即时反馈</b>：用电实时提醒 → 节能行为↑</li></ul><hr><p><i>核心：保留自由，降低好选择的阻力</i></p>'
```
