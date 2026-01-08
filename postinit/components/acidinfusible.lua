local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local AcidInfusible = require("components/acidinfusible")

local _OnInfusedDirty = AcidInfusible.OnInfusedDirty

function AcidInfusible:OnInfusedDirty(acidraining, hasrainimmunity)
    if self.inst:GetIsInInterior() then
        acidraining = false
    end
    
    return _OnInfusedDirty(self, acidraining, hasrainimmunity)
end 