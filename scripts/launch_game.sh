#!/bin/bash

# Japanese Bot Project - One-Click Game Launcher
# This script starts the backend, launches Android emulator, and runs the Flutter app

set -e  # Exit on any error

echo "🎮 Starting Japanese Bot Project - One-Click Launch..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -d "scripts" ]]; then
    print_error "Please run this script from the japanese-bot-project root directory"
    print_status "Current directory: $(pwd)"
    print_status "Expected: ~/japanese-bot-project"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists flutter; then
    print_error "Flutter is not installed or not in PATH"
    print_status "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

if ! command_exists adb; then
    print_error "Android Debug Bridge (adb) is not installed or not in PATH"
    print_status "Please install Android SDK first"
    exit 1
fi

print_success "Prerequisites check passed"

# Step 1: Start the backend
print_status "Step 1: Starting backend services..."
cd scripts
if [[ -f "./start_all.sh" ]]; then
    print_status "Running start_all.sh..."
    ./start_all.sh &
    BACKEND_PID=$!
    print_success "Backend started with PID: $BACKEND_PID"
else
    print_error "start_all.sh not found in scripts directory"
    exit 1
fi

# Wait a bit for backend to initialize
print_status "Waiting for backend to initialize..."
sleep 5

# Step 2: Check if emulator is already running
print_status "Step 2: Checking Android emulator status..."
if adb devices | grep -q "emulator"; then
    print_success "Android emulator is already running"
    EMULATOR_RUNNING=true
else
    print_status "No emulator running, will launch one..."
    EMULATOR_RUNNING=false
fi

# Step 3: Launch emulator if needed
if [[ "$EMULATOR_RUNNING" == "false" ]]; then
    print_status "Step 3: Launching Android emulator..."
    
    # Check available emulators
    AVAILABLE_EMULATORS=$(flutter emulators | grep -E "Pixel|Android" | head -1 | awk '{print $1}' | tr -d '•')
    
    if [[ -n "$AVAILABLE_EMULATORS" ]]; then
        print_status "Found emulator: $AVAILABLE_EMULATORS"
        print_status "Launching emulator (this may take a few minutes)..."
        
        # Launch emulator in background
        flutter emulators --launch "$AVAILABLE_EMULATORS" &
        EMULATOR_LAUNCH_PID=$!
        
        # Wait for emulator to be ready
        print_status "Waiting for emulator to be ready..."
        while ! adb devices | grep -q "emulator"; do
            sleep 3
            print_status "Still waiting for emulator..."
        done
        
        print_success "Emulator is now ready!"
    else
        print_error "No Android emulators found"
        print_status "Please create an emulator first using Android Studio"
        exit 1
    fi
else
    print_success "Emulator already running, skipping launch step"
fi

# Step 4: Wait for emulator to be fully ready
print_status "Step 4: Ensuring emulator is fully ready..."
sleep 10

# Step 5: Navigate to Flutter project and run
print_status "Step 5: Launching Flutter app..."
cd ../mobile/japanese_cold_bot

# Check if Flutter project is ready
if [[ ! -f "pubspec.yaml" ]]; then
    print_error "Flutter project not found at mobile/japanese_cold_bot"
    exit 1
fi

# Get dependencies if needed
print_status "Checking Flutter dependencies..."
flutter pub get

# Run the app
print_status "Starting Flutter app..."
print_success "🎮 Game is launching! Enjoy your visual novel experience!"
echo ""
print_status "Backend PID: $BACKEND_PID"
print_status "To stop everything, run: ./scripts/stop_all.sh"
echo ""

# Run Flutter app (this will block until app is closed)
flutter run

# Cleanup when app is closed
print_status "App closed, cleaning up..."
if [[ -n "$BACKEND_PID" ]]; then
    print_status "Stopping backend..."
    kill $BACKEND_PID 2>/dev/null || true
fi

print_success "🎮 Game session ended. Thanks for playing!"
