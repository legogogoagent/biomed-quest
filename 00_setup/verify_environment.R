#!/usr/bin/env Rscript

ok <- 0L
fail <- 0L

pass <- function(msg) {
  cat("✅", msg, "\n")
  ok <<- ok + 1L
}

fault <- function(msg, hint = "") {
  cat("❌", msg, "\n")
  if (nzchar(hint)) cat("   提示：", hint, "\n")
  fail <<- fail + 1L
}

check <- function(name, condition, detail = "", hint = "") {
  if (isTRUE(condition)) {
    pass(paste0(name, if (nzchar(detail)) paste0(" (", detail, ")") else ""))
  } else {
    fault(name, hint)
  }
}

check("R >= 4.2", getRversion() >= "4.2", as.character(getRversion()),
      "升级 R：https://cran.r-project.org")

packages <- c("tidyverse", "pheatmap", "here", "janitor", "skimr", "renv", "quarto")
for (pkg in packages) {
  check(
    paste0("R package ", pkg),
    requireNamespace(pkg, quietly = TRUE),
    hint = paste0('运行 install.packages("', pkg, '")')
  )
}

quarto_version <- tryCatch(
  system2("quarto", "--version", stdout = TRUE, stderr = TRUE),
  error = function(e) ""
)
check("quarto CLI", length(quarto_version) > 0 && nzchar(quarto_version[[1]]),
      paste(quarto_version, collapse = " "),
      "安装 Quarto：https://quarto.org/docs/get-started/")

git_version <- tryCatch(
  system2("git", "--version", stdout = TRUE, stderr = TRUE),
  error = function(e) ""
)
check("git", length(git_version) > 0 && nzchar(git_version[[1]]),
      paste(git_version, collapse = " "),
      "安装 Git：https://git-scm.com")

cat("\nPassed:", ok, " Failed:", fail, "\n")
if (fail > 0) {
  quit(status = 1)
}
cat("🎉 环境检查通过，可以进入 W0。\n")
