#!/bin/bash
# 文件位置: ~/japanese-bot-project/scripts/stop_all.sh
# 停止所有日語聊天機器人服務

echo "🛑 停止日語冷淡聊天機器人系統..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 停止 API 服務
echo -e "${BLUE}停止後端 API 服務...${NC}"
API_PIDS=$(pgrep -f "uvicorn main:app")
if [ ! -z "$API_PIDS" ]; then
    kill -TERM $API_PIDS
    sleep 2
    # 如果還在運行，強制殺死
    REMAINING_PIDS=$(pgrep -f "uvicorn main:app")
    if [ ! -z "$REMAINING_PIDS" ]; then
        kill -KILL $REMAINING_PIDS
    fi
    echo -e "${GREEN}✓ API 服務已停止${NC}"
else
    echo -e "${YELLOW}API 服務未運行${NC}"
fi

# 停止 VOICEVOX 容器
echo -e "${BLUE}停止 VOICEVOX 服務...${NC}"
if docker ps | grep -q "voicevox-engine"; then
    docker stop voicevox-engine
    docker rm voicevox-engine
    echo -e "${GREEN}✓ VOICEVOX 服務已停止${NC}"
else
    echo -e "${YELLOW}VOICEVOX 服務未運行${NC}"
fi

# 停止 Ollama 服務
echo -e "${BLUE}停止 Ollama 服務...${NC}"
OLLAMA_PIDS=$(pgrep -f "ollama serve")
if [ ! -z "$OLLAMA_PIDS" ]; then
    kill -TERM $OLLAMA_PIDS
    sleep 2
    # 如果還在運行，強制殺死
    REMAINING_PIDS=$(pgrep -f "ollama serve")
    if [ ! -z "$REMAINING_PIDS" ]; then
        kill -KILL $REMAINING_PIDS
    fi
    echo -e "${GREEN}✓ Ollama 服務已停止${NC}"
else
    echo -e "${YELLOW}Ollama 服務未運行${NC}"
fi

# 清理 Flutter 進程（如果在運行）
echo -e "${BLUE}檢查 Flutter 進程...${NC}"
FLUTTER_PIDS=$(pgrep -f "flutter")
if [ ! -z "$FLUTTER_PIDS" ]; then
    echo -e "${YELLOW}發現 Flutter 進程，建議手動停止${NC}"
    echo -e "${YELLOW}使用 Ctrl+C 停止 flutter run${NC}"
fi

echo -e "${GREEN}🏁 所有服務已停止${NC}"

# 顯示端口檢查
echo -e "${BLUE}最終端口檢查：${NC}"
for port in 8000 11434 50021; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${RED}⚠ 端口 $port 仍被占用${NC}"
    else
        echo -e "${GREEN}✓ 端口 $port 已釋放${NC}"
    fi
done