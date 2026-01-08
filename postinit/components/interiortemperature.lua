local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local _GetTemperatureAtXZ = GetTemperatureAtXZ

function GetTemperatureAtXZ(x, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        --print("GetGroupIdFromWorldPos: ",TheWorld.components.interiorspawner:GetGroupIdFromWorldPos(x,z))
        local current_group_id = TheWorld.components.interiorspawner:GetGroupIdFromWorldPos(x,z)
        local coolingUpgrade = TheWorld.components.roomsystem:GetHouseCoolingUpgradeStage(current_group_id)
        local warmingUpgrade = TheWorld.components.roomsystem:GetHouseWarmingUpgradeStage(current_group_id)
        if coolingUpgrade >= 10 and warmingUpgrade >= 10 then
            return 25
        end

        local current_world_temp = _GetTemperatureAtXZ(x, z, ...)

        if coolingUpgrade >= 5 then
            return math.min(current_world_temp, 69)
        end

        if warmingUpgrade >= 5 then
            return math.max(current_world_temp, 1)
        end
        --print(current_group_id,coolingUpgrade,warmingUpgrade,"temp: ",current_world_temp)
        return current_world_temp

    end
    --print("outside door: ",_GetTemperatureAtXZ(x, z, ...))
    return _GetTemperatureAtXZ(x, z, ...)
end

local _GetLocalTemperature = GetLocalTemperature
function GetLocalTemperature(inst, ...)
    if inst and inst.Transform then
        local x, y, z = inst.Transform:GetWorldPosition()
        return GetTemperatureAtXZ(x, z, ...)
    end
    return _GetLocalTemperature(inst, ...)
end 