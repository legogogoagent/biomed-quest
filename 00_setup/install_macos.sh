#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "❌ 未找到 Homebrew。请先安装：https://brew.sh"
  exit 1
fi

echo "==> 安装 R、Quarto、Git"
brew install r quarto git

echo "==> 安装 RStudio（可选，已安装会跳过）"
brew install --cask rstudio || true

echo "==> 安装 R 包"
Rscript -e 'install.packages(c("renv","tidyverse","pheatmap","here","janitor","skimr","quarto"), repos="https://cloud.r-project.org")'

echo "==> 初始化 renv"
Rscript -e 'if (!file.exists("renv.lock")) renv::init(restart = FALSE)'
Rscript -e 'renv::snapshot()'

echo "✅ macOS 环境安装完成。下一步：Rscript 00_setup/verify_environment.R"
