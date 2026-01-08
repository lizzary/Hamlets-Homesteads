GLOBAL.setfenv(1, GLOBAL)

local easing = require("easing")

local ContainerWidget = require("widgets/containerwidget")

local PlayerHud = require("screens/playerhud")

local _CreateOverlays = PlayerHud.CreateOverlays
function PlayerHud:CreateOverlays(owner, ...)
    _CreateOverlays(self, owner, ...)
end


local _OnUpdate = PlayerHud.OnUpdate
function PlayerHud:OnUpdate(dt, ...)
    _OnUpdate(self, dt, ...)

end
