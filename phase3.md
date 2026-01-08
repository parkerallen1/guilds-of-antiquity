Here is the technical specification for **Phase 3: The Empire & The Turn of the Age**.

Phase 1 was **Time**. Phase 2 was **Items**. Phase 3 is **Scale**.
This phase implements the "Tycoon" building mechanics and the critical "Prestige/New Game+" engine that makes the game infinite.

***

# Technical Brief: Guilds of Antiquity - Phase 3 (Buildings, Prestige & Themes)

**Goal:** Implement the exponential growth economy (Buildings) and the "Prestige" mechanic (Era Shifting).
**Key Deliverables:** Building Upgrade System, The "Vault" Persistence, Global Theme Engine, and the "End of Era" Logic.

---

## 1. Data Model Expansions

### A. The Building Model
Buildings act as global multipliers.
```dart
enum BuildingType { blacksmith, tavern, library, treasury, vault }

class Building {
  BuildingType type;
  int level;
  double baseCost;
  double costMultiplier; // Usually 1.5x per level
  
  // Dynamic Getter for Cost
  int get currentCost => (baseCost * pow(costMultiplier, level)).toInt();
  
  // Dynamic Getter for Effect
  // e.g., Level 5 Blacksmith = 1.25x damage
  double get effectMultiplier => 1.0 + (level * 0.05); 
}
```

### B. The Global State (Era Manager)
We need a singleton to manage the "Meta Game."
```dart
class GameState {
  int currentEraIndex; // 0 = Warrior, 1 = Thief, 2 = Mage
  List<Item> vaultItems; // Items saved from previous runs
  int ancientCoins; // Prestige currency earned after reset
  
  // Theme Getters
  Color get primaryColor => ... // Changes based on currentEraIndex
  String get currencyName => ... // "Gold" -> "Stolen Goods" -> "Mana"
}
```

---

## 2. The Building System (Tycoon Mechanics)

Implement a new tab/screen: **"The Hall"**.

### The Math
*   **The Blacksmith:** Multiplies `Hero.totalStr`.
*   **The Tavern:** Reduces `Quest.duration`.
*   **The Library:** Multiplies `XPGain`.
*   **The Treasury:** Generates passive Gold/Sec (Idle income).
    *   *Dev Note:* This requires updating the `GameTick` timer to add `(TreasuryLevel * 1 gold)` every second.

### The Vault (Special Logic)
The Vault is unique. It doesn't give stats; it gives **Slots**.
*   Level 1 Vault = 1 Slot for "New Game+".
*   Level 2 Vault = 2 Slots.
*   *Constraint:* Max level 5.

---

## 3. The "Prestige" Engine (The Era Shift)

This is the most dangerous code in the project. It deletes data. Proceed with caution.

### A. The Trigger
The "Boss Quest" (The Siege of the Capital).
*   Available only when `GuildHall.level > 50`.
*   Difficulty: Extremely High.
*   On Success: Trigger `showEndGameDialog()`.

### B. The Reset Logic
When the player accepts the transition to the next Era:
1.  **Serialize Legacy:** Move selected items from `Hero.inventory` to `GameState.vaultItems`.
2.  **Calculate Prestige Currency:** `AncientCoins += (TotalGold / 10,000)`.
3.  **The Wipe:**
    *   `Heroes.clear()`
    *   `Inventory.clear()`
    *   `Buildings.resetLevels()`
    *   `Gold = 0`
4.  **The Advance:** `currentEraIndex++`.
5.  **The Rebuild:** Reload the App Shell with the new Theme.

---

## 4. The Theme Engine (Dynamic UI)

To make the Eras feel distinct without rewriting the app, use Flutter's `ThemeData`.

### Implementation
Create an `AppTheme` provider that listens to `GameState.currentEraIndex`.

*   **Warrior Era (Index 0):**
    *   Font: *Cinzel* (Serif, jagged).
    *   Colors: Slate Grey, Blood Red, Gold.
    *   Background: Stone Texture.
*   **Thief Era (Index 1):**
    *   Font: *Lato* or *Courier* (Clean, precise).
    *   Colors: Dark Navy, Neon Purple, Silver.
    *   Background: Blueprint/Grid Texture.
*   **Mage Era (Index 2):**
    *   Font: *Uncial Antiqua* (Mystical).
    *   Colors: White, Cyan, Iridescent.
    *   Background: Starfield.

*Dev Note:* Wrap the entire `MaterialApp` in a `Consumer` that rebuilds when Era changes.

---

## 5. UI Specifications (Phase 3)

### A. The Building Grid
*   **Layout:** `SliverGrid`.
*   **Card Design:**
    *   **Top:** Icon + Name ("Blacksmith").
    *   **Middle:** Current Level ("Lvl 12") + Big Green Stat Text ("+60% STR").
    *   **Bottom:** Big Button ("Upgrade: 500g"). Disable button if `Gold < Cost`.

### B. The Vault Selector (End Game Screen)
*   **Visual:** A dramatic, dark modal. "Choose your Legacy."
*   **Interaction:**
    *   Left Side: Your current Heroes' gear.
    *   Right Side: The Vault (Slots based on Vault Building Level).
    *   Action: Drag and drop items to save them.
    *   Button: "Transcends Time" (Confirm Reset).

---

## 6. Implementation Roadmap (Phase 3)

1.  **Global State:** Refactor the main provider to handle `currentEraIndex`.
2.  **The Building Tab:** Build the UI. Connect the "Upgrade" buttons to subtract gold and increase level.
3.  **Stat Connection:** Go back to the `CombatFormula` (Phase 1/2) and inject the Building Multipliers.
    *   *Check:* `Strength = (Base + Item) * BlacksmithMultiplier`.
4.  **The Theme System:** Create the 3 theme definitions. Add a "Debug Button" to cycle through them instantly to test UI compliance.
5.  **The Wipe:** Write the `resetGame()` function. Test it thoroughly. Does it actually delete the heroes? Does it keep the Vault items?
6.  **The Vault Logic:** When a new game starts, check `GameState.vaultItems`. If items exist, put them in the "Inventory" immediately on startup.

---

## 7. Narrative & "Juice" (The Polish)

### The "History" Scroll
When an Era changes, display a scrolling text screen (Star Wars style).
*   **Warrior -> Thief:** *"The Empire you built brought peace, but peace breeds corruption. In the shadows of your great monuments, a new guild rises..."*
*   **Thief -> Mage:** *"The Empire collapsed from within. The chaos has torn the veil of reality. Magic floods the ruins..."*

### Visual Feedback
*   **On Building Upgrade:** Play a heavy "Hammer Anvil" sound. Shake the individual card.
*   **On Era Change:** Fade to White (duration: 2 seconds), then Fade from Black into the new color scheme.

**Deliverable:** A complete loop. I play Era 1, build a Blacksmith, kill the final boss, save my "Legendary Sword," screen fades to white, and I wake up in the Thief Era (Blue UI) with 0 gold, no heroes, but my Legendary Sword in my bag.