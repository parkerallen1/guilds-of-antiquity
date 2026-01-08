# Hall Refactor Walkthrough

## Overview
The Hall functionality has been completely refactored to support a manual production flow with customizable duration and meaningful rewards. The "Speed" upgrade has been replaced with "Quality", and rewards now scale with both Quantity (Amount Level) and Quality (Quality Level).

## Key Changes

### 1. Manual Production Flow
- **Select Duration**: Users can now choose a production duration (1 to 24 hours) using a slider.
- **Start Production**: Initiates the production process.
- **Wait**: A progress bar shows the remaining time.
- **Claim Rewards**: Once finished, the user must manually claim the rewards. Auto-collection has been removed.

### 2. Business Logic Updates
- **Mine**: Produces Gold.
  - Formula: `300 * DurationHours * Quantity * (1 + 0.2 * Quality)`
- **Farm**: Produces Gold and Items.
  - Gold: `100 * DurationHours * Quantity`
  - Items: `ceil(DurationHours * 0.5 * Quantity)`
  - **Quality Upgrade**: Increases the chance of finding higher rarity items (Rare, Epic, Legendary).
- **Lodge**: Discovers Quests.
  - Quests: `ceil(DurationHours * 0.25 * Quantity)`
  - **Quality Upgrade**: Increases the difficulty and rewards of the discovered quests.
  - **Procedural Quests**: The Lodge now generates "Bounty" quests with specific targets and locations. These quests have a chance to drop special items.

### 3. New Factories
- **LootFactory**: Updated to accept a `rarityBonus` parameter, allowing Quality upgrades to influence item drops.
- **QuestFactory**: Created to generate procedural "Bounty" quests with dynamic titles and rewards.

### 4. UI Updates
- **BusinessDashboardView**: Completely redesigned to handle the Idle, Producing, and Finished states.
- **Upgrades**: "Production Speed" replaced with "Quality".

## Verification
1.  **Navigate to the Hall**.
2.  **Select a Business** (e.g., Farm, Mine, or Lodge).
3.  **Select a Duration** (e.g., 1 hour) and click **Start Production**.
4.  **Wait** (or use a debug tool to fast-forward time if available, or just wait for a short duration test).
5.  **Claim Rewards** when the timer finishes.
6.  **Verify Rewards**:
    - **Mine**: Check Gold increase.
    - **Farm**: Check Gold and Inventory for new items.
    - **Lodge**: Check "Side Quests" (or map) for new "Bounty" quests.
