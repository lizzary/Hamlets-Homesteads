local assets =
{
    Asset("ANIM", "anim/permit_kitchen_reno.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst:AddTag("build_kitchen")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("permit_kitchen_reno")
    inst.AnimState:SetBuild("permit_kitchen_reno")
    inst.AnimState:PlayAnimation("idle")

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("roombuilder")

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("construction_permit_kitchen", fn, assets)
