# A-Level Helper — 已知问题 & 鸿蒙开发经验

## 一、当前已知问题

### 1. ~~相机功能未实现~~ [已修复 v2.1]

**修复于 Session 3 (2026-03-15)：** `CameraPage.ets` 已重写为双模式 UI：
1. **相册选图**（主要）：使用 `PhotoViewPicker` 系统 UI，无需权限声明
2. **手动文本输入**（备选）：TextArea + "Solve with AI" 按钮

完整流程已打通：相册选图 → `PhotoPreviewPage` → OCR → `SolutionPage`

---

### 2. OCR 不支持数学符号 [Major]

**现状：** `OcrService.ets` 使用 `@kit.CoreVisionKit` 的 `textRecognition.recognizeText()`，这是通用文本 OCR，只支持中英文印刷体。

**问题：** 数学公式（分数、积分号、上下标、希腊字母）会被误识别或丢失。对于 A-Level 数学题目来说，这是根本性的限制。

**解决方向：**
- 短期：手动文本输入 + AI 解析（当前方案，可用）
- 中期：接入专业数学 OCR 服务（如 Mathpix API）
- 长期：多模态 AI 直接识别图片（见 VISION.md Phase 3）

---

### 3. AI 功能依赖外部 API Key [Medium] — 部分修复

**现状：** AI 辅导和解题需要用户自行在设置页配置 MiniMax API Key。

**已修复 (v2.1)：**
- ✅ 添加了 API Key 预检查：在 QuizPage、CameraPage、PhotoPreviewPage 点击 AI 功能前弹出 AlertDialog 提示
- ✅ 添加了 "Test API" 按钮和结果显示，方便调试 Key 问题
- ✅ 修复了 API 域名（`api.minimax.chat`，非 `api.minimax.io`）

**仍存在：**
- 没有内置的免费 tier 或 fallback
- API Key 需要用户自行获取

---

### 4. ~~会话内存泄漏~~ [已修复 v2.1]

**修复于 Session 3 (2026-03-15)：**
- `QuizPage.ets`：添加 `closeChatPanel()` 关闭时清理 + `aboutToDisappear()` 兜底
- `SolutionPage.ets`：添加 `aboutToDisappear()` 调用 `clearSession()`

---

### 5. 数学渲染缺失 [Medium]

**现状：** AI 回答中的数学表达式以纯文本显示（`x^2`, `sqrt()`, `a/b`）。

**期望：** 渲染为标准数学符号（LaTeX 或类似格式）。

---

### 6. HTTP 流式传输不可用 [Major — 平台限制]

**现状：** 改为非流式 `request()` 调用（`stream: false`），完整回复一次性显示。

**根因：** HarmonyOS `requestInStream` 的 `dataReceive` 事件在接收若干 chunk 后**停止触发**。这是[华为已知 Bug](https://bbs.itying.com/topic/678d98114b218c005fa23295)，已上报但未修复。

**尝试过的方案（均失败）：**
1. ❌ 字节累积 + 全量解码 — `TextEncoder.encodeInto()` 返回 `{read, written}` 不是 `Uint8Array`，导致闪退
2. ❌ `processedTextLen` 偏移追踪 — 仍然卡住
3. ❌ 每 chunk 独立解码 — 仍然卡住
4. ❌ `setTimeout` 模拟流式 — `@State` 更新不触发 UI 刷新，也卡住

**当前方案：** 非流式调用，等待完整回复后一次显示。可靠但无打字机效果。

**未来方向：**
- 尝试 **RCP (`@kit.RemoteCommunicationKit`)**：华为官方推荐的新网络库，可能有更好的流式支持
- 等待华为修复 `requestInStream` Bug

---

## 二、鸿蒙开发经验总结（26 条教训）

> 以下问题在 HarmonyOS NEXT API 22 / SDK 6.0.2 开发中实际遇到过，均已解决。记录下来避免重蹈覆辙。

### A. 构建配置类

| # | 问题 | 正确做法 |
|---|------|---------|
| 1 | SDK 版本格式：用整数 `12` 会报错 | 必须用字符串 `"6.0.2(22)"`，三个字段都要设：`compileSdkVersion`, `compatibleSdkVersion`, `targetSdkVersion` |
| 2 | `hvigor-ohos-plugin` 放在 ohpm 依赖里会下载失败 | 必须放在 `hvigor/hvigor-config.json5` 里用 `file:` 本地路径引用 DevEco Studio 内置版本 |
| 3 | `hvigor-config.json5` 不支持 `execution.analyzeFiles` 字段 | 只允许的 execution 属性：`analyze`, `daemon`, `incremental`, `parallel`, `typeCheck`, `optimizationStrategy` |
| 4 | 缺少 app icon 会导致资源编译失败 | 必须提供有效的 1024×1024 PNG 图标文件 |

### B. ArkTS 严格模式类

| # | 问题 | 正确做法 |
|---|------|---------|
| 5 | 联合字面量类型 `'user' \| 'assistant'` 用于 `@Prop`/接口会报错 | 用基础类型 `string` 代替 |
| 6 | `@Prop` 不能直接接收复杂对象类型 | 要么拆成原始类型的多个 `@Prop`，要么提供完整默认值对象 |
| 7 | `JSON.parse(str) as SomeType` 内联转型被禁止 | 用中间变量：`const parsed: T = JSON.parse(str)` |
| 8 | `@Component` struct 中不能用 getter/setter | 改为普通方法：`get foo()` → `getFoo()` |
| 9 | 非空断言 `!` 操作符被禁止 | 用 `?.` 可选链 + `??` 空值合并代替 |
| 10 | `@State` 变量不能加 `private` 修饰符 | 移除 `private`，所有 ArkUI 装饰器变量都不加访问控制 |
| 11 | 未使用的 `@Prop` 声明会报错/警告 | 及时清理无用的 prop 声明 |

### C. API 变更类

| # | 问题 | 正确做法 |
|---|------|---------|
| 12 | 系统图标 `ohos_ic_public_settings` 在 API 22 中不存在 | 用 emoji `Text('⚙')` 代替；`ohos_ic_public_arrow_left` 仍可用 |
| 13 | `route_map.json` 要求每个页面文件导出 `@Builder` 函数 | 每个页面必须有 `@Builder export function XPageBuilder() { XPage() }`；`Index.ets` 不再用 `.navDestination()` |
| 14 | `navPathStack.getParamByName()` 返回 `Object[]` 不是强类型 | 先转 `Object[]`，再逐个元素 `as T` 转型 |
| 15 | `TextInput.onSubmit()` 回调签名变了 | 必须加参数：`(enterKey: EnterKeyType) => { ... }` |
| 16 | HTTP 流式请求不支持 `expectDataType` 选项 | `requestInStream()` 不要传 `expectDataType`，用 `on('dataReceive')` + `on('dataEnd')` 事件 |
| 17 | `@kit.CameraKit` 的 `cameraPicker.pick()` 编译失败 | 需要重新调研 API 22 的相机 API（可能需要用 `XComponent` + `CameraSession`） |

### D. UI/渲染类

| # | 问题 | 正确做法 |
|---|------|---------|
| 18 | `aboutToAppear()` 里调 `animateTo()` 不可靠 | 移到 `.onAppear()` UI 修饰符中 |
| 19 | `ForEach()` 没有 key generator 会导致 diff 警告和 UI 错误 | 必须提供第三个参数：`(item) => item.id` |
| 20 | 特殊 Unicode 字符（如 `▌`）可能导致渲染问题 | 在 UI 文本中优先使用 ASCII 字符 |
| 21 | `ForEach` key 如果跨状态不变（如 `opt_${idx}`），组件不会更新 | key 必须包含变化的状态：`q${currentIndex}_opt_${idx}` |
| 22 | 长内容把底部按钮推出 Scroll 可视区 | 将操作按钮移到 Scroll 外部，用固定底栏 + `shadow` 分隔 |

### E. 网络/API 类

| # | 问题 | 正确做法 |
|---|------|---------|
| 23 | `requestInStream` 的 `dataReceive` 事件若干 chunk 后停止触发 | 这是华为已知 Bug。改用非流式 `request()` 或等待 RCP 新库 |
| 24 | `util.TextEncoder.encodeInto()` 不返回 `Uint8Array` | 它返回 `{read, written}` 对象（Web 标准语义），用 `encode()` 代替 |
| 25 | MiniMax API 返回 HTTP 200 但 body 包含错误 | 必须检查 `base_resp.status_code` 字段，`0` 才是成功 |
| 26 | `setTimeout` 回调中修改 `@State` 可能不触发 UI 更新 | ArkUI 中 `@State` 在异步回调中的行为不一致，避免在 timer 中驱动 UI |

### F. 通用最佳实践

```
1. 始终先检查 API 是否在目标 SDK 版本中可用
2. 严格模式 = ArkTS 默认开启，不可关闭
3. Record<string, Object> 索引模式不可靠 → 用 interface 类型化
4. 复杂状态对象在 @State 中需要不可变更新模式（重建数组/对象）
5. 每次 SDK 升级后先跑一次全量编译，不要增量
6. 保存所有构建错误日志到版本控制，方便日后参考
7. MiniMax API 域名是 api.minimax.chat（不是 api.minimax.io）
8. 添加 Test API 按钮：调试 API 集成时极其有用
```

---

## 三、相机重建方案 — ✅ 已完成 (v2.1)

已实现方案 C（相册选图）+ 文本输入双模式：

```typescript
// CameraPage.ets 当前实现
import { photoAccessHelper } from '@kit.MediaLibraryKit';

const picker = new photoAccessHelper.PhotoViewPicker();
const options = new photoAccessHelper.PhotoSelectOptions();
options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
options.maxSelectNumber = 1;
const result = await picker.select(options);
// result.photoUris[0] → 导航到 PhotoPreviewPage
```

**优势：** 无需权限声明，系统 UI 保证兼容性。

**未来扩展：** 方案 A（系统相机拍照）→ 方案 B（自定义相机）

---

## 四、多模态能力路线图

### 输入端
| 阶段 | 能力 | 实现方式 |
|------|------|---------|
| v2.1 | 文本输入（当前） | TextArea 手动输入 |
| v2.2 | 相册图片选择 | PhotoViewPicker 选图 → OCR |
| v2.3 | 系统相机拍照 | 系统 Picker / CameraKit |
| v3.0 | 数学公式识别 | Mathpix API 或自训练模型 |
| v3.1 | 语音输入 | @kit.SpeechKit 语音转文字 |
| v4.0 | 多模态 AI 直传 | 图片直接传给视觉 AI 模型（跳过 OCR） |

### 输出端
| 阶段 | 能力 | 实现方式 |
|------|------|---------|
| v2.0 | 纯文本回答（当前） | MiniMax 流式文本 |
| v2.2 | 数学符号渲染 | ArkUI RichText 或 WebView + KaTeX |
| v3.0 | 语音播报 | @kit.TextToSpeechKit TTS |
| v3.1 | 图表/图解生成 | AI 生成 SVG/Canvas 图解 |
| v4.0 | 交互式解题步骤 | 分步展示 + 动画 + 可折叠 |

### 设备原生能力优先级
| 能力 | HarmonyOS Kit | 优先级 |
|------|--------------|--------|
| 文字 OCR | @kit.CoreVisionKit | 已实现 |
| 相机拍照 | @kit.CameraKit / PhotoViewPicker | P0 |
| 语音识别 | @kit.SpeechKit | P1 |
| 语音合成 | @kit.TextToSpeechKit | P2 |
| 手写识别 | @kit.CoreVisionKit (handwriting) | P2 |
| 图片分类 | @kit.CoreVisionKit (classification) | P3 |

---

*最后更新：2026-03-15*
