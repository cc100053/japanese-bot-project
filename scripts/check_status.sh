#!/bin/bash
# 文件位置: ~/japanese-bot-project/scripts/check_status.sh
# 快速檢查所有服務狀態

echo "📊 服務狀態檢查..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 檢查端口函數
check_port() {
    local service=$1
    local port=$2
    local url=$3
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $service (端口:$port) 正在運行${NC}"
        if [ ! -z "$url" ]; then
            response=$(curl -s --max-time 5 "$url" 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo -e "  ${BLUE}└─ HTTP 響應正常${NC}"
            else
                echo -e "  ${YELLOW}└─ HTTP 響應異常${NC}"
            fi
        fi
        return 0
    else
        echo -e "${RED}✗ $service (端口:$port) 未運行${NC}"
        return 1
    fi
}

echo -e "${BLUE}=== 端口狀態檢查 ===${NC}"
check_port "Ollama" "11434" "http://localhost:11434"
check_port "VOICEVOX" "50021" "http://localhost:50021/speakers"
check_port "Backend API" "8000" "http://localhost:8000"

echo -e "\n${BLUE}=== 進程檢查 ===${NC}"

# 檢查 Ollama 進程
if pgrep -f "ollama serve" > /dev/null; then
    echo -e "${GREEN}✓ Ollama 進程運行中${NC}"
else
    echo -e "${RED}✗ Ollama 進程未找到${NC}"
fi

# 檢查 API 進程
if pgrep -f "uvicorn main:app" > /dev/null; then
    echo -e "${GREEN}✓ API 進程運行中${NC}"
else
    echo -e "${RED}✗ API 進程未找到${NC}"
fi

# 檢查 Docker 容器
if docker ps | grep -q "voicevox-engine"; then
    echo -e "${GREEN}✓ VOICEVOX 容器運行中${NC}"
else
    echo -e "${RED}✗ VOICEVOX 容器未運行${NC}"
fi

echo -e "\n${BLUE}=== 模型檢查 ===${NC}"
models=$(ollama list 2>/dev/null | tail -n +2)
if [ ! -z "$models" ]; then
    echo -e "${GREEN}✓ 已安裝模型：${NC}"
    echo "$models" | while read line; do
        echo -e "  ${YELLOW}└─ $line${NC}"
    done
else
    echo -e "${RED}✗ 未找到已安裝的模型${NC}"
fi

echo -e "\n${BLUE}=== 快速功能測試 ===${NC}"
if curl -s --max-time 5 http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API 健康檢查通過${NC}"
    health=$(curl -s --max-time 5 http://localhost:8000/health 2>/dev/null)
    echo "$health" | python3 -m json.tool 2>/dev/null || echo "$health"
else
    echo -e "${RED}✗ API 健康檢查失敗${NC}"
fi

echo -e "\n${BLUE}=== 日誌文件檢查 ===${NC}"
LOG_DIR="$HOME/japanese-bot-project/logs"
if [ -d "$LOG_DIR" ]; then
    for log_file in api.log ollama.log; do
        log_path="$LOG_DIR/$log_file"
        if [ -f "$log_path" ]; then
            size=$(ls -lh "$log_path" | awk '{print $5}')
            echo -e "${GREEN}✓ $log_file ($size)${NC}"
        else
            echo -e "${YELLOW}- $log_file 不存在${NC}"
        fi
    done
else
    echo -e "${YELLOW}- 日誌目錄不存在${NC}"
fi

echo -e "\n${BLUE}=== 總結 ===${NC}"
echo -e "如果所有服務都在運行，現在可以啟動 Flutter 應用："
echo -e "${CYAN}cd ~/japanese-bot-project/mobile/japanese_cold_bot && flutter run${NC}"