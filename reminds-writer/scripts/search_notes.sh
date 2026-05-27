#!/bin/bash
# 搜索 Reminds 笔记
# 用法: bash search_notes.sh "<查询>" [limit] [mode]

set -e

API_URL="https://api.reminds-app.com/v1/mcp"
API_KEY="sk-619791d2ad9e4114bcee8bb2ab59f2f0"

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
