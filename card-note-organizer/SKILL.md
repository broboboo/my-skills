---
name: card-note-organizer
description: "卡片笔记整理工具。将零散的原始笔记、摘录、想法或网页内容转化为结构化的卡片笔记（标题 → 标签 → 一句话总结 → 核心洞见 → 来源）。支持单条和批量整理，支持导出为 Markdown/CSV/JSON，支持写入 Reminds 或 Obsidian vault。"
agent_created: true
---

# Card Note Organizer

将任意形式的原始笔记 — 散乱文字、摘录、灵感碎片、网页内容、文档片段 — 转化为结构化卡片笔记。每张卡片遵循「标题 → 标签 → 总结 → 洞见 → 来源」五要素，确保知识可检索、可复用、可关联。

## Workflow

### Step 1: Receive Input

接收用户输入，支持以下形式：

- 对话中直接给出的文本
- 文件路径（`.md`、`.txt` 等）
- URL（使用 WebFetch 提取网页内容后处理）

单条笔记直接处理；多条笔记混在一起时，先智能拆分为独立条目再逐一处理。

### Step 2: Analyze & Extract

对每条笔记：

1. 识别核心主题
2. 提取关键概念（观点、数据、方法论）
3. 判断笔记类型（事实陈述 / 观点论证 / 灵感碎片 / 实用技巧）
4. 评估完整性 — 信息不足时向用户追问

### Step 3: Generate Card

按 `references/card-spec.md` 中的规范生成卡片，依次填充五个要素：

1. **标题**（≤10 个汉字，准确概括主题）
2. **标签**（分为 1-2 个出处标签与 2-5 个内容标签；出处标签必要时用 `/` 分割多级来源；内容标签从原文和总结中提炼）
3. **一句话总结**（≤60 字，包含主题 + 核心观点）
4. **核心洞见**（金字塔总分结构：以「一句话总结」为顶层论点，2-5 个并列分论点从不同视角展开支撑；每个分论点都要有「视角名 + 论 + 据」；不再单写「核心论点」一行，避免与一句话总结重复）
5. **来源**（类型 + 出处 + 日期；缺失时标注「用户提供，未注明出处」并提醒补充）

### Step 4: Output

完成整理后，询问用户选择输出目标：

| 选项 | 方式 | 适用场景 |
|------|------|----------|
| 文件 | 写入当前工作目录，文件名 `card-notes-{timestamp}.md` | 通用 |
| Reminds | 调用 `mcp__reminds-mcp__create_fleeting`，按 `references/card-spec.md` 的 Reminds 写入格式生成 HTML：保留各部分标题、固定 emoji、部分间用分割线、用 `<strong>`/`<em>`/`<blockquote>`/`<mark>` 区分主次 | 闪念同步 |
| Obsidian | 写入用户指定的 vault 路径 | 知识库归档 |

如需导出为 CSV/JSON，使用 `scripts/export_cards.py`：

```bash
python3 scripts/export_cards.py input.md -f csv -o output.csv
```

支持的格式：`md`（默认）、`csv`、`json`。加 `--tags-only` 仅输出标签索引。

### Step 5: Quality Check

输出前对照 `references/card-spec.md` 中的质量自检清单，确认标题长度、出处标签数量、内容标签数量、总结字数、洞见结构（一句话总结作顶 + 2-5 个并列分论点 + 每点都有「视角名 + 论 + 据」）、来源完整度均达标。写入 Reminds 前额外检查：各部分标题是否保留、emoji 是否固定、分割线是否完整，并确认核心洞见区没有再重复一句「核心论点」与总结同义。

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
