# Elden Baptist - Dark Fantasy RPG

A 2D top-down open-world RPG built in **Godot 4.2+**, inspired by Elden Ring's dark fantasy setting.

## How to Run
1. Clone/download this repository
2. Open **Godot 4.2+** (or later)
3. Import the project by selecting the `project.godot` file
4. Press **F5** to run

## Key Features

### Combat System
- **Melee**: Light attacks (LClick/X), Heavy attacks (RClick/Y), 3-hit combos
- **Magic**: 7 spells (Holy Spark, Flame Wave, Ice Lance, Lightning Bolt, Dark Nova, Divine Wrath, Ancient Staff)
- **Dodge Roll**: Space/A with i-frames and stamina cost
- **Weapons**: Multiple melee weapons (swords, axes, daggers, maces) with unique stats

### Enemy AI & Bosses
- **11 enemy types** with unique shapes, colors, and behaviors
- **Spawn grace period**: Enemies don't attack for 3-6 seconds after spawning
- **FSM AI**: idle, patrol, chase, attack, hurt, flee states
- **4 multi-phase bosses**: Hollow Knight (2 phases), Bog Hydra (3), Storm Titan (3), Dark Sovereign (4)
- **6 boss attack patterns**: slash, slam, charge, AoE, summon minions, rapid slash

### Open World
- **4 distinct biomes**: Ashen Wastes, Crimson Mire, Frozen Peaks, Shadow Citadel
- **Procedural decorations**: biome-specific trees, rocks, mushrooms, crystals, pillars
- **Ground texture patches** for visual variety
- **Hidden secret areas** with rare loot
- **Region transitions** with name display and music changes
- **Random events**: ambushes, roaming elites, wandering merchants, treasure

### RPG Progression
- **Leveling**: XP-based with stat growth
- **Skill Trees**: 8 melee skills + 8 magic skills with prerequisites
- **Inventory**: 40 slots, equipment system, 5 rarity tiers
- **Loot Table**: ~30 items with weighted rarity drops

### NPC Systems
- **5 unique NPCs** with distinct visual appearances (Hermit, Ghost, Blacksmith, Scholar, Witch)
- **Dialogue system** with multi-line conversations
- **Quest system**: 6 main quests + 5 side quests
- **Merchant shops** with buyable weapons, spells, and potions

### Audio System (Procedural)
- **30+ sound effects** generated procedurally (sword swings, impacts, spells, pickups, menus, etc.)
- **6 procedural music tracks** (one per biome + menu + boss fight)
- **Volume controls**: Master, Music, SFX sliders in Settings menu
- All audio generated at runtime using `AudioStreamWAV` - no external audio files needed

### UI & Menus
- **Main Menu**: New Game, Continue, New Game+, Controls, Settings, Quit
- **Controls Panel**: Full keyboard+mouse AND Xbox controller bindings displayed
- **Settings Panel**: Master/Music/SFX volume sliders, Fullscreen toggle, VSync toggle
- **In-Game HUD**: HP, Stamina, Mana, XP bars, level, gold, equipped weapon/spell
- **Pause Menu**: Resume, Save, Load, Controls, Settings, Quit
- **Inventory, Quest Log, Skill Tree, Shop, World Map** panels
- **Death Screen** with respawn option

### Tutorial System
- **Guided intro sequence**: Welcome, Movement, and Controls tutorials shown at game start
- **Contextual tutorials**: Combat, Dodge, Magic, Interact, Inventory, Quests, Skills, Boss
- Tutorials auto-dismiss after 8 seconds or on [E] press
- Enemies have grace period during tutorial

### New Game+
- +35% enemy scaling per cycle
- Retained gear, levels, and skills
- New boss attack patterns in NG+
- Bosses gain speed each cycle

### Controls

| Action | Keyboard | Xbox Controller |
|--------|----------|-----------------|
| Move | W/A/S/D | Left Stick |
| Light Attack | Left Click | X |
| Heavy Attack | Right Click | Y |
| Dodge Roll | Space | A |
| Cast Spell | Q | LB |
| Interact | E | B |
| Cycle Spell | R | RB |
| Cycle Weapon | T | - |
| Use Item | F | - |
| Inventory | I | Back |
| Quest Log | J | Select |
| Skill Tree | K | - |
| World Map | M | - |
| Pause | ESC | Start |

### Save System
- 3 save slots with full game state serialization
- Displays level, region, play time, NG+ cycle per slot

## Project Structure
```
project.godot          # Engine config, input mappings, autoloads
scripts/
  autoload/            # 8 singletons (GameManager, SaveManager, etc.)
  player/              # Player controller with movement, combat, magic
  enemies/             # Enemy AI with distinct visuals per type
  bosses/              # Multi-phase boss system
  npcs/                # NPC dialogue, quests, merchants
  systems/             # Spell projectiles, AoE effects
  ui/                  # Game UI, main menu
  world/               # World generation, enemy spawner, region triggers, loot
scenes/                # .tscn scene files for all entities
```

## Technical Details
- **21 GDScript files**, **10 scene files**, ~5500+ lines of code
- All visuals are procedural Polygon2D shapes - no external art assets required
- All audio is procedurally generated - no external sound files required
- Runs on Godot 4.2+ with GL Compatibility renderer
