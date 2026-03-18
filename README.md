# Elden Baptist - Dark Fantasy RPG

A 2D top-down open-world RPG inspired by Elden Ring, built with Godot Engine 4.x.

## Game Overview

Play as **John the Baptist**, a mercenary with melee and magic combat styles, exploring a dark fantasy world corrupted by an ancient evil. Fight through multiple biomes, defeat powerful bosses, and uncover the truth behind the Shadow Citadel.

## How to Build & Run

### Prerequisites
- **Godot Engine 4.2+** (download from [godotengine.org](https://godotengine.org))

### Steps
1. Clone this repository
2. Open Godot Engine
3. Click **Import** and navigate to the project folder
4. Select the `project.godot` file
5. Click **Import & Edit**
6. Press **F5** or click the Play button to run

### Export
1. In Godot, go to **Project > Export**
2. Add a preset (Windows, Linux, macOS, Web)
3. Click **Export Project**
4. Choose a destination folder

## Controls

### Keyboard + Mouse
| Action | Key |
|--------|-----|
| Move | WASD |
| Light Attack | Left Mouse Button |
| Heavy Attack | Right Mouse Button |
| Dodge Roll | Space |
| Cast Spell | Q |
| Cycle Spell | R |
| Cycle Weapon | T |
| Interact | E |
| Use Item (Heal) | F |
| Inventory | I |
| Quest Log | J |
| Skill Tree | K |
| Map | M |
| Pause | Escape |

### Xbox Controller
| Action | Button |
|--------|--------|
| Move | Left Stick |
| Light Attack | X |
| Heavy Attack | Y |
| Dodge Roll | A |
| Interact | B |
| Cast Spell | LB |
| Cycle Spell | RB |
| Inventory | Back/Select |
| Quest Log | Start |
| Pause | Menu |

## Game Systems

### Combat
- **Light attacks** (fast, low stamina) chain into combos
- **Heavy attacks** (slow, high damage, more stamina)
- **Combo system**: Light > Light > Heavy for devastating finishers
- **Dodge roll** with i-frames (invulnerability during roll)
- **Stamina management** - attacks and dodges cost stamina

### Magic System
- Multiple spell types: Projectile, Area, Beam
- 7 unique spells from Holy Spark to Divine Wrath
- Mana management and cooldowns
- Cycle between equipped spells with R/RB

### Weapons
- 10 unique weapons across 6 types (sword, axe, dagger, hammer, greatsword, scythe)
- Each weapon has different damage, speed, and feel
- Find weapons from loot drops, shops, and quest rewards

### World Regions
1. **Ashen Wastes** - Starting area, ruins and dead trees
2. **Crimson Mire** - Poisonous swampland
3. **Frozen Peaks** - Ice-covered mountains
4. **Shadow Citadel** - The dark fortress (endgame)

### Bosses (Multi-Phase)
1. **Hollow Knight** (2 phases) - Ashen Wastes
2. **Bog Hydra** (3 phases) - Crimson Mire
3. **Storm Titan** (3 phases) - Frozen Peaks
4. **Dark Sovereign** (4 phases) - Shadow Citadel (Final Boss)

### Progression
- **Leveling**: Gain XP from kills, level up for stat increases and skill points
- **Skill Trees**: Melee tree (8 skills) + Magic tree (8 skills)
- **Equipment**: Weapons, armor, accessories, consumables
- **Loot**: 5 rarity tiers (Common, Uncommon, Rare, Epic, Legendary)

### Quests
- **6 Main Quests** forming a complete story arc
- **5 Side Quests** with unique objectives
- Quest tracking with objectives and rewards
- Auto-progression through the main questline

### NPCs
- Old Hermit (quest giver, lore)
- Weeping Ghost (side quest)
- Swamp Witch (story NPC)
- Doran the Smith (weapon/armor shop)
- Arcane Scholar (spell shop)
- Wandering Merchants (random events)

### Procedural Events
- Random ambushes, elite encounters, merchants, treasures
- Scale with player level and region
- Occur on a timer during gameplay

### New Game+
- Enemies scale +35% per NG+ cycle
- Player retains all gear, levels, and skills
- Bosses gain additional attack patterns
- Available after defeating the Dark Sovereign

### Save System
- 3 save slots
- Saves all progress: stats, inventory, quests, skills, position
- Save/Load from pause menu

## Project Structure

```
project.godot              # Godot project configuration
icon.svg                   # Game icon
scenes/
  menus/main_menu.tscn    # Title screen
  player/player.tscn      # Player character
  enemies/enemy.tscn      # Base enemy
  bosses/boss.tscn        # Boss template
  npcs/npc.tscn           # NPC template
  ui/game_ui.tscn         # Full HUD/UI overlay
  world/game_world.tscn   # Main game scene
  world/loot_pickup.tscn  # Collectible items
  effects/spell_projectile.tscn
  effects/aoe_effect.tscn
scripts/
  autoload/               # Singleton managers
    game_manager.gd       # Core game state, player stats
    save_manager.gd       # Save/load system
    quest_manager.gd      # Quest tracking
    event_manager.gd      # Procedural events
    audio_manager.gd      # Sound (placeholder)
    loot_table.gd         # Item database & loot generation
    tutorial_manager.gd   # Tutorial popups
    skill_manager.gd      # Skill trees
  player/
    player_controller.gd  # Movement, combat, dodge, magic
  enemies/
    enemy_base.gd         # AI: patrol, chase, attack, flee
  bosses/
    boss_base.gd          # Multi-phase boss system
  npcs/
    npc_base.gd           # Dialogue, quests, merchant
  ui/
    game_ui.gd            # HUD, inventory, quest log, skills
    main_menu.gd          # Title screen
  world/
    game_world.gd         # World manager, event spawning
    world_map.gd          # Procedural region generation
    enemy_spawner.gd      # Enemy population
    loot_pickup.gd        # Item collection
    region_trigger.gd     # Region transitions
  systems/
    spell_projectile.gd   # Spell behavior
    aoe_effect.gd         # Area effect visuals
```

## Gameplay Loop

1. **Awaken** in the Ashen Wastes
2. **Meet the Old Hermit** - receive your first quest
3. **Explore** the region, fight enemies, collect loot
4. **Level up** and invest in melee or magic skills
5. **Defeat the Hollow Knight** (first boss)
6. **Progress** through Crimson Mire, Frozen Peaks
7. **Face increasingly difficult bosses** with new phases
8. **Reach the Shadow Citadel** and defeat the Dark Sovereign
9. **Start New Game+** with stronger enemies and your full build

## Technical Notes

- Built for **Godot 4.2+** with GL Compatibility renderer
- All assets are procedural/placeholder (polygons and colors)
- No external dependencies required
- Pixel-perfect rendering with nearest-neighbor filtering
- Smooth camera following with position smoothing
