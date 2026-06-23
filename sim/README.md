# `sim/` — Headless balance simulator & text-play harness

A standalone Dart package that lets a bot (or an AI/LLM, or you) **play the real
game loop without the Flutter UI**, to find balance and pacing problems.

It is *faithful*: it imports the actual game logic (`lib/utils/game_logic.dart`,
`lib/utils/loot_factory.dart`, `lib/utils/quest_logic.dart`) and the shared
`lib/engine/quest_resolver.dart` — the **same resolver the live game's
`TickerService` calls**. So results reflect the real game, not a copy.

> Scope: this models the **questing → level-up → story-gate** loop, which is the
> repetitive-grind pain point. Business/Hall income is not yet modelled. See
> `FINDINGS.md` for what the sim has already surfaced, and for the important
> caveat that a bot measures *balance*, not *fun*.

## Setup

This package needs only pure-Dart deps (`hive`, `uuid`); it does **not** need
Flutter. With the Dart SDK on your PATH:

```bash
cd sim
dart pub get
```

## Mode 1 — mass bot runs (balance data)

Runs many full playthroughs and prints an aggregate report (completion rate,
hours, attempts, per-story-gate grind, healing time, etc.).

```bash
# one policy
dart run bin/run_sim.dart --policy balanced --runs 100

# compare all five play styles
dart run bin/run_sim.dart --all --runs 100

# isolate the tavern content-faucet, dump per-run rows to CSV
dart run bin/run_sim.dart --policy balanced --runs 100 --no-tavern --csv out.csv
```

Flags: `--policy <name>` | `--all`, `--runs N`, `--no-tavern`, `--csv FILE`,
`--seed N`. Policies: `rush_story`, `balanced`, `speed_stacker`, `greedy_gold`,
`tank` (see `lib/policies.dart`).

## Mode 2 — interactive / AI text play

Play one quest at a time via a text interface. Drive it interactively, or pipe a
script of commands (this is how an LLM "plays" it):

```bash
# interactive
dart run bin/play.dart

# scripted (an AI emits these lines)
printf 's\nq\ngo explore_ruins\nup str\nauto 50\ns\n' | dart run bin/play.dart
```

Commands: `s`/`status`, `q`/`quests`, `go <id|index>`, `up <str|spd|hp|luck>`,
`auto <n>` (let the built-in bot fast-forward N quests), `i`/`inv`, `shard`,
`help`, `exit`.

## Layout

| File | Role |
|---|---|
| `lib/quest_repo.dart` | Loads real `assets/data/quests.json`; prereq/hint gating |
| `lib/sim_state.dart` | Mutable game state: gold, hero, inventory, equip, heal-time |
| `lib/simulator.dart` | The loop + `applyQuestStep` (shared by bots and REPL) |
| `lib/policies.dart` | Bot play styles (quest-risk threshold + stat allocation) |
| `lib/metrics.dart` | Per-run results + aggregation helpers |
| `bin/run_sim.dart` | Mass-run CLI + report |
| `bin/play.dart` | Interactive / scriptable text play harness |

## Faithfulness notes / known approximations

- **Healing:** the bot rests to full before each fight. Total heal time is
  invariant to *when* you rest (you heal back exactly the damage taken), so the
  aggregate is faithful; it slightly overstates if you'd otherwise quest at
  partial HP and take near-zero damage.
- **Tavern timer** advances on virtual play-time (quest + heal seconds), since
  the live game only ticks while open (offline progression isn't wired yet).
- **Inventory full:** the bot auto-sells the cheapest item to make room (a
  reasonable-player behaviour; the raw game would drop the new item).
- **RNG** is non-seeded by default (`--seed` seeds the bot's decision RNG, not
  the game's internal loot/combat RNG); run many trials for stable medians.
