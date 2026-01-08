local AddPlayerPostInit = AddPlayerPostInit
GLOBAL.setfenv(1, GLOBAL)

local function UpdateHomeTechBonus(inst, data)
    if data.to and data.to:HasInteriorTag("home_prototyper") then
        inst.components.builder.home_bonus = 2
    else
        inst.components.builder.home_bonus = 0
    end
end

local function OnInteriorChange(inst, data)
    UpdateHomeTechBonus(inst, data)
    if data.to == nil then
        -- 存储玩家在室内时的淘气值，离开时触发 ？
        TheWorld.components.kramped:OnNaughtyAction(0, inst)
    end
end

AddPlayerPostInit(function(inst)
    if not TheWorld.ismastersim then
        return
    end

    inst:AddComponent("interiorvisitor")
    inst:AddComponent("persistencevision")
    inst:ListenForEvent("enterinterior", OnInteriorChange)
    inst:ListenForEvent("leaveinterior", OnInteriorChange)
end)
