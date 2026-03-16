# A-Level Helper - Development Logbook

## Project Overview

| Item | Detail |
|------|--------|
| **Project** | A-Level Helper (formerly A-Level Math P1 Helper) |
| **Platform** | HarmonyOS NEXT (ArkTS / ArkUI) |
| **Repository** | ALevelMathHelper |
| **Start Date** | 2026-03-13 |
| **Current Version** | 2.0.0 |

---

## Commit History

| # | Date | Hash | Description |
|---|------|------|-------------|
| 1 | 2026-03-13 14:11 | `06d630f` | Initial commit |
| 2 | 2026-03-13 16:03 | `2943e06` | Bug fix for HarmonyOS API 22 |
| 3 | 2026-03-14 15:13 | `b7d2bf6` | Multi-subject support |

---

## Session 1 — 2026-03-13: Project Bootstrap

### Commit 1: `06d630f` Initial commit: A-Level Math P1 Learning Helper for HarmonyOS NEXT

**Objective:** Build a complete A-Level Math P1 learning app from scratch for HarmonyOS NEXT.

**Architecture established:**
- **Entry point:** `Index.ets` — Navigation container with `NavPathStack`
- **Pages (9):** HomePage, ChapterListPage, KnowledgeCardPage, QuizPage, QuizResultPage, CameraPage, PhotoPreviewPage, SolutionPage, SettingsPage
- **Components (5):** ChatBubble, ChatPanel, PosterCanvas, OptionCard, ResultBadge
- **Models (2):** ChapterModel (Question, KnowledgePoint, Chapter, QuestionBank, QuizAnswer, QuizResult), ChatModel
- **Services (3):** MiniMaxService (AI chat), OcrService, ShareService
- **Data (1):** QuestionRepository (singleton, loads from JSON)
- **Routing:** `route_map.json` with named routes and builder functions

**Features implemented:**
1. **Knowledge & Quiz flow:** Browse 8 chapters → view knowledge point cards with images → take quiz → see results
2. **Photo Solver:** Camera → capture photo → OCR text extraction → AI step-by-step solution
3. **AI Tutor:** In-quiz "Ask AI" button opens half-modal chat panel with MiniMax M2.5 streaming
4. **Share Poster:** Generate visual score poster via PosterCanvas component
5. **Settings:** API key management for MiniMax service

**Content:**
- 8 chapters, 37 knowledge points, 185 questions
- Covers: Quadratics, Functions, Coordinate Geometry, Circular Measure, Trigonometry, Series, Differentiation, Integration

**Tech stack:**
- ArkTS + ArkUI declarative UI framework
- `@kit.NetworkKit` for HTTP streaming (SSE)
- `@kit.ArkData` preferences for persistent storage
- `@kit.ArkTS` util.TextDecoder for JSON parsing
- Navigation via `NavPathStack` + `NavDestination` pattern

---

### Commit 2: `2943e06` Fix compilation errors for HarmonyOS NEXT API 22 (SDK 6.0.2)

**Problem:** Build failed with HarmonyOS NEXT API 22 / SDK 6.0.2 due to breaking API changes.

**Changes (25 files, +208 -155):**
- Fixed type compatibility issues across components
- Updated `ChatBubble.ets`, `ChatPanel.ets`, `OptionCard.ets`, `ResultBadge.ets`, `PosterCanvas.ets`
- Updated `CameraPage.ets` camera API calls (~87 lines changed)
- Adjusted `QuizPage.ets` streaming callback patterns
- Updated `MiniMaxService.ets` HTTP request handling
- Modified `build-profile.json5` for SDK 6.0.2 compatibility
- Added placeholder icons (`icon.png`, `startIcon.png`, `app_icon.png`)
- Added `hvigor-config.json5` and `oh-package-lock.json5`

**Result:** Clean build on HarmonyOS NEXT API 22.

---

## Session 2 — 2026-03-14: Multi-Subject Support

### Commit 3: `b7d2bf6` Add multi-subject support: Mathematics, Biology, Psychology

**Objective:** Transform the app from a single-paper Math P1 tool into a multi-subject A-Level learning platform supporting Mathematics 9709 (6 papers), Biology 9700 (2 papers), and Psychology 9990 (4 papers).

**Duration:** ~1 hour implementation + parallel content generation

---

#### Phase 1: Data Layer (non-breaking foundation)

**1.1 ChapterModel.ets — New interfaces added**

```
+ SubjectInfo { id, name, nameCn, code, icon, color, gradientColors, papers[] }
+ PaperInfo { id, name, nameCn, subjectId, jsonFile, chapterCount, kpCount, questionCount, available }
+ QuizResult.paperId: string    (new field)
+ QuizResult.paperName: string  (new field)
```

**Rationale:** `SubjectInfo` and `PaperInfo` provide the static catalog data needed for the new selection pages. Adding `paperId`/`paperName` to `QuizResult` enables per-paper tracking in results and poster sharing.

**1.2 SubjectData.ets — New file (188 lines)**

Static catalog of all subjects and papers:

| Subject | Code | Papers |
|---------|------|--------|
| Mathematics | 9709 | P1, P2, P3, M1, S1, S2 |
| Biology | 9700 | AS (P1&P2), A2 (P4&P5) |
| Psychology | 9990 | P1, P2, P3, P4 |

Helper functions:
- `getSubject(subjectId)` → SubjectInfo
- `getPaper(paperId)` → PaperInfo
- `getSubjectForPaper(paperId)` → SubjectInfo

**1.3 QuestionRepository.ets — Multi-paper storage**

Before:
```typescript
private questionBank: QuestionBank | null = null;
async loadQuestionBank(context: Context): Promise<void>
getChapters(): Chapter[]
getChapter(chapterId: string): Chapter | undefined
getKnowledgePoint(chapterId: string, kpId: string): KnowledgePoint | undefined
getQuestions(chapterId: string, kpId: string): Question[]
```

After:
```typescript
private papers: Map<string, QuestionBank> = new Map();
async loadPaper(context: Context, jsonFile: string, paperId: string): Promise<void>
isPaperLoaded(paperId: string): boolean
getChapters(paperId: string): Chapter[]
getChapter(paperId: string, chapterId: string): Chapter | undefined
getKnowledgePoint(paperId: string, chapterId: string, kpId: string): KnowledgePoint | undefined
getQuestions(paperId: string, chapterId: string, kpId: string): Question[]
```

**Key design decision:** Papers are loaded lazily on demand (when user selects a paper in PaperSelectionPage), not all at once on app start. This keeps startup fast and memory efficient.

**1.4 Renamed `question_bank.json` → `math_p1.json`**

Content unchanged (1836 lines, 8 chapters, 37 KP, 185 questions). The rename aligns with the new multi-paper naming convention.

**1.5 Index.ets — Updated loader call**

```typescript
// Before:
this.repo.loadQuestionBank(getContext(this));
// After:
QuestionRepository.getInstance().loadPaper(getContext(this), 'math_p1.json', 'math_p1');
```

Math P1 is pre-loaded at startup so existing users get instant access to the original content.

---

#### Phase 2: New Pages + Routing

**2.1 SubjectSelectionPage.ets — New file (101 lines)**

- Displays 3 subject cards with gradient backgrounds matching subject theme colors
- Each card shows: icon, name, Chinese name, syllabus code, paper count
- "Select →" button navigates to PaperSelectionPage with `subjectId`
- Back button returns to HomePage

**UI Design:**
```
┌──────────────────────────┐
│ ← Choose Subject    3 subjects │
├──────────────────────────┤
│ ┌────────────────────────┐ │
│ │ 📐 Mathematics         │ │
│ │    数学 | 9709          │ │
│ │    [6 Papers]           │ │
│ │    [Select →]           │ │
│ └────────────────────────┘ │
│ ┌────────────────────────┐ │
│ │ 🧬 Biology              │ │
│ │    生物 | 9700          │ │
│ │    [2 Papers]           │ │
│ │    [Select →]           │ │
│ └────────────────────────┘ │
│ ┌────────────────────────┐ │
│ │ 🧠 Psychology           │ │
│ │    心理学 | 9990        │ │
│ │    [4 Papers]           │ │
│ │    [Select →]           │ │
│ └────────────────────────┘ │
└──────────────────────────┘
```

**2.2 PaperSelectionPage.ets — New file (137 lines)**

- Receives `subjectId` parameter, looks up subject via `getSubject()`
- Displays paper list with: icon, name, Chinese name, chapter count badge, question count badge
- On click: lazy-loads the paper JSON via `QuestionRepository.loadPaper()`, shows LoadingProgress spinner during load
- Navigates to ChapterListPage with `[subjectId, paperId]`
- Header shows subject name and code

**2.3 route_map.json — 2 routes added**

```json
{ "name": "SubjectSelectionPage", "pageSourceFile": "src/main/ets/pages/SubjectSelectionPage.ets", "buildFunction": "SubjectSelectionPageBuilder" },
{ "name": "PaperSelectionPage", "pageSourceFile": "src/main/ets/pages/PaperSelectionPage.ets", "buildFunction": "PaperSelectionPageBuilder" }
```

Total routes: 9 → 11

---

#### Phase 3: Navigation Chain Updates

**New navigation flow:**
```
HomePage
  → SubjectSelectionPage (choose subject)
    → PaperSelectionPage (choose paper, lazy-load JSON)
      → ChapterListPage (browse chapters)
        → KnowledgeCardPage (view KP cards + images)
          → QuizPage (answer questions)
            → QuizResultPage (see score, share poster)
```

**Parameter passing through the chain:**

| Page | Receives | Passes Forward |
|------|----------|----------------|
| HomePage | — | — |
| SubjectSelectionPage | — | `subjectId` |
| PaperSelectionPage | `subjectId` | `[subjectId, paperId]` |
| ChapterListPage | `[subjectId, paperId]` | `[paperId, chapterId]` |
| KnowledgeCardPage | `[paperId, chapterId]` | `[paperId, chapterId, kpId]` |
| QuizPage | `[paperId, chapterId, kpId]` | `QuizResult` object |
| QuizResultPage | `QuizResult` | — |

**3.1 HomePage.ets changes:**
- Title: "A-Level Math P1" → "A-Level Helper"
- Subtitle: "Cambridge 9709" → "Cambridge International"
- Tags: "8 Chapters / 37 Topics / 185 Questions" → "Math 9709 / Bio 9700 / Psych 9990"
- Description updated to mention "3 subjects"
- Start Learning button: `ChapterListPage` → `SubjectSelectionPage`
- Photo Solver description: "A-Level math problem" → "A-Level problem"

**3.2 ChapterListPage.ets changes:**
- Now accepts `[subjectId, paperId]` parameter (was: no params)
- Header shows paper name and Chinese name (was: just "Chapters")
- `getChapters()` called with `paperId` (was: no argument)
- Navigates to KnowledgeCardPage with `[paperId, chapterId]` (was: just `chapterId`)
- Added more chapter icons for subjects with >8 chapters

**3.3 KnowledgeCardPage.ets changes:**
- Accepts `[paperId, chapterId]` (was: just `chapterId`)
- Stores `paperId` as private field for passing to QuizPage
- `getChapter()` called with `(paperId, chapterId)` (was: just `chapterId`)
- Quiz navigation passes `[paperId, chapterId, kpId]` (was: `[chapterId, kpId]`)

**3.4 QuizPage.ets changes:**
- Accepts `[paperId, chapterId, kpId]` (was: `[chapterId, kpId]`)
- All repository calls include `paperId`
- QuizResult construction includes `paperId` and `paperName`
- AI tutor session includes `paperName` for context

**3.5 QuizResultPage.ets changes:**
- New "Paper" row in Details section showing `result.paperName`
- No structural changes to score display logic

**3.6 PosterCanvas.ets changes:**
- Default `result` prop includes `paperId: ''` and `paperName: ''`
- Header: "A-Level Math P1" → `this.result.paperName || 'A-Level Helper'`
- Subtitle: "Cambridge 9709" → "Cambridge International"
- Footer: "A-Level Math P1 Helper" → "A-Level Helper"

**3.7 MiniMaxService.ets changes:**
- `MATH_TUTOR_SYSTEM_PROMPT` → `TUTOR_SYSTEM_PROMPT`
- Prompt generalized: "A-Level Mathematics (Cambridge 9709 Paper 1) tutor" → "Cambridge International A-Level tutor" covering Mathematics, Biology, and Psychology
- Added subject-specific guidance: math notation, biology terminology, psychology study references
- `PHOTO_SOLVE_SYSTEM_PROMPT` generalized: "math problem" → "problem"
- `initTutorSession()` gains `paperName` parameter (default `''` for backward compat)
- `getMathTutorSystemPrompt()` → `getTutorSystemPrompt()`
- `initPhotoSolveSession()` text: "math problem" → "problem"

**3.8 SettingsPage.ets changes:**
- "App" value: "A-Level Math P1 Helper" → "A-Level Helper"
- "Syllabus" row → "Subjects" row: "Cambridge 9709" → "Math, Bio, Psych"
- Version: "1.0.0" → "2.0.0"

**3.9 string.json updates (both files):**

`entry/src/main/resources/base/element/string.json`:
```
module_desc: "A-Level Math P1 Learning Helper" → "A-Level Learning Helper"
EntryAbility_desc: "A-Level Math P1" → "A-Level Helper"
EntryAbility_label: "A-Level Math P1" → "A-Level Helper"
internet_reason: "...math tutoring" → "...tutoring"
```

`AppScope/resources/base/element/string.json`:
```
app_name: "A-Level Math P1" → "A-Level Helper"
```

---

#### Phase 4: Question Bank Content (11 new JSON files)

All JSON files follow the established schema: `{ chapters: [{ id, title, titleCn, knowledgePoints: [{ id, title, titleCn, image, questions: [{ id, stem, options, correctIndex, explanation, difficulty }] }] }] }`

##### Mathematics 9709

| File | Paper | Chapters | KPs | Questions | Topics |
|------|-------|----------|-----|-----------|--------|
| `math_p1.json` | P1 Pure Math 1 | 8 | 37 | 185 | Quadratics, Functions, Coord Geometry, Circular Measure, Trig, Series, Differentiation, Integration |
| `math_p2.json` | P2 Pure Math 2 | 6 | 6 | 18 | Algebra (modulus), Log & Exp, Trig identities, Implicit differentiation, Integration techniques, Numerical methods |
| `math_p3.json` | P3 Pure Math 3 | 9 | 9 | 27 | Partial fractions, Exp growth/decay, Compound angles, Product/quotient rule, Integration by parts, Simpson's rule, Vectors, Diff equations, Complex numbers |
| `math_m1.json` | M1 Mechanics | 5 | 5 | 15 | Forces & equilibrium, Kinematics (SUVAT), Momentum, Newton's laws, Work & energy |
| `math_s1.json` | S1 Statistics 1 | 5 | 5 | 15 | Data representation, Permutations & combinations, Conditional probability, Discrete random variables, Normal distribution |
| `math_s2.json` | S2 Statistics 2 | 5 | 5 | 15 | Poisson distribution, Linear combinations, Continuous random variables, Sampling & estimation, Hypothesis testing |

##### Biology 9700

| File | Paper | Chapters | KPs | Questions | Topics |
|------|-------|----------|-----|-----------|--------|
| `bio_as.json` | AS (P1&P2) | 11 | 11 | 33 | Cell structure, Biological molecules, Enzymes, Cell membranes, Mitosis, Nucleic acids, Plant transport, Mammalian transport, Gas exchange, Infectious diseases, Immunity |
| `bio_a2.json` | A2 (P4&P5) | 8 | 8 | 24 | Respiration & energy, Photosynthesis, Homeostasis, Control & coordination, Genetics, Selection & evolution, Classification, Genetic technology |

##### Psychology 9990

| File | Paper | Chapters | KPs | Questions | Topics |
|------|-------|----------|-----|-----------|--------|
| `psych_p1.json` | P1 AS Approaches | 4 | 4 | 12 | Biological approach, Cognitive approach, Learning approach, Social approach |
| `psych_p2.json` | P2 AS Research | 3 | 3 | 9 | Research methods, Data analysis, Research ethics |
| `psych_p3.json` | P3 A2 Specialist | 4 | 4 | 12 | Abnormal psychology, Consumer behaviour, Health psychology, Organisational psychology |
| `psych_p4.json` | P4 A2 Research | 3 | 3 | 9 | Applied research methods, Advanced research design, Issues & debates |

**Content quality notes:**
- Math P3 questions were verified with 6 corrections made for mathematical accuracy (partial fractions, exponential equations, Simpson's rule calculation, vector dot product, ODE solution)
- Biology questions use precise scientific terminology and common student misconceptions as distractors
- Psychology questions reference real researchers and studies (Milgram, Bandura, Asch, Raine et al., etc.)
- All questions reviewed for `correctIndex` accuracy

---

## Current Project Statistics

| Metric | Count |
|--------|-------|
| Source files (.ets) | 25 |
| Pages | 12 |
| Components | 5 |
| Services | 3 |
| Models | 2 |
| Data files | 2 (.ets) |
| Question bank files | 12 |
| Routes | 11 |
| Subjects | 3 |
| Papers | 12 |
| Total chapters | 71 |
| Total knowledge points | 100 |
| Total questions | 374 |
| Total JSON content lines | 5,164 |

---

## File Inventory

### Pages (12)
| File | Purpose | Lines |
|------|---------|-------|
| `Index.ets` | App entry, Navigation container | 22 |
| `HomePage.ets` | Landing page with feature cards | ~150 |
| `SubjectSelectionPage.ets` | Subject picker (3 subjects) | 101 |
| `PaperSelectionPage.ets` | Paper picker with lazy loading | 137 |
| `ChapterListPage.ets` | Chapter browser for selected paper | ~105 |
| `KnowledgeCardPage.ets` | Knowledge point cards with images | ~205 |
| `QuizPage.ets` | Quiz engine with AI chat | ~403 |
| `QuizResultPage.ets` | Score display and poster sharing | ~168 |
| `CameraPage.ets` | Camera capture | — |
| `PhotoPreviewPage.ets` | Photo preview + OCR trigger | — |
| `SolutionPage.ets` | AI solution display | — |
| `SettingsPage.ets` | API key management | ~123 |

### Components (5)
| File | Purpose |
|------|---------|
| `PosterCanvas.ets` | Share poster generation |
| `OptionCard.ets` | Quiz option button |
| `ResultBadge.ets` | Correct/incorrect badge |
| `ChatBubble.ets` | Chat message bubble |
| `ChatPanel.ets` | Chat panel container |

### Models (2)
| File | Interfaces |
|------|------------|
| `ChapterModel.ets` | SubjectInfo, PaperInfo, Question, KnowledgePoint, Chapter, QuestionBank, QuizAnswer, QuizResult |
| `ChatModel.ets` | ChatMessage, MiniMaxRequest, MiniMaxMessage, MiniMaxResponse |

### Services (3)
| File | Purpose |
|------|---------|
| `MiniMaxService.ets` | AI chat with streaming SSE |
| `OcrService.ets` | OCR text extraction |
| `ShareService.ets` | Poster sharing |

### Data (2)
| File | Purpose |
|------|---------|
| `QuestionRepository.ets` | Multi-paper question bank singleton |
| `SubjectData.ets` | Static subject/paper catalog |

---

## Session 3 — 2026-03-15: Bug Fixes, API Integration & Device Testing

### Overview

**Objective:** Build, deploy to device (HUAWEI Mate XT), and fix all bugs found during real-device testing. Focus on making the app stable and usable.

**Duration:** ~4 hours of iterative build → deploy → test → fix cycles

---

#### Build System Setup

Established CLI build workflow (no DevEco Studio GUI needed):

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap --no-daemon
```

Output: `entry/build/default/outputs/default/entry-default-signed.hap`

---

#### Bug Fix 1: Quiz Options Not Updating Between Questions

**Problem:** All questions displayed the same 4 options (from the first question). Selecting a different question showed different stem text but identical options.

**Root cause:** `ForEach` key generator was `opt_${idx}` — same keys across questions, so ArkUI reused old `OptionCard` components without updating props.

**Fix in `QuizPage.ets`:**
```typescript
// Before:
}, (option: string, idx: number) => `opt_${idx}`)
// After:
}, (option: string, idx: number) => `q${this.currentIndex}_opt_${idx}`)
```

---

#### Bug Fix 2: Action Buttons Hidden Below Fold

**Problem:** After submitting an answer, "Ask AI" and "Next" buttons were pushed off-screen by the large `ResultBadge` circle (140x140) and explanation text. Users couldn't find them.

**Fix in `QuizPage.ets`:**
- Moved Submit/Ask AI/Next buttons out of Scroll into a **fixed bottom bar** with shadow
- Replaced large `ResultBadge` circle with compact inline result banner (Row with icon + text)

---

#### Bug Fix 3: AI Tutor Not Responding

**Problem:** Clicking "Ask AI" showed the chat panel but no AI response appeared. MiniMax API returned error responses as non-SSE JSON which was silently ignored.

**Fix in `MiniMaxService.ets`:**
- Added `rawResponse` tracking to capture non-SSE error responses
- Added error detection in `dataEnd` handler: parse `base_resp.status_msg` and `error.message` from MiniMax error format
- MiniMax returns HTTP 200 even for API errors (error in `base_resp.status_code`)

---

#### Bug Fix 4: Wrong API Domain

**Problem:** API key was rejected as "invalid api key" despite being correct on MiniMax platform.

**Discovery:** Tested via curl — the correct domain is `api.minimax.chat` (NOT `api.minimax.io`).

**Fix:** Changed `API_URLS` to use `api.minimax.chat`:
```typescript
const API_URLS: string[] = [
  'https://api.minimax.chat/v1/text/chatcompletion_v2',
  'https://api.minimax.chat/v1/chat/completions'
];
```

---

#### Bug Fix 5: API Key Debugging Support

**Problem:** Hard to diagnose API key issues without visibility into what's being sent.

**Fix in `SettingsPage.ets` + `MiniMaxService.ets`:**
- Added `testApiConnection()` method that tries both endpoints
- Checks `base_resp.status_code` for MiniMax API-level errors (not just HTTP status)
- Shows key info (first 6 + last 4 chars + length) for debugging
- Added "Test API" button alongside "Save" button with color-coded result display

---

#### Bug Fix 6: Logo Added to HomePage

**Problem:** Project had `logo.jpeg` but it wasn't displayed anywhere.

**Fix:** Copied logo to `rawfile/`, added to HomePage header:
```typescript
Image($rawfile('logo.jpeg'))
  .width(52).height(52).borderRadius(12).objectFit(ImageFit.Cover)
```

---

#### Bug Fix 7: App Icons Converted to PNG

Converted all icon files from JPEG to PNG using `sips` for better HarmonyOS compatibility:
- `AppScope/resources/base/media/app_icon.png`
- `entry/src/main/resources/base/media/icon.png`
- `entry/src/main/resources/base/media/startIcon.png`

---

#### Bug Fix 8: Session Memory Leak

**Problem:** AI chat sessions (`chatHistory` Map entries) were never cleaned up.

**Fix:**
- `QuizPage.ets`: Added `closeChatPanel()` method that calls `clearSession()`, plus `aboutToDisappear()` fallback cleanup
- `SolutionPage.ets`: Added `aboutToDisappear()` to call `clearSession()`

---

#### Bug Fix 9: API Key Pre-checks

**Problem:** Tapping "Ask AI" or "Solve with AI" without an API key produced silent failures.

**Fix:** Added `hasApiKey()` checks with AlertDialog prompts in:
- `QuizPage.ets` → `openAIChat()`
- `CameraPage.ets` → "Solve with AI" button
- `PhotoPreviewPage.ets` → "Solve with AI" button

---

#### Bug Fix 10: Camera Page → Album + Text Input

**Problem:** Camera capture was not implemented (placeholder workaround).

**Fix:** Rewrote `CameraPage.ets` with dual-mode UI:
1. **Select from Album** (primary): Uses `PhotoViewPicker` system UI — no permissions needed
2. **Type Problem Manually** (secondary): Expandable TextArea with "Solve with AI" button

---

#### Streaming Issue: `requestInStream` Unreliable on HarmonyOS

**Problem:** AI responses consistently truncated mid-sentence. The streaming cursor "|" remained but no more content arrived. Multiple fix attempts failed:

1. ~~Byte accumulation + re-decode~~ → `TextEncoder.encodeInto()` crash (returns `{read, written}`, not `Uint8Array`)
2. ~~ProcessedTextLen tracking~~ → Still stuck after a few chunks
3. ~~Simple per-chunk decode~~ → Still stuck
4. ~~setTimeout simulated streaming~~ → Also stuck (`@State` update issues)

**Root cause:** HarmonyOS `requestInStream` `dataReceive` events **stop firing** after several chunks. This is a [known issue reported to Huawei](https://bbs.itying.com/topic/678d98114b218c005fa23295) but not yet fixed. `setTimeout` + `@State` reactivity in ArkUI also has documented compatibility issues.

**Final solution:** Switched to non-streaming `request()` call with `stream: false`. Full response is returned at once and displayed immediately. Reliable on device.

**Future option:** Huawei recommends migrating to **RCP (`@kit.RemoteCommunicationKit`)** which may have better streaming support.

---

#### Files Modified in Session 3

**Code (8 files):**
| File | Changes |
|------|---------|
| `MiniMaxService.ets` | API domain fix, non-streaming request, `testApiConnection()`, error handling, session cleanup |
| `QuizPage.ets` | ForEach key fix, fixed bottom bar, compact result banner, `closeChatPanel()`, `aboutToDisappear()`, API key check |
| `HomePage.ets` | Logo display with `$rawfile('logo.jpeg')` |
| `SettingsPage.ets` | Test API button, result display |
| `CameraPage.ets` | Rewrite: album picker + text input dual mode |
| `PhotoPreviewPage.ets` | API key pre-check |
| `SolutionPage.ets` | `aboutToDisappear()` session cleanup |
| `ChatModel.ets` | (import cleanup) |

**Assets:**
- `entry/src/main/resources/rawfile/logo.jpeg` (new)
- App icons converted JPEG → PNG (3 files)

---

## Current Project Statistics

| Metric | Count |
|--------|-------|
| Source files (.ets) | 25 |
| Pages | 12 |
| Components | 5 |
| Services | 3 |
| Models | 2 |
| Data files | 2 (.ets) |
| Question bank files | 12 |
| Routes | 11 |
| Subjects | 3 |
| Papers | 12 |
| Total chapters | 71 |
| Total knowledge points | 100 |
| Total questions | 374 |
| Total JSON content lines | 5,164 |
| Current Version | 2.1.0 |

---

## Pending / Future Work

- [ ] Push to GitHub (needs repo creation: `gh repo create`)
- [ ] Add knowledge point images for new papers (currently `image: ""`)
- [ ] Expand question banks (new papers have 3 questions per KP vs P1's 5)
- [ ] Investigate RCP (`@kit.RemoteCommunicationKit`) for true streaming support
- [ ] Add progress tracking per paper/subject
- [ ] Add search/filter across subjects
- [ ] Add quiz history and statistics dashboard
- [ ] Consider offline-first data sync
