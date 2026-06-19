# Guilds of Antiquity — Music & Audio Brief

Prompts and notes for generating the game's soundtrack (e.g. with Google Gemini / Lyria "music maker"). This feeds **Milestone 2 (Audio)** in `V1_PLAN.md` — once the files exist, the per-era music + fade-on-era-change gets wired up and `assets/audio/` is declared in `pubspec.yaml`.

## Design principle (important for an idle game)
The per-era background loops should be **low-intensity and non-fatiguing** — players leave the game running for long sessions, so the loops want to be ambient and sparse. Save the big, energetic music for the siege/boss and the era-transition cue. All three era loops should feel sonically distinct (they swap with the theme) but share a calm background energy so switching isn't jarring.

---

## Per-era background loops (primary need)

### Era 1 — Warrior / Age of Iron  (theme: red & gold, conquest)
```
Medieval ambient background loop for a guild-management game, warm and slow, around 70 BPM. Soft plucked lute and hammered dulcimer over sustained low cello drones, a faint heartbeat of distant war drums, the warmth of a crackling hearth. Noble but understated, made for long idle listening. Fully instrumental, sparse, seamless loop, no vocals, no abrupt intro or ending.
```

### Era 2 — Thief / Age of Shadows  (theme: navy & neon purple, stealth/heists)
```
Stealthy nocturnal ambient loop, dark and cool, around 85 BPM. Muted pizzicato strings, hushed upright bass, soft brushed percussion, distant night ambience of crickets and dripping water, a thin thread of noir clarinet. Tense yet relaxed, patient and sneaky, suited to long background play. Instrumental, minor key, seamless loop, no vocals.
```

### Era 3 — Mage / Age of Arcanum  (theme: cyan & iridescent, chaotic magic)
```
Ethereal cosmic ambient loop, weightless and mystical, around 60 BPM. Shimmering glassy synth pads, gentle celesta and bell arpeggios, deep resonant drones, airy wordless choir textures, a feeling of floating starlight. Calm and otherworldly, ideal for long idle sessions. Instrumental, no rhythmic drums, seamless loop, no abrupt ending.
```

---

## Set-piece cues (secondary, high impact)

### "The Turn of the Age" — era-transition cinematic
Plays over the ~15s history-scroll screen (`history_screen.dart`). This one is a **one-shot**, not a loop.
```
Short cinematic orchestral cue: the fall of one age and the dawn of another. Opens somber with low strings and a lone French horn, swells into a hopeful sweeping crescendo of full strings and soft timpani, then settles gently. Emotional, epic but restrained, about 30 seconds, with a clear beginning and ending (not looping). Instrumental, no vocals.
```

### "Siege of the Capital" — final boss / prestige battle
```
Epic battle music, tense and driving, around 120 BPM. Pounding taiko and war drums, urgent staccato strings, brass stabs, a heroic minor-key motif building in intensity. Cinematic and relentless for a climactic siege. Instrumental, energy sustained throughout for looping, no vocals.
```

### Museum / main-menu theme (optional but nice)
```
Calm reverent ambient theme for a museum of ancient relics, slow and timeless, around 60 BPM. Sparse music box and harp, a warm sustained pad, faint reverberant space, a gentle nostalgic melody. Peaceful and contemplative. Instrumental, soft dynamics, seamless loop, no vocals.
```

---

## Generation tips
- **Force the loop:** add "seamless loop, no fade-in/out, consistent energy" — Lyria likes to tack on intros/outros. Use the steady middle section if needed.
- **Make 2–3 variants** of each era loop; we can rotate them in-game to cut repetition (the asset-variation system supports numbered suffixes like `_2`, `_3`).
- **Export MP3** — safe cross-platform format for iOS + Android (the code already references `.mp3`).
- **Length:** ~30–70s is plenty for a loop.

---

## Target files → `assets/audio/`
Drop the finished files here with these names. The era index mapping matches `theme_provider.dart` (0 = Warrior, 1 = Thief, 2 = Mage). `AudioService.playMusic()` references paths relative to `assets/`, e.g. `audio/music_warrior.mp3`.

| File | Use | Loop? |
|---|---|---|
| `music_warrior.mp3` | Era 0 background | yes |
| `music_thief.mp3` | Era 1 background | yes |
| `music_mage.mp3` | Era 2 background | yes |
| `cue_turn_of_age.mp3` | Era-transition screen | no (one-shot) |
| `music_siege.mp3` | Final boss / siege | yes |
| `music_museum.mp3` | Museum / menu | yes |

---

## SFX — sourced separately (NOT music-gen)
Lyria won't nail short one-shot effects. These four are already referenced in `audio_service.dart` and should come from a CC0 sound library (Freesound / Kenney):

| File | Trigger |
|---|---|
| `audio/gold_gain.mp3` | gold reward |
| `audio/combat_hit.mp3` | combat resolve |
| `audio/level_up.mp3` | hero level up |
| `audio/legendary_drop.mp3` | legendary item found |

---

## M2 wiring checklist (do once files land)
- [ ] Create `assets/audio/` and declare it in `pubspec.yaml`
- [ ] Source + add the 4 SFX files
- [ ] Call `AudioService.playMusic()` per era (it's defined but never invoked today); fade/swap on era change
- [ ] Play `cue_turn_of_age` on the history screen, `music_siege` during the siege boss
- [ ] Add a Settings screen with sound / music / haptics toggles; respect them in `audio_service` + `feedback_service`
