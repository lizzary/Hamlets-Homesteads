local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("sinkholespawner", function(SinkholeSpawner)
    local oldDoTargetAttack = SinkholeSpawner.DoTargetAttack
    function SinkholeSpawner:DoTargetAttack(targetinfo)
        if TheWorld.components.interiorspawner:IsInInteriorRegion(targetinfo.pos.x,targetinfo.pos.z) then
            return
        end
        oldDoTargetAttack(self,targetinfo)
    end
end)