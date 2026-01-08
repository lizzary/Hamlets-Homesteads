-- NOTE: Sweet House used -1900 < x < 2000 and 1100 < z < 2000
-- NOTE: Porkland Room will use BORDER < x < +2000 and BORDER < z < +2000
-- BORDER VALUE is world_size/2 + 120
--
--  +------[z]------+
--  |               |
-- [x] The constant |
--  |               |
--  +---------------+
--                   \
--                    \
--                     **************************
--                     *                        *
--                     * (place in this region) *
--                     *                        *
--                     **************************
--

-- 亚丹：实际上，在上方注释版本的代码中，z的范围是(+BORDER + 2000,+infinite)
-- 亚丹：将z的坐标范围修改为(-1000,+infinite)，注意当z小于-2000时渲染会因为超出TheSim:UpdateRenderExtents而出现问题

local SPACE = 120
local MAX_X_OFFSET = 2000
local MAX_Z_OFFSET = 2000
local PADDING = 30


--用途: 初始化InteriorSpawner实例
--
--代码作用:
--
--设置世界尺寸和室内区域起始坐标
--
--初始化存储结构：exteriors(外部房屋)、interiors(室内中心)、interior_defs(室内定义)
--
--创建重用ID池 reuse_interior_ids
--
--延迟调用SetInteriorPos确保室内位置在渲染范围内
--
--创建专用实体destroyer用于摧毁工作类对象
local InteriorSpawner = Class(function(self, inst)
    self.inst = inst
    self.world_width = -1
    self.world_height = -1
    self.x_start = math.huge
    self.z_start = math.huge

    self.exteriors = {} -- {[exterior: string]: House}
    self.interiors = {} -- {[interior: string]: interiorworkblank}
    self.interior_defs = {} -- {[index: number]: InteriorDef}
    self.interior_groups = {}
    --    interior_groups = {
    --    [group_id_1] = {  -- 组ID，通常是第一个房间的interiorID
    --        ["0,0"] = interiorworkblank_entity,      -- 坐标(0,0)的房间
    --        ["1,0"] = interiorworkblank_entity,      -- 坐标(1,0)的房间
    --        ["0,1"] = interiorworkblank_entity,      -- 坐标(0,1)的房间
    --        -- ...
    --    },
    --    [group_id_2] = {
    --        ["0,0"] = interiorworkblank_entity,
    --        ["-1,0"] = interiorworkblank_entity,
    --        -- ...
    --    },
    --    -- 更多组...
    --}
    self.doors = {} -- {[index: string]: DoorDef}
    self.reuse_interior_ids = {} -- 记录那些生成后被删掉的室内 ID，以重复利用其空间
    self.next_interior_id = 0

    --记录世界坐标所属的房屋id
    self.worldPos2ExteriorsId_cache = setmetatable({}, {
        __index = function(self, x)
            -- 当访问不存在的 x 时，自动创建子表
            local subTable = {}
            rawset(self, x, subTable)
            return subTable
        end
    })
    -- 直接设置地点（无需手动创建子表）
    --worldPos2InteriorId_cache[10][10] = 1
    --worldPos2InteriorId_cache[50][10] = 2
    --
    ---- 添加更多地点
    --worldPos2InteriorId_cache[10][20] = 3
    --worldPos2InteriorId_cache[30][30] = 4
    --
    ---- 访问测试
    --print("(10,10):", worldPos2InteriorId_cache[10][10])  -- 1
    --print("(50,10):", worldPos2InteriorId_cache[50][10])  -- 2
    --print("(10,20):", worldPos2InteriorId_cache[10][20])  -- 3
    --print("(30,30):", worldPos2InteriorId_cache[30][30])  -- 4
    --print("(100,100):", worldPos2InteriorId_cache[100][100])  -- nil（未设置）

    inst:DoTaskInTime(0, function()
        self:SetInteriorPos() -- 保证室内位于渲染范围内
    end)

    self.destroyer = CreateEntity() -- for workable:Destroy()
    self.destroyer:AddTag("interior_destroyer")
end)


--用途: 计算室内区域的布局参数
--
--代码作用:
--
--获取世界地图尺寸并计算室内区域起始坐标(x_start, z_start)
--
--计算最大渲染范围并更新引擎渲染范围(TheSim:UpdateRenderExtents)
--
--标记位置已设置pos_set = true
function InteriorSpawner:SetInteriorPos()
    if self.pos_set then
        return
    end
    local w, h = TheWorld.Map:GetSize()
    self.world_width = w * TILE_SCALE
    self.world_height = h * TILE_SCALE
    self.x_start = self.world_width / 2 + 120
    self.z_start = self.world_height / 2 + 120

    local max_size = math.max(self.x_start + MAX_X_OFFSET, self.z_start + MAX_Z_OFFSET)
    max_size = math.ceil(2 * (max_size + SPACE + PADDING))
    TheSim:UpdateRenderExtents(max_size) -- 设置底层引擎的渲染范围。需要注意，根据官方的说法，渲染范围太大会影响性能

    self.pos_set = true

    -- for i = 1, 500 do
    --     local pos = self:IndexToPosition(i)
    --     assert(self:PositionToIndex(pos) == i, "Index not match: ".. i)
    -- end
end


--用途: 保存室内数据到存档
--
--代码作用: 打包interior_defs、next_interior_id、reuse_interior_ids到保存数据中
function InteriorSpawner:OnSave()
    local interior_defs = {}
    for interior_id, def in pairs(self.interior_defs) do
        interior_defs[interior_id] = def
    end
    return {
        interiors = interior_defs,
        next_interior_id = self.next_interior_id,
        reuse_interior_ids = self.reuse_interior_ids,
    }
end


--用途: 从存档加载室内数据
--
--代码作用:
--
--恢复室内定义、下一个ID和重用ID列表
--
--调用SetInteriorPos重新计算位置
function InteriorSpawner:OnLoad(data)
    if data then
        if data.interiors then
            for _, def in pairs(data.interiors) do
                self:AddInterior(def)
            end
        end
        if data.next_interior_id then
            self.next_interior_id = data.next_interior_id
        end
        if data.reuse_interior_ids then
            self.reuse_interior_ids = data.reuse_interior_ids
        end
    end
    self:SetInteriorPos()
end

--用途: 建立室内房间的连接图和坐标系统
--
--代码作用:
--
--找到所有有外部出口的房间作为起点
--
--使用WalkConnectedRooms递归遍历连接的门，为每个房间分配组ID和相对坐标
--
--建立房间连接图，用于后续的空间查询
function InteriorSpawner:GenerateInteriorGroupsAndCoordinates()
    local rooms_with_exit = {}
    for id, center in pairs(self.interiors) do
        if not center.group_id_set then
            if center:GetDoorToExterior() then
                table.insert(rooms_with_exit, center)
            end
        end
    end

    local function WalkConnectedRooms(center, group_id, coord_x, coor_y)
        if center.group_id_set then
            return
        end

        center:SetGroupId(group_id)
        center:SetCoordinates(coord_x, coor_y)
        -- Re-register this interior center since we have a group id now
        self:AddInteriorCenter(center)

        local x, _, z = center.Transform:GetWorldPosition()
        for _, door in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"}, {"predoor"})) do
            local target_interior = door.components.door.target_interior
            if target_interior and target_interior ~= "EXTERIOR" then
                local door_direction
                for _, direction in ipairs(self:GetDir()) do
                    if door:HasTag("door_"..direction.label) then
                        door_direction = direction
                        break
                    end
                end
                if door_direction then
                    local room = self:GetInteriorCenter(target_interior)
                    WalkConnectedRooms(room, group_id, coord_x + door_direction.x, coor_y + door_direction.y)
                else
                    print("This door doesn't have a direction!", door)
                end
            end
        end
    end

    for _, center in ipairs(rooms_with_exit) do
        WalkConnectedRooms(center, center.interiorID, 0, 0)
    end
end

function InteriorSpawner:LoadPostPass(newents, data)
    self:GenerateInteriorGroupsAndCoordinates()
end


--用途: 计算当前已使用的最大室内ID
--
--代码作用: 遍历interiors表找到最大ID，更新next_interior_id
-- WARNING: this mothod cannot be called before game load (interiorID is nil)
function InteriorSpawner:GetCurrentMaxId()
    local index = 0
    for id in pairs(self.interiors) do
        index = math.max(id, index)
    end
    self.next_interior_id = index
    return index
end

--用途: 分配新的室内ID
--
--代码作用:
--
--优先从reuse_interior_ids中获取可重用ID
--
--否则递增next_interior_id
function InteriorSpawner:GetNewID() -- 注意：每次该函数被调用，都会占用一个 interiorID 及其对应的室内区域，因此确定有使用需求再调用此函数
        -- 并且需要在该室内区域移除后需要触发回调，通过 reuse_interior_ids 来重复使用 interiorID
    local reuse_id = next(self.reuse_interior_ids)
    if reuse_id then
        self.reuse_interior_ids[reuse_id] = nil
        return reuse_id
    end
    self.next_interior_id = self.next_interior_id + 1
    return self.next_interior_id
end

-- function InteriorSpawner:Debug_CalculateNumSlots()
--     print(string.format("World size: %dx%d", self.world_width, self.world_height))
--     local x_size = math.floor(MAX_X_OFFSET / SPACE)
--     local y_size = math.floor((MAX_Z - MIN_Z) / SPACE)
--     print(string.format("InteriorSpawner can use %d slots (%dx%d)",
--         x_size * y_size,
--         x_size, y_size))
-- end

--用途: 检查坐标是否在允许生成室内的区域内
--
--代码作用: 判断x在[x_start-PADDING, x_start+MAX_X_OFFSET+PADDING]，z在[-1100, z_start+MAX_Z_OFFSET+PADDING]
-- TODO: Make all x, z things take a Vector3 or x, y, z for easier access
function InteriorSpawner:IsInInteriorRegion(x, z)
    return x >= self.x_start - PADDING and x <= self.x_start + MAX_X_OFFSET + PADDING
        and z >= - 1000 -100 and z <= self.z_start + MAX_Z_OFFSET + PADDING -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
end

--用途: 检查坐标是否在具体的室内房间边界内
--
--代码作用: 获取房间中心，计算与坐标的偏移，判断是否在房间尺寸/2 + padding范围内
function InteriorSpawner:IsInInteriorRoom(x, z, padding)
    padding = padding or 0
    local position = Vector3(x, 0, z)
    local center = self:GetInteriorCenter(position)
    if center then
        local width, depth = center:GetSize()
        local offset = center:GetPosition() - position
        return math.abs(offset.x) < depth/2 + padding and math.abs(offset.z) < width/2 + padding
    end
end

--用途: 综合检测是否在室内
--
--代码作用: 先检测区域，再检测具体房间
function InteriorSpawner:IsInInterior(x, z, padding)
    return self.world_width > 0 and self:IsInInteriorRegion(x, z) and self:IsInInteriorRoom(x, z, padding)
end

--用途: 根据位置或ID获取室内中心实体
--
--代码作用:
--
--服务器端：直接从interiors表中查找
--
--客户端：使用FindEntities在附近搜索
--
--支持通过位置或数字ID查找
-- Finds the interior center with position or index (interiorID)
-- Uses FindEntities on client, so only works if you're close to that interiorworkblank (center)
function InteriorSpawner:GetInteriorCenter(position_or_index)
    if not position_or_index then
        print("InteriorSpawner:GetInteriorCenter the param position_or_index is nil!!!")
        return
    end
    local is_number = type(position_or_index) == "number"
    if TheWorld.ismastersim then
        -- If we're finding by position, check if it's in the interior region
        if not is_number then
            local position = position_or_index
            if not self:IsInInteriorRegion(position.x, position.z) then
                return
            end
        end
        local index = is_number and position_or_index or self:PositionToIndex(position_or_index)
        return self.interiors[index]
    end

    local position = is_number and self:IndexToPosition(position_or_index) or position_or_index
    for _, v in ipairs(TheSim:FindEntities(position.x, 0, position.z, TUNING.ROOM_FINDENTITIES_RADIUS, {"pl_interiorcenter"})) do
        return v
    end
end

--用途: 将室内ID转换为世界坐标
--
--代码作用:
--
--基于网格系统计算坐标：x方向索引×SPACE + x_start，z方向索引×SPACE - 1000
--
--注释提到z从-1000开始，因为小地图同步问题
function InteriorSpawner:IndexToPosition(i)
    self:SetInteriorPos()
    local x_size = math.floor(MAX_X_OFFSET / SPACE)
    local x_index = i % x_size
    local z_index = math.floor(i / x_size)
    return Vector3(
        x_index * SPACE + self.x_start,
        0,
        z_index * SPACE - 1000) -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
end

--用途: 将世界坐标转换为室内ID interiorID
--
--代码作用: 逆运算，计算坐标在网格中的索引
-- Doesn't check if the position is in the interior area or ont
function InteriorSpawner:PositionToIndex(pos)

    self:SetInteriorPos()
    local x_size = math.floor(MAX_X_OFFSET / SPACE)
    local x_index = math.floor((pos.x - self.x_start) / SPACE + 0.5)
    local z_index = math.floor((pos.z + 1000) / SPACE + 0.5) -- 实际z坐标从-1000开始，因为在z<1000的位置，小地图同步会出现问题
    return z_index * x_size + x_index
end

--用途: 获取室内配置定义
--
--代码作用: 通过ID从interior_defs表中获取室内配置
-- Get the interior definition with position or index (interiorID)
function InteriorSpawner:GetInteriorDefinition(position_or_id)
    local id = type(position_or_id) == "number" and position_or_id or self:PositionToIndex(position_or_id)
    return self.interior_defs[id]
end

--用途: 注册外部房屋实体
--
--代码作用:
--
--将房屋添加到exteriors表
--
--监听房屋的onremove事件，移除时清理对应室内
function InteriorSpawner:AddExterior(entity)
    local interior_id = entity.interiorID
    self.exteriors[interior_id] = entity
    entity.interiorspawner_exterior_on_remove_listener = function()
        if not entity.components.fixable and entity.prefab ~= "reconstruction_project" then
            self.exteriors[interior_id] = nil
            self:OnRemoveExterior(entity)
        end
    end
    entity:ListenForEvent("onremove", entity.interiorspawner_exterior_on_remove_listener)
end

--用途: 将室内ID从一个外部实体转移到另一个
--
--代码作用: 更新exteriors表引用
function InteriorSpawner:TransferExterior(from_entity, to_entity)
    if from_entity.interiorspawner_exterior_on_remove_listener then
        from_entity:RemoveEventCallback("onremove", from_entity.interiorspawner_exterior_on_remove_listener)
        from_entity.interiorspawner_exterior_on_remove_listener = nil
    end
    self.exteriors[from_entity.interiorID] = nil

    self:AddExterior(to_entity)
end

--用途: 处理外部房屋被移除时的清理
--
--代码作用:
--
--获取对应的室内中心
--
--清除室内所有内容
--
--移除室内定义
function InteriorSpawner:OnRemoveExterior(entity)
    if entity.interiorID == nil then
        print("WARNING: remove exterior without interiorID: "..tostring(entity))
        return
    end

    if self.worldPos2InteriorId_cache then
        for x, subTable in pairs(self.worldPos2InteriorId_cache) do
            for z, location in pairs(subTable) do
                if location == entity.interiorID then
                    self.worldPos2InteriorId_cache[x][z] = nil
                end
            end
        end
    end

    local room = self:GetInteriorCenter(entity.interiorID)
    if room then
        local exterior_pos = entity:GetPosition()
        local allrooms = self:GetAllConnectedRooms(room)
        for center in pairs(allrooms) do
            self:ClearInteriorContents(center:GetPosition(), exterior_pos)
            if center.interiorID then
                self.interior_defs[center.interiorID] = nil
            end
        end
    end
end

--OnRemoveExterior的重写版，由提供entity改为提供id
function InteriorSpawner:RemoveInteriorById(interiorID,exterior_pos)
    if self.worldPos2InteriorId_cache then
        for x, subTable in pairs(self.worldPos2InteriorId_cache) do
            for z, id in pairs(subTable) do
                if id == entity.interiorID then
                    self.worldPos2InteriorId_cache[x][z] = nil
                end
            end
        end
    end

    local room = self:GetInteriorCenter(interiorID)
    if room then
        local allrooms = self:GetAllConnectedRooms(room)
        for center in pairs(allrooms) do
            self:ClearInteriorContents(center:GetPosition(), exterior_pos)
            if center.interiorID then
                self.interior_defs[center.interiorID] = nil
            end
        end
    end
end

--用途: 根据室内ID获取对应的外部房屋
function InteriorSpawner:GetExteriorById(id)
    assert(TheWorld.ismastersim, "This method must be called in server")
    local exterior = self.exteriors[id]
    if exterior and not exterior:IsValid() then
        self.exteriors[id] = nil
        return
    end
    return exterior
end

function InteriorSpawner:GetGroupIdFromWorldPos(x,z)

    local groupId = self.worldPos2ExteriorsId_cache[x][z]
    if groupId then
        return groupId
    end

    -- 1. 先检查是否在室内区域
    if not self:IsInInteriorRegion(x, z) then
        return nil  -- 不在室内区域，返回nil
    end

    -- 2. 获取室内中心实体
    local center = self:GetInteriorCenter({x=x,z=z})
    if not center then
        return nil  -- 没有找到室内中心
    end

    -- 3. 从室内中心获取组ID
    groupId = center:GetGroupId()

    self.worldPos2ExteriorsId_cache[x][z] = groupId
    return groupId
end
local EAST  = { x =  1, y =  0, label = "east" }
local WEST  = { x = -1, y =  0, label = "west" }
local NORTH = { x =  0, y =  1, label = "north" }
local SOUTH = { x =  0, y = -1, label = "south" }

-- local op_dir_str =
-- {
--     ["north"] = "south",
--     ["east"]  = "west",
--     ["south"] = "north",
--     ["west"]  = "east",
-- }

local dir = { EAST, WEST, NORTH, SOUTH }
local dir_opposite = { WEST, EAST, SOUTH, NORTH }

--用途: 定义四个基本方向(NORTH, SOUTH, EAST, WEST)并提供访问方法
function InteriorSpawner:GetNorth()
    return NORTH
end
function InteriorSpawner:GetSouth()
    return SOUTH
end
function InteriorSpawner:GetWest()
    return WEST
end
function InteriorSpawner:GetEast()
    return EAST
end

function InteriorSpawner:GetDir()
    return dir
end

function InteriorSpawner:GetDirOpposite()
    return dir_opposite
end

function InteriorSpawner:GetOppositeFromDirection(direction)
    if direction == NORTH then
        return self:GetSouth()
    elseif direction == EAST then
        return self:GetWest()
    elseif direction == SOUTH then
        return self:GetNorth()
    else
        return self:GetEast()
    end
end

-- maybe this should be consistent with the function above...
function InteriorSpawner:GetDirByLabel(label)
    if label == EAST.label then
        return EAST
    elseif label == WEST.label then
        return WEST
    elseif label == NORTH.label then
        return NORTH
    else
        return SOUTH
    end
end

--用途: 注册门并设置门组件属性
--
--代码作用:
--
--将门数据存储到doors表
--
--设置门的各种属性：目标室内、目标门ID等
--
--通知室内中心门的变化
function InteriorSpawner:AddDoor(door, def)
    if not def.my_door_id then
        print("WARNING: def.my_door_id is nil when AddDoor")
        return
    end
    self.doors[def.my_door_id] = {
        inst = door,
        my_interior_name = def.my_interior_name,
        target_interior = def.target_interior,
    }

    local door_component = door.components.door or door:AddComponent("door")

    door_component.door_id = def.my_door_id
    door_component.interior_name = def.my_interior_name
    door_component.target_door_id = def.target_door_id
    door_component.target_interior = def.target_interior
    door_component.target_exterior = def.target_exterior
    door_component.is_exit = def.is_exit

    local center = self:GetInteriorCenter(door:GetPosition())
    if center then
        center:OnDoorChange(door, true)
    end
end


--用途: 从系统中移除门
--
--代码作用: 清除门数据，触发门移除事件
function InteriorSpawner:RemoveDoor(door_id)
    local door_data = self.doors[door_id]
    if not door_data then
        print("ERROR: TRYING TO REMOVE A NON EXISTING DOOR DEFINITION")
        return
    end

    self.doors[door_id] = nil
    TheWorld:PushEvent("door_removed")

    local door = door_data.inst
    local center = self:GetInteriorCenter(door:GetPosition())
    if center then
        center:OnDoorChange(door, false)
    end
end

--用途: 在指定室内生成预设对象
--
--代码作用: 将对象生成在室内对应位置
function InteriorSpawner:SpawnObject(interiorID, prefab, offset)
    local object = SpawnPrefab(prefab)
    if not object then
        print("Error: Failed to spawn " .. prefab)
        return
    end

    local spawn_point = self:IndexToPosition(interiorID)
    if offset then
        spawn_point = spawn_point + offset
    end
    object.Transform:SetPosition(spawn_point:Get())
    return object
end

--用途: 将坐标转换为表键字符串
--
--代码作用: 格式化为"x,y"字符串，用于在interior_groups表中索引
function InteriorSpawner:CoordinatesToKey(x, y)
    return tostring(x) .. "," .. tostring(y)
end

--用途: 将坐标转换为表键字符串
--
--代码作用: 格式化为"x,y"字符串，用于在interior_groups表中索引
function InteriorSpawner:CenterCoordinatesToKey(center)
    local x, y = center:GetCoordinates()
    return self:CoordinatesToKey(x, y)
end

--用途: 注册室内中心实体
--
--代码作用: 添加到interiors表和对应的组结构中
function InteriorSpawner:AddInteriorCenter(center)
    self.interiors[center.interiorID] = center

    if center.group_id_set then
        local group_id = center:GetGroupId()
        if not self.interior_groups[group_id] then
            self.interior_groups[group_id] = {}
        end
        self.interior_groups[group_id][self:CenterCoordinatesToKey(center)] = center
    end
end

--用途: 注销室内中心
--
--代码作用: 从所有相关表中移除，ID加入重用池
function InteriorSpawner:RemoveInteriorCenter(center)
    self.interiors[center.interiorID] = nil
    self.interior_defs[center.interiorID] = nil
    self.reuse_interior_ids[center.interiorID] = true

    if center.group_id_set then
        local group_id = center:GetGroupId()
        if self.interior_groups[group_id] then
            self.interior_groups[group_id][self:CenterCoordinatesToKey(center)] = nil
        end
        if IsTableEmpty(self.interior_groups[group_id]) then
            self.interior_groups[group_id] = nil
        end
    end
end

--------房间创建与生成方法-----------------

local function CheckRoomSize(width, depth)
    assert(math.floor(width) == width, "Room width must be int")
    assert(math.floor(depth) == depth, "Room depth must be int")
    assert(width <= 64 and depth <= 64, "Room size must be smaller than 64")
    if width ~= TUNING.ROOM_TINY_WIDTH
        and width ~= TUNING.ROOM_SMALL_WIDTH
        and width ~= TUNING.ROOM_MEDIUM_WIDTH
        and width ~= TUNING.ROOM_LARGE_WIDTH then
        print("InteriorSpawner: warning: nonstandard room width")
    end
    if depth ~= TUNING.ROOM_TINY_DEPTH
        and depth ~= TUNING.ROOM_SMALL_DEPTH
        and depth ~= TUNING.ROOM_MEDIUM_DEPTH
        and depth ~= TUNING.ROOM_LARGE_DEPTH then
        print("InteriorSpawner: warning: nonstandard room depth")
    end
end

--用途: 主要的房间创建接口
--
--代码作用:
--
--解析参数：尺寸、纹理、道具、出口等
--
--创建室内定义(interior_def)
--
--处理出口，创建门定义
--
--调用AddInterior和SpawnInterior
-- roomindex here is used as the interiorID on all the interiors in the room,
-- and also interior_name for the door component on prop_door prefab
function InteriorSpawner:CreateRoom(params)
    local width = params.width or 15
    local height = params.height or 10
    local depth = params.depth or 10
    local group_id = assert(params.group_id)
    local interior_coordinate_x = assert(params.interior_coordinate_x)
    local interior_coordinate_y = assert(params.interior_coordinate_y)
    local dungeon_name = params.dungeon_name
    local roomindex = assert(params.roomindex)
    local addprops = params.addprops
    local exits = params.exits or {}
    local walltexture = params.walltexture
    local floortexture = params.floortexture
    local minimaptexture = params.minimaptexture
    local cityID = params.cityID
    local colour_cube = params.colour_cube or "images/colour_cubes/day05_cc.tex"
    local batted = params.batted
    local playerroom = params.playerroom
    local reverb = params.reverb                            -- Reverb preset
    local ambient_sound = params.ambient_sound              -- Ambient sound index
    local footstep_tile = params.footstep_tile              -- Footstep sound tile
    local cameraoffset = params.cameraoffset
    local zoom = params.zoom
    local forceInteriorMinimap = params.forceInteriorMinimap

    CheckRoomSize(width, depth)

    local interior_def = {
        unique_name = roomindex,
        dungeon_name = dungeon_name,
        width = width,
        height = height,
        depth = depth,
        prefabs = {},
        walltexture = walltexture,
        floortexture = floortexture,
        minimaptexture = minimaptexture,
        cityID = cityID,
        cc = colour_cube,
        batted = batted,
        playerroom = playerroom,
        enigma = false,
        reverb = reverb,
        ambient_sound = ambient_sound,
        footstep_tile = footstep_tile,
        cameraoffset = cameraoffset,
        zoom = zoom,
        forceInteriorMinimap = forceInteriorMinimap,
        group_id = group_id,
        interior_coordinate_x = interior_coordinate_x,
        interior_coordinate_y = interior_coordinate_y,
    }

    for _, prefab in ipairs(addprops) do
        if not prefab.chance or math.random() < prefab.chance then
            table.insert(interior_def.prefabs, prefab)
        end
    end

    for heading, exit in pairs(exits) do
        -- convert to number
        if type(exit.target_room) == "string" then
            print("WARNING: target_room is a string:", dungeon_name, exit.target_room)
            local index = assert(tonumber(select(3, exit.target_room:find("_(%d+)$"))), "Failed to convert to number: "..exit.target_room)
            exit.target_room = index
        end

        -- Create door prefab based on the direction
        local door_def = {}
        if exit.house_door then
            local doordata = PLAYER_INTERIOR_EXIT_DIR_DATA[heading.label]
            door_def = {
                name = exit.prefab_name,
                x_offset = doordata.x_offset,
                z_offset = doordata.z_offset,
                sg_name = exit.sg_name,
                startstate = exit.startstate,
                animdata = {
                    minimapicon = exit.minimapicon,
                    bank = exit.bank,
                    build = exit.build,
                    anim = exit.prefab_name .. "_open_" .. doordata.anim,
                    background = doordata.background,
                },
                my_door_id = roomindex .. doordata.my_door_id_dir,
                target_door_id = exit.target_room .. doordata.target_door_id_dir,
                target_interior = exit.target_room,
                rotation = -90,
                hidden = false,
                angle = doordata.angle,
                addtags = {"lockable_door", doordata.door_tag},
            }
        else
            if heading == NORTH then
                door_def = {
                    name = "prop_door",
                    x_offset = -depth / 2,
                    z_offset = 0,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "north",
                        background = true
                    },
                    my_door_id = roomindex .. "_NORTH",
                    target_door_id = exit.target_room .. "_SOUTH",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 0,
                    addtags = {"lockable_door", "door_north"}
                }
            elseif heading == SOUTH then
                door_def = {
                    name = "prop_door",
                    x_offset = (depth / 2),
                    z_offset = 0,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "south",
                        background = false
                    },
                    my_door_id = roomindex .. "_SOUTH",
                    target_door_id = exit.target_room .. "_NORTH",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 180,
                    addtags = {"lockable_door", "door_south"}
                }
                if not exit.secret then
                    table.insert(interior_def.prefabs, {
                        name = "prop_door_shadow",
                        x_offset = (depth / 2),
                        z_offset = 0,
                        animdata = {
                            bank = exit.bank,
                            build = exit.build,
                            anim = "south_floor",
                        },
                    })
                end
            elseif heading == EAST then
                door_def = {
                    name = "prop_door",
                    x_offset = 0,
                    z_offset = width / 2,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "east",
                        background = true,
                    },
                    my_door_id = roomindex .. "_EAST",
                    target_door_id = exit.target_room .. "_WEST",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 90,
                    addtags = {"lockable_door", "door_east"},
                }
            elseif heading == WEST then
                door_def = {
                    name = "prop_door",
                    x_offset = 0,
                    z_offset = -width / 2,
                    sg_name = exit.sg_name,
                    startstate = exit.startstate,
                    animdata = {
                        minimapicon = exit.minimapicon,
                        bank = exit.bank,
                        build = exit.build,
                        anim = "west",
                        background = true,
                    },
                    my_door_id = roomindex .. "_WEST",
                    target_door_id = exit.target_room .. "_EAST",
                    target_interior = exit.target_room,
                    rotation = -90,
                    hidden = false,
                    angle = 270,
                    addtags = {"lockable_door", "door_west"},
                }
            end
        end
        assert(door_def)

        if exit.vined then
            door_def.vined = true
        end

        if exit.secret then
            door_def.secret = true
            door_def.hidden = true
        end

        table.insert(interior_def.prefabs, door_def)
    end

    self:AddInterior(interior_def)
    self:SpawnInterior(interior_def)
end

--用途: 实际生成室内内容和实体
--
--代码作用:
--
--清除该位置的原有内容
--
--生成interiorworkblank作为房间中心
--
--遍历室内定义中的预设，生成所有对象（道具、门等）
--
--设置对象的属性：位置、旋转、标签、动画等
--
--处理特殊对象如门的方向判断
function InteriorSpawner:AddInterior(def)
    assert(self.interior_defs[def.unique_name] == nil, "THIS ROOM ALREADY EXISTS: "..def.unique_name)

    def.object_list = {}
    self.interior_defs[def.unique_name] = def

    if def.batted and TheWorld.components.batted then
        TheWorld.components.batted:RegisterBatCave(def.unique_name) -- unique_name is interiorID
    end
end

-- TODO: Doesn't work right now, see if we need it
-- function InteriorSpawner:GetInteriorByName(name)
--     if name == nil then
--         return nil
--     else
--         local interior = self.interior_defs[name]
--         if interior == nil then
--             print("!!ERROR: Unable To Find Interior Named:"..name)
--         end

--         return interior
--     end
-- end

local function teleport(entity, position)
    if entity.Physics then
        entity.Physics:Teleport(position:Get())
    else
        entity.Transform:SetPosition(position:Get())
    end
end

--用途: 清除室内所有实体
--
--代码作用:
--
--找到室内中心，停用门
--
--将玩家传送到外部位置
--
--分阶段清理实体：
--
--不可替换实体：传送或沉没
--
--可工作实体：用destroyer摧毁
--
--有生命实体：攻击后传送
--
--库存物品：传送
-- This also destroies the interior center
function InteriorSpawner:ClearInteriorContents(pos, exterior_pos)
    assert(TheWorld.ismastersim)

    TheWorld:PushEvent("pl_clearinterior", {pos = pos})

    local center = self:GetInteriorCenter(pos)
    if center then
        self:DeactivateHouseDoors(center)
    end

    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS, {"player"})
    for _, v in ipairs(ents) do
        v:PushEvent("pl_clearfrominterior", {exterior_pos = exterior_pos})
        if exterior_pos ~= nil then
            teleport(v, exterior_pos)
            v:SnapCamera()
        else
            TheWorld.components.playerspawner:SpawnAtNextLocation(v)
            v:SnapCamera()
        end
    end

    -- This destroies the interior center
    -- and this can generate more inventoryitems,
    -- so we do another pass afterwards to push them to the exit position
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"_inventoryitem"})
    if #ents > 0 then
        print("WARNING: Find "..#ents.." entities around pt "..tostring(pos)
            .." [INDEX="..self:PositionToIndex(pos).."]")
        for _, v in ipairs(ents) do
            v:PushEvent("pl_clearfrominterior", {exterior_pos = exterior_pos})
            if v:HasTag("irreplaceable") then
                if exterior_pos ~= nil then
                    teleport(v, exterior_pos)
                else
                    SinkEntity(v)
                end
            elseif v.components.workable and v.components.workable:GetWorkAction() == ACTIONS.HAMMER then
                v.components.workable:Destroy(self.destroyer)
                if v:IsValid() then
                    if exterior_pos ~= nil then
                       teleport(v, exterior_pos)
                    end
                end
            elseif v.components.health and v.components.combat then
                if exterior_pos ~= nil then
                   teleport(v, exterior_pos)
                else
                    SinkEntity(v)
                end
                v.components.combat:GetAttacked(nil, 20, nil)
            elseif v:IsValid() then
                v:Remove()
            end
        end
    end

    local ents = TheSim:FindEntities(pos.x, 0, pos.z, TUNING.ROOM_FINDENTITIES_RADIUS, {"_inventoryitem"})
    for _, v in ipairs(ents) do
        if v.components.inventoryitem then
            if exterior_pos then
                teleport(v, exterior_pos)
            else
                SinkEntity(v)
            end
            if v.components.health and v.components.combat then
                v.components.combat:GetAttacked(nil, 20, nil)
            end
        elseif v:IsValid() then
            v:Remove()
        end
    end
end


--用途: 实际生成室内内容和实体
--
--代码作用:
--
--清除该位置的原有内容
--
--生成interiorworkblank作为房间中心
--
--遍历室内定义中的预设，生成所有对象（道具、门等）
--
--设置对象的属性：位置、旋转、标签、动画等
--
--处理特殊对象如门的方向判断
function InteriorSpawner:SpawnInterior(interior)
    -- this function only gets run once per room when the room is first called.

    local pt = self:IndexToPosition(interior.unique_name)
    self:ClearInteriorContents(pt)

    -- print("InteriorSpawner:SpawnInterior", pt)

    local center = SpawnPrefab("interiorworkblank")
    center.Transform:SetPosition(pt:Get())
    center.interiorID = interior.unique_name
    center:SetUp(interior)

    for _, prefab in ipairs(interior.prefabs) do

        if --[[ GetWorld():IsWorldGenOptionNever(prefab.name)]] false then
            -- TODO: 实现这个特性
            -- 例如，关闭树枝时，遗迹内也不产生树枝
            print("CANCEL SPAWN ITEM DUE TO WORLD GEN PREFS", prefab.name)
        else
            local object = SpawnPrefab(prefab.name)

            -- TODO: remove this assertion in prod
            if object == nil then
                if prefab.name:find("pigman_") then
                    -- TODO: defined in global????
                else
                    print("Failed to spawn `"..tostring(prefab.name).."`")
                end
            else
                object.Transform:SetPosition(pt.x + prefab.x_offset, 0, pt.z + prefab.z_offset)

                -- flips the art of the item. This must be manually saved on items it it's to persist over a save
                if prefab.flip then
                    object.flipped = true
                end

                -- guess door direction
                if prefab.name == "prop_door" then
                    local dir = nil
                    local x, z = prefab.x_offset * 2, prefab.z_offset * 2
                    if x == 0 then
                        dir = z == -interior.width and "west"
                            or z == interior.width and "east"
                            or nil
                    elseif z == 0 then
                        dir = x == -interior.depth and "north"
                            or x == interior.depth and "south"
                            or nil
                    end
                    if dir ~= nil then
                        -- NOTE: this tag can be saved by door component
                        object:AddTag("door_"..dir)
                    else
                        print("WARNING: failed to guess door direction")
                        print("x:", prefab.x_offset, "z:", prefab.z_offset)
                    end
                end

                -- sets the initial roation of an object, NOTE: must be manually saved by the item to survive a save
                if prefab.rotation ~= nil then
                    object.Transform:SetRotation(prefab.rotation + (object.flipped and 180 or 0))
                elseif object.flipped then
                    object.Transform:SetRotation(90)
                end

                -- adds tags to the object
                if prefab.addtags then
                    for _, tag in ipairs(prefab.addtags) do
                        object:AddTag(tag)
                    end
                end

                if prefab.hidden then
                    object.components.door.hidden = true
                end
                if prefab.angle then
                    object.components.door.angle = prefab.angle
                end

                -- saves the roomID on the object
                -- if object.components.shopped then
                --     object.interiorID = interior.unique_name
                -- end

                -- sets an anim to start playing
                if prefab.animation then
                    object.AnimState:PlayAnimation(prefab.animation)
                    object.animation = prefab.animation
                    if object.frontvisual then
                        object.frontvisual.AnimState:PlayAnimation(prefab.animation)
                    end
                    if object.clochevisual then
                        object.clochevisual.AnimState:PlayAnimation(prefab.animation)
                    end
                    if object.costvisual then
                        object.costvisual:UpdateVisual(prefab.animation)
                    end
                end

                if prefab.usesounds then
                    object.usesounds = prefab.usesounds
                end

                if prefab.saleitem then
                    object.saleitem = prefab.saleitem
                end

                if prefab.justsellonce then
                    object:AddTag("justsellonce")
                end

                if prefab.startstate then
                    object.startstate = prefab.startstate
                    if object.sg == nil then
                        object:SetStateGraph(prefab.sg_name)
                        object.sg_name = prefab.sg_name
                    end

                    object.sg:GoToState(prefab.startstate)
                end

                if prefab.forcesleep then
                    object.components.sleeper:GoToSleep()
                    if object.sg and object.sg:HasState("sleeping") then
                        object.sg:GoToState("sleeping")
                    end
                end

                if prefab.shelfitems then
                    for _, data in ipairs(prefab.shelfitems) do
                        object.components.container:GiveItem(SpawnPrefab(data[2]), data[1])
                    end
                end

                -- this door should have vines
                if prefab.vined and object.components.vineable then
                    object.components.vineable:SetUpVine()
                end


                -- this function processes the extra data that the prefab has attached to it for interior stuff.
                if object.initInteriorPrefab then
                    -- object.initInteriorPrefab(object, GetPlayer(), prefab, interior)
                    object.initInteriorPrefab(object, --[[GetPlayer()]]nil , prefab, interior)
                    -- TODO: check who call it?
                end

                -- should the door be closed for some reason?
                -- needs to happen after the object initinterior so the door info is there.
                if prefab.door_closed then
                    for cause, setting in pairs(prefab.door_closed) do
                        object.components.door:SetDoorDisabled(setting, cause)
                    end
                end

                if prefab.secret then
                    object:AddTag("secret")
                    object:RemoveTag("lockable_door")
                    object:Hide()

                    self.inst:DoTaskInTime(0, function()
                        local crack = SpawnPrefab("wallcrack_ruins")
                        crack:SetCrack(object)
                    end)
                end

                -- needs to happen after the door_closed stuff has happened.
                if object.components.vineable then
                    object.components.vineable:InitInteriorPrefab()
                end

                -- if interior.cityID then
                --     if not object.components.citypossession then
                --         object:AddComponent("citypossession")
                --     end
                --     object.components.citypossession:SetCity(interior.cityID)
                -- end
            end
        end
    end
end

--用途: 递归获取通过门连接的所有房间
--
--代码作用: 深度优先遍历门连接图
function InteriorSpawner:GetAllConnectedRooms(center, allrooms)
    -- WARNING: this method is quite expensive and server only
    if not allrooms then
        allrooms = {}
    end
    if allrooms[center] then
        return
    end
    allrooms[center] = true
    local x, _, z = center.Transform:GetWorldPosition()
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})) do
        local target_interior = v.components.door and v.components.door.target_interior
        if target_interior and target_interior ~= "EXTERIOR" then
            local room = self.interiors[target_interior] or self:GetInteriorCenter(target_interior)
            assert(room, "Room not exists: "..target_interior)
            self:GetAllConnectedRooms(room, allrooms)
        end
    end
    return allrooms
end

--用途: 对房间内每个玩家执行函数
function InteriorSpawner:ForEachPlayerInRoom(interiorID, fn, ...)
    if not interiorID then
        return
    end

    local room = self:GetInteriorCenter(interiorID)
    if not room or not room:IsValid() then
        return
    end

    for _, player in pairs(AllPlayers) do
        local current_room = player:GetCurrentInteriorID()
        if current_room == interiorID then
            fn(player, ...)
        end
    end
end

--检查是否有玩家在房间内
function InteriorSpawner:IsAnyPlayerInRoom(interiorID)
    if not interiorID then
        return false
    end

    for _, player in pairs(AllPlayers) do
        if player:GetCurrentInteriorID() == interiorID then
            return true
        end
    end

    return false
end

--用途: 按距离排序获取同一组内的其他房间
-- Get a sorted list of rooms in distance to the given interior center
function InteriorSpawner:GetSortedRoomsInGroup(room)
    local group = self.interior_groups[room:GetGroupId()]
    local rooms = {}
    for _, center in pairs(group) do
        if center ~= room then
            table.insert(rooms, center)
        end
    end
    local current_x, current_y = room:GetCoordinates()
    table.sort(rooms, function(a, b)
        local a_x, a_y = a:GetCoordinates()
        local b_x, b_y = b:GetCoordinates()
        return distsq(current_x, current_y, a_x, a_y) < distsq(current_x, current_y, b_x, b_y)
    end)
    return rooms
end

--用途: 根据组ID和坐标获取房间
function InteriorSpawner:GetInteriorCenterByCoordinates(group_id, x, y)
    local group = self.interior_groups[group_id]
    if group then
        return group[self:CoordinatesToKey(x, y)]
    end
end

-- 一个房子最多能建几个房间
function InteriorSpawner:CanBuildMorePlayerRoom(house_id)
    return GetTableSize(self.interior_groups[house_id]) < 20
end

--用途: 获取指定方向相邻的房间
function InteriorSpawner:GetRoomInDirection(room, direction)
    local x, y = room:GetCoordinates()
    return self:GetInteriorCenterByCoordinates(room:GetGroupId(), x + direction.x, y + direction.y)
end

--用途: 获取四个基本方向的相邻房间
-- surrounding mean can be connected with a door, so each room has max 4 surrounding rooms
function InteriorSpawner:GetSurroundingRooms(group_id, x, y)
    local rooms = {}
    for _, direction in ipairs(self:GetDir()) do
        local center = self:GetInteriorCenterByCoordinates(group_id, x + direction.x, y + direction.y)
        if center then
            table.insert(rooms, {
                direction = direction,
                interior = center,
            })
        end
    end
    return rooms
end

--用途: 获取通过门连接的周围房间，排除指定方向
function InteriorSpawner:GetConnectedSurroundingPlayerRooms(house_id, id, exclude_dir)
    local found_doors = {}
    local center = self:GetInteriorCenter(id)
    if not center then
        return found_doors
    end

    local x, y, z = center.Transform:GetWorldPosition()
    local doors = TheSim:FindEntities(x, y, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door"})
    local curr_x, curr_y = center:GetCoordinates()

    for _, door in pairs(doors) do
        if door.prefab ~= "prop_door" then
            local target_interior = door.components.door.target_interior
            local target_x, target_y = self:GetInteriorCenter(target_interior):GetCoordinates()

            if target_y > curr_y then -- North door
                found_doors["north"] = target_interior
            elseif target_y < curr_y then -- South door
                found_doors["south"] = target_interior
            elseif target_x > curr_x then -- East Door
                found_doors["east"] = target_interior
            elseif target_x < curr_x then -- West Door
                found_doors["west"] = target_interior
            end
        end
    end

    found_doors[exclude_dir] = nil

    return found_doors
end

--用途: 停用连接到该房间的门
--
--代码作用: 找到所有连接的门，调用其DeactivateSelf方法
function InteriorSpawner:DeactivateHouseDoors(center)
    for _, door in ipairs(center.doors) do
        if door.components.door.target_interior and door.components.door.target_door_id and door:HasTag("house_door") then
            local connected_room = self:GetInteriorCenter(door.components.door.target_interior)
            if connected_room then
                for _, v in ipairs(connected_room.doors) do
                    if v.components.door.door_id == door.components.door.target_door_id then
                        v:DeactivateSelf()
                    end
                end
            end
            door:DeactivateSelf()
        end
    end
end


--用途: 专门用于拆除玩家房间
--
--代码作用: 类似ClearInteriorContents但针对玩家房间优化
-- This also destroies the interior center
function InteriorSpawner:DemolishPlayerRoom(room_id, exit_pos)
    assert(TheWorld.ismastersim)

    local center = self:GetInteriorCenter(room_id)

    self:DeactivateHouseDoors(center)

    local x, _, z = center.Transform:GetWorldPosition()

    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"player"})) do
        if exit_pos ~= nil then
            teleport(v, exit_pos)
            v:SnapCamera()
        else
            TheWorld.components.playerspawner:SpawnAtNextLocation(v)
            v:SnapCamera()
        end
    end

    -- This destroies the interior center,
    -- and this can generate more inventoryitems,
    -- so we do another pass afterwards to push them to the exit position
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, nil, {"_inventoryitem"})) do
        if v:HasTag("irreplaceable") then
            SinkEntity(v)
        elseif v.components.workable then
            v.components.workable:Destroy(self.destroyer)
            if v:IsValid() then
                teleport(v, exit_pos)
            end
        elseif v.components.health then
            if not v:HasTag("shadowcreature") then
                v.components.health:DoDelta(-math.random(10, 50))
                teleport(v, exit_pos)
            end
        elseif v:HasTag("companion") then
            teleport(v, exit_pos)
        elseif v:IsValid() then
            v:Remove()
        end
    end

    for _, v in ipairs(TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"_inventoryitem"})) do
        teleport(v, exit_pos)
    end

    TheWorld:PushEvent("room_removed", {id = room_id})
end

--用途: 检查房间连接性和可达性
--
--代码作用:
--
--检查房间是否连接到出口房间(坐标0,0)
--
--检查是否有房间不可达（排除指定房间）
--
--使用深度优先遍历验证整个组的连接性
-- function InteriorSpawner:IsPlayerRoomConnectedToExit(house_id, interior_id, exclude_dir, exclude_room_id)
function InteriorSpawner:ConnectedToExitAndNoUnreachableRooms(current_interior, exclude_dir, exclude_room_id)
    local house_id = current_interior:GetGroupId()
    local interior_id = current_interior.interiorID
    local rooms = self.interior_groups[house_id]
    if not rooms then
        return false
    end

    local target_rooms = GetTableSize(rooms)
    if exclude_room_id then
        target_rooms = target_rooms - 1
    end
    local checked_rooms = {}
    local reached_rooms = 0

    local connected_to_exit = false

    local op_dir_str =
    {
        ["north"] = "south",
        ["east"]  = "west",
        ["south"] = "north",
        ["west"]  = "east",
    }

    local function WalkRooms(current_interior_id, exclude_direction)
        if current_interior_id == exclude_room_id then
            return
        end

        checked_rooms[current_interior_id] = true
        reached_rooms = reached_rooms + 1

        local coord_x, coord_y = self:GetInteriorCenter(current_interior_id):GetCoordinates()
        if coord_x == 0 and coord_y == 0 then
            connected_to_exit = true
        end

        local surrounding_rooms = self:GetConnectedSurroundingPlayerRooms(house_id, current_interior_id, exclude_direction)
        for next_dir, room_id in pairs(surrounding_rooms) do
            if not checked_rooms[room_id] then
                WalkRooms(room_id, op_dir_str[next_dir])
            end
        end
    end
    WalkRooms(interior_id, exclude_dir)

    return connected_to_exit and reached_rooms == target_rooms
end


return InteriorSpawner
