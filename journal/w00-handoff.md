# Release 0 Handoff

## 已完成

- 公开学习库骨架
- Minecraft 风 README、地图、进度
- macOS/Linux 安装与环境检查
- W0 终点预览（airway 风格合成数据）
- L1 新手村与参考解
- 模板与 6 枚徽章
- 公开作品集骨架

## 验证结果

- `bash scripts/validate_release0.sh`：42 项通过，0 失败。
- `Rscript 00_setup/verify_environment.R`：10 项通过，0 失败。
- W0：PCA 6 个样本，差异表达 40 个基因，其中 8 个 `padj < 0.05`，热图 15 个基因。
- L1：起点代码自检失败并给出提示；参考解通过自检；生成物已清理。
- `renv.lock` 已记录 143 个包。

## 本机环境备注

当前 Linux 环境通过 mamba 安装：

```bash
mamba activate biomedcraft
# 或
mamba run -n biomedcraft Rscript ...
mamba run -n biomedcraft quarto render 00_setup/preview.qmd
```

macOS 请按 `00_setup/README.md` 使用 Homebrew。

## 下一步

1. 在 macOS 或 Linux 上按 `00_setup/README.md` 安装环境。
2. 跑通 `00_setup/preview.qmd`。
3. 完成 L1，领取木镐。
4. 进入 W2（L2 合成台）。

## 需要用户确认

- 已推送到 GitHub 公开远程（legogogoagent/biomed-quest）。
- 是否现在创建公开作品集远程。
- 是否把 `00_setup/preview.html` 保留在仓库中，还是只保留 `preview.qmd`。
