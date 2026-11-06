# SENSORCRAFT：iPhone 传感器实验室设计文档

- 日期：2026-11-06
- 状态：已实现并本地验证（多文件架构 + 可选单文件构建），待用户复核
- 交付目录：`webapp/sensor-craft/`（多文件静态项目 + 可选单文件构建产物）
- 目标设备：iPhone Safari（iOS 16+）；桌面 Chrome 作为降级与布局验证
- 视觉风格：Minecraft GUI（石质面板、物品槽、斜角边框、像素图标）
- 技术约束：原生 HTML/CSS/JS（经典脚本 + `window.SC` 命名空间）、零第三方依赖、无运行时构建；传感器仍受浏览器授权与安全上下文限制

## 1. 背景与目标

用户要为孩子/学生做一个「iPhone 传感器实验室」网页：把 iPhone Safari 能调用的传感器和硬件集中成一面卡片墙，点开任意卡片就能看到实时数据或画面，并把它作为后续继续开发小项目（测心率、分贝计、计步器、指南针、GPS 轨迹、反应力游戏等）的底座。

本设计要解决的不是「把 API 各写一个 demo」，而是：

1. 用一套统一的注册表与生命周期，让新增传感器/实验像「往背包里放一件物品」一样简单。
2. 让学生直观看到 iPhone 网页**能做什么、不能做什么、为什么**，而不是遇到白屏或静默失败。
3. 用 Minecraft 的物品栏、工作台、成就、XP 条，把枯燥的 API 调试变成可探索的游戏界面。
4. 交付一个结构清晰、可持续扩展的静态项目；同时提供可选的单文件构建产物，方便离线分发。

核心原则：**先探测、再渲染；打不开就解释；离开就释放。**

## 2. 非目标

- 不做医疗级测量。摄像头模块不做 rPPG 心率推断，不输出任何诊断结论。
- 不做原生 App、不做 App Store 打包；不申请 HealthKit、Apple Watch、后台常驻等原生能力。
- 不绕过 iOS 与浏览器的安全限制；拿不到的 API 只做「锁定卡 + 原因说明」。
- 不做账号、云同步、数据库、后端。
- 不引入 React/Vue/Three.js 等依赖；所有图形用 Canvas、CSS 和原生 Web API。
- 不使用 Mojang 官方贴图、字体或音效；纹理为自绘 SVG，英文/数字使用 OFL 的 Monocraft 子集。
- 不承诺 Android 全兼容；只保证在 Android Chrome 上尽量优雅降级。

## 3. 用户与使用场景

| 用户 | 场景 | 设计含义 |
|---|---|---|
| 中小学生（主要） | 在 iPhone 上点卡片、看波形、玩反应力小游戏 | 大字、大按钮、即时反馈、成就奖励 |
| 家长/老师 | 讲解「为什么 iPhone 网页拿不到气压计」 | 锁定卡必须有清楚的中文原因 |
| 开发者（用户本人） | 在这个文件上继续加传感器/实验 | 注册表 + 模块契约 + 公共工具，新增一项即可 |
| 桌面浏览器用户 | 没带手机时预览布局 | 所有模块必须能降级为空状态，不崩溃 |

## 4. 能力矩阵与卡片

### 4.1 状态枚举

| 状态 | 卡片表现 | 含义 |
|---|---|---|
| `ready` | 正常物品槽，可点击 | 当前浏览器/设备已检测到能力 |
| `partial` | 正常槽 + 黄色「受限」角标 | 能打开，但功能受设备/浏览器限制 |
| `locked` | 灰色槽 + 锁图标，仍可点击 | 网页无法获得该能力；点开显示原因与替代方案 |
| `info` | 正常槽 + 书图标 | 不是传感器，但值得解释（如 Face ID） |

`probe()` 在页面加载时执行一次；部分能力（手柄、WebGPU、补光灯）在打开模块时再复查。

### 4.2 主卡片（14 张）

| # | 卡片 | id | 默认状态 | 实时数据 / 画面 | 游戏化包装 |
|---|---|---|---|---|---|
| 1 | 摄像头 | `camera` | ready | 前后镜头画面、分辨率、FPS、拍照、中心取色、亮度 | 观察者之眼 |
| 2 | 麦克风 | `microphone` | ready | 实时音量 dB、波形、频谱、主频与音名 | 声波图腾 |
| 3 | 补光灯 | `torch` | partial | 能力探测与开关尝试 | 萤石灯 |
| 4 | 加速度计 | `accelerometer` | ready | 含重力/线性加速度、三轴、合矢量、计步、摇晃、自由落体 | 重力罗盘 |
| 5 | 陀螺仪 | `gyroscope` | ready | 三轴角速度、合矢量、峰值 RPM、旋转方块 | 旋转之眼 |
| 6 | 姿态与指南针 | `orientation` | ready | α/β/γ、水平气泡、罗盘方位、中文方位 | 探险家罗盘 |
| 7 | GPS 定位 | `geolocation` | ready | 经纬度、精度、速度、海拔、方向、轨迹画布、里程 | 地图制作者 |
| 8 | 多点触控 | `multitouch` | ready | 多指光点、触点数、最大同时触点数、反应力小游戏 | 多人压力板 |
| 9 | 扬声器/语音 | `speaker` | ready | 音调发生器、波形选择、TTS、语音识别可用性 | 音符盒 |
| 10 | 游戏手柄 | `gamepad` | partial | 手柄名称、按键亮灭、摇杆坐标 | 命令方块控制器 |
| 11 | 屏幕常亮 | `wakelock` | ready | Wake Lock 申请状态、重新获取 | 不灭之火 |
| 12 | WebGPU | `webgpu` | partial | 适配器/后端/特性列表；不可用则说明 | 附魔台 |
| 13 | 手动相机控制 | `camera-manual` | partial | 变焦/对焦/曝光能力探测与滑杆 | 红石相机 |
| 14 | Face ID / Touch ID | `biometrics` | info | 说明网页只能用于登录，拿不到脸/指纹数据 | 村民交易台 |

### 4.3 锁定卡片（12 张）

| # | 卡片 | id | 锁定原因（中文要点） |
|---|---|---|---|
| 1 | 环境光传感器 | `ambient-light` | iOS Safari 不暴露；Android 需手动开启实验特性 |
| 2 | 磁力计原始数据 | `magnetometer` | 只能通过姿态事件拿到算好的方向，拿不到原始三轴 |
| 3 | 气压计 | `barometer` | 网页无 API，需原生 App |
| 4 | 距离传感器 | `proximity` | 网页无 API |
| 5 | LiDAR / 原深感 | `lidar` | 网页无深度 API |
| 6 | Web Bluetooth | `bluetooth` | iOS Safari 不支持 Web Bluetooth |
| 7 | NFC | `nfc` | iOS Safari 不支持 Web NFC；且需原生 |
| 8 | USB / 串口 | `serial` | iOS 不支持 Web Serial；桌面 Chrome 可 |
| 9 | 震动反馈 | `vibration` | iOS Safari 忽略 Vibration API |
| 10 | 电池电量 | `battery` | iOS Safari 不提供 Battery Status API |
| 11 | HealthKit / 步数 | `healthkit` | 需原生 App 与用户授权 |
| 12 | 后台运行 | `background` | PWA 在 iOS 锁屏后不能持续采集 |

锁定卡不是死路：点开后有「在别的设备/原生 App 里怎么做」「回到可用卡片」的引导。

## 5. 信息架构与导航

```text
启动
 └─ 校准门（首次）
     └─ 背包视图（卡片墙）
         ├─ 顶部 F3 状态栏
         ├─ 分组卡片区
         │   ├─ 影像与声音
         │   ├─ 运动与环境
         │   ├─ 交互与输出
         │   ├─ 计算与身份
         │   └─ 未解锁图鉴
         └─ 底部 XP 条 + 聊天式事件日志
             └─ 点击卡片 → 工作台视图
                 ├─ 标题栏（图标 + 名称 + 状态角标）
                 ├─ 返回背包
                 ├─ 实时画面 / 图表 / 控件
                 ├─ 数据 HUD
                 └─ 模块内成就与提示
```

- **单页双视图**：背包视图与工作台视图同页切换，不刷新、不跳转。
- **返回方式**：`← 返回背包`、浏览器返回键（`history.pushState` + `popstate`）、键盘 `Esc`。
- **深链接（可选，低优先级）**：`#camera` 直接打开摄像头卡片，便于以后做课堂链接。首版实现，逻辑简单。

## 6. 视觉与交互规范（Minecraft GUI）

### 6.0 视觉论点 / 内容计划 / 交互计划

- **视觉论点**：一台被红石点亮的「传感器工作台」——深色石砖世界、浅灰物品栏、绿色 XP 与金色成就；所有数据都像游戏内方块读数，粗粝、方正、可触摸，而不是一张做得像游戏的 SaaS 仪表盘。
- **内容计划**：启动校准 → 背包（分组物品槽卡片墙）→ 工作台（单个传感器的实时画面 + 数据 HUD）→ 返回背包。全局常驻：F3 调试栏、XP 条、聊天式事件日志、成就 toast。
- **交互计划**：卡片按下时槽位下沉 80ms；打开工作台像拉开物品栏一样 120ms 展开；成就从右上角滑入并轻弹；所有读数按 10Hz 跳变，不做平滑插值。

### 6.1 材质与颜色

| 变量 | 值 | 用途 |
|---|---|---|
| `--bg-deepslate` | `#2a2a32` | 页面最底层 |
| `--bg-stone` | `#44444c` | 主背景 |
| `--bg-dirt` | `#7a4f28` | 页脚/边缘泥土 |
| `--panel` | `#d6d6d6` | 物品栏/工作台面板 |
| `--panel-dark` | `#a0a0a0` | 面板次级区域 |
| `--slot` | `#a4a4a4` | 物品槽底 |
| `--slot-hover` | `#bebebe` | 悬停/聚焦 |
| `--grass` | `#6fbf3a` | HUD 顶栏、草地方向 |
| `--grass-dark` | `#3f7a2e` | 绿色分隔线 |
| `--sky` | `#7fc4ff` | 天空/冷色点缀 |
| `--bevel-light` | `#ffffff` | 左上高光 |
| `--bevel-mid` | `#a0a0a0` | 内层过渡 |
| `--bevel-dark` | `#373737` | 右下阴影 |
| `--text-light` | `#f2f2f2` | 深色底文字 |
| `--text-dark` | `#3f3f3f` | 浅色面板文字 |
| `--xp-green` | `#7fff2a` | XP、正常状态、频谱 |
| `--gold` | `#ffd700` | 成就、标题、罗盘 |
| `--redstone` | `#ff3b3b` | 警告、超阈值、红石线 |
| `--lapis` | `#4a6cff` | 数据高亮、选中 |
| `--sculk-cyan` | `#55ffff` | 声波、麦克风 |
| `--amethyst` | `#2a0a4a` | 提示框边框 |
| `--tooltip-bg` | `#100010` | 提示框底 |

- **斜角边框**统一用 `box-shadow: inset 2px 2px 0 var(--bevel-light), inset -2px -2px 0 var(--bevel-dark)`；面板内层再加 1px `--bevel-mid`。
- **像素纹理**：石砖、深板岩、泥土、木板、黑曜石全部用 16×16 内联 SVG data URI 生成，`image-rendering: pixelated`，每个纹理最多 4–6 个颜色、硬边、1px 噪点；不使用外部图片。
- **圆角为 0**，阴影只用 1–2px 硬阴影，不用模糊大投影。
- **禁止**玻璃拟态、柔和渐变、16px 圆角、Inter/Roboto、紫色渐变 SaaS 风。

### 6.2 排版

- **英文/数字/标题**：内嵌 `Monocraft`（SIL OFL，非官方素材）的 WOFF2 子集，仅保留 ASCII、数字、标点和常用符号，base64 内联；用于 `CAMERA`、`READY`、`Lv.7`、F3 行、大号读数。
- **中文**：系统 CJK 字体栈（`"PingFang SC", "Noto Sans SC", "Microsoft YaHei", sans-serif`）。中文不强行像素化，用 `text-shadow: 2px 2px 0 #3f3f3f`（深色底）或 `1px 1px 0 #ffffff`（浅色面板）保持方块感。
- 字号只用 8 / 10 / 12 / 14 / 16 / 24 / 32px；读数右对齐，使用 tabular 数字。
- 英文小标签全大写并加 0.04em 字距；中文正文 14–16px，状态角标 10px。
- 不在 UI 里使用 emoji 代替图标。

### 6.3 布局与屏幕

- **背包视图**：居中的物品栏面板（`max-width: 760px`），标题栏含 `SENSORCRAFT`、倾斜的黄色 splash 文本、版本号；分组标题横跨整行；手机 4 列（槽 72px），桌面 6–8 列；适配 iPhone 安全区。
- **工作台视图**：全屏面板；顶部 48px 标题栏（返回、图标、名称、状态）；主体可滚动；底部粘性数据 HUD；左上返回、右上状态。
- **横屏**：工作台自动变成双栏（左画面、右数据）；竖屏上下堆叠。
- **F3 调试栏**：左上角等宽小字，默认折叠成一个 `F3` 按钮，点开后显示 `SENSORCRAFT v1.0`、`secure`、`sensors`、`fps`、`mode`。
- **聊天式日志**：左下角，最多 3 行，半透明黑底；`[SENSORCRAFT]` 黄色前缀，消息白色；8 秒后淡出。
- **XP 条**：底部固定，9px 高，黑色槽 + 绿色分段填充；左侧 `Lv.1 探索者`。
- **安全区**：所有固定元素加 `env(safe-area-inset-*)`。
- **竖屏优先**：iPhone 竖屏下工作台单列；读数面板双列紧凑；1:1 画布最高 52vh；工具栏按钮 ≥44px；首屏尽量同时看到主要画面和读数。

### 6.4 组件

- **物品槽卡片**：64–72px 正方形槽、内凹斜角、图标占槽约 88%（优先填满卡片）、下方名称、右上状态角标（`READY` / `PARTIAL` / `LOCKED`）；悬停/聚焦是 2px 白色描边 + 提示框；锁定卡整体去饱和并叠加屏障/锁图标。
- **提示框**：深紫黑底、紫色 1px 边框、白色文字、2px 硬阴影；显示中英文名、状态、一句可执行说明。
- **MC 按钮**：灰底斜角，悬停提亮，按下边框反转，禁用去饱和；最小 44px。
- **开关**：拉杆风格（左关右开，红石灯亮起）或槽位勾选；必须带文字状态。
- **滑杆**：灰色带刻度的轨道 + 12×18 斜角手柄 + 当前值气泡。
- **XP 条**：分段填充，不做连续渐变；用于信号、音量、进度。
- **成就 toast**：右上角，深灰 `#212121`、2px 金边、32px 图标槽、`成就达成！` 主标题 + 副标题；3 秒消失，最多同时 1 条。
- **错误面板**：红石红顶边 + `红石信号中断` + 原因 + 重试按钮 + 权限设置提示。
- **空状态**：箱子/漏斗图标 + 一行说明，如「手柄未连接，按任意键唤醒」。
- **加载态**：`正在生成地形…` 的像素进度条，不用旋转 spinner。

### 6.5 传感器 → Minecraft 物品映射

| 卡片 | 像素图标参考 | 主色 |
|---|---|---|
| 摄像头 | 望远镜 / 观察者 | 金 + 深灰 |
| 麦克风 | 幽匿感测体 | 青 + 深蓝 |
| 补光灯 | 火把 / 萤石 | 黄 + 橙 |
| 加速度计 | 重锤 / 落沙 | 棕 + 红石 |
| 陀螺仪 | 末影水晶 / 旋风棒 | 品红 + 青 |
| 姿态与指南针 | 指南针 | 红 + 白 |
| GPS | 藏宝图 | 羊皮纸黄 + 棕 |
| 多点触控 | 石质压力板 | 灰 + 红石 |
| 扬声器/语音 | 音符盒 | 木色 + 绿 |
| 游戏手柄 | 命令方块 | 橙 + 灰 |
| 屏幕常亮 | 营火 | 橙 + 黄 |
| WebGPU | 附魔台 | 紫 + 青 |
| 手动相机 | 红石比较器 | 红石红 + 灰 |
| Face ID | 村民 / 命名牌 | 绿 + 棕 |
| 未解锁 | 屏障 / 基岩 | 灰 + 深紫 |

图标全部用内联 SVG 的 16×16 / 32×32 像素网格绘制，不引用官方贴图。

### 6.6 模块画面艺术方向

- **摄像头 · 望远镜**：黑曜石色取景框、四角准星、中心十字、红色 `REC` 点；拍照时全屏白闪 + 金色成就。
- **麦克风 · 幽匿感测体**：声波扩散环 + 绿色 XP 频谱柱；大号 dB 数字，超过 85 闪红并显示 `TNT`。
- **加速度计 · 落沙与水平仪**：三轴红石信号条 +  lodestone 框里的气泡球；步数用像素脚印计数。
- **陀螺仪 · 末影水晶**：水晶随角速度旋转，峰值 RPM 用金色数字。
- **指南针 · 探险家罗盘**：像素罗盘盘面 + 红色指针 + 中文方位；水平时指针变绿。
- **GPS · 藏宝图**：羊皮纸网格地图，红石粉轨迹，路点用旗帜标记；速度/海拔用告示牌 HUD。
- **多点触控 · 压力板**：每个触点是一块亮起的石质压力板，编号用像素数字；点靶小游戏用矿石块当靶心。
- **扬声器 · 音符盒**：播放时升起像素音符粒子；TTS 用村民对话气泡。
- **游戏手柄 · 命令方块**：按键格像命令方块亮起，摇杆值显示为红石信号强度 0–15。
- **常亮 · 营火**：开启时火焰变亮、火星上升；关闭时只剩烟。
- **WebGPU · 附魔台**：符文列表逐行亮起，适配器信息像附魔描述。
- **手动相机 · 红石比较器**：变焦/对焦/曝光做成三个比较器旋钮；不支持时显示灰色 `无信号`。
- **Face ID · 村民交易**：交易界面 + 红色 `无法读取生物特征` 印章。

### 6.7 动效

- **总原则**：量化、分步、像素对齐；不做平滑缓动和模糊。
- 卡片按下：槽位下沉 1px，80ms 内完成。
- 打开工作台：3 帧展开（0/40/80ms 的阶梯透明与 2px 位移），像拉开物品栏。
- 成就 toast：180ms 从右侧滑入 + 2px 回弹。
- Splash 文本：每 2 秒上下浮动 1px。
- XP / 频谱 / 进度：按段跳变，不连续插值。
- 读数：最高 10Hz 更新；数值变化时短暂加 1 帧白色高亮。
- 悬停：图标上移 1px，槽位描边变白。
- 禁止：视差滚动、装饰性粒子雨、模糊光晕、无意义的无限旋转。
- `prefers-reduced-motion: reduce` 时关闭 splash 浮动、回弹和粒子。

### 6.8 明确避免

- 不使用 Mojang 官方贴图、字体、音效；`Monocraft` 是独立 OFL 字体，程序化纹理是自绘 SVG。
- 不把卡片做成普通圆角 SaaS 卡片；它必须是物品槽，因为卡片本身就是交互单位。
- 不用紫色渐变、玻璃拟态、霓虹发光来「假装高级」。
- 不用 emoji 代替像素图标。
- 不让平滑插值假装传感器在动；数据该怎么跳就怎么跳。
- 不在 UI 里出现提示词语言、AI 自述或设计说明。

## 7. 模块设计

每个模块遵循统一契约：

```js
{
  id, name, en, group, icon,
  probe(ctx) -> { status, reason?, detail? },
  mount(ctx) -> cleanupFn,   // 可返回释放函数
}
```

`ctx` 提供：`root`、`toast()`、`log()`、`onCleanup()`、`raf()`、`interval()`、`listen()`、`ensureStream()`、`feature`。模块内部不直接操作全局状态。

### 7.1 摄像头 `camera`

- **入口**：请求 `{ video: { facingMode } }`，默认后置；成功后显示视频。
- **画面**：4:3 取景框（`object-fit: cover`），十字准星、四角取景标记；顶部 HUD 显示 `RES`、`FPS`、`CAM`。
- **数据**：每 250ms 从隐藏画布采样中心 10×10 像素，显示平均色块与 `#RRGGBB`，亮度映射到 XP 条。
- **交互**：切换前后镜头、拍照（下载/长按保存提示）、暂停/继续。
- **失败**：区分「未授权」「没有摄像头」「被其他 App 占用」「非 HTTPS」。
- **成就**：首次看见画面「睁眼看世界」；首次拍照「记录者」。
- **释放**：停止所有 track、取消 rAF、移除 video srcObject。

### 7.2 麦克风 `microphone`

- **入口**：`getUserMedia({ audio: { echoCancellation:false, noiseSuppression:false } })`。
- **画面**：上：示波器（时域）；中：32 段频谱柱；下：大号 dB 数字 + 主频 + 音名。
- **数据**：`AnalyserNode`，`fftSize = 2048`；dB 用 RMS 近似并标注「相对值」；主频取频谱峰值；音名按十二平均律换算。
- **交互**：开始/停止、峰值保持开关、灵敏度滑杆。
- **反馈**：>85 显示红色「TNT 警告」；静音时显示「信号微弱」。
- **成就**：首次采集「听见世界」；检测到 >100 dB「爆破专家」。
- **释放**：停止 track、`AudioContext.close()`。

### 7.3 补光灯 `torch`

- **探测**：打开临时后置流，读 `track.getCapabilities().torch`。
- **画面**：一盏萤石灯；支持时显示开关与状态。
- **失败**：iOS 不稳定时明确写「当前系统/浏览器不开放网页控制补光灯」。
- **释放**：关闭流。

### 7.4 加速度计 `accelerometer`

- **入口**：`DeviceMotionEvent`；需在用户手势中请求权限。
- **画面**：三条 X/Y/Z 柱、合矢量数字、一个随重力倾斜的气泡球 Canvas。
- **派生**：步数（带阈值的峰值检测）、摇晃强度、自由落体（合矢量接近 0）。
- **兼容**：iOS 通常提供 `accelerationIncludingGravity`；`acceleration`（线性）可能为 `null`，此时只显示含重力数据并注明。
- **交互**：切换「含重力 / 线性」、重置计数。
- **成就**：走出 10 步「小小探险家」；检测到自由落体「掉进虚空」。
- **释放**：移除监听、取消 rAF。

### 7.5 陀螺仪 `gyroscope`

- **入口**：`DeviceMotionEvent.rotationRate`。
- **画面**：像素方块按角速度旋转；三轴数值与柱状条；峰值 RPM。
- **交互**：重置峰值。
- **成就**：转速超过 360°/s「旋转木马」。
- **降级**：无 `rotationRate` 时显示「此设备未提供陀螺仪数据」。

### 7.6 姿态与指南针 `orientation`

- **入口**：`DeviceOrientationEvent`（α/β/γ + `webkitCompassHeading`）。
- **画面**：Canvas 罗盘盘面（N/E/S/W + 中文方位）、水平气泡、三轴数字。
- **兼容**：iOS 的 `alpha` 与 `webkitCompassHeading` 区别要在 UI 注明；无指南针时显示「相对方向」。
- **成就**：转到正北「找到北方」；保持水平 3 秒「稳如磐石」。

### 7.7 GPS 定位 `geolocation`

- **入口**：`watchPosition({ enableHighAccuracy:true, maximumAge:2000, timeout:10000 })`。
- **画面**：Canvas 轨迹（自动缩放）、当前位置点、经纬度、精度圈、速度（km/h）、海拔、累计里程。
- **交互**：开始/停止、清空轨迹、复制坐标。
- **失败**：区分「拒绝授权」「定位超时」「室内精度低」。
- **性能**：轨迹最多保留 500 个点；仅在视图可见时更新。
- **成就**：移动 100 米「走出新手村」。

### 7.8 多点触控 `multitouch`

- **画面**：全屏 Canvas，每个触点一个带编号的彩色像素方块，外围 HUD 显示触点数与最大同时触点数。
- **小游戏**：「点靶」——随机出现 5×5 像素靶，记录反应时间与命中率。
- **成就**：同时 5 指「五指琴魔」；反应 <250ms「闪电侠」。
- **释放**：移除 pointer/touch 监听、取消 rAF。

### 7.9 扬声器/语音 `speaker`

- **音调**：频率滑杆 20–2000Hz、波形（sine/square/sawtooth/triangle）、播放/停止；显示音名与周期。
- **TTS**：文本输入 + 声音选择 + 语速；`speechSynthesis` 不支持时禁用。
- **语音识别**：检测 `SpeechRecognition || webkitSpeechRecognition`；iOS Safari 常返回 `service-not-allowed`，此时禁用按钮、显示「不是麦克风权限问题」并降级到「打开麦克风」；支持时显示转写文本与置信度。
- **成就**：播放 440Hz「调音师」；完成一次朗读「会说话的村民」。

### 7.10 游戏手柄 `gamepad`

- **入口**：`navigator.getGamepads()`；`gamepadconnected` / `gamepaddisconnected`。
- **画面**：按键格（0–17）亮灭、两个摇杆坐标、手柄 id。
- **空状态**：「未连接。先在系统蓝牙里连接 PS/Xbox 手柄，再按任意键」。
- **成就**：连接手柄「召唤坐骑」。

### 7.11 屏幕常亮 `wakelock`

- **入口**：`navigator.wakeLock.request('screen')`。
- **画面**：不灭之火的开关、当前状态、系统版本建议。
- **行为**：页面可见性恢复时自动重新申请；用户关闭后不再自动申请。
- **降级**：不支持时显示「iOS 16.4 以下或非安全上下文不可用」。

### 7.12 WebGPU `webgpu`

- **入口**：`navigator.gpu.requestAdapter()`。
- **画面**：附魔台风格的特性列表：适配器名称、后端、`features`、`limits`（只读展示关键项）。
- **降级**：不可用显示「尚未附魔：iOS 26 起才支持，且可能需开启实验特性」。
- **安全**：只读取信息，不申请写入权限。

### 7.13 手动相机控制 `camera-manual`

- **探测**：打开后置流，读取 `getCapabilities()` 的 `zoom`、`focusMode`、`exposureMode`、`torch`。
- **画面**：红石相机样式；支持的滑杆可动，不支持的灰显并写原因。
- **说明**：iOS Safari 基本不开放；Android Chrome 较完整。不伪造控制效果。
- **释放**：关闭流。

### 7.14 Face ID / Touch ID `biometrics`

- **画面**：村民交易台信息卡；说明「网页只能借助系统登录流程，无法读取脸或指纹数据」，并列出可以做/不可以做的边界。
- **交互**：一个「查看 WebAuthn 说明」的折叠区块，不实际调用生物识别。
- **成就**：阅读完毕「交易达成」。

## 8. 技术架构

### 8.1 文件架构（多文件、经典脚本 + 命名空间、零构建）

```text
webapp/sensor-craft/
├── index.html                     # 应用外壳：HUD、背包、工作台、toast、权限门
├── README.md                      # 部署、支持矩阵、扩展指南、单文件构建
├── css/
│   ├── font.css                   # 内嵌 Monocraft ASCII 子集（OFL）
│   ├── tokens.css                 # 颜色/间距/字体/斜角边框变量
│   ├── base.css                   # reset、背景纹理、排版、可访问性
│   ├── layout.css                 # HUD、背包、工作台、响应式
│   └── components.css             # 卡片、按钮、XP 条、toast、错误面板
├── js/
│   ├── core/
│   │   ├── namespace.js           # window.SC 初始化、版本、常量
│   │   ├── dom.js                 # $, el, escapeHtml, on, debounce
│   │   ├── format.js              # 数字/单位/音名/中文方位
│   │   ├── log.js                 # 事件日志 + 全局错误兜底
│   │   ├── context.js             # 模块 ctx 工厂 + 清理栈
│   │   ├── probe.js               # 统一能力检测与自检快照
│   │   ├── permissions.js         # 安全上下文、iOS 运动/姿态权限
│   │   ├── wake-lock.js           # 屏幕常亮服务
│   │   ├── registry.js            # SC.registerSensor / SC.getSensors
│   │   └── lifecycle.js           # open/close、历史、资源释放
│   ├── ui/
│   │   ├── icons.js               # 16×16 内联 SVG 像素图标
│   │   ├── toast.js               # 成就队列
│   │   ├── hud.js                 # 顶部 F3 状态栏
│   │   ├── bag.js                 # 卡片墙与分组渲染
│   │   ├── bench.js               # 工作台壳、标题、返回
│   │   ├── gate.js                # 首次校准门
│   │   └── debug.js               # 调试日志 + GitHub Issue 预填
│   ├── sensors/
│   │   ├── locked.js              # 12 张锁定卡的通用工厂
│   │   ├── camera.js
│   │   ├── microphone.js
│   │   ├── torch.js
│   │   ├── accelerometer.js
│   │   ├── gyroscope.js
│   │   ├── orientation.js
│   │   ├── geolocation.js
│   │   ├── multitouch.js
│   │   ├── speaker.js
│   │   ├── gamepad.js
│   │   ├── wakelock.js
│   │   ├── webgpu.js
│   │   ├── camera-manual.js
│   │   └── biometrics.js
│   └── main.js                    # 启动：检测 → 渲染 → 绑定 → 自检
├── server/                        # 可选：Cloudflare Worker / Vercel 日志代理（token 只在服务端）
├── build/
│   ├── build-standalone.mjs       # 可选：把多文件内联为 dist/sensor-craft.html
│   ├── subset-font.sh             # 开发期：把 Monocraft 子集化并输出 base64 CSS
│   └── fonts/                     # Monocraft 子集与 OFL 许可证
├── dist/                          # 构建产物（gitignore）
└── tests/
    └── manual-checklist.md        # iPhone/桌面实测清单
```

**为什么不用 ES Modules？** 本项目需要同时满足「清晰的多文件结构」和「可生成单个离线 HTML」。用经典脚本 + 单一命名空间（`window.SC`）可以让构建脚本只做按顺序拼接和内联，不需要打包器；同时 `file://` 也能打开界面（传感器 API 仍需 HTTPS）。代价是脚本加载顺序必须显式维护，因此由 `index.html` 固定顺序，`main.js` 永远最后加载。

**命名与边界约定：**

- 每个文件一个 IIFE：`(function (SC) { … })(window.SC = window.SC || {});`
- 所有全局只挂在 `SC` 下（`SC.core`、`SC.ui`、`SC.sensors`），不新增其他全局变量。
- 每个文件内部函数用文件前缀命名（如 `cameraMount`、`bagRender`），避免拼接后重名。
- 传感器文件只做两件事：`SC.registerSensor({...})` 和定义本模块函数；加载时不得产生副作用。
- `index.html` 只放挂载点和按顺序的 `<link>`/`<script defer>`，不放业务代码。
- 依赖方向：`sensors → core/context`（通过 ctx 使用能力），`ui → core`，`core` 不反向依赖 `ui`。

**`index.html` 外壳：**

```html
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#333333">
  <title>SENSORCRAFT · iPhone 传感器实验室</title>
  <link rel="stylesheet" href="./css/tokens.css">
  <link rel="stylesheet" href="./css/base.css">
  <link rel="stylesheet" href="./css/layout.css">
  <link rel="stylesheet" href="./css/components.css">
</head>
<body>
  <div id="app">
    <header id="hud"></header>
    <main id="bag-view"></main>
    <section id="bench-view" hidden></section>
    <footer id="xp-bar"></footer>
    <div id="toast-stack" aria-live="polite"></div>
    <div id="gate" role="dialog" aria-modal="true"></div>
  </div>

  <script defer src="./js/core/namespace.js"></script>
  <script defer src="./js/core/dom.js"></script>
  <script defer src="./js/core/format.js"></script>
  <script defer src="./js/core/log.js"></script>
  <script defer src="./js/core/context.js"></script>
  <script defer src="./js/core/probe.js"></script>
  <script defer src="./js/core/permissions.js"></script>
  <script defer src="./js/core/wake-lock.js"></script>
  <script defer src="./js/core/registry.js"></script>
  <script defer src="./js/core/lifecycle.js"></script>
  <script defer src="./js/ui/icons.js"></script>
  <script defer src="./js/ui/toast.js"></script>
  <script defer src="./js/ui/hud.js"></script>
  <script defer src="./js/ui/bag.js"></script>
  <script defer src="./js/ui/bench.js"></script>
  <script defer src="./js/ui/gate.js"></script>
  <script defer src="./js/sensors/locked.js"></script>
  <script defer src="./js/sensors/camera.js"></script>
  <!-- …其余传感器，顺序无关，只要在 main.js 之前… -->
  <script defer src="./js/main.js"></script>
</body>
</html>
```

**可选单文件构建：** `build/build-standalone.mjs` 读取 `index.html`，按出现顺序把 `<link rel="stylesheet">` 替换为 `<style>`、把 `<script src>` 替换为内联 `<script>`，输出 `dist/sensor-craft.html`。无第三方依赖，只用 Node 内置 `fs`/`path`。构建产物与源码行为一致，仍受 HTTPS 限制。

### 8.2 公共上下文 `ctx`

| 能力 | 说明 |
|---|---|
| `ctx.root` | 当前模块的 DOM 容器 |
| `ctx.toast({icon,title,subtitle})` | 成就提示，自动排队 |
| `ctx.log(text)` | 事件日志 |
| `ctx.onCleanup(fn)` | 注册清理函数 |
| `ctx.raf(cb)` | 受管理的 `requestAnimationFrame` 循环 |
| `ctx.interval(cb, ms)` | 受管理的定时器 |
| `ctx.listen(target, type, fn, opts)` | 受管理的监听器 |
| `ctx.ensureStream(constraints)` | 申请并登记 MediaStream |
| `ctx.motionPermission()` | 在用户手势中请求运动/姿态权限 |
| `ctx.feature` | 能力检测结果快照 |
| `ctx.setReadout(html)` | 更新工作台右侧数据 HUD |

### 8.3 生命周期

```text
open(id)
  ├─ 若已有模块：unmount() → releaseAll()
  ├─ mount(module, ctx)
  ├─ pushState(#id)
  └─ 更新标题/状态
close()
  ├─ unmount() → releaseAll()
  ├─ clear #id
  └─ 回到背包
visibilitychange(hidden)
  └─ 停止高频采样与绘制；媒体类模块释放流
visibilitychange(visible)
  └─ 媒体类模块显示「已暂停，点击重新开始」，不自动偷偷恢复
```

- 每个模块的 `mount` 用 `try/catch` 包裹；异常显示错误面板，不污染全局。
- `releaseAll()` 幂等：重复调用安全。

### 8.4 权限门 `gate`

- 首次进入显示全屏 MC 风格对话框，解释「点击开始会申请运动与姿态权限」。
- 主按钮「开始冒险」必须在用户手势内调用：
  1. `DeviceMotionEvent.requestPermission?.()`
  2. `DeviceOrientationEvent.requestPermission?.()`
  3. `navigator.wakeLock.request?.('screen')`（失败静默）
- 其他权限（摄像头、麦克风、定位）在各自模块打开时按需申请，不在启动时一次性轰炸。
- 选择「稍后」也能进入背包；首次点开运动类卡片时再触发权限门。

### 8.5 安全上下文与部署

- 摄像头、麦克风、定位需要 HTTPS 或 `localhost`。
- 若 `!window.isSecureContext`：顶部显示红色横幅「当前不是安全上下文，摄像头/麦克风/定位将不可用」。
- 部署建议（写进页面帮助气泡，不写在代码注释里）：
  - 电脑本地：`python3 -m http.server` 后访问 `http://localhost:8000/...`。
  - iPhone：部署到 GitHub Pages / 任意 HTTPS 静态托管；或使用可信的 HTTPS 隧道。
  - 不保证通过「文件 App 直接打开」能访问摄像头/麦克风。

## 9. 兼容与降级策略

| 场景 | 行为 |
|---|---|
| API 不存在 | `probe()` 返回 `locked` + 原因；卡片灰显但可点 |
| 权限被拒绝 | 错误面板 + 重试 + 系统设置指引 |
| API 存在但返回空 | 空状态文案，不显示 NaN |
| iOS 权限必须手势 | 统一通过权限门/模块按钮触发 |
| 页面切到后台 | 释放摄像头/麦克风并停止高频采样；恢复时提示点击重新开始 |
| 屏幕旋转/尺寸变化 | 所有 Canvas 按 `devicePixelRatio` 重算，最多 2 次防抖 |
| 低端机卡顿 | 频谱降到 16 段；图表最高 30fps；文本读数最高 10Hz |

## 10. 错误处理

- **统一错误类型**：`{ code, title, message, retry? }`。
- 常见 code：`PERMISSION_DENIED`、`NOT_FOUND`、`NOT_SUPPORTED`、`INSECURE_CONTEXT`、`DEVICE_BUSY`、`TIMEOUT`、`UNKNOWN`。
- 错误面板必须包含：发生了什么、为什么、下一步怎么做。
- 所有 Promise 链必须 `.catch()`；`window.onunhandledrejection` 兜底写入事件日志并 toast。
- 传感器数值异常（NaN/Infinity）显示 `--`，不打印到界面。

## 11. 性能与资源释放

- 离开模块时：停止 MediaStream 所有 track、关闭 AudioContext、移除全部监听器、取消 rAF/interval。
- 摄像头/麦克风同时只允许一个模块占用。
- GPS 轨迹点上限 500；触摸点上限 10；聊天日志最多显示 3 行。
- 文本 DOM 更新节流到 10Hz；Canvas 绘制优先 rAF。
- 不在 `visibilitychange` 后继续耗电。
- 页面首次加载目标 < 300KB（含内嵌 Monocraft ASCII 子集；无外部图片、无网络字体请求）；单文件构建产物目标 < 300KB。

## 12. 可访问性与儿童友好

- 所有交互控件用原生 `<button>`/`<input>`；图标按钮带 `aria-label`。
- 状态变化通过 `aria-live="polite"` 宣告；不只用颜色表达状态，同时有文字角标。
- 支持键盘：`Tab` 遍历、`Enter` 打开、`Esc` 返回。
- 最小字号 12px，正文 14–16px；数字读数 ≥ 24px。
- 文案用短句和拟物比喻，但不牺牲准确性。
- 不包含闪烁频率 3–55Hz 的强闪光；拍照白闪仅 150ms 且只触发一次。

## 13. 扩展指南（给未来的自己）

新增一个传感器/实验只需四步：

1. 新建 `js/sensors/my-sensor.js`，用 IIFE 注册：

```js
(function (SC) {
  SC.registerSensor({
    id: 'my-sensor',
    name: '我的传感器',
    en: 'MY SENSOR',
    group: '运动与环境',
    icon: SC.ui.icons.mySensor,
    probe() {
      return navigator.myAPI
        ? { status: 'ready' }
        : { status: 'locked', reason: '当前浏览器不支持 My API' };
    },
    mount(ctx) {
      ctx.root.innerHTML = `…`;
      ctx.listen(window, 'myevent', e => {
        ctx.setReadout('值：' + e.value);
      });
    }
  });
})(window.SC = window.SC || {});
```

2. 在 `index.html` 的传感器脚本区加一行 `<script defer src="./js/sensors/my-sensor.js"></script>`，位置在 `main.js` 之前。
3. 如需专属样式，在 `css/components.css` 加 `m-<id>-` 前缀的类；模块内样式由 `ctx.root` 限定。
4. 页面内「自检面板」会自动出现该模块的探测结果，无需额外注册。

约束：

- 模块不得直接改全局 DOM id，只能操作 `ctx.root`。
- 模块不得自己创建永久定时器；一律用 `ctx.raf` / `ctx.interval` / `ctx.listen`。
- 模块的 `mount` 必须通过 `ctx.onCleanup()` 或返回值注册清理逻辑。
- 传感器之间不得互相依赖；共享逻辑放 `core/`。
- 新增文件后记得同步更新 `build-standalone.mjs` 的脚本顺序（它直接读取 `index.html`，通常无需改代码）。

## 14. 验收标准

### 14.1 功能

- [ ] 桌面 Chrome（HTTP localhost）打开无控制台报错，卡片墙完整渲染。
- [ ] 每张 `ready`/`partial` 卡片可打开、显示实时数据或画面、可返回。
- [ ] 每张 `locked` 卡片可打开，显示中文原因与替代建议，不抛异常。
- [ ] 摄像头前后切换、拍照、取色、亮度条工作。
- [ ] 麦克风波形/频谱/dB/主频工作，停止后麦克风指示灯熄灭。
- [ ] 加速度计、陀螺仪、姿态在 iPhone 上授权后产生数据。
- [ ] GPS 轨迹、速度、里程、清空工作。
- [ ] 多点触控可同时显示多指，反应力小游戏可完成。
- [ ] 音调发生器、TTS 工作；语音识别不支持时有明确说明。
- [ ] Wake Lock 开关状态真实反映系统行为。
- [ ] 自检面板的结论与实际表现一致。
- [ ] `node build/build-standalone.mjs` 能生成 `dist/sensor-craft.html`，且与源码版行为一致。

### 14.2 资源与稳定性

- [ ] 连续打开/关闭摄像头 10 次，无内存明显增长、无残留音视频轨道。
- [ ] 返回背包后，iOS 状态栏的麦克风/摄像头指示消失。
- [ ] 页面切后台再回来，不出现重复监听或双份绘制。

### 14.3 视觉与交互

- [ ] 在 iPhone 390×844、桌面 1280×800 下布局正常，无横向滚动。
- [ ] 卡片触控目标 ≥ 44px，点击反馈明确；图标接近占满物品槽，状态角标不遮挡主要图形。
- [ ] iPhone 竖屏进入任意模块后，主要画面和读数在首屏内可读，不出现横向滚动。
- [ ] 成就 toast 不遮挡返回按钮。
- [ ] 尊重 `prefers-reduced-motion`。

### 14.4 可访问性

- [ ] 键盘可完成「打开卡片 → 返回」。
- [ ] 所有图标按钮有可读标签。
- [ ] 状态不只靠颜色区分。

## 15. 测试计划

1. **桌面 Chrome**：逐卡打开，检查控制台、布局、降级空状态；用设备模拟检查 390px 宽度。
2. **iPhone Safari（HTTPS）**：重点测权限门、运动权限、摄像头/麦克风、GPS、常亮、返回释放。
3. **异常路径**：拒绝权限、飞行模式、摄像头被占用、非 HTTPS、页面切后台。
4. **压力**：连续开合、快速切换卡片、旋转屏幕。
5. **构建**：运行 `build-standalone.mjs`，用浏览器直接打开产物，确认脚本顺序与资源内联正确。
6. **记录**：在 `webapp/sensor-craft/README.md` 放一张「设备 × 模块」实测表（可选，不阻塞交付）。

## 16. 风险与开放问题

| 风险 | 影响 | 缓解 |
|---|---|---|
| iOS 版本差异导致权限/传感器行为变化 | 某些卡片在旧系统不可用 | 全部走 `probe()`，锁定卡解释，不硬编码假设 |
| `file://` 打开无法用摄像头/麦克风 | 用户以为网页坏了 | 顶部安全上下文横幅 + 部署说明 |
| 补光灯 iOS 不稳定 | 开关无效 | 标 `partial`，只做能力检测与提示 |
| WebGPU 仅在 iOS 26+ 且可能需实验开关 | 大部分设备不可用 | 锁定/受限卡，不阻塞其他功能 |
| 语音识别 iOS 不支持 | 功能缺失 | 明确说明，TTS 仍可用 |
| 长时间打开摄像头发热耗电 | 体验差 | 离开即释放、后台暂停、页面提示 |
| 多文件脚本顺序需手动维护 | 漏加载/顺序错误导致启动失败 | 所有脚本 `defer`；`main.js` 固定最后；启动时自检缺失模块并提示 |

开放问题（不阻塞首版）：

- 是否需要在页面内提供「生成分享链接」或二维码，方便课堂上让学生打开？首版不做。
- 是否要把实测表做成页面内的「设备报告」导出？首版只做自检面板，不导出。
- 是否加入更多小游戏（如声控跳跃、重力迷宫）？首版保留多点触控反应力游戏，其余留作扩展。

## 17. 交付清单

1. `webapp/sensor-craft/`：完整多文件静态应用（`index.html` + `css/` + `js/`）。
2. `webapp/sensor-craft/README.md`：部署方式（HTTPS/本地服务器）、支持矩阵、如何新增卡片、如何生成单文件。
3. `webapp/sensor-craft/build/build-standalone.mjs`：可选构建脚本，输出 `dist/sensor-craft.html`。
4. 本设计文档。
5. 不自动提交 git；由用户确认后再决定是否 commit。
