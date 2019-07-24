# ubuntu20.04-repo

## 部署和使用
### 1. 构建和启动

```bash
# 创建目录
mkdir -p /opt/ubuntu-repo
cd /opt/ubuntu-repo

# 创建上述文件...

# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f ubuntu-repo
```

### 2. 监控同步进度

```bash
# 实时查看同步日志
docker exec ubuntu-repo tail -f /repo/logs/sync.log

# 查看仓库大小
docker exec ubuntu-repo du -sh /repo/mirror

# 查看同步状态
docker exec ubuntu-repo ls -la /repo/mirror/
```

### 3. 手动管理

```bash
# 手动触发同步
docker exec ubuntu-repo /usr/local/bin/sync-repo.sh

# 生成统计信息
docker exec ubuntu-repo /usr/local/bin/generate-stats.sh

# 进入容器管理
docker exec -it ubuntu-repo bash
```

## 离线部署方案
### 1. 打包整个仓库

```bash
#!/bin/bash
# 打包脚本: scripts/package-repo.sh

REPO_DIR="/opt/ubuntu-repo"
PACKAGE_NAME="ubuntu-repo-$(date +%Y%m%d).tar.gz"

echo "开始打包Ubuntu仓库..."

# 停止服务
docker-compose down

# 打包数据（排除临时文件）
tar --exclude='*.tmp' \
    --exclude='*.log' \ 
    --exclude='.sync_in_progress' \
    -czf "$PACKAGE_NAME" \
    -C "$REPO_DIR" \
    data/ config/ docker-compose.yml Dockerfile scripts/

echo "打包完成: $PACKAGE_NAME"
echo "大小: $(du -sh $PACKAGE_NAME | cut -f1)"
```

### 2. 离线机器部署脚本

```bash
#!/bin/bash
# 部署脚本: deploy-offline.sh

PACKAGE_FILE="$1"
DEPLOY_DIR="/opt/ubuntu-repo"

if [ -z "$PACKAGE_FILE" ]; then
    echo "使用方法: $0 <ubuntu-repo-package.tar.gz>"
    exit 1
fi

echo "开始离线部署Ubuntu仓库..."

# 创建部署目录
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# 解压仓库包
tar -xzf "$PACKAGE_FILE"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "错误: 需要先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: 需要先安装Docker Compose"
    exit 1
fi

# 构建并启动
docker-compose up -d

echo "部署完成!"
echo "仓库地址: http://localhost:8080"
echo "管理界面: http://localhost:8081"
echo ""
echo "客户端配置:"
echo "sudo tee /etc/apt/sources.list.d/local-repo.list << 'EOF'"
echo "deb http://$(hostname -I | awk '{print $1}'):8080/ubuntu focal main restricted universe multiverse"
echo "deb http://$(hostname -I | awk '{print $1}'):8080/ubuntu focal-updates main restricted universe multiverse"
echo "deb http://$(hostname -I | awk '{print $1}'):8080/ubuntu focal-security main restricted universe multiverse"
echo "EOF"
```
