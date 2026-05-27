# my-skills

我的 [WorkBuddy / Claw](https://www.codebuddy.cn/) skills 集合，方便在不同设备之间同步使用。

## 目录结构

```
my-skills/
├── README.md                     # 本文件
├── LICENSE                       # MIT
├── .gitignore
└── card-note-organizer/          # 卡片笔记整理 skill
    ├── SKILL.md
    ├── references/
    │   └── card-spec.md
    ├── scripts/
    │   └── export_cards.py
    └── assets/
        └── card-template.md
```

## 安装方式

### 方式一：克隆仓库后做软链接（推荐）

```bash
# 1. 克隆到任意位置
git clone https://github.com/broboboo/my-skills.git ~/code/my-skills

# 2. 把需要的 skill 软链接到 WorkBuddy 用户级 skills 目录
mkdir -p ~/.workbuddy/skills
ln -s ~/code/my-skills/card-note-organizer ~/.workbuddy/skills/card-note-organizer
```

以后只要 `cd ~/code/my-skills && git pull` 就能同步最新版本。

### 方式二：直接拷贝单个 skill

```bash
git clone https://github.com/broboboo/my-skills.git /tmp/my-skills
cp -r /tmp/my-skills/card-note-organizer ~/.workbuddy/skills/
```

## 当前包含的 skills

### card-note-organizer

卡片笔记整理工具。把零散的原始笔记、摘录、想法或网页内容转化为结构化卡片笔记（标题 → 标签 → 一句话总结 → 核心洞见 → 来源），核心洞见使用金字塔总分结构。

- 支持单条与批量整理
- 支持导出为 Markdown / CSV / JSON
- 支持写入 Reminds（HTML 格式）或 Obsidian vault

详见 [`card-note-organizer/SKILL.md`](./card-note-organizer/SKILL.md)。

## License

MIT，详见 [LICENSE](./LICENSE)。
