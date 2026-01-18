local BindingHouse = Class(function(self, inst)
    self.inst = inst
	self.recall_x = nil
	self.recall_y = nil
	self.recall_z = nil
	self.group_id = nil

	inst:AddTag("recall_unmarked")
end)

function BindingHouse:MarkPosition(recall_x, recall_y, recall_z, recall_worldid)
	if recall_x ~= nil then
		recall_x, recall_y, recall_z = recall_x or 0, recall_y or 0, recall_z or 0
		--V2C: this (instead of IsTeleportLinkingPermittedFromPoint) will still allow within arena
		if not IsTeleportingPermittedFromPointToPoint(recall_x, recall_y, recall_z, recall_x, recall_y, recall_z) then
			return false, "NO_TELEPORT_ZONE"
		end
		self.recall_x = recall_x
		self.recall_y = recall_y
		self.recall_z = recall_z
		self.inst:RemoveTag("recall_unmarked")

		self.recall_worldid = recall_worldid or TheShard:GetShardId()
	end

	if self.onMarkPosition ~= nil then
		self.onMarkPosition(self.inst, recall_x, recall_y, recall_z, recall_worldid)
	end
	return true
end

function BindingHouse:CopyFrom(deed)
	if deed.components.bindinghouse then
		--lua的拷贝机制...底层代码这一块
		local bh = deed.components.bindinghouse
		self:MarkPosition(bh.recall_x, bh.recall_y, bh.recall_z, bh.recall_worldid)
		self:BindHouseById(bh.group_id)
		self.inst.purplegem = deed.purplegem
		self.inst.components.rechargeable:SetChargeTime(deed.components.rechargeable.chargetime)
		self.inst.components.rechargeable:SetCharge(deed.components.rechargeable.current)
		self.inst.components.named:SetName(deed.components.named.name)
	end
end

function BindingHouse:IsMarked()
	return self.recall_worldid ~= nil
end

function BindingHouse:IsMarkedForSameShard()
	return self.recall_worldid == TheShard:GetShardId()
end

function BindingHouse:GetMarkedPosition()
	return self.recall_x, self.recall_y, self.recall_z
end

function BindingHouse:BindHouseById(group_id)
    self.group_id = group_id
end

function BindingHouse:CheckHouseExist()
    if TheWorld.components.interiorspawner ~= nil then
        if TheWorld.components.interiorspawner.interior_groups[self.group_id] ~= nil then
            return true
        end
    end

    return false
end

function BindingHouse:OnSave()
	return {
		recall_x = self.recall_x,
		recall_y = self.recall_y,
		recall_z = self.recall_z,
		recall_worldid = self.recall_worldid,
		group_id = self.group_id
	}
end

function BindingHouse:OnLoad(data)
    if data ~= nil then
        if data.recall_worldid ~= nil then
            self:MarkPosition(data.recall_x, data.recall_y, data.recall_z, data.recall_worldid)
        end
        if data.group_id ~= nil then
            self.group_id = data.group_id
        end
    end
end

return BindingHouse