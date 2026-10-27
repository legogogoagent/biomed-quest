# Data Sources

## preview_counts.csv / preview_metadata.csv

- 来源：`data-raw/generate_preview_data.R` 生成的合成数据。
- 用途：W0 终点预览，只演示“count → QC → 差异表达 → 可视化”的流程。
- 规模：40 个基因 × 6 个样本（3 control，3 treated）。
- 信号：前 8 个基因在 treated 组上调约 10 倍。
- 许可证：MIT（与仓库代码相同）。

真实 `airway` 数据在 L7 通过 Bioconductor 引入，不放入本目录。
