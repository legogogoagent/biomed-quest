# 肘与前臂交互式 3D 解剖学习器：设计文档

- 日期：2026-11-04
- 状态：已按多轮外部 review 更新（P0 + P1），并纳入双轴（屈伸 + 旋前/旋后）与剖面封盖；待用户复核
- 目标仓库：独立新建 Web 项目（暂定 `elbow-atlas`），不并入当前 R 学习仓库
- 数据来源：BodyParts3D 4.0（官方 99% 减面版，FMA ID 为主键）
- 数据许可：CC BY 4.0（DBCLS 官方归档，2025-02-27 更新）
- 技术栈：React + TypeScript + Vite、Three.js + React Three Fiber、drei OrbitControls

## 1. 背景与目标

医学生需要理解“结构 + 运动 + 毗邻关系”，而静态图谱无法展示关节活动时肌肉长度的动态变化。本项目做一个浏览器内、可静态部署的肘与前臂交互式解剖学习器，用一个区域把“结构浏览、关节约束、肌肉长度反馈、点选识别、断层迁移”做透，再决定是否扩展到其他区域。

核心假设：**用一份可人工维护的约束数据（关节枢轴、活动范围、肌肉附着点），就能在纯运动学场景图中做出解剖学上可信、可测试、可扩展的交互，而不需要物理引擎。**

产品定位（review 修正）：**这是一门课程里的肘部学习模块，不是全身解剖图谱。** 3D 本身不保证优于 2D 教学；价值来自任务化练习、关系理解、断层迁移和间隔复习。与 Complete Anatomy、Visible Body、Z-Anatomy 竞争的不是覆盖广度，而是“关节约束 + 肌肉长度 + 临床情景 + 教师可布置”的深度。

## 2. 非目标

- 不做全身 3D 图谱；不追求覆盖 3,000+ BodyParts3D 网格。
- 不使用物理引擎做碰撞、软组织 FEM、蒙皮或弹簧-质点仿真。
- 不做肩关节与腕关节自由度；MVP 做肘屈伸 + 前臂旋前/旋后两个自由度。
- 不做研究级生物力学：不计算肌力、力矩、肌纤维长度或激活水平。
- 不做通用碰撞检测与穿模修正。
- 不做账号、班级、教师看板、后端数据库。
- 不做移动端优先；桌面浏览器为主，触摸仅保证可用。
- 不做爆炸视图（区域规模小，教学收益低）。
- 不把 BodyParts3D 原始或衍生网格提交进当前仓库。
- 不覆盖女性模型、体型差异或解剖变异（官方数据只有单一成年男性）。

## 3. 数据来源与许可（已核实）

### 3.1 选择官方 4.0，不追 4.3

| 事实 | 结论 |
|---|---|
| 官方批量数据 | 只有 **4.0 / 99% 减面**：`isa_BP3D_4.0_obj_99.zip`（136 MB）、`partof_BP3D_4.0_obj_99.zip`（62 MB），OBJ 格式 |
| 官方许可 | **CC BY 4.0**，2025-02-27 更新；允许访问、再分发、衍生和商用 |
| 4.3 可得性 | **没有官方批量下载**；仅有 2026-09 的 Zenodo 第三方抓取（3,210 网格），来源与许可需逐件核验 |
| 模型范围 | 单一成年男性；无女性、体型或变异 |
| 数据结构 | 只有 ELEMENT（原子器官）有网格；COMPOUND（复合器官）需用 `isa_element_parts.txt` / `partof_element_parts.txt` 从 ELEMENT 拼出 |

**决策**：MVP 使用官方 4.0 99% 减面版。20–30 个网格的规模下，减面精度足够；个别近景结构以后可从 4.3 单件替换，但必须逐件记录来源与许可。Z-Anatomy 不作为基础数据（FMA 覆盖不完整、CC BY-SA 4.0），仅作为 Blender 手工 rig 的参考。

### 3.2 署名与衍生

- 必须使用官方署名：`BodyParts3D, © The Database Center for Life Science licensed under CC Attribution 4.0 International`。
- 必须链接 CC BY 4.0 许可，并注明“本项目对网格进行了裁剪、合并、减面和坐标归一化”。
- 若混入 4.3 或 Z-Anatomy 数据，该部分按其 CC BY-SA 条款处理，并与 4.0 数据分目录、分清单记录。
- 预处理清单必须记录：源 URL、版本、下载日期、原始 element file ID、修改步骤、许可。

### 3.3 预处理管线

1. 下载官方 `isa_BP3D_4.0_obj_99.zip`、`isa_parts_list_e.txt`、`isa_element_parts.txt`、`isa_inclusion_relation_list.txt`。
2. 用 FMA concept id 匹配教学结构；对 COMPOUND 结构查 `element_parts`，得到构成它的 ELEMENT file ID。
3. 导入选中的 OBJ，按教学结构合并 ELEMENT（一个教学结构最终一个 mesh）。
4. 清理：去重复顶点、去退化面、统一法线；不要求封闭流形。
5. 坐标归一化：统一为 Y-up、米制，模型靠近原点；固定解剖轴映射（X 左右、Y 上下、Z 前后）并写入 manifest。
6. 计算 centroid、AABB、三角面数、体积。
7. 导出 GLB（Draco 或 meshopt 压缩），生成 manifest 与全部数据 JSON。
8. 构建期用 zod 校验；不合法直接 fail build。

## 4. 结构集（肘 + 前臂，15–30 个可选网格）

| 类别 | 结构 |
|---|---|
| 骨骼 | 肱骨、桡骨、尺骨 |
| 上下文骨骼（不可选，仅剪影） | 肩胛骨、手骨 |
| 主要肌肉（参与长度反馈） | 肱二头肌（长头、短头）、肱肌、肱三头肌（长头、外侧头、内侧头） |
| 辅助肌肉 | 肱桡肌、旋前圆肌、旋前方肌、旋后肌 |
| 神经 | 正中神经、尺神经、桡神经、肌皮神经 |
| 血管 | 肱动脉、桡动脉近端、尺动脉近端 |
| 韧带/膜 | 尺侧副韧带、桡侧副韧带、环状韧带、骨间膜（若数据集无对应网格，则以标注点代替并标记） |
| 皮肤/皮下 | 上臂与前臂皮肤，可作为可剥离层 |

**FMA ID 规则**：所有 ID 从官方 `isa_parts_list_e.txt` 与 `element_parts` 表匹配并人工核对，禁止凭记忆填写。预处理脚本生成候选映射，人工确认后写入 `structures.json`。

**解剖完整性要求**：肱二头肌必须分长头/短头两条路径；肱三头肌显示三头，但长度反馈可用一条共同鹰嘴路径；肱肌必须参与长度反馈，避免“二头肌是唯一屈肘肌”的错误印象。

## 5. 用户流程与教学模式

### 5.1 模式划分（一次只做一件事）

| 模式 | 主要任务 | 默认显示 |
|---|---|---|
| Explore | 旋转、缩放、图层剥离、点选识别 | 半透明皮肤 + 骨骼 |
| Move | 拖动屈伸 + 前臂旋转，观察肌肉路径长度反馈 | 骨骼 + 二头/三头 + 肱肌 + 旋转肌 |
| Section | 三轴剖面、断层定位 | 骨骼 + 目标结构 |
| Identify | 结构识别测验 | 隐藏标签与皮肤 |
| Quiz | 功能/关系/断层/临床题 | 按题目配置 |

首次进入先做 30 秒 pre-training：骨 → 关节 → 肌肉 → 神经血管，并提示“本工具为教学近似，非临床诊断”。

### 5.2 Move 模式主循环

1. 拖动前臂或使用滑杆，肘关节在活动范围内屈伸。
2. 使用第二个滑杆或旋转手柄，前臂在旋前/旋后范围内旋转；两轴可独立组合。
3. 肱二头肌、肱肌随屈曲缩短；肱三头肌被动拉长。
4. 前臂旋转在固定肘角下也会改变肱二头肌路径长度：旋前位较长、旋后位较短；UI 要明确显示这一现象。
5. 实时显示两个角度、各肌肉路径长度、相对静息长度的百分比，并高亮当前主动肌。
6. 一行因果解释：“屈肘时肱二头肌与肱肌路径缩短，肱三头肌路径拉长；旋后时肱二头肌路径进一步缩短。”
7. 到达任一 ROM 边界时显示“已达解剖极限”，不静默卡住。

### 5.3 Explore / Section 模式

- 图层开关 + 透明度滑杆剥离皮肤、肌肉、神经血管。
- 点选结构 → 信息卡：中文名、英文名、拉丁名、FMA ID、系统、毗邻结构、一句临床联系。
- 剖面滑杆 + 三轴预设 + flip；选中结构时在对应断层上同步高亮（“Find in section”）。
- 剖面用于方向定位与断层迁移，不宣称等同真实影像。

### 5.4 临床情景（Quiz 模式）

至少实现 4 个：

1. 肱骨髁上骨折：肱动脉、正中神经。
2. 肱骨干骨折：桡神经。
3. 肘管综合征：尺神经。
4. 远端肱二头肌腱断裂：肱二头肌止点与屈肘/旋后功能。
5. 旋前圆肌综合征：正中神经在旋前圆肌两头的走行。

### 5.5 测验层级

| 层级 | 题型 | 示例 |
|---|---|---|
| L1 识别 | 给名称点结构 | 指出肱肌 |
| L2 功能 | 选择作用/支配 | 哪块肌肉主要屈肘？哪块肌肉完成旋后？ |
| L3 关系 | 毗邻/走行 | 桡神经在肱骨何处走行？ |
| L4 断层 | 在剖面中定位 | 在横断面上指出正中神经 |
| L5 临床 | 短情景 | 髁上骨折最易损伤哪条血管？ |

进度记录不只存“完成”，还存 `last_seen`、`attempts`、`accuracy`、`response_time`、`error_type`、`next_review`，用于间隔复习。

## 6. 关节约束与解剖近似

### 6.1 关节定义

MVP 采用两个独立自由度：

**A. 肘屈伸（hinge）**

- 角度定义：0° 为完全伸直，正方向为屈曲。
- **旋转轴**：不取全局 X，而取**肱骨内外上髁连线（transepicondylar axis）**；pivot 放在滑车/肱骨小头区域，略偏内外上髁连线远端。
- **默认 ROM**：屈曲 0–145°，过伸下限 −5°；可配置。
- **群体范围**：屈曲约 130–154°，过伸约 −6° 至 +11°；UI 必须说明个体差异，避免把变异当病理。

**B. 前臂旋前/旋后（rotation）**

- 旋转轴：**桡骨头中心 → 尺骨头中心**的连线（近似桡尺远侧关节轴）；pivot 放在桡骨头中心。
- 建模方式：**尺骨近似固定，桡骨绕该轴旋转**；手部若作为上下文加载，跟随桡骨。
- 角度定义：0° 为中立位（拇指向上）；正方向为**旋后**，负方向为**旋前**。
- 默认 ROM：−85°（旋前）至 +85°（旋后）；群体范围约 75–85° 各方向，可配置。
- 旋转轴随肘屈伸一起运动：`radiusRotationPivot` 必须挂在已屈伸的前臂组内，不能留在世界坐标。

**C. 两轴组合**

- 屈伸与旋转可独立组合；先应用屈伸，再在前臂局部应用旋转。
- 旋转不改变肱尺关节的屈伸轴；但会改变桡骨、肱二头肌止点与肱桡肌止点的世界位置。

**携带角**：教材常见约 6–15°，按测量方法有差异。若 BodyParts3D 原始网格已保留解剖静息姿态，则**保留网格自带的对线，不额外旋转**；只有当前臂被预处理摆直时，才用测量值恢复。无论哪种情况，都不把携带角加到任一旋转轴上。

**越界行为**：任一轴越界都 clamp 到边界并提示。

### 6.2 必须标注的近似

- 肘关节是 trochoginglymoid 复合关节：屈伸 + 前臂旋转 + 携带角；MVP 已实现屈伸与旋转，但仍是简化模型。
- 真实旋前/旋后发生在近侧与远侧桡尺关节，尺骨也有轻微运动；MVP 近似为“桡骨绕固定尺骨旋转”。
- 骨间膜、环状韧带与韧带被动张力未做物理仿真；旋转 ROM 由数据 clamp，不是仿真结果。
- 瞬时旋转轴在 ROM 中会变化；固定轴是教学近似。
- 肩关节固定；二头肌与三头肌长头跨肩，肩位会改变其长度。
- 肌长为“近似肌腱-肌腹路径长度”，不是肌纤维长度、不是生理肌长、不能推出肌力。
- 单一男性模型，不代表人群差异。

## 7. 技术架构

独立新仓库，单 Vite 应用内分三层，不做 monorepo：

```text
elbow-atlas/
├─ public/assets/elbow/      # 构建产物：GLB + 核心 JSON + 剖面 cap 网格
├─ data-src/                 # 人工维护 YAML：structures / joints / attachments / clinical / quiz
├─ scripts/preprocess/       # OBJ → COMPOUND 解析 → 清理 → 合并 → GLB → manifest
├─ src/
│  ├─ core/                  # 框架无关 Three.js：scene、loader、rig、picker、clipping
│  ├─ data/                  # 构建期生成并通过 zod 校验的 JSON
│  └─ ui/                    # React + R3F：模式、面板、图层、测验、本地进度
└─ tests/                    # Vitest 单元测试 + Playwright E2E
```

分层约束：

- `core/` 不 import React，可单独测试与复用。
- Three.js 对象放 refs；React 只管理 UI 状态，避免每帧 reconciliation。
- 运动状态源是两个标量：`elbowFlexionAngle` 与 `forearmRotationAngle`；滑杆与拖拽都写它们。

## 8. 渲染、拾取、透明与剖面

### 8.1 渲染与拾取

- **每个教学结构一个 mesh**；20–30 个 draw call 无压力，换取独立选择、透明度、裁剪和变换。
- **拾取用 Raycaster**：显式传入可选 mesh 数组，不使用 `scene.children` 递归；`pointerdown/up` 位移小于阈值才判定点击。
- 拾取必须过滤：不可见、不可选、透明度低于阈值、以及**被裁剪平面切掉**的交点（`plane.distanceToPoint(hit.point) >= 0`）。
- 鼠标坐标转 NDC 时注意 Y 轴方向；高频 hover 需节流。
- 默认不透明渲染；选中结构使用 ghost 材质；只有多结构同时半透明时才使用 `alphaHash`。
- 明确 `renderOrder`：不透明解剖 → 透明/ghost → 标注 → 剖面覆盖层。
- 不使用透明度作为拾取依据。

### 8.2 剖面与封盖

- 全局 `renderer.localClippingEnabled = true`；每个材质持有 `clippingPlanes`。
- 裁剪平面定义在**解剖/模型局部坐标系**，提供 flip；模型靠近原点并使用合理 near/far，避免深度精度问题。
- **不再接受空心剖面作为最终方案**。优先级：
  1. 运行时 **stencil cap**：对当前活动平面生成封盖，支持任意偏移。
  2. 若 stencil 在透明/多材质下不稳定，退化为**三个标准面预生成 cap 网格**（矢状/冠状/横断），滑块只在这些离散位置吸附。
- 剖面 UI 与结构选择联动：选中结构时在断层上高亮同名结构，支持“Find in section”练习。
- 明确文案：剖面是教学示意，不是 MRI/CT 重建。

### 8.3 肌肉长度可视化

- MVP 用附着点之间的示意管 + 数值，不声称真实肌腹形变。
- 示意管使用独立材质，避免与真实肌肉网格混淆。
- 后续可替换为 Blender 烘焙的 blendshape，按角度插值。

## 9. 数据模型

### 9.1 `structures.json`

```jsonc
{
  // 字段示例；fma_id / 坐标 / 统计值由预处理与官方 parts_list 匹配生成
  "fma_id": "FMA00000",
  "slug": "humerus_right",
  "names": { "zh": "肱骨", "en": "Humerus", "la": "Humerus" },
  "system": "skeletal",
  "region": "upper_limb",
  "laterality": "right",
  "selectable": true,
  "contextOnly": false,
  "mesh": "humerus_right.glb",
  "source": {
    "dataset": "BodyParts3D",
    "version": "4.0",
    "elementFileIds": ["FMA00000"],
    "license": "CC BY 4.0",
    "retrieved": "2026-11-04",
    "modifications": ["merged elements", "normalized", "decimated"]
  },
  "centroid": [0.0, 0.0, 0.0],
  "bbox": { "min": [0, 0, 0], "max": [0, 0, 0] },
  "tris": 12000,
  "neighbors": ["FMA00001"],
  "clinical": "一句临床联系"
}
```

### 9.2 `joints.json`

```jsonc
{
  "id": "elbow_right",
  "type": "compound",
  "parent": "humerus_right",
  "childGroup": "forearm_right",
  "flexion": {
    "type": "hinge",
    "axisLandmarks": {
      "medialEpicondyle": [0.0, 0.0, 0.0],
      "lateralEpicondyle": [0.0, 0.0, 0.0]
    },
    "pivot": [0.0, 0.0, 0.0],
    "restAngle": 0.0,
    "limits": { "min": -5.0, "max": 145.0 },
    "populationRange": { "flexion": [130, 154], "extension": [-6, 11] },
    "positive": "flexion"
  },
  "rotation": {
    "type": "radius_about_ulna",
    "axisLandmarks": {
      "radialHeadCenter": [0.0, 0.0, 0.0],
      "ulnarHeadCenter": [0.0, 0.0, 0.0]
    },
    "pivot": [0.0, 0.0, 0.0],
    "limits": { "min": -85.0, "max": 85.0 },
    "populationRange": { "pronation": [75, 85], "supination": [75, 85] },
    "positive": "supination",
    "neutral": "thumb_up"
  },
  "carryingAngleDeg": 8.0,
  "carryingAngleMode": "preserve_mesh_rest",
  "approximation": true
}
```

- 两个 `axis` 在加载时由 landmark 计算并归一化，不手填。
- `pivot`、landmark 均存对应父骨的局部坐标。
- `rotation` 轴挂在屈伸后的前臂局部空间，随肘屈伸运动。
- 正方向约定：屈伸正方向为屈曲；旋转正方向为旋后。左右侧若出现符号相反，按侧别在数据中翻转轴方向，不硬编码。 

### 9.3 `attachments.json`

```jsonc
{
  "muscle": "biceps_brachii_right",
  "pathLabel": "approximate musculotendinous path length",
  "heads": [
    {
      "name": "long_head",
      "origin":    { "bone": "scapula_right", "p": [0.0, 0.0, 0.0] },
      "via":       [{ "bone": "humerus_right", "p": [0.0, 0.0, 0.0] }],
      "insertion": { "bone": "radius_right",  "p": [0.0, 0.0, 0.0] },
      "note": "起自盂上结节，止于桡骨粗隆"
    },
    {
      "name": "short_head",
      "origin":    { "bone": "scapula_right", "p": [0.0, 0.0, 0.0] },
      "via":       [{ "bone": "humerus_right", "p": [0.0, 0.0, 0.0] }],
      "insertion": { "bone": "radius_right",  "p": [0.0, 0.0, 0.0] },
      "note": "起自喙突，止于桡骨粗隆"
    }
  ],
  "restLength": 0.0,
  "teachingNote": "肩固定前提下：屈肘缩短；同一肘角下，旋前位较长、旋后位较短"
}
```

- 肱二头肌止点在桡骨粗隆，必须随桡骨旋转而移动；这正是“固定肘角下旋转前臂会改变二头肌路径长度”的来源。
- 肱三头肌：`heads` 记录长头/外侧头/内侧头的视觉与起点信息；长度反馈使用一条共同鹰嘴路径（止点在尺骨，受前臂旋转影响小）。
- 肱肌：独立路径，起自肱骨前面下半，止于尺骨粗隆/冠突。
- 旋前圆肌、旋前方肌、旋后肌：用于旋转功能教学与测验；可选参与长度反馈，但必须标注为近似路径。
- 所有 `via` 固定到肱骨；禁止挂到桡/尺骨或世界坐标。止点按解剖挂在桡骨或尺骨，随对应骨运动。

### 9.4 其他数据

- `clinical.json`：结构 → 损伤/查体/影像要点。
- `quiz.json`：L1–L5 题目、选项、答案、解析、关联结构。
- `progress`（localStorage）：按 slug 记录 `last_seen`、`attempts`、`accuracy`、`response_time`、`error_type`、`next_review`。

## 10. 约束与肌肉长度实现

### 10.1 场景图与枢轴

BodyParts3D 网格顶点位于统一世界坐标。绑定方式：

```text
scene
└─ humerus mesh
└─ flexionPivot  (position = elbowPivot, quaternion 对齐到 transepicondylar axis)
   └─ carryingAngleGroup (通常为 identity；仅当前臂被预处理摆直时用于恢复携带角)
      └─ forearmOffset (position = -elbowPivot)
         ├─ ulna mesh
         ├─ radiusPivot (position = radialHeadCenter, quaternion 对齐到桡尺旋转轴)
         │  └─ radiusOffset (position = -radialHeadCenter)
         │     └─ radius mesh
         └─ hand context（跟随桡骨）
```

- 0° 时几何位置不变：`flexionPivot` 与 `forearmOffset` 的平移互相抵消；`radiusPivot` 与 `radiusOffset` 的平移互相抵消。
- 旋转 `flexionPivot` 即严格绕肘 pivot 旋转；旋转 `radiusPivot` 即让桡骨绕桡尺轴旋转，尺骨保持近似固定。
- 若网格保留原始静息姿态，`carryingAngleGroup` 保持 identity，避免重复施加携带角。
- 手部作为上下文时跟随桡骨；若不加载手部，在信息卡中说明“腕与手不在本模型内”。

### 10.2 附着点变换与路径长度

- 附着点以骨骼局部坐标存储。
- 运行时位置 = `bone.matrixWorld × localPoint`。
- 路径长度 = `|origin→via₁| + |via₁→via₂| + … + |viaₙ→insertion|`。
- 相对变化 = `(L − L_rest) / L_rest`。
- UI 标签固定为“近似肌腱-肌腹路径长度”，不写“肌肉长度”。
- 使用 via point 的原因：二头肌绕过肘前方、三头肌绕过鹰嘴后方；直连会穿骨并得到错误曲线。
- 肱二头肌止点挂在桡骨，因此会随 `radiusPivot` 旋转；肱三头肌止点挂在尺骨，受前臂旋转影响小。

### 10.3 预期行为与前提

在**肩固定、屈曲 0–140°、旋转 −85° 至 +85°**的范围内：

- 前臂中立位时：肱二头肌长头、短头、肱肌路径长度随屈曲单调下降；肱三头肌共同路径长度随屈曲单调上升。
- 固定肘角（如 90°）时：从旋后位转到旋前位，肱二头肌路径长度增加；从旋前位转到旋后位，肱二头肌路径长度减少（旋前位较长、旋后位较短）。
- 旋转过程中肱三头肌共同路径长度只允许小幅变化，不应出现与屈伸同量级的跳变。
- 不允许突变、反转或接近零长度的线段。
- 旋转过程中桡骨与尺骨不得出现明显穿插；若出现，优先检查旋转轴与 pivot。

若方向相反，优先检查：止点是否挂错骨、via 是否挂到前臂、旋转轴符号是否反、左右侧方向是否翻转、静息姿态是否与标定姿态一致。

### 10.4 拖拽角度计算

**屈伸**：

1. 指针射线与“过肘 pivot、法线为肱尺轴”的平面求交。
2. 交点在平面内相对 pivot 的方向与静息方向求有符号角。
3. clamp 到 `flexion.limits` 后写回 `elbowFlexionAngle`。

**前臂旋转**：

1. 指针射线与“过桡骨头中心、法线为桡尺轴”的平面求交。
2. 交点在平面内相对 pivot 的方向与中立位方向求有符号角。
3. clamp 到 `rotation.limits` 后写回 `forearmRotationAngle`。

**交互约束**：

- Move 模式提供“屈伸 / 旋转”手柄或分段选择器，避免同一拖拽同时改两个轴。
- 拖拽任一轴时禁用 OrbitControls，`pointerup` 后恢复。
- 两个滑杆始终可见，允许精确输入与键盘操作。

## 11. 教学设计与评估

### 11.1 设计原则

- 一次一个主任务；用模式切换降低外在认知负荷。
- 标签与信息卡靠近被选结构；同一时间只高亮当前主动肌。
- 允许学习者控制节奏；先骨/关节，再肌肉，再神经血管。
- 不把“3D”当卖点；卖点是可操作的关系、约束反馈和临床迁移。

### 11.2 检索与反馈

- 测验以回忆为主，不用高亮目标做提示。
- 错误反馈：并排显示“你选的”和“正确的”，给一条关系线索，要求稍后重试。
- 记录 `next_review`，按 1 天 / 3 天 / 7 天 / 14 天安排复习。
- 每次会话结束提供 60 秒 explain-back：“把肘屈到 90°，解释为什么二头肌缩短、三头肌拉长；再保持 90° 旋前/旋后，解释二头肌路径为什么变化。”

### 11.3 评估指标

| 维度 | 指标 |
|---|---|
| 识别 | 20 题前后测准确率 |
| 空间关系 | “肱二头肌腱内侧是什么”类题目 |
| 功能推理 | 预测 0/45/90/120° 屈曲、以及固定 90° 下旋前/旋后时肌肉路径长度变化方向 |
| 断层迁移 | 在示意断面上定位结构 |
| 临床迁移 | 4 个肘部情景短答题 |
| 保留 | 1 周 / 4 周平行测验 |
| 认知负荷 | NASA-TLX |
| 可用性 | SUS |

## 12. 校准工具

M1 交付一个仅开发环境可用的标定模式：

- 在网格表面点击取点，输出世界坐标与所属骨骼局部坐标。
- 依次采集：内/外上髁、肘 pivot、桡骨头中心、尺骨头中心、各肌肉 origin/via/insertion。
- 输入当前屈曲角与旋转角，实时预览路径长度与桡骨位置。
- 一键导出 `joints.yaml` / `attachments.yaml` 草稿。
- 内置校验：路径是否穿骨、长度是否随屈曲单调、固定肘角下旋转时二头肌方向是否正确、桡骨/尺骨是否明显穿插、是否出现零长度段。

理由：pivot 与 20+ 附着点的手工标定是最容易返工的环节；工具成本远低于反复试错。

## 13. 异常处理

- 构建期 zod 校验全部数据 JSON，不合法直接 fail build。
- 单个 GLB 加载失败：列表中置灰，不影响其他结构；记录明确错误。
- WebGL 不可用或 context lost：提示并提供重载按钮。
- 角度越界：clamp 并给出“已达解剖极限”提示。
- localStorage 不可用：降级为内存态，并提示进度不会保存。
- 剖面 stencil 失败：自动降级为三标准面 cap，并提示。

## 14. 测试与验收

### 14.1 单元测试（Vitest）

- 上髁两点 → 归一化屈伸轴；桡骨头/尺骨头两点 → 归一化旋转轴；pivot 局部坐标变换。
- 两个轴的 clamp 与有符号角换算。
- 指针射线到两个关节角的映射。
- 附着点随 `matrixWorld` 变换的正确性。
- **屈曲单调性**：肩固定、前臂中立位下，屈曲增大时二头肌长头/短头、肱肌下降，三头肌上升。
- **旋转方向性**：固定 90° 屈曲，从旋后转向旋前时二头肌路径长度增加；从旋前转向旋后时减少。
- 旋转时三头肌共同路径长度变化幅度显著小于二头肌。
- 路径不穿骨与桡尺骨不穿插（抽样屈曲 0/45/90/135°，旋转 −85/0/+85°）。
- 数据 schema 与来源字段校验。

### 14.2 E2E（Playwright）

- 加载区域资源，首屏无报错。
- 拖动前臂：屈曲角始终在 ROM 内；到达边界出现提示。
- 拖动旋转手柄：旋前/旋后角始终在 ROM 内；桡骨可见旋转。
- 两轴组合：同一组（屈曲角，旋转角）无论用户先调哪个滑杆，最终姿态一致且无跳变。
- 点击结构：信息卡名称与 FMA ID 正确。
- 图层开关与透明度生效。
- 剖面封盖可见，滑块与 flip 正常。
- 测验五级流程与进度写入。
- 关键机位截图回归。

### 14.3 验收标准

- 任意拖动下两个关节角都不越界；屈曲与旋转时的肌肉路径长度变化方向正确。
- 固定肘角旋转前臂时，二头肌路径长度按“旋前较长、旋后较短”变化。
- 区域内首屏资源 < 10 MB；中端笔记本 ≥ 50 fps。
- 25 个左右结构点选命中准确，无拖拽误触；裁剪后的结构不会被误选。
- 剖面有封盖，不出现空心内壁作为最终教学画面。
- 全部数据 JSON 通过 schema 校验；单元测试全部通过。
- UI 明确标注“教学近似，非临床诊断；单一男性模型；桡尺旋转为桡骨绕固定尺骨的近似”。

## 15. 里程碑与试点

| 阶段 | 交付物 | 预计 |
|---|---|---|
| Gate 0 | 找到 1 门真实课程/教师伙伴；确认数据、许可、评估方式 | 1 周（可与开发并行） |
| M0 | 新 repo、官方 4.0 子集预处理为 GLB、场景 + OrbitControls + Raycast | 1–2 天 |
| M1 | 全区域网格、图层/透明度、信息卡、校准工具 | 2–3 天 |
| M2 | 双轴 rig（屈伸 + 桡尺旋转）+ 双 ROM + 拖拽/滑杆 + 二头/三头/肱肌路径反馈 | 3–4 天 |
| M3 | 剖面封盖 + 五级测验 + 本地进度 + 临床情景 | 3 天 |
| M4 | 触摸、性能、文档、静态部署 | 1–2 天 |
| Pilot | 4 周真实课程试点：必做任务、前后测、延迟测、设备矩阵、教师审核 | 4 周 |

**Go/No-Go（试点后）**：至少满足三条才扩展区域：≥70% 学生完成必做任务；存在一个学生愿意反复使用的肘部任务；前后测/延迟测有可测提升；教师愿意下一轮继续布置。否则不扩全身，优先改成更紧密的课程模块或教学材料。

## 16. 风险与应对

| 风险 | 影响 | 应对 |
|---|---|---|
| pivot / 附着点标定不准 | 运动学失真、路径长度方向错误 | 校准工具 + 单调性/穿骨单元测试 |
| 桡尺旋转轴或方向偏差 | 旋前/旋后相反、肱二头肌长度方向错误 | 用桡骨头/尺骨头 landmark；左右侧符号在数据中翻转；旋转方向性单元测试 |
| 桡骨旋转时与尺骨穿插 | 视觉与教学错误 | 校准阶段抽样检查；必要时微调轴或限制 ROM |
| transepicondylar 轴定位偏差 | 屈伸轨迹与携带角错误 | 用上髁 landmark 计算，不用全局轴；M0 实测 |
| BodyParts3D 轴向、单位不明确 | 场景朝向与剖面轴错误 | M0 实测，写入 manifest 并加断言 |
| COMPOUND/ELEMENT 映射错误 | 结构缺件或重复 | 用官方 `element_parts` 表，人工核对清单 |
| 韧带/部分结构网格缺失 | 结构集不完整 | 以标注点替代，并在数据中标记 |
| 网格孔洞、非流形、内部面 | 视觉瑕疵、裁剪异常 | 去重/去退化面；不要求封闭流形；剖面用 cap 补偿 |
| 剖面 stencil 不稳定 | 断层画面错误 | 自动降级三标准面预生成 cap |
| 透明 + 裁剪伪影 | 观感受影响 | 默认不透明；ghost 单独材质；alphaHash 仅多结构 |
| 许可混用 | 再分发受限 | 4.0 与 4.3/Z-Anatomy 分目录记录；保留署名与修改说明 |
| 课程不采用 | 做出来没人用 | Gate 0 + 4 周试点；先验证教师布置与学生回访 |

## 17. 许可与部署

- 解剖数据：BodyParts3D 4.0，官方 CC BY 4.0；署名使用官方指定字符串，并注明修改。
- 若使用 4.3 单件或 Z-Anatomy：该部分按 CC BY-SA 处理，单独记录。
- 参考实现代码（human-atlas 等）为 MIT，仅作架构参考，不直接复制大段代码。
- 部署：静态 SPA，模型与 JSON 放静态托管/CDN；学习进度与测验记录存 IndexedDB/localStorage；无后端。
- 当前 R 学习仓库仅保留 `resources/` 资源索引，不存放 3D 应用代码或网格数据。

## 18. 后续演进（不在 MVP 内）

1. 肌肉外观从示意管升级为 Blender 烘焙 blendshape，按两个关节角度插值。
2. 加入肩关节自由度，处理二头肌长头与三头肌长头的跨肩长度变化。
3. 加入腕关节自由度，补全手部结构与旋前/旋后的远端效应。
4. 复制到膝、肩等区域，验证数据层可扩展性。
5. 若需要碰撞与软组织，再评估物理引擎或 FEM，而不是提前引入。

## 19. 外部 Review 依据（2026-11-04）

- 官方许可：<https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html>
- 官方下载：<https://dbarchive.biosciencedbc.jp/en/bodyparts3d/download.html>
- 官方 README：<https://dbarchive.biosciencedbc.jp/data/bodyparts3d/LATEST/README_e.html>
- BodyParts3D 4.3 第三方归档：<https://zenodo.org/records/22727173>（webfetch 被 Cloudflare 拦截，未独立核验）
- Z-Anatomy：<https://github.com/Z-Anatomy/Models-of-human-anatomy>
- 肘关节解剖与 ROM：
  - StatPearls, Anatomy, Shoulder and Upper Limb, Elbow Joint：<https://www.ncbi.nlm.nih.gov/books/NBK532948/>
  - Radiopaedia, Elbow：<https://radiopaedia.org/articles/elbow>
  - Elbow ROM 常模研究：<https://pmc.ncbi.nlm.nih.gov/articles/PMC6555111/>
  - Neumann《Kinesiology of the Musculoskeletal System》
- 3D 解剖教学与检索练习：
  - 3D 与 2D 解剖教学比较：<https://pmc.ncbi.nlm.nih.gov/articles/PMC12159242/>
  - 检索练习：<https://pmc.ncbi.nlm.nih.gov/articles/PMC6842879/>
  - Mayer 多媒体学习原则：<https://link.springer.com/article/10.1186/s40561-022-00200-2>
- 竞争与采用：Complete Anatomy、Visible Body、Z-Anatomy 公开资料
