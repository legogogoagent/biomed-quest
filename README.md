# ⛏️ BiomedCraft
> 一个生物医学大一学生的 R 语言生存存档

🟩 当前境界：Lv.0 迷路的村民
❤️ 模式：生存（严格教练，延迟给答案）
🌍 世界种子：airway-v1
📦 进度：0/12 关卡 · 0/3 Boss
🏆 成就：0/13

> Minecraft-inspired learning repo. Not affiliated with Mojang or Microsoft. 本项目不使用官方素材。

## 🗺️ 世界地图

```text
主世界   新手村 → 合成台 → 工作台 → 地图
            ↓ 传送门
下界     附魔台 → 红石电路 → 要塞 → 烈焰棒
            ↓ 传送门
末地     末地城 → 末地船 → 返回传送门 → 龙蛋
```

完整状态见 [MAP.md](MAP.md)，经验和成就见 [PROGRESS.md](PROGRESS.md)。

## 📜 游戏规则

- commit = 保存世界
- 每周 tag = 存档点
- act-1/2/3 tag = 传送门
- 成就必须附证据链接
- AI 是严格教练：先自己写，卡住只给提示，提交后才审查
- 每周至少 2 次 commit、1 篇复盘

## 🏆 成就墙

| 成就 | 条件 | 状态 |
|---|---|---|
| 木镐 | 第一次跑通 R 脚本 | 🔒 |
| 第一次合成 | 第一个 `dplyr` 管道或函数 | 🔒 |
| 工作台 | 完成一次可复现清洗 | 🔒 |
| 地图绘制者 | 第一张完整 `ggplot` | 🔒 |
| 附魔台 | 能解释一个统计概念 | 🔒 |
| 红石工程师 | 第一个可复用函数 | 🔒 |
| 下界通行证 | 读入并解释 `airway` | 🔒 |
| QC 守门人 | 发现或排除一个数据质量问题 | 🔒 |
| 末地行者 | 完成一次差异表达 | 🔒 |
| 龙蛋 | 通关 Boss 1 | 🔒 |
| 村庄英雄 | 把富集结果讲给非专业听众 | 🔒 |
| 经验修补 | 四周后回访旧关卡并改进 | 🔒 |
| 传说的起点 | 公开发布第一个作品集 | 🔒 |

## 🚀 快速开始

```bash
cd ~/Project/Biomedical
Rscript -e 'renv::restore()'
quarto render 00_setup/preview.qmd
```

第一次使用先读 [00_setup/README.md](00_setup/README.md)。

## 📂 存档结构

```text
00_setup/       安装、环境检查、W0 预览
01_overworld/   L1–L4 + 小 Boss 1
02_nether/      L5–L8 + 小 Boss 2
03_end/         L9–L12
bosses/         Boss 任务与战报
data/           原始与处理后的数据
R/              可复用函数
journal/        每周复盘与 AI 日志
templates/      任务卡、复盘、审查模板
assets/badges/  自绘像素徽章
docs/           设计文档与学习笔记
```

## 🧭 当前任务

- [00_setup/README.md](00_setup/README.md)：安装环境
- [00_setup/preview.qmd](00_setup/preview.qmd)：跑通终点预览
- [01_overworld/level-01-hello/README.md](01_overworld/level-01-hello/README.md)：L1 新手村

## 📄 License

代码 MIT；教程文字 CC-BY-4.0；数据遵循原始来源许可证。
