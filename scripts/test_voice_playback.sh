#!/bin/bash

# 音声播放功能测试脚本
# 用于测试模拟器上的TTS音声播放

echo "🎵 开始测试音声播放功能..."

# 检查Flutter环境
echo "📱 检查Flutter环境..."
flutter --version

# 检查项目依赖
echo "📦 检查项目依赖..."
cd mobile/japanese_cold_bot
flutter pub get

# 尝试编译项目
echo "🔨 尝试编译Flutter项目..."
if flutter build apk --debug; then
    echo "✅ Flutter项目编译成功"
else
    echo "❌ Flutter项目编译失败，请检查代码错误"
    exit 1
fi

# 返回项目根目录
cd ../..

# 检查后端服务状态
echo "📡 检查后端服务状态..."
if command -v curl &> /dev/null; then
    curl -s http://localhost:8000/health | jq '.' 2>/dev/null || echo "❌ 无法连接到后端服务"
else
    echo "⚠️  curl命令未找到，跳过后端服务检查"
fi

# 检查VOICEVOX服务状态
echo "🔊 检查VOICEVOX服务状态..."
if command -v curl &> /dev/null; then
    curl -s http://localhost:50021/speakers | jq '.[0].name' 2>/dev/null || echo "❌ 无法连接到VOICEVOX服务"
else
    echo "⚠️  curl命令未找到，跳过VOICEVOX服务检查"
fi

# 测试音声合成
echo "🎤 测试音声合成..."
if command -v curl &> /dev/null; then
    curl -X POST "http://localhost:8000/synthesize" \
      -H "Content-Type: application/json" \
      -d '{"text": "こんにちは、テストです。", "speaker": 1}' \
      | jq '.' 2>/dev/null || echo "❌ 音声合成失败"
else
    echo "⚠️  curl命令未找到，跳过音声合成测试"
fi

echo "✅ 测试完成！"
echo ""
echo "📱 在模拟器上测试步骤："
echo "1. 启动Flutter应用: flutter run"
echo "2. 发送消息给AI"
echo "3. 观察是否自动播放TTS音声"
echo "4. 检查控制台日志中的音声播放状态"
echo ""
echo "🔧 如果音声不播放，请检查："
echo "- 模拟器音量设置"
echo "- 后端服务是否正常运行"
echo "- VOICEVOX服务是否启动"
echo "- 网络连接是否正常"
echo ""
echo "🐛 如果编译失败，请检查："
echo "- Flutter SDK版本是否兼容"
echo "- 依赖包版本是否正确"
echo "- 代码语法是否有错误"
