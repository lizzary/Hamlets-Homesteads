local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("lunarhailbuildup", function(self, inst)
    if not TheWorld.ismastersim then
        return
    end

    local _DoLunarHailTick = self.DoLunarHailTick
    self.DoLunarHailTick = function(self, buildingup)
        local x, _, z = self.inst.Transform:GetWorldPosition()
        if TheWorld.components.interiorspawner:IsInInterior(x, z) then
            return
        end
        local ret = {_DoLunarHailTick(self, buildingup)}
        if UpdateLunarHailBuildup ~= nil then
            UpdateLunarHailBuildup(self.inst)
        end
        return unpack(ret)
    end
end) 