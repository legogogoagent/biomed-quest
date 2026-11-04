#!/usr/bin/env Rscript

# 渲染一个 BodyParts3D STL 模型。
# 先运行：./scripts/fetch_bodyparts3d.sh FMA24474
# 再安装：install.packages(c("rgl", "Rvcg"))
# 最后运行：Rscript resources/bodyparts3d/example_render.R

library(rgl)

stl <- "external/BodyParts3D/assets/BodyParts3D_data/stl/FMA24474.stl"

if (!file.exists(stl)) {
  stop("找不到模型。请先运行: ./scripts/fetch_bodyparts3d.sh FMA24474")
}

mesh <- readSTL(stl, force = TRUE)
shade3d(mesh, color = "#d9b38c")
rglwidget()

cat("✅ 已加载:", stl, "\n")
cat("   在 RStudio Viewer 或浏览器中查看 3D 模型。\n")
