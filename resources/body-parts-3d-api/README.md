# BodyParts3D 4.3 API

[olivercase/body_parts_3d_api](https://github.com/olivercase/body_parts_3d_api)

## 这是什么

BodyParts3D / Anatomography **4.3** 的完整、全分辨率网格集，以及配套的 Python 工具：

- 3,210 个验证过的 `.obj` 网格（Git LFS）
- `download_bodyparts3d_4.3.py`：下载、断点续传、校验
- `bp3d_subset.py`：按内置分组或正则只取需要的结构
- `MANIFEST.csv`：每个网格的 FJ/BP/FMA ID、名称、面数、顶点数、字节数
- 内置分组：brain、spine、spinal_cord、vagus_nerve、heart、lungs、gut、blood_vessel、leg_muscle、skin

## 为什么值得收藏

- 这是目前最实用的 **4.3 全分辨率** BodyParts3D 数据入口。
- 不需要先拉 3,210 个网格；可以只取一个心脏、肺或脑。
- 自带版本校验，避免“以为是 4.3，其实是 4.0”的问题。
- 和本项目已有的 3.0 STL 资源互补：3.0 适合快速读 STL，4.3 适合要更新/更全的几何。

## 用法

```bash
git lfs install
git clone https://github.com/olivercase/body_parts_3d_api.git
cd body_parts_3d_api

# 看内置分组
python3 bp3d_subset.py --list

# 只取心脏和肺（从仓库现有网格复制）
python3 bp3d_subset.py --group heart --group lungs --out subset

# 只取肠道，但从源站下载而不是复制
python3 bp3d_subset.py --group gut --download --out subset

# 全量重新下载并校验
python3 download_bodyparts3d_4.3.py
```

输出是 `subset/<group>/*.obj` 和 `subset/MANIFEST.csv`。

## 许可证

- 代码：MIT。
- 数据：README 标注 **CC BY-SA 2.1 Japan**。
- 引用软件 DOI：<https://doi.org/10.5281/zenodo.22727172>
- 引用数据：BodyParts3D / DBCLS，以及 Mitsuhashi et al. 2009（DOI: `10.1093/nar/gkn613`）。

**许可注意**：不同版本/来源的许可文本不完全一致。`human-atlas` 的 `ATTRIBUTION.md` 称 BodyParts3D 官方许可在 2025-02-27 更新为 CC BY 4.0；本仓库仍标 CC BY-SA 2.1 JP。再分发前以你实际使用的版本的官方许可为准。

## 结论

**收藏为“数据源”，不提交 LFS 网格。** 需要 4.3 全分辨率或特定器官子集时再下载。
