#!/bin/bash

# xclabel一键部署脚本
# 支持在任何目录执行
# 如果项目存在则先删除再拉取
# 自动更新Docker镜像加速器
# 自动重启Docker服务
# 可选择是否清除缓存并重新构建运行

# 参数说明
# -c, --clean: 清除Docker缓存并使用--no-cache构建
# -h, --help: 显示帮助信息

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认不清除缓存
CLEAN=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            echo -e "${GREEN}xclabel 图像标注工具一键部署脚本${NC}"
            echo -e ""
            echo -e "${YELLOW}Usage:${NC} $0 [OPTIONS]"
            echo -e ""
            echo -e "${YELLOW}Options:${NC}"
            echo -e "  -c, --clean   清除Docker缓存并使用--no-cache构建"
            echo -e "  -h, --help    显示帮助信息"
            echo -e ""
            exit 0
            ;;
        *)
            echo -e "${RED}错误：未知参数 '$1'${NC}"
            echo -e "使用 '$0 --help' 查看帮助信息"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}xclabel 图像标注工具一键部署脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""

# 显示当前模式
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}当前模式：清除缓存并重新构建${NC}"
else
    echo -e "${YELLOW}当前模式：保留缓存构建（推荐）${NC}"
fi
echo -e ""

# 检查是否有sudo权限
if ! sudo -n true 2>/dev/null; then
    echo -e "${RED}错误：您需要具有sudo权限才能运行此脚本${NC}"
    exit 1
fi

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}警告：不建议使用root用户直接运行此脚本${NC}"
    echo -e ""
fi

# 检查并安装Docker
echo -e "${GREEN}1. 检查Docker安装情况...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker未安装，正在安装...${NC}"
    
    # 更新包列表
    sudo apt-get update
    
    # 安装Docker依赖
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # 添加Docker官方GPG密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    # 刷新组权限
    newgrp docker > /dev/null 2>&1
    
    echo -e "${GREEN}Docker安装完成！${NC}"
else
    echo -e "${GREEN}Docker已安装，版本：$(sudo docker --version)${NC}"
fi

# 检查并安装Docker Compose
echo -e ""
echo -e "${GREEN}2. 检查Docker Compose安装情况...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose未安装，正在安装...${NC}"
    
    # 下载Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 赋予执行权限
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo -e "${GREEN}Docker Compose安装完成！${NC}"
else
    echo -e "${GREEN}Docker Compose已安装，版本：$(sudo docker-compose --version)${NC}"
fi

# 检查并安装Git
echo -e ""
echo -e "${GREEN}3. 检查Git安装情况...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git未安装，正在安装...${NC}"
    sudo apt-get update
    sudo apt-get install -y git
    echo -e "${GREEN}Git安装完成！${NC}"
else
    echo -e "${GREEN}Git已安装，版本：$(sudo git --version)${NC}"
fi

# 检查并开放9924端口
echo -e ""
echo -e "${GREEN}4. 检查并开放9924端口...${NC}"

# 检查ufw是否安装
if command -v ufw &> /dev/null; then
    echo -e "${GREEN}   4.1 检测到ufw已安装，检查9924端口状态...${NC}"
    
    # 检查ufw是否启用
    if sudo ufw status | grep -q "Status: active"; then
        # 检查9924端口是否已开放
        if ! sudo ufw status | grep -q "9924"; then
            echo -e "${YELLOW}   4.2 9924端口未开放，正在开放...${NC}"
            sudo ufw allow 9924/tcp
            echo -e "${GREEN}   4.3 9924端口已成功开放${NC}"
        else
            echo -e "${GREEN}   4.2 9924端口已开放${NC}"
        fi
    else
        echo -e "${YELLOW}   4.1 ufw已安装但未启用，跳过端口开放步骤${NC}"
    fi
else
    echo -e "${YELLOW}   4.1 ufw未安装，跳过端口开放步骤${NC}"
fi

# 更新/etc/docker/daemon.json
echo -e ""
echo -e "${GREEN}5. 更新Docker镜像加速器配置...${NC}"

# 备份原有配置
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak 2>/dev/null || echo -e "${YELLOW}原有配置文件不存在，将创建新配置文件...${NC}"

# 更新daemon.json配置
echo '{"registry-mirrors": ["https://docker.m.daocloud.io"]}' | sudo tee /etc/docker/daemon.json > /dev/null

echo -e "${GREEN}6. 重启Docker服务...${NC}"
sudo systemctl daemon-reload
sudo systemctl restart docker

# 等待Docker服务重启
sleep 5

# 部署xclabel
echo -e ""
echo -e "${GREEN}7. 部署xclabel...${NC}"

# 如果项目已存在，先删除
if [ -d "/opt/biaozhu-test" ]; then
    echo -e "${YELLOW}检测到项目已存在，正在删除...${NC}"
    
    # 停止并删除容器
    if sudo docker-compose -f /opt/biaozhu-test/docker-compose.yml ps -q > /dev/null 2>&1; then
        sudo docker-compose -f /opt/biaozhu-test/docker-compose.yml down -v
    fi
    
    # 删除项目目录
    sudo rm -rf /opt/biaozhu-test
fi

# 重新克隆代码
echo -e "${GREEN}8. 克隆代码到/opt/目录...${NC}"
sudo mkdir -p /opt/biaozhu-test
sudo chown -R $USER:$USER /opt/biaozhu-test
sudo git clone https://github.com/linjunbin0101/biaozhu-test.git /opt/biaozhu-test

# 进入项目目录
cd /opt/biaozhu-test || exit 1

echo -e "${GREEN}9. 修复app.py，添加allow_unsafe_werkzeug=True参数...${NC}"
# 修改app.py文件，添加allow_unsafe_werkzeug=True参数
sudo sed -i 's/socketio.run(app, debug=args.debug, host=args.host, port=args.port)/socketio.run(app, debug=args.debug, host=args.host, port=args.port, allow_unsafe_werkzeug=True)/g' app.py

echo -e "${GREEN}10. 优化Dockerfile，使用更稳定的Python Bullseye镜像...${NC}"
# 使用更稳定的Python Bullseye镜像重写Dockerfile
sudo cat > Dockerfile << 'EOF'
# 使用官方Python镜像作为基础镜像 (Debian Bullseye, 更稳定)
FROM python:3.10-slim-bullseye

# 设置工作目录
WORKDIR /app

# 配置apt源
RUN echo "deb http://deb.debian.org/debian bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list

# 安装系统依赖
RUN set -eux; \
    apt update -y --fix-missing && \
    apt install -y --no-install-recommends --fix-missing \
    gcc \
    libc-dev \
    libgl1 \
    libglib2.0-0 \
    && apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# 清理Docker缓存（可选）
if [ "$CLEAN" = true ]; then
    echo -e "${GREEN}11. 清除Docker缓存...${NC}"
    sudo docker system prune -f
    sudo docker volume prune -f
    sudo docker network prune -f
    sudo docker image prune -f
    echo -e "${GREEN}12. 重新构建镜像（无缓存）...${NC}"
    sudo docker-compose build --no-cache
else
    echo -e "${GREEN}11. 清理未使用的Docker镜像...${NC}"
    sudo docker image prune -f
    echo -e "${GREEN}12. 重新构建镜像（使用缓存）...${NC}"
    sudo docker-compose build
fi

echo -e "${GREEN}13. 启动服务...${NC}"
sudo docker-compose up -d

echo -e "${GREEN}部署完成！${NC}"

echo -e ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}部署成功！${NC}"
echo -e "${GREEN}访问地址：http://$(hostname -I | awk '{print $1}'):9924${NC}"
echo -e "${GREEN}本地访问：http://127.0.0.1:9924${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""
echo -e "${YELLOW}注意事项：${NC}"
echo -e "   1. 首次访问可能需要等待30秒左右，Docker正在下载依赖${NC}"
echo -e "   2. 如无法访问，请检查防火墙设置，确保9924端口已开放${NC}"
echo -e "   3. 后续更新可再次运行此脚本${NC}"
echo -e ""
echo -e "${GREEN}使用愉快！${NC}"
echo -e "${GREEN}=======================================${NC}"
