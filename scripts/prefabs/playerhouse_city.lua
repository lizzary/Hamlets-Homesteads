local GetPropDef = require("prefabs/interior_prop_defs")
require "prefabutil"
require "recipes"
local roomsystem = require("components/roomsystem")

local assets = {
    Asset("ANIM", "anim/pig_house_sale.zip"),
    Asset("ANIM", "anim/player_small_house1.zip"),
    Asset("ANIM", "anim/player_large_house1.zip"),

    Asset("ANIM", "anim/player_large_house1_manor_build.zip"),
    Asset("ANIM", "anim/player_large_house1_villa_build.zip"),
    Asset("ANIM", "anim/player_small_house1_cottage_build.zip"),
    Asset("ANIM", "anim/player_small_house1_tudor_build.zip"),
    Asset("ANIM", "anim/player_small_house1_gothic_build.zip"),
    Asset("ANIM", "anim/player_small_house1_brick_build.zip"),
    Asset("ANIM", "anim/player_small_house1_turret_build.zip"),

    Asset("MINIMAP_IMAGE", "player_house_brick"),
    Asset("MINIMAP_IMAGE", "player_house_cottage"),
    Asset("MINIMAP_IMAGE", "player_house_gothic"),
    Asset("MINIMAP_IMAGE", "player_house_manor"),
    Asset("MINIMAP_IMAGE", "player_house_tudor"),
    Asset("MINIMAP_IMAGE", "player_house_turret"),
    Asset("MINIMAP_IMAGE", "player_house_villa"),

    Asset("MINIMAP_IMAGE", "pig_house_sale"),

    Asset("SOUND", "sound/pig.fsb"),
}

local prefabs = {
    "renovation_poof_fx",
}

local function setScale(inst, build)
    inst.AnimState:SetScale(0.75, 0.75, 0.75)
end

local function getstatus(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst.bought then
        return "SOLD"
    else
        return "FORSALE"
    end
end
local function ondestory(inst)
    inst.components.lootdropper:DropLoot()

    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()

end
local function onhammered(inst, worker)

    if inst:HasTag("fire") and inst.components.burnable then
        inst.components.burnable:Extinguish()
    end

    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end

    if not inst.components.fixable then
        inst.components.lootdropper:DropLoot()
    end

    SpawnPrefab("collapse_big").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
    inst:Remove()
end

local function onhit(inst, worker)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("idle")

        -- 被砸的时候掉一些原材料
        local random = math.random()
        if random < 0.5 then
            if worker ~= nil and worker.components.locomotor ~= nil then
                inst.components.lootdropper:SetFlingTarget(worker:GetPosition(), 45)
            else
                inst.components.lootdropper:SetFlingTarget(nil, nil)
            end
            local loot
            if random < 0.25 then
                loot = inst.components.lootdropper:SpawnLootPrefab(Ingredient("cutstone", 1).type)
            else
                loot = inst.components.lootdropper:SpawnLootPrefab(Ingredient("boards", 1).type)

            end
            local x, y, z = loot.Transform:GetWorldPosition()
            loot.Physics:Teleport(x, 2 + math.random(), z)
        end
    end
end

local function onbuilt(inst)
    inst.build_by_player = true
    inst.AnimState:PlayAnimation("build")
    inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
    inst.AnimState:PushAnimation("idle")
    inst:BuyHouse()
end

local function BuyHouse(inst)
    inst.AnimState:Hide("boards")
    inst.bought = true
    inst.components.door:SetDoorDisabled(false, "bought_state")

    -- local x, y, z = inst.Transform:GetWorldPosition()
    -- local ents = TheSim:FindEntities(x, y, z, 6)
    -- for _, ent in ipairs(ents) do
    --     if ent.components.citypossession and not ent:HasTag("pig") then
    --         ent.components.citypossession:Disable()
    --     end
    -- end
end

local function CanAcceptGem(inst, item, giver)
    if inst:HasTag("burnt") then
        giver.components.talker:Say(STRINGS.ACTIONS.GIVE_GEM_FAIL_BURN)
        return false
    end
    if not inst.bought then
        giver.components.talker:Say(STRINGS.ACTIONS.GIVE_GEM_FAIL_BUY)
        return false
    end

    local WARMING_STAGE_2 = TheWorld.components.roomsystem.WARMING_STAGE_2
    local COOLING_STAGE_2 = TheWorld.components.roomsystem.COOLING_STAGE_2
    if item.prefab == "redgem" then
        if TheWorld.components.roomsystem:GetHouseWarmingUpgradeStage(inst.interiorID) < WARMING_STAGE_2 then
            return true
        end
        giver.components.talker:Say(STRINGS.ACTIONS.GIVE_RED_GEM_FAIL_LIMIT)
        return false
    end

    if item.prefab == "bluegem" then
        if TheWorld.components.roomsystem:GetHouseCoolingUpgradeStage(inst.interiorID) < COOLING_STAGE_2 then
            return true
        end
        giver.components.talker:Say(STRINGS.ACTIONS.GIVE_BLUE_GEM_FAIL_LIMIT)
        return false
    end

    giver.components.talker:Say(STRINGS.ACTIONS.GIVE_ITEM_FAIL)
    return false
end

local function OnAcceptGem(inst, giver, item)
    --累计到第5颗蓝宝石升级后，室内温度最低为1,累计到第5颗红宝石升级后，室内温度最高为69
    --若同时有10颗红宝石+10颗蓝宝石升级后，室内温度则恒为25
    inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    if item.prefab == "redgem" then
        print("warm upgarde 1")
        TheWorld.components.roomsystem:WarmingUpgrade(inst.interiorID,1)
    end

    if item.prefab == "bluegem" then
        TheWorld.components.roomsystem:CoolingUpgrade(inst.interiorID,1)
    end

end
local function OnReconstructe(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/pighouse_door")
    if inst.bought then
        inst.AnimState:Hide("boards")
        inst.components.door:SetDoorDisabled(false, "bought_state")
    end
end

local function CreateInterior(inst)
    local id = inst.interiorID
    local can_reuse_interior = id ~= nil

    local interior_spawner = TheWorld.components.interiorspawner
    if not can_reuse_interior then
        id = interior_spawner:GetNewID()
        inst.interiorID = id
        print("CreateInterior id:", id)
    end

    local name = "playerhouse" .. id
    local exterior_door_def = {
        my_door_id = name .. "_door",
        target_door_id = name .. "_exit",
        target_interior = id,
    }
    interior_spawner:AddDoor(inst, exterior_door_def)
    interior_spawner:AddExterior(inst)

    if can_reuse_interior then
        -- Reuse old interior, but we still need to re-register the door
        return
    end

    local floortexture = "levels/textures/noise_woodfloor.tex"
    local walltexture = "levels/textures/interiors/shop_wall_woodwall.tex"
    local minimaptexture = "levels/textures/map_interior/mini_floor_wood.tex"
    local colorcube = "images/colour_cubes/pigshop_interior_cc.tex"

    local addprops = GetPropDef("playerhouse_city", exterior_door_def)
    interior_spawner:CreateRoom({
        width = 15,
        height = nil,
        depth = 10,
        dungeon_name = name,
        roomindex = id,
        addprops = addprops,
        exits = {},
        walltexture = walltexture,
        floortexture = floortexture,
        minimaptexture = minimaptexture,
        colour_cube = colorcube,
        playerroom = true,
        reverb = "inside",
        ambient_sound = "HOUSE",
        footstep_tile = WORLD_TILES.WOODFLOOR,
        cameraoffset = nil,
        zoom = nil,
        group_id = inst.interiorID, --playerhouse_city的interiorID就是第一个房间的空间id以及该房子的group_id
        interior_coordinate_x = 0,
        interior_coordinate_y = 0,
    })

    local room = interior_spawner:GetInteriorCenter(id)
    room:AddInteriorTags("home_prototyper")
end

local function UseDoor(inst, data)
    if inst.usesounds then
        if data and data.doer and data.doer.SoundEmitter then
            for i, sound in ipairs(inst.usesounds) do
                data.doer:DoTaskInTime(FRAMES * 2, function()
                    data.doer.SoundEmitter:PlaySound(sound)
                end)
            end
        end
    end
end

-- local function canburn(inst)
--     local interior_spawner = TheWorld.components.interiorspawner
--     if inst.components.door then
--         local interior = inst.components.door.target_interior
--         if interior_spawner:IsPlayerConsideredInside(interior) then
--             -- try again in 2-5 seconds
--             return false, 2 + math.random() * 3
--         end
--     end
--     return true
-- end

local function OnBurntUp(inst, data)
    --inst.components.fixable:AddReconstructionStageData("burnt", "pig_townhouse", inst.build, 0.75, 1)
    if inst.doortask then
        inst.doortask:Cancel()
        inst.doortask = nil
    end
    inst:Remove()
end

local function OnSave(inst, data)
    if inst:HasTag("burnt") then
        data.burnt = true
    end
    data.build = inst.build
    data.animset = inst.animset
    data.bought = inst.bought
    data.interiorID = inst.interiorID
    data.prefabname = inst.prefabname
    data.minimapicon = inst.minimapicon
    data.build_by_player = inst.build_by_player
    data.coolingUpgrade = TheWorld.components.roomsystem:GetHouseCoolingUpgradeStage(inst.interiorID)
    data.warmingUpgrade = TheWorld.components.roomsystem:GetHouseWarmingUpgradeStage(inst.interiorID)
end

local function OnLoad(inst, data)
    if data then
        if data.build_by_player then
            inst.build_by_player = data.build_by_player
        end

        if data.interiorID then
            inst.interiorID = data.interiorID
        end
        CreateInterior(inst)

        if data.build then
            inst.build = data.build
            inst.AnimState:SetBuild(inst.build)
            setScale(inst, inst.build)
        end

        if data.animset then
            inst.animset = data.animset
            inst.AnimState:SetBank(inst.animset)
        end
        if data.bought then
            inst.bought = data.bought
            inst.AnimState:Hide("boards")
            inst.components.door:SetDoorDisabled(false, "bought_state")
        else
            inst.components.door:SetDoorDisabled(true, "bought_state")
        end
        if data.prefabname then
            inst.prefabname = data.prefabname
            inst.name = STRINGS.NAMES[string.upper(data.prefabname)]
        end

        if data.minimapicon then
            inst.minimapicon = data.minimapicon
            inst.MiniMapEntity:SetIcon(inst.minimapicon)
        end

        if data.burnt then
            inst.components.burnable.onburnt(inst)
        end

        if data.coolingUpgrade then
            TheWorld.components.roomsystem:CoolingUpgrade(inst.interiorID,data.coolingUpgrade)
        end

        if data.warmingUpgrade then
            TheWorld.components.roomsystem:WarmingUpgrade(inst.interiorID,data.warmingUpgrade)
        end
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("pig_house_sale.tex")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(1)
    inst.Light:Enable(false)
    inst.Light:SetColour(180 / 255, 195 / 255, 50 / 255)

    MakeObstaclePhysics(inst, 1)

    inst.bought = false

    inst:AddTag("playerhouse")
    inst:AddTag("renovatable")
    inst:AddTag("client_forward_action_target")

    inst.build = "pig_house_sale"
    inst.AnimState:SetBuild(inst.build)

    inst.animset = "pig_house_sale"
    inst.AnimState:SetBank(inst.animset)

    setScale(inst, inst.build)

    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(10)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:AddComponent("door")
    inst.components.door:SetDoorDisabled(true, "bought_state")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    MakeSnowCovered(inst, .01)

    MakeMediumBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)

    MakeHauntableWork(inst)

    -- inst.components.burnable:SetCanActuallyBurnFunction(canburn)
    inst:ListenForEvent("burntup", OnBurntUp)


    inst:AddComponent("fixable")

    --让房子可以接受物品
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(CanAcceptGem)
    inst.components.trader.onaccept = OnAcceptGem
    inst.components.trader.deleteitemonaccept = true  -- 接收后删除物品

    inst.BuyHouse = BuyHouse
    inst:ListenForEvent("deedbought", function() inst:BuyHouse() end, TheWorld)

    inst.interiors = {}
    inst:DoTaskInTime(0, function()
        CreateInterior(inst)
    end)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.build_by_player = false
    inst:DoTaskInTime(0, function()
        if not inst.build_by_player then
            TheWorld.playerhouse = inst
        end
    end)
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("ondestory", ondestory)

    inst.usesounds = {
        "dontstarve/common/together/gate/open",
    }

    inst:ListenForEvent("usedoor", UseDoor)

    --原mod对房屋拆除后的实现
    inst.OnReconstructe = OnReconstructe

    return inst
end

local function HideLayers(inst)
    inst.AnimState:Hide("snow")
    inst.AnimState:Hide("boards")
end

return Prefab("playerhouse_city", fn, assets, prefabs),
    MakePlacer("playerhouse_city_placer", "pig_house_sale", "pig_house_sale", "idle", nil, nil, nil, 0.75, nil, nil, HideLayers)
