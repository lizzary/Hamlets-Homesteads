local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("inventoryitem", function(self, inst)
    inst:AddTag("isinventoryitem")
    self.onimpassable = false
end)

local InventoryItem = require("components/inventoryitem")

-- 确保物品在室内区域内的正确位置
function InventoryItem:KeepOnInterior()
    local x, y, z = self.inst.Transform:GetWorldPosition()

    if TheWorld.components.interiorspawner == nil then
        return
    end

    local isininteriorregion = TheWorld.components.interiorspawner:IsInInteriorRegion(x, z)
    local isininteriorroom = TheWorld.components.interiorspawner:IsInInteriorRoom(x, z)

    if isininteriorregion and not isininteriorroom then
        local pt = Vector3(x, y, z)
        local dest = FindNearbyLand(pt, 1)
        if not dest then
            dest = FindNearbyLand(pt, 2)
        end
        if not dest then
            dest = FindNearbyLand(pt, 4)
        end
        if dest ~= nil then
            if self.inst.Physics ~= nil then
                self.inst.Physics:Teleport(dest:Get())
            elseif self.inst.Transform ~= nil then
                self.inst.Transform:SetPosition(dest:Get())
            end
        end
    end
end

local _OnDropped = InventoryItem.OnDropped
function InventoryItem:OnDropped(randomdir, speedmult, skipfall)
    _OnDropped(self, randomdir, speedmult)
    self:SetLanded(false, true)
end

local _SetLanded = InventoryItem.SetLanded
function InventoryItem:SetLanded(is_landed, should_poll_for_landing)
    if is_landed or not should_poll_for_landing then
        self.inst:RemoveTag("falling")
    else
        self.inst:AddTag("falling")
        self:KeepOnInterior()
    end
    _SetLanded(self, is_landed, should_poll_for_landing)
end

local _OnUpdate = InventoryItem.OnUpdate
function InventoryItem:OnUpdate(dt, ...)
    local x, y, z = self.inst.Transform:GetWorldPosition()

    if x and y and z and self.inst.Physics and self.inst.Physics:GetCollisionGroup() == COLLISION.ITEMS then
        local isimpassable = TheWorld.Map and TheWorld.Map.IsImpassableAtPoint and TheWorld.Map:IsImpassableAtPoint(x, 0, z) or false
        if self.inst.Physics then
            if not self.onimpassable and isimpassable then
                self:SetLanded(false, true)
                self.onimpassable = true
                self.inst.Physics:ClearCollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
            elseif self.onimpassable and not isimpassable then
                self.onimpassable = false
                self.inst.Physics:CollidesWith(COLLISION.GROUND - COLLISION.VOID_LIMITS)
                self.inst.AnimState:SetLayer(LAYER_WORLD)
            end
        end
    end
    if self.onimpassable and self.inst.Physics and self.inst.Physics:GetCollisionGroup() == COLLISION.ITEMS then
        self:KeepOnInterior()
        if y then
            if y < -0.01 then
                self.inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
                self.inst.Physics:CollidesWith(COLLISION.VOID_LIMITS)
            else
                self.inst.AnimState:SetLayer(LAYER_WORLD)
                self.inst.Physics:ClearCollidesWith(COLLISION.VOID_LIMITS)
            end
            if y < -3 then
                self:TryToSink()
                if not self.inst:HasTag("irreplaceable") then
                    self.inst:StopUpdatingComponent(self)
                end
            end
        else
            self:TryToSink()
            if not self.inst:HasTag("irreplaceable") then
                self.inst:StopUpdatingComponent(self)
            end
        end
    else
        return _OnUpdate(self, dt, ...)
    end
end

function InventoryItem:Launch(veldirect)
    if self.inst.Physics == nil then
        return
    end

    self:SetLanded(false, true)
    self.inst.Physics:SetVel(veldirect:Get())
end

local _SinkEntity = SinkEntity
function SinkEntity(entity, ...)
    if not entity:IsValid() then
        return _SinkEntity(entity, ...)
    end

    local px, py, pz = 0, 0, 0
    if entity.Transform then
        px, py, pz = entity.Transform:GetWorldPosition()

        if entity.persists
            and entity.components.inventoryitem
            and entity.components.inventoryitem.cangoincontainer
            and TheWorld.Map and TheWorld.Map.IsImpassableAtPoint and TheWorld.Map:IsImpassableAtPoint(px, py, pz) then

            local fx = SpawnPrefab("splash_water_sink")
            if fx then
                fx.Transform:SetPosition(px, py, pz)
            end
            return
        end
    end

    if entity.components.inventory then
        entity.components.inventory:DropEverything()
    end

    if entity.components.container then
        entity.components.container:DropEverything()
    end

    if entity:HasTag("oversized_veggie") then
        if entity.Transform then
            entity.Transform:SetPosition(px, py, pz)
        end
        return
    end

    local fx = SpawnPrefab((TheWorld.Map and TheWorld.Map.IsImpassableAtPoint and TheWorld.Map:IsImpassableAtPoint(px, py, pz)) and "splash_clouds_drop" or "splash_sink")
    if fx then
        fx.Transform:SetPosition(px, py, pz)
    end

    if entity:HasTag("irreplaceable") then
        local safe_pos = FindNearbyLand(Vector3(px, py, pz), 10)
        if safe_pos then
            if entity.Physics then
                entity.Physics:Stop()
            end
            entity.Transform:SetPosition(safe_pos:Get())
        else
            local portal = TheSim:FindFirstEntityWithTag("multiplayer_portal")
            if portal and portal:IsValid() then
                entity.Transform:SetPosition(portal.Transform:GetWorldPosition())
            end
        end
    else
        entity:Remove()
    end
end
