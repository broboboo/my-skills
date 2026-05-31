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

### HTML 格式规范（已验证可正常渲染）

#### 支持的标签

| 标签 | 用途 | 示例 |
|------|------|------|
| `<h1>` `<h2>` `<h3>` | 标题层级 | `<h1>主标题</h1>` |
| `<p>` | 段落 | `<p>正文内容</p>` |
| `<b>` | 粗体强调 | `<b>关键概念</b>` |
| `<i>` | 斜体/补充说明 | `<i>注释内容</i>` |
| `<blockquote>` | 引用/定义 | `<blockquote>引用原文</blockquote>` |
| `<ul>` + `<li>` | 无序列表 | `<ul><li>项目</li></ul>` |
| `<ol>` + `<li>` | 有序列表 | `<ol><li>步骤1</li></ol>` |
| 嵌套 `<ul>` | 多级列表 | `<ul><li>父<ul><li>子</li></ul></li></ul>` |
| `<table>` | 表格 | 含 `<tr>` `<th>` `<td>` |
| `<hr>` | 分割线 | `<hr>` |
| `<br>` | 换行 | `<br>` |
| `<a href="url">` | 链接 | `<a href="https://...">文本</a>` |
| `<mark>` | 高亮（黄色背景） | `<mark>高亮文本</mark>` |
| `<span style="background-color: #xxx">` | 自定义颜色高亮 | `<span style="background-color: #ffd700; padding: 2px 4px">高亮</span>` |

#### 不支持

- `==` 语法
- 原生 Markdown
- `<code>` / `<pre>` 代码块（可能不渲染等宽字体）

### 写入格式转换规则

当用户提供 Markdown 内容或要求"原封不动写入"时，按以下规则转换为 HTML：

| Markdown 元素 | 转换为 HTML |
|---------------|-------------|
| `# 标题` | `<h1>标题</h1>` |
| `## 标题` | `<h2>标题</h2>` |
| `### 标题` | `<h3>标题</h3>` |
| `**粗体**` | `<b>粗体</b>` |
| `*斜体*` | `<i>斜体</i>` |
| `> 引用` | `<blockquote>引用</blockquote>` |
| `- 列表项` | `<ul><li>列表项</li></ul>` |
| `1. 有序` | `<ol><li>有序</li></ol>` |
| 表格 `\| a \| b \|` | `<table><tr><th>a</th><th>b</th></tr>...</table>` |
| `---` 分割线 | `<hr>` |
| `==高亮==` | `<mark>高亮</mark>` |
| `` `代码` `` | `<b>代码</b>`（用粗体替代） |
| 代码块 ``` | 用 `<ul><li>` 逐行列出，或用 `<p>` 包裹 |
| 树形结构 | 用嵌套 `<ul><li>` 表示层级关系 |

### 格式最佳实践

1. **段落之间**用 `<p>` 包裹，不要裸文本
2. **表格**完整使用 `<table><tr><th>/<td>` 结构，确保有表头行
3. **嵌套列表**用 `<ul>` 嵌套在 `<li>` 内部表达层级
4. **分割线 `<hr>`** 用于分隔不同章节/层级内容
5. **不要自闭合** `<br/>` 写成 `<br>` 即可

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

> **注意：卡片笔记的格式规范已统一由 `card-note-organizer` skill 管理（`references/card-spec.md`），本 skill 不再维护独立的格式规范。写入 Reminds 时的 HTML 结构和渲染规则请参考 `card-note-organizer` 中的「Reminds 写入格式」章节。**

## 示例

### 示例1：卡片笔记（简短）

```bash
bash /root/.codebuddy/skills/reminds-writer/scripts/create_fleeting.sh '<h2>🧠 助推理论</h2><p>#Nudge #行为经济学 #塞勒 #选择架构 #决策</p><hr><blockquote>在不禁止任何选项、不改变经济激励的前提下，通过改变<b>选择架构</b>来引导行为。</blockquote><ul><li><b>默认选项</b>：器官捐献 opt-out → 捐献率90%+</li><li><b>环境设计</b>：食堂健康食物前置 → 选择率↑</li><li><b>即时反馈</b>：用电实时提醒 → 节能行为↑</li></ul><hr><p><i>核心：保留自由，降低好选择的阻力</i></p>'
```

### 示例2：完整知识笔记（含表格、多级标题、嵌套列表）

```html
<h1>视觉搜索（Visual Search）</h1>

<p><b>视觉搜索</b>是认知心理学/设计心理学中的核心概念，指人在视觉环境中<b>主动寻找特定目标</b>的认知加工过程。</p>

<h2>核心定义</h2>

<blockquote>在充满干扰项（distractors）的视觉场景中，定位目标刺激（target）的注意力分配过程。</blockquote>

<h2>两种搜索模式</h2>

<table>
<tr><th>模式</th><th>机制</th><th>速度</th><th>典型场景</th></tr>
<tr><td><b>前注意搜索（Pop-out）</b></td><td>并行加工，目标自动"跳出来"</td><td>极快，不受干扰项数量影响</td><td>红色按钮在一堆灰色按钮中</td></tr>
<tr><td><b>注意搜索（Serial Search）</b></td><td>逐一扫描，串行加工</td><td>慢，随干扰项增加线性增长</td><td>在文字列表中找特定词</td></tr>
</table>

<h2>关键理论</h2>

<h3>特征整合理论（Treisman, 1980）</h3>
<ul>
<li><b>单一特征</b>（颜色、大小、方向）可以并行检测 → pop-out</li>
<li><b>特征组合</b>（红色+方形）需要注意力逐一绑定 → 串行搜索</li>
</ul>

<h3>引导搜索模型（Wolfe, 1994）</h3>
<ul>
<li>自上而下（目标预期）+ 自下而上（显著性）共同引导注意力</li>
<li>解释了为什么"知道找什么"会显著加速搜索</li>
</ul>

<h2>设计中的应用</h2>

<table>
<tr><th>设计原则</th><th>做法</th><th>原理</th></tr>
<tr><td><b>视觉层级</b></td><td>用大小/颜色/粗细区分重要程度</td><td>让关键元素 pop-out</td></tr>
<tr><td><b>分组与留白</b></td><td>格式塔原则组织信息</td><td>缩小搜索范围</td></tr>
<tr><td><b>一致性</b></td><td>导航/按钮位置固定</td><td>利用空间记忆减少搜索</td></tr>
</table>

<h2>与其他概念的关系</h2>
<ul>
<li>视觉搜索
  <ul>
    <li>格式塔原则（组织降低搜索负荷）</li>
    <li>希克定律（选项多 → 决策慢）</li>
    <li>注意力经济（有限资源分配）</li>
  </ul>
</li>
</ul>

<hr>

<p><b>一句话总结</b>：好的设计就是让目标<b>不用找就能看到</b>。</p>
```
