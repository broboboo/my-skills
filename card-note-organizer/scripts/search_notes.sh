#!/bin/bash
# 搜索 Reminds 笔记
# 用法: bash search_notes.sh "<查询>" [limit] [mode]
#
# 认证方式（优先级从高到低）：
#   1. 环境变量 REMINDS_API_KEY
#   2. 当前目录下的 .reminids_key 文件（内容为纯文本 API Key）
#   3. ~/.reminids_key 文件
# 获取 API Key：登录 reminds-app.com → 设置 → API

set -e

API_URL="https://api.reminds-app.com/v1/mcp"

# 读取 API Key
if [ -n "$REMINDS_API_KEY" ]; then
    API_KEY="$REMINDS_API_KEY"
elif [ -f "$(dirname "$0")/.reminids_key" ]; then
    API_KEY=$(cat "$(dirname "$0")/.reminids_key")
elif [ -f "$HOME/.reminids_key" ]; then
    API_KEY=$(cat "$HOME/.reminids_key")
else
    echo "错误: 未设置 Reminds API Key。请通过以下方式之一提供："
    echo "  1. 设置环境变量: export REMINDS_API_KEY='your-key'"
    echo "  2. 在 scripts/ 目录创建 .reminids_key 文件，内容为 API Key"
    echo "  3. 在 ~/.reminids_key 文件写入 API Key"
    echo ""
    echo "获取 API Key: 登录 https://reminds-app.com → 设置 → API"
    exit 1
fi

if [ -z "$1" ]; then
  echo "错误: 请提供搜索查询"
  echo "用法: bash search_notes.sh '查询内容' [limit] [mode]"
  exit 1
fi

QUERY="$1"
LIMIT="${2:-10}"
MODE="${3:-retrieval}"

ESCAPED_QUERY=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$QUERY")

PAYLOAD="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"search_notes\",\"arguments\":{\"query\":${ESCAPED_QUERY},\"limit\":${LIMIT},\"mode\":\"${MODE}\"}}}"

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "$PAYLOAD")

echo "$RESPONSE" | grep -o 'data: .*' | sed 's/^data: //' | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        data = json.loads(line)
        if 'result' in data:
            result = data['result']
            if 'content' in result:
                for item in result['content']:
                    if item.get('type') == 'text':
                        print(item['text'])
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
        elif 'error' in data:
            print('错误:', data['error'].get('message', str(data['error'])))
    except json.JSONDecodeError:
        print(line)
"
