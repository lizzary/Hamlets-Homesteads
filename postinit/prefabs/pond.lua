local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local pond_prefabs = {
    "pond", 
    "pond_cave",
    "pond_mos"
}

for _, prefab_name in ipairs(pond_prefabs) do
    AddPrefabPostInit(prefab_name, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        if inst.components.acidlevel then
            local _DoDelta = inst.components.acidlevel.DoDelta
            if _DoDelta then
                inst.components.acidlevel.DoDelta = function(self, delta)
                    if inst:GetIsInInterior() then
                        if delta > 0 then
                            return
                        end
                    end
                    return _DoDelta(self, delta)
                end
            end
        end
    end)
end 