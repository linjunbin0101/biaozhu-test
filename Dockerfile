# 使用官方Python镜像作为基础镜像 (Debian Bookworm, 更稳定)
FROM python:3.10-slim-bookworm

# 设置工作目录
WORKDIR /app

# 配置apt源为国内镜像以提高下载速度和可靠性
RUN echo "deb http://deb.debian.org/debian bookworm main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list

# 安装系统依赖，添加--fix-missing和--allow-unauthenticated选项处理可能的问题
RUN apt-get update -y --fix-missing && \
    apt-get install -y --no-install-recommends --fix-missing \
    gcc \
    libc-dev \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

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