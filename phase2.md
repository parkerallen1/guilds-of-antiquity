Here is the technical specification for **Phase 2: The Armory & The Algorithm**.

While Phase 1 built the *skeleton* (timers and text), Phase 2 builds the *addiction* (loot, stats, and progression).

***

# Technical Brief: Guilds of Antiquity - Phase 2 (Items, Stats & Economy)

**Goal:** Transform the simple "wait-for-timer" loop into a "gear-optimization" loop.
**Key Deliverables:** Procedural Item Generation, Inventory Management, Advanced Stat Logic, and the Shop.

---

## 1. Data Model Expansions (Hive Updates)

We need to upgrade the `Hero` model and introduce a robust `Item` model.

### A. The Item Model (Procedural)
Items need to be flexible. Avoid hardcoding "Iron Sword". Use a component-based structure.

```dart
enum ItemRarity { common, rare, epic, legendary } // Color: Grey, Blue, Purple, Gold
enum ItemSlot { mainHand, offHand, armor, accessory }

class Item {
  String id;
  String name;         // Generated: "Vicious Longsword of the Bear"
  ItemRarity rarity;
  ItemSlot slot;
  
  // Stats (Values can be 0)
  int bonusStr;        // Adds to Combat Power
  int bonusDef;        // Reduces incoming damage
  int bonusSpd;        // Reduces Quest Duration (minutes)
  int bonusLuck;       // Increases Drop Rate %
  
  int value;           // Gold sell price
}
```

### B. The Hero Model Update
Update the `Hero` class to support equipping items.

```dart
class Hero {
  // ... existing fields (id, name, etc) ...
  
  // New Equipment Slots (Nullable)
  Item? mainHand;
  Item? offHand;
  Item? armor;
  Item? accessory;
  
  // Getter for Total Stats (Base + Gear)
  int get totalStr => baseStr + (mainHand?.bonusStr ?? 0) + ... ;
}
```

---

## 2. The "Loot Engine" (Logic)

This is where the fun happens. We need a `LootFactory` class.

### Procedural Name Generation
Don't manually write items. Combine strings.
*   **Prefixes:** "Rusty", "Polished", "Vicious", "King's".
*   **Roots:** "Dagger", "Greataxe", "Plate", "Ring".
*   **Suffixes:** "of Speed", "of Greed", "of the Mountain".

### The Generation Algorithm
When a quest drops loot (`dropRate > Random()`), call `LootFactory.generate(level)`:
1.  **Roll Rarity:** 70% Common, 20% Rare, 9% Epic, 1% Legendary.
2.  **Roll Slot:** Random `ItemSlot`.
3.  **Calculate Stats:**
    *   `Base Stat = ItemLevel * Multiplier`.
    *   *Common:* 1x Multiplier.
    *   *Legendary:* 5x Multiplier + Special Suffix.
4.  **Assign Name:** If stat is Strength, pick Strength-related names (e.g., "Bear", "Titan").

---

## 3. Mechanics Update (The Combat Math)

Update the Phase 1 combat logic to utilize the new stats.

### A. Quest Duration Calculation
*   *Old:* Fixed time (e.g., 10 minutes).
*   *New:* `Duration = BaseTime - (Hero.totalSpd * 0.5 minutes)`.
*   *Constraint:* Minimum duration is always 30 seconds (don't let it go negative).

### B. Damage Mitigation
*   *Old:* Hero takes fixed 50 damage on failure.
*   *New:* `DamageTaken = (EnemyAttack - Hero.totalDef)`.
    *   If `Hero.totalDef` is high enough, they take 0 damage (farming mode).

### C. The "Crit" System
*   If `Hero.totalStr` is 2x the `Quest.difficulty`, the hero performs a **"Crushing Blow"**.
    *   **Visual:** The text log shows this line in **BOLD RED**.
    *   **Reward:** Double XP.

---

## 4. UI Specifications (Phase 2)

### A. The Hero Detail Sheet (Modal)
When tapping a Hero in the Roster, open a `showModalBottomSheet`.
*   **Header:** Hero Portrait (Icon) + Name + Level.
*   **Paper Doll:** 4 distinct squares representing the slots (Weapon, Shield, Armor, Ring).
    *   *State:* If empty, show a faint icon. If equipped, show the Item Icon + Rarity Color Border.
*   **Stats Panel:** Show `STR`, `DEF`, `SPD`, `LUCK`.
    *   *UX Detail:* If an item is equipped, show the number in Green (e.g., "15 (+5)").
*   **Inventory Grid:** Bottom half of the sheet shows unequipped items in the "Bag".
    *   *Interaction:* Tapping an item in the bag checks if it fits the slot. If yes, **Equip** (swap with current).

### B. Visualizing Rarity
This is crucial for the "Beautiful UI."
*   Create a helper: `Color getRarityColor(ItemRarity rarity)`.
    *   Common: `#B0B0B0` (Grey)
    *   Rare: `#3B82F6` (Bright Blue)
    *   Epic: `#8B5CF6` (Purple)
    *   Legendary: `#F59E0B` (Gold) + **Glow Effect** (BoxShadow).

### C. The Shop (New Tab)
Add a "Merchant" tab to the bottom nav.
*   **Stock:** Generate 5 random items every 24 hours (or pay 1 gem to refresh).
*   **Sell:** Allow dragging items from Inventory to a "Sell Bin" to get Gold.

---

## 5. Implementation Roadmap (Phase 2)

1.  **Database Migration:** Update Hive adapters to include the new `Item` and updated `Hero` models. *Warning: This will wipe Phase 1 save data unless a migration script is written.*
2.  **The Factory:** Write the `LootFactory.dart` logic. Test it by printing 100 items to the console to ensure names and stats look right.
3.  **Inventory UI:** Build the Hero Detail Sheet. Just get items displaying first.
4.  **Equip Logic:** Implement the swap logic (Bag $\leftrightarrow$ Hero). Update total stats when this happens.
5.  **Combat Integration:** Hook the new stats into the `Quest` timer and result logic.
6.  **The Merchant:** Build the shop interface.

## 6. "Juice" Notes for the Team
*   **The "New Item" Badge:** When a hero returns with loot, put a small red dot on the "Roster" tab.
*   **The Legendary Sound:** If a Legendary item is generated, play a specific "Gong" or "Chime" sound (even if the app is in the background, send a high-priority notification).

**Deliverable:** A build where I can send a naked hero on a quest, he finds a "Rusty Sword", I equip it, and see his Attack Power go up from 5 to 7.