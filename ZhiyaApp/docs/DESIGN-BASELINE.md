# 知芽 iOS — Design Baseline v1.0

> **Date:** 2026-03-21
> **Platform:** iOS 17.0+ (SwiftUI)
> **Design Philosophy:** 终身陪伴伴侣 — 每一个设计决策都回答："这让孩子感受到被看见、被记住、被陪伴了吗？"

---

## 1. Color System

### Brand Colors

| Token | Hex | SwiftUI | Usage |
|-------|-----|---------|-------|
| cream | `#FFF8F0` | `ZhiyaTheme.cream` | Page background |
| ivory | `#FEFCF7` | `ZhiyaTheme.ivory` | Card background |
| goldenAmber | `#D4A574` | `ZhiyaTheme.goldenAmber` | Primary accent, buttons, highlights |
| warmGold | `#E8C9A0` | `ZhiyaTheme.warmGold` | Secondary gold, borders, subtle accents |
| softTeal | `#7DB8A0` | `ZhiyaTheme.softTeal` | Secondary color, progress indicators |
| darkBrown | `#4A3728` | `ZhiyaTheme.darkBrown` | Primary text |
| lightBrown | `#8B7355` | `ZhiyaTheme.lightBrown` | Secondary text, captions |

### Character Trait Colors

| Trait | Hex | Token | Usage |
|-------|-----|-------|-------|
| 正直 Integrity | `#6BBF7B` | `integrity` | Correct answers, positive feedback |
| 体贴 Empathy | `#F08080` | `empathy` | Wrong answers, error states, delete actions |
| 智慧 Wisdom | `#5AAFA0` | `wisdom` | Academic dimension, knowledge indicators |
| 耐心 Patience | `#90D4A0` | `patience` | Metacognitive dimension |
| 包容 Acceptance | `#7DD4C0` | `acceptance` | Mint accents |
| 热爱 Passion | `#E87BAF` | `passion` | Life exploration dimension |

### Subject Colors

| Subject | Hex | Gradient |
|---------|-----|----------|
| Mathematics | `#4E6EF2` | `#4E6EF2` → `#7B68EE` |
| Biology | `#4CAF50` | `#4CAF50` → `#66BB6A` |
| Psychology | `#9C27B0` | `#9C27B0` → `#BA68C8` |

### Emotion-Adaptive Backgrounds

| Mood | Background | When |
|------|-----------|------|
| Smooth | `#FFF8F0` (cream) | Normal flow |
| Frustrated | `#FFF0EC` (warm peach) | 3+ consecutive wrong |
| Low Energy | `#F5F0EB` (muted cream) | Low engagement detected |
| Anxious | `#F0F0F5` (cool cream) | Anxiety keywords detected |

---

## 2. Typography

**Font Family:** `.rounded` design throughout — warm, approachable, non-mechanical.

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `title()` | 24pt | Bold | Page titles, large numbers |
| `heading()` | 20pt | Semibold | Section headers, card titles |
| `body()` | 16pt | Regular | Body text, descriptions |
| `label()` | 14pt | Medium | Button labels, tags |
| `caption()` | 13pt | Regular | Secondary info, timestamps |

Custom sizes via parameter: `ZhiyaTheme.title(40)`, `ZhiyaTheme.body(15)`, etc.

---

## 3. Spacing & Layout

| Token | Value | Usage |
|-------|-------|-------|
| `spacingXS` | 4pt | Tight spacing (inside tags) |
| `spacingSM` | 8pt | Compact spacing (between small elements) |
| `spacingMD` | 16pt | Standard spacing (card padding, list gaps) |
| `spacingLG` | 24pt | Section spacing |
| `spacingXL` | 32pt | Large spacing (between major sections) |

### Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `cornerRadiusSM` | 10pt | Input fields, small badges |
| `cornerRadius` | 16pt | Cards, buttons, standard containers |
| `cornerRadiusLG` | 24pt | Large cards, modal sheets |

### Shadows

Soft, warm shadow — never harsh:
- Color: `black @ 6% opacity`
- Radius: `8pt`
- Y offset: `4pt`

---

## 4. Component Library

### ZhiyaCard

Standard content container. Cream → Ivory elevation with soft shadow.

```
[Ivory background]
[16pt padding all sides]
[16pt corner radius]
[Soft shadow: black 6%, radius 8, y 4]
```

### ZhiyaPrimaryButton

Golden amber filled button for primary actions.

```
[Golden amber background]
[White text, 14pt medium .rounded]
[Full width, 14pt vertical padding]
[16pt corner radius]
```

### OptionCard (Quiz)

4 visual states:
1. **Default:** Ivory background, warm gold border 20%
2. **Selected:** Golden amber 8% background, golden amber border
3. **Correct (result):** Green 8% background, green border, checkmark
4. **Wrong (result):** Coral 8% background, coral border, xmark

### ZhiyaMascotView

Programmatic character with 7 emotion states:

| Emotion | Eyes | Leaf | Body Color |
|---------|------|------|------------|
| Gazing | Round with highlights | Normal tilt | `#8FD4A4` |
| Happy | Upward arcs (^_^) | Perks up | `#7BC88F` |
| Thinking | One squinted | Tilts side | `#8FD4A4` |
| Caring | Droopy, soft | Lowered | `#A8D5BA` |
| Sleeping | Horizontal lines | Droops | `#C5DEC0` |
| Excited | Star sparkles | Straight up | `#7BC88F` |
| Calm | Soft, steady | Gentle | `#8FD4A4` |

Animations:
- **Swaying:** 3s ease-in-out, ±3° rotation, infinite
- **Blinking:** Random interval 3-6s, 0.15s duration

---

## 5. Screen Architecture

### Navigation Structure

```
[Onboarding] → hasCompletedOnboarding? → [MainTabView]
                                              ├── Tab 1: HomeView (NavigationStack)
                                              ├── Tab 2: SubjectSelectionView (NavigationStack)
                                              │           → PaperSelection → ChapterList → KnowledgeCard → Quiz → Result
                                              ├── Tab 3: GrowthTreeView (NavigationStack)
                                              │           → GrowthDimension / MemoryWall / WeeklyLetter / AnnualReview
                                              └── Tab 4: SettingsView (NavigationStack)
```

### Screen Inventory (26 views)

| Screen | Type | Key Visual Elements |
|--------|------|-------------------|
| **SeedMomentView** | Full-screen onboarding | Animated message reveal, growing mascot, subject picker. Layout: VStack + `.background(AmbientBackgroundView)` (not ZStack) to ensure keyboard avoidance works correctly |
| **HomeView** | ScrollView, cards | Greeting card + mascot, stat row (3 cards), suggestion card, action rows, tree preview |
| **SubjectSelectionView** | Gradient cards | 3 subject cards with gradient backgrounds, emoji icons |
| **PaperSelectionView** | Card list | Paper stats (chapters/KPs/questions), availability badge |
| **ChapterListView** | Card list | Chapter progress circles, KP count |
| **KnowledgeCardView** | Card list | KP title (bilingual), progress indicator |
| **QuizView** | Interactive quiz | Progress bar, stem, 4 option cards, explanation panel, floating mascot, bottom action bar |
| **QuizResultView** | Score display | Emoji, score fraction, message, answer detail list |
| **ChatPanelView** | Sheet (.medium/.large) | Message list, mascot header, input bar |
| **ChatBubbleView** | Message bubble | User (gold) vs assistant (ivory) + mascot avatar |
| **CameraSolverView** | Dual mode | Photo picker + manual text input |
| **SolutionView** | Chat interface | Problem display card + AI chat |
| **GrowthTreeView** | Visualization | Tree canopy (3 ellipses), trunk, 4 dimension bars, milestone list |
| **GrowthDimensionView** | Detail view | Dimension icon + description + placeholder |
| **MemoryWallView** | Memory list | Memory cards with type icons and colors |
| **WeeklyLetterView** | Letter card | Gold border, sections, mascot signature |
| **AnnualReviewView** | Stats display | Day count, stat rows, mascot message |
| **CelebrationView** | Overlay | Warm backdrop, animated mascot, milestone text |
| **WrongAnswerView** | Grouped list | Paper group headers, expandable cards with option comparison |
| **SettingsView** | Form | Profile section, API config, exam date picker, data management |

---

## 6. Interaction Patterns

### Emotion-Adaptive UI

The app background color shifts based on detected mood:
- Quiz: EmotionEngine tracks consecutive wrong answers
- Background transitions smoothly between mood colors
- Mascot emotion syncs with detected mood

### Relationship Stage Progression

| Stage | Days | Greeting Style | Mascot Size | Visual Cues |
|-------|------|---------------|-------------|-------------|
| 初识 Seed | 1-7 | Generic warm | 60pt → 80pt at planting | 1-2 leaves |
| 熟悉 Familiar | 8-30 | References last session | Standard | Multiple leaves |
| 了解 Understanding | 31-90 | Predicts daily needs | Standard | Visible branches |
| 同行 Companion | 90+ | Like an old friend | Standard | Full tree |

### Quiz Flow

```
[Answering] → select option → [Confirm] → tap confirm →
[ShowingResult] → show correct/wrong + explanation → tap "下一题" →
    └── if last question → [Completed] → QuizResultView
    └── if 3+ wrong → EmotionEngine → caring mode → background shifts
    └── "问知芽" → ChatPanelView sheet
```

### Onboarding (Seed Moment)

5-step conversational flow, not a form:
1. **Greeting** — "你好，我是知芽" (3 messages, animated reveal)
2. **Name** — Text field
3. **Subjects** — Tappable subject list with checkmarks
4. **Goals** — Optional text field
5. **Planting** — "以后每一天，我都在" + mascot grows to excited

---

## 7. Asset Inventory

### Generated Images (23)

| Category | Files | Format | Usage |
|----------|-------|--------|-------|
| Character | zhiya_expressions, zhiya_growth_stages, zhiya_avatar | JPEG | Expressions sheet, 4-stage evolution, chat avatar |
| Onboarding | seed_moment_1/2/3 | JPEG | Seed→sprout→pot sequence |
| Seasons | bg_spring/summer/autumn/winter | JPEG | HomeView bottom decoration (auto-switch by month) |
| Subjects | subject_math/biology/psychology | JPEG | Subject card backgrounds |
| Empty States | empty_no_wrong/memories/no_letters/no_data | JPEG | Empty list placeholders |
| Letter | letter_paper_bg, zhiya_signature | JPEG | Weekly letter background + signature stamp |
| Celebration | bg_celebration, annual_review | JPEG | Milestone overlay, year review header |
| Holiday | zhiya_cny, zhiya_birthday | JPEG | Chinese New Year + birthday variants |

### Color Palette Consistency

All images generated with unified style guide:
- Base: cream `#FFF8F0`
- Accent: golden amber `#D4A574`, soft green `#8FD4A4`
- Style: soft watercolor, hand-drawn feel
- No 3D, no pixel art, no anime

---

## 8. Synapse Layer Mapping

| Layer | Implementation | Files |
|-------|---------------|-------|
| ① Personas | Zhiya character definition | `zhiyaPersona.ts`, `users` table |
| ② Interface | iOS SwiftUI Views | 26 View files |
| ③ Gateway | Hono server + routing | `index.ts`, `routes/*`, `auth.ts` middleware |
| ④ Agent Engine | AI routing (MiniMax + Claude) | `aiGateway.ts` |
| ⑤ Compliance | Character trait enforcement | `complianceEngine.ts`, `complianceRules.ts`, `compliance.ts` middleware |
| ⑥ Proactive | Daily notifications, recall | `proactiveService.ts` |
| ⑥.5 Decision | Pattern analysis, predictions | `decisionEngine.ts` |
| ⑦ Skills+Memory | Personal memory, progress | `memoryService.ts`, question banks, progress API |
| ⑧ MCP Hub | Reserved | — |
| ⑨ External | Reserved | — |
