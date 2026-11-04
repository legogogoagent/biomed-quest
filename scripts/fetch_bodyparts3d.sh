#!/usr/bin/env bash
set -euo pipefail

FMA="${1:-}"
DEST="${2:-external/BodyParts3D}"

mkdir -p "$(dirname "$DEST")"

if [[ ! -d "$DEST/.git" ]]; then
  echo "==> 浅克隆 BodyParts3D 元数据（不下载 930 MB 模型）"
  git clone --depth 1 --filter=blob:none --no-checkout \
    https://github.com/Kevin-Mattheus-Moerman/BodyParts3D.git "$DEST"
  cd "$DEST"
  git sparse-checkout init --no-cone
  git sparse-checkout set \
    'README.md' \
    'LICENSE' \
    'LICENSE_content' \
    'src/' \
    'assets/BodyParts3D_data/FMA.csv' \
    'assets/BodyParts3D_data/parts_list_e.txt' \
    'assets/BodyParts3D_data/README_e.html' \
    'assets/BodyParts3D_data/coordinate_system.png'
  git checkout main
else
  cd "$DEST"
fi

if [[ -n "$FMA" ]]; then
  echo "==> 下载单个模型: ${FMA}.stl"
  git sparse-checkout add --no-cone "assets/BodyParts3D_data/stl/${FMA}.stl"
  git checkout main -- "assets/BodyParts3D_data/stl/${FMA}.stl"
  echo "✅ 模型位于: $(pwd)/assets/BodyParts3D_data/stl/${FMA}.stl"
else
  echo "✅ 元数据已就绪: $(pwd)"
  echo "   下载单个模型: ./scripts/fetch_bodyparts3d.sh FMA24474"
fi
