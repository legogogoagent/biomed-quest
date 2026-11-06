# 📚 资源库

外部资源索引。原则：**不把大仓库直接塞进本项目**；只记录来源、许可证、用法和按需下载方式。

| 资源 | 类型 | 用途 | 许可证 | 入口 |
|---|---|---|---|---|
| BodyParts3D 3.0 | 人体解剖 3D 模型（STL）+ Julia 接口 | 解剖可视化、3D 侧任务、网格处理练习 | 数据 CC BY-SA 2.1 Japan；代码 MIT | [bodyparts3d](bodyparts3d/README.md) |
| BodyParts3D 4.3 API | 4.3 全分辨率 OBJ + Python 下载/子集工具 | 需要更新/更全的几何，或只取特定器官 | 代码 MIT；数据 CC BY-SA 2.1 JP | [body-parts-3d-api](body-parts-3d-api/README.md) |
| Human Atlas | 浏览器交互式 3D 解剖浏览器（TypeScript） | 3D 解剖 UI 参考、数据管线参考 | 代码 MIT；数据 CC BY 4.0 | [human-atlas](human-atlas/README.md) |
| Anatomy Atlas | 3D 肌肉 + 运动库（JavaScript/Three.js） | 肌肉/运动 UX 参考；观望 | 模型 CC BY-SA 4.0；运动文本 MIT；应用代码未标 | [anatomy-atlas](anatomy-atlas/README.md) |

## 收录规则

1. 先查许可证、体积和最后更新时间。
2. 超过 50 MB 的仓库不复制、不做 submodule；用脚本按需下载。
3. 外部内容统一放 `external/`，该目录已被 `.gitignore` 忽略。
4. 每个资源都要写清：来源、许可证、引用方式、最小用法。
5. 不在公开作品集里放未授权数据；只放脚本、衍生图和来源说明。

## 当前收录

- [BodyParts3D 3.0](bodyparts3d/README.md)：人体解剖 3D 模型，适合解剖可视化和 3D 侧任务，不进入 RNA-seq 主线。
- [BodyParts3D 4.3 API](body-parts-3d-api/README.md)：4.3 全分辨率数据源，按需取子集。
- [Human Atlas](human-atlas/README.md)：交互式 3D 解剖参考实现，不 vendoring。
- [Anatomy Atlas](anatomy-atlas/README.md)：126 块肌肉 + 运动库的 3D 参考；代码许可未标，观望，不复制代码。

## 暂不收录

- `wspr/BodyParts3D-Matlab`：MATLAB 工具，4.0 的 99% 简化 OBJ，2018 年后基本未更新；与本项目的 R 主线不匹配。若以后用 MATLAB，再单独参考。
