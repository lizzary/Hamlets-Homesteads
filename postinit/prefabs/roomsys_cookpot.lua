local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)

AddPrefabPostInit("cookpot", function(inst)
    --相关逻辑移到stewer去了
    --inst:ListenForEvent("onbuilt", function(inst)
    --    local x, y, z = inst.Transform:GetWorldPosition()
    --    local roomtype
    --    if TheWorld.components.roomsystem then
    --        roomtype = TheWorld.components.roomsystem:GetRoomTypeByWorldPos(x, z)
    --        if roomtype == "kitchen" then
    --            inst:AddTag("in_kitchen")
    --
    --        end
    --    end
    --    print("This cookpot in room: ", roomtype or "none")
    --end)
    --
    local oldOnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if data then
            oldOnLoad(inst, data)
            if data.tag then
                inst:AddTag(data.tag)
            end
        end
    end

    local oldOnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        oldOnSave(inst, data)
        if inst:HasTag("in_kitchen") then
            data.tag = "in_kitchen"
        end
    end
end)

