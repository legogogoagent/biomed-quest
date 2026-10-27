#!/usr/bin/env Rscript

ok <- TRUE

say <- function(condition, message, hint = "") {
  if (isTRUE(condition)) {
    cat("✅", message, "\n")
  } else {
    cat("❌", message, "\n")
    if (nzchar(hint)) cat("   提示：", hint, "\n")
    ok <<- FALSE
  }
}

root <- here::here()
out_txt <- file.path(root, "output", "hello.txt")
out_html <- file.path(root, "01_overworld", "level-01-hello", "hello.html")

say(file.exists(out_txt), "找到 output/hello.txt",
    "先运行 quest.R，并用 writeLines() 写入文件。")

if (file.exists(out_txt)) {
  lines <- readLines(out_txt, warn = FALSE)
  say(length(lines) >= 3, "hello.txt 至少 3 行",
      "写入玩家名、等级和至少 3 个目标。")
  say(any(grepl("Lv|等级", lines)), "包含等级信息",
      "用 paste() 写入等级，例如 paste('等级: Lv', player_level)。")
}

say(file.exists(out_html), "找到 hello.html",
    "运行 quarto render 01_overworld/level-01-hello/hello.qmd")

if (!ok) {
  cat("\n还没通关。按上面的提示改，然后再运行一次。\n")
  quit(status = 1)
}

cat("\n🎉 L1 通关！别忘了写 5 句话解释并领取「木镐」成就。\n")
