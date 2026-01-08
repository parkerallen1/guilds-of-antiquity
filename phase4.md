Here is the technical specification for **Phase 4: The Juice, The Artifacts & The Museum**.

Phase 1-3 built a functional spreadsheet. Phase 4 turns that spreadsheet into a **Game**. This phase focuses on "Game Feel" (VFX, SFX, Haptics) and the deep-progression systems (Artifacts/Museum) that keep players for months.

***

# Technical Brief: Guilds of Antiquity - Phase 4 (Polish & Game Feel)

**Goal:** Implement "Juice" (Game Feel), Audio, and the "Rule-Breaking" Artifact system.
**Key Deliverables:** VFX Engine (Particles/Shake), Audio Manager, Haptic Integration, Artifact Logic, and the Global Museum.

---

## 1. The "Juice" Engine (Visuals & Haptics)

We need a dedicated service to handle feedback. Do not sprinkle code everywhere. Use a centralized `FeedbackService`.

### A. Visual Effects (VFX)
*   **Tech:** `flutter_animate` (for easy UI animations) and `confetti` package (for Loot).
*   **Screen Shake:** Create a `ShakeWidget` wrapper around the main Scaffold.
    *   *Trigger:* On "Combat Failure" or "Crit".
    *   *Logic:* Offset the X/Y by random(5px) for 200ms.
*   **Floating Text:** When Gold/XP is gained, spawn a text widget at the tap location that floats up and fades out.
    *   *Colors:* Gold (Currency), White (XP), Red (Damage).

### B. Haptics
*   **Tech:** `flutter/services.dart` -> `HapticFeedback`.
*   **Tiers:**
    *   `lightImpact`: Button presses.
    *   `mediumImpact`: Quest Complete / Gold gain.
    *   `heavyImpact`: Level Up / Building Upgrade.
    *   `vibrate`: Legendary Drop (Long buzz).

---

## 2. Audio Manager

Sound is 50% of the "Premium" feel.

*   **Tech:** `audioplayers` or `flame_audio` (Flame Audio is easier for pre-loading).
*   **The Soundscape (Per Era):**
    *   *Warrior:* Tavern ambience (muffled chatter, fire crackling).
    *   *Thief:* Night ambience (crickets, distant wind, dripping water).
    *   *Mage:* Ethereal hum (low synth drone).
*   **SFX Triggers:**
    *   `playGoldSound()`: Randomized pitch (so it doesn't get annoying).
    *   `playCombatHit()`: Sword clash vs Dagger shing vs Magic zap (based on Era).
    *   `playLegendaryDrop()`: A distinct "Choir" or "Gong" sound.

---

## 3. The Artifact System (Code Hooks)

Artifacts are not just "Items" with stats. They inject custom logic into the game loop.

### Architecture
Create an `Artifact` abstract class with hooks.
```dart
abstract class Artifact {
  String id;
  String name;
  String description;
  bool isUnlocked;

  // Hooks - Default to doing nothing
  double modifyGoldGain(double current) => current;
  int modifyQuestDuration(int seconds) => seconds;
  bool preventDeath(Hero hero) => false;
}
```

### Implementation Examples
1.  **The Greed Coin:**
    *   `modifyGoldGain` -> return `current * 2.0`;
    *   *Drawback:* You must handle the "Death" logic elsewhere.
2.  **The Chrono-Dial:**
    *   `modifyQuestDuration` -> return `seconds / 2`;
3.  **The Phoenix Feather:**
    *   `preventDeath` -> Returns `true` (and consumes the item).

### Integration
In your `GameTick` or `QuestLogic`, you must loop through active Artifacts:
```dart
// Inside Quest Logic
int duration = 600;
for (var artifact in activeArtifacts) {
  duration = artifact.modifyQuestDuration(duration);
}
```

---

## 4. The Museum (Long-Term Retention)

The Museum exists **outside** the loop. It tracks everything you have *ever* found across all resets.

### Data Model
```dart
class MuseumState {
  Set<String> unlockedItemIds; // IDs of every sword/ring found
  Set<String> unlockedEndings; // "Emperor", "Shadow King", "Archmage"
  
  double get completionPercentage => unlockedItemIds.length / totalItems;
}
```

### UI Specification
*   **Location:** Main Menu (Before entering the game world).
*   **Visuals:** A grid of 100 slots.
    *   *Locked:* A black silhouette (Use `ColorFiltered` widget with `BlendMode.srcIn`).
    *   *Unlocked:* Full color icon + Tap to view lore.
*   **Reward:**
    *   Find 50% of items: Start every run with +100 Gold.
    *   Find 100% of items: Unlock "God Mode" (Sandbox/Creative).

---

## 5. User Experience (UX) Polish

### A. The "Offline" Welcome Screen
When the user opens the app after 8 hours:
*   **Don't** just update the numbers silently.
*   **Do:** Show a modal summary.
    *   *"Welcome back, Guild Master."*
    *   *"While you were gone (8h 12m):"*
    *   *+ 4,502 Gold*
    *   *+ 12 Items Found*
    *   *3 Heroes Died (RIP)*
    *   *Button:* "Collect" (Triggers a satisfying gold animation).

### B. The Tutorial (First Run Only)
*   Use a "Spotlight" overlay (package: `tutorial_coach_mark`).
*   **Step 1:** Highlight "Recruit" -> "You need a hero."
*   **Step 2:** Highlight "Quest" -> "Send him to work."
*   **Step 3:** Wait 10s.
*   **Step 4:** Highlight "Inventory" -> "Equip this rusty sword."

---

## 6. Phase 4 Roadmap

1.  **Asset Collection:**
    *   Buy/Find an icon pack (RPG Icons).
    *   Buy/Find an audio pack (UI clicks, Medieval ambience).
    *   *Dev Note:* Ensure licenses permit commercial use.
2.  **The Feedback Service:** Create the class. Connect it to `Riverpod`. Replace all `print()` statements with `FeedbackService.showLog()`.
3.  **Audio Integration:** Implement background music that fades when changing Eras. Add click sounds to *every* button.
4.  **Artifact Logic:** Build the `Artifact` class. Hardcode 3 artifacts to test the hooks.
5.  **Visual Polish:** Add the "Floating Text" for damage/gold. Add the particle confetti for Legendary drops.
6.  **The Museum:** Implement the persistent Hive box for the collection.
7.  **Offline Calculation:** Build the "Welcome Back" modal.

---

## 7. Creative "Easters Eggs" (For the Team)

*   **The Konami Code:** If the player taps the Guild Logo 10 times, give them 1,000 gold. (Good for debugging, fun for players).
*   **The "Developer" Item:** Add a rare item named after the Lead Developer that has absurdly bad stats (or good ones).

---

# Final Project Summary (Phases 1-4)

If you execute these 4 phases, you will have:
1.  **MVP:** A working text RPG loop.
2.  **RPG Depth:** Deep stats, loot generation, and equipment strategy.
3.  **Meta-Game:** A generic-shifting world (Warrior/Thief/Mage) with building management.
4.  **Polish:** A juicy, high-quality mobile experience with long-term collection goals.

**You are now ready to build.** Start with Phase 1 and don't let feature creep set in until you hit Phase 4!