local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

---@param event string
---@param source entityscript | nil
---@param source_file string | nil
function EntityScript:GetEventCallbacks(event, source, source_file, test_fn)
    source = source or self

    if not self.event_listening[event] or not self.event_listening[event][source] then
        return
    end

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and (info.source == source_file) and (not test_fn or test_fn(fn)) then
                return fn
            end
        elseif (not test_fn or test_fn(fn)) then
            return fn
        end
    end
end

-- 添加必要的函数定义
function EntityScript:CanOnWater(allow_invincible)
    return self.components.amphibiouscreature ~= nil
        or (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnWater())
        or self:HasTag("flying")
        or self:HasTag("ignorewalkableplatformdrowning")
        or self:HasTag("shadow")
        or self:HasTag("shadowminion")
        or (self:HasTag("player") and (self.components.drownable == nil or not self.components.drownable:CanDrownOverWater(allow_invincible)))
end

function EntityScript:CanOnLand(allow_invincible)
    return self.components.amphibiouscreature ~= nil
        or (self.components.locomotor == nil or self.components.locomotor:CanPathfindOnLand())
        or (self:HasTag("player") and self.components.drydrownable == nil or self.components.drydrownable ~= nil and not self.components.drydrownable:CanDrownOverLand(allow_invincible))
end

function EntityScript:CanOnImpassable(allow_invincible)
    return self:HasTag("shadow")
end

-- 返回实体当前所在的室内ID
function EntityScript:GetCurrentInteriorID()
    if not self:IsValid() then
        return
    end
    local x, _, z = self.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        local interiorID = TheWorld.components.interiorspawner:PositionToIndex({x = x, z = z})
        return TheWorld.components.interiorspawner.interiors[interiorID] and interiorID
    end
end

function EntityScript:GetIsInInterior()
    if not self:IsValid() then
        return false
    end
    local x, _, z = self.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return true
    end
    return false
end

-- 室内湿润状态修正 - 让室内的物品也可以变湿
local _GetIsWet = EntityScript.GetIsWet
function EntityScript:GetIsWet(...) -- 危险的写法
    local ret
    if self:GetIsInInterior() then
        local _iswet = TheWorld.state.iswet
        TheWorld.state.iswet = false
        ret = _GetIsWet(self, ...)
        TheWorld.state.iswet = _iswet
    else
        ret = _GetIsWet(self, ...)
    end

    return ret or self:HasTag("temporary_wet")
end

--室内光照系统
function EntityScript:GetLightColour()
    local x, y, z = self.Transform:GetWorldPosition()
    local position = Vector3(x, y, z)
    
    local sum_r, sum_g, sum_b = 0, 0, 0
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"})) do
        if v ~= self and v.Light and v.Light:IsEnabled() then
            local _r, _g, _b = CalculateLight(v.Light, math.sqrt(v:GetPosition():DistSq(position)))
            sum_r = sum_r + _r
            sum_g = sum_g + _g
            sum_b = sum_b + _b
        end
    end
    if not self:GetIsInInterior() then
        local _r, _g, _b = TheSim:GetAmbientColour()
        sum_r = sum_r + _r / 255
        sum_g = sum_g + _g / 255
        sum_b = sum_b + _b / 255
    end

    return sum_r, sum_g, sum_b, 0.2126 * sum_r + 0.7152 * sum_g + 0.0722 * sum_b
end

function EntityScript:GetCurrentInteriorCenter()
    return TheWorld.components.interiorspawner:GetInteriorCenter(self:GetPosition())
end

function EntityScript:GetInteriorGroupID()
    local center = self:GetCurrentInteriorCenter()
    if center then
        return center:GetGroupId()
    end
end

function EntityScript:GetInteriorGroupPosition()
    local center = self:GetCurrentInteriorCenter()
    if center then
        local x, y, z = self.Transform:GetWorldPosition()
        local cx, cy, cz = center.Transform:GetWorldPosition()

        local current_x, current_y = center:GetCoordinates()
        local width, depth = center:GetSize()

        local offset_x = current_x * (width + INTERIOR_SPACEING * 2)
        local offset_y = current_y * (depth + INTERIOR_SPACEING * 2)

        return Vector3(x - cx - offset_y, 0, z - cz + offset_x)
    end
end

function EntityScript:GetRelativePositionInRoom(target)
    return target:GetInteriorGroupPosition() - self:GetInteriorGroupPosition()
end

function EntityScript:IsInSameRoomGroup(target)
    if not (target and target:IsValid()) then
        return false
    end

    local current_group = self:GetInteriorGroupID()
    local target_group = target:GetInteriorGroupID()

    return (current_group ~= nil) and current_group == target_group
end