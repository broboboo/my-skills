#!/bin/bash
# 创建 fleeting note 到 Reminds
# 用法1（参数）: bash create_fleeting.sh "<HTML内容>"
# 用法2（stdin）: echo "<HTML内容>" | bash create_fleeting.sh
# 用法3（文件）: bash create_fleeting.sh < /path/to/content.html
# 优先使用 stdin 输入以避免命令行参数长度限制（尤其含 base64 图片时）
#
# 认证方式（优先级从高到低）：
#   1. 环境变量 REMINDS_API_KEY
#   2. 当前目录下的 .reminids_key 文件（内容为纯文本 API Key）
#   3. ~/.reminids_key 文件
# 获取 API Key：登录 reminds-app.com → 设置 → API

set -e

API_URL="https://api.reminds-app.com/v1/mcp"
MAX_RETRIES=2
RETRY_DELAY=2

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

# 读取内容：stdin 优先于命令行参数
if [ ! -t 0 ]; then
    # 有 stdin 输入
    CONTENT=$(cat)
elif [ -n "$1" ]; then
    # 使用命令行参数
    CONTENT="$1"
else
    echo "错误: 请提供 HTML 内容（通过 stdin 或命令行参数）"
    echo "用法: echo '<h2>标题</h2>' | bash create_fleeting.sh"
    echo "  或: bash create_fleeting.sh '<h2>标题</h2><p>内容</p>'"
    exit 1
fi

if [ -z "$CONTENT" ]; then
    echo "错误: 内容为空"
    exit 1
fi

# 转义 JSON 中的特殊字符
ESCAPED_CONTENT=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$CONTENT")

PAYLOAD=$(cat <<EOF
{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"create_fleeting","arguments":{"content":${ESCAPED_CONTENT}}}}
EOF
)

# 带重试的 API 调用
attempt=0
while [ $attempt -le $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/reminds_response.txt -X POST "$API_URL" \
      -H "x-api-key: $API_KEY" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json, text/event-stream" \
      -d "$PAYLOAD")

    # 非 5xx 或已达最大重试次数，跳出
    if ! echo "$HTTP_CODE" | grep -q '^5' || [ $attempt -eq $MAX_RETRIES ]; then
        break
    fi

    attempt=$((attempt + 1))
    echo "⚠️  API 返回 $HTTP_CODE，重试 $attempt/$MAX_RETRIES ..." >&2
    sleep $RETRY_DELAY
done

RESPONSE=$(cat /tmp/reminds_response.txt)
rm -f /tmp/reminds_response.txt

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
