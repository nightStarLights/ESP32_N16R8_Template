#!/usr/bin/env bash
# 从本模板创建一个可直接编译的新 ESP-IDF 项目
# 用法: ./create_project.sh <项目名> [目标父目录]
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${1:-}"
TARGET_ROOT="${2:-$(dirname "$TEMPLATE_DIR")}"

if [[ -z "$PROJECT_NAME" ]]; then
    echo "用法: $(basename "$0") <项目名> [目标父目录]"
    echo "示例: $(basename "$0") ESP32_Bracelet_V3"
    exit 1
fi

DEST="$TARGET_ROOT/$PROJECT_NAME"
if [[ -e "$DEST" ]]; then
    echo "错误: 目标已存在 -> $DEST"
    exit 1
fi

mkdir -p "$DEST"
rsync -a \
    --exclude '.git/' \
    --exclude 'build/' \
    --exclude 'sdkconfig.old' \
    --exclude 'create_project.sh' \
    "$TEMPLATE_DIR/" "$DEST/"

sed -i "s/^project(\"template_project\")/project(\"$PROJECT_NAME\")/" "$DEST/CMakeLists.txt"

echo "已创建干净项目: $DEST"
echo
echo "下一步:"
echo "  cd $DEST"
echo "  idf.py set-target esp32s3   # 仅在需要改目标芯片时执行"
echo "  idf.py build                # build/ 由首次构建生成"
