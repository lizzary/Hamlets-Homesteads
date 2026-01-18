local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("sinkholespawner", function(SinkholeSpawner)
    local oldDoTargetAttack = SinkholeSpawner.DoTargetAttack
    function SinkholeSpawner:DoTargetAttack(targetinfo)
        if targetinfo.pos ~= nil and TheWorld.components.interiorspawner:IsInInteriorRegion(targetinfo.pos.x,targetinfo.pos.z) then
            targetinfo.attacks = targetinfo.attacks - 1 -- 跳过一次地震
            return
        end

        oldDoTargetAttack(self,targetinfo)
    end
end)