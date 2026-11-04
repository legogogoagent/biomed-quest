# RNA-seq: from count to biology

一张按 Anatomy skill 的“物体即解释”原则手绘的等距解释图。

![RNA-seq figure](preview.png)

## 打开方式

直接双击 `index.html`，或在仓库根目录运行：

```bash
python3 -m http.server 8000
# 浏览器打开 http://localhost:8000/docs/figures/rnaseq-count-to-biology/
```

页面是独立的 HTML/SVG/JS，不依赖外部库。支持 `prefers-reduced-motion`，离开视口时会暂停动画。

## 图在讲什么

这不是“方框 + 箭头”的流程图，而是一台把 count matrix 送进生物学解释的测试台。

| 机器部件 | RNA-seq 概念 |
|---|---|
| 左侧 6 支试管 | 6 个样本（3 control 蓝、3 treated 红） |
| 后方彩色面板 | 6 × 40 count matrix |
| 扫描门架 | 读取、QC、标准化 |
| 天平 | control vs treated 的比较（log2FC） |
| 拨盘 | 差异表达摘要：8 / 40，FDR < 0.05 |
| 金色闸门 | 显著性阈值；8 个基因通过 |
| 绘图仪 | 火山图 |
| 右侧卡片 | GO / KEGG / hypothesis，生物学解释 |

## 真实数字

- 6 个样本
- 40 个基因
- 8 个差异表达基因
- FDR < 0.05

这些是教学用的合成数字，对应 W0 预览的数据规模，不是某项真实研究的结论。

## 设计约束

- 等距投影、四段明暗、从后往前的绘制顺序。
- 主体是“机器”，不是抽象方块。
- 文字尽量放在铭牌上，图内只保留必要的读数。
- 动效克制：扫描滑架、拨盘指针、金色基因、绘图笔。
- 不使用 Minecraft 或第三方官方素材。

## 许可证

图与代码：MIT。可自由修改和复用。
