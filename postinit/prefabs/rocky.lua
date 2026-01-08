local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("rocky", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.OnUpdate then
        local _OnUpdate = inst.OnUpdate
        inst.OnUpdate = function(inst, dt)
            if inst:GetIsInInterior() then
                local had_immunity = inst.components.rainimmunity ~= nil
                if not had_immunity then
                    inst:AddComponent("rainimmunity")
                    inst.components.rainimmunity:AddSource(inst)
                end
                
                local result = _OnUpdate(inst, dt)
                
                if not had_immunity and inst.components.rainimmunity then
                    inst:RemoveComponent("rainimmunity")
                end
                
                return result
            else
                return _OnUpdate(inst, dt)
            end
        end
    end
end) 