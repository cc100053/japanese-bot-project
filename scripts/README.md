# 🎮 Japanese Bot Project - Launch Scripts

This directory contains scripts to easily launch and manage your Japanese Bot visual novel game.

## 🚀 Quick Start

### One-Click Launch (Recommended)
```bash
# From the japanese-bot-project root directory
./scripts/launch_game.sh
```

This single command will:
1. ✅ Start all backend services (API, TTS, etc.)
2. ✅ Launch Android emulator (if not already running)
3. ✅ Wait for emulator to be ready
4. ✅ Launch the Flutter visual novel app
5. ✅ Handle all dependencies automatically

### Manual Launch (if you prefer step-by-step)
```bash
# Start backend
cd scripts
./start_all.sh

# In another terminal, launch emulator
cd mobile/japanese_cold_bot
flutter emulators --launch "Pixel 7"  # or your preferred emulator

# Run the app
flutter run
```

## 🛑 Stopping the Game

### Stop Everything
```bash
./scripts/stop_game.sh
```

### Stop Backend Only
```bash
cd scripts
./stop_all.sh
```

## 📱 Prerequisites

Before using these scripts, ensure you have:

- ✅ **Flutter** installed and in PATH
- ✅ **Android SDK** installed with ADB
- ✅ **Android Emulator** created (Pixel 7 recommended)
- ✅ **Python** with required packages (handled by start_all.sh)

## 🔧 Troubleshooting

### Common Issues

1. **"Flutter not found"**
   - Install Flutter: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **"No emulators found"**
   - Create an emulator in Android Studio
   - Or use: `flutter emulators --create --name Pixel7`

3. **"Backend failed to start"**
   - Check if ports 8000 and 11434 are available
   - Ensure Ollama is installed: https://ollama.ai/

4. **"Permission denied"**
   - Make scripts executable: `chmod +x scripts/*.sh`

### Manual Checks

```bash
# Check Flutter
flutter doctor

# Check emulators
flutter emulators

# Check ADB
adb devices

# Check backend status
curl http://localhost:8000/health
```

## 🎯 What Gets Started

- **Backend API** (Port 8000)
- **Ollama LLM** (Port 11434)
- **Android Emulator**
- **Flutter App**

## 📁 Script Files

- `launch_game.sh` - One-click launcher (main script)
- `stop_game.sh` - Clean shutdown
- `start_all.sh` - Backend services only
- `stop_all.sh` - Backend services only

## 🎮 Enjoy Your Visual Novel!

Once launched, you'll see:
- Beautiful visual novel interface
- Character: 涼宮ハルヒ
- TTS voice synthesis
- Smooth animations and transitions
- Professional galgame experience

Happy gaming! 🎭✨
