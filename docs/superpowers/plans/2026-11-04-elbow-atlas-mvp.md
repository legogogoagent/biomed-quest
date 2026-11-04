# 肘与前臂 3D 解剖学习器 MVP 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在独立新仓库中实现一个可静态部署的肘与前臂 3D 解剖学习器，支持双轴关节运动、肌肉路径长度反馈、图层剥离、三标准面封盖剖面、五级测验与本地进度。

**Architecture:** 单 Vite 应用内分 `core/`（框架无关 Three.js）、`data/`（zod 校验后的 JSON）、`ui/`（React + R3F）。数据管线在构建前完成：官方 BodyParts3D 4.0 OBJ → 合并/归一化 → GLB + 统计 → 与人工维护 YAML 合并为受校验 JSON。关节是纯运动学场景图，不使用物理引擎。

**Tech Stack:** Node 22+、Python 3.11+、React 19、TypeScript、Vite、Three.js、@react-three/fiber、@react-three/drei、zustand、zod、trimesh、Vitest、Playwright。

---

## 前置约定

- 新仓库建在 `../elbow-atlas`（与当前 `Biomedical` 同级）；当前仓库只保存本计划与设计文档。
- 所有命令默认在 `elbow-atlas/` 下执行。
- 坐标单位统一为米，Y-up；模型靠近原点。
- 所有数据字段使用 camelCase；YAML 源文件也用 camelCase。
- 官方数据只使用 BodyParts3D 4.0 99% 减面版，许可是 CC BY 4.0。

---

## Task 1: 初始化仓库与测试工具链

**Files:**
- Create: `package.json`, `vite.config.ts`, `tests/smoke.test.ts`

- [ ] **Step 1: 创建 Vite React TS 项目**

Run:
```bash
cd ..
npm create vite@latest elbow-atlas -- --template react-ts
cd elbow-atlas
npm install
```

Expected: 生成 `elbow-atlas/`，`npm install` 无报错。

- [ ] **Step 2: 安装运行时与测试依赖**

Run:
```bash
npm install three @react-three/fiber @react-three/drei zustand zod yaml adm-zip
npm install -D vitest @types/three @playwright/test tsx
```

Expected: `package.json` 的 dependencies/devDependencies 出现上述包。

- [ ] **Step 3: 配置 Vitest**

Modify `vite.config.ts`:
```ts
/// <reference types="vitest" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
  },
})
```

Modify `package.json` scripts:
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "test": "vitest run",
    "test:watch": "vitest",
    "e2e": "playwright test",
    "fetch:data": "node scripts/fetch-data.mjs",
    "resolve:parts": "node scripts/resolve-parts.mjs",
    "preprocess": "python3 scripts/preprocess.py",
    "build:data": "tsx scripts/build-data.ts"
  }
}
```

- [ ] **Step 4: 写一个冒烟测试**

Create `tests/smoke.test.ts`:
```ts
import { describe, it, expect } from 'vitest'

describe('toolchain', () => {
  it('runs vitest', () => {
    expect(1 + 1).toBe(2)
  })
})
```

- [ ] **Step 5: 运行测试与构建**

Run:
```bash
npm test
npm run build
```

Expected: `1 passed`；`vite build` 成功输出 `dist/`。

- [ ] **Step 6: 提交**

```bash
git init
git add .
git commit -m "chore: scaffold elbow-atlas with vite react ts and vitest"
```

---

## Task 2: 核心数学函数

**Files:**
- Create: `src/core/math.ts`
- Test: `tests/math.test.ts`

- [ ] **Step 1: 写失败测试**

Create `tests/math.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import * as THREE from 'three'
import {
  clamp,
  axisFromLandmarks,
  signedAngleAroundAxis,
  polylineLength,
} from '../src/core/math'

describe('clamp', () => {
  it('clamps above max', () => {
    expect(clamp(150, -5, 145)).toBe(145)
  })
  it('clamps below min', () => {
    expect(clamp(-20, -5, 145)).toBe(-5)
  })
})

describe('axisFromLandmarks', () => {
  it('returns a normalized axis from two points', () => {
    const axis = axisFromLandmarks(
      new THREE.Vector3(1, 2, 3),
      new THREE.Vector3(1, 2, 5),
    )
    expect(axis.toArray()).toEqual([0, 0, 1])
  })
  it('throws when landmarks coincide', () => {
    expect(() =>
      axisFromLandmarks(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 0, 0)),
    ).toThrow('Landmarks must differ')
  })
})

describe('signedAngleAroundAxis', () => {
  it('returns +90 degrees for x to y around z', () => {
    const angle = signedAngleAroundAxis(
      new THREE.Vector3(1, 0, 0),
      new THREE.Vector3(0, 1, 0),
      new THREE.Vector3(0, 0, 1),
    )
    expect(THREE.MathUtils.radToDeg(angle)).toBeCloseTo(90)
  })
  it('returns -90 degrees for y to x around z', () => {
    const angle = signedAngleAroundAxis(
      new THREE.Vector3(0, 1, 0),
      new THREE.Vector3(1, 0, 0),
      new THREE.Vector3(0, 0, 1),
    )
    expect(THREE.MathUtils.radToDeg(angle)).toBeCloseTo(-90)
  })
})

describe('polylineLength', () => {
  it('sums segment distances', () => {
    const length = polylineLength([
      new THREE.Vector3(0, 0, 0),
      new THREE.Vector3(1, 0, 0),
      new THREE.Vector3(1, 1, 0),
    ])
    expect(length).toBeCloseTo(2)
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
npm test -- tests/math.test.ts
```

Expected: FAIL，提示无法找到 `../src/core/math`。

- [ ] **Step 3: 实现最小代码**

Create `src/core/math.ts`:
```ts
import * as THREE from 'three'

export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max)
}

export function axisFromLandmarks(a: THREE.Vector3, b: THREE.Vector3): THREE.Vector3 {
  const axis = new THREE.Vector3().subVectors(b, a)
  if (axis.lengthSq() === 0) throw new Error('Landmarks must differ')
  return axis.normalize()
}

export function signedAngleAroundAxis(
  from: THREE.Vector3,
  to: THREE.Vector3,
  axis: THREE.Vector3,
): number {
  const f = from.clone().projectOnPlane(axis)
  const t = to.clone().projectOnPlane(axis)
  if (f.lengthSq() === 0 || t.lengthSq() === 0) {
    throw new Error('Vectors must not be parallel to the axis')
  }
  f.normalize()
  t.normalize()
  const cross = new THREE.Vector3().crossVectors(f, t)
  const sin = cross.dot(axis)
  const cos = f.dot(t)
  return Math.atan2(sin, cos)
}

export function polylineLength(points: THREE.Vector3[]): number {
  let total = 0
  for (let i = 1; i < points.length; i += 1) {
    total += points[i].distanceTo(points[i - 1])
  }
  return total
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
npm test -- tests/math.test.ts
```

Expected: 6 passed。

- [ ] **Step 5: 提交**

```bash
git add src/core/math.ts tests/math.test.ts
git commit -m "feat: add joint math helpers"
```

---

## Task 3: 数据 schema 与校验

**Files:**
- Create: `src/data/schema.ts`
- Test: `tests/schema.test.ts`

- [ ] **Step 1: 写失败测试**

Create `tests/schema.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import {
  structureSchema,
  jointSchema,
  attachmentSchema,
  quizItemSchema,
} from '../src/data/schema'

const structure = {
  fmaId: 'FMA00000',
  slug: 'humerus_right',
  names: { zh: '肱骨', en: 'Humerus', la: 'Humerus' },
  system: 'skeletal',
  laterality: 'right',
  selectable: true,
  contextOnly: false,
  mesh: 'humerus_right.glb',
  source: {
    dataset: 'BodyParts3D',
    version: '4.0',
    elementFileIds: ['FMA00000'],
    license: 'CC BY 4.0',
    retrieved: '2026-11-04',
    modifications: ['merged elements'],
  },
  centroid: [0, 0, 0],
  bbox: { min: [0, 0, 0], max: [1, 1, 1] },
  tris: 100,
  neighbors: [],
  clinical: '示例',
}

const joint = {
  id: 'elbow_right',
  type: 'compound',
  parent: 'humerus_right',
  childGroup: 'forearm_right',
  flexion: {
    type: 'hinge',
    axisLandmarks: {
      medialEpicondyle: [0, 0, 0],
      lateralEpicondyle: [1, 0, 0],
    },
    pivot: [0, 0, 0],
    restAngle: 0,
    limits: { min: -5, max: 145 },
    populationRange: { flexion: [130, 154], extension: [-6, 11] },
    positive: 'flexion',
  },
  rotation: {
    type: 'radius_about_ulna',
    axisLandmarks: {
      radialHeadCenter: [0, 0, 0],
      ulnarHeadCenter: [0, 0, 1],
    },
    pivot: [0, 0, 0],
    limits: { min: -85, max: 85 },
    populationRange: { pronation: [75, 85], supination: [75, 85] },
    positive: 'supination',
    neutral: 'thumb_up',
  },
  carryingAngleDeg: 8,
  carryingAngleMode: 'preserve_mesh_rest',
  approximation: true,
}

const attachment = {
  muscle: 'biceps_brachii_right',
  pathLabel: 'approximate musculotendinous path length',
  heads: [
    {
      name: 'long_head',
      origin: { bone: 'scapula_right', p: [0, 0, 0] },
      via: [{ bone: 'humerus_right', p: [0, 0, 0] }],
      insertion: { bone: 'radius_right', p: [0, 0, 0] },
      note: '示例',
    },
  ],
  restLength: 0,
  teachingNote: '示例',
}

describe('schemas', () => {
  it('accepts a valid structure', () => {
    expect(structureSchema.parse(structure)).toBeTruthy()
  })
  it('rejects an invalid system', () => {
    expect(() =>
      structureSchema.parse({ ...structure, system: 'unknown' }),
    ).toThrow()
  })
  it('accepts a valid joint', () => {
    expect(jointSchema.parse(joint)).toBeTruthy()
  })
  it('accepts a valid attachment', () => {
    expect(attachmentSchema.parse(attachment)).toBeTruthy()
  })
  it('accepts a valid quiz item', () => {
    expect(
      quizItemSchema.parse({
        id: 'q1',
        level: 1,
        type: 'click',
        prompt: '指出肱肌',
        answerSlug: 'brachialis_right',
        explanation: '肱肌位于肱二头肌深面。',
      }),
    ).toBeTruthy()
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
npm test -- tests/schema.test.ts
```

Expected: FAIL，提示找不到 `../src/data/schema`。

- [ ] **Step 3: 实现 schema**

Create `src/data/schema.ts`:
```ts
import { z } from 'zod'

export const vec3Schema = z.tuple([z.number(), z.number(), z.number()])
export type Vec3 = z.infer<typeof vec3Schema>

export const systemSchema = z.enum([
  'skeletal',
  'muscular',
  'nervous',
  'vascular',
  'ligament',
  'skin',
])
export type System = z.infer<typeof systemSchema>

export const structureSchema = z.object({
  fmaId: z.string().min(1),
  slug: z.string().min(1),
  names: z.object({
    zh: z.string().min(1),
    en: z.string().min(1),
    la: z.string().min(1),
  }),
  system: systemSchema,
  laterality: z.enum(['right', 'left', 'midline']),
  selectable: z.boolean(),
  contextOnly: z.boolean(),
  mesh: z.string().min(1),
  source: z.object({
    dataset: z.literal('BodyParts3D'),
    version: z.literal('4.0'),
    elementFileIds: z.array(z.string().min(1)).min(1),
    license: z.literal('CC BY 4.0'),
    retrieved: z.string().min(1),
    modifications: z.array(z.string()),
  }),
  centroid: vec3Schema,
  bbox: z.object({ min: vec3Schema, max: vec3Schema }),
  tris: z.number().int().nonnegative(),
  neighbors: z.array(z.string()),
  clinical: z.string(),
})
export type StructureData = z.infer<typeof structureSchema>

const bonePointSchema = z.object({
  bone: z.string().min(1),
  p: vec3Schema,
})

export const attachmentSchema = z.object({
  muscle: z.string().min(1),
  pathLabel: z.string().min(1),
  heads: z
    .array(
      z.object({
        name: z.string().min(1),
        origin: bonePointSchema,
        via: z.array(bonePointSchema),
        insertion: bonePointSchema,
        note: z.string(),
      }),
    )
    .min(1),
  restLength: z.number().nonnegative(),
  teachingNote: z.string(),
})
export type AttachmentData = z.infer<typeof attachmentSchema>

export const jointSchema = z.object({
  id: z.string().min(1),
  type: z.literal('compound'),
  parent: z.string().min(1),
  childGroup: z.string().min(1),
  flexion: z.object({
    type: z.literal('hinge'),
    axisLandmarks: z.object({
      medialEpicondyle: vec3Schema,
      lateralEpicondyle: vec3Schema,
    }),
    pivot: vec3Schema,
    restAngle: z.number(),
    limits: z.object({ min: z.number(), max: z.number() }),
    populationRange: z.object({
      flexion: z.tuple([z.number(), z.number()]),
      extension: z.tuple([z.number(), z.number()]),
    }),
    positive: z.literal('flexion'),
  }),
  rotation: z.object({
    type: z.literal('radius_about_ulna'),
    axisLandmarks: z.object({
      radialHeadCenter: vec3Schema,
      ulnarHeadCenter: vec3Schema,
    }),
    pivot: vec3Schema,
    limits: z.object({ min: z.number(), max: z.number() }),
    populationRange: z.object({
      pronation: z.tuple([z.number(), z.number()]),
      supination: z.tuple([z.number(), z.number()]),
    }),
    positive: z.literal('supination'),
    neutral: z.literal('thumb_up'),
  }),
  carryingAngleDeg: z.number(),
  carryingAngleMode: z.enum(['preserve_mesh_rest', 'restore']),
  approximation: z.boolean(),
})
export type JointData = z.infer<typeof jointSchema>

export const quizItemSchema = z.discriminatedUnion('type', [
  z.object({
    id: z.string().min(1),
    level: z.number().int().min(1).max(5),
    type: z.literal('click'),
    prompt: z.string().min(1),
    answerSlug: z.string().min(1),
    explanation: z.string(),
  }),
  z.object({
    id: z.string().min(1),
    level: z.number().int().min(1).max(5),
    type: z.literal('choice'),
    prompt: z.string().min(1),
    choices: z.array(z.object({ id: z.string(), label: z.string() })).min(2),
    answerId: z.string().min(1),
    explanation: z.string(),
  }),
])
export type QuizItem = z.infer<typeof quizItemSchema>

export const clinicalEntrySchema = z.object({
  slug: z.string().min(1),
  summary: z.string().min(1),
  vignette: z.string().optional(),
})
export type ClinicalEntry = z.infer<typeof clinicalEntrySchema>

export const sectionPlaneSchema = z.object({
  id: z.enum(['sagittal', 'coronal', 'axial']),
  label: z.string().min(1),
  normal: vec3Schema,
  origin: vec3Schema,
})
export type SectionPlane = z.infer<typeof sectionPlaneSchema>

export const meshStatsSchema = z.object({
  slug: z.string().min(1),
  fmaId: z.string().min(1),
  elementFileIds: z.array(z.string().min(1)).min(1),
  centroid: vec3Schema,
  bbox: z.object({ min: vec3Schema, max: vec3Schema }),
  tris: z.number().int().nonnegative(),
})
export type MeshStats = z.infer<typeof meshStatsSchema>
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
npm test -- tests/schema.test.ts
```

Expected: 5 passed。

- [ ] **Step 5: 提交**

```bash
git add src/data/schema.ts tests/schema.test.ts
git commit -m "feat: add anatomy data schemas"
```

## Task 4: 下载官方数据与解析部件 ID

**Files:**
- Create: `scripts/fetch-data.mjs`, `scripts/lib/resolve.mjs`, `scripts/resolve-parts.mjs`
- Test: `tests/resolve.test.ts`

- [ ] **Step 1: 写解析函数的失败测试**

Create `tests/resolve.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { findParts } from '../scripts/lib/resolve.mjs'

const lines = [
  'FMA00001\tFMA00001\tHumerus',
  'FMA00002\tFMA00002\tBiceps brachii',
  'FMA00003\tFMA00003\tTriceps brachii',
]

describe('findParts', () => {
  it('finds case-insensitive substring matches', () => {
    const result = findParts(lines, 'biceps')
    expect(result).toHaveLength(1)
    expect(result[0].en).toBe('Biceps brachii')
  })
  it('returns empty for no match', () => {
    expect(findParts(lines, 'femur')).toEqual([])
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
npm test -- tests/resolve.test.ts
```

Expected: FAIL，找不到 `scripts/lib/resolve.mjs`。

- [ ] **Step 3: 实现解析库**

Create `scripts/lib/resolve.mjs`:
```js
export function parsePartsLines(text) {
  return text
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line) => {
      const [conceptId, representationId, en] = line.split('\t')
      return { conceptId, representationId, en }
    })
    .filter((row) => row.conceptId && row.representationId && row.en)
}

export function findParts(partsOrLines, query) {
  const rows = Array.isArray(partsOrLines)
    ? partsOrLines
    : parsePartsLines(partsOrLines)
  const needle = query.trim().toLowerCase()
  return rows.filter((row) => row.en.toLowerCase().includes(needle))
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
npm test -- tests/resolve.test.ts
```

Expected: 2 passed。

- [ ] **Step 5: 写下载脚本**

Create `scripts/fetch-data.mjs`:
```js
import { mkdir, writeFile } from 'node:fs/promises'
import AdmZip from 'adm-zip'

const BASE = 'https://dbarchive.biosciencedbc.jp/data/bodyparts3d/LATEST'
const OUT = 'external/bodyparts3d'
const FILES = [
  'README_e.html',
  'isa_parts_list_e.txt',
  'partof_parts_list_e.txt',
  'isa_inclusion_relation_list.txt',
  'isa_element_parts.txt',
  'isa_BP3D_4.0_obj_99.zip',
]

await mkdir(OUT, { recursive: true })

for (const name of FILES) {
  const res = await fetch(`${BASE}/${name}`)
  if (!res.ok) throw new Error(`Failed to download ${name}: ${res.status}`)
  const buf = Buffer.from(await res.arrayBuffer())
  await writeFile(`${OUT}/${name}`, buf)
  console.log(`saved ${name} (${buf.length} bytes)`)
}

const zip = new AdmZip(`${OUT}/isa_BP3D_4.0_obj_99.zip`)
zip.extractAllTo(`${OUT}/obj`, true)
console.log('extracted OBJ files to external/bodyparts3d/obj')
```

- [ ] **Step 6: 写 CLI 并运行**

Create `scripts/resolve-parts.mjs`:
```js
import { readFile } from 'node:fs/promises'
import { findParts, parsePartsLines } from './lib/resolve.mjs'

const [, , ...queries] = process.argv
if (queries.length === 0) {
  console.error('Usage: node scripts/resolve-parts.mjs "humerus" "biceps brachii"')
  process.exit(1)
}

const text = await readFile('external/bodyparts3d/isa_parts_list_e.txt', 'utf8')
const parts = parsePartsLines(text)

for (const query of queries) {
  console.log(`\n=== ${query} ===`)
  const matches = findParts(parts, query)
  if (matches.length === 0) {
    console.log('no matches')
    continue
  }
  for (const match of matches) {
    console.log(`${match.conceptId}\t${match.representationId}\t${match.en}`)
  }
}
```

Run:
```bash
npm run fetch:data
node scripts/resolve-parts.mjs humerus "biceps brachii" "radial nerve"
```

Expected: `external/bodyparts3d/obj/` 下有 OBJ；终端打印匹配行，包含 concept id、representation id、英文名。

- [ ] **Step 7: 提交**

```bash
git add scripts tests/resolve.test.ts
git commit -m "feat: download bodyparts3d and resolve part ids"
```

---

## Task 5: 人工数据源与网格预处理

**Files:**
- Create: `data-src/structures.yaml`, `data-src/section-planes.yaml`, `scripts/preprocess.py`
- Output: `public/assets/elbow/*.glb`, `public/assets/elbow/mesh-stats.json`

- [ ] **Step 1: 创建结构清单**

Create `data-src/structures.yaml`。`lookups` 中每个英文名必须与 `scripts/resolve-parts.mjs` 输出中的 `en` 完全一致；先运行解析器确认，再填。4.0 只有“头”级肌肉条目，所以二头肌/三头肌/旋前圆肌用多个 lookups 合并。

```yaml
- slug: humerus_right
  lookups: [right humerus]
  fmaId: ""
  names: { zh: 肱骨, en: Right humerus, la: Humerus }
  system: skeletal
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [scapula_right, radius_right, ulna_right]
  clinical: 肱骨干骨折可损伤桡神经。

- slug: radius_right
  lookups: [right radius]
  fmaId: ""
  names: { zh: 桡骨, en: Right radius, la: Radius }
  system: skeletal
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, ulna_right]
  clinical: 桡骨远端骨折常见，注意桡动脉与正中神经。

- slug: ulna_right
  lookups: [right ulna]
  fmaId: ""
  names: { zh: 尺骨, en: Right ulna, la: Ulna }
  system: skeletal
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, radius_right]
  clinical: 尺骨鹰嘴是肱三头肌止点。

- slug: scapula_right
  lookups: [right scapula]
  fmaId: ""
  names: { zh: 肩胛骨, en: Right scapula, la: Scapula }
  system: skeletal
  laterality: right
  selectable: false
  contextOnly: true
  neighbors: [humerus_right]
  clinical: 肩胛骨为二头肌长头与三头肌长头提供起点。

- slug: biceps_brachii_right
  lookups: [long head of right biceps brachii, short head of right biceps brachii]
  fmaId: ""
  names: { zh: 肱二头肌, en: Right biceps brachii, la: Musculus biceps brachii }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, radius_right, scapula_right]
  clinical: 远端肱二头肌腱断裂会导致屈肘与旋后无力。

- slug: brachialis_right
  lookups: [right brachialis]
  fmaId: ""
  names: { zh: 肱肌, en: Right brachialis, la: Musculus brachialis }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, ulna_right]
  clinical: 肱肌是主要的屈肘肌，位于肱二头肌深面。

- slug: triceps_brachii_right
  lookups: [long head of right triceps brachii, lateral head of right triceps brachii, medial head of right triceps brachii]
  fmaId: ""
  names: { zh: 肱三头肌, en: Right triceps brachii, la: Musculus triceps brachii }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, ulna_right, scapula_right]
  clinical: 肱三头肌长头跨肩，肩位会影响其长度。

- slug: brachioradialis_right
  lookups: [right brachioradialis]
  fmaId: ""
  names: { zh: 肱桡肌, en: Right brachioradialis, la: Musculus brachioradialis }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, radius_right]
  clinical: 肱桡肌在旋前/旋后中立位屈肘最有力。

- slug: pronator_teres_right
  lookups: [humeral head of right pronator teres, ulnar head of right pronator teres]
  fmaId: ""
  names: { zh: 旋前圆肌, en: Right pronator teres, la: Musculus pronator teres }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, radius_right]
  clinical: 旋前圆肌可压迫正中神经。

- slug: pronator_quadratus_right
  lookups: [right pronator quadratus]
  fmaId: ""
  names: { zh: 旋前方肌, en: Right pronator quadratus, la: Musculus pronator quadratus }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [radius_right, ulna_right]
  clinical: 旋前方肌是主要的旋前肌之一。

- slug: supinator_right
  lookups: [right supinator]
  fmaId: ""
  names: { zh: 旋后肌, en: Right supinator, la: Musculus supinator }
  system: muscular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right, radius_right, ulna_right]
  clinical: 旋后肌由桡神经深支支配。

- slug: brachial_artery_right
  lookups: [right brachial artery]
  fmaId: ""
  names: { zh: 肱动脉, en: Right brachial artery, la: Arteria brachialis }
  system: vascular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [humerus_right]
  clinical: 髁上骨折可损伤肱动脉。

- slug: radial_artery_right
  lookups: [right radial artery]
  fmaId: ""
  names: { zh: 桡动脉, en: Right radial artery, la: Arteria radialis }
  system: vascular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [radius_right]
  clinical: 桡动脉是常用的触诊与穿刺血管。

- slug: ulnar_artery_right
  lookups: [right ulnar artery]
  fmaId: ""
  names: { zh: 尺动脉, en: Right ulnar artery, la: Arteria ulnaris }
  system: vascular
  laterality: right
  selectable: true
  contextOnly: false
  neighbors: [ulna_right]
  clinical: 尺动脉参与掌浅弓。
```

- [ ] **Step 2: 创建剖面平面数据**

Create `data-src/section-planes.yaml`。坐标先用 `[0,0,0]`，在 Task 9 校准后替换为肘中心坐标。

```yaml
- id: sagittal
  label: 矢状面
  normal: [1, 0, 0]
  origin: [0, 0, 0]
- id: coronal
  label: 冠状面
  normal: [0, 0, 1]
  origin: [0, 0, 0]
- id: axial
  label: 横断面
  normal: [0, 1, 0]
  origin: [0, 0, 0]
```

- [ ] **Step 3: 写预处理脚本**

Create `scripts/preprocess.py`:
```python
#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

import numpy as np
import trimesh
import yaml

UNIT_SCALE = 0.001
AXIS_ROTATION = np.eye(3)


def read_parts(path: Path):
    parts = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        cols = line.split("\t")
        if len(cols) < 3:
            continue
        concept_id, rep_id, en = cols[0].strip(), cols[1].strip(), cols[2].strip()
        if concept_id and rep_id and en:
            parts[en.lower()] = (concept_id, rep_id)
    return parts


def read_element_parts(path: Path):
    mapping = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        cols = line.split("\t")
        if len(cols) < 3:
            continue
        concept_id, _name, element_id = cols[0].strip(), cols[1].strip(), cols[2].strip()
        if concept_id and element_id:
            mapping.setdefault(concept_id, []).append(element_id)
    return mapping


def resolve_element_ids(entry, parts, element_parts, obj_by_stem):
    concept_ids = []
    element_ids = []
    paths = []
    for lookup in entry["lookups"]:
        key = lookup.lower()
        if key not in parts:
            close = [name for name in parts if key in name][:10]
            raise SystemExit(
                f"{entry['slug']}: lookup '{lookup}' not found. Close matches: {close}"
            )
        concept_id, _rep_id = parts[key]
        ids = element_parts.get(concept_id)
        if not ids:
            raise SystemExit(
                f"{entry['slug']}: no element_parts entry for {concept_id} ({lookup})"
            )
        for element_id in ids:
            matches = [p for stem, p in obj_by_stem.items() if stem == element_id]
            if not matches:
                matches = [
                    p for stem, p in obj_by_stem.items() if stem == f"{element_id}M"
                ]
            if len(matches) != 1:
                raise SystemExit(
                    f"{entry['slug']}: element {element_id} matched {len(matches)} OBJ files"
                )
            concept_ids.append(concept_id)
            element_ids.append(element_id)
            paths.append(matches[0])
    return concept_ids, element_ids, paths


def load_and_merge(paths, slug):
    meshes = []
    for path in paths:
        mesh = trimesh.load(path, process=True, force="mesh")
        if mesh.is_empty:
            raise SystemExit(f"{slug}: empty mesh in {path}")
        meshes.append(mesh)
    merged = trimesh.util.concatenate(meshes)
    transform = np.eye(4)
    transform[:3, :3] = AXIS_ROTATION
    merged.apply_transform(transform)
    merged.apply_scale(UNIT_SCALE)
    merged.merge_vertices()
    merged.update_faces(merged.nondegenerate_faces())
    merged.remove_unreferenced_vertices()
    merged.fix_normals()
    return merged


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--structures", default="data-src/structures.yaml")
    parser.add_argument("--planes", default="data-src/section-planes.yaml")
    parser.add_argument("--data-root", default="external/bodyparts3d")
    parser.add_argument("--out", default="public/assets/elbow")
    parser.add_argument("--only", default=None)
    args = parser.parse_args()

    data_root = Path(args.data_root)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    parts = read_parts(data_root / "isa_parts_list_e.txt")
    element_parts = read_element_parts(data_root / "isa_element_parts.txt")
    obj_dir = data_root / "obj"
    obj_by_stem = {p.stem: p for p in obj_dir.rglob("*.obj")}
    if not obj_by_stem:
        raise SystemExit(f"No OBJ files in {obj_dir}; run npm run fetch:data first")

    structures = yaml.safe_load(Path(args.structures).read_text(encoding="utf-8"))
    planes = yaml.safe_load(Path(args.planes).read_text(encoding="utf-8"))
    stats = {}
    loaded = {}

    for entry in structures:
        if args.only and entry["slug"] != args.only:
            continue
        concept_ids, element_ids, paths = resolve_element_ids(
            entry, parts, element_parts, obj_by_stem
        )
        mesh = load_and_merge(paths, entry["slug"])
        glb_path = out / f"{entry['slug']}.glb"
        mesh.export(glb_path)
        bounds = mesh.bounds
        stats[entry["slug"]] = {
            "slug": entry["slug"],
            "fmaId": "+".join(dict.fromkeys(concept_ids)),
            "elementFileIds": element_ids,
            "centroid": [round(v, 6) for v in mesh.centroid.tolist()],
            "bbox": {
                "min": [round(v, 6) for v in bounds[0].tolist()],
                "max": [round(v, 6) for v in bounds[1].tolist()],
            },
            "tris": int(mesh.faces.shape[0]),
        }
        loaded[entry["slug"]] = mesh
        extent = float(np.linalg.norm(mesh.extents))
        print(
            f"{entry['slug']}: {stats[entry['slug']]['tris']} tris, "
            f"bbox diag {extent:.3f} m"
        )
        if not (0.01 <= extent <= 1.5):
            raise SystemExit(
                f"{entry['slug']}: bbox diagonal {extent:.3f} m looks wrong; "
                "check UNIT_SCALE and AXIS_ROTATION"
            )

    (out / "mesh-stats.json").write_text(
        json.dumps(stats, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    if args.only:
        return

    for plane in planes:
        normal = np.array(plane["normal"], dtype=float)
        origin = np.array(plane["origin"], dtype=float)
        for side, multiplier in (("a", 1.0), ("b", -1.0)):
            scene = trimesh.Scene()
            for slug, mesh in loaded.items():
                sliced = trimesh.intersections.slice_mesh_plane(
                    mesh, normal * multiplier, origin, cap=True
                )
                if sliced.is_empty or sliced.faces.shape[0] == 0:
                    raise SystemExit(f"{plane['id']}/{side}: empty slice for {slug}")
                scene.add_geometry(sliced, node_name=slug, geom_name=slug)
            target = out / f"section-{plane['id']}-{side}.glb"
            scene.export(target)
            print(f"wrote {target}")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: 安装 Python 依赖并验证单根骨**

Run:
```bash
python3 -m pip install trimesh numpy pyyaml
python3 scripts/preprocess.py --only humerus_right
```

Expected: 输出 `humerus_right: ... tris ...`，生成 `public/assets/elbow/humerus_right.glb` 与 `mesh-stats.json`。若 bbox 报错，调整 `UNIT_SCALE` 或 `AXIS_ROTATION` 后重跑。

- [ ] **Step 5: 跑全量预处理**

Run:
```bash
python3 scripts/preprocess.py
```

Expected: 每个结构一个 GLB；生成 `section-sagittal-a.glb`、`-b`、`section-coronal-a/b`、`section-axial-a/b`。若某个 structure 的 `lookups` 中某个名字找不到，按错误提示的 close matches 修改 `data-src/structures.yaml` 后重跑。

- [ ] **Step 6: 提交**

```bash
git add data-src scripts/preprocess.py
git commit -m "feat: add bodyparts3d preprocessing and section caps"
```

---

## Task 6: 合并并校验数据 JSON

**Files:**
- Create: `src/data/assemble.ts`, `scripts/build-data.ts`
- Test: `tests/assemble.test.ts`
- Output: `src/data/generated/structures.json`, `joints.json`, `attachments.json`, `quiz.json`, `clinical.json`, `section-planes.json`

- [ ] **Step 1: 写失败测试**

Create `tests/assemble.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import { assembleStructures } from '../src/data/assemble'

describe('assembleStructures', () => {
  it('merges yaml metadata with mesh stats', () => {
    const yaml = [
      {
        slug: 'humerus_right',
        lookups: ['Humerus'],
        fmaId: '',
        names: { zh: '肱骨', en: 'Humerus', la: 'Humerus' },
        system: 'skeletal' as const,
        laterality: 'right' as const,
        selectable: true,
        contextOnly: false,
        neighbors: [],
        clinical: '示例',
      },
    ]
    const stats = {
      humerus_right: {
        slug: 'humerus_right',
        fmaId: 'FMA00001',
        elementFileIds: ['FMA00001'],
        centroid: [0, 0, 0] as [number, number, number],
        bbox: {
          min: [0, 0, 0] as [number, number, number],
          max: [1, 1, 1] as [number, number, number],
        },
        tris: 10,
      },
    }
    const result = assembleStructures(yaml, stats, '2026-11-04')
    expect(result[0].fmaId).toBe('FMA00001')
    expect(result[0].mesh).toBe('humerus_right.glb')
    expect(result[0].source.license).toBe('CC BY 4.0')
  })

  it('throws when stats are missing', () => {
    const yaml = [
      {
        slug: 'x',
        lookups: ['X'],
        fmaId: '',
        names: { zh: 'x', en: 'X', la: 'X' },
        system: 'skeletal' as const,
        laterality: 'right' as const,
        selectable: true,
        contextOnly: false,
        neighbors: [],
        clinical: '',
      },
    ]
    expect(() => assembleStructures(yaml, {}, '2026-11-04')).toThrow(
      'missing mesh stats',
    )
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
npm test -- tests/assemble.test.ts
```

Expected: FAIL，找不到 `../src/data/assemble`。

- [ ] **Step 3: 实现合并函数**

Create `src/data/assemble.ts`:
```ts
import { structureSchema, type MeshStats, type StructureData } from './schema'

export interface StructureYaml {
  slug: string
  lookups: string[]
  fmaId: string
  names: { zh: string; en: string; la: string }
  system: StructureData['system']
  laterality: StructureData['laterality']
  selectable: boolean
  contextOnly: boolean
  neighbors: string[]
  clinical: string
}

export function assembleStructures(
  entries: StructureYaml[],
  stats: Record<string, MeshStats>,
  retrieved: string,
): StructureData[] {
  return entries.map((entry) => {
    const meshStats = stats[entry.slug]
    if (!meshStats) throw new Error(`missing mesh stats for ${entry.slug}`)
    return structureSchema.parse({
      fmaId: entry.fmaId || meshStats.fmaId,
      slug: entry.slug,
      names: entry.names,
      system: entry.system,
      laterality: entry.laterality,
      selectable: entry.selectable,
      contextOnly: entry.contextOnly,
      mesh: `${entry.slug}.glb`,
      source: {
        dataset: 'BodyParts3D',
        version: '4.0',
        elementFileIds: meshStats.elementFileIds,
        license: 'CC BY 4.0',
        retrieved,
        modifications: [
          'merged elements',
          'normalized to meters and Y-up',
          'decimated source 99%',
        ],
      },
      centroid: meshStats.centroid,
      bbox: meshStats.bbox,
      tris: meshStats.tris,
      neighbors: entry.neighbors,
      clinical: entry.clinical,
    })
  })
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
npm test -- tests/assemble.test.ts
```

Expected: 2 passed。

- [ ] **Step 5: 写构建 CLI**

Create `scripts/build-data.ts`:
```ts
import { readFile, writeFile, mkdir } from 'node:fs/promises'
import YAML from 'yaml'
import {
  attachmentSchema,
  clinicalEntrySchema,
  jointSchema,
  meshStatsSchema,
  quizItemSchema,
  sectionPlaneSchema,
  type MeshStats,
} from '../src/data/schema'
import { assembleStructures, type StructureYaml } from '../src/data/assemble'

const readYaml = async (path: string) => YAML.parse(await readFile(path, 'utf8'))

const structuresYaml = (await readYaml('data-src/structures.yaml')) as StructureYaml[]
const jointsYaml = await readYaml('data-src/joints.yaml')
const attachmentsYaml = await readYaml('data-src/attachments.yaml')
const quizYaml = await readYaml('data-src/quiz.yaml')
const clinicalYaml = await readYaml('data-src/clinical.yaml')
const planesYaml = await readYaml('data-src/section-planes.yaml')
const statsRaw = JSON.parse(
  await readFile('public/assets/elbow/mesh-stats.json', 'utf8'),
) as Record<string, MeshStats>

const stats = Object.fromEntries(
  Object.entries(statsRaw).map(([slug, value]) => [
    slug,
    meshStatsSchema.parse(value),
  ]),
)

const structures = assembleStructures(structuresYaml, stats, '2026-11-04')
const joints = jointSchema.parse(jointsYaml[0])
const attachments = attachmentsYaml.map((item: unknown) =>
  attachmentSchema.parse(item),
)
const quiz = quizYaml.map((item: unknown) => quizItemSchema.parse(item))
const clinical = clinicalYaml.map((item: unknown) =>
  clinicalEntrySchema.parse(item),
)
const planes = planesYaml.map((item: unknown) => sectionPlaneSchema.parse(item))

await mkdir('src/data/generated', { recursive: true })
const write = async (name: string, value: unknown) =>
  writeFile(`src/data/generated/${name}`, JSON.stringify(value, null, 2))

await write('structures.json', structures)
await write('joints.json', joints)
await write('attachments.json', attachments)
await write('quiz.json', quiz)
await write('clinical.json', clinical)
await write('section-planes.json', planes)

console.log(
  `wrote ${structures.length} structures, ${attachments.length} attachments`,
)
```

- [ ] **Step 6: 创建 joints/attachments/quiz/clinical 源文件**

Create `data-src/joints.yaml`。坐标全部用 0，Task 9 校准后替换；`carryingAngleMode` 必须是 `preserve_mesh_rest`。

```yaml
- id: elbow_right
  type: compound
  parent: humerus_right
  childGroup: forearm_right
  flexion:
    type: hinge
    axisLandmarks:
      medialEpicondyle: [0, 0, 0]
      lateralEpicondyle: [1, 0, 0]
    pivot: [0, 0, 0]
    restAngle: 0
    limits: { min: -5, max: 145 }
    populationRange:
      flexion: [130, 154]
      extension: [-6, 11]
    positive: flexion
  rotation:
    type: radius_about_ulna
    axisLandmarks:
      radialHeadCenter: [0, 0, 0]
      ulnarHeadCenter: [0, 0, 1]
    pivot: [0, 0, 0]
    limits: { min: -85, max: 85 }
    populationRange:
      pronation: [75, 85]
      supination: [75, 85]
    positive: supination
    neutral: thumb_up
  carryingAngleDeg: 8
  carryingAngleMode: preserve_mesh_rest
  approximation: true
```

Create `data-src/attachments.yaml`。坐标先用 0，Task 9 校准后替换。

```yaml
- muscle: biceps_brachii_right
  pathLabel: approximate musculotendinous path length
  heads:
    - name: long_head
      origin: { bone: scapula_right, p: [0, 0, 0] }
      via: [{ bone: humerus_right, p: [0, 0, 0] }]
      insertion: { bone: radius_right, p: [0, 0, 0] }
      note: 起自盂上结节，止于桡骨粗隆
    - name: short_head
      origin: { bone: scapula_right, p: [0, 0, 0] }
      via: [{ bone: humerus_right, p: [0, 0, 0] }]
      insertion: { bone: radius_right, p: [0, 0, 0] }
      note: 起自喙突，止于桡骨粗隆
  restLength: 0
  teachingNote: 肩固定前提下：屈肘缩短；旋前位较长、旋后位较短
- muscle: brachialis_right
  pathLabel: approximate musculotendinous path length
  heads:
    - name: main
      origin: { bone: humerus_right, p: [0, 0, 0] }
      via: [{ bone: humerus_right, p: [0, 0, 0] }]
      insertion: { bone: ulna_right, p: [0, 0, 0] }
      note: 起自肱骨前面下半，止于尺骨粗隆
  restLength: 0
  teachingNote: 屈肘时缩短
- muscle: triceps_brachii_right
  pathLabel: approximate musculotendinous path length
  heads:
    - name: common_path
      origin: { bone: humerus_right, p: [0, 0, 0] }
      via: [{ bone: humerus_right, p: [0, 0, 0] }]
      insertion: { bone: ulna_right, p: [0, 0, 0] }
      note: 三头共同鹰嘴路径；长头跨肩
  restLength: 0
  teachingNote: 屈肘时拉长；受前臂旋转影响小
```

Create `data-src/quiz.yaml`:

```yaml
- id: q-function-supinator
  level: 2
  type: choice
  prompt: 哪块肌肉是主要的旋后肌？
  choices:
    - { id: pronator_teres_right, label: 旋前圆肌 }
    - { id: supinator_right, label: 旋后肌 }
    - { id: pronator_quadratus_right, label: 旋前方肌 }
  answerId: supinator_right
  explanation: 旋后肌由桡神经深支支配，是主要的旋后肌。
- id: q-relation-radial-nerve
  level: 3
  type: choice
  prompt: 桡神经在肱骨何处走行？
  choices:
    - { id: radial_groove, label: 桡神经沟 }
    - { id: cubital_tunnel, label: 肘管 }
    - { id: carpal_tunnel, label: 腕管 }
  answerId: radial_groove
  explanation: 桡神经沿肱骨桡神经沟走行。
- id: q-section-median
  level: 4
  type: choice
  prompt: 在肘窝横断面上，正中神经通常位于肱动脉的哪一侧？
  choices:
    - { id: medial, label: 内侧 }
    - { id: lateral, label: 外侧 }
    - { id: posterior, label: 后方 }
  answerId: medial
  explanation: 在肘窝，正中神经位于肱动脉内侧。
- id: q-clinical-supracondylar
  level: 5
  type: choice
  prompt: 肱骨髁上骨折最易损伤哪条血管？
  choices:
    - { id: brachial_artery_right, label: 肱动脉 }
    - { id: radial_artery_right, label: 桡动脉 }
    - { id: ulnar_artery_right, label: 尺动脉 }
  answerId: brachial_artery_right
  explanation: 肱骨髁上骨折可损伤肱动脉与正中神经。
- id: q-clinical-midshaft
  level: 5
  type: choice
  prompt: 肱骨干中段骨折最易损伤哪条神经？
  choices:
    - { id: radial_nerve_right, label: 桡神经 }
    - { id: median_nerve_right, label: 正中神经 }
    - { id: ulnar_nerve_right, label: 尺神经 }
  answerId: radial_nerve_right
  explanation: 桡神经沿肱骨桡神经沟走行，肱骨干骨折可导致垂腕。
- id: q-clinical-cubital
  level: 5
  type: choice
  prompt: 肘管综合征压迫哪条神经？
  choices:
    - { id: ulnar_nerve_right, label: 尺神经 }
    - { id: radial_nerve_right, label: 桡神经 }
    - { id: median_nerve_right, label: 正中神经 }
  answerId: ulnar_nerve_right
  explanation: 尺神经经过肱骨内上髁后方的肘管。
- id: q-clinical-biceps-rupture
  level: 5
  type: choice
  prompt: 远端肱二头肌腱断裂最直接影响哪项动作？
  choices:
    - { id: supination, label: 旋后 }
    - { id: wrist_flexion, label: 屈腕 }
    - { id: finger_extension, label: 伸指 }
  answerId: supination
  explanation: 肱二头肌是主要的旋后肌之一，远端肌腱断裂会导致旋后与屈肘无力。
- id: q-identify-brachialis
  level: 1
  type: click
  prompt: 指出肱肌
  answerSlug: brachialis_right
  explanation: 肱肌位于肱二头肌深面，是主要屈肘肌。
```

Create `data-src/clinical.yaml`:

```yaml
- slug: biceps_brachii_right
  summary: 远端肱二头肌腱断裂会导致屈肘与旋后无力。
  vignette: 患者提重物时突感肘前疼痛，可见肱二头肌隆起。
- slug: median_nerve_right
  summary: 髁上骨折可损伤正中神经。
  vignette: 肘部外伤后出现拇指对掌无力。
- slug: radial_nerve_right
  summary: 肱骨干骨折可损伤桡神经，导致垂腕。
  vignette: 肱骨中段骨折后出现腕背伸无力。
- slug: ulnar_nerve_right
  summary: 肘管综合征压迫尺神经。
  vignette: 肘内侧麻木，环指与小指无力。
- slug: brachial_artery_right
  summary: 髁上骨折可损伤肱动脉。
  vignette: 肘部外伤后前臂苍白、桡动脉搏动减弱。
```

- [ ] **Step 7: 运行构建并验证**

Run:
```bash
npm run build:data
```

Expected: `src/data/generated/` 下生成 6 个 JSON；终端打印 `wrote 14 structures, 3 attachments`。

- [ ] **Step 8: 提交**

```bash
git add src/data scripts/build-data.ts data-src tests/assemble.test.ts
git commit -m "feat: assemble and validate anatomy data"
```

---

## Task 7: 双轴运动学 rig

**Files:**
- Create: `src/core/rig.ts`
- Test: `tests/rig.test.ts`

- [ ] **Step 1: 写失败测试**

Create `tests/rig.test.ts`:
```ts
import { describe, it, expect } from 'vitest'
import * as THREE from 'three'
import { ElbowRig } from '../src/core/rig'
import type { JointData } from '../src/data/schema'

const joint: JointData = {
  id: 'elbow_right',
  type: 'compound',
  parent: 'humerus_right',
  childGroup: 'forearm_right',
  flexion: {
    type: 'hinge',
    axisLandmarks: { medialEpicondyle: [0, 0, 0], lateralEpicondyle: [1, 0, 0] },
    pivot: [0, 0, 0],
    restAngle: 0,
    limits: { min: -5, max: 145 },
    populationRange: { flexion: [130, 154], extension: [-6, 11] },
    positive: 'flexion',
  },
  rotation: {
    type: 'radius_about_ulna',
    axisLandmarks: { radialHeadCenter: [0, 0, 0], ulnarHeadCenter: [0, 0, 1] },
    pivot: [0, 0, 0],
    limits: { min: -85, max: 85 },
    populationRange: { pronation: [75, 85], supination: [75, 85] },
    positive: 'supination',
    neutral: 'thumb_up',
  },
  carryingAngleDeg: 8,
  carryingAngleMode: 'preserve_mesh_rest',
  approximation: true,
}

function makeBone(name: string) {
  const mesh = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.1, 0.1))
  mesh.name = name
  mesh.position.set(0.5, 0, 0)
  return mesh
}

function makeRig() {
  return new ElbowRig(joint, {
    humerus: makeBone('humerus'),
    ulna: makeBone('ulna'),
    radius: makeBone('radius'),
  })
}

describe('ElbowRig', () => {
  it('keeps geometry in place at zero angles', () => {
    const rig = makeRig()
    rig.updateMatrixWorld()
    const p = new THREE.Vector3(0.5, 0, 0)
    expect(
      rig.worldPoint('radius_right', p.toArray() as [number, number, number]).distanceTo(p),
    ).toBeLessThan(1e-6)
  })

  it('clamps flexion to limits', () => {
    const rig = makeRig()
    rig.setFlexion(180)
    expect(THREE.MathUtils.radToDeg(rig.flexionPivot.rotation.z)).toBeCloseTo(145)
  })

  it('rotates radius but not ulna around the radioulnar axis', () => {
    const rig = makeRig()
    rig.updateMatrixWorld()
    const ulnaBefore = rig.worldPoint('ulna_right', [0.5, 0, 0])
    const radiusBefore = rig.worldPoint('radius_right', [0.5, 0, 0])
    rig.setRotation(90)
    rig.updateMatrixWorld()
    const ulnaAfter = rig.worldPoint('ulna_right', [0.5, 0, 0])
    const radiusAfter = rig.worldPoint('radius_right', [0.5, 0, 0])
    expect(ulnaAfter.distanceTo(ulnaBefore)).toBeLessThan(1e-6)
    expect(radiusAfter.distanceTo(radiusBefore)).toBeGreaterThan(0.1)
  })

  it('computes polyline path length through world points', () => {
    const rig = makeRig()
    rig.updateMatrixWorld()
    const length = rig.pathLength([
      { bone: 'humerus_right', p: [0, 0, 0] },
      { bone: 'radius_right', p: [0.5, 0, 0] },
    ])
    expect(length).toBeCloseTo(0.5)
  })

  it('makes a radius-attached path longer in pronation than supination', () => {
    const rig = makeRig()
    rig.setFlexion(90)
    rig.setRotation(-85)
    rig.updateMatrixWorld()
    const pronated = rig.pathLength([
      { bone: 'humerus_right', p: [0.5, 0.2, 0] },
      { bone: 'radius_right', p: [0.5, 0, 0] },
    ])
    rig.setRotation(85)
    rig.updateMatrixWorld()
    const supinated = rig.pathLength([
      { bone: 'humerus_right', p: [0.5, 0.2, 0] },
      { bone: 'radius_right', p: [0.5, 0, 0] },
    ])
    expect(pronated).toBeGreaterThan(supinated)
  })
})
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
npm test -- tests/rig.test.ts
```

Expected: FAIL，找不到 `../src/core/rig`。

- [ ] **Step 3: 实现 rig**

Create `src/core/rig.ts`:
```ts
import * as THREE from 'three'
import { axisFromLandmarks, clamp, polylineLength } from './math'
import type { JointData, Vec3 } from '../data/schema'

export interface RigBones {
  humerus: THREE.Object3D
  ulna: THREE.Object3D
  radius: THREE.Object3D
  hand?: THREE.Object3D
  humerusExtras?: THREE.Object3D[]
  forearmExtras?: THREE.Object3D[]
  radiusExtras?: THREE.Object3D[]
}

export interface PathPoint {
  bone: string
  p: Vec3
}

export class ElbowRig {
  readonly root = new THREE.Group()
  readonly flexionPivot = new THREE.Group()
  readonly carryingAngleGroup = new THREE.Group()
  readonly forearmOffset = new THREE.Group()
  readonly radiusPivot = new THREE.Group()
  readonly radiusOffset = new THREE.Group()
  private readonly bones = new Map<string, THREE.Object3D>()
  private readonly extraRoots: THREE.Object3D[] = []
  private readonly joint: JointData

  constructor(joint: JointData, bones: RigBones) {
    this.joint = joint

    const flexAxis = axisFromLandmarks(
      new THREE.Vector3(...joint.flexion.axisLandmarks.medialEpicondyle),
      new THREE.Vector3(...joint.flexion.axisLandmarks.lateralEpicondyle),
    )
    const flexPivot = new THREE.Vector3(...joint.flexion.pivot)
    this.flexionPivot.position.copy(flexPivot)
    this.flexionPivot.quaternion.setFromUnitVectors(
      new THREE.Vector3(0, 0, 1),
      flexAxis,
    )
    this.forearmOffset.position.copy(flexPivot).negate()

    const rotAxis = axisFromLandmarks(
      new THREE.Vector3(...joint.rotation.axisLandmarks.radialHeadCenter),
      new THREE.Vector3(...joint.rotation.axisLandmarks.ulnarHeadCenter),
    )
    const radialHead = new THREE.Vector3(...joint.rotation.pivot)
    this.radiusPivot.position.copy(radialHead)
    this.radiusPivot.quaternion.setFromUnitVectors(
      new THREE.Vector3(0, 0, 1),
      rotAxis,
    )
    this.radiusOffset.position.copy(radialHead).negate()

    this.root.add(bones.humerus)
    this.root.add(this.flexionPivot)
    this.flexionPivot.add(this.carryingAngleGroup)
    this.carryingAngleGroup.add(this.forearmOffset)
    this.forearmOffset.add(bones.ulna)
    this.forearmOffset.add(this.radiusPivot)
    this.radiusPivot.add(this.radiusOffset)
    this.radiusOffset.add(bones.radius)
    if (bones.hand) this.radiusOffset.add(bones.hand)

    bones.humerusExtras?.forEach((object) => this.root.add(object))
    bones.forearmExtras?.forEach((object) => this.forearmOffset.add(object))
    bones.radiusExtras?.forEach((object) => this.radiusOffset.add(object))
    this.extraRoots.push(
      ...(bones.humerusExtras ?? []),
      ...(bones.forearmExtras ?? []),
      ...(bones.radiusExtras ?? []),
    )

    this.bones.set('humerus_right', bones.humerus)
    this.bones.set('ulna_right', bones.ulna)
    this.bones.set('radius_right', bones.radius)
    if (bones.hand) this.bones.set('hand_right', bones.hand)
  }

  setFlexion(degrees: number): void {
    const value = clamp(
      degrees,
      this.joint.flexion.limits.min,
      this.joint.flexion.limits.max,
    )
    this.flexionPivot.rotation.z = THREE.MathUtils.degToRad(value)
  }

  setRotation(degrees: number): void {
    const value = clamp(
      degrees,
      this.joint.rotation.limits.min,
      this.joint.rotation.limits.max,
    )
    this.radiusPivot.rotation.z = THREE.MathUtils.degToRad(value)
  }

  updateMatrixWorld(): void {
    this.root.updateMatrixWorld(true)
  }

  worldPoint(bone: string, local: Vec3): THREE.Vector3 {
    const object = this.bones.get(bone)
    if (!object) throw new Error(`Unknown bone: ${bone}`)
    return new THREE.Vector3(...local).applyMatrix4(object.matrixWorld)
  }

  pathLength(points: PathPoint[]): number {
    return polylineLength(points.map((point) => this.worldPoint(point.bone, point.p)))
  }

  getFlexionPlane(): THREE.Plane {
    const axis = new THREE.Vector3(0, 0, 1).applyQuaternion(
      this.flexionPivot.getWorldQuaternion(new THREE.Quaternion()),
    )
    const pivot = this.flexionPivot.getWorldPosition(new THREE.Vector3())
    return new THREE.Plane().setFromNormalAndCoplanarPoint(axis, pivot)
  }

  getRotationPlane(): THREE.Plane {
    const axis = new THREE.Vector3(0, 0, 1).applyQuaternion(
      this.radiusPivot.getWorldQuaternion(new THREE.Quaternion()),
    )
    const pivot = this.radiusPivot.getWorldPosition(new THREE.Vector3())
    return new THREE.Plane().setFromNormalAndCoplanarPoint(axis, pivot)
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
npm test -- tests/rig.test.ts
```

Expected: 5 passed。

- [ ] **Step 5: 提交**

```bash
git add src/core/rig.ts tests/rig.test.ts
git commit -m "feat: add two-axis elbow rig"
```

---

## Task 8: 场景加载、拾取与状态 store

**Files:**
- Create: `src/core/picking.ts`, `src/core/drag.ts`, `src/core/loader.ts`, `src/ui/store.ts`, `src/ui/AnatomyViewer.tsx`
- Modify: `src/core/rig.ts`（加 `pickables` getter）, `src/App.tsx`, `src/main.tsx`, `src/index.css`

- [ ] **Step 1: 写拾取与拖拽工具**

Create `src/core/picking.ts`:
```ts
import * as THREE from 'three'

export interface PickResult {
  slug: string
  point: THREE.Vector3
  distance: number
}

export function toNdc(event: PointerEvent, element: HTMLElement): THREE.Vector2 {
  const rect = element.getBoundingClientRect()
  const x = ((event.clientX - rect.left) / rect.width) * 2 - 1
  const y = -((event.clientY - rect.top) / rect.height) * 2 + 1
  return new THREE.Vector2(x, y)
}

export function pickStructure(
  event: PointerEvent,
  element: HTMLElement,
  camera: THREE.Camera,
  meshes: THREE.Object3D[],
): PickResult | null {
  const raycaster = new THREE.Raycaster()
  raycaster.setFromCamera(toNdc(event, element), camera)
  const hits = raycaster.intersectObjects(meshes, true)
  for (const hit of hits) {
    let node: THREE.Object3D | null = hit.object
    while (node && !node.userData.slug) node = node.parent
    if (!node) continue
    return {
      slug: node.userData.slug as string,
      point: hit.point.clone(),
      distance: hit.distance,
    }
  }
  return null
}
```

Create `src/core/drag.ts`:
```ts
import * as THREE from 'three'
import { signedAngleAroundAxis } from './math'

export function pointerAngleOnPlane(
  event: PointerEvent,
  element: HTMLElement,
  camera: THREE.Camera,
  plane: THREE.Plane,
  pivot: THREE.Vector3,
): number | null {
  const rect = element.getBoundingClientRect()
  const ndc = new THREE.Vector2(
    ((event.clientX - rect.left) / rect.width) * 2 - 1,
    -((event.clientY - rect.top) / rect.height) * 2 + 1,
  )
  const raycaster = new THREE.Raycaster()
  raycaster.setFromCamera(ndc, camera)
  const point = new THREE.Vector3()
  if (!raycaster.ray.intersectPlane(plane, point)) return null
  const v = point.sub(pivot)
  let ref = new THREE.Vector3(1, 0, 0).projectOnPlane(plane.normal)
  if (ref.lengthSq() < 0.01) {
    ref = new THREE.Vector3(0, 0, 1).projectOnPlane(plane.normal)
  }
  if (ref.lengthSq() < 0.01) return null
  ref.normalize()
  return signedAngleAroundAxis(ref, v, plane.normal)
}
```

- [ ] **Step 2: 写加载器**

Create `src/core/loader.ts`:
```ts
import * as THREE from 'three'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'
import type { StructureData } from '../data/schema'

export async function loadStructures(
  structures: StructureData[],
): Promise<Map<string, THREE.Object3D>> {
  const loader = new GLTFLoader()
  const map = new Map<string, THREE.Object3D>()
  await Promise.all(
    structures.map(async (structure) => {
      const gltf = await loader.loadAsync(
        `${import.meta.env.BASE_URL}assets/elbow/${structure.mesh}`,
      )
      const root = gltf.scene
      root.name = structure.slug
      root.traverse((child) => {
        if ((child as THREE.Mesh).isMesh) {
          child.userData.slug = structure.slug
          child.userData.system = structure.system
          const mesh = child as THREE.Mesh
          mesh.material = Array.isArray(mesh.material)
            ? mesh.material.map((m) => m.clone())
            : mesh.material.clone()
        }
      })
      map.set(structure.slug, root)
    }),
  )
  return map
}
```

- [ ] **Step 3: 写 store**

Create `src/ui/store.ts`:
```ts
import { create } from 'zustand'
import type { ElbowRig } from '../core/rig'
import type { System } from '../data/schema'

export type Mode = 'explore' | 'move' | 'section' | 'identify' | 'quiz'
export type DragAxis = 'flexion' | 'rotation'

const SYSTEMS: System[] = [
  'skeletal',
  'muscular',
  'nervous',
  'vascular',
  'ligament',
  'skin',
]

interface ViewerState {
  mode: Mode
  flexion: number
  rotation: number
  selected: string | null
  layers: Record<System, boolean>
  opacity: Record<System, number>
  dragAxis: DragAxis
  rig: ElbowRig | null
  setMode: (mode: Mode) => void
  setFlexion: (value: number) => void
  setRotation: (value: number) => void
  setSelected: (slug: string | null) => void
  setLayer: (system: System, visible: boolean) => void
  setOpacity: (system: System, value: number) => void
  setDragAxis: (axis: DragAxis) => void
  setRig: (rig: ElbowRig | null) => void
}

const defaultLayers = Object.fromEntries(
  SYSTEMS.map((system) => [system, true]),
) as Record<System, boolean>

export const useViewerStore = create<ViewerState>((set) => ({
  mode: 'explore',
  flexion: 0,
  rotation: 0,
  selected: null,
  layers: defaultLayers,
  opacity: {
    skeletal: 1,
    muscular: 1,
    nervous: 1,
    vascular: 1,
    ligament: 1,
    skin: 0.15,
  },
  dragAxis: 'flexion',
  rig: null,
  setMode: (mode) => set({ mode }),
  setFlexion: (flexion) => set({ flexion }),
  setRotation: (rotation) => set({ rotation }),
  setSelected: (selected) => set({ selected }),
  setLayer: (system, visible) =>
    set((state) => ({ layers: { ...state.layers, [system]: visible } })),
  setOpacity: (system, value) =>
    set((state) => ({ opacity: { ...state.opacity, [system]: value } })),
  setDragAxis: (dragAxis) => set({ dragAxis }),
  setRig: (rig) => set({ rig }),
}))
```

- [ ] **Step 4: 给 rig 加 pickables getter**

Modify `src/core/rig.ts`，在 `getRotationPlane` 后加：
```ts
  get pickables(): THREE.Object3D[] {
    return [...this.bones.values(), ...this.extraRoots]
  }
```

- [ ] **Step 5: 写场景组件**

Create `src/ui/AnatomyViewer.tsx`:
```tsx
import { Canvas, useFrame, useThree } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { useEffect, useRef, useState } from 'react'
import * as THREE from 'three'
import structuresJson from '../data/generated/structures.json'
import jointJson from '../data/generated/joints.json'
import type { StructureData, JointData } from '../data/schema'
import { loadStructures } from '../core/loader'
import { ElbowRig } from '../core/rig'
import { pickStructure } from '../core/picking'
import { pointerAngleOnPlane } from '../core/drag'
import { useViewerStore, type DragAxis } from './store'

const structures = structuresJson as StructureData[]
const joint = jointJson as JointData

function RigScene({ rig }: { rig: ElbowRig }) {
  const flexion = useViewerStore((s) => s.flexion)
  const rotation = useViewerStore((s) => s.rotation)
  useFrame(() => {
    rig.setFlexion(flexion)
    rig.setRotation(rotation)
    rig.updateMatrixWorld()
  })
  return <primitive object={rig.root} />
}

function Scene() {
  const { gl, camera } = useThree()
  const controlsRef = useRef<any>(null)
  const [rig, setRig] = useState<ElbowRig | null>(null)
  const setStoreRig = useViewerStore((s) => s.setRig)
  const setSelected = useViewerStore((s) => s.setSelected)

  useEffect(() => {
    let cancelled = false
    loadStructures(structures).then((bones) => {
      if (cancelled) return
      const humerus = bones.get('humerus_right')
      const ulna = bones.get('ulna_right')
      const radius = bones.get('radius_right')
      if (!humerus || !ulna || !radius) {
        throw new Error('Missing humerus/ulna/radius GLB')
      }
      const pick = (...slugs: string[]) =>
        slugs
          .map((slug) => bones.get(slug))
          .filter((object): object is THREE.Object3D => Boolean(object))
      const next = new ElbowRig(joint, {
        humerus,
        ulna,
        radius,
        humerusExtras: pick(
          'scapula_right',
          'biceps_brachii_right',
          'brachialis_right',
          'triceps_brachii_right',
          'brachial_artery_right',
        ),
        forearmExtras: pick('ulnar_artery_right'),
        radiusExtras: pick(
          'brachioradialis_right',
          'pronator_teres_right',
          'pronator_quadratus_right',
          'supinator_right',
          'radial_artery_right',
        ),
      })
      setRig(next)
      setStoreRig(next)
    })
    return () => {
      cancelled = true
    }
  }, [setStoreRig])

  useEffect(() => {
    if (!rig) return
    const canvas = gl.domElement
    let down: { x: number; y: number } | null = null
    let drag: {
      axis: DragAxis
      startPointer: number
      startJoint: number
      plane: THREE.Plane
      pivot: THREE.Vector3
    } | null = null

    const onDown = (event: PointerEvent) => {
      down = { x: event.clientX, y: event.clientY }
      const state = useViewerStore.getState()
      if (state.mode !== 'move') return
      const hit = pickStructure(event, canvas, camera, rig.pickables)
      if (!hit) return
      const plane =
        state.dragAxis === 'flexion' ? rig.getFlexionPlane() : rig.getRotationPlane()
      const pivot =
        state.dragAxis === 'flexion'
          ? rig.flexionPivot.getWorldPosition(new THREE.Vector3())
          : rig.radiusPivot.getWorldPosition(new THREE.Vector3())
      const pointer = pointerAngleOnPlane(event, canvas, camera, plane, pivot)
      if (pointer === null) return
      drag = {
        axis: state.dragAxis,
        startPointer: pointer,
        startJoint: state.dragAxis === 'flexion' ? state.flexion : state.rotation,
        plane,
        pivot,
      }
      if (controlsRef.current) controlsRef.current.enabled = false
    }

    const onMove = (event: PointerEvent) => {
      if (!drag) return
      const pointer = pointerAngleOnPlane(
        event,
        canvas,
        camera,
        drag.plane,
        drag.pivot,
      )
      if (pointer === null) return
      const delta = THREE.MathUtils.radToDeg(pointer - drag.startPointer)
      const next = drag.startJoint + delta
      if (drag.axis === 'flexion') {
        useViewerStore
          .getState()
          .setFlexion(
            THREE.MathUtils.clamp(
              next,
              joint.flexion.limits.min,
              joint.flexion.limits.max,
            ),
          )
      } else {
        useViewerStore
          .getState()
          .setRotation(
            THREE.MathUtils.clamp(
              next,
              joint.rotation.limits.min,
              joint.rotation.limits.max,
            ),
          )
      }
    }

    const onUp = (event: PointerEvent) => {
      if (drag) {
        drag = null
        if (controlsRef.current) controlsRef.current.enabled = true
        return
      }
      if (!down) return
      const moved = Math.hypot(event.clientX - down.x, event.clientY - down.y)
      down = null
      if (moved > 5) return
      const hit = pickStructure(event, canvas, camera, rig.pickables)
      setSelected(hit?.slug ?? null)
    }

    canvas.addEventListener('pointerdown', onDown)
    canvas.addEventListener('pointermove', onMove)
    canvas.addEventListener('pointerup', onUp)
    return () => {
      canvas.removeEventListener('pointerdown', onDown)
      canvas.removeEventListener('pointermove', onMove)
      canvas.removeEventListener('pointerup', onUp)
    }
  }, [rig, gl, camera, setSelected])

  return (
    <>
      {rig && <RigScene rig={rig} />}
      <ambientLight intensity={1.2} />
      <directionalLight position={[2, 4, 3]} intensity={2} />
      <OrbitControls
        ref={controlsRef}
        makeDefault
        minDistance={0.15}
        maxDistance={2}
      />
    </>
  )
}

export function AnatomyViewer() {
  return (
    <div className="viewer">
      <Canvas
        camera={{ position: [0.4, 0.25, 0.6], fov: 45, near: 0.01, far: 10 }}
      >
        <Scene />
      </Canvas>
    </div>
  )
}
```

- [ ] **Step 6: 接到 App 并验证**

Modify `src/App.tsx`:
```tsx
import { AnatomyViewer } from './ui/AnatomyViewer'

export default function App() {
  return (
    <main className="app">
      <AnatomyViewer />
    </main>
  )
}
```

Modify `src/index.css`:
```css
html,
body,
#root {
  height: 100%;
  margin: 0;
  background: #111318;
  color: #e8e8e8;
  font-family: system-ui, sans-serif;
}

.app {
  height: 100%;
}

.viewer {
  height: 100%;
}
```

Run:
```bash
npm run dev
```

Expected: 浏览器打开后能看到肘部模型；控制台无 GLB 404；可以旋转/缩放。

- [ ] **Step 7: 提交**

```bash
git add src/core src/ui src/App.tsx src/index.css
git commit -m "feat: load anatomy scene with picking and drag math"
```

---

## Task 9: 校准工具

**Files:**
- Create: `src/ui/CalibrationPanel.tsx`
- Modify: `src/ui/store.ts`, `src/ui/AnatomyViewer.tsx`, `src/App.tsx`

- [ ] **Step 1: 在 store 里记录最近一次拾取**

Modify `src/ui/store.ts`：

在 `ViewerState` 接口中加：
```ts
  lastPick: { slug: string; world: [number, number, number]; local: [number, number, number] } | null
  setLastPick: (pick: ViewerState['lastPick']) => void
```

在 `create` 的初始值中加：
```ts
  lastPick: null,
  setLastPick: (lastPick) => set({ lastPick }),
```

- [ ] **Step 2: 在拾取时计算局部坐标**

Modify `src/ui/AnatomyViewer.tsx` 的 `onUp`，在 `setSelected` 后加：
```ts
      if (hit) {
        const root = rig.pickables.find((object) => object.userData.slug === hit.slug)
        if (root) {
          const local = root.worldToLocal(hit.point.clone())
          useViewerStore.getState().setLastPick({
            slug: hit.slug,
            world: [hit.point.x, hit.point.y, hit.point.z],
            local: [local.x, local.y, local.z],
          })
        }
      }
```

- [ ] **Step 3: 写校准面板**

Create `src/ui/CalibrationPanel.tsx`:
```tsx
import { useState } from 'react'
import YAML from 'yaml'
import { useViewerStore } from './store'

interface CalibrationPoint {
  label: string
  slug: string
  world: [number, number, number]
  local: [number, number, number]
}

const LABELS = [
  'medialEpicondyle',
  'lateralEpicondyle',
  'elbowPivot',
  'radialHeadCenter',
  'ulnarHeadCenter',
  'origin',
  'via',
  'insertion',
]

export function CalibrationPanel() {
  const lastPick = useViewerStore((s) => s.lastPick)
  const [label, setLabel] = useState(LABELS[0])
  const [points, setPoints] = useState<CalibrationPoint[]>([])

  const add = () => {
    if (!lastPick) return
    setPoints((current) => [...current, { label, ...lastPick }])
  }

  const download = () => {
    const blob = new Blob([YAML.stringify(points)], { type: 'text/yaml' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'calibration.yaml'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <aside className="panel calibration">
      <h2>校准模式</h2>
      <p>点击模型上的点，选择标签后 Add。完成后 Download。</p>
      <select value={label} onChange={(e) => setLabel(e.target.value)}>
        {LABELS.map((item) => (
          <option key={item} value={item}>
            {item}
          </option>
        ))}
      </select>
      <button onClick={add} disabled={!lastPick}>
        Add
      </button>
      <button onClick={download} disabled={points.length === 0}>
        Download YAML
      </button>
      <pre>{JSON.stringify(lastPick, null, 2)}</pre>
      <ol>
        {points.map((point, index) => (
          <li key={`${point.label}-${index}`}>
            {point.label} @ {point.slug} local={point.local.map((v) => v.toFixed(4)).join(', ')}
          </li>
        ))}
      </ol>
    </aside>
  )
}
```

- [ ] **Step 4: 在 App 中挂载**

Modify `src/App.tsx`:
```tsx
import { AnatomyViewer } from './ui/AnatomyViewer'
import { CalibrationPanel } from './ui/CalibrationPanel'

const calibrate = new URLSearchParams(window.location.search).has('calibrate')

export default function App() {
  return (
    <main className="app">
      <AnatomyViewer />
      {calibrate && <CalibrationPanel />}
    </main>
  )
}
```

Run:
```bash
npm run dev -- --port 5173
```

打开 `http://localhost:5173/?calibrate=1`，点击模型，Add 几个点，Download，确认 YAML 含 world/local 坐标。

为避免与图层面板重叠，在 `src/index.css` 加：
```css
.calibration {
  left: 16px;
  right: auto;
}
```

- [ ] **Step 5: 用校准结果替换 joints/attachments**

把下载的 `calibration.yaml` 中的 `local` 坐标填进 `data-src/joints.yaml` 与 `data-src/attachments.yaml`。必须采集：

- 内外上髁 → `flexion.axisLandmarks`
- 肘 pivot → `flexion.pivot`
- 桡骨头中心 → `rotation.axisLandmarks.radialHeadCenter` 与 `rotation.pivot`
- 尺骨头中心 → `rotation.axisLandmarks.ulnarHeadCenter`
- 二头肌长头/短头 origin、via、insertion
- 肱肌 origin、via、insertion
- 三头肌共同路径 origin、via、insertion
- 肘中心 → `data-src/section-planes.yaml` 中三个平面的 `origin`（先用同一个肘中心即可）

然后重跑：
```bash
python3 scripts/preprocess.py
npm run build:data
```

Expected: `joints.json` 与 `attachments.json` 坐标不再是 0；三标准面切面围绕肘部生成，而不是模型原点。

`restLength` 可以保持 0：MovePanel 会在首次加载时用 0° 屈曲、0° 旋转计算基线。若你希望把基线固化到数据里，把 Move 模式首次读数写回 `attachments.yaml` 的 `restLength`。

- [ ] **Step 6: 提交**

```bash
git add src/ui/CalibrationPanel.tsx src/ui/store.ts src/ui/AnatomyViewer.tsx src/App.tsx data-src
git commit -m "feat: add in-app calibration workflow"
```

---

## Task 10: Move 模式（双轴、读数、拖拽）

**Files:**
- Create: `src/ui/MovePanel.tsx`
- Modify: `src/App.tsx`, `src/index.css`

- [ ] **Step 1: 写 MovePanel**

Create `src/ui/MovePanel.tsx`:
```tsx
import { useEffect, useMemo, useRef, useState } from 'react'
import attachmentsJson from '../data/generated/attachments.json'
import jointJson from '../data/generated/joints.json'
import type { AttachmentData, JointData } from '../data/schema'
import { useViewerStore } from './store'

const joint = jointJson as JointData
const attachments = attachmentsJson as AttachmentData[]

interface Readout {
  muscle: string
  head: string
  length: number
  percent: number
}

export function MovePanel() {
  const rig = useViewerStore((s) => s.rig)
  const flexion = useViewerStore((s) => s.flexion)
  const rotation = useViewerStore((s) => s.rotation)
  const dragAxis = useViewerStore((s) => s.dragAxis)
  const setFlexion = useViewerStore((s) => s.setFlexion)
  const setRotation = useViewerStore((s) => s.setRotation)
  const setDragAxis = useViewerStore((s) => s.setDragAxis)
  const [readouts, setReadouts] = useState<Readout[]>([])
  const baseline = useRef<Record<string, number>>({})

  const paths = useMemo(
    () =>
      attachments.flatMap((attachment) =>
        attachment.heads.map((head) => ({
          muscle: attachment.muscle,
          head: head.name,
          points: [head.origin, ...head.via, head.insertion],
          rest: attachment.restLength,
        })),
      ),
    [],
  )

  useEffect(() => {
    if (!rig) return
    rig.setFlexion(0)
    rig.setRotation(0)
    rig.updateMatrixWorld()
    const next: Record<string, number> = {}
    paths.forEach((path) => {
      next[`${path.muscle}-${path.head}`] = rig.pathLength(path.points)
    })
    baseline.current = next
  }, [rig, paths])

  useEffect(() => {
    if (!rig) return
    rig.setFlexion(flexion)
    rig.setRotation(rotation)
    rig.updateMatrixWorld()
    const next = paths.map((path) => {
      const length = rig.pathLength(path.points)
      const key = `${path.muscle}-${path.head}`
      const rest = path.rest > 0 ? path.rest : (baseline.current[key] ?? length)
      return {
        muscle: path.muscle,
        head: path.head,
        length,
        percent: ((length - rest) / rest) * 100,
      }
    })
    setReadouts(next)
  }, [rig, flexion, rotation, paths])

  const mostShortened = readouts.reduce<Readout | null>(
    (best, item) => (!best || item.percent < best.percent ? item : best),
    null,
  )

  return (
    <aside className="panel">
      <h2>Move</h2>
      <label>
        屈曲 {flexion.toFixed(1)}°
        <input
          type="range"
          min={joint.flexion.limits.min}
          max={joint.flexion.limits.max}
          step={1}
          value={flexion}
          onChange={(e) => setFlexion(Number(e.target.value))}
        />
      </label>
      <label>
        旋前/旋后 {rotation.toFixed(1)}°
        <input
          type="range"
          min={joint.rotation.limits.min}
          max={joint.rotation.limits.max}
          step={1}
          value={rotation}
          onChange={(e) => setRotation(Number(e.target.value))}
        />
      </label>
      <div className="segmented">
        <button
          className={dragAxis === 'flexion' ? 'active' : ''}
          onClick={() => setDragAxis('flexion')}
        >
          拖拽屈伸
        </button>
        <button
          className={dragAxis === 'rotation' ? 'active' : ''}
          onClick={() => setDragAxis('rotation')}
        >
          拖拽旋转
        </button>
      </div>
      <p className="hint">正数 = 屈曲 / 旋后；负数 = 过伸 / 旋前。</p>
      <ul className="readouts">
        {readouts.map((item) => (
          <li
            key={`${item.muscle}-${item.head}`}
            className={item === mostShortened ? 'active' : ''}
          >
            <span>{item.muscle.replace('_right', '')}</span>
            <span>{item.head}</span>
            <span>{item.length.toFixed(3)} m</span>
            <span>{item.percent.toFixed(1)}%</span>
          </li>
        ))}
      </ul>
      <p className="hint">路径长度为近似肌腱-肌腹长度，不是肌纤维长度。</p>
    </aside>
  )
}
```

- [ ] **Step 2: 接到 App**

Modify `src/App.tsx`:
```tsx
import { AnatomyViewer } from './ui/AnatomyViewer'
import { CalibrationPanel } from './ui/CalibrationPanel'
import { MovePanel } from './ui/MovePanel'
import { useViewerStore } from './ui/store'

const calibrate = new URLSearchParams(window.location.search).has('calibrate')

export default function App() {
  const mode = useViewerStore((s) => s.mode)
  const setMode = useViewerStore((s) => s.setMode)

  return (
    <main className="app">
      <nav className="mode-bar">
        {(['explore', 'move', 'section', 'identify', 'quiz'] as const).map((item) => (
          <button
            key={item}
            className={mode === item ? 'active' : ''}
            onClick={() => setMode(item)}
          >
            {item}
          </button>
        ))}
      </nav>
      <AnatomyViewer />
      {mode === 'move' && <MovePanel />}
      {calibrate && <CalibrationPanel />}
    </main>
  )
}
```

- [ ] **Step 3: 加基础样式**

Append to `src/index.css`:
```css
.app {
  display: grid;
  grid-template-columns: 1fr;
  position: relative;
}

.mode-bar {
  position: fixed;
  top: 12px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 6px;
  z-index: 10;
  background: #1a1d24;
  padding: 6px;
  border-radius: 999px;
}

.mode-bar button,
.segmented button {
  background: transparent;
  color: #cfd3dc;
  border: 0;
  padding: 6px 12px;
  border-radius: 999px;
  cursor: pointer;
}

.mode-bar button.active,
.segmented button.active {
  background: #3b82f6;
  color: white;
}

.panel {
  position: fixed;
  top: 64px;
  right: 16px;
  width: 340px;
  max-height: calc(100vh - 80px);
  overflow: auto;
  background: #1a1d24ee;
  border: 1px solid #2e333d;
  border-radius: 12px;
  padding: 16px;
  z-index: 10;
}

.panel label {
  display: grid;
  gap: 6px;
  margin-bottom: 12px;
}

.segmented {
  display: flex;
  gap: 6px;
  background: #111318;
  border-radius: 999px;
  padding: 4px;
}

.readouts {
  list-style: none;
  padding: 0;
  margin: 12px 0;
}

.readouts li {
  display: grid;
  grid-template-columns: 1fr 1fr auto auto;
  gap: 8px;
  font-size: 12px;
  padding: 6px 0;
  border-bottom: 1px solid #2e333d;
}

.readouts li.active {
  color: #4ade80;
}

.hint {
  color: #8b93a3;
  font-size: 12px;
}
```

- [ ] **Step 4: 手动验证**

Run:
```bash
npm run dev
```

在 Move 模式：拖动两个滑杆，角度被 clamp；肌肉读数随屈曲/旋转变化；切换拖拽轴后在画布上拖动模型能改变对应角度。

- [ ] **Step 5: 提交**

```bash
git add src/ui/MovePanel.tsx src/App.tsx src/index.css
git commit -m "feat: add move mode with dual-axis readouts"
```

---

## Task 11: Explore 模式（图层、透明度、信息卡）

**Files:**
- Create: `src/ui/LayerPanel.tsx`, `src/ui/InfoCard.tsx`
- Modify: `src/core/loader.ts`, `src/ui/AnatomyViewer.tsx`, `src/App.tsx`

- [ ] **Step 1: 在加载器里记录 system**

Modify `src/core/loader.ts`，在 `root.name = structure.slug` 后加：
```ts
      root.userData.slug = structure.slug
      root.userData.system = structure.system
```

- [ ] **Step 2: 写图层面板**

Create `src/ui/LayerPanel.tsx`:
```tsx
import type { System } from '../data/schema'
import { useViewerStore } from './store'

const SYSTEMS: { id: System; label: string }[] = [
  { id: 'skeletal', label: '骨骼' },
  { id: 'muscular', label: '肌肉' },
  { id: 'vascular', label: '血管' },
]

export function LayerPanel() {
  const layers = useViewerStore((s) => s.layers)
  const opacity = useViewerStore((s) => s.opacity)
  const setLayer = useViewerStore((s) => s.setLayer)
  const setOpacity = useViewerStore((s) => s.setOpacity)

  return (
    <section className="panel">
      <h2>图层</h2>
      {SYSTEMS.map((system) => (
        <label key={system.id} className="layer-row">
          <span>
            <input
              type="checkbox"
              checked={layers[system.id]}
              onChange={(e) => setLayer(system.id, e.target.checked)}
            />
            {system.label}
          </span>
          <input
            type="range"
            min={0.05}
            max={1}
            step={0.05}
            value={opacity[system.id]}
            onChange={(e) => setOpacity(system.id, Number(e.target.value))}
          />
        </label>
      ))}
      <p className="hint">MVP 只有骨骼/肌肉/血管三组网格；神经/皮肤为 phase 2。点选结构可查看信息卡。</p>
    </section>
  )
}
```

- [ ] **Step 3: 写信息卡**

Create `src/ui/InfoCard.tsx`:
```tsx
import structuresJson from '../data/generated/structures.json'
import clinicalJson from '../data/generated/clinical.json'
import type { ClinicalEntry, StructureData } from '../data/schema'
import { useViewerStore } from './store'

const structures = structuresJson as StructureData[]
const clinical = clinicalJson as ClinicalEntry[]

const SYSTEM_LABELS: Record<string, string> = {
  skeletal: '骨骼',
  muscular: '肌肉',
  nervous: '神经',
  vascular: '血管',
  ligament: '韧带/膜',
  skin: '皮肤',
}

export function InfoCard() {
  const selected = useViewerStore((s) => s.selected)
  if (!selected) return null
  const structure = structures.find((item) => item.slug === selected)
  if (!structure) return null
  const extra = clinical.find((item) => item.slug === selected)

  return (
    <section className="panel info-card">
      <h2>{structure.names.zh}</h2>
      <p>{structure.names.en}</p>
      <p className="latin">{structure.names.la}</p>
      <dl>
        <dt>FMA</dt>
        <dd>{structure.fmaId}</dd>
        <dt>系统</dt>
        <dd>{SYSTEM_LABELS[structure.system]}</dd>
        <dt>毗邻</dt>
        <dd>{structure.neighbors.join('、') || '—'}</dd>
      </dl>
      <p>{structure.clinical}</p>
      {extra && <p className="hint">{extra.summary}</p>}
      <p className="hint">教学近似，非临床诊断。</p>
    </section>
  )
}
```

- [ ] **Step 4: 在 Scene 中应用图层与透明度**

Modify `src/ui/AnatomyViewer.tsx` 的 `Scene`：在 `useEffect` 里读取 store，并新增一个 effect：
```tsx
  const layers = useViewerStore((s) => s.layers)
  const opacity = useViewerStore((s) => s.opacity)
  const mode = useViewerStore((s) => s.mode)

  useEffect(() => {
    if (!rig) return
    rig.root.visible = mode !== 'section'
    rig.pickables.forEach((root) => {
      const system = root.userData.system as keyof typeof opacity
      if (!system) return
      root.visible = layers[system]
      root.traverse((child) => {
        const mesh = child as THREE.Mesh
        if (!mesh.isMesh) return
        const materials = Array.isArray(mesh.material) ? mesh.material : [mesh.material]
        materials.forEach((material) => {
          material.transparent = opacity[system] < 1
          material.opacity = opacity[system]
          material.depthWrite = opacity[system] >= 1
          material.alphaHash = opacity[system] < 1 && opacity[system] > 0.2
          material.needsUpdate = true
        })
      })
    })
  }, [rig, layers, opacity, mode])
```

- [ ] **Step 5: 接到 App**

Modify `src/App.tsx`：
```tsx
import { AnatomyViewer } from './ui/AnatomyViewer'
import { CalibrationPanel } from './ui/CalibrationPanel'
import { InfoCard } from './ui/InfoCard'
import { LayerPanel } from './ui/LayerPanel'
import { MovePanel } from './ui/MovePanel'
import { useViewerStore } from './ui/store'

const calibrate = new URLSearchParams(window.location.search).has('calibrate')

export default function App() {
  const mode = useViewerStore((s) => s.mode)
  const setMode = useViewerStore((s) => s.setMode)

  return (
    <main className="app">
      <nav className="mode-bar">
        {(['explore', 'move', 'section', 'identify', 'quiz'] as const).map((item) => (
          <button
            key={item}
            className={mode === item ? 'active' : ''}
            onClick={() => setMode(item)}
          >
            {item}
          </button>
        ))}
      </nav>
      <AnatomyViewer />
      {(mode === 'explore' || mode === 'identify') && (
        <>
          <LayerPanel />
          <InfoCard />
        </>
      )}
      {mode === 'move' && <MovePanel />}
      {calibrate && <CalibrationPanel />}
    </main>
  )
}
```

Append to `src/index.css`:
```css
.layer-row {
  display: grid;
  grid-template-columns: 1fr 120px;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.info-card {
  top: auto;
  bottom: 16px;
  right: 16px;
  width: 320px;
}

.info-card .latin {
  color: #8b93a3;
  font-style: italic;
}

.info-card dl {
  display: grid;
  grid-template-columns: 60px 1fr;
  gap: 4px;
  font-size: 13px;
}
```

- [ ] **Step 6: 提交**

```bash
git add src/ui/LayerPanel.tsx src/ui/InfoCard.tsx src/core/loader.ts src/ui/AnatomyViewer.tsx src/App.tsx src/index.css
git commit -m "feat: add explore mode layers and info card"
```

---

## Task 12: Section 模式（三标准面封盖）

**Files:**
- Create: `src/ui/SectionPanel.tsx`, `src/ui/SectionScene.tsx`
- Modify: `src/ui/store.ts`, `src/ui/AnatomyViewer.tsx`, `src/App.tsx`

- [ ] **Step 1: 扩展 store**

Modify `src/ui/store.ts`，在 `ViewerState` 接口中加：
```ts
  sectionPlane: 'sagittal' | 'coronal' | 'axial'
  sectionSide: 'a' | 'b'
  setSectionPlane: (plane: ViewerState['sectionPlane']) => void
  setSectionSide: (side: ViewerState['sectionSide']) => void
```

在初始值中加：
```ts
  sectionPlane: 'sagittal',
  sectionSide: 'a',
  setSectionPlane: (sectionPlane) => set({ sectionPlane }),
  setSectionSide: (sectionSide) => set({ sectionSide }),
```

- [ ] **Step 2: 写切面场景**

Create `src/ui/SectionScene.tsx`:
```tsx
import { useEffect, useState } from 'react'
import * as THREE from 'three'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'

interface Props {
  plane: 'sagittal' | 'coronal' | 'axial'
  side: 'a' | 'b'
}

export function SectionScene({ plane, side }: Props) {
  const [scene, setScene] = useState<THREE.Group | null>(null)

  useEffect(() => {
    let cancelled = false
    const loader = new GLTFLoader()
    loader.load(
      `${import.meta.env.BASE_URL}assets/elbow/section-${plane}-${side}.glb`,
      (gltf) => {
        if (cancelled) return
        gltf.scene.traverse((child) => {
          const mesh = child as THREE.Mesh
          if (!mesh.isMesh) return
          mesh.userData.slug = child.name
          mesh.material = Array.isArray(mesh.material)
            ? mesh.material.map((m) => m.clone())
            : mesh.material.clone()
        })
        setScene(gltf.scene)
      },
    )
    return () => {
      cancelled = true
    }
  }, [plane, side])

  if (!scene) return null
  return <primitive object={scene} />
}
```

- [ ] **Step 3: 写切面面板**

Create `src/ui/SectionPanel.tsx`:
```tsx
import sectionPlanesJson from '../data/generated/section-planes.json'
import type { SectionPlane } from '../data/schema'
import { useViewerStore } from './store'

const planes = sectionPlanesJson as SectionPlane[]

export function SectionPanel() {
  const plane = useViewerStore((s) => s.sectionPlane)
  const side = useViewerStore((s) => s.sectionSide)
  const setPlane = useViewerStore((s) => s.setSectionPlane)
  const setSide = useViewerStore((s) => s.setSectionSide)

  return (
    <aside className="panel">
      <h2>Section</h2>
      <div className="segmented">
        {planes.map((item) => (
          <button
            key={item.id}
            className={plane === item.id ? 'active' : ''}
            onClick={() => setPlane(item.id)}
          >
            {item.label}
          </button>
        ))}
      </div>
      <div className="segmented" style={{ marginTop: 10 }}>
        <button className={side === 'a' ? 'active' : ''} onClick={() => setSide('a')}>
          近端/前侧
        </button>
        <button className={side === 'b' ? 'active' : ''} onClick={() => setSide('b')}>
          远端/后侧
        </button>
      </div>
      <p className="hint">切面为预处理封盖模型，非 MRI/CT 重建。</p>
    </aside>
  )
}
```

- [ ] **Step 4: 接到 App 与 Scene**

Modify `src/App.tsx`：
```tsx
import { SectionPanel } from './ui/SectionPanel'
```
并在 `mode === 'move'` 后加：
```tsx
      {mode === 'section' && <SectionPanel />}
```

Modify `src/ui/AnatomyViewer.tsx`：

顶部加：
```tsx
import { SectionScene } from './SectionScene'
```

在 `Scene` 里加：
```tsx
  const sectionPlane = useViewerStore((s) => s.sectionPlane)
  const sectionSide = useViewerStore((s) => s.sectionSide)
```

在 return 中、`{rig && <RigScene rig={rig} />}` 后加：
```tsx
      {mode === 'section' && (
        <SectionScene plane={sectionPlane} side={sectionSide} />
      )}
```

- [ ] **Step 5: 验证**

Run:
```bash
npm run dev
```

在 Section 模式：切换矢状/冠状/横断，画面切换为封盖切面；切换 a/b 看到另一侧；不应出现空心内壁。

- [ ] **Step 6: 提交**

```bash
git add src/ui/SectionPanel.tsx src/ui/SectionScene.tsx src/ui/store.ts src/ui/AnatomyViewer.tsx src/App.tsx
git commit -m "feat: add precomputed capped section mode"
```

---

## Task 13: 测验与本地进度

**Files:**
- Create: `src/ui/progress.ts`, `src/ui/QuizPanel.tsx`
- Modify: `src/App.tsx`, `src/index.css`

- [ ] **Step 1: 写进度模块**

Create `src/ui/progress.ts`:
```ts
export interface ProgressEntry {
  lastSeen: string
  attempts: number
  correct: number
  streak: number
  lastCorrect: boolean
  nextReview: string
}

const KEY = 'elbow-atlas-progress-v1'
const SCHEDULE_DAYS = [1, 3, 7, 14]

export function loadProgress(): Record<string, ProgressEntry> {
  try {
    return JSON.parse(localStorage.getItem(KEY) ?? '{}')
  } catch {
    return {}
  }
}

export function recordAnswer(slug: string, correct: boolean): ProgressEntry {
  const all = loadProgress()
  const previous = all[slug]
  const attempts = (previous?.attempts ?? 0) + 1
  const correctCount = (previous?.correct ?? 0) + (correct ? 1 : 0)
  const streak = correct ? (previous?.streak ?? 0) + 1 : 0
  const days = SCHEDULE_DAYS[Math.min(streak, SCHEDULE_DAYS.length - 1)]
  const nextReview = new Date(Date.now() + days * 86400000).toISOString()
  const entry: ProgressEntry = {
    lastSeen: new Date().toISOString(),
    attempts,
    correct: correctCount,
    streak,
    lastCorrect: correct,
    nextReview,
  }
  all[slug] = entry
  try {
    localStorage.setItem(KEY, JSON.stringify(all))
  } catch {
    // localStorage 不可用时只保留内存态；UI 会提示。
  }
  return entry
}
```

- [ ] **Step 2: 写测验面板**

Create `src/ui/QuizPanel.tsx`:
```tsx
import { useMemo, useState } from 'react'
import quizJson from '../data/generated/quiz.json'
import type { QuizItem } from '../data/schema'
import { recordAnswer } from './progress'
import { useViewerStore } from './store'

const quiz = quizJson as QuizItem[]

export function QuizPanel() {
  const selected = useViewerStore((s) => s.selected)
  const [index, setIndex] = useState(0)
  const [result, setResult] = useState<boolean | null>(null)
  const [score, setScore] = useState({ correct: 0, total: 0 })
  const item = quiz[index]

  const answerSlug = useMemo(() => {
    if (!item) return null
    return item.type === 'click' ? item.answerSlug : item.answerId
  }, [item])

  const submit = (correct: boolean) => {
    if (!item || result !== null) return
    setResult(correct)
    setScore((current) => ({
      correct: current.correct + (correct ? 1 : 0),
      total: current.total + 1,
    }))
    recordAnswer(answerSlug ?? item.id, correct)
  }

  const next = () => {
    setResult(null)
    setIndex((current) => current + 1)
  }

  if (!item) {
    return (
      <aside className="panel">
        <h2>测验完成</h2>
        <p>
          得分 {score.correct} / {score.total}
        </p>
        <button
          onClick={() => {
            setIndex(0)
            setScore({ correct: 0, total: 0 })
            setResult(null)
          }}
        >
          再来一轮
        </button>
      </aside>
    )
  }

  return (
    <aside className="panel">
      <h2>
        测验 {index + 1} / {quiz.length}
      </h2>
      <p className="hint">Level {item.level}</p>
      <p>{item.prompt}</p>

      {item.type === 'click' ? (
        <button
          disabled={!selected || result !== null}
          onClick={() => submit(selected === item.answerSlug)}
        >
          提交选中结构：{selected ?? '未选中'}
        </button>
      ) : (
        <div className="choices">
          {item.choices.map((choice) => (
            <button
              key={choice.id}
              disabled={result !== null}
              onClick={() => submit(choice.id === item.answerId)}
            >
              {choice.label}
            </button>
          ))}
        </div>
      )}

      {result !== null && (
        <>
          <p className={result ? 'correct' : 'wrong'}>
            {result ? '正确' : '错误'}
          </p>
          <p className="hint">{item.explanation}</p>
          <button onClick={next}>下一题</button>
        </>
      )}
    </aside>
  )
}
```

- [ ] **Step 3: 接到 App**

Modify `src/App.tsx`：
```tsx
import { QuizPanel } from './ui/QuizPanel'
```
并在 `mode === 'section'` 后加：
```tsx
      {mode === 'quiz' && <QuizPanel />}
```

Append to `src/index.css`:
```css
.choices {
  display: grid;
  gap: 8px;
}

.choices button,
.panel > button {
  text-align: left;
  background: #242933;
  color: #e8e8e8;
  border: 1px solid #343b47;
  border-radius: 8px;
  padding: 8px 10px;
  cursor: pointer;
}

.correct {
  color: #4ade80;
}

.wrong {
  color: #f87171;
}
```

- [ ] **Step 4: 手动验证**

Run:
```bash
npm run dev
```

在 Quiz 模式：完成至少一题；刷新页面后 localStorage 里仍有记录（DevTools → Application → Local Storage → `elbow-atlas-progress-v1`）。

- [ ] **Step 5: 提交**

```bash
git add src/ui/progress.ts src/ui/QuizPanel.tsx src/App.tsx src/index.css
git commit -m "feat: add five-level quiz and local progress"
```

---

## Task 14: E2E、性能与部署

**Files:**
- Create: `playwright.config.ts`, `tests/e2e/app.spec.ts`, `README.md`
- Modify: `package.json`

- [ ] **Step 1: 配置 Playwright**

Create `playwright.config.ts`:
```ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: 'tests/e2e',
  timeout: 30000,
  use: {
    baseURL: 'http://127.0.0.1:4173',
    trace: 'on-first-retry',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: {
    command: 'npm run build && npm run preview -- --host 127.0.0.1 --port 4173',
    url: 'http://127.0.0.1:4173',
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
})
```

- [ ] **Step 2: 写 E2E 冒烟测试**

Create `tests/e2e/app.spec.ts`:
```ts
import { test, expect } from '@playwright/test'

test('loads anatomy and switches modes', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('canvas')).toBeVisible()
  await page.getByRole('button', { name: 'move' }).click()
  await expect(page.getByText('Move')).toBeVisible()
  await expect(page.getByText('屈曲')).toBeVisible()
})

test('section mode loads capped planes', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'section' }).click()
  await expect(page.getByText('Section')).toBeVisible()
  await page.getByRole('button', { name: '冠状面' }).click()
  await page.getByRole('button', { name: '远端/后侧' }).click()
  await expect(page.locator('canvas')).toBeVisible()
})

test('quiz records progress', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'quiz' }).click()
  await expect(page.getByText('测验 1 / 8')).toBeVisible()
  await page.getByRole('button', { name: /旋前圆肌|旋后肌|旋前方肌/ }).first().click()
  await expect(page.getByText(/正确|错误/)).toBeVisible()
  const stored = await page.evaluate(() =>
    localStorage.getItem('elbow-atlas-progress-v1'),
  )
  expect(stored).not.toBeNull()
})
```

- [ ] **Step 3: 跑 E2E**

Run:
```bash
npx playwright install chromium
npm run e2e
```

Expected: 3 passed。若 GLB 资源缺失，先跑 `npm run preprocess` 与 `npm run build:data`。

- [ ] **Step 4: 性能检查**

Run preview 后用 Chrome DevTools Performance 记录 10 秒：

- 旋转 + 拖动屈伸 + 切换图层。
- 目标：中端笔记本 ≥ 50 fps；首屏资源 < 10 MB（Network 面板过滤 `assets/elbow`）。
- 若低于目标：先减少 `section-*.glb` 的加载（只在 Section 模式按需加载），再检查材质是否被重复创建。

- [ ] **Step 5: 写 README 与署名**

Create `README.md`:
````markdown
# Elbow Atlas

浏览器内肘与前臂 3D 解剖学习器。支持双轴运动、肌肉路径长度反馈、图层剥离、三标准面封盖剖面、五级测验与本地进度。

## 开发

```bash
npm install
npm run fetch:data
python3 -m pip install trimesh numpy pyyaml
npm run preprocess
npm run build:data
npm run dev
```

## 数据与许可

解剖数据来自 BodyParts3D 4.0（99% 减面版），由 DBCLS 发布：

> BodyParts3D, © The Database Center for Life Science licensed under CC Attribution 4.0 International

本项目对网格进行了裁剪、合并、减面和坐标归一化。许可见：
<https://dbarchive.biosciencedbc.jp/en/bodyparts3d/lic.html>

## 教学声明

本工具为教学近似，非临床诊断标准；模型为单一成年男性，不覆盖女性、体型差异或解剖变异。肌肉长度为近似肌腱-肌腹路径长度，不是肌纤维长度或生理肌长。

## 部署

```bash
npm run build
npm run preview
```

`dist/` 可部署到任意静态托管。学习进度存 IndexedDB/localStorage，无后端。
````

- [ ] **Step 6: 提交**

```bash
git add playwright.config.ts tests/e2e README.md package.json
git commit -m "test: add e2e smoke tests and deployment docs"
```

---

## 本计划明确不包含

- 任意偏移的运行时 stencil cap；MVP 只有三个标准面的预生成封盖模型。
- Section 模式下与 3D 选中联动的 “Find in section” 高亮；MVP 只做切面切换与 L4 文本题。试点后再加。
- 真实肌腹形变；MVP 只显示路径长度、百分比与示意读数。
- 肩/腕自由度、碰撞检测、软组织 FEM。
- 外周神经、肘部韧带、区域皮肤、整只手的 3D 网格；MVP 只做骨骼/肌肉/血管三组，phase 2 再从 Z-Anatomy 补神经/皮肤。

## 完成标准

- Task 1–14 全部通过。
- `npm test` 与 `npm run e2e` 全绿。
- 在真实设备上：屈曲与旋转都被 clamp；二头肌路径长度在固定肘角下按“旋前较长、旋后较短”变化；三标准面切面有封盖；点选、图层、测验、进度可用。
- 所有页面明确显示“教学近似，非临床诊断；单一男性模型”。
- MVP 只包含骨骼/肌肉/血管三组真实网格；神经/皮肤/韧带/手部为文字内容或 phase 2。

