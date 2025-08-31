# 模擬器音声播放測試指南

## 🎯 功能概述

本應用在AI回覆時會自動播放TTS合成的音声，提供更好的用戶體驗。

## 🚀 測試步驟

### 1. 環境準備

確保以下服務正在運行：

```bash
# 檢查後端服務
curl http://localhost:8000/health

# 檢查VOICEVOX服務
curl http://localhost:50021/speakers
```

### 2. 啟動應用

```bash
cd mobile/japanese_cold_bot
flutter run
```

### 3. 測試音声播放

1. 在聊天界面發送任意消息
2. 等待AI回覆
3. 觀察是否自動播放TTS音声
4. 檢查頂部工具列是否顯示"音声再生中..."狀態

## 🔧 故障排除

### 編譯錯誤

**常見錯誤：**
```
Error: The getter 'onPlayerError' isn't defined for the type 'AudioPlayer'.
```

**解決方法：**
這是 `audioplayers` 5.2.1 版本的API變化導致的。已修復為使用 `onPlayerException`。

**其他可能的API變化：**
- `onPlayerError` → `onPlayerException`
- `onAudioPositionChanged` → `onPositionChanged`

### 音声不播放

**可能原因：**
- 模擬器音量設置過低
- 後端服務未啟動
- VOICEVOX服務未啟動
- 網絡連接問題

**解決方法：**
1. 檢查模擬器音量設置
2. 確認後端服務狀態
3. 重啟VOICEVOX服務
4. 檢查防火牆設置

### 音声播放錯誤

**檢查日誌：**
```bash
# 查看Flutter應用日誌
flutter logs

# 查看後端日誌
tail -f logs/api.log
```

**常見錯誤：**
- `Audio player exception`: 音声播放器異常
- `Voice synthesis failed`: 音声合成失敗
- `Connection failed`: 連接失敗

## 📱 模擬器特定設置

### Android 模擬器

- **IP地址**: 使用 `10.0.2.2:8000` 連接主機服務
- **音量設置**: 確保媒體音量不為0
- **權限**: 確保應用有音声播放權限

### iOS 模擬器

- **IP地址**: 使用 `localhost:8000` 連接主機服務
- **音量設置**: 使用系統音量控制
- **權限**: 確保應用有音声播放權限

## 🎵 音声播放狀態

### 視覺指示器

- **頂部工具列**: 顯示"音声再生中..."狀態
- **停止按鈕**: 音声播放時顯示紅色停止按鈕
- **角色立繪**: 音声播放時顯示音声圖標

### 控制功能

- **自動播放**: AI回覆後自動開始播放
- **手動停止**: 點擊停止按鈕停止播放
- **重複播放**: 點擊聊天氣泡的音声圖標重複播放

## 📊 性能優化

### 音声緩存

- 相同文本的音声會被緩存
- 避免重複合成相同內容
- 提升播放響應速度

### 錯誤處理

- 音声合成失敗時顯示錯誤提示
- 網絡錯誤時自動重試
- 播放錯誤時自動恢復

## 🧪 測試腳本

使用提供的測試腳本快速驗證功能：

```bash
# 基本功能測試
chmod +x scripts/test_voice_playback.sh
./scripts/test_voice_playback.sh

# API兼容性檢查
chmod +x scripts/fix_audioplayers_api.sh
./scripts/fix_audioplayers_api.sh
```

## 📝 開發者注意事項

### 日誌輸出

應用會在控制台輸出詳細的音声播放日誌：

```
🎵 Starting voice synthesis for: こんにちは
🎵 Audio path received: /static/audio/voice_abc123.wav
🎵 Full audio URL: http://10.0.2.2:8000/static/audio/voice_abc123.wav
🎵 Audio playback started
🎵 Audio player state changed: playing
🎵 Audio playback completed
```

### 狀態管理

- `_isPlayingVoice`: 追蹤音声播放狀態
- `_audioPlayer`: 管理音声播放器實例
- 自動狀態同步和錯誤恢復

### API兼容性

**audioplayers 5.2.1 版本變化：**
- 使用 `onPlayerException` 替代 `onPlayerError`
- 使用 `onPositionChanged` 替代 `onAudioPositionChanged`
- 錯誤對象使用 `error.message` 獲取錯誤信息

## 🎉 成功標準

音声播放功能正常工作時：

1. ✅ AI回覆後自動開始播放TTS音声
2. ✅ 頂部工具列顯示播放狀態
3. ✅ 可以手動停止音声播放
4. ✅ 音声播放完成後狀態自動更新
5. ✅ 錯誤情況下顯示適當的提示信息
6. ✅ 編譯無錯誤，應用正常啟動

## 🐛 常見問題解決

### 問題1: 編譯錯誤
**症狀**: `onPlayerError` 未定義
**解決**: 已修復為使用 `onPlayerException`

### 問題2: 音声不播放
**症狀**: 應用正常但無音声
**解決**: 檢查模擬器音量、後端服務狀態

### 問題3: 網絡連接失敗
**症狀**: 音声合成失敗
**解決**: 檢查IP地址配置、防火牆設置
