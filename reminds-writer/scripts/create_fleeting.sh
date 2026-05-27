#!/bin/bash
# 创建 fleeting note 到 Reminds
# 用法: bash create_fleeting.sh "<HTML内容>"

set -e

API_URL="https://api.reminds-app.com/v1/mcp"
API_KEY="sk-619791d2ad9e4114bcee8bb2ab59f2f0"

if [ -z "$1" ]; then
  echo "错误: 请提供 HTML 内容作为参数"
  echo "用法: bash create_fleeting.sh '<h2>标题</h2><p>内容</p>'"
  exit 1
fi

CONTENT="$1"

# 转义 JSON 中的特殊字符
ESCAPED_CONTENT=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$CONTENT")

PAYLOAD=$(cat <<EOF
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"create_fleeting","arguments":{"content":${ESCAPED_CONTENT}}}}
EOF
)

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "$PAYLOAD")

# 解析 SSE 响应
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
            elif 'isError' in result and result['isError']:
                print('错误:', result)
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
        elif 'error' in data:
            print('错误:', data['error'].get('message', str(data['error'])))
    except json.JSONDecodeError:
        print(line)
"
