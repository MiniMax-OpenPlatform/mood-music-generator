# 使用官方 Python 运行时作为基础镜像
FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量和代理（构建时使用）
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=5111 \
    http_proxy=http://pac-internal.xaminim.com:3129 \
    https_proxy=http://pac-internal.xaminim.com:3129

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY main.py .
COPY templates ./templates
COPY static ./static

# 创建临时文件目录
RUN mkdir -p temp_sessions

# 清除构建时的代理环境变量（运行时不需要）
ENV http_proxy="" \
    https_proxy=""

# 暴露端口
EXPOSE 5111

# 健康检查（使用 Python 检查，不依赖 curl）
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5111/health')" || exit 1

# 启动应用
CMD ["python", "main.py"]
