#!/bin/bash
set -e

PROJECT_DIR="/home/ben/projects/game/block-defense"
EXPORT_DIR="$PROJECT_DIR/export/web"
GODOT="$HOME/bin/godot"

echo "Exporting Block Defense to web..."
mkdir -p "$EXPORT_DIR"

cd "$PROJECT_DIR"
$GODOT --headless --export-release "Web" "$EXPORT_DIR/index.html"

echo "Export complete: $EXPORT_DIR"
ls -la "$EXPORT_DIR"
