GLOBAL.setfenv(1, GLOBAL)

local _MakeInventoryPhysics = MakeInventoryPhysics
function MakeInventoryPhysics(inst, mass, rad, ...)
    local physics = _MakeInventoryPhysics(inst, mass, rad, ...)
    return physics
end

local _ChangeToInventoryItemPhysics = ChangeToInventoryItemPhysics
function ChangeToInventoryItemPhysics(inst, mass, rad, ...)
    local physics = _ChangeToInventoryItemPhysics(inst, mass, rad, ...)
    return physics
end

local _ChangeToCharacterPhysics = ChangeToCharacterPhysics
function ChangeToCharacterPhysics(inst, mass, rad, ...)
    local physics = _ChangeToCharacterPhysics(inst, mass, rad, ...)
    if mass then
        physics:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return physics
end

local _RemovePhysicsColliders = RemovePhysicsColliders
function RemovePhysicsColliders(inst, ...)
    _RemovePhysicsColliders(inst, ...)
    local physics = inst.Physics
    if not physics then
        return
    end
    return physics
end

function ChangeToJunmpingPhysics(inst, mass, rad)
    local phys = inst.Physics
    if mass then
        phys:SetMass(mass)
        phys:SetFriction(0)
    end
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    if rad then
        phys:SetCapsule(rad, 1)
    end
    if mass then
        phys:SetDamping(5) -- 最后执行摩擦力, 否则会出问题. 例如联机版的鬼魂漂移bug
    end
    return phys
end

function MakePoisonableCharacter(inst, sym, offset, fxstyle, damage_penalty, attack_period_penalty, speed_penalty, hunger_burn, sanity_scale)
end


function MakeHauntableDoor(inst)
    if not inst.components.door then
        print("Warning: Trying to call MakeHauntableDoor without door component")
        return
    end

    if not inst.components.hauntable then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, player)
        inst:PushEvent("open")
    end)
end

function MakeHauntableVineDoor(inst)
    if not inst.components.hackable and not inst.components.vineable then
        print("Warning: Trying to call MakeHauntableVineDoor without hackable or vineable component")
        return
    end

    if not inst.components.hauntable then
        inst:AddComponent("hauntable")
    end
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL
    inst.components.hauntable:SetOnHauntFn(function(inst, player)
        if math.random() <= TUNING.HAUNT_CHANCE_OFTEN then
            if inst.components.vineable and inst.components.vineable.vines and
                inst.components.vineable.vines.components.hackable and inst.components.vineable.vines.stage > 0 then
                    inst.components.vineable.vines.components.hackable:WorkedBy(player, 1)
            elseif inst.components.hackable and inst.stage > 0 then -- 内部门用vineable, 外部门用hackable...需要代码清理
                inst.components.hackable:WorkedBy(player, 1)
            end
        end
        return false
    end)
end

local function build_rectangle_collision_mesh(rad, height, width)
    local points = {
        Vector3(-width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, -rad / 2),
        Vector3(width / 2, 0, rad / 2),
        Vector3(-width / 2, 0, rad / 2),
    }
    local triangles = {}
    local y0 = 0
    local y1 = height
    for i = 1, 4 do
        local p1 = points[i]
        local p2 = points[i == 4 and 1 or i + 1]

        table.insert(triangles, p1.x)
        table.insert(triangles, y0)
        table.insert(triangles, p1.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y0)
        table.insert(triangles, p2.z)

        table.insert(triangles, p1.x)
        table.insert(triangles, y1)
        table.insert(triangles, p1.z)

        table.insert(triangles, p2.x)
        table.insert(triangles, y1)
        table.insert(triangles, p2.z)
    end

    return triangles
end

function MakeInteriorPhysics(inst, rad, height, width)
    height = height or 20

    inst:AddTag("blocker")
    inst.Physics = inst.Physics or inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetTriangleMesh(build_rectangle_collision_mesh(rad, height, width or rad))
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
end

function MakeInteriorWallPhysics(inst, rad, height, width)
    height = height or 20

    inst:AddTag("blocker")
    inst.Physics = inst.Physics or inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetTriangleMesh(build_rectangle_collision_mesh(rad, height, width or rad))
    inst.Physics:SetCollisionGroup(COLLISION.GROUND)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.FLYERS)
end

-- 重写积雪系统，使室内建筑不显示积雪效果
local _MakeSnowCovered = MakeSnowCovered
function MakeSnowCovered(inst, ...)
    _MakeSnowCovered(inst, ...)
    
    if not inst:HasTag("SnowCovered") then
        return
    end

    local function UpdateSnowEffect(inst)
        if not inst:IsValid() or not inst:HasTag("SnowCovered") then
            return
        end
        
        -- 检查是否有月亮碎片覆盖，如果有，则不处理积雪效果
        if inst.components.lunarhailbuildup and inst.components.lunarhailbuildup:GetBuildupPercent() > 0 then
            return
        end

        if not TheWorld or not TheWorld.ismastersim then
            return
        end
        
        local is_in_interior = false
        if inst.GetIsInInterior then
            is_in_interior = inst:GetIsInInterior()
        elseif inst:HasTag("inside_interior") then
            is_in_interior = true
        elseif TheWorld.components and TheWorld.components.interiorspawner then
            local x, _, z = inst.Transform:GetWorldPosition()
            is_in_interior = TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
        end
        
        if is_in_interior then
            inst.AnimState:Hide("snow")
        else

            if TheWorld.state and TheWorld.state.issnowcovered then
                inst.AnimState:Show("snow")
            else
                inst.AnimState:Hide("snow")
            end
        end
    end
    

    if inst.DoTaskInTime then
        inst:DoTaskInTime(0.1, function()
            UpdateSnowEffect(inst)
            
            if inst.Listen then
                inst:ListenForEvent("enterinterior", function(inst, data)
                    UpdateSnowEffect(inst)
                end)
                
                inst:ListenForEvent("leaveinterior", function(inst, data)
                    UpdateSnowEffect(inst)
                end)
                
                if TheWorld and TheWorld.state then
                    inst:WatchWorldState("issnowcovered", function(world)
                        UpdateSnowEffect(inst)
                    end)
                end
            end
            
            if inst.DoPeriodicTask then
                inst:DoPeriodicTask(30, function() 
                    UpdateSnowEffect(inst)
                end)
            end
        end)
    end
end








