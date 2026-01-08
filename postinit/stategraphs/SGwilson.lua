local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1, GLOBAL)

require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.RENOVATE, "dolongaction"),
    ActionHandler(ACTIONS.TAKEFROMSHELF, "doshortaction"),
    ActionHandler(ACTIONS.PUTONSHELF, "doshortaction"),
    ActionHandler(ACTIONS.USEDOOR, "usedoor"),
    ActionHandler(ACTIONS.BUILD_ROOM, "doshortaction"),
    ActionHandler(ACTIONS.DEMOLISH_ROOM, "doshortaction"),
}

local eventhandlers = {
    -- 暂时不需要额外的事件处理器
}

local states = {
    State{
        name = "usedoor",
        tags = {"doing", "busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")
            inst.AnimState:PushAnimation("give_pst", false)
            if inst.components.playercontroller then
                inst.components.playercontroller:Enable(false)
            end

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            if target and target.components.door then
                inst:ForceFacePoint((inst:GetPosition() - target.components.door:GetOffsetPos()):Get())
            end
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                local buffaction = inst:GetBufferedAction()
                local target = buffaction ~= nil and buffaction.target or nil
                if target and not target.components.door:IsLocked() then
                    inst:ScreenFade(false, 0.4)
                    inst.sg.mem.screenfaded = true
                end
                inst:DoStaticTaskInTime(0.6, function()
                    if inst.sg.mem.screenfaded then
                        inst:ScreenFade(true, 0.4)
                        inst.sg.mem.screenfaded = false
                    end
                end)
            end),

            TimeEvent(15 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),

            TimeEvent(19 * FRAMES, function(inst)
                if inst.components.playercontroller then
                    inst.components.playercontroller:Enable(true)
                end
                inst.sg:RemoveStateTag("busy")
            end),

            TimeEvent(30 * FRAMES, function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if inst.components.playercontroller then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
            if inst.sg.mem.screenfaded then
                inst:ScreenFade(true, 0.4)
                inst.sg.mem.screenfaded = false
            end
        end,
    },
}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson", state)
end

AddStategraphPostInit("wilson", function(sg)
    -- 房间门锤击保护，也就是室内有人，或者有多个房间时，禁止玩家锤击
    local _hammer_start_onenter = sg.states["hammer_start"].onenter
    sg.states["hammer_start"].onenter = function(inst, ...)
        local action = inst:GetBufferedAction()
        if action and action.target:HasTag("interior_door") and action.target:HasTag("house_door") and not action.target:DoorCanBeRemoved() then
            inst:ClearBufferedAction()
            inst.components.talker:Say(GetString(inst.prefab, "ANNOUNCE_ROOM_STUCK"))
            inst.sg:GoToState("talk")
        else
            return _hammer_start_onenter(inst, ...)
        end
    end

    local function ClearLimitedChairState(inst)
        inst:RemoveTag("sitting_on_chair")
        inst:RemoveTag("limited_sitting")
        
        inst.Transform:SetFourFaced()
        
        inst.AnimState:SetBank("wilson")
        
        inst.AnimState:MakeFacingDirty()
        
        inst:DoTaskInTime(0.1, function(inst)
            if inst:IsValid() and not inst:HasTag("sitting_on_chair") then
                inst.Transform:SetFourFaced()
                inst.AnimState:MakeFacingDirty()
            end
        end)
    end
--这一部分很头疼，因为不知道是删除了什么导致人物从室内斜着坐的椅子下来后人物会一直面朝一个方向，后来改了家具的标签解决了
    local _stop_sitting_onexit = sg.states["stop_sitting"].onexit
    sg.states["stop_sitting"].onexit = function(inst, ...)
        local was_limited_chair = inst.sg.statemem.chair and 
                                 inst.sg.statemem.chair:HasTag("limited_chair")
        
        if _stop_sitting_onexit ~= nil then
            _stop_sitting_onexit(inst, ...)
        end
        
        if was_limited_chair then
            ClearLimitedChairState(inst)
        end
    end

    if sg.states["sit_jumpoff"] and sg.states["sit_jumpoff"].onexit then
        local _sit_jumpoff_onexit = sg.states["sit_jumpoff"].onexit
        sg.states["sit_jumpoff"].onexit = function(inst, ...)
            local was_limited_chair = inst.sg.statemem.chair and 
                                     inst.sg.statemem.chair:HasTag("limited_chair")
            
            if _sit_jumpoff_onexit ~= nil then
                _sit_jumpoff_onexit(inst, ...)
            end
            
            if was_limited_chair then
                ClearLimitedChairState(inst)
            end
        end
    end

    if sg.states["stop_sitting_pst"] then
        local _stop_sitting_pst_onenter = sg.states["stop_sitting_pst"].onenter
        sg.states["stop_sitting_pst"].onenter = function(inst, ...)
            if _stop_sitting_pst_onenter ~= nil then
                _stop_sitting_pst_onenter(inst, ...)
            end
            
            if inst:HasTag("limited_sitting") then
                ClearLimitedChairState(inst)
            end
        end
    end

    local _idle_onenter = sg.states["idle"].onenter
    sg.states["idle"].onenter = function(inst, ...)
        if inst:HasTag("limited_sitting") and not inst:HasTag("sitting_on_chair") then
            ClearLimitedChairState(inst)
        end
        
        if _idle_onenter ~= nil then
            return _idle_onenter(inst, ...)
        end
    end
end)
