#!/usr/bin/env python3
"""卡片笔记导出工具 - 支持 Markdown、CSV、JSON 格式导出和标签索引生成。

解析策略：基于标准 Markdown 标题层级结构，不依赖特定 emoji 符号。
当前卡片结构：标题 + 标签 + 一句话总结 + 核心洞见 + 来源。
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from datetime import datetime
from pathlib import Path

SECTION_ALIASES = {
    "tags": ["标签", "tags"],
    "summary": ["一句话总结", "总结", "summary"],
    "insight": ["核心洞见", "洞见", "insight"],
    "source": ["来源", "source"],
}


def parse_card_markdown(md_text: str) -> list[dict]:
    """从 Markdown 文本中解析出所有卡片笔记。

    支持两种常见结构：
    1. 批量格式：`## 卡片 N` 分隔，每个块内有 `## 标题` 和 `###` 子标题。
    2. 单卡格式：整篇即一张卡片，以 `## 标题` + `###` 子标题组织。
    """
    cards = []
    blocks = _split_card_blocks(md_text)

    for block in blocks:
        if not block.strip():
            continue

        card = {
            "title": _extract_title(block),
            "tags": [],
            "summary": "",
            "insight": "",
            "source_type": "",
            "source_name": "",
            "source_date": "",
        }

        for heading, content in _extract_sections(block):
            key = _match_section_key(heading)
            if key == "tags":
                card["tags"] = _extract_tags(content)
            elif key == "summary":
                card["summary"] = content.strip()
            elif key == "insight":
                card["insight"] = content.strip()
            elif key == "source":
                _parse_source(card, content)

        if card["title"] or card["summary"] or card["insight"]:
            cards.append(card)

    return cards


def _split_card_blocks(md_text: str) -> list[str]:
    """按 `## 卡片` 分割批量卡片；没有批量标题时整篇视为单卡。"""
    lines = md_text.split("\n")
    has_card_heading = any(line.startswith("## 卡片") for line in lines)
    if not has_card_heading:
        return [md_text]

    blocks = []
    current = []
    for line in lines:
        if line.startswith("## 卡片"):
            if current:
                blocks.append("\n".join(current))
            current = [line]
        else:
            current.append(line)
    if current:
        blocks.append("\n".join(current))
    return blocks


def _extract_title(block: str) -> str:
    """提取卡片标题：第一个非 `## 卡片`、非索引类的二级标题。"""
    for line in block.split("\n"):
        stripped = line.strip()
        if not stripped.startswith("## "):
            continue
        title = stripped[3:].strip()
        lower = title.lower()
        if title.startswith("卡片") or lower in {"tag index", "标签索引"}:
            continue
        return title
    return ""


def _extract_sections(block: str) -> list[tuple[str, str]]:
    """提取所有 `###` 子标题及其正文。"""
    sections = []
    current_heading = None
    current_lines = []

    for line in block.split("\n"):
        if line.startswith("### "):
            if current_heading is not None:
                sections.append((current_heading, _clean_section_content("\n".join(current_lines))))
            current_heading = line[4:].strip()
            current_lines = []
        else:
            if current_heading is not None:
                current_lines.append(line)

    if current_heading is not None:
        sections.append((current_heading, _clean_section_content("\n".join(current_lines))))

    return sections


def _clean_section_content(content: str) -> str:
    """清理 section 正文中的独立 Markdown 分割线。"""
    lines = [line for line in content.split("\n") if line.strip() not in {"---", "***", "___"}]
    return "\n".join(lines).strip()


def _match_section_key(heading: str) -> str | None:
    """根据标题文本识别 section；忽略 emoji 和大小写。"""
    cleaned = re.sub(r"[^\w\u4e00-\u9fff]+", "", heading).lower()
    for key, aliases in SECTION_ALIASES.items():
        for alias in aliases:
            alias_cleaned = re.sub(r"[^\w\u4e00-\u9fff]+", "", alias).lower()
            if alias_cleaned in cleaned:
                return key
    return None


def _extract_tags(content: str) -> list[str]:
    """提取 `#标签` / 裸 #标签，支持 `#书名/章节名` 多级标签。"""
    tags = re.findall(r"`?#([^`\s#，,；;]+)`?", content)
    return [tag.strip() for tag in tags if tag.strip()]


def _parse_source(card: dict, content: str):
    """解析来源字段。"""
    type_match = re.search(r"\*\*(?:类型|Type)\*\*[：:]\s*(.+)", content)
    source_match = re.search(r"\*\*(?:出处|From|Source)\*\*[：:]\s*(.+)", content)
    date_match = re.search(r"\*\*(?:日期|Date)\*\*[：:]\s*(.+)", content)

    if type_match:
        card["source_type"] = type_match.group(1).strip()
    if source_match:
        card["source_name"] = source_match.group(1).strip()
    if date_match:
        card["source_date"] = date_match.group(1).strip()


def export_to_csv(cards: list[dict], output_path: str):
    """导出为 CSV 文件。"""
    with open(output_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "title", "tags", "summary", "insight", "source_type", "source_name", "source_date"
        ])
        writer.writeheader()
        for card in cards:
            writer.writerow({
                "title": card["title"],
                "tags": " | ".join(card["tags"]),
                "summary": card["summary"],
                "insight": card["insight"],
                "source_type": card["source_type"],
                "source_name": card["source_name"],
                "source_date": card["source_date"],
            })
    print(f"CSV exported: {output_path}")


def export_to_json(cards: list[dict], output_path: str):
    """导出为 JSON 文件。"""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(cards, f, ensure_ascii=False, indent=2)
    print(f"JSON exported: {output_path}")


def generate_tag_index(cards: list[dict]) -> str:
    """生成标签索引。"""
    tag_index = {}
    for i, card in enumerate(cards, 1):
        for tag in card["tags"]:
            tag_index.setdefault(tag, []).append(i)

    lines = ["## 标签索引", ""]
    for tag in sorted(tag_index.keys()):
        card_nums = ", ".join(f"卡片 {n}" for n in tag_index[tag])
        lines.append(f"- `#{tag}` -> {card_nums}")

    return "\n".join(lines)


def export_to_markdown(cards: list[dict], output_path: str):
    """导出为完整的 Markdown 文件。"""
    lines = [
        "# Card Notes",
        f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"Total: {len(cards)} cards",
        "",
    ]

    for i, card in enumerate(cards, 1):
        tags_str = " ".join(f"`#{t}`" for t in card["tags"])
        title = card["title"] or f"卡片 {i}"
        lines.extend([
            f"## 卡片 {i}",
            "",
            "---",
            "",
            f"## {title}",
            "",
            "---",
            "",
            "### 🏷️ 标签",
            "",
            tags_str,
            "",
            "---",
            "",
            "### 💬 一句话总结",
            "",
            card["summary"],
            "",
            "---",
            "",
            "### 💡 核心洞见",
            "",
            card["insight"],
            "",
            "---",
            "",
            "### 📎 来源",
            "",
            f"- **类型**：{card['source_type']}",
            f"- **出处**：{card['source_name']}",
            f"- **日期**：{card['source_date']}",
            "",
        ])

    lines.append(generate_tag_index(cards))

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Markdown exported: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Card note export tool")
    parser.add_argument("input", help="Input Markdown file path")
    parser.add_argument("-f", "--format", choices=["md", "csv", "json"], default="md",
                        help="Export format (default: md)")
    parser.add_argument("-o", "--output", help="Output file path")
    parser.add_argument("--tags-only", action="store_true", help="Only generate tag index")

    args = parser.parse_args()

    md_text = Path(args.input).read_text(encoding="utf-8")
    cards = parse_card_markdown(md_text)

    if not cards:
        print("No card notes detected")
        return

    print(f"Parsed {len(cards)} card notes")

    if args.tags_only:
        print(generate_tag_index(cards))
        return

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    ext_map = {"md": ".md", "csv": ".csv", "json": ".json"}

    if not args.output:
        args.output = f"card-notes-{timestamp}{ext_map[args.format]}"

    if args.format == "csv":
        export_to_csv(cards, args.output)
    elif args.format == "json":
        export_to_json(cards, args.output)
    else:
        export_to_markdown(cards, args.output)


if __name__ == "__main__":
    main()
