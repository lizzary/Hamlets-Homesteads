local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("world", function(inst)
    if not TheWorld.components.interiorspawner then
        inst:AddComponent("interiorspawner")
    end

    if not TheWorld.components.roomsystem then
        inst:AddComponent("roomsystem")
    end

    if not TheNet:IsDedicated() then
        inst:AddComponent("interiorhudindicatablemanager")
    end

    if not TheWorld.ismastersim then
        return
    end

    if not TheWorld.components.worldtimetracker then
        inst:AddComponent("worldtimetracker")
    end

    -- 这里为原版室内鸟类生成打了补丁
    inst:DoTaskInTime(0, function()
        if not inst.components.interiorspawner then
            inst:AddComponent("interiorspawner")
        end

        local bsp = inst.components.birdspawner
        if not bsp or bsp._interior_patch then
            return
        end
        bsp._interior_patch = true

        local function IsInterior(x, z)
            local isp = inst.components.interiorspawner
            return isp and isp:IsInInteriorRegion(x, z) and isp:IsInInteriorRoom(x, z)
        end

        local _SpawnBird = bsp.SpawnBird
        function bsp:SpawnBird(spawnpoint, ignorebait)
            if spawnpoint then
                local x, _, z = spawnpoint:Get()
                if IsInterior(x, z) then
                    return nil -- 室内禁止生成鸟类
                end
            end
            return _SpawnBird(self, spawnpoint, ignorebait)
        end

        print("室内已经禁用鸟类生成")
    end)
end)

-- 禁用室内雨滴效果，这一部分应该没生效，后来改了另一个文件最后禁用了

-- 自己添加的补丁：禁止室内放置特定物品
local function BanInteriorDeployment(prefab_name, item_name)
    AddPrefabPostInit(prefab_name, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:DoTaskInTime(0, function()
            if not inst.components.deployable then
                return
            end

            local _CanDeploy = inst.components.deployable.CanDeploy
            function inst.components.deployable:CanDeploy(pt, deployer, ...)
                if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(pt.x, pt.z) then
                    if deployer and deployer.components.talker then
                        deployer.components.talker:Say("不能在室内放置" .. item_name .. "！")
                    end
                    return false
                end
                
                -- 在室外时使用原版逻辑
                return _CanDeploy(self, pt, deployer, ...)
            end

            print("已禁止室内放置" .. item_name)
        end)
    end)
end

-- 禁止室内放置所有可能导致崩溃的蜘蛛卵，在室内放蜘蛛卵，会产生堆栈错误！！！
BanInteriorDeployment("spidereggsack", "蜘蛛卵")