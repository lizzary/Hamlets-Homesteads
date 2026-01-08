local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)

local InventoryItem = require("components/inventoryitem_replica")

local _CanDeploy = InventoryItem.CanDeploy
function InventoryItem:CanDeploy(pt, mouseover, deployer, rot, ...)
    local ret = _CanDeploy(self, pt, mouseover, deployer, rot, ...)
    if self.inst.candeployfn then
        return ret and self.inst.candeployfn(self.inst, pt, mouseover, deployer, rot)
    end
    return ret
end

local _SetOwner = InventoryItem.SetOwner
function InventoryItem:SetOwner(owner, ...)
    return _SetOwner(self, owner, ...)
end
