#!/bin/bash

# xclabel一键部署脚本
# 支持首次部署和后续更新
# 自动处理Docker和Docker Compose安装
# 自动处理权限问题

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}xclabel 图像标注工具一键部署脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e ""

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
    echo -e "${GREEN}Docker已安装，版本：$(docker --version)${NC}"
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
    echo -e "${GREEN}Docker Compose已安装，版本：$(docker-compose --version)${NC}"
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
    echo -e "${GREEN}Git已安装，版本：$(git --version)${NC}"
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

# 部署或更新xclabel
echo -e ""
echo -e "${GREEN}5. 部署/更新xclabel...${NC}"

if [ -d "/opt/biaozhu-test" ]; then
    echo -e "${YELLOW}检测到项目已存在，正在更新...${NC}"
    
    cd /opt/biaozhu-test || exit 1
    
    echo -e "${GREEN}   4.1 停止当前服务...${NC}"
    docker-compose down
    
    echo -e "${GREEN}   4.2 拉取最新代码...${NC}"
    git pull
    
    echo -e "${GREEN}   4.3 修复Dockerfile中的依赖问题...${NC}"
    # 修复libgl1-mesa-glx依赖问题，替换为libgl1
    sed -i 's/libgl1-mesa-glx/libgl1/g' Dockerfile
    
    echo -e "${GREEN}   4.4 重新构建镜像...${NC}"
    docker-compose build --no-cache
    
    echo -e "${GREEN}   4.5 启动服务...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}更新完成！${NC}"
else
    echo -e "${YELLOW}检测到项目不存在，正在部署...${NC}"
    
    echo -e "${GREEN}   4.1 创建项目目录...${NC}"
    sudo mkdir -p /opt/biaozhu-test
    sudo chown -R $USER:$USER /opt/biaozhu-test
    
    echo -e "${GREEN}   4.2 克隆代码...${NC}"
    git clone https://github.com/linjunbin0101/biaozhu-test.git /opt/biaozhu-test
    
    echo -e "${GREEN}   4.3 修复Dockerfile中的依赖问题...${NC}"
    cd /opt/biaozhu-test || exit 1
    # 修复libgl1-mesa-glx依赖问题，替换为libgl1
    sed -i 's/libgl1-mesa-glx/libgl1/g' Dockerfile
    
    echo -e "${GREEN}   4.4 启动服务...${NC}"
    docker-compose up -d
    
    echo -e "${GREEN}部署完成！${NC}"
fi

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