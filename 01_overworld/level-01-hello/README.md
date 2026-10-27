# L1 新手村：第一次进入世界

⏱️ 预计 4–5 小时（核心 3 小时 + 可选 2 小时）
🏆 成就：木镐
🎯 目标：完成第一份玩家档案，跑通 R → Quarto → Git 的最小闭环。

## 为什么做这个

你不需要先学完所有语法。先完成一个能运行、能渲染、能提交的小作品，知道“一个 R 项目长什么样”。

## 任务

1. 读 `concepts.qmd`，认识对象、向量、数据框、函数。
2. 运行 `warmup.R`，看输出。
3. 编辑 `quest.R`，把 TODO 换成你的信息。
4. 编辑 `hello.qmd`，让它读取 `output/hello.txt` 并显示。
5. 运行 `check_level_01.R`，直到全部 ✅。
6. 渲染 `hello.qmd`。
7. 写 `journal.md` 的复盘三问 + 5 句话解释。
8. commit，并在 `PROGRESS.md` 领取木镐。

## 通关条件

- `Rscript 01_overworld/level-01-hello/quest.R` 能运行。
- `output/hello.txt` 至少 3 行，包含等级信息。
- `01_overworld/level-01-hello/hello.html` 存在。
- `check_level_01.R` 全部 ✅。
- `journal.md` 完成。
- 至少 1 次 commit。

## 5 句话解释

1. 这关解决了什么问题？
2. 输入是什么、输出是什么？
3. 关键函数为什么选它？
4. 结果说明什么？
5. 还有什么不确定？

## 卡住了怎么办

- 先看报错最后一行。
- 用 `?函数名` 查文档。
- 在 `journal/ai-log.md` 记录问题，再让 AI 给一级提示，不要直接要代码。
