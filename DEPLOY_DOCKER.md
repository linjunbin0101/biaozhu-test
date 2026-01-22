# xclabel Docker部署指南

本指南将指导您如何在Ubuntu服务器上使用Docker和Docker Compose一键部署xclabel图像标注工具。

## 🚀 快速开始

### 一键部署（推荐）

如果您的服务器已安装Docker和Docker Compose，只需运行以下**单条命令**即可完成部署：

```bash
# 拉取代码到/opt路径并部署（一键完成）
git clone https://github.com/linjunbin0101/biaozhu-test.git /opt/biaozhu-test && cd /opt/biaozhu-test && docker-compose up -d
```

服务启动后，访问：`http://服务器IP:9924`

## 前提条件

在开始部署之前，请确保您的Ubuntu服务器满足以下条件：

1. **Ubuntu 20.04+**：推荐使用Ubuntu 22.04 LTS
2. **Docker**：已安装Docker 20.10+版本
3. **Docker Compose**：已安装Docker Compose 1.29+版本
4. **网络访问**：服务器需开放9924端口，或您计划使用的自定义端口
5. **Git**：用于克隆仓库

## 🔧 安装Docker和Docker Compose

如果您的服务器尚未安装Docker和Docker Compose，请按照以下步骤安装：

### 安装Docker

```bash
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

# 验证Docker安装
 sudo docker --version

# 将当前用户添加到docker组（可选，避免每次使用sudo）
 sudo usermod -aG docker $USER
 newgrp docker
```

### 安装Docker Compose

```bash
# 下载Docker Compose
 sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# 赋予执行权限
 sudo chmod +x /usr/local/bin/docker-compose

# 验证Docker Compose安装
 docker-compose --version
```

## 部署步骤

### 方法1：克隆仓库部署（推荐）

1. **克隆仓库**

```bash
# 克隆仓库到本地
 git clone https://gitee.com/Vanishi/xclabel.git
 cd xclabel
```

2. **启动服务**

```bash
# 使用Docker Compose启动服务
 docker-compose up -d
```

### 方法2：手动下载部署

1. **创建项目目录**

```bash
 mkdir -p ~/xclabel
 cd ~/xclabel
```

2. **下载项目文件**

```bash
# 下载必要的项目文件
 curl -O https://gitee.com/Vanishi/xclabel/raw/master/Dockerfile
 curl -O https://gitee.com/Vanishi/xclabel/raw/master/docker-compose.yml
 curl -O https://gitee.com/Vanishi/xclabel/raw/master/requirements.txt
 curl -O https://gitee.com/Vanishi/xclabel/raw/master/app.py
 curl -O https://gitee.com/Vanishi/xclabel/raw/master/AiUtils.py

# 下载目录结构
 git clone --depth=1 --filter=blob:none --no-checkout https://gitee.com/Vanishi/xclabel.git .
 git checkout master -- static/ templates/
```

3. **启动服务**

```bash
# 使用Docker Compose启动服务
 docker-compose up -d
```

## 访问服务

服务启动后，您可以通过以下方式访问xclabel：

- **本地访问**：`http://127.0.0.1:9924`
- **远程访问**：`http://服务器IP:9924`

## 常用命令

### 启动服务

```bash
docker-compose up -d
```

### 停止服务

```bash
docker-compose down
```

### 查看服务状态

```bash
docker-compose ps
```

### 查看服务日志

```bash
# 查看实时日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f xclabel

# 查看最近100行日志
docker-compose logs --tail=100 xclabel
```

### 重启服务

```bash
docker-compose restart
```

### 构建/重新构建镜像

```bash
# 构建镜像
docker-compose build

# 重新构建镜像（不使用缓存）
docker-compose build --no-cache
```

## 目录结构说明

部署后，项目目录结构如下：

```
/opt/biaozhu-test/
├── uploads/          # 上传的图片和视频存储目录（持久化）
├── plugins/          # 插件目录，用于YOLO11安装（持久化）
├── static/           # 静态资源目录
├── templates/        # HTML模板目录
├── app.py            # 主应用文件
├── AiUtils.py        # AI自动标注工具类
├── Dockerfile        # Docker构建文件
├── docker-compose.yml # Docker Compose配置文件
└── requirements.txt  # Python依赖列表
```

**持久化目录说明**：
- `uploads/`：保存用户上传的图片和视频，数据会持久化到宿主机
- `plugins/`：保存YOLO11相关插件和模型，数据会持久化到宿主机
- `static/`：静态资源目录，包含CSS、JavaScript和图片资源

## 自定义配置

### 修改端口

如果您需要使用自定义端口，可以修改`docker-compose.yml`文件中的端口映射：

```yaml
ports:
  - "自定义端口:9924"
```

例如，将端口改为8080：

```yaml
ports:
  - "8080:9924"
```

修改后，需要重启服务：

```bash
docker-compose down
docker-compose up -d
```

### 修改时区

默认时区为Asia/Shanghai（上海），如果您需要修改时区，可以修改`docker-compose.yml`文件中的TZ环境变量：

```yaml
environment:
  - TZ=您的时区
```

例如，改为UTC时区：

```yaml
environment:
  - TZ=UTC
```

## 升级服务

当项目有新版本发布时，您可以按照以下步骤升级服务：

1. **更新代码**

```bash
# 进入项目目录
cd /opt/biaozhu-test

# 拉取最新代码
git pull
```

2. **重新构建并启动服务**

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 故障排除

### 服务无法启动

1. **查看日志**

```bash
docker-compose logs -f
```

2. **检查端口占用**

```bash
# 检查9924端口是否被占用
sudo lsof -i :9924
# 或使用netstat
sudo netstat -tuln | grep 9924
```

3. **检查Docker服务状态**

```bash
sudo systemctl status docker
```

### 访问时出现502错误

- 检查服务是否正在运行：`docker-compose ps`
- 检查容器日志：`docker-compose logs -f xclabel`
- 检查端口映射是否正确

### 上传文件失败

- 检查宿主机`uploads/`目录权限：`ls -la uploads/`
- 确保Docker容器有写入权限

## 安全建议

1. **定期更新镜像**：定期拉取最新代码并重新构建镜像，以获取最新的安全补丁
2. **使用HTTPS**：在生产环境中，建议使用Nginx或Apache作为反向代理，并配置HTTPS
3. **限制访问IP**：如果可能，限制只有特定IP可以访问服务
4. **定期备份数据**：定期备份`uploads/`和`plugins/`目录，以防止数据丢失
5. **使用强密码**：如果服务有认证功能，使用强密码

## 反向代理配置（可选）

如果您希望使用域名访问服务，并配置HTTPS，可以使用Nginx作为反向代理。以下是一个简单的Nginx配置示例：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 重定向HTTP到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL配置
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;

    # 代理配置
    location / {
        proxy_pass http://127.0.0.1:9924;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 常见问题

### Q: 如何查看容器内部情况？

A: 您可以使用以下命令进入容器：

```bash
docker exec -it xclabel /bin/bash
```

### Q: 如何修改配置文件？

A: 直接修改宿主机上的配置文件，修改后重启服务即可：

```bash
docker-compose restart
```

### Q: 如何清理未使用的Docker资源？

A: 您可以使用以下命令清理未使用的Docker资源：

```bash
docker system prune -f
```

## 技术支持

如果您在部署过程中遇到问题，可以通过以下方式获取技术支持：

- 项目GitHub地址：https://github.com/beixiaocai/xclabel
- 项目Gitee地址：https://gitee.com/Vanishi/xclabel
- 作者主页：https://www.yuturuishi.com

## 许可证

本项目采用MIT许可证，详细信息请查看LICENSE文件。

## 贡献

欢迎提交Issue和Pull Request，共同改进xclabel项目！

---

感谢您使用xclabel图像标注工具！祝您使用愉快！