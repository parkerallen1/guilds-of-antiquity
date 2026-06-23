# Guilds of Antiquity — Game Loop & Engagement Research Brief

> **Purpose of this document.** This is a complete, self-contained description of
> *Guilds of Antiquity* — its core loop, every mechanic, every formula, and the full
> content inventory — assembled so an external research team (game designers, systems
> designers, retention/engagement analysts) can recommend how to make the game **more
> engaging, fun, and exciting** without needing access to the source code.
>
> The specific problem we want solved is stated in §9. Everything before it is the
> context needed to reason about that problem. All numbers below are pulled directly
> from the live code as of this writing, not from marketing copy.

---

## 1. What the game is

*Guilds of Antiquity* is a **mobile (iOS/Android) UI-based idle RPG / management sim**
built in Flutter. There is no real-time action or twitch input. The player builds a
guild, sends a hero on quests, manages a business, collects loot, and eventually
**"prestiges"** — wiping progress to advance into the next of three themed historical
**Eras**, carrying forward a small legacy.

It is a **single-hero-at-a-time, mostly-single-screen** experience. The fantasy is
"run a medieval adventuring guild and build a legacy across the ages." Visual style is
a deliberate retro **medieval 8-bit** (NES/SNES RPG) aesthetic.

**Core pillars as designed:**
- **Idle/management:** send hero out, wait, claim rewards, reinvest.
- **RPG progression:** level up, allocate stats, equip procedural loot.
- **Prestige meta-loop:** three Eras (Warrior → Thief → Mage), each a fresh start with a permanent legacy currency and a persistent Museum collection.

**Important caveat for the research team:** the three Eras currently differ **only in
theme/skin and museum trophies** — the Warrior/Thief/Mage classes have *no mechanical
differences*. `classType` is a cosmetic string (everyone is literally a "Mercenary").
Deep class/era mechanics are explicitly deferred to a future release. So today the
game is effectively **one loop, reskinned twice.**

---

## 2. The core game loop (step by step)

This is the entire moment-to-moment experience:

1. **Create / recruit a hero.** Hero starts at Level 1 with base stats STR 5, SPD 5, HP 100, Luck 0. Recruiting costs 50 gold; in Era 0 you may have only **1 hero**, later up to **5**.
2. **Pick a quest** from the map (main story), the side-quest list, the Tavern, or the Shop. Each quest shows a **recommended difficulty/level**.
3. **Send the hero.** The hero becomes `questing` for a duration (see §3.3). The player **waits** — there is nothing else to actively do during a quest except manage the business/shop.
4. **A 1Hz ticker resolves the quest** when its timer expires (see §3). Outcome = success/failure roll → gold, XP, possible loot, possible level-up, HP loss.
5. **Claim/observe rewards.** XP may trigger a level-up, granting **1 upgrade point** to spend on a stat.
6. **Heal.** If the hero took damage they heal passively over time while idle; if they hit 0 HP they enter **`recovering`** and cannot quest until healed (or you pay gold to revive).
7. **Reinvest.** Spend gold on stat-adjacent purchases, business upgrades, bag upgrades, hints, etc. Equip better loot.
8. **Repeat** quests to grind gold/XP until strong enough for the next main-story quest.
9. **Prestige** when ready: reset everything, gain **Ancient Coins**, advance to the next Era, carry forward Vault items + the Museum.

The **main-story questline** is the spine: 9 main quests gated behind `requiredQuestId`
chains, ending in `siege_capital` (the prestige trigger). Between story beats, the
player grinds **side quests** and **replays** to gain the levels/gold needed for the next
story gate.

---

## 3. Combat & quest resolution (exact formulas)

There is **no interactive combat**. A quest is a single probabilistic resolution at the
end of a timer. All of the following is from `lib/utils/game_logic.dart` and
`lib/services/ticker_service.dart`.

### 3.1 Success chance
```
levelDiff   = hero.level - quest.difficulty
chance      = 80 + (levelDiff * 10) + (hero.totalStr - quest.difficulty) * 0.5
chance      = clamp(chance, 5%, 100%)
```
- At equal level, base success is **80%**.
- Each level above/below the quest difficulty is **±10%**.
- Strength adds a mild **±0.5% per point** above/below difficulty.
- So a hero merely *at* the recommended level already succeeds 80% of the time; +2 levels = 100%.

### 3.2 Health loss (applied on BOTH success and failure)
```
lossPercent = max(0, 90 - (successChance + hero.totalDef))
damage      = round(maxHp * lossPercent / 100)
```
- Higher success chance → less damage. At 90%+ success with any defense, damage ≈ 0.
- Defense comes **only from equipment** (base defense is 0).

### 3.3 Quest duration (where "Speed" matters)
```
speedFactor      = 1 + (hero.totalSpd / 100)        // SPD 100 ⇒ ÷2, SPD 300 ⇒ ÷4
reducedDuration  = quest.durationSeconds / speedFactor
finalDuration    = ceil(reducedDuration / tavernMultiplier)   // min 1 second
```
- Speed is the only stat that compresses the wait. A high-speed build farms much faster.

### 3.4 XP, leveling, upgrade points
```
on success:  xpGained = quest.xpReward (×0.5 if it's a replay of a completed quest)
level-up:    while level < 50 and xp >= level*100:  xp -= level*100; level++; upgradePoints++
```
- **XP to next level = currentLevel × 100.** L1→2 = 100xp, L2→3 = 200xp, … L49→50 = 4900xp.
- **Level cap = 50.**
- Each level grants **exactly 1 upgrade point.**

### 3.5 Spending upgrade points (`hero_detail_sheet.dart`)
Each point buys **one** of:
- **+1 Strength** (mild success bonus)
- **+1 Speed** (faster quests)
- **+10 Max HP**
- **+1 Luck** (loot drop chance)

There is no respec. Points are the *only* way stats grow besides equipment.

### 3.6 Loot drop
```
dropChance = 0.10 + (hero.totalLuck * 0.01)     // base 10%, +1% per Luck
```
On a drop, `LootFactory` rolls rarity then a slot.

---

## 4. Loot & equipment

From `lib/utils/loot_factory.dart`. Four equip slots: **Main Hand, Off Hand, Armor,
Accessory.** Loot is procedural.

**Rarity roll** (d100 + rarityBonus):
| Rarity | Range | Stat multiplier |
|---|---|---|
| Common | 0–69 (70%) | ×1.0 |
| Rare | 70–89 (20%) | ×2.0 |
| Epic | 90–98 (9%) | ×3.0 |
| Legendary | 99 (1%) | ×5.0 |

**Stat magnitude:** `baseStat = round(level × rarityMultiplier)` — loot scales with the
**hero's level at drop time**, so loot found early is permanently weak.

- Main Hand → Strength; Off Hand → Defense (×0.8); Armor → Defense; Accessory → Speed *or* Luck (×0.5).
- Legendaries use named templates (e.g., "Blade of the Fallen King") with high mixed stats.
- **Quest/story rewards** ("Whispering Stone Fragment", "The Abdication Ring", etc.) are one-of-a-kind, granted on **first completion only**, and feed the Museum.

**Inventory:** starts at **20 slots**. "Inventory Full!" blocks new loot. Bag upgrades
from the shop cost `(currentLimit − 15) × 100` gold. Items sell for `10 + rarity×10` gold.

---

## 5. The business / management layer ("The Hall")

The player runs **one** business at a time. Production is **manual and timed**: choose a
duration (1–24 hours), start, wait, then **claim** (no auto-collect). From
`game_provider.dart` / `business_model.dart`:

| Business | Output | Formula (per claim) |
|---|---|---|
| **Mine** | Gold | `300 × hours × amountLvl × (1 + 0.2 × qualityLvl)` |
| **Farm** | Gold + Items | Gold `100 × hours × amountLvl`; Items `ceil(hours × 0.5 × amountLvl)`, quality raises rarity |
| **Lodge** | Quests | `ceil(hours × 0.25 × amountLvl)` procedural "Bounty" quests, quality raises difficulty/reward |

**Upgrade costs** (both Quantity "Amount" and "Quality" tracks):
`cost = 100 × 1.5^(level−1)` — geometric, so each level ~50% pricier.

**Bounty quests** (from the Lodge, `quest_factory.dart`): random target + location,
fixed **5-minute** duration, `gold = 100×diff + rng`, `xp = 50×diff + rng`, 50% drop,
not replayable.

---

## 6. Quest content inventory

There are **32 hand-authored quests** in `assets/data/quests.json` plus procedural
bounties. Quests are gated by `requiredQuestId` and chained by `nextQuestId`.

### 6.1 Main story spine (9 quests, the prestige path)
| # | id | Title | Difficulty | Duration | Gold | XP |
|---|---|---|---|---|---|---|
| 1 | explore_ruins | The Whispering Stone | 1 | 10s | 10 | 20 |
| 2 | clear_forest | Shadows in the Grove | 5 | 30s | 50 | 100 |
| 3 | defend_village | The Traitor's Gate | 10 | 60s | 200 | 500 |
| 4 | mountain_pass | The Frozen Whisper | 15 | 120s | 400 | 800 |
| 5 | cursed_temple | Sanctuary of the Void | 20 | 300s | 800 | 1200 |
| 6 | dragon_lair | Awakening of the Ash-King | 30 | 600s | 2000 | 2500 |
| 7 | dark_army | The March of the Silenced | 40 | 1200s | 5000 | 3500 |
| 8 | siege_capital | The Final Eclipse (**prestige trigger**) | 50 | 3600s | 10000 | 5000 |

(`ancient_library` and others hang off the late chain.) Note difficulty jumps:
1 → 5 → 10 → 15 → 20 → 30 → 40 → 50. The **gaps between story gates** are exactly where
the grind lives.

### 6.2 Side quests & chains
- Standalone repeatables: `training_day`, `daily_patrol`, `dungeon_delve`, `monster_hunt`, plus many one-offs (`lost_cat`, `rat_cellar`, `millers_ghost`, etc.).
- **Multi-part chains** with lore + unique legendary rewards: **The Lost Heir** (3 parts), **Cursed Amulet** (2 parts), **The Bandit King** (3 parts, partly hint-gated).
- **Hint-gated secrets:** some legendary quests (`bandit_king_3`, `dragon_lair`) need `requiredHints` (e.g., 3) before they appear. Hints come from buying **Mysterious Shards** (500 gold each) in the shop — a random eligible quest gets a hint per purchase.

### 6.3 Replay scaling (`quest_logic.dart`)
Completed quests can be **replayed** at reduced reward (≈50% gold/XP). To fight
staleness, repeated quests get an "Elite" bump by completion count:
| Completions | Difficulty bonus | Reward multiplier |
|---|---|---|
| 10+ | +1 | ×1.2 |
| 25+ | +2 | ×1.5 |
| 50+ | +3 | ×2.0 |

### 6.4 How new quests surface (the discovery pipeline)
- **Story:** completing a quest auto-unlocks its `nextQuestId`.
- **Tavern:** periodically offers a new side quest. Timer is **~1 hour** for the first, then **10–14 hours** between subsequent ones (`tavern_tab.dart`). This is *very* slow.
- **Lodge business:** generates bounties on claim.
- **Shop:** sells shards (hints) and bag upgrades; rotating quest offers cost `difficulty × 10` gold to accept.
- There is a **TODO in the code** for "random chance to discover a side quest on success" — currently **not implemented**, so quests do NOT drop organically from adventuring.

---

## 7. Prestige & meta-progression

From `game_provider.resetGame()`:
- **Trigger:** completing `siege_capital`.
- **Reward:** `ancientCoins += floor(gold / 10000)` — a permanent currency.
- **Wipe:** heroes, inventory, active quests, logs, gold (→0), business, vault level, artifacts, all quest progress/hints/completion counts.
- **Carry-over:** **Vault items** (moved into the new inventory) + the **Museum** collection + Ancient Coins. Vault capacity = `vaultLevel` (upgradeable, `vaultLevel × 1000` gold).
- **Advance:** `currentEraIndex++` (Era 1 Iron/Warrior → Era 2 Shadows/Thief → Era 3 Arcanum/Mage).

**Open design gap:** Ancient Coins are *accumulated but have almost no sink/effect on
gameplay yet.* The prestige reward currently feels mostly cosmetic (new theme + museum
trophies). There is no mechanical era differentiation.

**Artifacts** (`artifact.dart`) — powerful passives — exist in code (Greed Coin = ×2
gold; Chrono Dial = ÷2 quest time; Phoenix Feather = cheat death once) but currently
have **no earn path / UI to acquire them.**

**Museum:** a persistent, cross-playthrough collection of every unique item ever found.
It is framed as the meta-progression "trophy case" but is currently passive (display
only, no bonuses).

---

## 8. Death / failure model

- Quest failure still costs HP and yields no rewards (XP only on success).
- At 0 HP the hero enters **`recovering`**: heals at ~3× idle rate, auto-returns to idle, cannot quest meanwhile. A **Revive (gold)** button is the fast path. An active Phoenix Feather is consumed to cheat death (survive at 1 HP).
- Passive idle healing: roughly **full HP in 1 hour** at base, reduced by Speed.

---

## 9. The problem we want researched (the actual ask)

> **"The game loop is too loose. It gets repetitive and boring when you're stuck on the
> same side quest waiting to level up."**

Concretely, what the player experiences:

1. **Long dead gaps between story gates.** Each main quest is a big difficulty jump
   (e.g., 20 → 30 → 40 → 50). To clear the next gate at a comfortable success rate you
   need several levels. With XP-to-level = `level×100` and only ~50% XP on replays, the
   player ends up **re-running the same one or two best side quests dozens of times**
   purely to grind levels.
2. **No decisions during the grind.** A quest is "tap → wait → claim." During the wait
   there is no meaningful interaction. Stat allocation is 1 point per level into one of
   four sliders. The "build" space is shallow.
3. **Slow, thin content faucet.** New side quests arrive from the Tavern only every
   **10–14 hours**, organic discovery-on-success is unimplemented, and the Lodge requires
   you to already be investing hours into the business. So the player rarely gets a
   *fresh* objective exactly when they're bored of the current one.
4. **Weak short-term goals & feedback.** Outside of a rare level-up or 1%-chance
   legendary, most claims are "you got some gold and some XP." There are no quotas,
   streaks, daily goals, milestones, or surprises pulling the player to the next claim.
5. **Reward curve is flat in feel.** Loot scales to level and rarities are mostly common;
   gold mostly recirculates into business/bag upgrades that just make more gold. The
   prestige payoff (Ancient Coins) has no spend, and Eras don't change how you play.
6. **The idle promise is half-kept.** (For context: offline progression isn't fully wired
   yet, so the game mostly only advances while open — which makes the active grind feel
   even more like the *only* thing to do.)

**What we want from the research:** concrete, prioritized recommendations to tighten the
loop and raise engagement — drawing on best practices from successful idle/incremental
RPGs and management games. Specifically we'd value guidance on:

- **Pacing the level/XP and difficulty curves** so the player is never stuck grinding the
  same node for more than a short, satisfying burst (catch-up XP, scaling rewards, soft
  level gates vs. hard walls, "rested"/bonus XP, etc.).
- **Adding meaningful choice to the moment-to-moment loop** (build diversity, quest
  modifiers/risk-reward, active abilities, party/multi-hero synergy) without breaking the
  idle/casual framing.
- **A tighter short-term goal layer** (dailies, bounties, milestone chains, collection
  goals, events) that creates "one more quest" pull.
- **Making rewards feel exciting** (drop-table design, pity/streak systems, juicy
  feedback, chase items) at a casual mobile cadence.
- **Giving prestige and the three Eras real teeth** — what should Ancient Coins buy, and
  how can Warrior/Thief/Mage Eras play differently enough to make the meta-loop a reason
  to keep going rather than a reset?
- **Closing the boredom-during-wait gap** — what should a player *do* while a hero is out?

**Constraints to respect in recommendations:**
- Mobile, casual, **no twitch/action gameplay** — it must stay a tap-and-manage idle RPG.
- Single hero early (max 5 later); mostly single-screen UI.
- Built on the existing systems above; prefer tuning + additive systems over ground-up redesigns.
- Retro 8-bit presentation; small art budget.

---

## 10. Quick-reference cheat sheet (all the numbers in one place)

- **Base stats:** STR 5, SPD 5, HP 100, Luck 0. **Recruit cost:** 50 g. **Roster:** 1 (Era 0) → 5.
- **Success:** `80 + 10×(level−diff) + 0.5×(STR−diff)`, clamped 5–100%.
- **Damage %:** `max(0, 90 − success% − DEF)` of max HP, on win *or* loss.
- **Quest time:** `duration / (1 + SPD/100)`, ÷ tavern mult, min 1s.
- **Drop chance:** `10% + 1%×Luck`. **Rarity:** 70/20/9/1 % (C/R/E/L), stat ×1/×2/×3/×5.
- **XP to level:** `level × 100`. **Cap:** L50. **1 upgrade point/level.** Point = +1 STR / +1 SPD / +10 HP / +1 Luck.
- **Replay reward:** ~50%; **Elite scaling** at 10/25/50 completions (+1/+2/+3 diff, ×1.2/1.5/2.0 reward).
- **Business upgrade cost:** `100 × 1.5^(lvl−1)`. **Mine gold:** `300×h×amt×(1+0.2×qual)`. **Farm gold:** `100×h×amt`.
- **Bag upgrade:** `(limit−15) × 100` g. **Shard (hint):** 500 g. **Sell item:** `10 + 10×rarity`.
- **Prestige:** `ancientCoins += floor(gold/10000)`, full wipe, carry Vault + Museum, Era++.
- **Idle heal:** ~full HP / hour (faster with SPD); **recovering** ≈ 3× that rate.
- **Tavern new-quest cadence:** ~1h first, then 10–14h.

---

*Prepared as the research-context handoff for the "tighten the game loop / improve
engagement" investigation. Source of truth: the live Flutter codebase (`lib/`,
`assets/data/quests.json`).*
