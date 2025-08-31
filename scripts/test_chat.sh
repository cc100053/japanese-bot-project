#!/bin/bash
# 聊天功能測試腳本
# 文件位置: ~/japanese-bot-project/scripts/test_chat.sh

echo "🧪 測試聊天功能..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 測試聊天端點
echo -e "${BLUE}測試聊天端點...${NC}"

# 發送測試請求
echo "發送測試消息: テスト"
chat_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" --max-time 20 -X POST "http://localhost:8000/chat" \
    -H "Content-Type: application/json" \
    -d '{"message": "テスト"}' 2>/dev/null)

# 分離響應內容和狀態碼
http_status=$(echo "$chat_response" | grep "HTTP_STATUS:" | cut -d: -f2)
response_body=$(echo "$chat_response" | grep -v "HTTP_STATUS:")

echo -e "${CYAN}HTTP 狀態碼: $http_status${NC}"
echo -e "${CYAN}響應內容: $response_body${NC}"

# 檢查響應
if [ "$http_status" = "200" ]; then
    if echo "$response_body" | grep -q "response"; then
        echo -e "${GREEN}✓ 聊天功能正常${NC}"
        
        # 提取 AI 回應
        reply=$(echo "$response_body" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)
        echo -e "${GREEN}AI 回應: $reply${NC}"
    else
        echo -e "${RED}✗ 響應中缺少 'response' 字段${NC}"
        echo -e "${YELLOW}完整響應: $response_body${NC}"
    fi
else
    echo -e "${RED}✗ HTTP 錯誤: $http_status${NC}"
    echo -e "${YELLOW}錯誤響應: $response_body${NC}"
fi

echo ""
echo -e "${BLUE}=== 調試信息 ===${NC}"
echo -e "• 檢查後端日誌: ${CYAN}tail -f ~/japanese-bot-project/logs/api.log${NC}"
echo -e "• 檢查 Ollama 日誌: ${CYAN}tail -f ~/japanese-bot-project/logs/ollama.log${NC}"
echo -e "• 檢查 Ollama 狀態: ${CYAN}curl -s http://localhost:11434/api/tags${NC}"
echo -e "• 檢查後端狀態: ${CYAN}curl -s http://localhost:8000/health${NC}"
