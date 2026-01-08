# Guilds of Antiquity

A UI-based Idle RPG / Management game where you build a guild, conquer the region, and advance through history.

## 🎮 Game Overview

**Guilds of Antiquity** is a unique blend of idle RPG and management simulation. Unlike typical idle games where numbers just go up, this game introduces a "Prestige" mechanic that fundamentally changes the game world. You play through three distinct Eras, each with its own theme and mechanics, building a legacy that spans centuries.

## ✨ Key Features

### 🕰️ The Three Eras
Progress through history, with each Era offering a new challenge and aesthetic:
*   **Era 1: The Age of Iron (Warrior)** - Focus on brute force, conquest, and expansion.
*   **Era 2: The Age of Shadows (Thief)** - Focus on infiltration, heists, and managing "Heat".
*   **Era 3: The Age of Arcanum (Mage)** - Focus on stabilizing chaotic magic and channeling mana.

### 🦸 Hero Progression
*   **Recruit & Customize**: Create your unique hero at the start of each Era.
*   **Stats & Leveling**: Manage **Strength**, **Speed**, **HP**, and **Luck**. Earn XP from quests and spend upgrade points to build your perfect champion.
*   **Equipment**: Equip your hero with weapons, armor, and accessories to boost their power.
*   **Inventory Management**: Manage your inventory with a slot limit. Sell unwanted gear for gold or purchase **Bag Upgrades** from the shop to carry more loot.
*   **Procedural Loot**: Find thousands of unique items with randomized names, rarities (Common, Rare, Epic, Legendary), and stat bonuses.

### 🏰 Guild Management
Upgrade your base of operations to provide global bonuses to your hero:
*   **The Hall (Business)**: Manage a specialized business to fund your guild.
    *   **Manual Production**: Choose your own work hours! Select a production duration (1-24 hours) and claim your rewards when the work is done. Longer shifts yield massive returns.
    *   **Farm**: Produces **Gold** and **Items**. Upgrading **Quality** increases the chance of finding Rare, Epic, and Legendary gear.
    *   **Mine**: Produces massive amounts of **Gold**. Upgrading **Quality** significantly boosts the gold output multiplier.
    *   **Lodge**: Scouts for **Bounty Quests**. Upgrading **Quality** finds more dangerous bounties with better rewards.
    *   **Upgrades**: Invest in **Quantity** (more stuff) and **Quality** (better stuff) to maximize your business's efficiency.
*   **Tavern**: The hub for information. Visit to hear rumors and discover new **Side Quests** from patrons. The more famous you become, the more often patrons will have jobs for you.
*   **Vault**: The most critical building—allows you to save items to carry over into the next Era.

### 🗺️ Quests & Exploration
*   **Map Progression**: Explore a dynamic map, unlocking new nodes and regions as you complete quests.
*   **Smart Difficulty**: Quests display a **Recommended Level**. Heroes meeting this requirement gain a significant combat advantage, ensuring fair progression.
*   **Dynamic Speed**: Your hero's **Speed** stat drastically reduces quest duration using a non-linear scaling formula, making speed builds viable for rapid farming.
*   **Epic Main Questline**: Engage in a challenging main story with increasing difficulty and duration, culminating in massive siege battles.
*   **Quest Chains**: Experience multi-part side stories (e.g., "The Lost Heir", "The Bandit King") that unlock sequentially and offer deep lore.
*   **Replayability**: Mastered a quest? Replay completed side quests to farm Gold and XP (at a reduced rate) to prepare for the next big challenge.
*   **Unique Rewards**: Complete quest chains to earn one-of-a-kind **Legendary Items** that can't be found anywhere else.
*   **Legendary Hints**: Some legendary quests are hidden. Purchase **Mysterious Shards** from the Merchant to uncover hints. Once enough hints are gathered, the quest location is revealed.

### 🏛️ The Museum & Artifacts
*   **Persistent Collection**: The **Museum** exists outside of time, tracking every unique item you've ever found across all your playthroughs.
*   **Artifacts**: Collect powerful, rule-breaking Artifacts (e.g., The Greed Coin, The Chrono-Dial) that provide unique passive bonuses.
*   **Legacy**: Use the **Vault** to preserve your most powerful legendary items when you prestige, giving your new hero a head start in the next age.

## 🛠️ Technical Details

Built with **Flutter**, this project demonstrates a scalable architecture for complex state-heavy applications.

*   **State Management**: `flutter_riverpod` for reactive state and dependency injection.
*   **Local Database**: `hive` for fast, offline-first data persistence (NoSQL).
*   **Audio**: Custom audio service for immersive soundscapes and haptic feedback.
*   **Architecture**: Service-based architecture separating UI, Business Logic, and Data Models.

## 🚀 Getting Started

1.  **Prerequisites**: Ensure you have Flutter installed (`flutter doctor`).
2.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/guilds-of-antiquity.git
    ```
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the app**:
    ```bash
    flutter run
    ```

---

*Concept & Design by Parker Allen*

## 🎨 Asset Requirements

The game requires specific assets for the Museum and Quest items. These should be placed in `assets/images/items/quest/` and `assets/images/items/legendary/`.

### Quest Items (Trophies)
Location: `assets/images/items/quest/`
*   `whispering_stone.png`: A glowing blue stone fragment.
*   `corrupted_root.png`: A twisted, dark root.
*   `bandit_badge.png`: A crude metal badge.
*   `frozen_heart.png`: A blue, icy heart.
*   `void_essence.png`: A swirling purple orb.
*   `ash_king_head.png`: A dragon skull with smoke.
*   `thrall_helmet.png`: A dark iron helmet.
*   `crown_eclipse.png`: A black crown with a solar eclipse motif.
*   `shard_reality.png`: A jagged, glitchy-looking shard.

### Legendary Items
Location: `assets/images/items/legendary/`
*   `abdication_ring.png`: A gold ring with a scratched-out crest.
*   `tear_bride.png`: A blue gemstone shaped like a teardrop.
*   `thorne_dagger.png`: A jagged, rusty dagger.
*   `ring_legendary.png`: A generic legendary ring (placeholder).
*   `nebulas_grasp.png`: A staff swirling with nebula colors (fix for typoed filename).
*   (Plus existing legendary weapon assets)

### Generic Equipment Assets
Location: `assets/images/items/generic/` (Create this folder structure)

#### Main Hand
*   **Swords**: `iron_sword.png`, `steel_longsword.png`, `golden_gladius.png`
*   **Axes**: `battle_axe.png`, `double_headed_axe.png`, `rusty_hatchet.png`
*   **Daggers**: `iron_dagger.png`, `curved_dagger.png`, `ritual_knife.png`
*   **Staves**: `oak_staff.png`, `gem_topped_staff.png`, `twisted_staff.png`

#### Off Hand
*   **Shields**: `wooden_buckler.png`, `iron_heater_shield.png`, `tower_shield.png`
*   **Magic**: `orb_of_fire.png`, `ancient_tome.png`

#### Armor
*   **Heavy**: `iron_plate_armor.png`, `steel_chestplate.png`
*   **Light**: `leather_tunic.png`, `studded_vest.png`
*   **Robes**: `silk_robe.png`, `hooded_cloak.png`
*   **Helmets**: `iron_helm.png`, `knights_visor.png`

#### Accessories
*   **Rings**: `gold_ring.png`, `silver_band.png`, `ruby_ring.png`
*   **Amulets**: `gold_necklace.png`, `bone_charm.png`

### Character & Tavern Assets
Location: `assets/images/npcs/` (Create this folder structure)

#### Tavern Patrons
*   `bartender.png`: A friendly but tough bartender cleaning a glass.
*   `old_mercenary.png`: A scarred veteran in worn armor.
*   `mysterious_traveler.png`: A figure in a hooded cloak, face hidden.
*   `merchant_npc.png`: A wealthy merchant with a coin purse.

**Note on Variations:**
You can add multiple versions of any character or item image by adding a number suffix. The game will randomly choose one!
*   Example: `female_thief.png`, `female_thief_2.png`, `female_thief_3.png`
*   Example: `bartender.png`, `bartender_2.png`

#### Hero Portraits
Location: `assets/images/heroes/`
*   **Warrior**: `male_warrior.png`, `female_warrior.png`
*   **Ranger**: `male_ranger.png`, `female_ranger.png`
*   **Mage**: `male_mage.png`, `female_mage.png`
*   **Thief**: `male_thief.png`, `female_thief.png`