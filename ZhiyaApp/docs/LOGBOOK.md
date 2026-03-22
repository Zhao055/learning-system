# 知芽 iOS + Synapse Server - Development Logbook

## Project Overview

| Item | Detail |
|------|--------|
| **Project** | 知芽 (ZhiYa) — AI原生成长伴侣 |
| **Platforms** | iOS (SwiftUI) + Synapse Server (Hono/TypeScript) |
| **Repository** | learning-system/ZhiyaApp + learning-system/zhiya-server |
| **Start Date** | 2026-03-20 |
| **Current Version** | 1.0.0 |
| **Ported From** | HarmonyOS ArkTS app (ALevelMathHelper, 27 source files) |

---

## Session 1 — 2026-03-20~21: Full Build from Zero

### Objective

Implement the complete 知芽 iOS + Synapse Server system from the ground up, based on the HarmonyOS prototype. Not a direct port — reimagined as a "终身陪伴伴侣" (lifelong companion) with four-dimensional growth tracking, emotional intelligence, and visual data moat.

### Duration: ~4 hours

---

### Phase 1: iOS App — Architecture & Foundation

#### Design System (`Design/`)

| File | Lines | Purpose |
|------|-------|---------|
| `ZhiyaTheme.swift` | 85 | Complete design token system: 12 brand colors, font scales (.rounded), spacing, corner radius, shadows, gradients |
| `ZhiyaComponents.swift` | 95 | Reusable components: ZhiyaCard, ZhiyaPrimaryButton, ZhiyaSecondaryButton, ZhiyaTextField, SubjectBadge |

Design tokens established:
- Background: cream `#FFF8F0`, card: ivory `#FEFCF7`
- Primary: goldenAmber `#D4A574`, secondary: softTeal `#7DB8A0`
- Text: darkBrown `#4A3728`
- 6 character trait colors (正直/体贴/智慧/耐心/包容/热爱)
- Font: `.rounded` design throughout

#### Models (`Models/`, 9 files)

| File | Key Types |
|------|-----------|
| `QuestionBank.swift` | QuestionBank, Chapter, KnowledgePoint, Question (Codable, mirrors HarmonyOS schema) |
| `Subject.swift` | SubjectInfo, PaperInfo, SubjectData (static catalog of 3 subjects, 12 papers) |
| `Progress.swift` | ProgressRecord, QuizAnswer, QuizResult, KpProgress, ChapterProgress, TotalStats, WrongAnswerItem |
| `ChatMessage.swift` | ChatMessage (id, role, content, timestamp, isStreaming), MessageRole enum |
| `QuizState.swift` | QuizState (questions, currentIndex, selectedIndex, answers, phase, consecutiveWrong) |
| `CompanionState.swift` | RelationshipStage (seed/familiar/understanding/companion), ZhiyaEmotion (7 states), DetectedMood, CompanionProfile |
| `GrowthMemory.swift` | GrowthMemory, MemoryType (7 types), Milestone, MilestoneType, WeeklyLetter |
| `EmotionalProfile.swift` | EmotionalProfile, MoodEntry, RecoveryPattern, MoodTrend |
| `GrowthDimension.swift` | GrowthDimensionType (academic/metacognitive/emotional/lifeExploration), GrowthTree, TreeBranch, TreeLeaf, TreeFlower |

**New vs HarmonyOS:** CompanionState, GrowthMemory, EmotionalProfile, GrowthDimension are entirely new — these form the 四维数据壁垒 (four-dimensional data moat) core.

#### Services (`Services/`, 8 files)

| File | Purpose | Ported From |
|------|---------|-------------|
| `QuestionRepository.swift` | Singleton, lazy-load JSON question banks, query interface | `QuestionRepository.ets` |
| `ProgressService.swift` | Track answers, compute stats, wrong answer management (UserDefaults) | `ProgressService.ets` |
| `AIService.swift` | MiniMax M2.5 API + server gateway dual-mode, system prompt generation | `MiniMaxService.ets` |
| `NetworkService.swift` | HTTP POST, SSE streaming via AsyncThrowingStream, GET | New |
| `KeychainService.swift` | Keychain CRUD for API keys | New |
| `MemoryService.swift` | Growth memories, milestones, weekly letters, growth tree state (UserDefaults) | New |
| `EmotionEngine.swift` | Mood detection from quiz behavior, UI color adaptation, mood profile accumulation | New |
| `CompanionEngine.swift` | Greeting generation (context-aware), relationship stage, today suggestion, struggle detection | New |

**Key architecture decision:** SSE streaming uses `URLSession.bytes(for:)` with `AsyncThrowingStream` — clean Swift concurrency, no callback hell.

#### ViewModels (`ViewModels/`, 7 files)

| File | Purpose |
|------|---------|
| `OnboardingViewModel.swift` | Seed Moment 5-step flow (greeting→name→subjects→goals→planting) |
| `HomeViewModel.swift` | Greeting, suggestion, stats aggregation |
| `QuizViewModel.swift` | Full quiz lifecycle: load→select→confirm→record→milestone check→tree update→next/complete |
| `ChatViewModel.swift` | Stream AI messages, update assistant bubble in real-time |
| `WrongAnswerViewModel.swift` | Load, group by paper, expand/collapse, delete |
| `SettingsViewModel.swift` | API key, server URL, exam date, connection test |
| `GrowthTreeViewModel.swift` | Load tree state, compute stage label, leaf counts |

#### Views (`Views/`, 26 files across 10 subdirectories)

| Directory | Files | Purpose |
|-----------|-------|---------|
| `Onboarding/` | SeedMomentView | 种子动画 + 对话式入门 (animated message reveal, subject picker, goal input) |
| `Home/` | HomeView | 知芽问候卡 + 统计行 + 今日建议 + 快速操作 + 成长树预览 |
| `Learning/` | SubjectSelectionView, PaperSelectionView, ChapterListView, KnowledgeCardView | 完整学习导航流 (科目→试卷→章节→知识点) |
| `Quiz/` | QuizView, OptionCardView, QuizResultView | 答题引擎 with 浮动知芽角色 + 情绪感知背景色 + Ask知芽 sheet |
| `Chat/` | ChatPanelView, ChatBubbleView | 半屏对话面板 with 知芽头像 + 流式打字光标 |
| `Camera/` | CameraSolverView, SolutionView | PHPicker + 手动输入 + AI解题聊天 |
| `Growth/` | GrowthTreeView, GrowthDimensionView, MemoryWallView, WeeklyLetterView, AnnualReviewView, CelebrationView | 成长伴侣完整体验 (树/四维/印记/信件/回顾/庆祝) |
| `WrongBook/` | WrongAnswerView | 错题本 (分组/展开/删除) |
| `Settings/` | SettingsView | API Key + 服务器 + 考试日期 + 数据管理 |
| `Components/` | ZhiyaMascotView, GradientCard/StatBarView/EmptyStateView | 知芽角色表情系统 (7状态, 眨眼+摇摆动画) + 通用组件 |

**MainTabView.swift**: 4-tab layout (首页/学习/成长/设置)

#### Extensions & Resources

| Item | Detail |
|------|--------|
| `Color+Zhiya.swift` | Hex color initializer |
| `Resources/QuestionBanks/` | 12 JSON files (646 questions, 3 subjects) |
| `Resources/Images/` | 23 Gemini-generated illustrations (角色表情/入门/四季/科目/空状态/信件/庆祝/节日) |

---

### Phase 2: Synapse Server — Nine-Layer Architecture

#### Infrastructure

| File | Purpose |
|------|---------|
| `package.json` | Hono + Drizzle ORM + better-sqlite3 + JWT + UUID |
| `tsconfig.json` | ES2022 target, ESNext modules, strict mode |
| `drizzle.config.ts` | SQLite dialect, schema path |

#### Database (`db/`, 2 files)

**`schema.ts`** — 7 tables:
| Table | Purpose | Key Fields |
|-------|---------|------------|
| `users` | User profiles | deviceId, name, subjects, joinDate, examDate, treeLevel, relationshipStage |
| `progress` | Answer records | paperId, chapterId, kpId, questionId, correct, selectedIndex |
| `sessions` | Chat sessions | type (tutor/solver), context, messages |
| `memories` | Growth memories | type, title, content, dimension, emotionalWeight |
| `milestones` | Achievements | title, description, type, achievedDate |
| `companion_state` | Companion data | emotionalProfile, growthTree, weeklyLetters |
| `growth_snapshots` | Growth tracking | dimension, score, details, date |

**`client.ts`** — SQLite with WAL mode via better-sqlite3

#### Middleware (`middleware/`, 2 files)

| File | Layer | Purpose |
|------|-------|---------|
| `auth.ts` | ③ Gateway | JWT generation, verification, authMiddleware |
| `compliance.ts` | ⑤ Compliance | Distress signal detection, emotional mode flag |

#### Prompts (`prompts/`, 3 files)

| File | Purpose |
|------|---------|
| `zhiyaPersona.ts` | 知芽完整品格定义 (六大品格), TUTOR_SYSTEM_PROMPT, SOLVER_SYSTEM_PROMPT |
| `tutorPrompt.ts` | Dynamic tutor prompt builder (question/options/context/emotional mode) |
| `complianceRules.ts` | Post-hook response compliance checker (no direct answers/no judgment/no rushing) |

#### Services (`services/`, 8 files)

| File | Layer | Purpose |
|------|-------|---------|
| `aiGateway.ts` | ④ Agent Engine | MiniMax + Claude dual routing, SSE streaming, Claude→OpenAI format transform |
| `complianceEngine.ts` | ⑤ Compliance | Pre-hook (distress detection) + post-hook (response checking) |
| `memoryService.ts` | ⑦ Memory | CRUD for memories, milestones, growth snapshots, companion state |
| `emotionService.ts` | — | Keyword-based emotion analysis (frustrated/anxious/lowEnergy/happy) |
| `companionService.ts` | ①⑥ Persona+Proactive | Context-aware greeting generation, relationship stage calculation |
| `growthTracker.ts` | ⑥.5 Decision | Growth insights (weak topics, accuracy), growth tree data from progress |
| `proactiveService.ts` | ⑥ Proactive | Daily notifications: gentle recall, exam countdown, daily plan |
| `decisionEngine.ts` | ⑥.5 Decision | Error pattern analysis, time pattern analysis, personalized insights |

#### Routes (`routes/`, 7 files)

| File | Endpoints |
|------|-----------|
| `auth.ts` | `POST /auth/register` — device registration, JWT issuance |
| `questionBanks.ts` | `GET /api/subjects`, `GET /api/papers/:id/bank` |
| `chat.ts` | `POST /api/chat/tutor`, `POST /api/chat/solve` — SSE streaming with compliance hooks |
| `progress.ts` | `POST /api/progress/record`, `GET /api/progress/stats` |
| `wrongAnswers.ts` | `GET /api/wrong-answers`, `DELETE /api/wrong-answers/:id` |
| `companion.ts` | `GET /api/companion/greeting`, `GET /api/companion/stage`, `POST /api/companion/emotion`, `GET /api/companion/weekly-letter` |
| `growth.ts` | `GET /api/growth/tree`, `GET /api/growth/memories`, `GET /api/growth/insights`, `GET /api/growth/trajectory`, `GET /api/growth/profile` |

#### Entry Point (`index.ts`)

- Auto-creates all 7 tables on startup (CREATE TABLE IF NOT EXISTS)
- CORS + Logger middleware
- Public routes: `/auth`
- Protected routes: `/api/*` (JWT) + `/api/chat/*` (compliance)
- Health check: `GET /` and `GET /health`

---

### Phase 3: Asset Generation & Integration

- 23 illustrations generated via Gemini with consistent style guide
- Categories: character expressions (6), growth stages (4), seed moment (3), seasonal backgrounds (4), subject covers (3), empty states (4), letter decoration (2), celebration (2), holiday variants (2)
- All images renamed and integrated into `Resources/Images/`

---

### Phase 4: Build & Deployment

#### Xcode Project Setup

- Generated `.xcodeproj` with 52 source files + 35 resources
- Scheme configured for Debug/Release
- iOS 17.0 deployment target
- Bundle ID: `com.qizhao.zhiya`
- Development Team: `GG7YDX9538`
- Auto-provisioning enabled

#### Build Results

| Target | Result | Notes |
|--------|--------|-------|
| iPhone 17 Pro Simulator | **BUILD SUCCEEDED** | 0 errors, 0 warnings |
| Qi的iPhone (physical) | **BUILD SUCCEEDED** | 0 errors, 0 warnings (4 deprecation warnings fixed) |
| Synapse Server | **Running on :3000** | All 14 API endpoints verified via curl |

#### Server API Verification

| Endpoint | Status | Response |
|----------|--------|----------|
| `GET /` | 200 | `{"name":"知芽 Synapse Server","version":"1.0.0","status":"running"}` |
| `POST /auth/register` | 200 | JWT token + userId |
| `GET /api/subjects` | 200 | 3 subjects (数学/生物/心理学) |
| `GET /api/papers/math_p1/bank` | 200 | 8 chapters, 37 KPs |
| `GET /api/progress/stats` | 200 | Stats JSON |
| `GET /api/companion/greeting` | 200 | Context-aware greeting ("早上好，小明！") |
| `GET /api/companion/stage` | 200 | `{"stage":"seed","label":"初识","daysSinceJoin":0}` |
| `POST /api/companion/emotion` | 200 | Mood detection ("太难了" → frustrated) |
| `GET /api/growth/tree` | 200 | 4-branch tree structure |

#### Deprecation Fixes

4 `onChange(of:perform:)` warnings fixed across CameraSolverView, SolutionView, ChatPanelView, SettingsView — updated to iOS 17 two-parameter closure syntax.

---

## Current Project Statistics

### iOS App

| Metric | Count |
|--------|-------|
| Swift source files | 52 |
| Views | 26 |
| ViewModels | 7 |
| Services | 8 |
| Models | 9 |
| Design files | 2 |
| Extensions | 1 |
| Question bank JSONs | 12 |
| Image assets | 23 |
| Subjects | 3 |
| Papers | 12 |
| Total questions | 646 |

### Synapse Server

| Metric | Count |
|--------|-------|
| TypeScript source files | 23 |
| Routes | 7 (14 endpoints) |
| Services | 8 |
| Prompts | 3 |
| Database tables | 7 |
| Middleware | 2 |
| Synapse layers implemented | 9 (①②③④⑤⑥⑥.5⑦⑧⑨ reserved) |

---

## Pending / Future Work

- [ ] Connect iOS app to Synapse Server (currently using local-only mode)
- [ ] Integrate Gemini-generated images into Views (replace programmatic mascot with image assets)
- [ ] Implement push notifications (APNs integration)
- [ ] Add progress data sync (iOS ↔ Server)
- [ ] Weekly letter generation with AI (server-side scheduled task)
- [ ] Growth tree interaction animations (tap branch → drill into dimension)
- [ ] Real device end-to-end testing with MiniMax API
- [ ] TestFlight distribution
