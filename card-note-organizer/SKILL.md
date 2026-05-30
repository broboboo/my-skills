---
name: card-note-organizer
description: "卡片笔记整理工具。将零散的原始笔记、摘录、想法或网页内容转化为结构化的卡片笔记（标题 → 标签 → 一句话总结 → 核心洞见 → 关键图示 → 来源）。支持单条和批量整理；输入中带有图片时，必须保留并嵌入卡片；支持导出为 Markdown/CSV/JSON，支持写入 Reminds 或 Obsidian vault。"
agent_created: true
---

# Card Note Organizer

将任意形式的原始笔记 — 散乱文字、摘录、灵感碎片、网页内容、文档片段 — 转化为结构化卡片笔记。每张卡片遵循「标题 → 标签 → 总结 → 洞见 → 图示 → 来源」六要素（图示在原文有图时出现），确保知识可检索、可复用、可关联。

## Workflow

### Step 1: Receive Input

接收用户输入，支持以下形式：

- 对话中直接给出的文本
- 文件路径（`.md`、`.txt` 等）
- URL（使用 WebFetch 提取网页内容后处理）

单条笔记直接处理；多条笔记混在一起时，先智能拆分为独立条目再逐一处理。

**图片识别规则（强制）：** 解析输入时必须扫描以下三种图片语法，得到原文图片清单：

1. 标准 Markdown：`![alt](path or url)`
2. Obsidian wiki link：`![[file.png]]`、`![[file.png|caption]]`
3. HTML：`<img src="..." />`

得到图片清单后，对每张图判断「核心图示」还是「装饰/封面」：保留核心图示，丢弃装饰图。判别标准见 `references/card-spec.md`。

### Step 2: Analyze & Extract

对每条笔记：

1. 识别核心主题
2. 提取关键概念（观点、数据、方法论）
3. 判断笔记类型（事实陈述 / 观点论证 / 灵感碎片 / 实用技巧）
4. 评估完整性 — 信息不足时向用户追问

### Step 3: Generate Card

按 `references/card-spec.md` 中的规范生成卡片，依次填充六个要素：

1. **标题**（≤10 个汉字，准确概括主题）
2. **标签**（分为三类：① 出处标签 1-2 个，用 `/` 分割多级来源；② 内容标签 2-5 个，从原文和总结中提炼主题/领域/方法；③ 概念标签，数量不限，标注笔记核心涉及的术语、理论、模型——必须与笔记核心强相关，仅顺带提及的不加）
3. **一句话总结**（≤60 字，包含主题 + 核心观点）
4. **核心洞见**（金字塔总分结构：以「一句话总结」为顶层判断，展开 2-4 个最关键的支撑点，必要时最多 5 个。**必须完成「抽象 → 判断」**，即从原文素材中提炼出原文没有直接说出的上位判断或洞察，而不是把原文事实换个说法重新排列。呈现方式按内容逻辑关系选择：并列对比用表格，递进/因果用自然段落，步骤用编号列表；无序 bullet 仅用于真正并列的情况）
5. **关键图示**（仅当原文有核心图示时出现；保留所有核心图示，按出现顺序列出，可加简短 caption）
6. **来源**（类型 + 出处 + 日期；缺失时标注「用户提供，未注明出处」并提醒补充）

### Step 4: Output

完成整理后，询问用户选择输出目标：

| 选项 | 方式 | 适用场景 |
|------|------|----------|
| 文件 | 写入当前工作目录，文件名 `card-notes-{timestamp}.md`；图片用原始引用语法保留（`![[...]]` 或 `![](...)`） | 通用 |
| Reminds | 调用 `mcp__reminds-mcp__create_fleeting`，按 `references/card-spec.md` 的 Reminds 写入格式生成 HTML：保留各部分标题、固定 emoji、部分间用分割线、用 `<strong>`/`<em>`/`<blockquote>`/`<mark>` 区分主次。**图片必须直接嵌入 HTML**：本地图片用 `data:` URI（base64）内联，远程图片直接用 `<img src="https://..." />`，禁止只留路径文字 | 闪念同步 |
| Obsidian | 写入用户指定的 vault 路径；保留 `![[wiki link]]` 形式以便在 vault 内自动渲染 | 知识库归档 |

如需导出为 CSV/JSON，使用 `scripts/export_cards.py`：

```bash
python3 scripts/export_cards.py input.md -f csv -o output.csv
```

支持的格式：`md`（默认）、`csv`、`json`。加 `--tags-only` 仅输出标签索引。

### Step 5: Quality Check

输出前对照 `references/card-spec.md` 中的质量自检清单，确认标题长度、出处标签数量、内容标签数量、总结字数、洞见结构（一句话总结作顶 + 2-4 个高密度支撑点，必要时最多 5 个；每点都有明确判断与简短展开；整体不冗长、不生硬、不滥用多级列表）、关键图示是否漏掉、来源完整度均达标。写入 Reminds 前额外检查：各部分标题是否保留、emoji 是否固定、分割线是否完整、所有原文图片已通过 `<img>`（远程链接或 base64 data URI）嵌入 HTML，**禁止只写路径文字代替图片**。

## Batch Mode

多条笔记时：

1. 用 `---` 分隔卡片，编号 `## 卡片 1`、`## 卡片 2`
2. 末尾生成标签索引
3. 询问用户是否需要调整

## Resources

- `references/card-spec.md` — 卡片结构模板、各字段详细规范、质量自检清单
- `scripts/export_cards.py` — 多格式导出脚本（MD/CSV/JSON/标签索引）
- `assets/card-template.md` — 可复制的空白卡片模板

## Pitfalls

- 保持 `scripts/export_cards.py` 兼容系统 Python 3.9；如需使用 Python 3.10+ 类型语法，必须加 `from __future__ import annotations` 或改用旧式类型写法。
- Reminds 只接收 HTML 内容；写入前先用 Markdown 层级设计结构，再转换为 HTML，并保留分割线、emoji 标题和出处标签。
- **图片必须嵌入而非省略**：本地图片转为 `data:image/<ext>;base64,...` 内联，远程图片用原 URL；Obsidian wiki link `![[file.png]]` 在写入 Reminds 时必须先解析到真实文件再 base64 化。
- Obsidian wiki link 解析路径优先级：① 同目录 `attachments/`、`assets/`；② vault 根目录搜索；③ 解析失败时在卡片中保留原 wiki link 并附文字提示「图片解析失败，见原笔记」。
- 当 skill 文件（SKILL.md / references / scripts / assets）发生任何修改后，必须按 `~/.workbuddy/MEMORY.md` 中「Skill 同步到 GitHub 规则」立即同步至 `broboboo/my-skills`。
- 核心洞见优先追求"少而准"，不要为了结构完整硬凑到 5 点；通常 2-4 点最佳。避免使用"原文指出/原文提到"作为常规句式，除非确实需要引用原句。
- **核心洞见 ≠ 原文复述/改写**：原文是素材，不是产出。必须从素材中抽象出原文没有直接说出的上位判断（如从"Miller's Law + 本能层次 + 三重功能"抽象出"标题设计 = 认知工程"）。如果写完发现只是把原文事实用段落串联或换说法排列了一遍，说明提炼失败，必须重写。
- **呈现方式与逻辑关系匹配**：递进/因果链用自然段落（通过逻辑连接词体现推进），并列对比用表格，步骤用编号列表。无序 bullet（`-`）天然传达并列关系，禁止用它表达递进或因果。
