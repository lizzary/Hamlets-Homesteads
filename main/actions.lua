local AddAction = AddAction
local AddComponentAction = AddComponentAction
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

if not rawget(_G, "HotReloading") then
    _G.PL_ACTIONS = {
        USEDOOR = Action({priority = 1, mount_valid = false, ghost_valid = true, encumbered_valid = true}),
        PUTONSHELF = Action({ distance = 1.5 }),
        TAKEFROMSHELF = Action({ distance = 1.5, priority = 1 }),
        RENOVATE = Action({}),
        BUILD_ROOM = Action({}),
        DEMOLISH_ROOM = Action({}),
    }

    for name, ACTION in pairs(_G.PL_ACTIONS) do
        ACTION.id = name
        ACTION.str = STRINGS.ACTIONS[name] or name
        AddAction(ACTION)
    end
end

----set up the action functions

ACTIONS.USEDOOR.fn = function(act)
    local door = act.target
    if not door or not door.components.door then
        return false
    end
    if door.components.door:IsLocked() then
        return false, "LOCKED"
    end
    return door.components.door:Activate(act.doer)
end



ACTIONS.PUTONSHELF.fn = function(act)
    local shelf = act.target.components.visualslot:GetShelf()

    if shelf.components.container ~= nil and act.invobject.components.inventoryitem ~= nil then
        local item = act.invobject.components.inventoryitem:RemoveFromOwner(shelf.components.container.acceptsstacks)
        local success = shelf.components.container:GiveItem(item, act.target.components.visualslot:GetSlot(), nil, false)
        if item:HasTag("small_livestock") then 
            if act.doer and item:HasTag("canbetrapped") then
                local d_pos = act.doer:GetPosition()
                local s_pos = shelf:GetPosition()
                shelf.components.container:DropItemBySlot(act.target.components.visualslot:GetSlot(), (d_pos + s_pos) / 2)
            else
                shelf.components.container:DropItemBySlot(act.target.components.visualslot:GetSlot(), shelf:GetPosition())
            end
        end
        return success
    end
end

ACTIONS.PUTONSHELF.stroverridefn = function(act)
    return STRINGS.ACTIONS.STORE.GENERIC
end

ACTIONS.TAKEFROMSHELF.fn = function(act)
    local shelf = act.target.components.visualslot:GetShelf()

    if shelf.components.lock and shelf.components.lock:IsLocked() then
        return false
    end

    if shelf.components.container then
        local item = shelf.components.container:RemoveItemBySlot(act.target.components.visualslot:GetSlot())
        act.doer.components.inventory:GiveItem(item, nil, act.doer:GetPosition())

        return true
    end
end



ACTIONS.RENOVATE.fn = function(act)
    if act.target:HasTag("renovatable") then
        if act.invobject.components.renovator then
            act.invobject.components.renovator:Renovate(act.target)
        end

        act.invobject:Remove()

        return true
    end
end

ACTIONS.BUILD_ROOM.fn = function(act)
    if act.invobject.components.roombuilder and act.target:HasTag("predoor") then
        return act.invobject.components.roombuilder:BuildRoom(act.target, act.invobject)
    end
    return false
end

ACTIONS.DEMOLISH_ROOM.fn = function(act)
    if act.invobject.components.roomdemolisher and act.target:HasTag("house_door") and act.target:HasTag("interior_door") then
        return act.invobject.components.roomdemolisher:DemolishRoom(act.doer, act.target, act.invobject)
    end
    return false
end

local PL_COMPONENT_ACTIONS =
{
    SCENE = { -- args: inst, doer, actions, right
        door = function(inst, doer, actions, right)
            if not inst:HasTag("door_hidden") and not inst:HasTag("door_disabled") then
                table.insert(actions, ACTIONS.USEDOOR)
            end
        end,
        visualslot = function(inst, doer, actions, right)
            if not inst:HasTag("empty") then
                local shelf = inst.replica.visualslot:GetShelf()
                if not shelf:HasTag("locked")
                    and inst.replica.visualslot:GetItem() ~= nil
                    and inst.replica.visualslot:GetItem():IsValid() then

                        table.insert(actions, ACTIONS.TAKEFROMSHELF)
                end
            end
        end,
    },

    USEITEM = { -- args: inst, doer, target, actions, right
        renovator = function(inst, doer, target, actions, right)
            if target:HasTag("renovatable") then
                table.insert(actions, ACTIONS.RENOVATE)
            end
        end,
        roombuilder = function(inst, doer, target, actions, right)
            if target:HasTag("predoor") then
                table.insert(actions, ACTIONS.BUILD_ROOM)
            end
        end,
        roomdemolisher = function(inst, doer, target, actions, right)
            if target:HasTag("interior_door") and target:HasTag("house_door") then
                table.insert(actions, ACTIONS.DEMOLISH_ROOM)
            end
        end,
    },

    POINT = { -- args: inst, doer, pos, actions, right, target
    },

    EQUIPPED = { -- args: inst, doer, target, actions, right
    },

    INVENTORY = { -- args: inst, doer, actions, right
    },

    ISVALID = { -- args: inst, action, right
    },
}

for actiontype, actons in pairs(PL_COMPONENT_ACTIONS) do
    for component, fn in pairs(actons) do
        AddComponentAction(actiontype, component, fn)
    end
end

-- hack
local COMPONENT_ACTIONS = ToolUtil.GetUpvalue(EntityScript.CollectActions, "COMPONENT_ACTIONS")
local SCENE = COMPONENT_ACTIONS.SCENE
local USEITEM = COMPONENT_ACTIONS.USEITEM
local POINT = COMPONENT_ACTIONS.POINT
local EQUIPPED = COMPONENT_ACTIONS.EQUIPPED
local INVENTORY = COMPONENT_ACTIONS.INVENTORY



local _USEITEM_inventoryitem = USEITEM.inventoryitem
function USEITEM.inventoryitem(inst, doer, target, actions, right, ...)
    if inst.replica.inventoryitem ~= nil then
        if not inst.replica.inventoryitem:CanOnlyGoInPocket() then
            if target:HasTag("visual_slot") then
                if target:HasTag("empty") then
                        table.insert(actions, ACTIONS.PUTONSHELF)
                        return
                end
            end
        end
    end
    return _USEITEM_inventoryitem(inst, doer, target, actions, right, ...)
end

local PlayerController = require("components/playercontroller")

local NON_AUTO_EQUIP_ACTIONS = {
    [ACTIONS.PUTONSHELF] = true,
}

local do_action_auto_equip = PlayerController.DoActionAutoEquip
function PlayerController:DoActionAutoEquip(buffaction, ...)
    if NON_AUTO_EQUIP_ACTIONS[buffaction.action] then
        return
    end
    return do_action_auto_equip(self, buffaction, ...)
end

function PLENV.OnHotReload()
    USEITEM.inventoryitem = _USEITEM_inventoryitem
end
