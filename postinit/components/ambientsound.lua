local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

-- 由于室内空间实在地图边角，所以会有海浪声，这很诡异，因此以下内容修改环境音效组件，禁用室内海浪声
AddComponentPostInit("ambientsound", function(self, inst)
    if TheNet:IsDedicated() then
        return
    end
    
    inst:DoTaskInTime(0.1, function()
        if not self.OnUpdate then
            return
        end
        
        local _OriginalOnUpdate = self.OnUpdate
        
        function self:OnUpdate(dt)
            local is_in_interior = false
            if ThePlayer and ThePlayer:IsValid() then
                if ThePlayer.GetIsInInterior then
                    is_in_interior = ThePlayer:GetIsInInterior()
                elseif ThePlayer:HasTag("inside_interior") then
                    is_in_interior = true
                elseif TheWorld.components and TheWorld.components.interiorspawner then
                    local x, _, z = ThePlayer.Transform:GetWorldPosition()
                    is_in_interior = TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
                end
            end
            
            _OriginalOnUpdate(self, dt)
            
            if is_in_interior then
                if inst.SoundEmitter then
                    inst.SoundEmitter:KillSound("waves")
                end
            end
        end
    end)
end) 