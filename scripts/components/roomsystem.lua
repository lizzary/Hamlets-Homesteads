-- 注：这个组件是全局的，因为挂在TheWrold下面了，请使用TheWorld.components.roomsystem来引用
local function autoTable()
    return setmetatable({}, {
        __index = function(t, k)
            local new = autoTable()
            rawset(t, k, new)
            return new
        end
    })
end

local function checkTableOrValue(var)
    if type(var) == "table" then
        return nil
    end

    return var
end

local Roomsystem = Class(function(self, inst)
    self.inst = inst
    --累计到第5颗蓝宝石升级后，室内温度最低为69
    --累计到第5颗红宝石升级后，室内温度最高为1
    --若同时有10颗红宝石+10颗蓝宝石升级后，室内温度则恒为25
    self.warming_stage1_level = 5
    self.cooling_stage1_level = 5
    self.warming_stage2_level = 10
    self.warming_stage2_level = 10

    self.WARMING_STAGE_1 = 1
    self.COOLING_STAGE_1 = 1
    self.WARMING_STAGE_2 = 2
    self.COOLING_STAGE_2 = 2

    self.inst:AddTag("roomsystem")

    self.house = autoTable()
    self.room = autoTable()
end)


--温控逻辑：\postinit\components\interiortemperature.lua
function Roomsystem:CoolingUpgrade(groupId,level)
    self.house[groupId]["coolingUpgrade"] = (checkTableOrValue(self.house[groupId]["coolingUpgrade"]) or 0) + level
end

function Roomsystem:GetCoolingUpgrade(groupId)
    return (checkTableOrValue(self.house[groupId]["coolingUpgrade"]) or 0)
end

function Roomsystem:GetHouseCoolingUpgradeStage(groupId)
    if not groupId then
        return 0
    end
    local coolingUpgrade = (checkTableOrValue(self.house[groupId]["coolingUpgrade"]) or 0)
    if coolingUpgrade < 5 then
        return 0
    elseif coolingUpgrade < 10 then
        return 1
    else
        return 2
    end
end

function Roomsystem:WarmingUpgrade(groupId,level)
    self.house[groupId]["warmingUpgrade"] = (checkTableOrValue(self.house[groupId]["warmingUpgrade"]) or 0) + level
end

function Roomsystem:GetWarmingUpgrade(groupId)
    return (checkTableOrValue(self.house[groupId]["warmingUpgrade"]) or 0)
end

function Roomsystem:GetHouseWarmingUpgradeStage(groupId)
    if not groupId then
        return 0
    end
    local coolingUpgrade = (checkTableOrValue(self.house[groupId]["warmingUpgrade"]) or 0)
    if coolingUpgrade < 5 then
        return 0
    elseif coolingUpgrade < 10 then
        return 1
    else
        return 2
    end
end

function Roomsystem:SetRoomType(interiorId,roomtype)
    self.room[interiorId] = roomtype
end

function Roomsystem:GetRoomTypeById(interiorId)
    return checkTableOrValue(self.room[interiorId])
end

function Roomsystem:GetRoomTypeByWorldPos(x,z)

    if not TheWorld.components.interiorspawner:IsInInteriorRegion(x,z) then
        return nil
    end

    local interiorId = TheWorld.components.interiorspawner:PositionToIndex({x=x,z=z})
    return self:GetRoomTypeById(interiorId)
end

return Roomsystem