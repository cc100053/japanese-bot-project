#!/bin/bash
# Prompt 調試腳本
# 文件位置: ~/japanese-bot-project/scripts/debug_prompt.sh

echo "🔍 調試 Prompt 格式問題..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 測試 1: 簡單的 prompt ===${NC}"
echo "測試簡單的 User/Assistant 格式..."

response1=$(curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "qwen2.5:3b", "prompt": "User: こんにちは\nAssistant:", "stream": false}' \
  -s)

echo "回應: $(echo "$response1" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)"

echo -e "\n${BLUE}=== 測試 2: 後端使用的 prompt 格式 ===${NC}"
echo "測試後端使用的 System/User/Assistant 格式..."

system_prompt="あなたは「冷淡ちゃん」という名前のキャラクターです。特徴：- 常に冷たく、素っ気ない態度 - 短い文で答える - 感情をあまり表現しない - 「別に」「そう」「ふーん」などをよく使う - でも実は少し優しい一面もある ユーザーのメッセージに対して、冷淡ちゃんらしく返答してください。"

response2=$(curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"qwen2.5:3b\", \"prompt\": \"System: $system_prompt\\n\\nUser: こんにちは\\n\\nAssistant:\", \"stream\": false}" \
  -s)

echo "回應: $(echo "$response2" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)"

echo -e "\n${BLUE}=== 測試 3: 簡化的 System prompt ===${NC}"
echo "測試簡化的 System prompt..."

simple_prompt="あなたは冷淡なキャラクターです。短い文で答えてください。"

response3=$(curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"qwen2.5:3b\", \"prompt\": \"System: $simple_prompt\\nUser: こんにちは\\nAssistant:\", \"stream\": false}" \
  -s)

echo "回應: $(echo "$response3" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)"

echo -e "\n${BLUE}=== 測試 4: 直接測試後端 API ===${NC}"
echo "測試後端 API 的實際響應..."

backend_response=$(curl -X POST "http://localhost:8000/chat" \
  -H "Content-Type: application/json" \
  -d '{"message": "こんにちは"}' \
  -s)

echo "後端回應: $backend_response"

echo -e "\n${YELLOW}=== 分析結果 ===${NC}"
echo "如果測試 1 正常但測試 2 異常，說明 System prompt 格式有問題"
echo "如果測試 2 正常但後端 API 異常，說明後端處理有問題"
