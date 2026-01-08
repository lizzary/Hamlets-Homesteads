GLOBAL.setfenv(1, GLOBAL)

-- 室内光照计算函数
function CalculateLight(light, dist)
    if dist > light:GetCalculatedRadius() then
        return 0, 0, 0
    end
    -- thanks to HalfEnder776
    local A = math.log(light:GetIntensity())
    local B
    local C
    local D
    local r, g, b = light:GetColour()

    if A == 0 then
        if dist > light:GetRadius() then
            D = 0
        else
            D = 1
        end
    elseif A < 0 then
        B = -(light:GetFalloff() / A)
        C = (dist / light:GetRadius()) ^ B
        D = math.exp(A * C)
    else -- A > 0
        D = 0
    end

    return D * r, D * g, D * b
end

-- 室内光照检测
local Sim = getmetatable(TheSim).__index
local old_GetLightAtPoint = Sim.GetLightAtPoint
Sim.GetLightAtPoint = function(sim, x, y, z, light_threshold, ...) -- 和原版GetLightAtPoint的算法还是存在差别
    if TheWorld and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        local position = Vector3(x, y, z)
        local center = TheWorld.components.interiorspawner:GetInteriorCenter(position)
        if center then
            local sum = 0
            local center_position = center:GetPosition()
            for _, v in ipairs(TheSim:FindEntities(center_position.x, 0, center_position.z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"INLIMBO"})) do
                if v.Light and v.Light:IsEnabled() then
                    local _r, _g, _b = CalculateLight(v.Light, math.sqrt(v:GetPosition():DistSq(position)))
                    sum = sum + 0.2126 * _r + 0.7152 * _g + 0.0722 * _b
                    if light_threshold and (sum >= light_threshold) then
                        return sum
                    end
                end
            end
            return sum
        end
    end
    return old_GetLightAtPoint(sim, x, y, z, light_threshold, ...)
end

local _CanEntitySeeTarget = CanEntitySeeTarget
function CanEntitySeeTarget(inst, target, ...)
    if inst and inst.player_classified then
        if target and target:IsValid() and inst.components.persistencevision and inst.components.persistencevision.persistence_ents[target] then
            return true
        end
    end
    return _CanEntitySeeTarget(inst, target, ...)
end
