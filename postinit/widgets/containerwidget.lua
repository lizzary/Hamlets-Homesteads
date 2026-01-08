local AddClassPostConstruct = AddClassPostConstruct
local PLENV = env
GLOBAL.setfenv(1, GLOBAL)

local InvSlot = require("widgets/invslot")
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")
local ImageButton = require("widgets/imagebutton")
local ContainerWidget = require("widgets/containerwidget")

if not rawget(_G, "HotReloading") then
    AddClassPostConstruct("widgets/containerwidget", function(self)
    end)
end

function PLENV.OnHotReload()
end 