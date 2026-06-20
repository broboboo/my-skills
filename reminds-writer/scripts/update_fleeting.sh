#!/bin/bash
# 更新已有的 fleeting note
# 用法1（参数）: bash update_fleeting.sh <id> "<HTML内容>"
# 用法2（stdin）: echo "<HTML内容>" | bash update_fleeting.sh <id>
# 优先使用 stdin 输入以避免命令行参数长度限制

set -e

API_URL="https://api.reminds-app.com/v1/mcp"
API_KEY="sk-619791d2ad9e4114bcee8bb2ab59f2f0"
MAX_RETRIES=2
RETRY_DELAY=2

ID="$1"
if [ -z "$ID" ]; then
    echo "错误: 请提供 fleeting note id"
    echo "用法: echo '<h2>新内容</h2>' | bash update_fleeting.sh 123"
    echo "  或: bash update_fleeting.sh 123 '<h2>新内容</h2>'"
    exit 1
fi

# 读取内容：stdin 优先于命令行参数
if [ ! -t 0 ]; then
    CONTENT=$(cat)
elif [ -n "$2" ]; then
    CONTENT="$2"
else
    echo "错误: 请提供 HTML 内容（通过 stdin 或第二个参数）"
    exit 1
fi

if [ -z "$CONTENT" ]; then
    echo "错误: 内容为空"
    exit 1
fi

# 转义 JSON
ESCAPED_CONTENT=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$CONTENT")

PAYLOAD=$(cat <<EOF
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"update_fleeting","arguments":{"id":${ID},"content":${ESCAPED_CONTENT}}}}
EOF
)

attempt=0
while [ $attempt -le $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/reminds_update_response.txt -X POST "$API_URL" \
      -H "x-api-key: $API_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json, text/event-stream" \
      -d "$PAYLOAD")

    if ! echo "$HTTP_CODE" | grep -q '^5' || [ $attempt -eq $MAX_RETRIES ]; then
        break
    fi

    attempt=$((attempt + 1))
    echo "⚠️  API 返回 $HTTP_CODE，重试 $attempt/$MAX_RETRIES ..." >&2
    sleep $RETRY_DELAY
done

RESPONSE=$(cat /tmp/reminds_update_response.txt)
rm -f /tmp/reminds_update_response.txt

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
                print('提示: 如果 API 不支持 update_fleeting，请手动删除旧笔记后重新创建')
            else:
                print(json.dumps(result, ensure_ascii=False, indent=2))
        elif 'error' in data:
            print('错误:', data['error'].get('message', str(data['error'])))
    except json.JSONDecodeError:
        print(line)
"
