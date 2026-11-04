# Human Atlas

[ashemag/human-atlas](https://github.com/ashemag/human-atlas)

## 这是什么

一个浏览器里的交互式 3D 解剖浏览器：

- React + Three.js + shadcn/ui
- 2,234 个可选择的 BodyParts3D 4.0 网格
- 15 个解剖系统、3,432 个命名概念
- 支持旋转、缩放、点选、系统开关、爆炸视图和搜索
- 约 33 MB 压缩几何；Node.js 22.13+，不需要 API key

在线 demo：<https://human-atlas-seven.vercel.app>

## 为什么值得收藏

- 如果你的项目以后要做“解剖 3D 浏览器”或“器官选择器”，它是很好的**参考实现**。
- 可以看它怎么处理网格批处理、GPU 选择、爆炸视图、移动端控制和搜索。
- 4.5k stars，MIT 代码，数据来源清晰。

## 不建议直接复制的原因

- 它是 TypeScript/React 应用，不是 R 包；对当前 `biomed-quest` 的 RNA-seq 主线没有直接依赖。
- 仓库约 104 MB，包含浏览器优化后的几何；没必要塞进学习仓库。
- 它用的是 **BodyParts3D 4.0，99% 简化几何**；如果你要全分辨率 4.3，用 [body-parts-3d-api](../body-parts-3d-api/README.md)。

## 本地运行

```bash
git clone https://github.com/ashemag/human-atlas.git
cd human-atlas
npm ci
npm run dev
# 打开 http://localhost:3016
```

## 许可证

- 应用代码：MIT。
- 解剖数据：BodyParts3D 4.0，`public/ATTRIBUTION.md` 标注为 **CC BY 4.0**。
- 使用或再分发时保留 BodyParts3D / DBCLS 署名。

## 结论

**收藏为“外部参考”，不 vendoring。** 适合未来做 3D 解剖交互时回来读代码和设计。
