-- component that record infomations about player interior status
local CC_DEF_INDEX = require("main/interior_texture_defs").CC_DEF_INDEX

--------------------辅助函数---------------------------------
--on_x, on_z：同步外部位置到客户端副本
--
--on_exterior_icon：同步外部图标到客户端副本
--
--on_center_ent：同步当前中心实体到客户端副本
--
--on_interior_cc：同步颜色立方体纹理到客户端副本
local function on_x(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_x:set(math.floor(value + 0.5))
    end
end

local function on_z(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_pos_z:set(math.floor(value + 0.5))
    end
end

local function on_exterior_icon(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.exterior_icon:set(value)
    end
end

local function on_center_ent(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.center_ent:set(value)
    end
end

local function on_interior_cc(self, value)
    if self.inst.replica.interiorvisitor then
        self.inst.replica.interiorvisitor.interior_cc:set(CC_DEF_INDEX[value] or 0)
    end
end
----------------------------------------------------------
local function init(inst)
    local interiorvisitor = inst.components.interiorvisitor
    if interiorvisitor then
        interiorvisitor:Init()
    end
end

local function on_respawned_from_ghost(inst)
    local interiorvisitor = inst.components.interiorvisitor
    if interiorvisitor then
        interiorvisitor:RecordMapOnEnteringNewRoom()
    end
end

--1. 构造函数 InteriorVisitor
--用途：初始化组件实例
--
--详细说明：
--
--创建组件的所有数据字段（位置、图标、地图数据等）
--
--设置属性变化的监听回调函数
--
--延迟执行init函数
--
--监听房间移除和玩家复活事件
--
--初始化各种数据表（地图数据、同步队列、实体跟踪表等）
local InteriorVisitor = Class(function(self, inst)
    self.inst = inst
    self.exterior_pos_x = 0
    self.exterior_pos_z = 0
    self.exterior_icon = ""
    self.interior_cc = "images/colour_cubes/day05_cc.tex"
    self.center_ent = nil
    self.last_center_ent = nil
    self.interior_map = {}
    self.scheduled_sync_map_data = {
        addition = {},
        deletion = {},
    }
    self.always_shown_minimap_entities = {}
    self.room_visited_time = {}

    self.update_hud_indicatable_entities = {}

    -- self.restore_physics_task = nil

    self.last_mainland_pos = nil

    self.inst:DoStaticTaskInTime(0, init)
    self.record_map_on_room_removal = function(_, data)
        self:RecordMap(data.id, nil)
    end
    self.inst:ListenForEvent("room_removed", self.record_map_on_room_removal, TheWorld)
    self.inst:ListenForEvent("ms_respawnedfromghost", on_respawned_from_ghost)
end, nil,
{
    exterior_pos_x = on_x,
    exterior_pos_z = on_z,
    exterior_icon = on_exterior_icon,
    center_ent = on_center_ent,
    interior_cc = on_interior_cc,
})

--用途：清理组件移除时的资源
--
--详细说明：
--
--移除所有监听的事件回调
--
--防止内存泄漏和残留事件监听
function InteriorVisitor:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("room_removed", self.record_map_on_room_removal, TheWorld)
    self.inst:RemoveEventCallback("ms_respawnedfromghost", on_respawned_from_ghost)
end

--用途：设置玩家进入房间前的室外位置
--
--详细说明：
--
--记录玩家从室外进入房间时的位置坐标
--
--用于玩家离开房间时返回到正确位置
function InteriorVisitor:SetExteriorPosition(x, z)
    self.exterior_pos_x = x
    self.exterior_pos_z = z
end

--位与运算，用于物理碰撞掩码计算
local function BitAND(a,b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a%2, b%2
        if ra + rb >1 then c = c + p end
        a, b, p = (a-ra)/2, (b-rb)/2, p*2
    end
    return c
end

--用途：更新玩家和生物的物理碰撞
--
--详细说明：
--
--在房间内调整实体的物理碰撞组
--
--防止玩家和生物在房间边界处卡住
--
--查找房间内所有需要调整物理的实体
function InteriorVisitor:UpdatePlayerAndCreaturePhysics(ent)
    local center = ent:GetPosition()
    local radius = ent:GetSearchRadius()
    for _, v in ipairs(TheSim:FindEntities(center.x, 0, center.z, radius, nil, {"INLIMBO", "pl_invisiblewall"})) do
        if v.Physics ~= nil and v.Physics:GetCollisionGroup() ~= COLLISION.OBSTACLES then
            self:TunePhysics(v, ent)
        end
    end
end

--用途：调整单个实体的物理设置
--
--详细说明：
--
--判断实体是否靠近房间边界
--
--如果实体靠近不可见墙，则临时移除与障碍物的碰撞
--
--避免实体在房间边界处被卡住
function InteriorVisitor:TunePhysics(inst, ent)
    if inst and inst:IsValid() and inst.Physics ~= nil then
        local player_pos = inst:GetPosition()
        local center_pos = ent:GetPosition()
        local offset = center_pos - player_pos
        local width, depth = ent:GetSize()
        if (math.abs(offset.x) > depth/2 + 1 or math.abs(offset.z) > width/2 + 1)
            and #(TheSim:FindEntities(player_pos.x, 0, player_pos.z, 2, {"pl_invisiblewall"})) > 0 then
            local mask = inst.Physics:GetCollisionMask()
            if BitAND(mask, COLLISION.OBSTACLES) > 0 then
                inst.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
                self:DelayRestorePhysics(inst, .4)
            end
        end
    end
end

--用途：延迟恢复实体的物理碰撞
--
--详细说明：
--
--在一段时间后恢复实体的正常碰撞设置
--
--取消现有的恢复任务（避免重复）
--
--确保物理调整是临时的
function InteriorVisitor:DelayRestorePhysics(inst, delay)
    if inst.interiorvisitor_restore_physics_task then
        inst.interiorvisitor_restore_physics_task:Cancel()
    end

    inst.interiorvisitor_restore_physics_task = inst:DoTaskInTime(delay or 1, function()
        if inst.Physics then
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
        end
    end)
end

--检查是否为蚁丘房间
local function is_anthill_room(id)
    local interior_spawner = TheWorld.components.interiorspawner
    local interior_define = interior_spawner:GetInteriorDefinition(id)
    return interior_define and interior_define.dungeon_name == "ANTHILL1"
end


--用途：记录或更新房间的地图数据
--
--详细说明：
--
--记录玩家探索过的房间信息
--
--保存房间访问时间
--
--通过RPC将地图数据同步到客户端
--
--支持批量同步优化（延迟发送）
function InteriorVisitor:RecordMap(id, data, no_send)
    self.interior_map[id] = data

    if data then
        self.room_visited_time[id] = TheWorld.components.worldtimetracker:GetTime()
    else
        self.room_visited_time[id] = nil
    end

    if no_send then
        return
    end

    self.scheduled_sync_map_data.addition[id] = data
    if not data then
        table.insert(self.scheduled_sync_map_data.deletion, id)
    end
    if not self.scheduled_sync_map_data_task then
        self.scheduled_sync_map_data_task = self.inst:DoStaticTaskInTime(0, function()
            if not IsTableEmpty(self.scheduled_sync_map_data.deletion) then
                SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "remove_interior_map"), self.inst.userid, ZipAndEncodeString(self.scheduled_sync_map_data.deletion))
            end
            if not IsTableEmpty(self.scheduled_sync_map_data.addition) then
                SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "interior_map"), self.inst.userid, ZipAndEncodeString(self.scheduled_sync_map_data.addition))
            end
            self.scheduled_sync_map_data = {
                addition = {},
                deletion = {},
            }
            self.scheduled_sync_map_data_task = nil
        end)
    end
end

--用途：重置蚁丘房间的门地图数据
--
--详细说明：
--
--根据迷宫重置时间更新蚁丘房间的门状态
--
--将过时的门标记为未知状态
--
--只在蚁丘迷宫重置后重新探索门
function InteriorVisitor:RecordAnthillDoorMapReset(no_send)
    local anthill_entrance = TheWorld.anthill_entrance
    if not anthill_entrance then
        print("No anthill entrance!")
        return
    end

    for id, data in pairs(self.interior_map) do
        if is_anthill_room(id) then
            if id == (self.center_ent and self.center_ent.interiorID) then
                self:RecordMap(id, data, true)
            elseif self.room_visited_time[id] < anthill_entrance.maze_reset_time then
                for _, door in ipairs(data.doors) do
                    door.unknown = true
                    door.hidden = false
                end
                self:RecordMap(id, data, no_send)
            end
        end
    end
    if self.center_ent and is_anthill_room(self.center_ent.interiorID) then
        self:UpdateSurroundingDoorMaps(self.center_ent, nil, self.interior_map[self.center_ent.interiorID])
    end
end

--用途：验证和迁移地图数据
--
--详细说明：
--
--检查已记录的房间是否仍然存在
--
--更新旧版本数据格式（添加组ID、坐标等）
--
--确保地图数据的完整性
--
--自动重置过时的蚁丘门数据
function InteriorVisitor:ValidateAndMigrateMapData()
    for id, map_data in pairs(self.interior_map) do
        local center = TheWorld.components.interiorspawner:GetInteriorCenter(id)
        if not center or (map_data.uuid and map_data.uuid ~= center.uuid) then
            self.interior_map[id] = nil
            self.room_visited_time[id] = nil
        else
            if not map_data.group_id then
                local group_id = center:GetGroupId()
                local x, y = center:GetCoordinates()
                map_data.group_id = group_id
                map_data.coord_x = x
                map_data.coord_y = y
            end
            if not self.room_visited_time[id] then
                self.room_visited_time[id] = TheWorld.components.worldtimetracker:GetTime()
            end
        end
    end
    self:RecordAnthillDoorMapReset(true)
end

local op_dir_str = {
    north = "south",
    east  = "west",
    south = "north",
    west  = "east",
}

--获取指定方向的房门实体
local function get_door_at_direction(center, direction)
    local x, _, z = center.Transform:GetWorldPosition()
    local doors = TheSim:FindEntities(x, 0, z, TUNING.ROOM_FINDENTITIES_RADIUS, {"interior_door", "door_"..direction})
    return doors[1]
end

--用途：更新相邻房间的门状态
--
--详细说明：
--
--同步当前房间门的状态到相邻房间
--
--确保门的状态在相连房间间保持一致
--
--处理门的隐藏、禁用和未知状态
function InteriorVisitor:UpdateSurroundingDoorMaps(center_ent, last_center_ent, map_data)
    if not map_data then
        return
    end
    local interior_spawner = TheWorld.components.interiorspawner
    for _, door in ipairs(map_data.doors) do
        local target_interior = door.target_interior
        local target_interior_map = self.interior_map[target_interior]
        if target_interior_map then
            local target_center = interior_spawner:GetInteriorCenter(target_interior)
            if target_center and target_center ~= last_center_ent then
                local door_ent = get_door_at_direction(center_ent, door.direction)
                local hidden = door_ent:HasTag("door_hidden")
                local disabled = door_ent:HasTag("door_disabled")
                for _, target_interior_door in ipairs(target_interior_map.doors) do
                    if target_interior_door.direction == op_dir_str[door.direction] then
                        local dirty = false
                        if target_interior_door.hidden ~= hidden then
                            target_interior_door.hidden = hidden
                            dirty = true
                        end
                        if target_interior_door.disabled ~= disabled then
                            target_interior_door.disabled = disabled
                            dirty = true
                        end
                        if target_interior_door.unknown then
                            target_interior_door.unknown = nil
                            dirty = true
                        end
                        if dirty then
                            self:RecordMap(target_interior, target_interior_map)
                        end
                        break
                    end
                end
            end
        end
    end
end

--用途：检查是否可以记录房间地图
--
--详细说明：
--
--检查玩家是否为幽灵状态
--
--允许幽灵记录已探索过的房间
--
--防止幽灵记录未探索的新房间
function InteriorVisitor:CanRecordMap(room_id)
    -- Can record if we're not ghost or if have previously visited this room
    return not self.inst:HasTag("playerghost") or self.interior_map[room_id]
end

--用途：玩家进入新房间时记录地图
--
--详细说明：
--
--记录当前房间的地图数据
--
--更新离开的房间的地图数据（忽略非缓存项）
--
--同步相邻房间的门状态
function InteriorVisitor:RecordMapOnEnteringNewRoom(last_center)
    local current_center = self.center_ent
    if current_center and self:CanRecordMap(current_center.interiorID) then
        local map_data = current_center:CollectMinimapData()
        self:UpdateSurroundingDoorMaps(current_center, last_center, map_data)
        self:RecordMap(current_center.interiorID, map_data)
    end
    -- Record again and ignore non cacheable things once we're out of the last visited room
    if last_center and last_center ~= current_center and last_center:IsValid() and self:CanRecordMap(last_center.interiorID) then
        local map_data = last_center:CollectMinimapData(true)
        self:UpdateSurroundingDoorMaps(last_center, current_center, map_data)
        self:RecordMap(last_center.interiorID, map_data)
    end
end

--获取房间对应的外部世界实体
local function GetExterior(center)
    local door = center:GetDoorToExterior()
    if door then
        local exterior = TheWorld.components.interiorspawner:GetExteriorById(door.components.door.interior_name)
        if exterior then
            return exterior
        end
    end
end

--用途：获取最后进入的外部世界位置
--
--详细说明：
--
--优先获取当前房间的外部出口
--
--如果当前房间没有外部出口，则遍历已连接的房间
--
--返回任何可用的外部出口位置
-- Get the current room's exterior or fallback to any of the exit exteriors from all connected rooms
function InteriorVisitor:GetLastEnteredExterior()
    local interior_spawner = TheWorld.components.interiorspawner
    local exterior = GetExterior(self.center_ent)
    if exterior then
        return exterior
    end
    for room in pairs(interior_spawner:GetAllConnectedRooms(self.center_ent)) do
        if self.interior_map[room.interiorID] then
            local exterior = GetExterior(self.center_ent)
            if exterior then
                return exterior
            end
        end
    end
end

--用途：更新玩家的室内外状态和位置信息
--
--详细说明：
--
--检测玩家是否在房间内
--
--处理房间进入/离开事件
--
--更新外部位置和图标
--
--记录离开房间时的位置
--
--触发相关事件（进入室内、离开室内、房间组变化）
function InteriorVisitor:UpdateExteriorPos()
    local interior_spawner = TheWorld.components.interiorspawner
    local x, _, z = self.inst.Transform:GetWorldPosition()
    local ent = interior_spawner:GetInteriorCenter(Vector3(x, 0, z))

    self.center_ent = ent
    local last_center_ent = self.last_center_ent
    self.last_center_ent = ent

    if last_center_ent ~= ent then
        self:RecordMapOnEnteringNewRoom(last_center_ent)
    end

    if ent then
        if not self.inst:HasTag("inside_interior") then
            self.inst:AddTag("inside_interior")
        end
        if last_center_ent ~= ent then
            self.inst:PushEvent("enterinterior", {from = last_center_ent, to = ent})
            if last_center_ent ~= nil 
                and last_center_ent:IsValid()
                and ent ~= nil
                and ent:IsValid()
                and ent:IsInSameRoomGroup(last_center_ent) then

            else
                self.inst:PushEvent("roomgroupchange")
            end
        end
        self.interior_cc = ent.interior_cc
        self:UpdatePlayerAndCreaturePhysics(ent)

        -- If we just entered a room from outside
        if not last_center_ent then
            local exterior = self:GetLastEnteredExterior()
            if exterior then
                local x, _, z = exterior.Transform:GetWorldPosition()
                self:SetExteriorPosition(x, z)
                if exterior.MiniMapEntity then
                    self.exterior_icon = exterior.MiniMapEntity:GetIcon() or ""
                end
            end
        end
    else
        if self.inst:HasTag("inside_interior") then
            self.inst:RemoveTag("inside_interior")
            self.inst:PushEvent("leaveinterior", {from = last_center_ent, to = nil})
        end

        if not interior_spawner:IsInInteriorRegion(x, z) then
            self.last_mainland_pos = {x = x, z = z}
        end
        self.exterior_icon = ""
    end

    self:RevealAlwaysShownMinimapEntities()
    self:UpdateHudIndicatableEntities()
end

--检查玩家是否可以揭示实体
local function can_reveal_entity(player, entity)
    local restriction = entity.MiniMapEntity:GetRestriction()
    return not restriction or player:HasTag(restriction)
end

--用途：显示始终可见的小地图实体
--
--详细说明：
--
--跟踪并显示当前房间组内的特殊实体图标
--
--同步到客户端的小地图显示
--
--处理实体的添加、更新和删除
--
--考虑玩家的揭示权限（通过标签检查）
function InteriorVisitor:RevealAlwaysShownMinimapEntities()
    if not self.center_ent then
        if not IsTableEmpty(self.always_shown_minimap_entities) then
            self.always_shown_minimap_entities = {}
            SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "always_shown_interior_map"), self.inst.userid, ZipAndEncodeString({ { type = "clear" } }))
        end
        return
    end

    -- 安全检查：确保interiormaprevealer组件存在（修复在原版游戏中的崩溃问题）
    if not TheWorld.components.interiormaprevealer or not TheWorld.components.interiormaprevealer.tracking_entities then
        -- 在原版游戏中，interiormaprevealer组件不存在，直接返回避免崩溃
        return
    end

    local sync_actions = {}

    for ent in pairs(self.always_shown_minimap_entities) do
        if not TheWorld.components.interiormaprevealer.tracking_entities[ent] then
            table.insert(sync_actions, {
                type = "delete",
                data = self.always_shown_minimap_entities[ent].id,
            })
            self.always_shown_minimap_entities[ent] = nil
        end
    end

    local interior_group = self.center_ent:GetGroupId()

    for ent in pairs(TheWorld.components.interiormaprevealer.tracking_entities) do
        local network_id = ent.Network and ent.Network:GetNetworkID()
        -- Some mods have entities with minimap icon but without network
        if network_id and not (ent.prefab == "globalmapicon" and ent._target and ent._target.prefab == "interiorworkblank") then
            local pos = ent:GetPosition()
            local center = TheWorld.components.interiorspawner:GetInteriorCenter(pos)
            local current_data = self.always_shown_minimap_entities[ent]
            if center and center ~= self.center_ent and interior_group == center:GetGroupId() and can_reveal_entity(self.inst, ent) then
                local icon = ent.MiniMapEntity:GetIcon()
                if icon ~= nil and icon ~= "" then
                    local offset = pos - center:GetPosition()
                    local priority = ent.MiniMapEntity:GetPriority() or 0
                    local coord_x, coord_y = center:GetCoordinates()
                    local has_changes = false
                    if not current_data then
                        current_data = {
                            id = network_id,
                            coord_x = coord_x,
                            coord_y = coord_y,
                            offset_x = offset.x,
                            offset_z = offset.z,
                            icon = icon,
                            priority = priority,
                        }
                        self.always_shown_minimap_entities[ent] = current_data
                        has_changes = true
                    elseif current_data.offset_x ~= offset.x
                        or current_data.offset_z ~= offset.z
                        or current_data.coord_x ~= coord_x
                        or current_data.coord_y ~= coord_y
                        or current_data.icon ~= icon
                        or current_data.priority ~= priority then

                        current_data.offset_x = offset.x
                        current_data.offset_z = offset.z
                        current_data.coord_x = coord_x
                        current_data.coord_y = coord_y
                        current_data.icon = icon
                        current_data.priority = priority
                        has_changes = true
                    end
                    if has_changes then
                        table.insert(sync_actions, {
                            type = "replace",
                            data = current_data,
                        })
                    end
                end
            elseif current_data then
                table.insert(sync_actions, {
                    type = "delete",
                    data = network_id,
                })
                self.always_shown_minimap_entities[ent] = nil
            end
        end
    end

    if not IsTableEmpty(sync_actions) then
        SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "always_shown_interior_map"), self.inst.userid, ZipAndEncodeString(sync_actions))
    end
end

--用途：更新HUD上可指示的实体（主要是其他玩家）
--
--详细说明：
--
--跟踪相邻房间内的其他玩家
--
--在HUD上显示附近玩家的位置
--
--只显示上下左右相邻的房间（非对角线）
--
--同步玩家的名称、位置和状态
-- This is basically the same as `InteriorVisitor:RevealAlwaysShownMinimapEntities`,
-- but for tracking HUD indicatables inside the interior
--
-- Note: we only track players for now
function InteriorVisitor:UpdateHudIndicatableEntities()
    if not self.center_ent then
        if not IsTableEmpty(self.update_hud_indicatable_entities) then
            self.update_hud_indicatable_entities = {}
            SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "update_hud_indicatable_entities"), self.inst.userid, ZipAndEncodeString({ { type = "clear" } }))
        end
        return
    end

    local sync_actions = {}

    for ent in pairs(self.update_hud_indicatable_entities) do
        if not table.contains(AllPlayers, ent) then
            table.insert(sync_actions, {
                type = "delete",
                data = self.update_hud_indicatable_entities[ent].id,
            })
            self.update_hud_indicatable_entities[ent] = nil
        end
    end

    local interior_group = self.center_ent:GetGroupId()
    local current_coord_x, current_coord_y = self.center_ent:GetCoordinates()

    for _, ent in ipairs(AllPlayers) do
        -- We can use either userid or network id here,
        -- but since dummy players (e.g. from `c_spawn("wilson")`) don't have userid
        -- we use network id here
        -- local userid = ent.userid
        local network_id = ent.Network and ent.Network:GetNetworkID()
        if network_id and ent ~= self.inst then
            local pos = ent:GetPosition()
            local center = TheWorld.components.interiorspawner:GetInteriorCenter(pos)
            local current_data = self.update_hud_indicatable_entities[ent]
            local should_show = false
            if center and center ~= self.center_ent and interior_group == center:GetGroupId() then
                local coord_x, coord_y = center:GetCoordinates()
                local is_x_adjacent = math.abs(current_coord_x - coord_x) == 1
                local is_y_adjacent = math.abs(current_coord_y - coord_y) == 1
                -- Only top down left right, no diagonal
                if (is_x_adjacent or is_y_adjacent) and not (is_x_adjacent and is_y_adjacent) then
                    local offset = pos - center:GetPosition()
                    local userflags = ent.Network:GetUserFlags()
                    local display_name = ent:GetDisplayName()
                    local has_changes = false
                    if not current_data then
                        current_data = {
                            id = network_id,
                            prefab = ent.prefab,
                            coord_x = coord_x,
                            coord_y = coord_y,
                            offset_x = offset.x,
                            offset_z = offset.z,
                            display_name = display_name,
                            userflags = userflags,
                        }
                        self.update_hud_indicatable_entities[ent] = current_data
                        has_changes = true
                    elseif current_data.offset_x ~= offset.x
                        or current_data.offset_z ~= offset.z
                        or current_data.coord_x ~= coord_x
                        or current_data.coord_y ~= coord_y
                        or current_data.display_name == display_name
                        or current_data.userflags == userflags then

                        current_data.offset_x = offset.x
                        current_data.offset_z = offset.z
                        current_data.coord_x = coord_x
                        current_data.coord_y = coord_y
                        current_data.display_name = display_name
                        current_data.userflags = userflags
                        has_changes = true
                    end
                    if has_changes then
                        table.insert(sync_actions, {
                            type = "replace",
                            data = current_data,
                        })
                    end
                    should_show = true
                end
            end
            if not should_show and current_data then
                table.insert(sync_actions, {
                    type = "delete",
                    data = network_id,
                })
                self.update_hud_indicatable_entities[ent] = nil
            end
        end
    end

    if not IsTableEmpty(sync_actions) then
        SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "update_hud_indicatable_entities"), self.inst.userid, ZipAndEncodeString(sync_actions))
    end
end

--用途：保存组件数据到存档
--
--详细说明：
--
--保存外部位置、大陆位置、图标
--
--保存所有探索过的房间地图数据
--
--保存房间访问时间戳
function InteriorVisitor:OnSave()
    return {
        -- The position of last exterior the player entered
        last_exterior_pos = {x = self.exterior_pos_x, z = self.exterior_pos_z},
        -- The position of the player before they entered a room
        last_mainland_pos = self.last_mainland_pos,
        exterior_icon = self.exterior_icon,
        interior_map = self.interior_map,
        room_visited_time = self.room_visited_time,
    }
end

--用途：从存档加载组件数据
--
--详细说明：
--
--恢复保存的所有数据
--
--转换旧版本数据格式
--
--如果房间被破坏，将玩家传送到安全位置
--
--防止玩家卡在已销毁的房间区域
function InteriorVisitor:OnLoad(data)
    if data.last_exterior_pos then
        self:SetExteriorPosition(data.last_exterior_pos.x, data.last_exterior_pos.z)
    end
    if data.last_mainland_pos then
        self.last_mainland_pos = data.last_mainland_pos
    end
    if data.exterior_icon then
        self.exterior_icon = data.exterior_icon
    end
    if data.interior_map then
        self.interior_map = data.interior_map
    end
    if data.room_visited_time then
        self.room_visited_time = data.room_visited_time
    end

    for id, map_data in pairs(self.interior_map) do -- 转换旧存档的数据格式
        if map_data.floor_texture then
            map_data.minimap_floor_texture = map_data.floor_texture
            map_data.floor_texture = nil
        end
    end

    -- restore player position if interior was destroyed
    if GetTick() > 0 and self.last_mainland_pos ~= nil then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
            and not TheWorld.components.interiorspawner:IsInInterior(x, z) then
            self.inst.Transform:SetPosition(self.last_mainland_pos.x, 0, self.last_mainland_pos.z)
        end
    end
end

--用途：初始化组件（在所有实体加载后调用）
--
--详细说明：
--
--验证和迁移地图数据
--
--通过延迟任务将完整地图数据发送到客户端
--
--处理客户端ThePlayer可能为nil的特殊情况
-- This should be called after all entities loaded
function InteriorVisitor:Init()
    self:ValidateAndMigrateMapData()
    -- Don't quite understand why ThePlayer can be nil when the client receives this,
    -- from HandleClientRPC in networkclientrpc.lua, it shouldn't happen, but it does anyway,
    -- since this is not critical to the client on initial load, use a delay here to mitigate this
    self.inst:DoStaticTaskInTime(3, function()
        SendModRPCToClient(GetClientModRPC("Hamlets_Homesteads", "interior_map"), self.inst.userid, ZipAndEncodeString(self.interior_map))
    end)
end

return InteriorVisitor
