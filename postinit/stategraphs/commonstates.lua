GLOBAL.setfenv(1, GLOBAL)
require("stategraphs/commonstates")

-- 室内足音处理
local _PlayFootstep = PlayFootstep
function PlayFootstep(inst, volume, ispredicted, ...)
    local room = TheWorld.components.interiorspawner:GetInteriorCenter(inst:GetPosition())
    if room and inst.SoundEmitter then
        local footstep_tile = room.footstep_tile or room._footstep_tile:value()

        local tile_info = GetTileInfo(footstep_tile) or GetTileInfo(WORLD_TILES.DIRT)
        local runsound = tile_info.runsound or "dontstarve/movement/run_woods"
        local walksound = tile_info.walksound or "dontstarve/movement/walk_woods"
        local suffix = (inst:HasTag("smallcreature") and "_small") or (inst:HasTag("largecreature") and "_large" or "")
        local sound = (inst.sg ~= nil and inst.sg:HasStateTag("running") and runsound or walksound) .. suffix

        inst.SoundEmitter:PlaySound(sound, nil, volume or 1, ispredicted)
    else
        _PlayFootstep(inst, volume, ispredicted, ...)
    end
end

CommonStates.AddExtraStateFn = function(states, name, fns)
    local state = nil
    for k, v in pairs(states) do
        if v.name == name then
            state = v
        end
    end

    assert(state, string.format("Can't find state named: %s", name))

    for fn_name, fn in pairs(fns) do
        local _fn = state[fn_name]
        state[fn_name] = function(...)
            fn(...)
            if _fn then
                return _fn(...)
            end
        end
    end
end
