Here is a technical specification document tailored for a Flutter developer. It breaks down **Phase 1: The Age of Iron** into architectural decisions, data models, and specific implementation steps.

You can copy-paste this directly to your developer.

***

# Technical Brief: Guilds of Antiquity - Phase 1 (MVP)

**Target Platform:** Flutter (iOS & Android)
**Core Concept:** UI-Based Idle RPG (Text-heavy, management focus, no 3D physics).
**Phase 1 Goal:** The "Warrior Era" loop. Recruit heroes, send on timed quests, receive loot/text logs, upgrade base.

---

## 1. Recommended Tech Stack
*   **State Management:** **Riverpod** (Preferred) or Provider. We need global state that updates frequently (game ticks).
*   **Local Database:** **Hive** or **Isar**.
    *   *Why:* We need to store complex objects (Heroes, Items) efficiently. `Shared_Preferences` is too weak; `SQL` is too slow/boilerplate. Hive is blazing fast and NoSQL.
*   **UI Library:** standard Flutter Widgets + **Google Fonts** (Cinzel or Lato for that RPG feel).
*   **Icons:** **FontAwesome** or **Lucide** (Clean, distinct icons for UI).

---

## 2. Architecture & Core Loop

### The "Game Tick" Engine
Since this is not a physics game, we do **not** need a game engine like Unity or Flame.
*   **Implementation:** Use a `Timer.periodic` (running every 1 second) in a background Service/Controller.
*   **Logic per Tick:**
    1.  Check active quests: `if (CurrentTime > QuestEndTime) -> Complete Quest`.
    2.  Passive healing for heroes in the Guild Hall.
    3.  Update UI state (Gold generation if applicable).

### Offline Progression (Crucial)
The game must calculate what happened while the app was closed.
*   **On App Start:** Compare `DateTime.now()` with `LastSavedTime`.
*   **Calculation:** `TimeDifference = Now - LastSave`. Run the simulation loop for that duration (e.g., instantly finish quests that would have ended 2 hours ago).

---

## 3. Data Models (The Schema)

Please implement these Hive Objects/Models.

**A. Hero Model**
```dart
class Hero {
  String id;
  String name;      // e.g., "Gorlag the Stout"
  String classType; // "Mercenary" (Fixed for Phase 1)
  int level;
  int xp;
  
  // Stats
  int strength;     // Determines combat success
  int speed;        // Reduces quest duration
  int hp;           // Current Health
  int maxHp;
  
  // State
  HeroStatus status; // Enum: IDLE, QUESTING, DEAD, RECOVERING
  DateTime? questCompletesAt; // Null if idle
  
  List<Item> inventory; // Max 3 slots
}
```

**B. Quest Model**
```dart
class Quest {
  String title;       // "Clear the Rat Cellar"
  int difficulty;     // Target Strength req
  int durationSeconds;
  int goldReward;
  int xpReward;
  double dropRate;    // e.g. 0.05 for Legendary
}
```

**C. LogEntry Model (The "Matrix Code" Feed)**
```dart
class LogEntry {
  String message;     // The flavor text
  LogType type;       // Enum: INFO (White), COMBAT (Red), LOOT (Green), GOLD (Yellow)
  DateTime timestamp;
}
```

---

## 4. UI Specification (The "Beautiful Simple" Layout)

The app should use a **Scaffold** split into three distinct vertical sections.

### Section A: The Stage (Top 20%)
*   **Visual:** A static, high-quality asset of a "Medieval War Table" or "Barracks."
*   **Overlay:** A "Gold Counter" (Big, bold font) and "Active Heroes" count (e.g., 3/5).
*   **Creative Liberty:** Feel free to add a subtle parallax effect or floating dust particles here using `AnimatedPositioned` or simple Lottie files.

### Section B: The Log (Middle 45%)
*   **Widget:** `ListView.builder` (Reverse order, newest at bottom).
*   **Style:** Dark background (`Color(0xFF1A1A1A)`). Text should be monospace or serif.
*   **Functionality:**
    *   When a hero deals damage: `Text("Gorlag hits for 12.", color: Colors.red)`
    *   When loot drops: `Text("FOUND: Rusty Sword!", color: Colors.greenAccent)`
    *   *Dev Note:* Add a `ShaderMask` at the top of this list so text fades out smoothly as it scrolls up.

### Section C: The Command Deck (Bottom 35%)
*   **Structure:** Tabbed View or Horizontal Scroll.
*   **Tab 1: Roster (Manage Heroes)**
    *   List of Hero Cards showing HP bars and "Equip" buttons.
    *   Action: Tap Hero -> Send on Quest -> Select Quest from Popup.
*   **Tab 2: Recruit (The Tavern)**
    *   Button: "Hire Mercenary (50 Gold)".
*   **Tab 3: Build (Upgrades)**
    *   Button: "Blacksmith (Increases Base Strength)" - Cost: 200 Gold.
    *   Button: "Barracks (Increases Hero Cap)" - Cost: 500 Gold.

---

## 5. Mechanics to Implement (Logic)

### 1. The Combat Formula (Simplified for MVP)
When a quest completes, run this check:
```dart
bool success = (Hero.strength + Random().nextInt(5)) > Quest.difficulty;

if (success) {
  // Grant Gold & XP
  // 10% chance to take small damage
  // Generate "Success" Log
} else {
  // Hero takes massive damage (HP - 50)
  // No Gold
  // Generate "Failure" Log
}
```

### 2. The Loot Generator
If a quest is successful, roll 1-100.
*   If roll > 90: Generate an `Item`.
*   **Item Generation Logic:** Pick a random `Adjective` ("Heavy", "Sharp") + `Noun` ("Dagger", "Shield").
*   *Stat Logic:* "Sharp" adds +2 Str. "Heavy" adds +2 Defense.

### 3. The Flavor Text Generator
Create a helper class `TextGen`.
*   `TextGen.generateAttack(heroName, enemyName)`
*   Returns random string: `"$heroName smashes the $enemyName with a chair!"` or `"$heroName stabs the $enemyName in the knee!"`

---

## 6. Implementation Roadmap (Order of Operations)

1.  **Project Setup:** Initialize Flutter, setup Riverpod scope, setup Hive boxes.
2.  **Skeleton UI:** Build the 3-section layout with dummy data (hardcoded strings).
3.  **The Loop:** Create the `Timer` service. Make the Gold counter go up by 1 every second automatically to test the state connection.
4.  **Hero Logic:** Implement "Recruit" button. Display dynamic heroes in the list.
5.  **Quest Logic:** Implement the "Send" button and the delayed "Return" logic. Connect the Text Log to these events.
6.  **Polish:** Add the colors, fonts, and the fading text effect.

**Deliverable:** An APK/TestFlight build where I can hire a guy, send him to kill a rat, watch a timer, read a log that he killed it, and see my gold go up.