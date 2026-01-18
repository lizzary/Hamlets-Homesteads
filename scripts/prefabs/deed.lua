local assets =
{
    Asset("ANIM", "anim/deed.zip"),
    Asset("ANIM", "anim/pocketwatch_portal_fx.zip")
}

------------添加宝石-------------------------
local MAX_GEM_STORE = 20
local function AddGem(inst,gem_num)
    inst.purplegem = (inst.purplegem or 0) + (gem_num or 1)
    if inst.purplegem <= 0 then
        inst.components.named:SetName(STRINGS.NAMES.DEED)
    else
        inst.components.named:SetName(STRINGS.NAMES.DEED .. " " .. tostring(inst.purplegem) .. "/" .. tostring(MAX_GEM_STORE))
    end
end
local function UseGem(inst,gem_num)
    inst.purplegem = math.max(0, (inst.purplegem or 0) - (gem_num or 1))
    if inst.purplegem <= 0 then
        inst.components.named:SetName(STRINGS.NAMES.DEED)
    else
        inst.components.named:SetName(STRINGS.NAMES.DEED .. " " .. tostring(inst.purplegem) .. "/" .. tostring(MAX_GEM_STORE))
    end
end
local function GetGemNum(inst)
    return inst.purplegem or 0
end
local function Recall_ItemTradeTest(inst, item, giver)
    if item.prefab == "purplegem" then
        inst.purplegem = inst.purplegem or 0
        if inst.purplegem < MAX_GEM_STORE then
            return true
        end
    end

    return false
end

local function Recall_OnGemGiven(inst, giver, item)
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    AddGem(inst,1)
end
----------丢物品出来-----------
local function launchitem(pt,item,giver,angle)
    local x, y, z = pt:Get()
    y = 4.5
    if not angle then
        if giver ~= nil and giver:IsValid() then
            angle = 180 - giver:GetAngleToPoint(x, 0, z)
        else
            local down = TheCamera:GetDownVec()
            angle = math.atan2(down.z, down.x) / DEGREES
            giver = nil
        end
    end
    item.Transform:SetPosition(x, y, z)
    local speed = math.random() * 4 + 2
    angle = (angle + math.random() * 60 - 30) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end
-----------时间裂隙---------------------
--检查出口位置是否可用的函数：
--不能靠近洞穴入口
--1单位半径内不能有其他实体（FX和INLIMBO标签的除外）
local function noentcheckfn(pt)
    --定义检查位置是否可用时忽略的标签
    local NOTENTCHECK_CANT_TAGS = { "FX", "INLIMBO" }
    return not TheWorld.Map:IsPointNearHole(pt) and #TheSim:FindEntities(pt.x, pt.y, pt.z, 1, nil, NOTENTCHECK_CANT_TAGS) == 0
end

local function DestoryDeedOndeploy(deploy_pt,deployer,deed)
    launchitem(deploy_pt, deed)
    local x, y, z = deploy_pt:Get()
    for i = 1, 10 do
        if i < 6 then
            local lighting = SpawnPrefab("lightning")
            lighting.Transform:SetPosition(x + math.random(-10, 10), y, z + math.random(-10, 10))
        end
        launchitem(deploy_pt, SpawnPrefab("nightmarefuel"), nil, math.random(1, 364))
    end
    deed.components.burnable:Ignite()
    deployer.components.talker:Say(STRINGS.ACTIONS.DEPLOY_DEED_NO_HOUSE)
end

local function ondeploy(inst, pt, deployer)
    print("is cave: ",TheWorld:HasTag("cave"),"share id: ",TheShard:GetShardId())
    local inventory = deployer.components.inventory or deployer.components.container

    if not inst.components.rechargeable:IsCharged() then
        inventory:GiveItem(inst)
        inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
        deployer.components.talker:Say(STRINGS.ACTIONS.DEPLOY_DEED_CD)
        return
    end

    if inst.purplegem == nil or inst.purplegem <= 0 then
        inventory:GiveItem(inst)
        inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
        deployer.components.talker:Say(STRINGS.ACTIONS.DEPLOY_DEED_NO_GEM)
        return
    end

    local bindinghouse = inst.components.bindinghouse
    if bindinghouse:IsMarked() then
        --跨世界的房子存在检测搞不定
        if TheShard:GetShardId() ~= bindinghouse.recall_worldid then
            inventory:GiveItem(inst)
            inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
            deployer.components.talker:Say(STRINGS.ACTIONS.DEPLOY_DEED_CROSS_WORLD)
            return
        end
        if bindinghouse:CheckHouseExist() then
            -- 放置时空裂隙
            local portal = SpawnPrefab("pocketwatch_portal_entrance")
            local x, y, z = pt:Get()
            portal.Transform:SetPosition(x, y, z)
            inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
            -- 放置出口
            local _x,_y,_z = bindinghouse:GetMarkedPosition()
            local _pt = {x=_x,y=_y,z=_z}
            local offset = FindWalkableOffset(_pt, math.random() * TWOPI, 3 + math.random(), 16, false, true, noentcheckfn, true, true)
                    or FindWalkableOffset(_pt, math.random() * TWOPI, 5 + math.random(), 16, false, true, noentcheckfn, true, true)
                    or FindWalkableOffset(_pt, math.random() * TWOPI, 7 + math.random(), 16, false, true, noentcheckfn, true, true)
            if offset ~= nil then
                _pt = _pt + offset
            end
            portal:SpawnExit(bindinghouse.recall_worldid, _pt.x, _pt.y, _pt.z)
            --消耗宝石并返还
            UseGem(inst,1)
            inst.components.rechargeable:SetCharge(0)
            inventory:GiveItem(inst)

        --房子不存在就销毁证书
        else
            DestoryDeedOndeploy(pt,deployer,inst)
        end
    else --空证书
        inventory:GiveItem(inst)
        inst.SoundEmitter:PlaySound("wanda1/wanda/portal_entrance_pre")
        deployer.components.talker:Say(STRINGS.ACTIONS.REVEAL_MAP_FAIL)
    end

end

local function onbinding(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/beam_level_up")
    inst.AnimState:PlayAnimation("binding_finish")
    inst.AnimState:PushAnimation("idle", false)
end
------------地图功能-------------------------
local function GetTargetPosition(inst, doer)
    local x,y,z = inst.components.bindinghouse:GetMarkedPosition()
    return {x=x,y=y,z=z}
end

local function PreRevealCheck(inst, doer)
    local bindinghouse = inst.components.bindinghouse
    if bindinghouse:IsMarked() and bindinghouse:CheckHouseExist() then
        return true
    end

    if not bindinghouse:IsMarked() then
        doer.components.talker:Say(STRINGS.ACTIONS.REVEAL_MAP_FAIL)
    end

    doer.components.talker:Say(STRINGS.ACTIONS.REVEAL_MAP_FAIL_NO_HOUSE)

    return false
end
---------------其他--------------------------------
local function OnBurntUp(inst, data)
    --SpawnPrefab("ash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    for i = 1,5 do
        launchitem(inst:GetPosition(),SpawnPrefab("ash"),nil,math.random(1, 365))
    end
end

local function OnSave(inst, data)
    data.purplegem = inst.purplegem
end

local function OnLoad(inst, data)
    if data then
        if data.purplegem then
            inst.purplegem = data.purplegem
        end
    end
end
-----------------------------------------
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("deed")
    inst.AnimState:SetBuild("deed")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("usedeploystring")
    inst:AddTag("deed")
    inst.pickupsound = "gem"
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("named")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.foleysound = "dontstarve/movement/foley/jewlery"

    inst:AddComponent("tradable") --可交易

    inst:AddComponent("deployable") --放时空裂隙
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.placer = "pocketwatch_portal_entrance"
    inst.components.deployable.ondeploy = ondeploy

    inst:AddComponent("mapspotrevealer") --地图揭示
    inst.components.mapspotrevealer:SetGetTargetFn(GetTargetPosition)
    inst.components.mapspotrevealer:SetPreRevealFn(PreRevealCheck)

    inst:AddComponent("trader") --接受宝石
    inst.components.trader:SetAbleToAcceptTest(Recall_ItemTradeTest)
    inst.components.trader.onaccept = Recall_OnGemGiven

    inst:AddComponent("rechargeable") -- 添加cd
    inst.components.rechargeable:SetChargeTime(480) --充能到满时间要480秒
    inst.components.rechargeable:SetCharge(inst.components.rechargeable.total) --初始充能值是满

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL

    inst:AddComponent("bindinghouse")

    inst.OnBinding = onbinding
    MakeHauntableLaunch(inst)
    MakeLargeBurnable(inst, nil, nil, true) -- 这个里面会主动加burnable组件
    inst:ListenForEvent("burntup", OnBurntUp)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

return Prefab("deed", fn, assets),
        MakePlacer("deed_placer","pocketwatch_portal_fx","pocketwatch_portal_fx","portal_entrance_loop",true,nil,nil,nil,90,nil)

