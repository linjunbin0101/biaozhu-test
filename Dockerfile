# 使用官方Python镜像作为基础镜像 (Debian Bookworm, 更稳定)
FROM python:3.10-slim-bookworm

# 设置工作目录
WORKDIR /app

# 安装系统依赖 - 使用重试机制和完整错误处理
RUN set -eux; \
    # 配置可靠的apt源
    echo 'deb http://deb.debian.org/debian bookworm main contrib non-free' > /etc/apt/sources.list; \
    echo 'deb http://deb.debian.org/debian bookworm-updates main contrib non-free' >> /etc/apt/sources.list; \
    echo 'deb http://deb.debian.org/debian-security bookworm-security main contrib non-free' >> /etc/apt/sources.list; \
    
    # 重试机制：最多尝试3次apt-get update
    for i in {1..3}; do \
        if apt-get update -y --fix-missing; then \
            break; \
        fi; \
        if [ $i -eq 3 ]; then \
            echo 'Failed to update apt after 3 attempts'; \
            exit 1; \
        fi; \
        echo 'Retrying apt-get update...'; \
        sleep 2; \
    done; \
    
    # 重试机制：最多尝试3次apt-get install
    for i in {1..3}; do \
        if apt-get install -y --no-install-recommends --fix-missing \
            gcc \
            libc-dev \
            libgl1 \
            libglib2.0-0; then \
            break; \
        fi; \
        if [ $i -eq 3 ]; then \
            echo 'Failed to install packages after 3 attempts'; \
            exit 1; \
        fi; \
        echo 'Retrying apt-get install...'; \
        sleep 2; \
    done; \
    
    # 清理apt缓存
    rm -rf /var/lib/apt/lists/*

# 复制requirements.txt到工作目录
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目文件到工作目录
COPY . .

# 创建必要的目录
RUN mkdir -p uploads plugins

# 暴露端口
EXPOSE 9924

# 启动命令
CMD ["python", "app.py"]