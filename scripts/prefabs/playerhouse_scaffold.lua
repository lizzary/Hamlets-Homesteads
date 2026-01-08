
local function onhammered_scaffold(inst)
	local pt = inst:GetPosition()
	--inst.components.lootdropper.spawn_loot_inside_prefab = true
	--inst.components.lootdropper.y_speed = nil
	--inst.components.lootdropper:SetFlingTarget(nil, nil)
	--inst.components.lootdropper:DropLoot(pt)
	--
	--inst.components.constructionsite:DropAllMaterials(pt)

	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(pt:Get())
	fx:SetMaterial("rock")
	inst:Remove()
end

local function onconstructed_scaffold(inst)
	print("scaffold constructed !")
	if inst.components.constructionsite:IsComplete() then

        local new_inst = ReplacePrefab(inst, "playerhouse_city")
		new_inst:PushEvent("onbuilt")

    else
        inst.components.workable:SetWorkLeft(5)
    end
end
local function onbuilt_scaffold(inst, doer)
	print("scaffold build !")
	inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("scaffold", false)
    inst.SoundEmitter:PlaySound("meta2/pillar/scaffold_place")
end



local function MakeScaffold()
	local assets = {
		Asset("ANIM", "anim/pig_house_sale.zip")
	}

	local prefabs = {
		"collapse_big",
		"construction_container",
	}

	local function fn()
		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMiniMapEntity()
		inst.entity:AddNetwork()

		inst.MiniMapEntity:SetIcon("pig_house_sale.tex")
		local PHYSICS_RADIUS = 1.45
		MakeObstaclePhysics(inst, PHYSICS_RADIUS,6)

		inst.AnimState:SetBank("pig_house_sale")      -- 指定动画资源包
		inst.AnimState:SetBuild("pig_house_sale")    -- 指定动画构建文件
		inst.AnimState:PlayAnimation("scaffold")  -- 播放脚手架状态的动画


		inst:AddTag("structure")                -- 标记为结构物
		inst:AddTag("antlion_sinkhole_blocker") -- 阻止蚁狮沙坑生成
		inst:AddTag("constructionsite")         -- 标记为建筑工地（用于优化）

		if not TheWorld.ismastersim then
			return inst
		end

		-- === 以下代码只在主模拟世界（服务端）执行 ===
		inst:AddComponent("constructionsite")
		inst.components.constructionsite:SetConstructionPrefab("construction_container")  -- 设置建筑容器
		inst.components.constructionsite:SetOnConstructedFn(onconstructed_scaffold)      -- 设置建造完成回调

		-- 添加可工作组件（允许玩家用锤子等工具交互）
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)   -- 设置工作动作为锤击
        inst.components.workable:SetWorkLeft(5)                  -- 设置需要的工作次数
        --inst.components.workable:SetOnWorkCallback(onhit_scaffold)       -- 设置工作回调（每次锤击）
        inst.components.workable:SetOnFinishCallback(onhammered_scaffold) -- 设置完成回调（完全破坏）

		inst:ListenForEvent("onbuilt", onbuilt_scaffold)   -- 监听放置事件

		return inst
	end

	return Prefab("playerhouse_scaffold", fn, assets, prefabs)
end

return MakeScaffold()