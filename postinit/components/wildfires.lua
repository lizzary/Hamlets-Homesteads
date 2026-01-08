local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("wildfires", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end

    local OnPlayerLeft = inst:GetEventCallbacks("ms_playerleft", inst, "scripts/components/wildfires.lua")
    if not OnPlayerLeft then return end
    
    local CancelSpawn = ToolUtil.GetUpvalue(OnPlayerLeft, "CancelSpawn")
    if not CancelSpawn then return end

    local _scheduledtasks = ToolUtil.GetUpvalue(CancelSpawn, "_scheduledtasks")
    if not _scheduledtasks then return end

    local OnPlayerJoined = inst:GetEventCallbacks("ms_playerjoined", inst, "scripts/components/wildfires.lua")
    if not OnPlayerJoined then return end

    local ScheduleSpawn = ToolUtil.GetUpvalue(OnPlayerJoined, "ScheduleSpawn")
    if not ScheduleSpawn then return end

    local LightFireForPlayer, scope_fn, i = ToolUtil.GetUpvalue(ScheduleSpawn, "LightFireForPlayer")
    if not LightFireForPlayer then return end

    local function LightFireForPlayer_New(player, rescheduleFn)
        if player:GetIsInInterior() then
            _scheduledtasks[player] = nil
            rescheduleFn(player)
            return
        end

        return LightFireForPlayer(player, rescheduleFn)
    end

    debug.setupvalue(scope_fn, i, LightFireForPlayer_New)
end) 