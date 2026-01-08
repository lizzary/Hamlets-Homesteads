local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "exterior_texture_packages", --房子外观
    "visual_slot", --架子上的物品槽
    "shelves", --架子家具
    "deco", --家具
    "deco_antiquities",--装饰品
    "deco_chair", --椅子
    "deco_lamp", --灯
    "deco_lightglow", --灯
    "deco_placers", --家具放置
    "deco_plantholder", --盆栽
    "deco_roomglow", --灯
    "deco_swinging_light", --灯
    "deco_table", --桌子
    "deco_wall_ornament", --墙饰
    "interior_boundary", --室内边界
    "interior_surface", --室内地
    "interior_texture_packages", --室内材质
    "interiorwall_fx", --墙特效
    "interiorfloor_fx", --地板特效
    "interiorworkblank", --默认布局
    "prop_door", --门
    "rugs", --地毯
    "playerhouse_city", --住房系统的核心文件
    "deed", --房屋产权证书
    "house_door", --门
    "construction_permit", --扩建许可证
    "construction_permit_kitchen",--同上，不过是厨房版的
    "construction_permit_lab", --同上，远古科技
    "demolition_permit", --拆除许可证
    "playerhouse_scaffold",
    "playerhouse_reconstruction",
    "target_indicator_marker",
    "kitchen_buff_foods",
}

Assets = {
    -- minimap
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("ATLAS", "images/hud/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/hud/pl_inventoryimages.xml", 256), -- for minisign

    -- crafting menu icons
    --Asset("ATLAS", "images/hud/pl_crafting_menu_icons.xml"),



    -- interior map toggle button and arrows
    Asset("ATLAS", "images/hud/pl_mapscreen_widgets.xml"),
    Asset("IMAGE", "images/hud/pl_mapscreen_widgets.tex"),

    -- Billboard
    Asset("SHADER", "shaders/animrotatingbillboard.ksh"),

    Asset("SHADER", "shaders/anim_vertical.ksh"), 

    -- Interior MiniMap --待精简
    Asset("ATLAS", "interior_minimap/interior_minimap.xml"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_marble_royal.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_marble_royal.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_ruins_slab.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_ruins_slab.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_antcave_floor.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_antcave_floor.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_vamp_cave_noise.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_vamp_cave_noise.tex"),

    Asset("ATLAS", "levels/textures/map_interior/mini_floor_wood.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_wood.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_woodpanels.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_woodpanels.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_marble.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_marble.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_checker.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_checker.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_checkered.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_checkered.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_cityhall.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_cityhall.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_sheetmetal.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_sheetmetal.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_geometrictiles.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_geometrictiles.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_shag_carpet.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_shag_carpet.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_transitional.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_transitional.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_herringbone.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_herringbone.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_hexagon.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_hexagon.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_hoof_curvy.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_hoof_curvy.tex"),
    Asset("ATLAS", "levels/textures/map_interior/mini_floor_octagon.xml"),
    Asset("IMAGE", "levels/textures/map_interior/mini_floor_octagon.tex"),

    -- Cookbook HD icons
    Asset("ATLAS", "images/hud/pl_cook_pot_food_image.xml"),
    Asset("IMAGE", "images/hud/pl_cook_pot_food_image.tex"),

    Asset("SHADER", "shaders/ui_fillmode.ksh"),
    Asset("SHADER", "shaders/ui_anim_cc_nolight.ksh"),
}

for _, v in ipairs(require("main/interior_texture_defs").Assets) do
    table.insert(Assets, v)
end

ToolUtil.RegisterInventoryItemAtlas("images/hud/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")
AddMinimapAtlas("interior_minimap/interior_minimap.xml")

local sounds = {
    --Asset("SOUND", "sound/DLC003_sfx.fsb"), --房子建造和进出的音效，建造和进出音效替换成了原版的猪房建造音效和栅栏门开关音效
    --Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
}

local shade_anim_assets =
{
} 
for _, v in ipairs(shade_anim_assets) do
    for i = 0, v.length do
        local realframe = i + 1
        local framepath = v.path..tostring(realframe)..".tex"
        table.insert(Assets, Asset("IMAGE", framepath))
    end
end

if not TheNet:IsDedicated() then
    for _, asset in ipairs(sounds) do
        table.insert(Assets, asset)
    end
end

