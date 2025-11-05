# 最简单的 APK 编译指南

GitHub Actions 遇到了一些环境问题。这里提供最简单的本地编译方案。

## 方案一：使用在线 Flutter 编译服务（推荐，最简单）

### Codemagic（免费）

1. **注册账号**
   - 访问：https://codemagic.io/
   - 用 GitHub 账号登录

2. **添加项目**
   - 点击 "Add application"
   - 选择 "mood-music-generator" 仓库
   - 选择 "Flutter App"

3. **配置构建**
   ```yaml
   workflows:
     android-workflow:
       name: Android Workflow
       scripts:
         - name: Build APK
           script: |
             cd mood_music_app
             flutter packages pub get
             flutter build apk --release
       artifacts:
         - build/app/outputs/flutter-apk/*.apk
   ```

4. **开始构建**
   - 点击 "Start new build"
   - 等待 10 分钟
   - 下载 APK

**优点**：
- ✅ 完全免费（每月 500 分钟）
- ✅ 无需本地环境
- ✅ 自动配置所有依赖
- ✅ 提供构建日志

---

## 方案二：本地编译（如果你有 Flutter 环境）

### 前提条件
- 已安装 Flutter SDK
- 已安装 Android SDK

### 快速编译脚本

创建文件 `quick_build.sh`：

```bash
#!/bin/bash

echo "🚀 开始编译 APK..."

# 1. 创建临时项目
flutter create --org com.moodmusic --project-name mood_music_app temp_build

# 2. 复制代码
cp -r mood_music_app/lib/* temp_build/lib/
cp mood_music_app/pubspec.yaml temp_build/

# 3. 进入目录
cd temp_build

# 4. 安装依赖
flutter pub get

# 5. 编译
flutter build apk --release

# 6. 显示结果
echo ""
echo "✅ 编译完成！"
echo ""
echo "APK 位置："
ls -lh build/app/outputs/flutter-apk/*.apk

# 7. 复制到主目录
cd ..
mkdir -p apk_output
cp temp_build/build/app/outputs/flutter-apk/*.apk apk_output/

echo ""
echo "APK 已复制到: apk_output/"
```

使用方法：
```bash
chmod +x quick_build.sh
./quick_build.sh
```

---

## 方案三：使用 Docker（跨平台）

如果你有 Docker，这是最可靠的方式：

```bash
# 1. 拉取 Flutter 镜像
docker pull cirrusci/flutter:stable

# 2. 运行构建
docker run --rm -v $(pwd):/app cirrusci/flutter:stable \
  sh -c "cd /app && \
         flutter create --org com.moodmusic temp && \
         cp -r mood_music_app/lib/* temp/lib/ && \
         cp mood_music_app/pubspec.yaml temp/ && \
         cd temp && \
         flutter pub get && \
         flutter build apk --release && \
         cp build/app/outputs/flutter-apk/*.apk /app/"

# APK 会出现在当前目录
```

---

## 方案四：手动步骤（最详细）

### 步骤 1: 安装 Flutter

**Windows**:
```powershell
# 下载
https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip

# 解压到 C:\flutter
# 添加到 PATH: C:\flutter\bin
```

**macOS**:
```bash
brew install flutter
```

**Linux**:
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"
```

### 步骤 2: 验证环境

```bash
flutter doctor
```

确保显示：
```
✓ Flutter (Channel stable, 3.19.0)
✓ Android toolchain
```

### 步骤 3: 克隆项目

```bash
git clone https://github.com/backearth1/mood-music-generator.git
cd mood-music-generator
```

### 步骤 4: 创建完整项目

```bash
flutter create --org com.moodmusic --project-name mood_music_app build_temp
```

### 步骤 5: 复制代码

```bash
# Windows PowerShell
Copy-Item -Recurse mood_music_app\lib\* build_temp\lib\
Copy-Item mood_music_app\pubspec.yaml build_temp\

# macOS/Linux
cp -r mood_music_app/lib/* build_temp/lib/
cp mood_music_app/pubspec.yaml build_temp/
```

### 步骤 6: 编译

```bash
cd build_temp
flutter pub get
flutter build apk --release
```

### 步骤 7: 获取 APK

```
位置: build_temp/build/app/outputs/flutter-apk/
文件: app-release.apk
```

---

## 预编译 APK（如果都不行）

如果以上方法都有问题，我可以：

1. **在本地服务器编译好 APK**
2. **上传到网盘**
3. **发给你下载链接**

只需要告诉我你需要，我可以提供预编译的 APK。

---

## 常见问题

### Q: Flutter 安装失败？
A: 使用在线服务（Codemagic），无需本地安装

### Q: 编译时间太长？
A: 首次编译 15-20 分钟正常，后续 3-5 分钟

### Q: 提示 SDK 版本问题？
A: 运行 `flutter upgrade` 更新到最新版本

### Q: Gradle 下载慢？
A: 使用国内镜像或 VPN

---

## 推荐优先级

1. **Codemagic 在线编译** ⭐⭐⭐⭐⭐ 最简单
2. **本地脚本编译** ⭐⭐⭐⭐ 如果有环境
3. **Docker 编译** ⭐⭐⭐ 最可靠
4. **手动编译** ⭐⭐ 最详细
5. **预编译 APK** ⭐ 最后的选择

---

## 下一步

选择一个方案尝试，如果遇到问题随时告诉我！
