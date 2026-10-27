#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(tibble)
})

counts <- read_csv("data/raw/preview_counts.csv", show_col_types = FALSE)
metadata <- read_csv("data/raw/preview_metadata.csv", show_col_types = FALSE)

count_matrix <- counts |>
  column_to_rownames("gene") |>
  as.matrix()

log_matrix <- log2(count_matrix + 1)

# PCA：看样本是否按条件分开
pca <- prcomp(t(log_matrix), scale. = TRUE)
pca_df <- as.data.frame(pca$x[, 1:2]) |>
  rownames_to_column("sample") |>
  left_join(metadata, by = "sample")

# 简化的差异表达：t 检验 + BH 校正（仅用于预览，正式分析用 DESeq2）
de_results <- lapply(rownames(log_matrix), function(gene) {
  control <- log_matrix[gene, metadata$condition == "control"]
  treated <- log_matrix[gene, metadata$condition == "treated"]
  tibble(
    gene = gene,
    mean_control = mean(control),
    mean_treated = mean(treated),
    log2fc = mean(treated) - mean(control),
    p_value = t.test(control, treated)$p.value
  )
}) |>
  bind_rows() |>
  mutate(p_adj = p.adjust(p_value, method = "BH")) |>
  arrange(p_value)

# 热图：取最显著的 15 个基因
top_genes <- de_results |>
  slice_head(n = 15) |>
  pull(gene)

heatmap_df <- as.data.frame(log_matrix[top_genes, , drop = FALSE]) |>
  rownames_to_column("gene")

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

write_csv(pca_df, "data/processed/preview_pca.csv")
write_csv(de_results, "data/processed/preview_volcano.csv")
write_csv(heatmap_df, "data/processed/preview_heatmap.csv")

cat("✅ PCA:", nrow(pca_df), "samples\n")
cat("✅ DE:", nrow(de_results), "genes; significant (padj < 0.05):",
    sum(de_results$p_adj < 0.05, na.rm = TRUE), "\n")
cat("✅ Heatmap:", nrow(heatmap_df), "genes\n")
