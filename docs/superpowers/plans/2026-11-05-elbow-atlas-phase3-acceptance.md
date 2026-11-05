# Phase 3：形变、切面交互、验收与部署记录

- 日期：2026-11-05
- 状态：已完成并合并到 `elbow-atlas` 的 `master`
- 应用：`/home/aigc/Project/elbow-atlas`
- 部署：Docker + nginx 非 root 容器，`http://localhost:8080/`

## 本轮完成的设计项

1. **真实肌腹形变**
   - `src/core/muscleDeformer.ts`：沿 origin→via→insertion 折线做线性蒙皮，保留顶点参数与垂直偏移。
   - `src/ui/MuscleDeformation.tsx`：Move 模式下替换肱二头肌、肱肌、肱三头肌的静态网格；随屈伸缩短/拉长。
   - 主动肌按“缩短最多”高亮。
   - 明确标注为近似线性蒙皮，不是 FEM 或 Blender blendshape。

2. **前臂旋转中立位**
   - 加入 `rotation.restAngle: -90`：UI 0° = 拇指向上中立位，负值旋前、正值旋后。
   - 真实数据验证：前臂 90° 屈曲时，旋前 0.3206 m > 中立 0.3174 m > 旋后 0.3093 m。

3. **Find-in-section**
   - Section 模式下点击切面结构 → 蓝色高亮 + InfoCard。
   - 从 Explore 选中的结构切换到 Section 后仍保持高亮。
   - 仅可选择 `selectable: true` 的结构；肩胛骨等 context-only 结构不再被选中。

4. **教学反馈与免责声明**
   - Move 模式显示主动肌 teaching note、ROM 极限提示、群体范围提示。
   - 页面常驻免责声明：教学近似、非临床诊断、单一男性模型、桡尺旋转为近似。

5. **进度模型**
   - 新增 `accuracy`、`responseTimeMs`、`errorType`，保留 1/3/7/14 天间隔复习。

6. **构建期数据校验**
   - `scripts/validate-data.ts` 校验 19 structures、1 joint、3 attachments、8 quiz、5 clinical、3 section planes，并检查所有 GLB 存在。
   - `prebuild` 自动执行校验与资产检查。

7. **加载容错**
   - 结构加载改为 `Promise.allSettled`，非关键结构失败只警告；必需骨缺失才报错。
   - Section 加载失败时回退到未切割的解剖视图。
   - WebGL context lost 提示。

8. **部署与 CI**
   - `Dockerfile`：Node 22 构建 → `nginxinc/nginx-unprivileged:1.27-alpine` 运行，非 root（uid 101）。
   - `deploy/nginx.conf`：SPA fallback、gzip、缓存、安全头、`.glb` MIME。
   - `.github/workflows/ci.yml`：Node 22、`npm ci`、测试、构建、Playwright E2E。
   - `deploy/serve-local.sh`：仅绑定 127.0.0.1 的本地兜底服务器。

## 验收结果

| 检查 | 结果 |
|---|---|
| `npm test` | 11 个文件 / **53 tests passed** |
| `npx tsc -b` | 通过 |
| `npm run build` | 通过；prebuild 校验 19 结构/25 资产 |
| `npm run lint` | 0 errors；2 个既有 immutability warning |
| `npm run e2e` | **6/6 passed** |
| Lighthouse（4178） | Accessibility **100**、Best Practices **100**、SEO **100** |
| Docker | 非 root 容器；`/` 200、`humerus_right.glb` 200、`model/gltf-binary` |
| 安全 | `npm audit` 0 vulnerabilities；无 secrets/XSS sink/外部运行时请求 |

## 部署

```bash
docker run -d --name elbow-atlas-final -p 8080:8080 elbow-atlas:final
```

- 本地：`http://localhost:8080/`
- 预览：`http://localhost:4178/`
- 局域网：`http://192.10.10.11:8080/`（如防火墙允许）

## 许可

- 应用代码：MIT（`LICENSE`）。
- BodyParts3D 网格/切面/皮肤裁剪：CC BY 4.0。
- Z-Anatomy 神经网格：CC BY-SA 4.0；衍生物按 CC BY-SA 4.0 分发。
- 详见 `NOTICE` 与 `public/assets/elbow/*ATTRIBUTION.md`。

## 已知限制

- 解剖锚点、ROM、肌肉路径为几何近似，需医学审核；`?calibrate=1` 可人工修正。
- 二头肌/三头肌路径在 0–145° 内已通过真实锚点单调性测试；仍为近似折线，不是真实肌腱滑移/包裹。
- 神经/皮肤为静态网格，Move 模式隐藏；不随肘关节形变。
- Section 只有 3 个标准面，不支持任意偏移实时切面。
- 肌腹形变为线性蒙皮，非 FEM；二头肌短头未单独形变。
- 肌腹与骨在屈曲末端可能存在 <1 cm 的浅表接触/压缩，未做碰撞修正。
- 肱三头肌长头未单独建模；`common_path` 代表三头共同鹰嘴路径。
- Section 相机不会自动对齐切面法线，切面可能以斜视角显示。
- 主 JS chunk 约 1.35 MB（gzip 376 kB），Vite 仍有 >500 kB 警告。
- 性能仅在软件渲染/本机 GPU 环境测过，未做中端笔记本基准。
- 未执行真实 GitHub Actions（仓库无 remote）；工作流已配置并解析通过。

## 生物力学复核与修复（2026-11-05 追加）

由独立“解剖/生物力学”review subagent 在 0/45/90/145° 屈曲、−85/0/+85° 旋转、前/后/内/外视角下检查，发现问题并修复：

| 发现 | 修复 |
|---|---|
| Move 模式 `brachioradialis` 等未形变肌肉仍被钉在桡骨组上，屈肘时甩出/穿过肱骨 | Move 模式隐藏所有未参与形变的原始肌肉，只保留二头/肱肌/三头的形变网格 |
| 从 Move 返回 Explore 时保留屈曲姿态，静态肌肉脱位 | 切到非 Move 模式时自动重置屈曲/旋转为 0 |
| Section 切面没有神经，无法验证神经位置 | `scripts/generate-sections.py` 基于全部非皮肤结构重新生成 6 个切面 GLB，包含 4 条神经 |
| 145° 附近二头肌/三头肌长度反弹 | 用网格扫描重选 via 点；新增 0–145° 单调性测试，二头持续缩短、三头持续拉长 |
| 0° 静止时仍高亮“主动肌” | 静止时不显示主动肌；非零角度高亮当前缩短最多的肌肉 |
| 浅表肌肉-骨接触 | 记录为 <1 cm 近似接触，不做碰撞修正 |
| 三头长头未单独建模 | 数据/README 明确 `common_path` 为共同鹰嘴路径 |

复核结论：**ANATOMICALLY ACCEPTABLE WITH NOTES**；无 gross penetration，主要教学方向正确。

## 明确不在本设计内（新项目/后续）

- 肩、腕自由度与跨肩肌肉长度。
- 膝、肩、全身其他区域。
- 碰撞检测、软组织 FEM、真实 Blender blendshape。
- 任意偏移运行时 stencil cap。
- 完整医学验证、女性/人群变异、临床级神经走行。
- 课程 pilot 的 NASA-TLX/SUS/前后测/延迟测。
