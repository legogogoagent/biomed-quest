# Anatomy Atlas

[SirwanAfifi/anatomy-atlas](https://github.com/SirwanAfifi/anatomy-atlas)

## 这是什么

一个浏览器里的交互式 3D 肌肉解剖 + 运动库：

- 126 个肌肉结构、18 个解剖分组
- 旋转、缩放、搜索、选择、上/下半身视图
- 肌肉/肌腱细节、纤维着色、选择高亮、标签、关节地标
- 选中肌肉后可查看运动卡片、器械/肌群筛选和分步说明
- Three.js + JavaScript；WebGL 2；无 WebGL 时保留 HTML 肌肉浏览器
- 模型约 19.7 MiB 压缩，2,246,073 个三角面
- Node.js 22.12+

在线 demo：<https://sirwan.info/anatomy-atlas/>

## 为什么值得收藏

- 它把“肌肉解剖”和“运动库”放在同一个界面里，和 Human Atlas 的通用解剖定位不同。
- 如果你以后做“解剖 + 康复/运动”侧任务，它的交互、运动数据结构、移动端和 WebGL fallback 都值得参考。
- README 写得很细：数据来源、转换步骤、测试、许可证和不可用 WebGL 的降级方案都有。

## 为什么不建议直接复制

- **非常新**：2026-10-25 创建，0 stars、0 forks，尚未经过社区长期验证。
- **应用代码没有明确许可证**：仓库没有顶层 `LICENSE`，`package.json` 是 `"private": true` 且没有 `license` 字段。只有模型、运动数据和媒体分别有许可。
- 约 36 MB，含 19.7 MiB 模型和运动照片；不值得塞进当前 R 学习仓库。
- 它是 JavaScript/Three.js 应用，不是 R 包；对 RNA-seq 主线没有直接依赖。

## 本地运行

```bash
git clone https://github.com/SirwanAfifi/anatomy-atlas.git
cd anatomy-atlas
npm ci
npm run dev
# 打开 http://localhost:4173
```

验证：

```bash
npm run check
npm test
npm run build
```

## 许可证（务必分开看）

- 3D 模型与衍生解剖元数据：**CC BY-SA 4.0**（Z-Anatomy / BodyParts3D 衍生）。
- 运动文字数据：**MIT**（`hasaneyldrm/exercises-dataset`）。
- 运动照片：**Unlicense**（Free Exercise DB）；Gym Visual 图片/GIF 未包含。
- **应用代码：未标注许可证**。在作者明确许可前，按“保留所有权利”处理，不要直接复制代码。

模型署名：

> Z-Anatomy, CC BY-SA 4.0; BodyParts3D, DBCLS, CC BY-SA 2.1 Japan.

## 结论

**收藏为“参考/观望”，不 vendoring，不复制应用代码。** 建议 3–6 个月后复查：是否加了代码许可证、是否有社区使用和维护。若只是找通用解剖 UI，优先看已经 MIT 的 [Human Atlas](../human-atlas/README.md)。
