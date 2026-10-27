# 🛠️ 00_setup：进入世界之前

目标：在 macOS 或 Linux 上安装 R、Quarto、Git，安装 R 包，初始化 `renv`，完成第一次 commit。

## 1. 安装

### macOS

```bash
brew install r quarto git
brew install --cask rstudio
```

如果没有 Homebrew，先按 https://brew.sh 安装。

### Linux（Ubuntu/Debian）

有 `mamba` 或 `conda` 时，推荐用独立环境，避免污染系统：

```bash
mamba create -y -n biomedcraft -c conda-forge \
  r-base r-tidyverse r-pheatmap r-here r-janitor r-skimr r-renv quarto
mamba run -n biomedcraft Rscript -e 'install.packages("quarto", repos="https://cloud.r-project.org")'
```

没有 `mamba` 且有 `sudo` 时：

```bash
sudo apt-get update
sudo apt-get install -y r-base r-base-dev git curl
QUARTO_URL=$(curl -fsSL https://api.github.com/repos/quarto-dev/quarto-cli/releases/latest \
  | grep -o 'https://[^"]*linux-amd64.deb' | head -n 1)
curl -fL -o /tmp/quarto.deb "$QUARTO_URL"
sudo dpkg -i /tmp/quarto.deb
```

### 一键脚本

```bash
bash 00_setup/install_macos.sh
# 或
bash 00_setup/install_linux.sh
```

## 2. 安装 R 包

```bash
Rscript -e 'install.packages(c("renv","tidyverse","pheatmap","here","janitor","skimr","quarto"), repos="https://cloud.r-project.org")'
```

## 3. 初始化 renv

```bash
Rscript -e 'renv::init(restart = FALSE)'
Rscript -e 'renv::snapshot()'
```

成功后仓库根目录会出现 `renv.lock`、`renv/`、`.Rprofile`。

## 4. 检查环境

```bash
Rscript 00_setup/verify_environment.R
```

期望：每行都是 ✅，最后输出“环境检查通过”。

## 5. 第一次 commit

```bash
git add .Rprofile renv.lock renv
git commit -m "chore: initialize renv"
```

## 常见问题

- `Rscript: command not found`：R 没装好，或 PATH 没更新。macOS 用 `brew doctor`；Linux 用 `which R` 检查。
- `quarto: command not found`：重新安装 Quarto，确认 `/usr/local/bin` 或 conda 环境在 PATH 中。
- `renv::init()` 卡住：先确认能访问 CRAN；公司/学校网络可能需要配置代理。
- Linux 没有 sudo：用 mamba/conda 方案，不要强行 `sudo`。
