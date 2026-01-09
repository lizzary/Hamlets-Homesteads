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


    self.inst:AddTag("roomsystem")

    self.house = autoTable()
    self.room = autoTable()
end)

--累计到第5颗蓝宝石升级后，室内温度最低为69
--宝石数量的逻辑在\postinit\components\interiortemperature.lua，其实把相关逻辑放进这里比较好
function Roomsystem:CoolingUpgrade(groupId,level)
    self.house[groupId]["coolingUpgrade"] = (checkTableOrValue(self.house[groupId]["coolingUpgrade"]) or 0) + level
end

--累计到第5颗红宝石升级后，室内温度最高为1
function Roomsystem:GetHouseCoolingUpgradeStage(groupId)
    return (checkTableOrValue(self.house[groupId]["coolingUpgrade"]) or 0)
end
--若同时有10颗红宝石+10颗蓝宝石升级后，室内温度则恒为25

function Roomsystem:WarmingUpgrade(groupId,level)
    self.house[groupId]["warmingUpgrade"] = (checkTableOrValue(self.house[groupId]["warmingUpgrade"]) or 0) + level
end

function Roomsystem:GetHouseWarmingUpgradeStage(groupId)
    return (checkTableOrValue(self.house[groupId]["warmingUpgrade"]) or 0)
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