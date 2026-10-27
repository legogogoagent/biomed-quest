#!/usr/bin/env Rscript

# 生成 airway 风格的合成 count 数据，仅用于 W0 预览。
# 真实 airway 数据在 L7 引入。

set.seed(42)

genes <- sprintf("GENE%02d", 1:40)
samples <- c("ctrl_1", "ctrl_2", "ctrl_3", "trt_1", "trt_2", "trt_3")
condition <- rep(c("control", "treated"), each = 3)

base_expression <- rpois(length(genes), lambda = 200)
counts <- matrix(0, nrow = length(genes), ncol = length(samples),
                 dimnames = list(genes, samples))

for (i in seq_along(samples)) {
  counts[, i] <- rnbinom(length(genes), mu = base_expression, size = 20)
}

# 前 8 个基因在处理组中上调约 10 倍，制造可检测的信号。
counts[1:8, 4:6] <- round(counts[1:8, 4:6] * 10)
counts <- round(counts)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

counts_df <- data.frame(gene = genes, counts, check.names = FALSE)
write.csv(counts_df, "data/raw/preview_counts.csv", row.names = FALSE)

metadata_df <- data.frame(
  sample = samples,
  condition = condition,
  stringsAsFactors = FALSE
)
write.csv(metadata_df, "data/raw/preview_metadata.csv", row.names = FALSE)

cat("✅ 生成 data/raw/preview_counts.csv（40 genes × 6 samples）\n")
cat("✅ 生成 data/raw/preview_metadata.csv（3 control + 3 treated）\n")
