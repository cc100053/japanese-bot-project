#!/bin/bash

# Japanese Bot Project - Game Stopper
# This script orchestrates the stopping of all game-related services.

echo "🛑 Stopping Japanese Bot Project..."

# Get the directory of the script to ensure paths are correct
SCRIPT_DIR="$(dirname "$0")"

# --- 1. Stop Backend Services ---
# The stop_all.sh script handles Uvicorn, Ollama, and Docker.
echo "--- Stopping backend services (using stop_all.sh) ---"
if [[ -f "$SCRIPT_DIR/stop_all.sh" ]]; then
    "$SCRIPT_DIR/stop_all.sh"
else
    echo "⚠️ Warning: stop_all.sh not found. Backend services may need to be stopped manually."
fi

# --- 2. Stop Flutter Application ---
# stop_all.sh only warns about Flutter, so we stop it here explicitly.
echo "--- Stopping Flutter application ---"
if pgrep -f "flutter" > /dev/null; then
    pkill -f "flutter"
    echo "✅ Flutter application stopped."
else
    echo "ℹ️ Flutter application was not running."
fi

echo "✅ Game stop sequence complete."