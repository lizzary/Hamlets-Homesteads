local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local AcidLevel = require("components/acidlevel")

local _SetIgnoreAcidRainTicks = AcidLevel.SetIgnoreAcidRainTicks

function AcidLevel:SetIgnoreAcidRainTicks(ignoreacidrainticks)
    local x, _, z = self.inst.Transform:GetWorldPosition()
    if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        ignoreacidrainticks = true
    end
    
    return _SetIgnoreAcidRainTicks(self, ignoreacidrainticks)
end

local _DoAcidRainDamageOnEquipped = AcidLevel.DoAcidRainDamageOnEquipped
local _DoAcidRainRotOnAllItems = AcidLevel.DoAcidRainRotOnAllItems  
local _DoAcidRainDamageOnHealth = AcidLevel.DoAcidRainDamageOnHealth

function AcidLevel:DoAcidRainDamageOnEquipped(item, damage)
    local owner = item.components.inventoryitem and item.components.inventoryitem.owner
    if owner and owner:GetIsInInterior() then
        return
    end
    
    return _DoAcidRainDamageOnEquipped(self, item, damage)
end

function AcidLevel:DoAcidRainRotOnAllItems(item, percent)
    local owner = item.components.inventoryitem and item.components.inventoryitem.owner
    if owner and owner:GetIsInInterior() then
        return
    end
    
    return _DoAcidRainRotOnAllItems(self, item, percent)
end

function AcidLevel:DoAcidRainDamageOnHealth(inst, damage)
    if inst:GetIsInInterior() then
        return
    end
    
    return _DoAcidRainDamageOnHealth(self, inst, damage)
end 