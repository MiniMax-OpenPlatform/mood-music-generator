#!/bin/bash

# 心情音乐生成器 - APK 自动构建脚本

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  心情音乐生成器 APK 构建脚本${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter 未安装${NC}"
    echo -e "${YELLOW}请访问 https://flutter.dev/docs/get-started/install 安装 Flutter${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Flutter 环境已就绪${NC}"

# 创建构建目录
BUILD_DIR="mood_music_app_build"

if [ -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}! 构建目录已存在，将重新使用${NC}"
else
    echo -e "${GREEN}→ 创建 Flutter 项目结构...${NC}"
    flutter create --org com.moodmusic --project-name mood_music_app $BUILD_DIR
fi

# 复制源代码
echo -e "${GREEN}→ 复制源代码...${NC}"
cp -r mood_music_app/lib/* $BUILD_DIR/lib/
cp mood_music_app/pubspec.yaml $BUILD_DIR/

# 进入构建目录
cd $BUILD_DIR

# 安装依赖
echo -e "${GREEN}→ 安装依赖...${NC}"
flutter pub get

# 清理旧构建
echo -e "${GREEN}→ 清理旧构建...${NC}"
flutter clean

# 构建 APK
echo -e "${GREEN}→ 开始编译 Release APK...${NC}"
echo -e "${YELLOW}  (此过程可能需要 5-15 分钟)${NC}"
flutter build apk --release --split-per-abi

# 显示结果
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  ✓ 编译成功！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${GREEN}APK 文件位于:${NC}"
ls -lh build/app/outputs/flutter-apk/*.apk

# 复制到 releases 目录
cd ..
mkdir -p releases
cp $BUILD_DIR/build/app/outputs/flutter-apk/*.apk releases/
echo ""
echo -e "${GREEN}✓ APK 已复制到 releases/ 目录${NC}"
echo ""
echo -e "${YELLOW}推荐安装: releases/app-arm64-v8a-release.apk (适用于大多数设备)${NC}"
