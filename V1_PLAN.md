# Guilds of Antiquity — Road to v1

_Status snapshot: 2026-06-19. This plan supersedes the open-ended scope in `phase1–4.md` and defines the concrete, finishable path to a shippable v1._

---

## 0. Where the project actually stands

The codebase was recovered from GitHub (`origin/main`, commit `6f84d3a`). It is **far more complete than it looks** — this is not a greenfield build, it's a **finishing job**.

- **Compiles clean:** `flutter analyze` → 0 errors, 45 warnings/info (mostly `withOpacity` deprecations).
- **49 Dart files**, well-architected: Riverpod for state, Hive for persistence, a service layer (ticker / audio / feedback / quest / hive), and a full UI tree.
- **The core loop works end-to-end:** hero creation → send on quest → 1Hz ticker resolves combat → gold/XP/loot/leveling → quest-chain unlocks → prestige/era-shift reset. Verified in `ticker_service.dart` and `game_provider.resetGame()`.
- **Most README features are reachable in-UI:** Roster, Quest Map, The Hall (Farm/Mine/Lodge businesses), Tavern, Shop, Vault, Museum, equipment/inventory, hero creation, 3 themed eras.

### What's genuinely missing or broken
| Area | State |
|---|---|
| **Offline progression** | `lastSaveTime` is persisted but **never used** to advance the sim on resume. An "idle game" that only ticks while open. |
| **Audio** | 4 SFX referenced in `audio_service.dart`; **zero audio files exist**, none declared in `pubspec`. Game is silent. |
| **Onboarding** | `tutorial_coach_mark` is a dependency but **not integrated**. |
| **Hero classes / era mechanics** | `classType` is a cosmetic string ("Mercenary"). Eras differ only in theme + museum trophies, **not gameplay**. |
| **A handful of real bugs** | Asset crash, soft-lock on death, wrong museum %, dead unit test — see §2. |

---

## 1. What "v1" means (scope — ✅ confirmed 2026-06-19)

> **v1 = a polished, bug-free, fully-playable idle RPG built on the systems that already exist.** All three eras ship as visual + progression variety (new theme, new museum trophies, prestige currency). Deep **mechanical** differentiation between Warrior/Thief/Mage classes is **deferred to v1.1**. **Target: mobile only (iOS + Android).**

**Rationale:** the existing loop is a complete, satisfying game. Adding class-specific stat curves, era-specific quest/loot/business pools, and an artifact economy is a large content+balance effort that doesn't block shipping — it's the obvious *next* release. Pulling it into v1 roughly doubles the timeline. If you'd rather v1 include mechanical era depth, say so and I'll fold §6 into the critical path.

**In scope for v1:** stability, the idle loop closed (offline progress), audio, onboarding, content/balance integrity, and ship readiness (icon, splash, release build, smoke tests).

**Deferred to v1.1+:** class mechanics, era-specific content pools, artifact UI/earn path, expanded museum, settings depth.

---

## 2. Milestone 0 — Stabilize & de-risk ✅ _(complete — 2026-06-19)_

Goal: the app runs on a real device through a full play session and a prestige with **zero crashes or soft-locks**.

> **Status: DONE.** `flutter analyze` → 0 issues (was 45); 4 `LootFactory` unit tests green (replaced the broken counter test); app builds + boots clean on the iPhone 17 Pro sim with no runtime errors. Death model implemented as **time-based recovery**: a downed hero enters `recovering`, heals ~3× rate then auto-returns to `idle`; an active Phoenix Feather is consumed to cheat death (1 HP); quest-start is gated for non-idle heroes; a **Revive (gold)** button is the fast path. Remaining: observe a real death→recover cycle in live play (RNG/time-gated — deferred to gameplay QA).

1. **Run it.** `flutter run` on an iOS sim + Android emulator. Click through hero creation → quest → claim → shop → hall → prestige. Capture anything that throws. _(Nothing below is real until we've seen it on a device.)_
2. **Asset crash — legendary staff.** `loot_factory.dart:179` references `nebulas_grasp.png`; file on disk is `nebulus_grasp.png`. Rename the reference (or the file). Crashes when a legendary staff rolls.
3. **Death soft-lock.** `command_deck.dart:262–266` — dead-hero button is a stub (`// Revive logic or new era?`). Today a dead hero = stuck game. Decide + implement: revive-for-gold, auto-recover-over-time, or "fallen hero → recruit new." This is a **must-fix** for v1.
4. **Wire `preventDeath`.** `artifact.dart` defines it; nothing calls it. Add the check in `ticker_service.dart` (~line 271) before applying lethal damage, and consume the Phoenix Feather. (Even if artifacts aren't earnable yet, the hook shouldn't be dead code.)
5. **Museum %.** `museum_state.dart:16` hardcodes `/ 100.0` but there are 12 items → shows 12% at 100% complete. Compute the real total from `MuseumItems`.
6. **Shop refresh.** `shop_tab.dart:51,341` — `refresh()` result discarded (`unused_result`). Confirm the shop actually restocks; fix if it silently no-ops.
7. **Async-gap navigation.** `end_game_dialog.dart:211` uses `BuildContext` across an `await`. Guard with `if (context.mounted)` to avoid a crash on slow prestige.
8. **Dead pubspec dirs.** Remove the 4 declared-but-missing asset dirs (`characters/`, `illustrations/`, `ui/`, `ui/textures/`) from `pubspec.yaml`, or create them. (`flutter analyze` warnings 45–48.)
9. **Analyzer cleanup.** Bulk `withOpacity → withValues`, drop unused imports/fields/vars (`asset_utils.dart`, `hero_creation_screen.dart`, `audio_service.dart`). Target: analyze → 0 issues.
10. **Fix the test suite.** `test/widget_test.dart` is the default Flutter **counter** test — it will fail against this app. Replace with a real boot smoke test (see M5).

---

## 3. Milestone 1 — Close the idle loop ⭐ _(the genre-defining feature)_

Goal: leaving and returning makes meaningful progress. This is the single biggest gameplay gap.

1. **Offline simulation on resume.** The data exists (`game_provider.dart:26,111,335` persists `lastSaveTime`). On app start / foreground, compute `elapsed = now - lastSaveTime` and apply it:
   - Complete any quest whose `questCompletesAt` passed while away.
   - Advance business production (`productionFinishTime`) → mark claimable.
   - Apply passive healing for idle/recovering heroes.
   - Tune a sane offline cap (e.g. 8–12h) so it stays balanced.
2. **App lifecycle hook.** Add a `WidgetsBindingObserver` (none exists today) to trigger the resume calc on `AppLifecycleState.resumed` and re-save `lastSaveTime` on `paused`.
3. **"Welcome Back" modal** (phase4 §5A). On resume after a threshold gap, show a summary: time away, gold earned, items found, heroes lost, with a satisfying "Collect."
4. **Persist active artifacts.** Confirm `activeArtifactIds` is saved/loaded on boot (audit flagged it may not be).

---

## 4. Milestone 2 — Audio & game feel 🔊

Goal: the "premium" feel phase4 describes. The plumbing exists; the assets don't.

1. **Source SFX** (CC0/commercial-safe): `gold_gain`, `combat_hit`, `level_up`, `legendary_drop`. Add `assets/audio/`, declare it in `pubspec.yaml`. `audio_service.dart` already references these paths.
2. **Background music per era** (Warrior/Thief/Mage ambience) with fade on era change. `playMusic()` exists but is never called — wire it.
3. **Settings: sound / music / haptics toggles.** No settings screen exists yet; add a minimal one (also the natural home for a "reset save" / about). Respect toggles in `audio_service` + `feedback_service`.
4. **Verify the juice already coded:** floating text, screen shake, confetti, haptics all fire (`game_feedback_wrapper.dart` looks complete — just confirm on device).

---

## 5. Milestone 3 — Onboarding & first-run UX 🎓

1. **Tutorial** via `tutorial_coach_mark` (already a dep), phase4 §5B: spotlight Recruit → Send on Quest → Equip → Claim. First run only (persist a flag in `settingsBox`).
2. **Title / main menu** (optional but recommended): the design puts the Museum "before entering the game world." Today it boots straight in. A light title screen (Continue / Museum / Settings) makes the Museum-as-meta-progression framing land.
3. **Empty/edge states:** first-run with no hero, no business, no quests discovered — confirm each reads clearly.

---

## 6. Milestone 4 — Content, balance & integrity 🎚️

1. **Quest-chain integrity.** `quests.json` has 32 quests with `requiredQuestId`/`nextQuestId` chains and the `siege_capital` prestige trigger. Verify the whole graph is reachable and the prestige boss is actually attainable. (Some durations are 3–10s — likely debug values to retune for real play.)
2. **Economy balance pass.** Gold/XP curves, business returns (`walkthrough.md` formulas), shop prices, bag-upgrade scaling, level cost (`level*100`, cap 50). Play to era-2 and tune.
3. **Side-quest random discovery.** `ticker_service.dart:256` TODO — add a random chance to surface side quests on quest success (currently menu-only).
4. _(Deferred to v1.1: hero-class stat multipliers, era-specific quest/loot/business pools, artifact earn path + UI, more museum items per era.)_

---

## 7. Milestone 5 — Ship readiness 🚀

1. **Branding:** app icon, splash screen, app display name, bundle IDs (currently `com.example.guilds_of_antiquity`), `version` in pubspec.
2. **Platform config:** Android/iOS permissions, min SDKs, signing. **Mobile-only for v1** (web/desktop out of scope). The `web/`, `macos/`, `windows/`, `linux/` scaffolds can stay but are unsupported.
3. **Smoke tests:** a boot test + a couple of unit tests on the pure logic (`game_logic.dart` combat/duration math, `loot_factory` rarity rolls) — high value, low effort, and replaces the broken counter test.
4. **Release build + on-device QA:** `flutter build apk` / `ios`, full playthrough including a prestige, offline-progress check (close 1h, reopen).
5. **First commit hygiene:** the repo has a single "first commit." Consider committing this work in reviewable chunks per milestone.

---

## 8. Suggested sequence & rough sizing

| Milestone | Why this order | Rough size |
|---|---|---|
| **M0 Stabilize** | Can't evaluate anything until it runs without crashing | S–M |
| **M1 Idle loop** | The defining feature gap; everything else is polish on top | M |
| **M2 Audio/feel** | Highest perceived-quality lift per hour | S–M (M if sourcing/producing music) |
| **M3 Onboarding** | Needed before anyone but you can play it | S |
| **M4 Content/balance** | Best done once the loop+feel are final | M |
| **M5 Ship** | Last; depends on all the above being stable | S–M |

_Sizes are relative (S/M/L), not calendar estimates — I don't know your cadence. M0+M1 are the true critical path; M2–M3 are parallelizable._

---

## 9. Open questions for you
1. ~~Scope~~ — ✅ defer era/class mechanics to v1.1.
2. ~~Platforms~~ — ✅ mobile-only (iOS + Android).
3. ~~Death model~~ — ✅ time-based recovery (+ optional pay-gold-to-revive). Implemented in M0.
4. **Audio (M2):** do you have an asset source/budget, or should I find CC0 placeholders?
