local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("frograin", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end
    
    local OnPlayerLeft = inst:GetEventCallbacks("ms_playerleft", TheWorld, "scripts/components/frograin.lua")
    if not OnPlayerLeft then return end

    local CancelSpawn = ToolUtil.GetUpvalue(OnPlayerLeft, "CancelSpawn")
    if not CancelSpawn then return end

    local _scheduledtasks = ToolUtil.GetUpvalue(CancelSpawn, "_scheduledtasks")
    if not _scheduledtasks then return end

    local OnPlayerJoined = inst:GetEventCallbacks("ms_playerjoined", TheWorld, "scripts/components/frograin.lua")
    if not OnPlayerJoined then return end

    local ScheduleSpawn = ToolUtil.GetUpvalue(OnPlayerJoined, "ScheduleSpawn")
    if not ScheduleSpawn then return end

    local SpawnFrogForPlayer, scope_fn, i = ToolUtil.GetUpvalue(ScheduleSpawn, "SpawnFrogForPlayer")
    if not SpawnFrogForPlayer then return end

    local function SpawnFrogForPlayer_New(player, reschedule)
        if player:GetIsInInterior() then
            _scheduledtasks[player] = nil
            reschedule(player)
            return
        end
        return SpawnFrogForPlayer(player, reschedule)
    end

    debug.setupvalue(scope_fn, i, SpawnFrogForPlayer_New)
end) 