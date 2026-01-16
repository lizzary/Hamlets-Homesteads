local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("sinkholespawner", function(SinkholeSpawner)
    local oldDoTargetAttack = SinkholeSpawner.DoTargetAttack
    function SinkholeSpawner:DoTargetAttack(targetinfo)
        if not targetinfo or not targetinfo.pos or not targetinfo.pos.x or not targetinfo.pos.z then --可能在洞穴什么的
            return
        end
        if TheWorld.components.interiorspawner:IsInInteriorRegion(targetinfo.pos.x,targetinfo.pos.z) then
            return
        end
        oldDoTargetAttack(self,targetinfo)
    end
end)