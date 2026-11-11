#!/usr/bin/env bash
# Linux / macOS 等价于 tools/build_android.ps1。
# 需要：JDK 21、Android SDK（Platform 37 / Build Tools 36.0.0 / NDK 29.0.13113456 /
# CMake 3.22.1+）、Rust 与 aarch64-linux-android target。
#
#   ./tools/build_android.sh Debug
#   ./tools/build_android.sh Release
set -euo pipefail

VARIANT="${1:-Release}"
case "$VARIANT" in
  Debug|Release) ;;
  *) echo "用法: $0 [Debug|Release]" >&2; exit 2 ;;
esac

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if [ ! -f local.properties ]; then
  echo "警告: 未找到 local.properties；请确保 ANDROID_HOME / ANDROID_NDK_HOME 已设置。" >&2
fi

task=":manager:assemble${VARIANT}"
echo "==> ./gradlew ${task}"
chmod +x ./gradlew
./gradlew "$task" --no-daemon

echo "==> 完成: ${task}（产物在 out/apk）"
