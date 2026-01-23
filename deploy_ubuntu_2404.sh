#!/bin/bash

# xclabel Ubuntu 24.04 专用部署脚本
# 使用固定的Dockerfile，避免从GitHub拉取旧版本
# 支持首次部署和更新

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}xclabel Ubuntu 24.04 专用部署脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""

# 项目目录
PROJECT_DIR="/opt/xclabel"

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}警告：不建议使用root用户直接运行此脚本${NC}"
    echo -e ""
fi

# 检查项目目录是否存在
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${GREEN}1. 检测到项目已存在，进入更新模式...${NC}"
    cd "$PROJECT_DIR"
    
    # 停止当前服务
    echo -e "${GREEN}   1.1 停止当前服务...${NC}"
    docker compose down
    
    # 更新代码
    echo -e "${GREEN}   1.2 更新代码...${NC}"
    git pull || echo -e "${YELLOW}   ⚠️  git pull失败，使用本地代码继续${NC}"
else
    echo -e "${GREEN}1. 检测到项目不存在，进入首次部署模式...${NC}"
    
    # 创建项目目录
    echo -e "${GREEN}   1.1 创建项目目录...${NC}"
    sudo mkdir -p "$PROJECT_DIR"
    sudo chown -R "$USER:$USER" "$PROJECT_DIR"
    
    # 克隆代码
    echo -e "${GREEN}   1.2 克隆代码...${NC}"
    git clone https://gitee.com/Vanishi/xclabel.git "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# 使用固定的可靠Dockerfile
cat > Dockerfile << 'EOF'
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
    \
    # 重试机制：最多尝试3次apt update
    for i in {1..3}; do \
        if apt update -y --fix-missing; then \
            break; \
        fi; \
        if [ $i -eq 3 ]; then \
            echo 'Failed to update apt after 3 attempts'; \
            exit 1; \
        fi; \
        echo 'Retrying apt update...'; \
        sleep 2; \
    done; \
    \
    # 重试机制：最多尝试3次apt install
    for i in {1..3}; do \
        if apt install -y --no-install-recommends --fix-missing \
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
        echo 'Retrying apt install...'; \
        sleep 2; \
    done; \
    \
    # 清理apt缓存和临时文件，减少镜像大小
    apt clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
EOF

echo -e "${GREEN}2. Dockerfile已更新为稳定版本${NC}"

# 修复docker-compose.yml中的version警告
if grep -q "version:" docker-compose.yml; then
    echo -e "${GREEN}3. 修复docker-compose.yml中的version警告...${NC}"
    sed -i '/version:/d' docker-compose.yml
fi

# 构建镜像
echo -e "${GREEN}4. 构建Docker镜像...${NC}"
docker compose build --no-cache

# 启动服务
echo -e "${GREEN}5. 启动服务...${NC}"
docker compose up -d

# 检查服务状态
echo -e "${GREEN}6. 检查服务状态...${NC}"
echo -e ""
docker compose ps

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}访问地址：http://$SERVER_IP:9924${NC}"
echo -e "${GREEN}本地访问：http://127.0.0.1:9924${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""
echo -e "${YELLOW}注意事项：${NC}"
echo -e "   1. 首次访问可能需要等待几秒钟${NC}"
echo -e "   2. 如无法访问，请检查防火墙设置${NC}"
echo -e "   3. 查看日志：docker compose logs -f${NC}"
echo -e ""
echo -e "${GREEN}使用愉快！${NC}"
echo -e "${GREEN}=======================================${NC}"