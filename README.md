# VANTA Hub

Revamped ScriptHub with a futuristic control-surface UI, stronger module scaffolding, and a cleaner path for adding new games.

## Highlights
- New VANTA visual system in `ui/library/UILibrary.lua`
- Multi-page hub builder in `ui/wrappers/hub.lua`
- New `GameFactory.CreatePagedWindow(...)` helper for faster UI setup
- New `core/game_schema.lua` scaffold helper
- Bite By Night module migrated to the new page/card layout
- Universal fallback updated to match the new hub style
- Theme presets: Vanta / Nebula / Ember

## Fast path for adding a new game
1. Copy `games/templates/GameTemplate`
2. Register the game in `loader/registry.lua`
3. Reuse `GameFactory.Boot(...)`
4. Build pages with `GameFactory.CreatePagedWindow(...)` or `ui/wrappers/hub.lua`
