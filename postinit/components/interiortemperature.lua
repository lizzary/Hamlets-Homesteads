local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local _GetTemperatureAtXZ = GetTemperatureAtXZ

function GetTemperatureAtXZ(x, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        --print("GetGroupIdFromWorldPos: ",TheWorld.components.interiorspawner:GetGroupIdFromWorldPos(x,z))
        local current_group_id = TheWorld.components.interiorspawner:GetGroupIdFromWorldPos(x,z)
        local CoolingUpgradeStage = TheWorld.components.roomsystem:GetHouseCoolingUpgradeStage(current_group_id)
        local WarmingUpgradeStage = TheWorld.components.roomsystem:GetHouseWarmingUpgradeStage(current_group_id)
        local WARMING_STAGE_1 = TheWorld.components.roomsystem.WARMING_STAGE_1
        local COOLING_STAGE_1 = TheWorld.components.roomsystem.COOLING_STAGE_1
        local WARMING_STAGE_2 = TheWorld.components.roomsystem.WARMING_STAGE_2
        local COOLING_STAGE_2 = TheWorld.components.roomsystem.COOLING_STAGE_2
        if CoolingUpgradeStage >= COOLING_STAGE_2 and WarmingUpgradeStage >= WARMING_STAGE_2 then
            return 25
        end

        local current_world_temp = _GetTemperatureAtXZ(x, z, ...)

        if CoolingUpgradeStage >= COOLING_STAGE_1 then
            return math.min(current_world_temp, 69)
        end

        if WarmingUpgradeStage >= WARMING_STAGE_1 then
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