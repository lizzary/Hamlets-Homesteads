local function onhammered_scaffold(inst,worker)

    if worker and worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) and
            worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS):HasTag("hammer") then

        TheWorld.components.interiorspawner:RemoveInteriorById(inst.interiorID,inst.exterior_pos)

        SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
        inst:Remove()

    else
        inst.components.workable:SetWorkLeft(5)
    end
end

--在fixable组件做的数据传递
local function onconstructed_scaffold(inst)
    print("playerhouse_reconstruction construct")
    if inst.components.constructionsite:IsComplete() and inst.reconstruction_prefab then
        local reconstructed = SpawnPrefab(inst.reconstruction_prefab)
        print("onconstructed_scaffold: ",type(inst.reconstruction_prefab)," ",inst.reconstruction_prefab)
        reconstructed.Transform:SetPosition(inst.Transform:GetWorldPosition())

        reconstructed.interiorID = inst.interiorID
        print("reconstructed.interiorID: ",reconstructed.interiorID)

        if reconstructed.interiorID then
            TheWorld.components.interiorspawner:TransferExterior(inst, reconstructed)
        end
        reconstructed.AnimState:PlayAnimation("reconstruct")
        reconstructed.AnimState:PushAnimation("idle")


        if inst.reconstruction_overridebuild then
            reconstructed.AnimState:AddOverrideBuild(inst.reconstruction_overridebuild)
        end

        reconstructed.bought = inst.bought

        if reconstructed.OnReconstructe then
            reconstructed:OnReconstructe()
        end
        inst:Remove()
    else
        inst.components.workable:SetWorkLeft(5)
    end
end

-- 添加保存函数
local function OnSave(inst, data)
    data.reconstruction_prefab = inst.reconstruction_prefab
    data.interiorID = inst.interiorID
    data.exterior_pos = inst.exterior_pos
    data.bought = inst.bought
    data.reconstruction_overridebuild = inst.reconstruction_overridebuild

end

-- 添加加载函数
local function OnLoad(inst, data)
    if data then
        inst.reconstruction_prefab = data.reconstruction_prefab
        inst.interiorID = data.interiorID
        inst.exterior_pos = data.exterior_pos
        inst.bought = data.bought or false
        inst.reconstruction_overridebuild = data.reconstruction_overridebuild
    end
end

local function MakeReconstructionProject()
    local assets = {
        Asset("ANIM", "anim/pighouse_rubble.zip"),
    }

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        inst.MiniMapEntity:SetIcon("pig_house_sale.tex")

        inst.AnimState:SetBank("pighouse_rubble")
        inst.AnimState:SetBuild("pighouse_rubble")
        inst.AnimState:PlayAnimation("rubble")

        inst:AddTag("playerhouse_reconstruction")
        inst:AddTag("antlion_sinkhole_blocker") -- 阻止蚁狮沙坑生成

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("constructionsite")
        inst.components.constructionsite:SetConstructionPrefab("construction_container")  -- 设置建筑容器
        inst.components.constructionsite:SetOnConstructedFn(onconstructed_scaffold)      -- 设置建造完成回调

		-- 添加可工作组件（允许玩家用锤子等工具交互）
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)   -- 设置工作动作为锤击
        inst.components.workable:SetWorkLeft(5)                  -- 设置需要的工作次数
        --inst.components.workable:SetOnWorkCallback(onhit_scaffold)       -- 设置工作回调（每次锤击）
        inst.components.workable:SetOnFinishCallback(onhammered_scaffold) -- 设置完成回调（完全破坏）


        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        return inst
    end

    return Prefab("playerhouse_reconstruction", fn, assets)
end

return MakeReconstructionProject()
