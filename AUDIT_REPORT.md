# BELTECH App — Full Codebase Audit Report
> Generated: March 2026 | Flutter / Dart | Reviewer: Claude

---

## Executive Summary

This is a well-structured Flutter personal management app with clean architecture, Riverpod state management, Supabase cloud sync, and a dark glassmorphism UI. The engineering fundamentals are solid — layers are properly separated, the DI setup is clean, and the MPESA SMS parser is genuinely impressive. However, the app is still relatively early-stage and has several UX gaps, missing features, and quality-of-life improvements that would make it feel like a polished, production-grade product. This report organizes findings into: **what can be improved**, **what features to add**, and **technologies to adopt**.

---

## 1. What Can Be Improved

### 1.1 App Identity & Package Name
The app is still named `dart_2_0` in `pubspec.yaml` and referenced throughout the package import paths (`package:dart_2_0/...`). This is a development artifact — for production it must be renamed to something like `com.beltech.app`. This also affects the app's Play Store identity, push notification tokens, and deep links.

**Fix:** Run `flutter pub run rename --bundleId com.beltech.app --appname "BELTECH"` and update all import paths.

---

### 1.2 Hardcoded Greeting on Home Screen
The home screen greets the user with `"Good Evening"` — always, regardless of the time of day. This is a minor but immediately noticeable immersion-breaker that undermines the "personal" feel of the app.

**Fix:** Compute the greeting dynamically:
```
Morning   → 5am–12pm
Afternoon → 12pm–5pm
Evening   → 5pm–9pm
Night     → 9pm–5am
```

Also consider personalizing it with the user's first name: *"Good morning, Belinze"* — the profile data is already available.

---

### 1.3 Navigation Architecture — No go_router
Navigation is handled inconsistently. The main shell uses `IndexedStack` + Riverpod tab index, which is fine, but the Settings screen is opened via `Navigator.of(context).push(MaterialPageRoute(...))` directly from the Profile screen. This breaks the shell pattern and means Settings has no place in the nav hierarchy.

There are also no named routes, no deep link support, and no URL-based navigation (relevant for web builds). If this app ever needs to deep-link into a specific task or expense from a notification, there's no clean way to do it right now.

**Fix:** Adopt `go_router` (already a standard in Flutter). Settings should be a proper shell branch or a route off the Profile destination, not an imperative push.

---

### 1.4 Calendar — No Event Indicators on Grid
The calendar grid shows days but gives no visual indication of which days actually have events. A user has to tap each day individually to discover what's scheduled. This defeats the purpose of a month view.

**Fix:** Add event dot indicators beneath each date cell. The `CalendarEventsCard` already receives event lists — the data just needs to flow back up to the grid. A simple approach: pass a `Set<DateTime>` of days that have events and render a small colored dot.

**Also missing:** Swipe gestures for month navigation (currently requires tapping the chevron buttons), and no week or agenda view alternative.

---

### 1.5 AI Assistant — Raw Text Rendering
The AI assistant response rendering does a manual `replaceAll('**', '')` to strip markdown bold syntax. This is a fragile hack — it will also accidentally strip intentional double-asterisks and won't handle other markdown like `*italic*`, `` `code` ``, lists, or headers that the LLM may return.

**Fix:** Use the `flutter_markdown` package to render assistant responses natively. This will handle all markdown formatting correctly and make responses look much more readable, especially for structured answers (lists, tables, code blocks).

---

### 1.6 Expenses — Capped at 20 Transactions
The `expenses_snapshot_content.dart` renders `.take(20)` transactions silently. There is no "Load more" button, no pagination, and no indication to the user that they are only seeing the 20 most recent transactions. This is a silent data truncation that could confuse users who are looking for older records.

**Fix:** Either implement proper pagination (lazy loading with `ListView.builder`) or add a "Show all" button that links to a full transaction list screen.

---

### 1.7 Category Breakdown — Text Only, No Visualisation
The `_CategoryCard` in the expenses snapshot shows category totals as plain rows (icon + name + amount). There's no visual proportion — the user can't quickly see that "Food" is 60% of their spending vs. "Transport" at 15%.

**Fix:** Add a pie/donut chart above the category rows using `fl_chart` (which is already in the project). This is one of the highest-impact visual upgrades possible with zero new dependencies.

---

### 1.8 Task Cards — Priority Is Invisible
The `TaskItem` entity has a `priority` field and there's a priority input in the task creation dialog, but the `TaskItemCard` renders tasks identically regardless of priority. High-priority tasks look the same as low-priority ones — the data is collected but never shown.

**Fix:** Add a colored priority indicator to each task card. A left border stripe or a colored dot (`AppColors.danger` for high, `AppColors.warning` for medium, `AppColors.success` for low) works well with the glassmorphism style.

---

### 1.9 Error States — No Retry
All error states across the app show a message ("Unable to load tasks", "Unable to load dashboard") with no retry option. If a user gets a network error on startup, they have no action available except to kill and reopen the app.

**Fix:** Add a `Retry` button to all `ErrorMessage` widgets that re-triggers the relevant provider. Riverpod makes this trivial: `ref.invalidate(homeOverviewProvider)`.

---

### 1.10 Empty States — Not Designed
When a user opens the app fresh (no tasks, no expenses, no events), the screens show empty `ListView`s or near-empty shells. There is a basic "No tasks in this filter" glass card but it's minimal. First-run empty states are a critical UX moment — they set tone and guide the user to take their first action.

**Fix:** Design proper illustrated empty states for each feature with a short encouraging message and a CTA button. For example:
- Tasks: *"Nothing on your plate yet. Add your first task!"* → `[+ Add Task]` button
- Calendar: *"Your schedule is clear. Plan something."*
- Expenses: *"No transactions yet. Import your MPESA messages."*

---

### 1.11 Currency Is Hardcoded (KES)
"KES" is hardcoded as a string literal in at least 8 places across the codebase (home screen, expenses screen, home overview, expenses snapshot content, transaction row, etc). This makes internationalisation impossible and makes the app look unfinished for any user outside Kenya.

**Fix:** Centralise currency configuration. At minimum, move the currency symbol to `AppConstants` or user settings so it's changed in one place. Long-term, support multi-currency.

---

### 1.12 Performance — BackdropFilter Overuse
Every single `GlassCard` applies a `BackdropFilter` with `ImageFilter.blur(sigmaX: 12, sigmaY: 12)`. On a screen like Home that has 6+ `GlassCard` instances, this means 6+ blur compositing layers being rendered every frame. On mid-range Android devices this causes dropped frames and jank.

**Fix:** Benchmark on a real mid-range device. If jank is measurable, consider:
- Reducing blur sigma to 6–8
- Using a static glass gradient without blur for deeply nested cards
- Introducing a `LiteGlassCard` variant without backdrop filter for high-density lists

---

### 1.13 Settings Screen — Very Thin
Settings only contains biometric toggle and theme picker. A production personal management app typically offers:
- Notification preferences (task reminders, event alerts, etc.)
- Data management (export data, clear local cache)
- About / version info (currently no version displayed)
- Account deletion (required for app store compliance)
- Currency/locale settings

---

### 1.14 Profile — No Avatar
The profile screen shows a name and email but no avatar or profile photo. With Supabase storage already in the stack, this is straightforward to add and significantly increases the "personalized" feel.

---

### 1.15 No Custom Typography
The app uses the system default font (Roboto on Android, SF Pro on iOS). The glassmorphism aesthetic pairs particularly well with modern geometric sans-serif fonts. Using the default makes the app feel less distinctive.

**Fix:** Add `google_fonts: ^6.x` and apply **Inter** or **DM Sans** globally in `AppTheme`. Both are free, widely used, and have excellent readability at small sizes.

---

### 1.16 Missing Keyboard Safe Area in Assistant Screen
The assistant input area uses hardcoded `bottom: 96` padding. This does not respond to the soft keyboard inset and may overlap or mis-position the input field on different devices or when the keyboard is open.

**Fix:** Use `MediaQuery.of(context).viewInsets.bottom` to dynamically pad the input area when the keyboard is visible, or wrap the assistant screen in a `Scaffold` with `resizeToAvoidBottomInset: true`.

---

### 1.17 Notifications Package Not Being Utilized
`flutter_local_notifications` is in `pubspec.yaml` and there's a `local_notification_service.dart` in core, but no feature actively schedules notifications. Task due dates and calendar events are obvious candidates for local notification reminders — the infrastructure is there but disconnected.

---

### 1.18 No Swipe-to-Delete on Lists
Expense transactions and tasks require tapping a row to get to the edit/delete dialog. Swipe-to-delete is a standard mobile UX pattern that makes list management dramatically faster. Currently the friction for deleting an item is: tap → wait for dialog → tap delete. It should be: swipe → confirm.

**Fix:** Use `flutter_slidable` to add swipe actions to task and expense rows.

---

## 2. Features to Add

### 2.1 Budget Tracking (High Impact)
The app tracks spending but has no budget system. A monthly budget per category (Food, Transport, Airtime, Bills) with a progress bar showing utilisation would transform the expenses feature from a ledger into an actual financial management tool.

Suggested additions:
- Budget setup screen (monthly limits per category)
- Progress bar on each category in the expenses view
- A "budget health" card on the home dashboard (e.g. "You've used 78% of your Food budget")
- Warning notifications when approaching 90% of a budget

---

### 2.2 Income Tracking (High Impact)
Currently only expenses are tracked. The app has no concept of income, which means there's no way to compute net cash flow or savings rate. Adding an "Income" transaction type (separate from MPESA expenses) would allow:
- Net balance calculation (income – expenses)
- Savings rate tracking
- "Money In vs. Money Out" chart on the home screen

---

### 2.3 Recurring Tasks & Events (Medium Impact)
There's no way to create a recurring task (e.g., "Pay rent — monthly") or a recurring calendar event (e.g., "Team standup — every Monday"). The domain entities would need a `recurrenceRule` field and the UI would need a recurrence picker. This is one of the most-requested features in personal productivity apps.

---

### 2.4 Smart Notifications (Medium Impact)
With `flutter_local_notifications` already imported, the app is positioned to deliver:
- Task due date reminders (e.g., 1 hour before due)
- Calendar event reminders (e.g., 30 minutes before)
- Budget warning alerts (e.g., "You've spent 90% of your Transport budget")
- Daily summary notification (e.g., 8am: "You have 3 tasks due today and 2 events")

---

### 2.5 Data Export (Medium Impact)
Users should be able to export their transaction history as a CSV or PDF statement. This is a core trust feature — it reassures users that their data is portable and not locked in. Supabase can serve as the data source; `share_plus` handles the sharing dialog.

---

### 2.6 Global Search (Medium Impact)
There's no way to search across tasks, expenses, or events. A search screen with unified results across all features would make the app feel much more powerful for power users.

---

### 2.7 Savings / Financial Goals (Medium Impact)
Allow users to create savings goals with a target amount and deadline. Show a progress ring and estimated completion date based on current savings rate. This turns the app from expense tracking into genuine personal finance management.

---

### 2.8 Onboarding Flow (Medium Impact)
There is no first-run onboarding experience. New users land directly on an empty home dashboard with no explanation of what the app does or how to get started. A 3–4 screen onboarding slideshow (using `introduction_screen`) showing each major feature with a visual would significantly improve activation.

---

### 2.9 Calendar Event Color Coding (Low–Medium Impact)
Currently all calendar events look identical. Color-coding events by category or type (Work, Personal, Health, Finance) with user-selectable colors would make the calendar scannable at a glance.

---

### 2.10 Widgets (Home Screen Widgets) (Low Impact, High Delight)
Android and iOS home screen widgets showing today's spending total, pending task count, and today's events would keep the app top-of-mind for users without requiring them to open it. Flutter's `home_widget` package makes this feasible.

---

### 2.11 Assistant Context Awareness (High Impact on AI Quality)
The AI assistant currently handles generic queries. It should be able to answer questions using the user's actual live data — "How much did I spend this week?" should pull from the local Drift DB and include the real number in the prompt context. This is the difference between a general-purpose chatbot and a genuinely useful personal assistant.

The Supabase Edge Function proxy architecture already supports this — the function could be augmented to accept a `context` payload containing recent transactions, upcoming events, and pending tasks.

---

### 2.12 Markdown + Rich Responses in AI Chat
AI responses that contain numbered lists, bullet points, bold text, or code blocks should render richly, not as raw markdown strings. This is especially important for structured financial advice or task breakdowns that the assistant returns.

---

### 2.13 Spending Trend Line Chart (Home Screen)
Augment or replace the weekly bar chart on the home screen with a 30-day spending trend line chart. This gives the user a better signal on whether their spending is going up or down over time, which is more actionable than a 7-day bar chart.

---

### 2.14 MPESA Category Improvement — ML or Rule Expansion
The current MPESA categorizer has 5 categories and matches on a handful of keywords. This will produce a lot of "Other" transactions for anything outside Food/Airtime/Bills/Transport. A more extensive keyword map, or (longer-term) an ML-based classifier, would improve accuracy significantly. At minimum, the categories should be user-editable.

---

## 3. Technologies to Adopt

| Package | Purpose | Why |
|---|---|---|
| `go_router ^14` | Navigation | Named routes, deep links, shell routes, URL-based nav. Essential for production. |
| `google_fonts ^6` | Typography | Inter or DM Sans — transforms the visual quality with one line of code |
| `flutter_markdown ^0.7` | AI chat rendering | Proper markdown in assistant responses instead of `replaceAll` hacks |
| `flutter_slidable ^3` | Swipe gestures | Swipe-to-delete/edit on task and expense list rows |
| `shimmer ^3` | Loading states | Skeleton loading placeholders instead of spinners — far more polished |
| `flutter_animate ^4` | Micro-animations | Page transitions, card entrance, button feedback — significantly elevates perceived quality |
| `share_plus ^10` | Data export | Native share sheet for CSV/PDF exports |
| `freezed ^2` | Immutable domain models | Replace hand-written entities with code-generated immutable classes + copyWith + equality |
| `json_serializable` | JSON parsing | Safer, generated JSON mappers instead of manual map parsing |
| `introduction_screen ^3` | Onboarding | Polished first-run experience |
| `home_widget ^0.7` | Home screen widgets | Android + iOS widgets for at-a-glance stats |
| `intl ^0.19` | i18n + number formatting | Proper currency formatting (`NumberFormat.currency(locale: 'en_KE', symbol: 'KES')`) instead of string interpolation |
| `table_calendar ^3` | Calendar | Mature calendar widget with event dots, range selection, week view — vs. the current custom-built grid |
| `fl_chart` *(already present)* | Donut / pie charts | Add category donut chart in expenses — zero new dependency |
| `cached_network_image ^3` | Profile avatars | Efficiently cache and display profile photos from Supabase Storage |

---

## 4. Architecture Observations

The clean architecture implementation is genuinely good — domain/data/presentation separation is respected throughout, providers are well-scoped, and the Supabase + Drift dual-backend pattern is clever for offline-first operation. A few observations:

**Routing** is the biggest architectural gap. The `AppShell` + `IndexedStack` pattern is fine for the bottom nav, but `Navigator.push` leaking out of `ProfileScreen` is inconsistent and will cause issues as the app scales.

**Repository duplication**: Every feature has both a local `_repository_impl.dart` and a `supabase_repository_impl.dart`. The switching logic between them (via `useSupabaseProvider`) is a clean pattern, but the two implementations share a lot of identical data-mapping code. A shared `BaseRepository` abstract class with common mapping utilities would reduce duplication.

**Test coverage**: `mocktail` is in dev dependencies which is correct, but there's no evidence of substantial test files in the `test/` directory. The `CODING_RULES.md` mandates tests for repositories, use cases, and business logic — this should be enforced before the codebase grows further.

**Logging**: No logging infrastructure is visible. Adding `logger ^2` or the Dart `logging` package with a singleton would help enormously in debugging production issues. Riverpod has an `observer` hook that makes logging state changes trivial.

---

## 5. Quick Wins (Do These First)

These are low-effort, high-impact improvements that can be made in under a day each:

1. **Dynamic greeting** — time-based + user's first name (`"Good morning, Belinze"`)
2. **Priority color stripe** on task cards — one-line change per card
3. **Retry buttons** on all error states — `ref.invalidate(provider)`
4. **google_fonts + Inter** — 2 lines in `AppTheme`, transforms visual quality
5. **Calendar event dots** — pass event dates to the grid, render a 4px dot
6. **Donut chart** in expenses — `fl_chart` is already installed, add a `PieChart` to `_CategoryCard`
7. **Remove `.take(20)` limit** on expenses list or add visible "Show more" button
8. **"KES" → currency constant** in `AppConstants`
9. **App name/package rename** — `dart_2_0` → `com.beltech.app`
10. **flutter_markdown** in assistant — replaces the `replaceAll('**', '')` hack

---

## 6. Summary Assessment

| Area | Rating | Notes |
|---|---|---|
| Architecture | ★★★★☆ | Clean, well-structured. Routing is the gap. |
| Code Quality | ★★★★☆ | Well-organised, follows CODING_RULES well |
| UI/UX Design | ★★★☆☆ | Glassmorphism foundation is good, needs polish and empty states |
| Feature Completeness | ★★☆☆☆ | Core loop works, but budget, income, notifications, and search are missing |
| Performance | ★★★☆☆ | BackdropFilter overuse is a risk on mid-range devices |
| Testing | ★★☆☆☆ | Infrastructure exists but coverage appears low |
| Accessibility | ★★☆☆☆ | No semantic labels, no screen reader support |
| Production Readiness | ★★☆☆☆ | Package name, auth, and stability not yet production-grade |

The app has excellent bones. The biggest opportunity is UX depth — adding budget tracking, rich notifications, better empty states, and a polished onboarding flow would make this feel like a complete product rather than an impressive prototype.
