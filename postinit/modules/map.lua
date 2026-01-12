
GLOBAL.setfenv(1, GLOBAL)

local worldtiledefs = require("worldtiledefs")
require "components/map" --手动加载
local TILE_SCALE = TILE_SCALE

-- 保存原版实现
local _Original_IsPassableAtPoint = Map.IsPassableAtPoint
local _Original_IsImpassableAtPoint = Map.IsImpassableAtPoint
local _Original_IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint
local _Original_IsAboveGroundAtPoint = Map.IsAboveGroundAtPoint
local _Original_GetTileAtPoint = Map.GetTileAtPoint
local _Original_GetTile = Map.GetTile
local _Original_GetTileCenterPoint = Map.GetTileCenterPoint
-- 恢复室内家具相关的部署判定
local _Original_CanDeployRecipeAtPoint = Map.CanDeployRecipeAtPoint

-- 确保所有原始函数都存在
if not _Original_IsPassableAtPoint then
    _Original_IsPassableAtPoint = function(self, x, y, z, ...) return true end
end
if not _Original_IsImpassableAtPoint then
    _Original_IsImpassableAtPoint = function(self, x, y, z, ...) return false end
end
if not _Original_IsVisualGroundAtPoint then
    _Original_IsVisualGroundAtPoint = function(self, x, y, z, ...) return true end
end
if not _Original_IsAboveGroundAtPoint then
    _Original_IsAboveGroundAtPoint = function(self, x, y, z, ...) return true end
end
if not _Original_GetTileAtPoint then
    _Original_GetTileAtPoint = function(self, x, y, z, ...) return WORLD_TILES.GRASS end
end
if not _Original_GetTile then
    _Original_GetTile = function(self, x, y, ...) return WORLD_TILES.GRASS end
end
if not _Original_GetTileCenterPoint then
    _Original_GetTileCenterPoint = function(self, x, y, z, ...) return x, y, z end
end
if not _Original_CanDeployRecipeAtPoint then
    _Original_CanDeployRecipeAtPoint = function(self, pt, recipe, rot, player, ...) return true end
end

function Map:IsPassableAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return _Original_IsPassableAtPoint(self, x, y, z, ...)
end

function Map:IsImpassableAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return not TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return _Original_IsImpassableAtPoint(self, x, y, z, ...)
end

function Map:IsVisualGroundAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return _Original_IsVisualGroundAtPoint(self, x, y, z, ...)
end

function Map:ReverseIsVisualGroundAtPoint(x, y, z)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return _Original_IsVisualGroundAtPoint(self, x, y, z)
end

function Map:IsAboveGroundAtPoint(x, y, z, ...)
    if TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)
    end
    return _Original_IsAboveGroundAtPoint(self, x, y, z, ...)
end

function Map:GetTileAtPoint(x, y, z, ...)
    local tile = _Original_GetTileAtPoint(self, x, y, z, ...)
    if tile == WORLD_TILES.INVALID then
        if x and z and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
            if TheWorld.components.interiorspawner:IsInInteriorRoom(x, z) then
                tile = WORLD_TILES.INTERIOR
            else
                tile = WORLD_TILES.IMPASSABLE
            end
        end
    end
    return tile
end

function Map:GetTile(x, y, ...)
    local tile = _Original_GetTile(self, x, y, ...)
    if tile == WORLD_TILES.INVALID then
        local tx, _, tz = self:GetPointAtTile(x, y)
        if x and y and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(tx, tz) then
            if TheWorld.components.interiorspawner:IsInInteriorRoom(tx, tz) then
                tile = WORLD_TILES.INTERIOR
            else
                tile = WORLD_TILES.IMPASSABLE
            end
        end
    end
    return tile
end

function Map:GetTileCenterPoint(x, y, z, ...)
    if x and z and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
        return math.floor(x / 4) * 4 + 2, 0, math.floor(z / 4) * 4 + 2
    else
        return _Original_GetTileCenterPoint(self, x, y, z, ...)
    end
end

function Map:GetPointAtTile(x, y)
    local w, h = TheWorld.Map:GetSize()
    local tx = (x - w / 2) * TILE_SCALE
    local tz = (y - h / 2) * TILE_SCALE
    return tx, 0, tz
end

function Map:CanDeployRecipeAtPoint(pt, recipe, rot, player, ...)
    if recipe and pt and TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInteriorRegion(pt.x, pt.z) then
        -- 室内特殊家具（如墙饰、门、吊灯、柱子等）允许部署
        if recipe.build_mode == BUILDMODE.HOME_DECOR then
            return true
        elseif not TheWorld.components.interiorspawner:IsInInteriorRoom(pt.x, pt.z, -1) then
            return false
        end
        local x, y, z = pt:Get()
        if not self:ReverseIsVisualGroundAtPoint(x, y, z) then
            return false
        end
        return _Original_CanDeployRecipeAtPoint(self, pt, recipe, rot, player, ...)
    end
    return _Original_CanDeployRecipeAtPoint(self, pt, recipe, rot, player, ...)
end
