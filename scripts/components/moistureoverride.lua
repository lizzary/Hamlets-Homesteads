local SourceModifierList = require("util/sourcemodifierlist")

local DRY_THRESHOLD = TUNING.MOISTURE_DRY_THRESHOLD
local WET_THRESHOLD = TUNING.MOISTURE_WET_THRESHOLD

local MoistureOverride = Class(function(self, inst)
    self.inst = inst

    self.wetness = 0

    self.rate_add = SourceModifierList(self.inst, 0, SourceModifierList.additive)
    self.rate_mult = SourceModifierList(self.inst, 1)
end)

---@param moisture number
function MoistureOverride:SetAddMoisture(source, moisture)
    self.rate_add:SetModifier(source, moisture)
end

function MoistureOverride:SetMultMoisture(source, moisture)
    self.rate_mult:SetModifier(source, moisture)
end

function MoistureOverride:RemoveAddMoisture(source)
    self.rate_add:RemoveModifier(source)
end

function MoistureOverride:RemoveMultMoisture(source)
    self.rate_mult:RemoveModifier(source)
end

function MoistureOverride:AddOnce(wetness)
    self.wetness = math.clamp(self.wetness + wetness, 0, TUNING.MAX_WETNESS)
end

function MoistureOverride:OnUpdate(dt)
    -- 简化的湿度处理，移除对plateauweather的依赖
    local rate_additive = self.rate_add:Get() * dt
    
    -- 使用原版饥荒的湿度系统
    local world_moisture_rate = 0
    if TheWorld.state.israining then
        world_moisture_rate = TheWorld.state.precipitationrate or 0
    end
    
    -- 在室内时，湿度变化较慢
    if self.inst:GetIsInInterior() then
        world_moisture_rate = world_moisture_rate * 0.1
    end
    
    self.rate_mult:SetModifier("weather", world_moisture_rate)

    self.wetness = math.clamp(self.wetness + self.rate_mult:Get() * dt + self.rate_add:Get() * dt, 0, TUNING.MAX_WETNESS)

    if self.wetness == 0 then
        self.inst:RemoveComponent("moistureoverride")
        return
    end

    if self.wetness > WET_THRESHOLD then
        self.inst:AddTag("temporary_wet")
    elseif self.wetness < DRY_THRESHOLD then
        self.inst:RemoveTag("temporary_wet")
    end
end

function MoistureOverride:GetDebugString()
    return string.format("Wetness: %2.2f Rate(additive): %2.2f Rate(multiply): %2.2f", self.wetness, self.rate_add:Get(), self.rate_mult:Get())
end

return MoistureOverride
 