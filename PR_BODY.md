# feat(ui): complete title screen implementation

## Summary
- Implements complete title screen functionality with custom UI components, background image, and interactive buttons
- Adds reusable CustomButton class with hover/press animations and audio feedback
- Includes scene composition following project conventions and proper signal handling

## Commits included
- feat(ui): implement title screen scene with background and menu buttons
- feat(ui): add CustomButton class with hover/press animations and audio
- fix(ui): add null safety check for tween creation in CustomButton

## Files changed
- `project.godot` — updated project configuration and scene references
- `scenes/title_screen.tscn` — complete title screen scene with UI layout
- `scripts/title_screen.gd` — title screen controller script
- `scripts/utilities/custom_button.gd` — reusable button component with animations
- `assets/images/titleScreen.jpg` — background image for title screen

## How to test
1. Open the project in Godot 4.x
2. Run the project (F5) to see the title screen
3. Hover over buttons to see scale animation and hear hover sound
4. Click buttons to see press animation and hear click sound
5. Verify UI layout adapts properly to different window sizes
6. Check that all buttons emit `pressed_confirmed` signal correctly

## Implementation details
- **CustomButton**: Extends Button with configurable hover/press scaling, smooth animations via Tween, and integrated audio feedback
- **Title Screen**: Uses proper container layout (AspectRatioContainer + VBoxContainer) for responsive design
- **Audio Integration**: Connects to UserInterfaceAudio autoload for consistent sound effects
- **Signal Safety**: Includes null checks to prevent tween errors during scene initialization

## Notes for reviewer
- CustomButton is designed as a reusable component for the entire project
- Scene follows CONTRIBUTING.md guidelines for naming and structure
- All UI interactions are properly handled with signal connections
- Background image is placed as Sprite2D to avoid blocking UI input