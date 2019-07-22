#!/bin/bash
# scripts/sync-repo.sh

REPO_BASE="/repo"
MIRROR_DIR="$REPO_BASE/mirror"
LOG_DIR="$REPO_BASE/logs"

echo "$(date): 开始同步仓库..."

# 检查是否已在同步
if [ -f "$MIRROR_DIR/.sync_in_progress" ]; then
    echo "同步已在进行中，跳过此次同步"
    exit 0
fi

# 创建同步标志
touch "$MIRROR_DIR/.sync_in_progress"

# 执行同步
apt-mirror /etc/apt/mirror.list

# 同步完成处理
if [ $? -eq 0 ]; then
    echo "$(date): 仓库同步完成"
    touch "$MIRROR_DIR/.sync_completed"

    # 更新权限
    chown -R www-data:www-data "$MIRROR_DIR"

    # 生成统计信息
    /usr/local/bin/generate-stats.sh
else
    echo "$(date): 仓库同步失败"
fi

# 移除同步标志
rm -f "$MIRROR_DIR/.sync_in_progress"
