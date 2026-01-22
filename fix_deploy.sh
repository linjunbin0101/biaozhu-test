#!/bin/bash

# xclabel部署修复脚本
# 修复Docker构建失败问题

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}xclabel 部署修复脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""

# 检查项目目录
if [ -d "/opt/biaozhu-test" ]; then
    echo -e "${GREEN}1. 检测到项目已存在，进入项目目录...${NC}"
    cd /opt/biaozhu-test
else
    echo -e "${RED}1. 项目目录不存在，请先运行部署脚本！${NC}"
    exit 1
fi

# 修复Dockerfile
echo -e "${GREEN}2. 修复Dockerfile，使用更稳定的Ubuntu 22.04镜像...${NC}"

cat > Dockerfile << 'EOF'
# 使用更稳定的Ubuntu 22.04镜像
FROM ubuntu:22.04

# 设置工作目录
WORKDIR /app

# 更新apt源并安装依赖
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    gcc \
    libc-dev \
    libgl1 \
    libglib2.0-0 \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# 复制requirements.txt到工作目录
COPY requirements.txt .

# 安装Python依赖
RUN pip3 install --no-cache-dir -r requirements.txt

# 复制项目文件到工作目录
COPY . .

# 创建必要的目录
RUN mkdir -p uploads plugins

# 暴露端口
EXPOSE 9924

# 启动命令
CMD ["python3", "app.py"]
EOF

echo -e "${GREEN}3. Dockerfile修复完成！${NC}"

# 停止当前服务
echo -e "${GREEN}4. 停止当前服务...${NC}"
docker-compose down

# 重新构建镜像
echo -e "${GREEN}5. 重新构建镜像...${NC}"
docker-compose build --no-cache

# 启动服务
echo -e "${GREEN}6. 启动服务...${NC}"
docker-compose up -d

# 检查服务状态
echo -e "${GREEN}7. 检查服务状态...${NC}"
echo -e ""
docker-compose ps

echo -e ""
# 检查端口监听
echo -e "${GREEN}8. 检查9924端口监听...${NC}"
if sudo ss -tuln | grep -q "9924"; then
    echo -e "${GREEN}   ✅ 9924端口已成功监听${NC}"
else
    echo -e "${YELLOW}   ⚠️  9924端口未监听，可能服务启动失败${NC}"
fi

echo -e ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}修复完成！${NC}"
echo -e "${GREEN}访问地址：http://$(hostname -I | awk '{print $1}'):9924${NC}"
echo -e "${GREEN}本地访问：http://127.0.0.1:9924${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""

# 查看日志提示
echo -e "${YELLOW}如果服务未启动成功，您可以查看日志了解详情：${NC}"
echo -e "   docker-compose logs -f"
echo -e ""
echo -e "${GREEN}使用愉快！${NC}"
echo -e "${GREEN}=======================================${NC}"