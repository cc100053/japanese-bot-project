#!/bin/bash
# 文件位置: ~/japanese-bot-project/scripts/start_all.sh
# 日語冷淡聊天機器人一鍵啟動腳本

echo "🚀 啟動日語冷淡聊天機器人系統..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 項目根目錄
PROJECT_ROOT="$HOME/japanese-bot-project"

# 日誌文件
LOG_DIR="$PROJECT_ROOT/logs"
mkdir -p "$LOG_DIR"
API_LOG="$LOG_DIR/api.log"
OLLAMA_LOG="$LOG_DIR/ollama.log"

# 檢查必要服務
check_service() {
    local service_name=$1
    local port=$2
    echo -e "${YELLOW}檢查 $service_name (端口:$port)...${NC}"
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $service_name 正在運行${NC}"
        return 0
    else
        echo -e "${RED}✗ $service_name 未運行${NC}"
        return 1
    fi
}

# 檢查命令是否存在
check_command() {
    local cmd=$1
    local install_hint=$2
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓ $cmd 已安裝${NC}"
        return 0
    else
        echo -e "${RED}✗ $cmd 未安裝${NC}"
        if [ ! -z "$install_hint" ]; then
            echo -e "${YELLOW}  安裝提示: $install_hint${NC}"
        fi
        return 1
    fi
}

# 等待服務啟動
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_wait=$3
    local count=0
    
    echo -e "${YELLOW}等待 $service_name 啟動...${NC}"
    while [ $count -lt $max_wait ]; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $service_name 已啟動 (等待時間: ${count}s)${NC}"
            return 0
        fi
        sleep 1
        count=$((count + 1))
        printf "${CYAN}.${NC}"
    done
    echo ""
    echo -e "${RED}✗ $service_name 啟動超時${NC}"
    return 1
}

# 停止現有服務
stop_services() {
    echo -e "${PURPLE}停止現有服務...${NC}"
    
    # 停止 API 服務
    pkill -f "uvicorn main:app" 2>/dev/null && echo -e "${YELLOW}已停止 API 服務${NC}"
    
    # 停止 VOICEVOX 容器
    if docker ps | grep -q "voicevox-engine"; then
        docker stop voicevox-engine 2>/dev/null && echo -e "${YELLOW}已停止 VOICEVOX 容器${NC}"
    fi
    
    # 清理舊容器
    docker rm voicevox-engine 2>/dev/null
    
    sleep 2
}

# 主函數
main() {
    echo -e "${BLUE}=== 環境檢查 ===${NC}"
    
    # 檢查必要命令
    ENV_OK=true
    check_command "ollama" "brew install ollama" || ENV_OK=false
    check_command "docker" "安裝 Docker Desktop" || ENV_OK=false
    check_command "flutter" "安裝 Flutter SDK" || ENV_OK=false
    check_command "curl" "系統自帶" || ENV_OK=false
    
    if [ "$ENV_OK" = false ]; then
        echo -e "${RED}❌ 環境檢查失敗，請先安裝缺失的工具${NC}"
        exit 1
    fi
    
    # 檢查項目目錄
    if [ ! -d "$PROJECT_ROOT" ]; then
        echo -e "${RED}❌ 項目目錄不存在: $PROJECT_ROOT${NC}"
        exit 1
    fi
    
    # 停止現有服務
    stop_services
    
    echo -e "\n${BLUE}=== 第一階段：啟動基礎服務 ===${NC}"
    
    # 1. 啟動 Ollama
    echo -e "${BLUE}1. 啟動 Ollama 服務...${NC}"
    if ! check_service "Ollama" 11434; then
        echo "正在啟動 Ollama..."
        nohup ollama serve > "$OLLAMA_LOG" 2>&1 &
        if wait_for_service "Ollama" 11434 30; then
            sleep 2  # 額外等待服務穩定
        else
            echo -e "${RED}✗ Ollama 啟動失敗，檢查日誌: tail $OLLAMA_LOG${NC}"
            exit 1
        fi
    fi
    
    # 2. 檢查和下載模型
    echo -e "${BLUE}2. 檢查語言模型...${NC}"
    available_models=$(ollama list 2>/dev/null | tail -n +2)
    
    if echo "$available_models" | grep -q "qwen2.5"; then
        echo -e "${GREEN}✓ 找到 qwen2.5 模型${NC}"
    elif echo "$available_models" | grep -q "elyza"; then
        echo -e "${GREEN}✓ 找到 ELYZA 日語模型${NC}"
    else
        echo -e "${YELLOW}正在下載輕量級模型 qwen2.5:3b (約1.4GB)...${NC}"
        echo -e "${CYAN}這可能需要幾分鐘，請耐心等待...${NC}"
        ollama pull qwen2.5:3b
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 模型下載完成${NC}"
        else
            echo -e "${RED}✗ 模型下載失敗${NC}"
            exit 1
        fi
    fi
    
    # 3. 啟動 VOICEVOX
    echo -e "${BLUE}3. 啟動 VOICEVOX TTS 服務...${NC}"
    if ! check_service "VOICEVOX" 50021; then
        echo "正在啟動 VOICEVOX Docker 容器..."
        docker run -d --name voicevox-engine -p 50021:50021 voicevox/voicevox_engine:cpu-ubuntu20.04-latest
        if wait_for_service "VOICEVOX" 50021 60; then
            echo -e "${GREEN}✓ VOICEVOX 啟動成功${NC}"
        else
            echo -e "${RED}✗ VOICEVOX 啟動失敗${NC}"
            echo -e "${YELLOW}檢查 Docker 日誌: docker logs voicevox-engine${NC}"
            exit 1
        fi
    fi
    
    echo -e "\n${BLUE}=== 第二階段：啟動後端 API ===${NC}"
    
    # 4. 檢查 Python 環境
    echo -e "${BLUE}4. 檢查 Python 後端環境...${NC}"
    if [ ! -f "$PROJECT_ROOT/backend/venv/bin/activate" ]; then
        echo -e "${RED}✗ Python 虛擬環境不存在${NC}"
        exit 1
    fi
    
    # 5. 啟動後端 API
    echo -e "${BLUE}5. 啟動後端 API 服務...${NC}"
    if ! check_service "Backend API" 8000; then
        echo "正在啟動後端 API..."
        cd "$PROJECT_ROOT/backend"
        source venv/bin/activate
        nohup uvicorn main:app --host 0.0.0.0 --port 8000 --log-level info > "$API_LOG" 2>&1 &
        if wait_for_service "Backend API" 8000 30; then
            echo -e "${GREEN}✓ 後端 API 啟動成功${NC}"
        else
            echo -e "${RED}✗ 後端 API 啟動失敗${NC}"
            echo -e "${YELLOW}檢查日誌: tail $API_LOG${NC}"
            exit 1
        fi
    fi
    
    echo -e "\n${BLUE}=== 第三階段：系統測試 ===${NC}"
    
    # 6. 測試各個服務
    echo -e "${BLUE}6. 測試服務健康狀態...${NC}"
    
    # 測試根端點
    echo "測試 API 根端點..."
    root_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" --max-time 10 http://localhost:8000/ 2>/dev/null)
    
    # 分離響應內容和狀態碼
    root_http_status=$(echo "$root_response" | grep "HTTP_STATUS:" | cut -d: -f2)
    root_response_body=$(echo "$root_response" | grep -v "HTTP_STATUS:")
    
    if [ "$root_http_status" = "200" ] && echo "$root_response_body" | grep -q "running"; then
        echo -e "${GREEN}✓ API 根端點正常${NC}"
    else
        echo -e "${RED}✗ API 根端點異常${NC}"
        echo -e "${YELLOW}HTTP 狀態碼: $root_http_status${NC}"
        echo -e "${YELLOW}響應內容: $root_response_body${NC}"
    fi
    
    # 測試健康檢查
    echo "測試健康檢查端點..."
    health_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" --max-time 15 http://localhost:8000/health 2>/dev/null)
    
    # 分離響應內容和狀態碼
    health_http_status=$(echo "$health_response" | grep "HTTP_STATUS:" | cut -d: -f2)
    health_response_body=$(echo "$health_response" | grep -v "HTTP_STATUS:")
    
    if [ "$health_http_status" = "200" ] && echo "$health_response_body" | grep -q "running"; then
        echo -e "${GREEN}✓ 健康檢查通過${NC}"
        
        # 顯示詳細健康狀態
        echo -e "${CYAN}健康狀態詳情：${NC}"
        echo "$health_response_body" | python3 -m json.tool 2>/dev/null || echo "$health_response_body"
    else
        echo -e "${RED}✗ 健康檢查失敗${NC}"
        echo -e "${YELLOW}HTTP 狀態碼: $health_http_status${NC}"
        echo -e "${YELLOW}響應內容: $health_response_body${NC}"
    fi
    
    # 測試基本對話
    echo "測試基本聊天功能..."
    chat_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" --max-time 20 -X POST "http://localhost:8000/chat" \
        -H "Content-Type: application/json" \
        -d '{"message": "テスト"}' 2>/dev/null)
    
    # 分離響應內容和狀態碼
    http_status=$(echo "$chat_response" | grep "HTTP_STATUS:" | cut -d: -f2)
    response_body=$(echo "$chat_response" | grep -v "HTTP_STATUS:")
    
    if [ "$http_status" = "200" ] && echo "$response_body" | grep -q "response"; then
        echo -e "${GREEN}✓ 聊天功能測試通過${NC}"
        reply=$(echo "$response_body" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])" 2>/dev/null)
        echo -e "${CYAN}AI 回應: $reply${NC}"
    else
        echo -e "${RED}✗ 聊天功能測試失敗${NC}"
        echo -e "${YELLOW}HTTP 狀態碼: $http_status${NC}"
        echo -e "${YELLOW}響應內容: $response_body${NC}"
        echo -e "${YELLOW}檢查後端日誌: tail -f $API_LOG${NC}"
        
        # 額外的調試信息
        if [ "$http_status" != "200" ]; then
            echo -e "${RED}HTTP 錯誤: $http_status${NC}"
        fi
        
        if ! echo "$response_body" | grep -q "response"; then
            echo -e "${RED}響應中缺少 'response' 字段${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}🎉 後端系統啟動完成！${NC}"
    echo -e "${BLUE}=== 服務信息 ===${NC}"
    echo -e "• API 服務: ${GREEN}http://localhost:8000${NC}"
    echo -e "• API 文檔: ${GREEN}http://localhost:8000/docs${NC}"
    echo -e "• 健康檢查: ${GREEN}http://localhost:8000/health${NC}"
    echo -e "• VOICEVOX: ${GREEN}http://localhost:50021/docs${NC}"
    
    echo -e "\n${YELLOW}=== Flutter 應用啟動 ===${NC}"
    echo -e "${BLUE}現在可以啟動 Flutter 應用：${NC}"
    echo -e "${CYAN}cd $PROJECT_ROOT/mobile/japanese_cold_bot${NC}"
    echo -e "${CYAN}flutter devices  # 檢查可用設備${NC}"
    echo -e "${CYAN}flutter run      # 啟動應用${NC}"
    
    echo -e "\n${YELLOW}=== 日誌文件位置 ===${NC}"
    echo -e "• API 日誌: ${CYAN}tail -f $API_LOG${NC}"
    echo -e "• Ollama 日誌: ${CYAN}tail -f $OLLAMA_LOG${NC}"
    echo -e "• Docker 日誌: ${CYAN}docker logs voicevox-engine${NC}"
    
    echo -e "\n${YELLOW}=== 停止所有服務 ===${NC}"
    echo -e "${RED}pkill -f ollama && docker stop voicevox-engine && pkill -f uvicorn${NC}"
}

# 腳本入口點
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi