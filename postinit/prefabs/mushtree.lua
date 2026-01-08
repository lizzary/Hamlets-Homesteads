local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local mushtree_prefabs = {
    "mushtree_tall",
    "mushtree_medium", 
    "mushtree_small",
    "mushtree_tall_webbed",
    "mushtree_medium_webbed",
    "mushtree_small_webbed"
}

for _, prefab_name in ipairs(mushtree_prefabs) do
    AddPrefabPostInit(prefab_name, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        if inst.components.timer then
            local _OnTimerDone = inst.components.timer.OnTimerDone
            if _OnTimerDone then
                inst.components.timer.OnTimerDone = function(self, data)
                    if data.name == "acidvisualsupdate" and inst:GetIsInInterior() then
                        return
                    end
                    return _OnTimerDone(self, data)
                end
            end
        end
    end)
end 