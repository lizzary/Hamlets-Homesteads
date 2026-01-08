GLOBAL.setfenv(1, GLOBAL)

local params = require("containers").params

--架子容器配置
local shelf1 =
{
    widget = {
        slotpos = { Vector3(0, 0, 0) }
    },
    acceptsstacks = false,
}

local shelf1x3 = {
    widget = {
        slotpos = {
            Vector3(-85 + 20, 0,   0),
            Vector3(-85 + 20, -80, 0),
            Vector3(-85 + 20, 80,  0)
        },
    },
    acceptsstacks = false,
}

local shelf2x3 =
{
    widget = {
        slotpos = {
            Vector3(-165, -80, 0),
            Vector3(-85,  -80, 0),
            Vector3(-165, 0,   0),
            Vector3(-85,  0,   0),
            Vector3(-165, 80,  0),
            Vector3(-85,  80,  0)
        },
    },
    acceptsstacks = false,
}

-- 各种架子容器配置
params["shelf_displaycase_wood"] = shelf1x3
params["shelf_displaycase_metal"] = shelf1x3

params["shelf_wood"] = shelf2x3
params["shelf_basic"] = shelf2x3
params["shelf_metal"] = shelf2x3
params["shelf_marble"] = shelf2x3
params["shelf_glass"] = shelf2x3
params["shelf_ladder"] = shelf2x3
params["shelf_hutch"] = shelf2x3
params["shelf_industrial"] = shelf2x3
params["shelf_adjustable"] = shelf2x3
params["shelf_fridge"] = shelf2x3
params["shelf_cinderblocks"] = shelf2x3
params["shelf_midcentury"] = shelf2x3
params["shelf_wallmount"] = shelf2x3
params["shelf_aframe"] = shelf2x3
params["shelf_crates"] = shelf2x3
params["shelf_hooks"] = shelf2x3
params["shelf_pipe"] = shelf2x3
params["shelf_hattree"] = shelf2x3
params["shelf_pallet"] = shelf2x3
params["shelf_floating"] = shelf2x3

--遗迹的展示架子和猪女王的展示台，么用
params["shelf_ruins"] = shelf1
params["shelf_queen_display_1"] = shelf1
params["shelf_queen_display_2"] = shelf1
params["shelf_queen_display_3"] = shelf1
params["shelf_queen_display_4"] = shelf1

-- 商店购买者容器，没用
params["shop_buyer"] = shelf1
