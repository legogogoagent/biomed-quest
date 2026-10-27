#!/usr/bin/env bash
set -euo pipefail

if command -v mamba >/dev/null 2>&1; then
  echo "==> 使用 mamba 创建 biomedcraft 环境"
  mamba create -y -n biomedcraft -c conda-forge \
    r-base r-tidyverse r-pheatmap r-here r-janitor r-skimr r-renv quarto
  mamba run -n biomedcraft Rscript -e 'install.packages("quarto", repos="https://cloud.r-project.org")'
  mamba run -n biomedcraft Rscript -e 'if (!file.exists("renv.lock")) renv::init(restart = FALSE)'
  mamba run -n biomedcraft Rscript -e 'renv::snapshot()'
  echo "✅ 已创建环境。下一步：conda activate biomedcraft && Rscript 00_setup/verify_environment.R"
  exit 0
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "❌ 没有 sudo，也没有 mamba/conda。请安装 mamba 或手动安装 R/Quarto。"
  exit 1
fi

echo "==> 安装 R、Git、curl"
sudo apt-get update
sudo apt-get install -y r-base r-base-dev git curl

echo "==> 安装最新版 Quarto"
QUARTO_URL=$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest \
  | grep -o 'https://[^"]*linux-amd64.deb' | head -n 1)
if [[ -z "${QUARTO_URL}" ]]; then
  echo "❌ 没能找到 Quarto 的 .deb 下载地址，请手动安装：https://quarto.org/docs/get-started/"
  exit 1
fi
curl -fL -o /tmp/quarto.deb "$QUARTO_URL"
sudo dpkg -i /tmp/quarto.deb

echo "==> 安装 R 包"
Rscript -e 'install.packages(c("renv","tidyverse","pheatmap","here","janitor","skimr","quarto"), repos="https://cloud.r-project.org")'

echo "==> 初始化 renv"
Rscript -e 'if (!file.exists("renv.lock")) renv::init(restart = FALSE)'
Rscript -e 'renv::snapshot()'

echo "✅ Linux 环境安装完成。下一步：Rscript 00_setup/verify_environment.R"
