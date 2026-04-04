--[[

ScriptHub Dev Notes

Structure Overview:

loader/
    Entry + routing logic

core/
    Shared systems (state, runtime, cleanup, logger)

ui/
    UILibrary + wrappers + themes

shared/
    Small reusable helpers (services, instances, tables, players)

features/
    Reusable feature systems (ESP, movement, visuals)

games/
    active/     -> live supported games
    templates/  -> base template for new games
    archive/    -> old/unused

dev/
    examples/   -> quick test loaders
    test/       -> smoke tests
    notes/      -> this file

Key Rules:

- One folder = one responsibility
- Game logic NEVER goes in loader/
- Reusable systems NEVER go inside a game folder
- Every game = its own folder
- Always use registry for adding games

Flow:

loader/init.lua
    -> registry.lua
    -> router.lua
    -> bootstrap.lua
    -> game init.lua

Game modules always return:

return {
    Init = function(ctx)
    end
}

]]