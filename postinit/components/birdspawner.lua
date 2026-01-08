local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("birdspawner", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end

    local OnLunarBirdEvent, scope_fn_event, i_event = ToolUtil.GetUpvalue(self.OnPostInit, "OnLunarBirdEvent")
    if OnLunarBirdEvent then
        local function OnLunarBirdEvent_New()
            for _, player in ipairs(ToolUtil.GetUpvalue(OnLunarBirdEvent, "_activeplayers")) do
                if not player:GetIsInInterior() then
                    OnLunarBirdEvent(player)
                end
            end
        end
        debug.setupvalue(scope_fn_event, i_event, OnLunarBirdEvent_New)
    end
    
    local ScheduleSpawn, scope_fn_spawn, i_spawn = ToolUtil.GetUpvalue(self.OnPostInit, "ScheduleSpawn")
    if ScheduleSpawn then
        local SpawnCorpseForPlayer, scope_fn_corpse, i_corpse = ToolUtil.GetUpvalue(ScheduleSpawn, "SpawnCorpseForPlayer")
        if SpawnCorpseForPlayer then
            local function SpawnCorpseForPlayer_New(player, reschedule)
                if not player:GetIsInInterior() then
                    return SpawnCorpseForPlayer(player, reschedule)
                elseif reschedule then
                    local _scheduledtasks = ToolUtil.GetUpvalue(SpawnCorpseForPlayer, "_scheduledtasks")
                    if _scheduledtasks then
                        _scheduledtasks[player] = nil
                        reschedule(player)
                    end
                end
            end
            debug.setupvalue(scope_fn_corpse, i_corpse, SpawnCorpseForPlayer_New)
        end
    end
    
    local _SendMutatedBirdOnPlayer = self.SendMutatedBirdOnPlayer
    self.SendMutatedBirdOnPlayer = function(self_ptr, player, ...)
        if not player:GetIsInInterior() then
            return _SendMutatedBirdOnPlayer(self_ptr, player, ...)
        end
    end
    
    local _SendMutatedBirdOnLunarHailBuildUp = self.SendMutatedBirdOnLunarHailBuildUp
    self.SendMutatedBirdOnLunarHailBuildUp = function(self_ptr, target, ...)
        local x, _, z = target.Transform:GetWorldPosition()
        if not TheWorld.components.interiorspawner:IsInInterior(x, z) then
             return _SendMutatedBirdOnLunarHailBuildUp(self_ptr, target, ...)
        end
    end
end) 