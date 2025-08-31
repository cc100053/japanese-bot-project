#!/bin/bash
# Android 模擬器連接測試腳本
# 文件位置: ~/japanese-bot-project/scripts/test_android_connection.sh

echo "📱 測試 Android 模擬器連接配置..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 獲取主機 IP 地址
HOST_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

echo -e "${BLUE}=== 測試 1: localhost:8000 (主機) ===${NC}"
echo "測試主機的 localhost 連接..."

if curl -s --max-time 5 http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✓ localhost:8000 連接正常${NC}"
else
    echo -e "${RED}✗ localhost:8000 連接失敗${NC}"
fi

echo -e "\n${BLUE}=== 測試 2: $HOST_IP:8000 (Android 模擬器) ===${NC}"
echo "測試 Android 模擬器的主機 IP 連接..."

if curl -s --max-time 5 http://$HOST_IP:8000/health > /dev/null; then
    echo -e "${GREEN}✓ $HOST_IP:8000 連接正常${NC}"
else
    echo -e "${RED}✗ $HOST_IP:8000 連接失敗${NC}"
fi

echo -e "\n${BLUE}=== 測試 3: 聊天功能 ($HOST_IP) ===${NC}"
echo "測試 Android 模擬器的聊天功能..."

chat_response=$(curl -s --max-time 10 -X POST "http://$HOST_IP:8000/chat" \
    -H "Content-Type: application/json" \
    -d '{"message": "テスト"}' 2>/dev/null)

if [ $? -eq 0 ] && echo "$chat_response" | grep -q "response"; then
    echo -e "${GREEN}✓ 聊天功能正常${NC}"
    reply=$(echo "$chat_response" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)
    echo -e "${CYAN}AI 回應: $reply${NC}"
else
    echo -e "${RED}✗ 聊天功能失敗${NC}"
    echo "響應: $chat_response"
fi

echo -e "\n${YELLOW}=== 配置說明 ===${NC}"
echo "• Android 模擬器使用: ${CYAN}$HOST_IP:8000${NC}"
echo "• iOS 模擬器使用: ${CYAN}localhost:8000${NC}"
echo "• 實體設備使用: ${CYAN}$HOST_IP:8000${NC}"

echo -e "\n${YELLOW}=== Flutter 配置已更新 ===${NC}"
echo "• API 服務已自動檢測平台"
echo "• Android 使用主機 IP: ${CYAN}$HOST_IP:8000${NC}"
echo "• 其他平台使用: ${CYAN}localhost:8000${NC}"

echo -e "\n${YELLOW}=== 下一步 ===${NC}"
echo "1. 在 Flutter 應用中執行熱重載 (R)"
echo "2. 或者重新啟動 Flutter 應用"
echo "3. 測試聊天功能是否正常工作"
