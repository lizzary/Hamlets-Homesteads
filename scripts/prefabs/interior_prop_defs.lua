local PROP_DEFS = {}

local EXIT_SHOP_SOUND = "dontstarve/common/together/gate/close"

-- 玩家房屋的默认布局
PROP_DEFS.playerhouse_city = function(exterior_door_def)
    return {
        {
            name = "prop_door",
            x_offset = 5,
            z_offset = 0,
            animdata = {
                minimapicon = "player_frontdoor.tex",
                bank ="pig_shop_doormats",
                build ="pig_shop_doormats",
                anim = "idle_old",
                background = true,
            },
            my_door_id = exterior_door_def.target_door_id,
            target_door_id = exterior_door_def.my_door_id,
            addtags={"guard_entrance"},
            usesounds={EXIT_SHOP_SOUND},
            is_exit = true,
        },

        { name = "deco_roomglow", x_offset = 0, z_offset = 0 },

        { name = "shelf_cinderblocks",      x_offset = -4.5, z_offset = -15/3.5, addtags={"playercrafted"} },
        { name = "deco_antiquities_wallfish", x_offset = -5,   z_offset =  3.9,    rotation = 90, addtags={"playercrafted"} },

        { name = "deco_antiquities_cornerbeam",  x_offset = -5,  z_offset =  -15/2, rotation =  90, flip=true, addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam",  x_offset = -5,  z_offset =   15/2, rotation =  90,            addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset =  -15/2, rotation =  90, flip=true, addtags={"playercrafted"} },
        { name = "deco_antiquities_cornerbeam2", x_offset = 4.7, z_offset =   15/2, rotation =  90,            addtags={"playercrafted"} },
        { name = "swinging_light_rope_1",        x_offset = -2,  z_offset =  0,                addtags={"playercrafted"} },

        { name = "charcoal", x_offset = -3, z_offset = -2 },
        { name = "charcoal", x_offset =  2, z_offset =  3 },

        { name = "window_tall_curtain", x_offset = 0, z_offset = 15/2, rotation = 90, addtags={"playercrafted"} },
    }
end

local function GenerateProps(name, ...)
    if not PROP_DEFS[name] then
        print("Undefined interior prop: " .. name)
        return {}
    end

    return PROP_DEFS[name](...)
end

return GenerateProps
