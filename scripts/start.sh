#!/bin/bash
# scripts/start.sh

set -e

REPO_BASE="/repo"
MIRROR_DIR="$REPO_BASE/mirror"
CONFIG_DIR="$REPO_BASE/config"
LOG_DIR="$REPO_BASE/logs"

echo "=== Ubuntu Repository Server Starting ==="

# 创建必要目录
mkdir -p "$MIRROR_DIR" "$LOG_DIR"
chown -R www-data:www-data "$MIRROR_DIR"

# 复制配置文件
if [ -f "$CONFIG_DIR/mirror.list" ]; then
    cp "$CONFIG_DIR/mirror.list" /etc/apt/mirror.list
else
    echo "警告: 未找到 mirror.list 配置文件"
fi

# 启动 Apache
service apache2 start

# 检查是否需要初始化
if [ ! -f "$MIRROR_DIR/.sync_completed" ] && [ ! -f "$MIRROR_DIR/.sync_in_progress" ]; then
    echo "开始首次同步软件仓库..."

    # 后台同步
    nohup /usr/local/bin/sync-repo.sh > "$LOG_DIR/sync.log" 2>&1 &

    echo "仓库同步已在后台启动"
    echo "同步进度: docker exec <container> tail -f /repo/logs/sync.log"
fi

# 设置定时同步
echo "0 2 * * * root /usr/local/bin/sync-repo.sh >> $LOG_DIR/sync.log 2>&1" > /etc/cron.d/repo-sync
service cron start

echo "服务启动完成"
echo "仓库地址: http://localhost:端口"
echo "查看状态: http://localhost:端口/repo-status"

# 保持容器运行
exec tail -f "$LOG_DIR/apache_access.log" "$LOG_DIR/sync.log"
