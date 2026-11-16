#!/bin/bash
# 长生卡工具 · iOS 只读版 —— 一键打包成未签名 ipa
# 用法：双击本文件；或在终端执行 bash build_ipa.command
# 前提：macOS + Xcode（命令行工具已安装，xcodebuild 可用）

set -e
cd "$(dirname "$0")"

PROJECT="TikaViewer.xcodeproj"
TARGET="TikaViewer"
BUILD_DIR="build"

echo "== 清理旧产物 =="
rm -rf "$BUILD_DIR" "Payload" "TikaViewer.ipa"

echo "== 编译（Release / arm64 / 不签名）=="
xcodebuild \
  -project "$PROJECT" \
  -target "$TARGET" \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64 \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/$TARGET.app"
if [ ! -d "$APP_PATH" ]; then
  echo "!! 没找到 $APP_PATH，编译可能失败" >&2
  exit 1
fi

echo "== 组装未签名 ipa =="
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qry "$TARGET.ipa" Payload
rm -rf Payload

echo ""
echo "完成：$(pwd)/$TARGET.ipa"
ls -lh "$TARGET.ipa"
echo ""
echo "下一步：把 $TARGET.ipa 传到手机，用 LiveContainer 导入并自签安装。"
