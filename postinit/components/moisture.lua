local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local Moisture = require("components/moisture")

function Moisture:GetMoistureRate(...)
    local rate = 0
    -- 只在下雨时才加潮湿度，下雪不加
    if TheWorld.state.israining and not TheWorld.state.issnowing then
        rate = self:_GetMoistureRateAssumingRain()
    end
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        rate = 0
    end
    return rate
end

--这个函数不确定要不要删掉
local _GetDryingRate = Moisture.GetDryingRate
function Moisture:GetDryingRate(...)
    local rate = _GetDryingRate(self, ...)
    if TheWorld.state.issnowing and rate <= 0 then
        rate = TUNING.MOISTURE_DRYING_RATE or 0.1
    end
    return rate
end
