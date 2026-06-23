# Simulation Findings — Guilds of Antiquity game loop

_Generated from the headless balance simulator in `sim/`. The simulator replays
the **real** game logic (it imports `GameLogic`, `LootFactory`, `QuestLogic` and
the shared `QuestResolver` that the live game's `TickerService` now also calls —
single source of truth, so these numbers reflect the actual game, not a
re-implementation)._

**Method:** 5 bot "play styles" (rush-story, balanced, speed-stacker,
greedy-gold, tank), 60 playthroughs each of one Era (hero L1 → clearing
`siege_capital`). The bot rests to full HP between fights (faithful in
aggregate: total heal time = total damage taken ÷ heal rate), spends upgrade
points by policy, auto-equips upgrades, and buys hint shards when a hint-gated
main quest blocks the story. Business income is **excluded** in this version
(the questing-to-level loop is the user's stated pain point). Figures are
medians.

> ⚠️ **What this can and cannot tell you.** This measures *balance, pacing and
> progression* — it is excellent for that. It does **not** measure fun: a bot
> doesn't feel waiting, doesn't get bored, and plays more patiently/optimally
> than any human. Treat "the grind is N hours / M repeats" as the diagnosis and
> human judgement as the verdict on whether that's miserable.

---

## Headline numbers (per Era, median across policies)

| Metric | Value | So what |
|---|---|---|
| **Total time to finish one Era** | **~16–19 in-game hours** | And you do it **3×** (one per Era) with no mechanical change. |
| **% of that time spent waiting to heal** | **~50–60%** | Over half the game is dead waiting time, not playing. |
| **Total quest attempts** | **~3,900–7,400** | Per Era. |
| **Times the single most-farmed quest is replayed** | **~3,800–7,300×** | One quest, thousands of times. This *is* the "repetitive and boring" complaint, quantified. |
| **Hint shards bought to clear the hint-gated story** | **~5–6** (needs only 3) | ~2,500–3,000 gold wasted to RNG (see below). |
| **Final hero level at endgame** | **~41–42** (cap is 50) | The level cap isn't the constraint — gear is. |

---

## 1. Healing is the single biggest time sink (~50–60% of play)

Passive healing is ~1 hour to full at base, scaled by Speed, and **only happens
while the hero is idle** — you cannot heal and quest at the same time. Because
damage is a *percent of max HP* (`90 − success% − defense`), early heroes with
low success and no defense lose ~8–30% HP per fight and must then wait minutes
to heal before the next one.

- In the **first 200 quests**, the bot spent **~6h25m healing vs ~14m
  questing** — the early game is almost entirely waiting.
- Across a full Era, healing is **7–11 hours** of the 16–19h total.

This is the mechanical root of "it feels slow." It is also invisible in the
design docs because nothing surfaces it.

## 2. The first real wall is `defend_village` (difficulty 5 → 10)

The story difficulty jumps 1 → 5 → **10** → 15 → 20 → 30 → 40 → 50. The 5→10
step lands while the hero is still weak and slow:

| Gate | Diff | Median grind to reach it (attempts / hours) |
|---|---|---|
| clear_forest | 5 | 2 / 0.6h |
| **defend_village** | **10** | **~55 / ~7–8h** ← the brick wall |
| mountain_pass | 15 | ~210 / ~2.5h |
| cursed_temple | 20 | ~450 / ~1.0h |
| dragon_lair | 30 | ~1,100 / ~1.6h |
| dark_army | 40 | ~2,100 / ~2.4h |
| siege_capital | 50 | ~2,500 / ~3.0h |

Counter-intuitively the **early game is the worst grind** (per gate), because
Speed and gear haven't ramped yet so each fight is slow *and* each heal is long.
By mid-game the player is over-levelled and gear-carried, so later gates clear
faster despite higher difficulty.

## 3. Optimal play is degenerate single-quest spam

The bot maximises XP-per-second, and the winning strategy is to **spam one short
high-XP quest thousands of times** (3,800–7,300× on a single quest). The most
efficient way to play is also the most monotonous — a classic design smell.

## 4. The content faucet doesn't fix repetition

The Tavern surfaces a new side quest only every 10–14h. Turning it **off**
entirely made the game **longer** (≈24h vs ≈18h) but *less* concentrated on one
quest — i.e. more quests doesn't mean less grinding, it just changes which quest
you spam. New content arrives far too slowly to relieve boredom in the moment.

## 5. Hint RNG taxes story progress

`dragon_lair` (a main-story gate) needs 3 hints. Hints come from 500-gold shards,
but each shard lands on a **random** unhinted hidden quest — and there are two
(`dragon_lair` and the side quest `bandit_king_3`). So to get 3 hints onto
`dragon_lair` the bot buys **~5–6 shards** (~2,500–3,000 gold), wasting roughly
half of them on a quest it didn't want. Pure friction with no upside.

## 6. Power comes from RNG gear, not choices

Once equipment is working, heroes finish around level 41–42 (well under the cap)
because a single **legendary** drop (1% of drops, ×5 stat multiplier) dwarfs
~40 levels of stat points. Build choice barely matters; a lucky legendary does.
The four upgrade stats also collapse — Speed (faster farming + faster healing)
dominates, so "spend a point" is rarely a real decision.

## 7. Then you do it all again

Clearing `siege_capital` prestiges you into the next Era — the **identical loop**
with a new skin. Three Eras = ~50 hours of the same grind. Ancient Coins
accumulate with no spend; the Eras don't change how you play.

---

## Suggested levers (for the research team / design)

These fall straight out of the data above:

1. **Attack healing downtime** — it's ~half the game. Options: heal during
   questing, much faster base regen, a cheap heal, or make downtime *do
   something* (that's the natural home for active business/management).
2. **Smooth the early difficulty curve / the 5→10 gate** — catch-up XP, a
   gentler ramp, or scaling rewards so the first wall isn't a multi-hour slog.
3. **Make grinding a decision, not a spam loop** — quest modifiers, risk/reward,
   variety bonuses, anti-repetition diminishing returns, or objectives that
   rotate, so the optimal play isn't "spam the one best node."
4. **Fix hint RNG** — let shards target a chosen quest, or separate the hidden
   quests' hint pools.
5. **Make stat choice and prestige matter** — differentiate the four stats,
   give Ancient Coins a meaningful spend, and give the three Eras real
   mechanical identity so the meta-loop is a reason to continue.

_Re-run any of these claims with `dart run bin/run_sim.dart --all --runs 100`._
