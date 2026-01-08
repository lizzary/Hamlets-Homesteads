GLOBAL.setfenv(1, GLOBAL)

function GetWorldSetting(setting, default)
    local worldsettings = TheWorld and TheWorld.components.worldsettings
    if worldsettings then
        return worldsettings:GetSetting(setting)
    end
    return default
end

function TagToDirect(inst)
    if inst:HasTag("door_north") then
        return 180
    end
    if inst:HasTag("door_east") then
        return -90
    end
    if inst:HasTag("door_west") then
        return 90
    end
    if inst:HasTag("door_south") then
        return 0
    end
end

function CalculateInteriorOffset(current_center, target_coord_x, target_coord_y)
    local current_x, current_y = current_center:GetCoordinates()
    local width, depth = current_center:GetSize()
    local offset_x = (target_coord_x - current_x) * (width + INTERIOR_SPACEING * 2)
    local offset_y = (target_coord_y - current_y) * (depth + INTERIOR_SPACEING * 2)
    return Vector3(-offset_y, 0, offset_x)
end
