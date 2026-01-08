local AddStategraphState = AddStategraphState
local AddStategraphEvent = AddStategraphEvent
local AddStategraphPostInit = AddStategraphPostInit
local AddStategraphActionHandler = AddStategraphActionHandler
GLOBAL.setfenv(1, GLOBAL)

local TIMEOUT = 2

local actionhandlers = {
    ActionHandler(ACTIONS.RENOVATE, "dolongaction"),
    ActionHandler(ACTIONS.TAKEFROMSHELF, "doshortaction"),
    ActionHandler(ACTIONS.PUTONSHELF, "doshortaction"),
    ActionHandler(ACTIONS.USEDOOR, "usedoor"),
    ActionHandler(ACTIONS.BUILD_ROOM, "doshortaction"),
    ActionHandler(ACTIONS.DEMOLISH_ROOM, "doshortaction"),
}

local eventhandlers = {
}

local states = {
    State{
        name = "usedoor",
        tags = {"doing", "busy"},
        server_states = {"usedoor"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("give")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)

            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            if target and target.components.door then
                local facing = target.components.door:GetFacingFromTarget(inst)
                if facing then
                    inst.Transform:SetRotation(facing)
                end
            end
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end
    },
}

for _, actionhandler in ipairs(actionhandlers) do
    AddStategraphActionHandler("wilson_client", actionhandler)
end

for _, eventhandler in ipairs(eventhandlers) do
    AddStategraphEvent("wilson_client", eventhandler)
end

for _, state in ipairs(states) do
    AddStategraphState("wilson_client", state)
end

AddStategraphPostInit("wilson_client", function(sg)
    local function ClearLimitedChairState_Client(inst)
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

        local _stop_sitting_onexit_client = sg.states["stop_sitting"].onexit
        sg.states["stop_sitting"].onexit = function(inst, ...)
            local was_limited_chair = inst.sg.statemem.chair and 
                                     inst.sg.statemem.chair:HasTag("limited_chair")
            
            if _stop_sitting_onexit_client ~= nil then
                _stop_sitting_onexit_client(inst, ...)
            end
            
            if was_limited_chair then
                ClearLimitedChairState_Client(inst)
        end
    end

    if sg.states["sit_jumpoff"] and sg.states["sit_jumpoff"].onexit then
        local _sit_jumpoff_onexit_client = sg.states["sit_jumpoff"].onexit  
        sg.states["sit_jumpoff"].onexit = function(inst, ...)
            local was_limited_chair = inst.sg.statemem.chair and 
                                     inst.sg.statemem.chair:HasTag("limited_chair")
            
            if _sit_jumpoff_onexit_client ~= nil then
                _sit_jumpoff_onexit_client(inst, ...)
            end
            
            if was_limited_chair then
                ClearLimitedChairState_Client(inst)
            end
        end
    end

    if sg.states["stop_sitting_pst"] then
        local _stop_sitting_pst_onenter_client = sg.states["stop_sitting_pst"].onenter
        sg.states["stop_sitting_pst"].onenter = function(inst, ...)
            if _stop_sitting_pst_onenter_client ~= nil then
                _stop_sitting_pst_onenter_client(inst, ...)
            end
            
            if inst:HasTag("limited_sitting") then
                ClearLimitedChairState_Client(inst)
            end
        end
    end
end)
