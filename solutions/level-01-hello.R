#!/usr/bin/env Rscript

# L1 参考解：通关后解锁。先自己尝试，再看这里。

player_name <- "Alex"
player_level <- 1
goals <- c("完成 W0 预览", "通过 L1 自检", "写下 5 句话解释")

player <- data.frame(
  name = player_name,
  level = player_level,
  goal = goals
)

print(player)
print(summary(player))

dir.create(here::here("output"), showWarnings = FALSE)
writeLines(
  c(
    paste("玩家:", player_name),
    paste("等级: Lv", player_level),
    paste("目标:", paste(goals, collapse = " / "))
  ),
  here::here("output", "hello.txt")
)

quarto::quarto_render(
  here::here("01_overworld", "level-01-hello", "hello.qmd")
)

cat("✅ 参考解完成：output/hello.txt 和 hello.html 已生成\n")
