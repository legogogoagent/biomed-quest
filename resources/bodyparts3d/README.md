# BodyParts3D

人体解剖 3D 模型集合（STL）+ Julia 接口，由 [Kevin-Mattheus-Moerman/BodyParts3D](https://github.com/Kevin-Mattheus-Moerman/BodyParts3D) 维护。

## 这是什么

- 来源：BodyParts3D / Anatomography 项目（日本 DBCLS）。
- 内容：人体各解剖结构的二进制 STL 模型，文件名使用 FMA（Foundational Model of Anatomy）ID，例如 `FMA24474.stl`（右股骨）。
- 版本：`3.0 / 20110915`；目前只有单一男性模型。
- 附加数据：`FMA.csv`、`parts_list_e.txt` 等提供 FMA ID 与英文名称的对应。
- 代码：`src/` 下有 Julia 接口；本学习仓库不依赖 Julia。

## 为什么收录

它适合做这些**侧任务**，不是 RNA-seq 主线：

- 解剖结构 3D 可视化；
- STL 网格读取、缩放、旋转、体积/表面积计算；
- FMA ID 与英文解剖名的映射练习；
- 未来做“解剖 + 组学”跨模态展示时的素材。

## 体积警告

上游仓库约 **930 MB**，不要直接 `git clone` 全量。使用本项目的脚本：

```bash
# 只拉元数据、FMA 表、parts list 和 src（不下载 STL）
./scripts/fetch_bodyparts3d.sh

# 只下载一个模型，例如右股骨 FMA24474
./scripts/fetch_bodyparts3d.sh FMA24474
```

下载位置：

```text
external/BodyParts3D/
└── assets/BodyParts3D_data/
    ├── FMA.csv
    ├── parts_list_e.txt
    ├── png/                  # 预览图，按需
    └── stl/
        └── FMA24474.stl      # 只包含你指定的模型
```

`external/` 已被 `.gitignore` 忽略；不要把模型提交到仓库。

## 在 R 里使用

可选包（不加入主线 `renv`，需要时单独安装）：

```r
install.packages(c("rgl", "Rvcg"))
```

读取并渲染一个 STL：

```r
library(rgl)

stl <- "external/BodyParts3D/assets/BodyParts3D_data/stl/FMA24474.stl"
if (!file.exists(stl)) {
  stop("先运行: ./scripts/fetch_bodyparts3d.sh FMA24474")
}

mesh <- readSTL(stl, force = TRUE)
shade3d(mesh, color = "#d9b38c")
rglwidget()
```

也可用 `Rvcg::vcgImport()` 读取网格后做面积、体积、平滑等处理。完整示例见 [example_render.R](example_render.R)。

## 许可证与引用

**必须遵守上游许可证。**

- 3D 模型与衍生几何：**CC BY-SA 2.1 Japan**（署名 + 相同方式共享）。
- 代码：**MIT**。
- 上游要求署名：

> BodyParts3D, (c) The Database Center for Life Science licensed under CC Attribution-Share Alike 2.1 Japan.

引用论文：

> Mitsuhashi N, Fujieda K, Tamura T, Kawamoto S, Takagi T, Okubo K.
> BodyParts3D: 3D structure database for anatomical concepts.
> Nucleic Acids Res. 2009 Jan;37(Database issue):D782-5.
> https://doi.org/10.1093/nar/gkn613

数据归档 DOI：`http://doi.org/10.18908/lsdba.nbdc00837-000`

## 注意

- 模型主要用于展示和教学，不保证适合有限元等计算用途；例如皮肤模型可能有非流形三角面。
- 不是临床数据，不能用于诊断或治疗。
- 上游选择 3.0 而不是 4.0，是因为 4.0 的皮肤/肌肉区域存在相交问题。
- 如果你把模型或衍生图放进公开作品集，必须保留署名和 CC BY-SA 许可说明。
