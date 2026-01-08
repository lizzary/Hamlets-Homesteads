local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

local function Init(inst)
    if inst.components.inventoryitem then
        return
    end

    -- Disable for now for performance reason and also player might get squeezed out of world bound
    if not inst:HasTag("nokeeponpassable") and inst.components.keeponpassable == nil then
        inst:AddComponent("keeponpassable")
    end
end

AddComponentPostInit("locomotor", function(self)
    self.inst:DoStaticTaskInTime(0, Init)
end)
