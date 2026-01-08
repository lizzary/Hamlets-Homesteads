local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

local ACTION_BUTTON_NO_TAGS = {"DECOR", "INLIMBO", "fire", "burnt", "FX"}
local ACTION_BUTTON_ONE_OF_TAGS = {"door", "interior_door"}
local WORK_ACTIONS = {"CHOP", "DIG", "HAMMER", "MINE", "HACK"}

local function get_action(target)
    if target:HasActionComponent("door")
        and not target:HasTag("door_hidden")
        and not target:HasTag("door_disabled")
        and not (target:HasTag("burnt") or target:HasTag("fire")) then
        return ACTIONS.USEDOOR
    end
    for _, work_action in ipairs(WORK_ACTIONS) do
        if target:HasTag(work_action .. "_workable") then
            return ACTIONS[work_action]
        end
    end
end

local function ActionButtonOverride(inst, force_target)
    if inst.components.playercontroller:IsDoingOrWorking() then
        return nil, false
    end
    local is_direct_walking = inst.components.playercontroller.directwalking
    local action_dist = not force_target and (is_direct_walking and 3 or 6) or (is_direct_walking and 9 or 36)
    local x, y, z = inst.Transform:GetWorldPosition()
    local action_target = TheSim:FindEntities(x, y, z, action_dist, nil, ACTION_BUTTON_NO_TAGS, ACTION_BUTTON_ONE_OF_TAGS)
    for i, v in ipairs(action_target) do
        if v ~= inst and v.entity:IsVisible() and CanEntitySeeTarget(inst, v) then
            local action = get_action(v)
            if action ~= nil then
                return BufferedAction(inst, v, action)
            end
        end
    end
    return nil, false
end

AddPrefabPostInit("player_classified", function(inst)
    if not TheNet:IsDedicated() then
        local player = inst.entity:GetParent()
        if player then
            player.components = player.components or {}
            player.components.playercontroller = player.components.playercontroller or {}
            player.components.playercontroller.actionbuttonoverride = ActionButtonOverride
        end
    end
end)
