# 450 Fishing Game

A 2D fishing game built with Godot 4.5 featuring a catch minigame, shop system, pet companions, and save/load functionality.

## 🎮 Game Features

- **Fishing System**: Cast your line and catch various fish with different rarities
- **Minigame Mechanic**: Complete key sequences to successfully catch fish
- **Shop System**: Sell fish for gold and purchase upgrades and pets
- **Pet Companions**: Buy and equip adorable pets (octopet, pengpet) that follow you around
- **Inventory Management**: Track all fish you've caught
- **Save/Load System**: Multiple save slots using SQLite database
- **Settings**: Customizable audio controls

## 🎣 How to Play

1. **Movement**: Use WASD or Arrow Keys to move your character
2. **Fishing**: Walk to water and press **Space** to cast your fishing line
3. **Catching Fish**: When you get a bite, quickly complete the button sequence minigame
4. **Shop**: Press **E** to open the shop (when near it)
   - Sell your caught fish for gold
   - Buy upgrades to improve your fishing abilities
   - Purchase pet companions
5. **Inventory**: Check your caught fish and collection progress
6. **Save/Load**: Use the menu to save your progress or load previous games

## 📁 Project Structure

```
fluffy-engine/
├── addons/              # Godot plugins
│   └── godot-sqlite/    # SQLite database integration
├── assets/              # Game assets
│   ├── images/          # General images
│   ├── sounds/          # Audio files
│   ├── sprites/         # Character and object sprites
│   └── tilesets/        # Tileset resources
├── scenes/              # Godot scene files (.tscn)
│   ├── fishing/         # Fishing-related scenes
│   ├── pets/            # Pet character scenes
│   ├── player/          # Player character scenes
│   ├── ui/              # User interface scenes
│   └── world/           # World and environment scenes
├── scripts/             # GDScript files (.gd)
│   ├── database/        # Database management
│   ├── fishing/         # Fishing system logic
│   ├── managers/        # Global managers (autoloaded singletons)
│   ├── pets/            # Pet behavior scripts
│   ├── player/          # Player controller scripts
│   ├── ui/              # UI controller scripts
│   └── world/           # World object scripts
└── shaders/             # Custom shader files
```

## 🛠️ Technical Details

### Engine
- **Godot Engine 4.5** (Forward Plus renderer)
- **Language**: GDScript

### Key Systems

#### 1. Autoloaded Singletons
The game uses several autoloaded scripts for global state management (located in `scripts/managers/`):
- `DatabaseManager`: SQLite database operations (scripts/database/)
- `GameState`: Current game session data
- `InputManager`: Centralized input handling
- `PauseManager`: Game pause state
- `UIAudioManager`: UI sound effects (scripts/ui/)
- `ShopUI`: Global shop interface

#### 2. Database System
Uses SQLite (via godot-sqlite plugin) for persistent storage:
- Save game slots
- Player stats (level, gold, experience)
- Inventory tracking
- Upgrade and pet ownership

#### 3. Fishing System
Located in `scripts/fishing/fishing_system.gd`:
- 5 different fish types with varying rarities
- Random size generation
- Bite timing mechanics
- Button sequence minigame
- Fish escape mechanics

#### 4. Shop System
Located in `scripts/ui/shop_ui.gd`:
- Dynamic item listings
- Purchase/sell transactions
- Upgrade application system
- Pet spawning and management

## 📝 Code Documentation

Each script includes:
- **Header comments**: File path and purpose
- **Section dividers**: Clear organization with visual separators
- **Variable documentation**: Comments explaining each variable's purpose
- **Function descriptions**: What each function does
- **Usage instructions**: How to extend or modify systems (see shop_ui.gd for example)

### Key Files to Review

- [game_state.gd](scripts/managers/game_state.gd) - Global game state management
- [player.gd](scripts/player/player.gd) - Player movement and controls
- [fishing_system.gd](scripts/fishing/fishing_system.gd) - Core fishing mechanics
- [shop_ui.gd](scripts/ui/shop_ui.gd) - Shop interface and economy
- [database_manager.gd](scripts/database/database_manager.gd) - Save/load functionality

## 🚀 Getting Started

### Prerequisites
- Godot Engine 4.5 or later

### Installation

1. Clone the repository:
```bash
git clone https://github.com/michaelfournier064/fluffy-engine.git
cd fluffy-engine
```

2. Open the project in Godot:
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`
   - Click "Import & Edit"

3. Run the game:
   - Press F5 or click the Play button in Godot Editor

## 🎨 Assets

- **Sprites**: Custom pixel art for player, pets, and environment
- **Audio**: Click sounds and UI feedback
- **Tilesets**: Water areas and grass terrain
- **Catch Images**: 5 unique fish catch celebration screens

## 📊 Fish Types

| Fish Name | Rarity | Size Range | Value Range |
|-----------|--------|------------|-------------|
| Bass | Common | 30-60 cm | Lower value |
| Trout | Common | 25-50 cm | Lower value |
| Goldfish | Uncommon | 10-20 cm | Medium value |
| Snapper | Rare | 40-80 cm | Higher value |
| Tuna | Legendary | 80-200 cm | Highest value |

## 🐙 Available Pets

- **Octopet**: Adorable octopus companion
- **Pengpet**: Cute penguin companion

Pets follow the player and provide companionship (cosmetic feature).

## 🔧 Extending the Game

### Adding New Fish
Edit `scripts/fishing/fishing_system.gd`:
1. Add new entry to `fish_types` array
2. Add corresponding catch image to `assets/sprites/`

### Adding Shop Items
Edit `scripts/ui/shop_ui.gd`:
- **Upgrades**: Add to `shop_upgrades` array and create handler in `apply_upgrade()`
- **Pets**: Add to `shop_pets` array and create scene in `scenes/pets/`

See comments in shop_ui.gd for detailed instructions.

## 🐛 Known Issues

None currently reported. Please submit issues via GitHub if you encounter any problems.

## 📜 License

This project is created for educational purposes as part of a school assignment.

## 👨‍💻 Author

Michael Fournier (@michaelfournier064)

## 🙏 Acknowledgments

- Godot Engine community
- godot-sqlite plugin by 2shady4u
- Pixel art assets (custom created)

---

**Repository**: https://github.com/michaelfournier064/fluffy-engine  
**Course**: CS 450 - Game Development  
**Date**: December 2025
