# 🎮 Typing Adventure

> A roguelike typing game that fuses the mechanics of **Bookworm Adventures**, **Z-Type**, **Vampire Survivors**, and **Slay The Spire**

---

## 📋 Quick Links

- [Overview](#-overview)
- [Core Gameplay](#-core-gameplay)
- [Game Systems](#-game-systems)
- [Progress Tracking](#-progress-tracking)
- [Project Structure](#-project-structure)

---

## 🎯 Overview

**Typing Adventure** is a unique roguelike where players **type predetermined words** to defeat waves of enemies in real-time combat. It combines strategic item management, dynamic boss encounters, and skill-based typing mechanics for an engaging and replayable experience.

### Game Pillars

| Pillar               | Inspiration                | Implementation                                                       |
| -------------------- | -------------------------- | -------------------------------------------------------------------- |
| **RPG Mechanics**    | Bookworm Adventures        | Permanent upgrades, relics, stat progression                         |
| **Real-time Combat** | Z-Type + Vampire Survivors | Type words to shoot; enemies spawn in waves around stationary player |
| **Progression**      | Slay The Spire             | Branching map, node system, shops, runs                              |
| **Item Synergies**   | Balatro                    | Items interact with each other for powerful combinations             |

---

## 🎮 Core Gameplay

### The Combat Loop

1. **Enemies Spawn** in waves from screen edges
2. **Type a Word** to attack the nearest enemy
3. **Press SPACEBAR** to "shoot" (execute the typed word)
4. **Accuracy Matters**: Incorrect typing = miss; correct typing = damage based on word value
5. **Defeat Waves** to reach the shop phase

### Wave & Round System

```
Round 1 ─┬─ Wave 1 (3 enemies)
         ├─ Wave 2 (4 enemies)
         ├─ Wave 3 (5 enemies)
         ├─ Wave 4 (6 enemies)
         ├─ Wave 5 (7 enemies)
         └─ SHOP → Buy items, words, upgrades
```

- **Each wave** increases enemy count
- **Each round** increases enemy HP/defense
- **Shop phases** occur after completing all waves in a round

### Accuracy & Damage System

- **Word Value**: Determined by length and difficulty
- **Perfect Accuracy**: Deals full damage
- **Misses**: Both player and enemy lose small amounts of HP
- **I-frames**: Brief invulnerability after taking damage (upgradeable)

---

## 🎲 Game Systems

### 🏠 Shop & Economy

#### Money Sources

| Source       | Reward                                             |
| ------------ | -------------------------------------------------- |
| Kill Enemy   | Coins                                              |
| Finish Wave  | Coins × (enemies killed in wave)                   |
| Finish Round | Bonus coins = `floor(round_difficulty × accuracy)` |
| _Example_    | _Round 5 difficulty with 90% accuracy = 4 coins_   |

#### Shop Items

- **Items**: Modify gameplay mechanics and synergize with each other
- **Words**: Expand word pool or unlock new mechanics
- **Word Upgrades**: Enhance specific words
- **Shop Rerolls**: Refresh available items

### 👹 Enemy Types

| Enemy           | Behavior                           | Strategy                   |
| --------------- | ---------------------------------- | -------------------------- |
| **Tank**        | High HP, slow movement             | Focus fire; prioritize     |
| **Charger**     | Rushes player, high damage         | React quickly to eliminate |
| **Archer**      | Shoots arrows with "dodge" prompts | Backspace and type "dodge" |
| **Dodger**      | Rare; can evade shots              | Relies on RNG              |
| _(More coming)_ | —                                  | —                          |

### 👑 Boss Encounters

Bosses grant **permanent run-wide boosts (relics)** when defeated.

#### Boss Debuffs

- **Capitalization**: Text randomly capitalized; must type exactly as shown
- **Nausea**: Visual distortion; reduced accuracy and random missed shots
- **Disabled Keys**: Certain letters become unusable (buy specific words to bypass)
- _(More debuffs coming)_

### 🎁 Item System

Items fundamentally change how you play (inspired by Balatro):

| Item                     | Effect                                                                    |
| ------------------------ | ------------------------------------------------------------------------- |
| **No Spacebar**          | Type continuously; constant damage stream (no SPACEBAR needed)            |
| **Gibberish Mode**       | Accept any character combination within time window; longer = more damage |
| **Word Length Modifier** | Increase/decrease word difficulty (affects damage scaling)                |
| **Word Storage (7x)**    | Accumulate 7 words; release for massive area explosion                    |
| **Synergy Items**        | Items interact with each other—some combo powerfully, others conflict     |

### 🎯 Bonus Attack System

- **5 Perfect Words**: Automatically damage all enemies within a radius
- **Relic Variant**: Trigger every 10 perfect words (less stringent, higher damage)
- **Strategic Benefit**: Rewards high-accuracy players

### ⏮️ Skip & Rewind Feature

#### Rewind (10 coins)

- Go back one round
- **Limited**: Once per 5 rounds
- **Unlock more**: With relics from boss defeats
- Use case: Didn't like shop offerings; want another chance

#### Skip (15 coins)

- Skip a boss fight and progress to next round
- **Do NOT receive** the boss's relic
- **Limited**: Once per 5 rounds
- Use case: Boss too difficult; want to push forward

---

## 🎪 Node System (Map)

The game will feature a **Slay The Spire-style map** where players navigate through different node types:

| Node            | Description                     |
| --------------- | ------------------------------- |
| **Unknown**     | Random encounter (TBD)          |
| **Enemy**       | Wave-based combat               |
| **Elite Enemy** | Harder waves; better rewards    |
| **Merchant**    | Shop phase (buying items/words) |
| **Treasure**    | Free reward                     |
| **Rest**        | Restore HP                      |
| **Boss**        | Boss encounter + relic reward   |

---

## 📊 Progress Tracking

### ✅ Completed

- [x] Core game concept and design documentation
- [x] Game architecture overview
- [x] Godot project setup
- [x] Basic scene structure (Game, Player, World, Slime)
- [x] Asset library (sprites, fonts, sounds, music)

### 🚧 In Progress

- [ ] **Player mechanics** (movement, typing input, shooting)
- [ ] **Enemy AI** (wave spawning, basic pathfinding)
- [ ] **Combat system** (word matching, accuracy calculation, damage)
- [ ] **UI/UX** (word display, health bars, score display)

### 📋 Coming Soon

- [ ] Wave and round progression system
- [ ] Shop system (item purchasing)
- [ ] Boss encounters and debuffs
- [ ] Relic system (permanent upgrades)
- [ ] Node/map system (Slay The Spire-style progression)
- [ ] Item synergy system
- [ ] Save/load system
- [ ] Audio integration (background music, sound effects)
- [ ] Tutorial/onboarding

### 🔮 Future/Experimental

- [ ] Additional enemy types
- [ ] Advanced boss mechanics
- [ ] Leaderboard system
- [ ] Difficulty modifiers
- [ ] Daily runs/challenges

---

## 📁 Project Structure

```
repo-for-da-proto/
├── Assets/
│   ├── fonts/              # Game fonts (PixelOperator8)
│   ├── music/              # Background music
│   ├── sounds/             # Sound effects (jump, coin, explosion, etc.)
│   └── sprites/            # Game sprites (characters, enemies, UI)
├── Scenes/                 # Godot scene files (.tscn)
│   ├── game.tscn          # Main game scene
│   ├── Player.tscn        # Player character
│   ├── world.tscn         # World/arena
│   ├── slime.tscn         # Slime enemy
│   ├── damage.tscn        # Damage effect
│   └── typing.tscn        # Typing UI
├── Script/                 # GDScript files (.gd)
│   ├── game.gd            # Game logic
│   ├── player.gd          # Player mechanics
│   ├── slime.gd           # Slime AI
│   ├── damage.gd          # Damage system
│   ├── timer.gd           # Timer utilities
│   └── typing.gd          # Typing system
├── project.godot          # Godot project config
└── README.md              # This file
```

---

## 🔧 Development Notes

### Balance (In Discussion)

- Wave count per round (currently: 5 waves)
- Coins per action
- Enemy scaling
- Item costs
- Shop appearance frequency

### Shop Style (In Discussion)

The game will feature a shop phase inspired by:

- **Dead Cells**: Simple merchant room with limited items
- **Slay The Spire**: Shop as a node on the map
- **Balatro**: Dense shops with item synergies

### Known Experimental Features

- Dodging mechanic for archer enemies
- Gibberish input mode
- Item synergy interactions

---

## 📝 License & Credits

- **Fonts**: PixelOperator8 (free font)
- **Assets**: Original or free-licensed
- **Inspirations**: Bookworm Adventures, Z-Type, Vampire Survivors, Slay The Spire, Balatro

---

_Last Updated: 2026_
