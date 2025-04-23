#!/bin/bash

# 脚本出错时退出
set -e

# --- 配置变量 ---
SOURCE_BRANCH="main"          # 你的源代码分支
PAGES_BRANCH="main"       # GitHub Pages 部署分支
PUBLIC_DIR="public"           # Hugo 输出目录
REMOTE_NAME="origin"          # 你的远程仓库名称 (通常是 origin)
COMMIT_MSG_PREFIX="Update site" # 自动生成的 commit 信息前缀

# --- 脚本开始 ---

echo "▶️ Starting deployment..."

# 添加所有新文件并提交
echo "▶️ Committing deployed site..."
git add .
git commit -m "init"

git push $REMOTE_NAME $PAGES_BRANCH

echo "✅ Deployment complete!"
exit 0