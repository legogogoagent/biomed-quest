# L1 主任务：建立你的玩家档案
# 运行：Rscript 01_overworld/level-01-hello/quest.R

player_name <- "你的名字"   # 改成你的名字
player_level <- 1
goals <- c("目标 1", "目标 2", "目标 3")  # 改成你自己的 3 个目标

player <- data.frame(
  name = player_name,
  level = player_level,
  goal = goals
)

print(player)
print(summary(player))

# 你的任务：
# 1. 创建 output/ 目录（提示：dir.create()）
# 2. 用 writeLines() 把玩家名、等级、目标写入 output/hello.txt
# 3. 运行本脚本，然后运行 check_level_01.R
