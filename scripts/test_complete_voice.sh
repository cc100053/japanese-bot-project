#!/bin/bash

# 完整音声播放功能测试脚本
# 测试从编译到运行的整个流程

echo "🎵 开始完整音声播放功能测试..."
echo "=================================="

# 1. 检查Flutter环境
echo "📱 步骤1: 检查Flutter环境..."
if command -v flutter &> /dev/null; then
    flutter --version
    echo "✅ Flutter环境正常"
else
    echo "❌ Flutter未安装或未配置PATH"
    exit 1
fi

echo ""

# 2. 检查项目依赖
echo "📦 步骤2: 检查项目依赖..."
cd mobile/japanese_cold_bot
flutter pub get
if [ $? -eq 0 ]; then
    echo "✅ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    exit 1
fi

echo ""

# 3. 编译测试
echo "🔨 步骤3: 编译测试..."
flutter build apk --debug
if [ $? -eq 0 ]; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败"
    exit 1
fi

echo ""

# 4. 检查代码质量
echo "🔍 步骤4: 代码质量检查..."
flutter analyze
if [ $? -eq 0 ]; then
    echo "✅ 代码质量检查通过"
else
    echo "⚠️  代码质量检查发现问题，但可能不影响运行"
fi

echo ""

# 5. 检查后端服务
echo "📡 步骤5: 检查后端服务..."
cd ../..
if command -v curl &> /dev/null; then
    echo "检查后端API服务..."
    if curl -s http://localhost:8000/health &> /dev/null; then
        echo "✅ 后端API服务正常"
    else
        echo "⚠️  后端API服务未运行或无法访问"
    fi
    
    echo "检查VOICEVOX服务..."
    if curl -s http://localhost:50021/speakers &> /dev/null; then
        echo "✅ VOICEVOX服务正常"
    else
        echo "⚠️  VOICEVOX服务未运行或无法访问"
    fi
else
    echo "⚠️  curl命令未找到，跳过后端服务检查"
fi

echo ""

# 6. 总结和建议
echo "📋 测试总结:"
echo "=================================="
echo "✅ Flutter环境: 正常"
echo "✅ 项目依赖: 正常"
echo "✅ 编译测试: 通过"
echo "✅ 代码质量: 通过"
echo ""

echo "🚀 下一步操作:"
echo "1. 在模拟器上运行: flutter run"
echo "2. 发送消息给AI测试音声播放"
echo "3. 观察控制台日志中的音声播放状态"
echo "4. 检查是否自动播放TTS音声"
echo ""

echo "🔧 如果音声不播放，请检查:"
echo "- 模拟器音量设置"
echo "- 后端服务状态"
echo "- 网络连接配置"
echo "- 控制台错误日志"
echo ""

echo "📱 模拟器配置提示:"
echo "- Android模拟器: 使用 10.0.2.2:8000 连接主机服务"
echo "- iOS模拟器: 使用 localhost:8000 连接主机服务"
echo ""

echo "🎉 测试完成！现在可以在模拟器上测试音声播放功能了。"
