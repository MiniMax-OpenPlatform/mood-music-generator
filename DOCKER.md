# Docker 部署指南

本文档介绍如何使用 Docker 部署心情音乐生成器 Web 服务。

## 📋 前置要求

- Docker >= 20.10
- Docker Compose >= 2.0（可选）

检查版本：
```bash
docker --version
docker compose version
```

## 🚀 快速开始

### 方式 1：使用 Docker Compose（推荐）

**一键启动：**
```bash
docker compose up -d
```

**查看状态：**
```bash
docker compose ps
```

**查看日志：**
```bash
docker compose logs -f
```

**停止服务：**
```bash
docker compose down
```

### 方式 2：使用 Docker 命令

**1. 构建镜像：**
```bash
# 如果需要代理，设置环境变量
export http_proxy=http://pac-internal.xaminim.com:3129
export https_proxy=http://pac-internal.xaminim.com:3129

# 构建镜像
docker build -t mood-music-generator:latest .
```

**2. 运行容器：**
```bash
docker run -d \
  --name mood-music-generator \
  -p 5111:5111 \
  -v $(pwd)/temp_sessions:/app/temp_sessions \
  --restart unless-stopped \
  mood-music-generator:latest
```

**3. 查看日志：**
```bash
docker logs -f mood-music-generator
```

**4. 停止容器：**
```bash
docker stop mood-music-generator
docker rm mood-music-generator
```

## 🔧 配置说明

### 端口映射

默认端口：`5111`

修改端口：
```bash
# 方式 1：修改 docker-compose.yml
ports:
  - "8080:5111"  # 主机端口:容器端口

# 方式 2：修改 docker run 命令
docker run -p 8080:5111 ...
```

### 数据持久化

临时音频文件存储在 `temp_sessions` 目录：

```yaml
# docker-compose.yml
volumes:
  - ./temp_sessions:/app/temp_sessions
```

### 环境变量

支持的环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `PORT` | 5111 | 服务监听端口 |

**设置方式：**
```bash
# Docker Compose
environment:
  - PORT=8080

# Docker Run
docker run -e PORT=8080 ...
```

## 📊 健康检查

Docker 容器内置健康检查：

- **检查间隔**: 30秒
- **超时时间**: 10秒
- **启动等待**: 10秒
- **重试次数**: 3次
- **检查命令**: `GET http://localhost:5111/health`

查看健康状态：
```bash
docker inspect --format='{{.State.Health.Status}}' mood-music-generator
```

## 🐛 故障排查

### 1. 容器无法启动

检查日志：
```bash
docker logs mood-music-generator
```

常见问题：
- 端口被占用：修改端口映射
- 网络不通：检查 Docker 网络配置

### 2. 构建失败

**网络问题：**
```bash
# 设置代理
export http_proxy=http://pac-internal.xaminim.com:3129
export https_proxy=http://pac-internal.xaminim.com:3129

# 重新构建
docker build --no-cache -t mood-music-generator:latest .
```

**清理缓存：**
```bash
docker builder prune -a
```

### 3. 容器健康检查失败

进入容器排查：
```bash
docker exec -it mood-music-generator bash

# 容器内检查
curl http://localhost:5111/health
python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:5111/health').read())"
```

## 📦 镜像管理

### 查看镜像

```bash
docker images | grep mood-music
```

### 删除镜像

```bash
docker rmi mood-music-generator:latest
```

### 镜像导出/导入

**导出：**
```bash
docker save -o mood-music-generator.tar mood-music-generator:latest
```

**导入：**
```bash
docker load -i mood-music-generator.tar
```

## 🔐 生产环境建议

### 1. 资源限制

```yaml
# docker-compose.yml
services:
  mood-music-web:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### 2. 日志管理

```yaml
services:
  mood-music-web:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 3. 自动重启

```yaml
services:
  mood-music-web:
    restart: unless-stopped
```

### 4. 反向代理

推荐使用 Nginx 作为反向代理：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5111;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 🔄 更新部署

```bash
# 1. 停止当前服务
docker compose down

# 2. 拉取最新代码
git pull

# 3. 重新构建镜像
docker build -t mood-music-generator:latest .

# 4. 启动新版本
docker compose up -d

# 5. 清理旧镜像
docker image prune -f
```

## 📝 完整示例

**生产环境 docker-compose.yml：**

```yaml
services:
  mood-music-web:
    image: mood-music-generator:latest
    container_name: mood-music-generator
    ports:
      - "5111:5111"
    environment:
      - PORT=5111
    volumes:
      - ./temp_sessions:/app/temp_sessions
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:5111/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    networks:
      - mood-music-network

networks:
  mood-music-network:
    driver: bridge
```

## 🌐 访问服务

启动成功后，访问：
- **本地**: http://localhost:5111
- **局域网**: http://服务器IP:5111

## 📞 获取帮助

遇到问题？
- 查看日志: `docker compose logs -f`
- 检查状态: `docker compose ps`
- 健康检查: `docker inspect mood-music-generator`
- 提交 Issue: https://github.com/MiniMax-OpenPlatform/mood-music-generator/issues
