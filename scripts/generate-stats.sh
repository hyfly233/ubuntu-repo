#!/bin/bash
# scripts/generate-stats.sh

REPO_BASE="/repo"
MIRROR_DIR="$REPO_BASE/mirror"

echo "生成仓库统计信息..."

# 统计信息
TOTAL_SIZE=$(du -sh "$MIRROR_DIR" 2>/dev/null | cut -f1)
TOTAL_FILES=$(find "$MIRROR_DIR" -type f | wc -l)
DEB_COUNT=$(find "$MIRROR_DIR" -name "*.deb" | wc -l)
LAST_SYNC=$(stat -c %y "$MIRROR_DIR/.sync_completed" 2>/dev/null || echo "未知")

# 生成HTML状态页面
cat > "$MIRROR_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Ubuntu Repository Status</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .stats { background: #f5f5f5; padding: 20px; border-radius: 5px; }
        .stats h2 { margin-top: 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Ubuntu Software Repository</h1>

    <div class="stats">
        <h2>Repository Statistics</h2>
        <table>
            <tr><th>Item</th><th>Value</th></tr>
            <tr><td>Total Size</td><td>$TOTAL_SIZE</td></tr>
            <tr><td>Total Files</td><td>$TOTAL_FILES</td></tr>
            <tr><td>DEB Packages</td><td>$DEB_COUNT</td></tr>
            <tr><td>Last Sync</td><td>$LAST_SYNC</td></tr>
        </table>
    </div>

    <h2>Available Distributions</h2>
    <ul>
EOF

# 添加可用发行版
find "$MIRROR_DIR" -name "dists" -type d | while read dist_dir; do
    find "$dist_dir" -maxdepth 1 -type d | while read release_dir; do
        release=$(basename "$release_dir")
        if [ "$release" != "dists" ]; then
            echo "        <li><a href=\"$(realpath --relative-to="$MIRROR_DIR" "$release_dir")\">$release</a></li>" >> "$MIRROR_DIR/index.html"
        fi
    done
done

cat >> "$MIRROR_DIR/index.html" << EOF
    </ul>

    <p><a href="/repo-status">Server Status</a></p>
    <p><em>Generated: $(date)</em></p>
</body>
</html>
EOF

echo "统计信息生成完成"
