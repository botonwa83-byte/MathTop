#!/usr/bin/env bash
# 一键发布法律文档到 GitHub Pages（botonwa83-byte/MathTop）
# 用法：./scripts/publish_pages.sh
set -euo pipefail

OWNER=botonwa83-byte
REPO=MathTop
BRANCH=main
DOCS=docs
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== 发布 $DOCS 到 $OWNER/$REPO"
cd "$ROOT"
git add "$DOCS"
if git diff --cached --quiet; then
  echo "docs 无变化，跳过提交"
else
  git commit -m "docs: publish MathTop legal pages"
fi
git push origin HEAD

echo "== 启用 Pages（$BRANCH /docs）"
if gh api -X POST "repos/$OWNER/$REPO/pages" \
     -f "source[branch]=$BRANCH" -f "source[path]=/docs" >/dev/null 2>&1; then
  echo "Pages 已启用"
else
  echo "Pages 可能已启用或需手动开启：https://github.com/$OWNER/$REPO/settings/pages"
fi

echo "== 校验（等待 60s 让 Pages 首次构建完成后再跑一次）"
for f in index privacy terms support; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "https://$OWNER.github.io/$REPO/$f.html")
  echo "  $f.html -> $code"
done
