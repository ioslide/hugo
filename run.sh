#!/bin/bash

# 脚本出错时退出
set -e

# --- 配置变量 ---
SOURCE_BRANCH="main"          # 你的源代码分支
PAGES_BRANCH="gh-pages"       # GitHub Pages 部署分支
PUBLIC_DIR="public"           # Hugo 输出目录
REMOTE_NAME="origin"          # 你的远程仓库名称 (通常是 origin)
COMMIT_MSG_PREFIX="Update site" # 自动生成的 commit 信息前缀

# --- 脚本开始 ---

echo "▶️ Starting deployment..."

# 1. 获取用户提交信息 (可选, 否则使用默认信息)
MSG="$1"
if [ -z "$MSG" ]; then
  read -p "Enter commit message (or press Enter for default): " MSG
  if [ -z "$MSG" ]; then
    MSG="$COMMIT_MSG_PREFIX on $(date +'%Y-%m-%d %H:%M:%S')"
  fi
fi

# 2. 确保在源代码分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$SOURCE_BRANCH" ]; then
  echo "❌ Error: Not on source branch '$SOURCE_BRANCH'. Current branch is '$CURRENT_BRANCH'."
  echo "Please switch to '$SOURCE_BRANCH' branch first."
  exit 1
fi

echo "▶️ Committing source code changes on branch '$SOURCE_BRANCH'..."
# 添加所有更改 (确保 .gitignore 配置正确)
git add .
# 提交更改
git commit -m "$MSG" || { echo "ℹ️ Nothing to commit in source branch. Proceeding..."; }
# 推送源代码
echo "▶️ Pushing source code to $REMOTE_NAME/$SOURCE_BRANCH..."
git push $REMOTE_NAME $SOURCE_BRANCH

# 记录当前源代码提交的 hash，用于 Pages 部署信息
SOURCE_COMMIT_HASH=$(git rev-parse HEAD)

# 3. 构建 Hugo 站点
echo "▶️ Building Hugo site into '$PUBLIC_DIR' directory..."
hugo # 或者 hugo --minify 如果你想压缩输出

# 4. 部署到 GitHub Pages 分支
echo "▶️ Deploying to $REMOTE_NAME/$PAGES_BRANCH..."

# 检查 gh-pages 分支是否存在，不存在则创建孤儿分支
if git show-ref --quiet refs/heads/$PAGES_BRANCH; then
  git checkout $PAGES_BRANCH
else
  echo "ℹ️ Creating orphan branch '$PAGES_BRANCH'..."
  git checkout --orphan $PAGES_BRANCH
  git reset --hard
  git commit --allow-empty -m "Initial commit for $PAGES_BRANCH branch"
  git push $REMOTE_NAME $PAGES_BRANCH # 推送空分支以在远程创建
  git checkout $SOURCE_BRANCH # 切回源分支再切过去，确保跟踪设置正确
  git checkout $PAGES_BRANCH
fi

# 确保在 gh-pages 分支
if [ "$(git rev-parse --abbrev-ref HEAD)" != "$PAGES_BRANCH" ]; then
    echo "❌ Error: Failed to switch to '$PAGES_BRANCH'. Aborting."
    exit 1
fi

# 清理旧文件 (除了 .git 目录)
echo "▶️ Cleaning old site files from '$PAGES_BRANCH'..."
git ls-files | grep -vE '^(\.git/|\.gitignore)$' | xargs --no-run-if-empty git rm -rf --ignore-unmatch

# 从 public 目录复制新文件
echo "▶️ Copying new site files from '$PUBLIC_DIR'..."
# 使用 rsync 更安全高效，--delete 会删除目标目录中源目录没有的文件
# --exclude '.git/' 避免尝试删除 .git 目录
rsync -av --delete --exclude '.git/' "$PUBLIC_DIR/" .

# 添加 .nojekyll 文件 (告诉 GitHub Pages 不要尝试用 Jekyll 处理)
touch .nojekyll

# 添加所有新文件并提交
echo "▶️ Committing deployed site..."
git add .
git commit -m "Deploy site from $SOURCE_BRANCH@${SOURCE_COMMIT_HASH:0:7}" -m "$MSG"

# 推送 Pages 分支
echo "▶️ Pushing deployment to $REMOTE_NAME/$PAGES_BRANCH..."
git push $REMOTE_NAME $PAGES_BRANCH

# 切换回原来的源代码分支
echo "▶️ Switching back to branch '$SOURCE_BRANCH'..."
git checkout $SOURCE_BRANCH

echo "✅ Deployment complete!"
echo "   Source pushed to: $REMOTE_NAME/$SOURCE_BRANCH"
echo "   Site deployed to: $REMOTE_NAME/$PAGES_BRANCH"
echo "   Your GitHub Pages site should update shortly."

exit 0