# Phase 2：Z-Anatomy 神经 + BodyParts3D 皮肤实现记录

- 日期：2026-11-05
- 状态：已完成并合并到 `elbow-atlas` 的 `master`
- 应用仓库：`/home/aigc/Project/elbow-atlas`

## 目标

在 MVP 的 14 个骨骼/肌肉/血管网格之上，补充：

1. 右侧正中、尺、桡、肌皮神经。
2. 右臂皮肤层。

## 数据来源与许可

| 资产 | 来源 | 许可 | 说明 |
|---|---|---|---|
| 4 条神经 | Z-Anatomy Blender 模板 | CC BY-SA 4.0 | 从 `Median nerve.r`、`Ulnar nerve.r`、`Radial nerve.r`、`Musculocutaneous nerve.r` 曲线转为网格 |
| 右臂皮肤 | BodyParts3D 4.0 `skin`（FJ2810） | CC BY 4.0 | 从全身皮肤裁剪出右臂区域 |
| 基础 14 个结构 | BodyParts3D 4.0 | CC BY 4.0 | 保持不变 |

Z-Anatomy 模板的 `Integument` 集合为空，没有可直接使用的皮肤网格；因此皮肤改用 BodyParts3D 全身皮肤裁剪，避免引入来源不明的皮肤资产。

## 坐标对齐

- Z-Anatomy 与 BodyParts3D 同为 Z-up、米制、近似同源。
- 用右侧肱骨、桡骨、尺骨、肩胛骨的包围盒中心做 Umeyama 相似变换（缩放 + 旋转 + 平移）。
- 结果：
  - 缩放 `0.963164667`
  - 最大骨性残差 `0.001643 m`（约 1.6 mm）
- 对齐后再施加项目统一的 `R_x(-90)`，转为 Y-up、+Z 前侧。

## 新增资产

```text
public/assets/elbow/
├─ median_nerve_right.glb              6,912 tris
├─ ulnar_nerve_right.glb               4,224 tris
├─ radial_nerve_right.glb              3,072 tris
├─ musculocutaneous_nerve_right.glb    1,920 tris
├─ skin_right_arm.glb                 21,478 tris
├─ z-anatomy-stats.json
├─ skin-stats.json
├─ Z-ANATOMY-ATTRIBUTION.md
└─ SKIN-ATTRIBUTION.md
```

## 实现

- `scripts/fetch-z-anatomy.sh`：下载并解压 Z-Anatomy 模板（不下载 Blender）。
- `scripts/extract-z-anatomy-nerves.py`：在 Blender 无头模式下把 4 条神经曲线转为网格，导出 OBJ。
- `scripts/align-z-anatomy-nerves.py`：Umeyama 对齐、Y-up、导出 GLB 与统计。
- `scripts/extract-skin.py`：加载 BodyParts3D 全身皮肤，裁剪右臂盒体，导出 GLB 与统计。
- `data-src/structures-supplement.yaml`：新增 4 条神经 + 1 个皮肤结构。
- `src/data/schema.ts`：`source.dataset` 支持 `BodyParts3D` / `Z-Anatomy`，`license` 支持 `CC BY 4.0` / `CC BY-SA 4.0`。
- `src/data/assemble.ts` / `scripts/build-data.ts`：合并三个 stats 文件，生成 19 个结构。
- `src/ui/LayerPanel.tsx`：恢复 `神经` 层，新增 `皮肤` 层；皮肤默认关闭。
- `src/ui/AnatomyViewer.tsx`：神经染黄、皮肤染浅肤色的半透明层；Move 模式自动隐藏神经/皮肤。
- `src/ui/InfoCard.tsx`：FMA 标签改为 ID，显示来源与许可。
- `src/ui/SectionPanel.tsx`：注明切面模型只含骨/肌/血管。

## 验证

- `npm test`：40/40 通过。
- `npm run e2e`：4/4 通过（含神经/皮肤图层加载与切换）。
- `npm run build`：通过，prebuild 校验 25 个运行时资产。
- 视觉检查：神经在 Explore 中可见；皮肤默认关闭，开启后半透明；Move 模式隐藏神经/皮肤。

## 已知限制

- 神经与皮肤网格挂在肱骨静态组上，不随肘关节形变；Move 模式隐藏，Explore 保持解剖静息位展示。
- Section 三标准面封盖仍只包含 MVP 的 14 个结构，不含神经/皮肤。
- 神经为 Z-Anatomy 的教学级走行，不是临床验证的神经束数据。
- 皮肤为 BodyParts3D 全身皮肤的矩形裁剪，边缘开放；作为体表上下文，不是完整皮肤层。
- 皮肤裁剪仍包含少量腋/躯干内侧区域；可按需收紧 `SKIN_BOX` 后重跑 `scripts/extract-skin.py`。
