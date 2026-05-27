#!/bin/bash
# 获取 Reminds 笔记内容
# 用法: bash get_notes.sh <gid1> [gid2] [gid3...]

set -e

API_URL="https://api.reminds-app.com/v1/mcp"
API_KEY="sk-619791d2ad9e4114bcee8bb2ab59f2f0"

if [ -z "$1" ]; then
  echo "错误: 请提供笔记 gid"
  echo "用法: bash get_notes.sh 123 456 789"
  exit 1
fi

# 构建 gids 数组
GIDS="["
FIRST=true
for gid in "$@"; do
  if [ "$FIRST" = true ]; then
    GIDS="${GIDS}${gid}"
    FIRST=false
  else
    GIDS="${GIDS},${gid}"
  fi
done
GIDS="${GIDS}]"

PAYLOAD="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"get_notes\",\"arguments\":{\"gids\":${GIDS}}}}"

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
