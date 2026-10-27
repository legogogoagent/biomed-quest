# L1 热身：运行我，观察输出
# 命令：Rscript 01_overworld/level-01-hello/warmup.R

name <- "新手玩家"
level <- 1
goals <- c("跑通 R 脚本", "完成第一次 commit", "写下 5 句话解释")

cat("玩家：", name, "\n")
cat("等级：Lv.", level, "\n")
cat("目标：\n")
print(goals)

player <- data.frame(
  name = name,
  level = level,
  goal = goals
)

print(player)
str(player)
summary(player)
