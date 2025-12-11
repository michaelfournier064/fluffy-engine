# 450 Fishing Game - Design Documentation

## Table of Contents
1. [Class Diagram and Descriptions](#class-diagram-and-descriptions)
2. [Process Flow Chart](#process-flow-chart)

---

## Class Diagram and Descriptions

### Class Identification

The fishing game is built using the following core classes:

#### **Core System Classes (Autoloaded Singletons)**
1. **GameState** - Global game state manager
2. **DatabaseManager** - SQLite database handler
3. **ShopUI** - Shop interface and commerce system

#### **Gameplay Classes**
4. **Player** - Player character controller
5. **FishingSystem** - Fishing mechanics and minigame
6. **FishingUI** - Fishing interface display

#### **World Classes**
7. **WaterArea** - Defines fishable water zones

#### **Pet Classes (Inheritance Hierarchy)**
8. **Octopet** - Ocean-themed pet companion
9. **Pengpet** - Penguin-themed pet companion

---

### Class Details

---

#### 1. GameState (extends Node)
**Purpose:** Centralized management of all game state data and player progression.

**Attributes:**
- `current_save_id: int` - ID of currently loaded save file
- `player_name: String` - Name of the player character
- `current_scene: String` - Current game scene path
- `player_level: int` - Player's experience level
- `player_experience: int` - Current experience points
- `player_gold: int` - Player's currency
- `fish_caught: int` - Total number of fish caught
- `total_playtime: int` - Total time played in seconds
- `player_position: Vector2` - Player's world position
- `legendary_fish_chance_bonus: int` - Upgrade bonus for legendary fish (%)
- `owned_pets: Array[String]` - List of purchased pet names
- `equipped_pet: String` - Currently active pet (empty if none)

**Methods:**
- `load_game_state(save_data: Dictionary) -> void` - Loads game state from save data
- `save_game_state() -> void` - Saves current state to database
- `create_new_game(save_name: String, p_name: String) -> void` - Initializes new game
- `add_experience(amount: int) -> void` - Adds XP and checks for level up
- `add_gold(amount: int) -> void` - Adds currency to player
- `increment_fish_caught() -> void` - Increments fish counter
- `check_level_up() -> void` - Checks and processes level ups
- `reset_game_state() -> void` - Resets all state variables

**Signals:**
- `game_saved()` - Emitted when game is saved
- `game_loaded()` - Emitted when game is loaded

**Design Justification:**
- Autoloaded as singleton for global access from any scene
- Centralizes state management to avoid data inconsistency
- Acts as single source of truth for player data
- Facilitates save/load system integration

---

#### 2. DatabaseManager (extends Node)
**Purpose:** Manages all persistent data storage using SQLite database.

**Attributes:**
- `db: SQLite` - SQLite database connection object
- `db_name: String` - Path to database file ("user://game_database.db")

**Methods:**
- `initialize_database() -> void` - Creates database and tables
- `create_tables() -> void` - Sets up all database tables
- `create_save(save_name: String, player_name: String) -> int` - Creates new save
- `update_save(save_id: int, save_data: Dictionary) -> bool` - Updates save data
- `load_save(save_id: int) -> Dictionary` - Loads save by ID
- `get_all_saves() -> Array` - Returns all available saves
- `delete_save(save_id: int) -> void` - Removes a save
- `add_fish_to_collection(save_id: int, fish_data: Dictionary) -> void` - Adds caught fish
- `get_fish_collection(save_id: int) -> Array` - Gets all caught fish
- `delete_fish_from_collection(collection_id: int) -> void` - Removes fish (for selling)
- `save_settings(settings_data: Dictionary) -> void` - Saves game settings
- `load_settings() -> Dictionary` - Loads game settings
- `close_database() -> void` - Closes database connection

**Signals:**
- `database_ready()` - Emitted when database is initialized
- `save_completed(save_id: int)` - Emitted after save creation
- `save_loaded(save_data: Dictionary)` - Emitted after save load
- `database_error(error_message: String)` - Emitted on database errors

**Database Tables:**
- `game_saves` - Player save files
- `player_inventory` - Item inventory (future expansion)
- `fish_collection` - All caught fish records
- `quests` - Quest data (future expansion)
- `game_settings` - Settings and preferences

**Design Justification:**
- Autoloaded singleton for consistent database access
- Separates data persistence from game logic
- Uses SQLite for reliable local storage
- Foreign key constraints ensure data integrity
- Extensible design allows for future features

---

#### 3. ShopUI (extends CanvasLayer)
**Purpose:** Manages the in-game shop interface, item purchasing, and pet management.

**Attributes:**
- `shop_screen: Control` - Main shop UI container
- `is_open: bool` - Shop visibility state
- `money_label: Label` - Displays current gold
- `current_section: String` - Active tab ("sell", "upgrades", "pets")
- `sell_fish_container: VBoxContainer` - Fish selling UI
- `upgrades_container: VBoxContainer` - Upgrades UI
- `pets_container: VBoxContainer` - Pets UI
- `spawned_pet: Node` - Reference to active pet in world
- `shop_upgrades: Array[Dictionary]` - Available upgrades
- `shop_pets: Array[Dictionary]` - Available pets

**Methods:**
- `setup_shop() -> void` - Creates UI elements
- `create_shop_item(item: Dictionary, is_pet: bool) -> Panel` - Creates item UI
- `create_tab_button(tab_name: String, parent: HBoxContainer) -> void` - Creates tab
- `switch_section(section: String) -> void` - Changes active tab
- `update_money_display() -> void` - Updates gold display
- `buy_item(item: Dictionary) -> void` - Handles item purchases
- `purchase_pet(pet: Dictionary) -> void` - Adds pet to collection
- `equip_pet(pet_name: String) -> void` - Spawns pet in world
- `unequip_pet(pet_name: String) -> void` - Removes pet from world
- `refresh_pets_ui() -> void` - Updates pet UI states
- `spawn_pet(pet_name: String) -> void` - Instantiates pet scene
- `apply_upgrade(upgrade: Dictionary) -> void` - Applies upgrade effects
- `toggle_shop() -> void` - Opens/closes shop
- `load_fish_inventory() -> void` - Loads caught fish for selling
- `create_fish_item(fish: Dictionary) -> Panel` - Creates fish sell UI
- `sell_fish(fish: Dictionary) -> void` - Sells fish for gold

**Design Justification:**
- CanvasLayer ensures UI renders above game world
- Process mode ALWAYS allows shop to function when game is paused
- Dynamic button states (Buy/Equip/Unequip) provide clear feedback
- Tabbed interface organizes different shop functions
- Directly integrates with GameState for data consistency
- Spawns pets dynamically by loading scenes

---

#### 4. Player (extends CharacterBody2D)
**Purpose:** Controls player character movement, animations, and fishing interactions.

**Attributes:**
- `speed: float` - Movement speed (200.0)
- `animated_sprite: AnimatedSprite2D` - Character animations
- `fishing_system: Node` - Reference to FishingSystem
- `fishing_ui: CanvasLayer` - Reference to FishingUI
- `is_fishing: bool` - Current fishing state
- `facing_direction: int` - Horizontal facing (1=right, -1=left)
- `last_vertical_direction: int` - Vertical direction for animations
- `in_water_area: bool` - Whether player is in fishable water

**Methods:**
- `_physics_process(delta: float) -> void` - Handles movement and animations
- `handle_movement() -> void` - Processes WASD input
- `update_animation() -> void` - Switches animations based on state
- `_input(event: InputEvent) -> void` - Handles fishing and minigame input
- `toggle_fishing() -> void` - Starts/stops fishing
- `_on_water_area_entered(area: Area2D) -> void` - Enables fishing
- `_on_water_area_exited(area: Area2D) -> void` - Disables fishing
- `_on_fishing_ended() -> void` - Resets player state after fishing
- `_on_fish_caught(fish_data: Dictionary) -> void` - Handles catch event
- `_on_fish_escaped() -> void` - Handles escape event

**Animations:**
- `walk_up` - Walking upward
- `walk_down` - Walking downward
- `walk_side` - Walking horizontally (sprite flips for direction)
- `fishing` - Fishing idle animation

**Design Justification:**
- CharacterBody2D provides built-in physics and collision
- Separates movement logic from fishing logic
- Signal-based communication with FishingSystem avoids tight coupling
- Input handling prioritizes minigame input during fishing
- Animation system uses single "side" animation with flip for efficiency
- Left-click cancel provides intuitive exit from fishing

---

#### 5. FishingSystem (extends Node)
**Purpose:** Core fishing mechanics including bite timing, minigame, and fish generation.

**Attributes:**
- `cast_range: float` - Maximum fishing distance
- `bite_time_min: float` - Minimum wait for fish bite (2.0s)
- `bite_time_max: float` - Maximum wait for fish bite (8.0s)
- `catch_window: float` - Time to press space when fish bites (1.5s)
- `minigame_sequence_length: int` - Number of keys in minigame (5)
- `minigame_time_limit: float` - Time to complete minigame (5.0s)
- `fish_types: Array[Dictionary]` - Database of fish species
- `is_fishing: bool` - Active fishing session
- `waiting_for_bite: bool` - Waiting for fish to bite
- `fish_hooked_active: bool` - Fish has bitten, ready to catch
- `current_fish: Dictionary` - Currently hooked fish data
- `minigame_active: bool` - Minigame in progress
- `key_sequence: Array` - Random key sequence for minigame
- `current_key_index: int` - Progress in key sequence
- `bite_timer: Timer` - Countdown to fish bite
- `catch_timer: Timer` - Countdown for catch window
- `minigame_timer: Timer` - Countdown for minigame completion

**Methods:**
- `setup_timers() -> void` - Initializes timer nodes
- `start_fishing() -> bool` - Begins fishing session
- `end_fishing() -> void` - Ends fishing session
- `stop_fishing() -> void` - Internal cleanup of all fishing states
- `attempt_catch() -> bool` - Starts minigame when fish bites
- `start_minigame() -> void` - Generates and starts key sequence
- `check_key_input(action: String) -> bool` - Validates minigame input
- `complete_minigame_success() -> void` - Fish caught successfully
- `fail_minigame() -> void` - Fish escapes
- `generate_fish_data() -> Dictionary` - Creates random fish with stats
- `select_random_fish() -> Dictionary` - Selects fish based on rarity
- `get_fish_catalog() -> Array[Dictionary]` - Returns all fish types
- `_on_bite_timer_timeout() -> void` - Fish bites
- `_on_catch_timer_timeout() -> void` - Missed catch window
- `_on_minigame_timeout() -> void` - Minigame time expired

**Signals:**
- `fishing_started()` - Fishing session begins
- `fish_hooked(fish_data: Dictionary)` - Fish bites
- `fish_caught(fish_data: Dictionary)` - Fish successfully caught
- `fish_escaped()` - Fish gets away
- `fishing_ended()` - Fishing session ends
- `minigame_started(sequence: Array)` - Minigame begins
- `minigame_key_pressed(correct: bool, progress: int, total: int)` - Key pressed
- `minigame_failed()` - Minigame failed

**Fish Rarity System:**
- **Common (60%)**: Bass, Trout
- **Uncommon (25%)**: Snapper
- **Rare (13%)**: Tuna
- **Legendary (2% + bonuses)**: Goldfish

**Design Justification:**
- Node-based design allows attachment to any scene
- Signal-driven architecture decouples fishing logic from UI
- Timer-based events create suspense and challenge
- Minigame adds skill-based gameplay element
- Rarity system creates progression incentive
- Legendary bonuses from shop create meaningful upgrades
- State machine pattern (is_fishing, waiting_for_bite, fish_hooked_active, minigame_active) prevents invalid transitions
- Random fish generation creates variety in catches

---

#### 6. FishingUI (extends CanvasLayer)
**Purpose:** Displays fishing status, prompts, and minigame interface.

**Attributes:**
- `fishing_system: Node` - Reference to FishingSystem
- `status_label: Label` - Shows current fishing state
- `minigame_container: Control` - Minigame UI container
- `key_display: Label` - Shows required key sequence
- `progress_label: Label` - Shows minigame progress

**Methods:**
- `set_fishing_system(system: Node) -> void` - Connects to fishing system
- `_on_fishing_started() -> void` - Shows "Waiting for bite..." message
- `_on_fish_hooked(fish_data: Dictionary) -> void` - Shows "Press SPACE!" prompt
- `_on_minigame_started(sequence: Array) -> void` - Displays key sequence
- `_on_minigame_key_pressed(correct: bool, progress: int, total: int) -> void` - Updates progress
- `_on_fish_caught(fish_data: Dictionary) -> void` - Shows catch screen with fish details
- `_on_fish_escaped() -> void` - Shows "Fish escaped!" message
- `_on_fishing_ended() -> void` - Hides all fishing UI
- `show_catch_screen(fish_data: Dictionary) -> void` - Displays "You Caught!" screen
- `hide_ui() -> void` - Clears all UI elements

**Design Justification:**
- CanvasLayer renders UI above game world
- Signal-based updates ensure UI stays synchronized with game state
- Separate from FishingSystem for modularity
- "You Caught!" screens provide satisfying feedback
- Visual feedback for each minigame key press

---

#### 7. WaterArea (extends Area2D)
**Purpose:** Defines zones where fishing is allowed and provides water visual effects.

**Attributes:**
- `water_sprite: ColorRect` - Visual water representation
- `time: float` - Animation time tracker
- `base_color: Color` - Base water color (0.15, 0.35, 0.65, 0.75)
- `highlight_color: Color` - Highlight for depth effect (0.3, 0.55, 0.9, 0.8)

**Methods:**
- `_ready() -> void` - Sets collision layers
- `_process(delta: float) -> void` - Animates water effects

**Visual Effects:**
- Multi-frequency wave patterns
- Shimmer and sparkle effects
- Color transitions for depth
- Gentle position offset for movement

**Design Justification:**
- Area2D for collision detection with player
- Collision layer 2 dedicated to water zones
- Visual feedback shows fishable areas
- Animated effects make water feel alive
- Separate visual effects from gameplay logic

---

#### 8. Octopet (extends CharacterBody2D)
**Purpose:** Pet companion that follows the player with ocean theme.

**Attributes:**
- `follow_speed: float` - Movement speed (100.0)
- `follow_distance: float` - Distance to maintain from player (50.0)
- `player: CharacterBody2D` - Reference to player character
- `animated_sprite: AnimatedSprite2D` - Pet animations

**Methods:**
- `_ready() -> void` - Finds player and initializes
- `find_player() -> void` - Locates player using "player" group
- `_physics_process(delta: float) -> void` - Follows player with animations

**Animation Logic:**
- Follows player when too far away
- Stops and idles when close enough
- Flips horizontally based on movement direction
- Plays "walk" animation when moving

**Design Justification:**
- CharacterBody2D for physics-based movement
- Group-based player finding avoids hard references
- call_deferred() prevents initialization timing issues
- Scale (0.3) makes pet appropriately sized

---

#### 9. Pengpet (extends CharacterBody2D)
**Purpose:** Pet companion that follows the player with penguin theme.

**Attributes:**
- `follow_speed: float` - Movement speed (100.0)
- `follow_distance: float` - Distance to maintain from player (50.0)
- `player: CharacterBody2D` - Reference to player character
- `animated_sprite: AnimatedSprite2D` - Pet animations

**Methods:**
- `_ready() -> void` - Finds player and initializes
- `find_player() -> void` - Locates player using "player" group
- `_physics_process(delta: float) -> void` - Follows player with animations

**Animation Logic:**
- Identical behavior to Octopet
- Different sprite and scale (0.23) for size matching

**Design Justification:**
- Reuses proven Octopet architecture for consistency
- Different scale compensates for taller sprite dimensions
- Smaller collision radius (8.0) for more accurate hitbox

---

### Class Relationships

#### Inheritance Hierarchy
```
Node
├── GameState (Autoload Singleton)
├── DatabaseManager (Autoload Singleton)
├── FishingSystem
└── WaterArea (extends Area2D)

CanvasLayer
├── ShopUI (Autoload Singleton)
└── FishingUI

CharacterBody2D
├── Player
├── Octopet
└── Pengpet
```

#### Associations and Dependencies

**GameState:**
- Used by: `ShopUI`, `FishingSystem`, `Player`, `DatabaseManager`
- Relationship: Global state access (singleton pattern)

**DatabaseManager:**
- Used by: `GameState`, `ShopUI`, `FishingSystem`
- Relationship: Data persistence service (singleton pattern)

**ShopUI:**
- Uses: `GameState`, `DatabaseManager`
- Spawns: `Octopet`, `Pengpet`
- Relationship: Manages pet lifecycle

**Player:**
- Uses: `FishingSystem`, `FishingUI`
- Detected by: `WaterArea`, `Octopet`, `Pengpet`
- Relationship: Controls fishing flow, provides follow target for pets

**FishingSystem:**
- Used by: `Player`
- Communicates with: `FishingUI`, `GameState`, `DatabaseManager`
- Relationship: Core fishing logic provider

**FishingUI:**
- Uses: `FishingSystem`
- Relationship: Visual representation of fishing state

**WaterArea:**
- Interacts with: `Player`
- Relationship: Triggers fishing availability

**Octopet & Pengpet:**
- Follows: `Player`
- Spawned by: `ShopUI`
- Relationship: Autonomous companion entities

#### Communication Patterns

**Signal-Based Communication:**
- `FishingSystem` → `FishingUI`: fishing state changes
- `FishingSystem` → `Player`: fishing completion
- `DatabaseManager` → `GameState`: save/load events
- `WaterArea` → `Player`: area entry/exit

**Direct Method Calls:**
- `Player` → `FishingSystem`: start_fishing(), attempt_catch(), check_key_input()
- `ShopUI` → `GameState`: property access for gold, pets, upgrades
- `FishingSystem` → `DatabaseManager`: add_fish_to_collection()
- `ShopUI` → `DatabaseManager`: get_fish_collection(), delete_fish_from_collection()

**Singleton Access:**
- All classes can access `GameState`, `DatabaseManager`, `ShopUI` globally

---

### Design Justifications

#### 1. Singleton Pattern for Core Systems
**Why:** GameState, DatabaseManager, and ShopUI are autoloaded singletons.
**Justification:**
- Ensures single source of truth for game state
- Provides global access without passing references
- Persists across scene changes
- Simplifies save/load system integration

#### 2. Signal-Driven Architecture
**Why:** Heavy use of signals for inter-class communication.
**Justification:**
- Decouples classes, improving maintainability
- Allows multiple listeners without modifying emitter
- Prevents circular dependencies
- Makes code more testable

#### 3. Separation of Logic and Presentation
**Why:** FishingSystem (logic) separate from FishingUI (presentation).
**Justification:**
- Allows logic to function without UI (testing, headless mode)
- UI can be redesigned without touching game logic
- Multiple UIs could represent same system
- Follows single responsibility principle

#### 4. Component-Based Pet System
**Why:** Pets are separate nodes spawned/destroyed dynamically.
**Justification:**
- Pets only exist when equipped, saving resources
- Easy to add new pet types without modifying shop
- Pets can be independently updated
- Supports future multi-pet system

#### 5. Timer-Based Fishing Mechanics
**Why:** Timers for bite, catch window, and minigame.
**Justification:**
- Creates suspense and challenge
- Easy to balance by adjusting timer values
- Non-blocking, allows smooth gameplay
- Clear timeout conditions

#### 6. Database for Persistence
**Why:** SQLite database instead of JSON/binary files.
**Justification:**
- Relational structure for complex data (fish collection, inventory)
- SQL queries for filtering and aggregation
- Data integrity with foreign keys
- Scalable for future features (achievements, leaderboards)

#### 7. Rarity-Based Fish System
**Why:** Tiered rarity with upgrade bonuses.
**Justification:**
- Creates progression incentive
- Rare catches feel rewarding
- Shop upgrades have meaningful impact
- Easy to balance by adjusting percentages

---

## Process Flow Chart

### 1. Game Startup Flow

```
┌─────────────────┐
│   Game Start    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Load Autoload   │
│   Singletons    │
│  - GameState    │
│  - Database     │
│  - ShopUI       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Initialize     │
│   Database      │
│ Create Tables   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Load Title    │
│     Screen      │
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │ Player │
    │ Choice │
    └───┬────┘
        │
   ┌────┴────┐
   │         │
   ▼         ▼
┌──────┐  ┌──────────┐
│ New  │  │   Load   │
│ Game │  │   Game   │
└──┬───┘  └────┬─────┘
   │           │
   │           ▼
   │      ┌──────────────┐
   │      │ Query Saves  │
   │      │ from Database│
   │      └──────┬───────┘
   │             │
   │             ▼
   │      ┌──────────────┐
   │      │ Select Save  │
   │      └──────┬───────┘
   │             │
   │             ▼
   │      ┌──────────────┐
   │      │ Load Save    │
   │      │     Data     │
   │      └──────┬───────┘
   │             │
   └──────┬──────┘
          │
          ▼
   ┌──────────────┐
   │ Load Main    │
   │ Game Scene   │
   └──────────────┘
```

**Annotations:**
- Autoload singletons persist across all scenes
- Database initialized once on startup
- Title screen provides entry point for player choice
- New Game creates save entry in database
- Load Game queries existing saves and loads selected one
- Both paths converge to main game scene

---

### 2. Fishing Process Flow

```
┌──────────────────┐
│  Player Enters   │
│   Water Area     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ WaterArea Detects│
│ Player Collision │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Set Player     │
│ in_water_area =  │
│      true        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Player Presses   │
│     SPACE        │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │Is in   │  NO
    │water?  ├─────► [Do Nothing]
    └───┬────┘
        │YES
        ▼
┌──────────────────┐
│ Start Fishing    │
│ System           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Set is_fishing  │
│    = true        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Play Fishing     │
│   Animation      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Start Bite Timer │
│ (Random 2-8s)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Show "Waiting    │
│ for bite..." UI  │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │ Timer  │
    │Expires │
    └───┬────┘
        │
        ▼
┌──────────────────┐
│  Fish Bites!     │
│ Select Random    │
│      Fish        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Calculate Rarity │
│  (60% Common,    │
│  25% Uncommon,   │
│  13% Rare,       │
│  2%+ Legendary)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Show "Press      │
│ SPACE to reel!"  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Start Catch      │
│  Timer (1.5s)    │
└────────┬─────────┘
         │
    ┌────┴─────┐
    │          │
    ▼          ▼
┌─────────┐ ┌──────────┐
│ Player  │ │  Timer   │
│ Presses │ │ Expires  │
│  SPACE  │ │          │
└────┬────┘ └────┬─────┘
     │           │
     │           ▼
     │      ┌──────────┐
     │      │   Fish   │
     │      │  Escapes │
     │      └────┬─────┘
     │           │
     │           ▼
     │      ┌──────────┐
     │      │   End    │
     │      │ Fishing  │
     │      └──────────┘
     │
     ▼
┌──────────────────┐
│ Start Minigame   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Generate Random  │
│  5-Key Sequence  │
│   (W/A/S/D)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Show Key         │
│   Sequence       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Start Minigame   │
│  Timer (5s)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Player Presses   │
│      Key         │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │Correct │  NO
    │  Key?  ├─────────┐
    └───┬────┘         │
        │YES           │
        ▼              ▼
┌──────────────┐  ┌──────────┐
│  Increment   │  │ Minigame │
│   Progress   │  │  Failed  │
└──────┬───────┘  └────┬─────┘
       │               │
       ▼               │
  ┌────────┐           │
  │All Keys│  NO       │
  │  Done? ├───────────┤
  └───┬────┘           │
      │YES             │
      ▼                ▼
┌──────────────┐  ┌──────────┐
│   Success!   │  │   Fish   │
│ Generate Fish│  │  Escapes │
│     Data     │  └────┬─────┘
└──────┬───────┘       │
       │               │
       ▼               │
┌──────────────┐       │
│ Add Fish to  │       │
│  Database    │       │
└──────┬───────┘       │
       │               │
       ▼               │
┌──────────────┐       │
│ Increment    │       │
│ Fish Caught  │       │
└──────┬───────┘       │
       │               │
       ▼               │
┌──────────────┐       │
│   Add XP     │       │
│              │       │
└──────┬───────┘       │
       │               │
       ▼               │
┌──────────────┐       │
│ Show "You    │       │
│  Caught!"    │       │
│   Screen     │       │
└──────┬───────┘       │
       │               │
       └───────┬───────┘
               │
               ▼
        ┌──────────────┐
        │ End Fishing  │
        │  Session     │
        └──────────────┘
```

**Annotations:**
- Water area collision enables fishing capability
- Bite timer creates anticipation
- Catch window (1.5s) requires quick reflexes
- Minigame adds skill-based challenge
- Wrong key immediately fails minigame
- Fish data persisted to database on success
- Left-click at any point cancels fishing

---

### 3. Shop System Flow

```
┌──────────────────┐
│ Player Presses E │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Toggle Shop    │
│     Visibility   │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │ Shop   │  NO
    │ Open?  ├─────► [Hide Shop, Unpause]
    └───┬────┘
        │YES
        ▼
┌──────────────────┐
│  Show Shop UI    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Pause Game     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Update Gold      │
│    Display       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Load Fish from   │
│    Database      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Player Selects  │
│      Tab         │
└────────┬─────────┘
         │
    ┌────┴─────┐
    │          │
    ▼          ▼
┌─────────┐ ┌──────────┐
│  Sell   │ │ Upgrades │
│  Fish   │ │   Tab    │
└────┬────┘ └────┬─────┘
     │           │
     │           ▼
     │      ┌──────────────┐
     │      │ Player Clicks│
     │      │     Buy      │
     │      └──────┬───────┘
     │             │
     │             ▼
     │        ┌────────┐
     │        │Enough  │  NO
     │        │ Gold?  ├─────► [Show Error]
     │        └───┬────┘
     │            │YES
     │            ▼
     │      ┌──────────────┐
     │      │ Deduct Gold  │
     │      └──────┬───────┘
     │             │
     │             ▼
     │      ┌──────────────┐
     │      │Apply Upgrade │
     │      │  (e.g. +2%   │
     │      │  Legendary)  │
     │      └──────┬───────┘
     │             │
     │             ▼
     │      ┌──────────────┐
     │      │Update Display│
     │      └──────────────┘
     │
     ▼
┌──────────────┐
│ Player Clicks│
│     Sell     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Add Gold    │
│ (Fish Value) │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Delete Fish  │
│from Database │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Refresh Fish │
│     List     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│Update Display│
└──────────────┘
```

**Annotations:**
- E key toggles shop visibility
- Shop pauses game for player focus
- Tabs organize different shop functions
- Gold check prevents overspending
- Upgrades immediately affect GameState
- Fish selling removes from database permanently
- Dynamic UI updates reflect changes instantly

---

### 4. Pet Management Flow

```
┌──────────────────┐
│  Player Opens    │
│   Shop (E key)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Select Pets Tab │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Show Available  │
│      Pets        │
│  (Octopet,       │
│   Pengpet)       │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │  Pet   │  YES
    │ Owned? ├─────────────┐
    └───┬────┘             │
        │NO                │
        ▼                  ▼
┌──────────────┐    ┌─────────────┐
│ Show "Buy"   │    │    Show     │
│   Button     │    │ "Equip" or  │
│   (Green)    │    │ "Unequip"   │
└──────┬───────┘    └──────┬──────┘
       │                   │
       ▼                   │
┌──────────────┐           │
│ Player Clicks│           │
│     Buy      │           │
└──────┬───────┘           │
       │                   │
       ▼                   │
  ┌────────┐               │
  │Enough  │  NO           │
  │ Gold?  ├─────► [Error] │
  └───┬────┘               │
      │YES                 │
      ▼                    │
┌──────────────┐           │
│ Deduct Gold  │           │
└──────┬───────┘           │
       │                   │
       ▼                   │
┌──────────────┐           │
│  Add Pet to  │           │
│ owned_pets[] │           │
└──────┬───────┘           │
       │                   │
       ▼                   │
┌──────────────┐           │
│ Change Button│           │
│  to "Equip"  │           │
└──────┬───────┘           │
       │                   │
       └───────┬───────────┘
               │
               ▼
        ┌──────────────┐
        │ Player Clicks│
        │    Equip     │
        └──────┬───────┘
               │
               ▼
          ┌────────┐
          │Another │  YES
          │  Pet   ├─────────┐
          │Equipped│         │
          └───┬────┘         │
              │NO            ▼
              │       ┌─────────────┐
              │       │Unequip Other│
              │       │     Pet     │
              │       └──────┬──────┘
              │              │
              └──────┬───────┘
                     │
                     ▼
              ┌─────────────┐
              │Set equipped │
              │  pet name   │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │  Load Pet   │
              │    Scene    │
              │ (.tscn file)│
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │ Instantiate │
              │  Pet Node   │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │  Add Pet to │
              │ Game Scene  │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │   Pet Finds │
              │    Player   │
              │ (via group) │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │Pet Positions│
              │  Near Player│
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │Pet Begins   │
              │  Following  │
              │   Player    │
              └──────┬──────┘
                     │
                     ▼
              ┌─────────────┐
              │Change Button│
              │ to "Unequip"│
              │   (Orange)  │
              └─────────────┘


┌──────────────────┐
│ Player Clicks    │
│    Unequip       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Clear equipped   │
│    pet name      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Remove Pet Node │
│   from Scene     │
│  (queue_free)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Change Button    │
│  to "Equip"      │
│     (Blue)       │
└──────────────────┘
```

**Annotations:**
- Pet ownership is permanent after purchase
- Only one pet can be equipped at a time
- Equipping spawns pet scene dynamically
- Pet uses group system to find player autonomously
- Unequipping destroys pet node to save resources
- Button color indicates state (Green=Buy, Blue=Equip, Orange=Unequip)
- Pet remains owned after unequipping for re-equipping later

---

### 5. Save/Load Flow

```
┌──────────────────┐
│   Player Takes   │
│     Action       │
│ (Catch Fish,     │
│  Buy Item, etc.) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Update Game    │
│      State       │
│  (GameState.*) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Call GameState   │
│ .save_game_      │
│    state()       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Build save_data │
│   Dictionary     │
│  {gold: 500,     │
│   level: 3, ...} │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Call Database    │
│ Manager.update   │
│    _save()       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Execute SQL     │
│ UPDATE query     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Set last_       │
│   modified       │
│  timestamp       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Emit game_saved()│
│     Signal       │
└──────────────────┘


┌──────────────────┐
│  Player Selects  │
│  "Load Game"     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Query Database   │
│ for All Saves    │
│ (SELECT *)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Display Save    │
│      List        │
│ (sorted by date) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Player Clicks    │
│      Save        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Call Database    │
│ Manager.load_    │
│   save(id)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Execute SQL     │
│ SELECT query     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Return save_    │
│  data Dictionary │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Call GameState   │
│ .load_game_      │
│  state(data)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Set GameState   │
│   properties     │
│ (gold, level,    │
│  position, etc.) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Emit game_       │
│  loaded()        │
│     Signal       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Change Scene to  │
│   Main Game      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Restore Player  │
│    Position      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│   Apply Loaded   │
│      State       │
│  (UI, stats)     │
└──────────────────┘
```

**Annotations:**
- Auto-save occurs after significant game events
- Save data stored as relational database records
- Timestamps allow sorting saves by recency
- Load restores all player progress
- Scene change preserves GameState (singleton)
- Player position restored for seamless continuation

---

### Decision Points Summary

| Decision Point | Options | Logic |
|----------------|---------|-------|
| **In water area?** | Yes / No | Determines if fishing can start |
| **Fish bite timer** | 2-8 seconds | Random anticipation period |
| **Space pressed in time?** | Yes / No | Catch window success |
| **Minigame key correct?** | Yes / No | Validate against sequence |
| **All keys completed?** | Yes / No | Minigame success |
| **Enough gold?** | Yes / No | Purchase validation |
| **Pet owned?** | Yes / No | Show Buy vs Equip |
| **Another pet equipped?** | Yes / No | Unequip before equipping new |
| **Fish rarity roll** | 0.0-1.0 | Determines fish type |

---

## Conclusion

This design documentation provides a comprehensive overview of the 450 Fishing Game's architecture, including:

- **9 core classes** with detailed attributes, methods, and justifications
- **Clear relationship diagrams** showing inheritance and associations
- **5 complete process flowcharts** covering all major game systems
- **Decision point analysis** for key game mechanics
- **Design pattern justifications** explaining architectural choices

The architecture prioritizes:
- **Modularity**: Separate concerns for maintainability
- **Scalability**: Easy to add new features (fish, pets, upgrades)
- **Persistence**: Robust save/load system with SQLite
- **Decoupling**: Signal-based communication for flexibility
- **Player Experience**: Engaging mechanics with clear feedback

This documentation serves as a comprehensive guide for understanding, maintaining, and extending the fishing game codebase.
