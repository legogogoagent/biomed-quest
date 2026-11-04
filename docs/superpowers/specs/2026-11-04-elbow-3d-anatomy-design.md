# 肘与前臂交互式 3D 解剖学习器：设计文档

- 日期：2026-11-04
- 状态：设计已确认，待用户复核
- 目标仓库：独立新建 Web 项目（暂定 `elbow-atlas`），不并入当前 R 学习仓库
- 数据来源：BodyParts3D 4.3（FMA ID 为主键）
- 技术栈：React + TypeScript + Vite、Three.js + React Three Fiber、drei OrbitControls

## 1. 背景与目标

医学生需要理解“结构 + 运动 + 毗邻关系”，而静态图谱无法展示关节活动时肌肉长度的动态变化。本项目做一个浏览器内、可离线部署的肘与前臂交互式解剖学习器，用一个区域把“结构浏览、关节约束、肌肉长度反馈、点选识别”做透，再决定是否扩展到全身。

本项目要验证的核心假设是：**用一份可人工维护的约束数据（关节枢轴、活动范围、肌肉附着点），就能在纯运动学场景图中做出解剖学上可信、可测试、可扩展的交互，而不需要物理引擎。**

## 2. 非目标

- 不做全身 3D 图谱；不追求覆盖 3,000+ BodyParts3D 网格。
- 不使用物理引擎做碰撞、软组织 FEM、蒙皮或弹簧-质点仿真。
- 不在 MVP 做前臂旋前/旋后（只保留屈伸单自由度）。
- 不做通用碰撞检测与穿模修正。
- 不做账号、班级、教师看板、后端数据库。
- 不做移动端优先；桌面浏览器为主，触摸仅保证可用。
- 不做爆炸视图（区域规模小，教学收益低）。
- 不把 BodyParts3D 原始或衍生网格提交进当前仓库。

## 3. 结构集（肘 + 前臂，15–25 个可选网格）

| 类别 | 结构 |
|---|---|
| 骨骼 | 肱骨、桡骨、尺骨 |
| 上下文骨骼（不可选，仅剪影） | 肩胛骨、手骨 |
| 主要肌肉 | 肱二头肌（长头、短头）、肱肌、肱三头肌（长头、外侧头、内侧头） |
| 辅助肌肉 | 肱桡肌 |
| 神经 | 正中神经、尺神经、桡神经、肌皮神经 |
| 血管 | 肱动脉、桡动脉近端、尺动脉近端 |
| 韧带 | 尺侧副韧带、桡侧副韧带、环状韧带（若数据集无对应网格，则以标注点代替） |
| 皮肤/皮下 | 上臂与前臂皮肤，可作为可剥离层 |

**FMA ID 规则**：所有 ID 从官方 `FMA.csv` / `parts_list` 中匹配并人工核对，禁止凭记忆填写。预处理脚本生成候选映射，人工确认后写入 `structures.json`。

## 4. 用户流程与核心交互

### 4.1 主循环

1. 进入场景，默认显示半透明皮肤 + 骨骼，相机对准肘部。
2. 拖动前臂或使用角度滑杆，肘关节在活动范围内屈伸。
3. 肱二头肌随屈曲缩短、肱三头肌被动拉长，实时显示角度、肌长与相对静息长度百分比。
4. 通过图层开关与透明度滑杆剥离皮肤、肌肉、神经血管。
5. 点选任一结构，右侧信息卡显示中文名、英文名、拉丁名、FMA ID、系统、毗邻结构与一句临床联系。
6. 矢状/冠状/横断剖面滑杆观察内部关系。
7. 测验模式：隐藏标签与皮肤，给出结构名，要求点击对应结构；结果写入本地进度。

### 4.2 关节约束

- 关节类型：铰链（单轴）。
- 角度定义：0° 为完全伸直，正方向为屈曲。
- 默认活动范围：屈曲 0–145°，过伸下限 −5°（可配置）。
- 数值来源：解剖学教材与文献的常模（如 Neumann《Kinesiology of the Musculoskeletal System》、AAOS 常模），界面上标注“教学近似值，非临床诊断标准”。
- 越界行为：输入被 clamp 到边界，并显示“已达解剖极限”提示。

### 4.3 明确砍掉的功能

- 爆炸视图。
- 前臂旋转。
- 真实肌腹形变（先用附着点之间的示意管与长度读数）。
- GPU picking（当前规模用 Raycaster）。
- 剖面封盖（接受空心剖面）。

## 5. 技术架构

独立新仓库，单 Vite 应用内分三层，不做 monorepo：

```text
elbow-atlas/
├─ public/assets/elbow/      # 构建产物：GLB + 三份 JSON
├─ data-src/                 # 人工维护 YAML：structures / joints / attachments
├─ scripts/preprocess/       # OBJ → 清理 → 减面 → GLB → centroid/AABB/manifest
├─ src/
│  ├─ core/                  # 框架无关 Three.js：scene、loader、rig、picker、clipping
│  ├─ data/                  # 构建期生成并通过校验的 JSON
│  └─ ui/                    # React + R3F：面板、图层、测验、本地进度
└─ tests/                    # Vitest 单元测试 + Playwright E2E
```

分层约束：

- `core/` 不 import React，可单独测试与复用。
- `ui/` 只通过明确的 store 接口操作场景状态。
- 数据在构建期由 zod 校验，不合法则构建失败。

### 5.1 渲染与拾取决策

- **每个结构一个 mesh**，不合并、不做实例化；20 个左右 draw call 无性能压力，换来选择、透明度、裁剪面的实现简单。
- **拾取用 Raycaster**：仅对可见结构求交；`pointerdown` 与 `pointerup` 位移小于阈值才判定为点击，避免拖拽误触。
- **透明**：按系统分组排序，使用 `alphaHash` 或 `depthWrite=false` 减少排序穿帮；皮肤默认透明度 0.15。
- **裁剪**：全局 `renderer.localClippingEnabled = true`，每个材质持有 `clippingPlanes`；剖面为空心，不做 stencil 封盖。
- **坐标轴**：预处理阶段统一为 Y-up、米制，并固定解剖轴映射并在 manifest 中声明（X 左右、Y 上下、Z 前后）。

## 6. 数据模型

### 6.1 `structures.json`

```jsonc
{
  // 字段示例；fma_id / 坐标 / 统计值由预处理与 FMA.csv 匹配生成
  "fma_id": "FMA00000",
  "slug": "humerus_right",
  "names": { "zh": "肱骨", "en": "Humerus", "la": "Humerus" },
  "system": "skeletal",
  "region": "upper_limb",
  "laterality": "right",
  "selectable": true,
  "contextOnly": false,
  "mesh": "humerus_right.glb",
  "centroid": [0.0, 0.0, 0.0],
  "bbox": { "min": [0, 0, 0], "max": [0, 0, 0] },
  "tris": 12000,
  "neighbors": ["FMA00001"],
  "clinical": "一句临床联系"
}
```

### 6.2 `joints.json`

```jsonc
{
  "id": "elbow_right",
  "type": "hinge",
  "parent": "humerus_right",
  "childGroup": "forearm_right",
  "pivot": [0.0, 0.0, 0.0],
  "axis": [1.0, 0.0, 0.0],
  "restAngle": 0.0,
  "limits": { "min": -5.0, "max": 145.0 },
  "positive": "flexion",
  "source": "教材常模，教学近似"
}
```

`pivot`、`axis` 与附着点均由校准工具在模型坐标系中取点生成。

### 6.3 `attachments.json`

```jsonc
{
  "muscle": "biceps_brachii_right",
  "heads": [
    {
      "name": "long_head",
      "origin":    { "bone": "scapula_right", "p": [0.0, 0.0, 0.0] },
      "via":       [{ "bone": "humerus_right", "p": [0.0, 0.0, 0.0] }],
      "insertion": { "bone": "radius_right",  "p": [0.0, 0.0, 0.0] }
    }
  ],
  "restLength": 0.0,
  "teachingNote": "屈肘时缩短，伸肘时拉长"
}
```

## 7. 约束与肌肉长度实现

### 7.1 场景图与枢轴

BodyParts3D 网格顶点位于统一的世界坐标。绑定方式：

```text
scene
└─ humerus mesh (世界坐标)
└─ jointGroup  (position = pivot)
   └─ innerGroup (position = -pivot)
      ├─ radius mesh
      └─ ulna mesh
```

0° 时几何位置保持不变；旋转 `jointGroup` 即严格绕 `pivot` 旋转。

### 7.2 附着点变换与肌长

- 附着点以“骨骼局部坐标（相对骨骼原始世界坐标）”存储。
- 运行时位置 = `bone.matrixWorld × localPoint`。
- 肌长 = `|origin→via₁| + |via₁→via₂| + … + |viaₙ→insertion|` 的折线长度。
- 相对变化 = `(L − L_rest) / L_rest`。
- 使用 via point 的原因：肱二头肌绕过肘前方、肱三头肌绕过鹰嘴后方；直连起止点会得到错误的长度曲线。

### 7.3 拖拽角度计算

1. 指针射线与“过 pivot、法线为关节轴”的平面求交。
2. 取交点在平面内相对 pivot 的方向向量，与静息方向求有符号角。
3. clamp 到 `limits` 后写回唯一状态源 `elbowAngle`。
4. 拖拽期间禁用 OrbitControls，`pointerup` 后恢复。

## 8. 校准工具

M1 交付一个仅开发环境可用的标定模式：

- 在任意网格表面点击取点，输出世界坐标。
- 依次采集关节 pivot、旋转轴两端点、各肌肉 origin/via/insertion。
- 一键导出 `joints.yaml` / `attachments.yaml` 草稿。

理由：pivot 与 20+ 附着点的手工标定是本项目最容易返工的环节，工具成本远低于反复试错。

## 9. 异常处理

- 构建期 zod 校验三份 JSON，不合法直接 fail build。
- 单个 GLB 加载失败：该结构在列表中置灰，不影响其他结构；控制台记录明确错误。
- WebGL 不可用或 context lost：显示提示并提供重载按钮。
- 角度越界：clamp 并给出“已达解剖极限”提示。
- localStorage 不可用：降级为内存态，并在界面提示进度不会保存。

## 10. 测试与验收

### 10.1 单元测试（Vitest）

- 角度 clamp 与有符号角换算。
- 指针射线到关节角的映射。
- 附着点随 `matrixWorld` 变换的正确性。
- **肌肉长度单调性**：屈曲增大时肱二头肌长度单调下降、肱三头肌单调上升；伸肘反之。
- 数据 schema 校验。

### 10.2 E2E（Playwright）

- 加载区域资源，首屏无报错。
- 拖动前臂：角度始终在 ROM 内；到达边界出现提示。
- 点击结构：信息卡名称与 FMA ID 正确。
- 图层开关与透明度生效。
- 滑块调节剖面，画面变化。
- 测验流程：出题 → 点击 → 判定 → 进度写入。
- 关键机位截图回归。

### 10.3 验收标准

- 任意拖动下关节角不越界，肌肉长度变化方向正确。
- 区域内首屏资源 < 10 MB；中端笔记本 ≥ 50 fps。
- 20 个左右结构的点选命中准确，无拖拽误触。
- 三份数据 JSON 通过 schema 校验；单元测试全部通过。
- 界面明确标注“教学近似，非临床诊断”。

## 11. 里程碑

| 阶段 | 交付物 | 预计 |
|---|---|---|
| M0 | 新 repo、预处理 1 根骨为 GLB、场景 + OrbitControls + Raycast | 1–2 天 |
| M1 | 全区域网格、图层/透明度、信息卡、校准工具 | 2–3 天 |
| M2 | 关节 rig + ROM + 拖拽/滑杆 + 肌肉折线长度反馈 | 2–3 天 |
| M3 | 剖面 + 测验 + 本地进度 | 2 天 |
| M4 | 触摸支持、性能优化、文档、静态部署 | 1–2 天 |

## 12. 风险与应对

| 风险 | 影响 | 应对 |
|---|---|---|
| pivot / 附着点标定不准 | 运动学失真，肌肉长度方向错误 | 校准工具 + 用长度单调性单元测试兜底 |
| BodyParts3D 轴向、单位不明确 | 场景朝向与剖面轴错误 | M0 实测确认，写入 manifest 并加断言 |
| 韧带或部分结构网格缺失 | 结构集不完整 | 缺失项以标注点替代，并在数据中标记 |
| 网格存在孔洞、非流形、内部面 | 视觉瑕疵、裁剪异常 | 预处理去重、去退化面、可选补洞；不要求封闭流形 |
| CC BY-SA 2.1 JP 的传染性 | 衍生数据再分发受限 | 保持署名；发布前核对官方当前许可；不开源商业闭源计划 |
| 透明 + 裁剪的渲染伪影 | 教学观感受影响 | alphaHash、按层排序；接受空心剖面 |

## 13. 许可与部署

- 解剖数据：BodyParts3D / DBCLS，按对应版本官方许可署名（当前资料标注为 CC BY-SA 2.1 JP；Human Atlas 声称 2025-02-27 更新为 CC BY 4.0，发布前以官方文本为准）。
- 参考实现代码（human-atlas 等）为 MIT，仅作架构参考，不直接复制大段代码。
- 部署：静态 SPA，模型与 JSON 放静态托管/CDN；学习进度与测验记录存 IndexedDB/localStorage；无后端。
- 当前 R 学习仓库仅保留 `resources/` 资源索引，不存放 3D 应用代码或网格数据。

## 14. 后续演进（不在 MVP 内）

1. 肌肉外观从示意管升级为 Blender 烘焙 blendshape，按关节角度插值。
2. 增加前臂旋前/旋后第二自由度。
3. 复制到腕、膝、肩等区域，验证数据层可扩展性。
4. 若需要碰撞与软组织，再评估物理引擎或 FEM，而不是提前引入。
