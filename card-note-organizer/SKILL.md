---
name: card-note-organizer
description: "卡片笔记整理工具。将零散的原始笔记、摘录、想法或网页内容转化为结构化的卡片笔记（标题 → 标签 → 一句话总结 → 核心要点 → 洞见 → 关键图示 → 来源）。支持单条和批量整理；输入中带有图片时，必须保留并嵌入卡片；支持导出为 Markdown/CSV/JSON，支持写入 Reminds 或 Obsidian vault。"
agent_created: true
---

# Card Note Organizer

将任意形式的原始笔记 — 散乱文字、摘录、灵感碎片、网页内容、文档片段 — 转化为结构化卡片笔记。每张卡片遵循「标题 → 标签 → 总结 → 核心要点 → 洞见 → 图示 → 来源」七要素（图示在原文有图时出现，洞见在无值得提炼时可不写），确保知识可检索、可复用、可关联。

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

按 `references/card-spec.md` 中的规范生成卡片，依次填充要素：

1. **标题**（≤10 个汉字，准确概括主题）
2. **标签**（分为三类：① 出处标签 1-2 个，用 `/` 分割多级来源；② 内容标签 2-5 个，从原文和总结中提炼主题/领域/方法；③ 概念标签，数量不限，标注笔记核心涉及的术语、理论、模型——必须与笔记核心强相关，仅顺带提及的不加）
3. **一句话总结**（≤60 字，包含主题 + 核心观点）
4. **核心要点**（忠实保留输入材料中最重要的观点、结论、清单、因果关系。允许适度精简和结构化，但不歪曲、不丢失关键内容。呈现方式灵活选择，重要的是结构清晰、逻辑明确、易理解）
5. **洞见**（基于核心要点，提炼出原文没有直接说出的上位判断、关联、启发或延伸思考。观点必须清楚，自由提炼。无值得提炼时可不写此区段）
6. **关键图示**（仅当原文有核心图示时出现；保留所有核心图示，按出现顺序列出，可加简短 caption）
7. **来源**（类型 + 出处 + 日期；缺失时标注「用户提供，未注明出处」并提醒补充）

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

输出前对照 `references/card-spec.md` 中的质量自检清单，确认标题长度、出处标签数量、内容标签数量、总结字数、核心要点是否保留了原文关键内容（不能为精简而丢失）、洞见是否有额外判断（不重复核心要点）、关键图示是否漏掉、来源完整度均达标。写入 Reminds 前额外检查：各部分标题是否保留、emoji 是否固定、分割线是否完整、所有原文图片已通过 `<img>`（远程链接、Reminds 内部协议或 base64 data URI）嵌入 HTML，**禁止只写路径文字代替图片**。

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
- 核心要点区必须保留原文关键内容（清单、对比、因果链等），不能为了"提炼"而消化掉重要具体信息。
- 洞见区只写额外判断，不重复核心要点已有内容；如果某条笔记无值得额外提炼的洞见，洞见区可以不写。
- **核心要点 ≠ 原文照搬**：允许精简、结构化、重组，但关键内容不能丢。**洞见 ≠ 核心要点的改写**：必须产出原文没有直接给出的上位概念、因果归因、类比关联或方法论命名。
