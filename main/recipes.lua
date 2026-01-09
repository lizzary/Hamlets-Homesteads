local AddDeconstructRecipe = AddDeconstructRecipe
local AddRecipe2 = AddRecipe2
local AddRecipeFilter = AddRecipeFilter
local AddPrototyperDef = AddPrototyperDef
local AddRecipePostInit = AddRecipePostInit
GLOBAL.setfenv(1, GLOBAL)

local TechTree = require("techtree")

local change_recipes = require("main/change_recipes")
local DISABLE_RECIPES = change_recipes.DISABLE_RECIPES
local LOST_RECIPES = change_recipes.LOST_RECIPES

-- 原有的配方修改代码

for i, recipe_name in ipairs(DISABLE_RECIPES) do
    AddRecipePostInit(recipe_name, function(recipe)
        recipe.disabled_worlds = { "porkland" }
    end)
end

for i, recipe_name in ipairs(LOST_RECIPES) do
    AddRecipePostInit(recipe_name, function(recipe)
        recipe.level = TechTree.Create(TECH.LOST)
    end)
end

--AllRecipes["cookbook"].ingredients = {Ingredient("papyrus", 1), Ingredient("radish", 1)} -- TODO: 检测世界来修改配方

local _telebase_testfn = AllRecipes["telebase"].testfn
AllRecipes["telebase"].testfn = function(pt, rot, ...)
    if TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z) then
        return false
    end

    return _telebase_testfn(pt, rot, ...)
end

local _GetValidRecipe = GetValidRecipe
function GetValidRecipe(recipe_name, ...)
    local recipe = _GetValidRecipe(recipe_name, ...)
    if recipe and TheWorld and (recipe.disabled_worlds and TheWorld:HasTags(recipe.disabled_worlds)) then
        return
    end
    return recipe
end

local function SortRecipe(a, b, filter_name, offset)
    local filter = CRAFTING_FILTERS[filter_name]
    if filter and filter.recipes then
        for sortvalue, product in ipairs(filter.recipes) do
            if product == a then
                table.remove(filter.recipes, sortvalue)
                break
            end
        end

        local target_position = #filter.recipes + 1
        for sortvalue, product in ipairs(filter.recipes) do
            if product == b then
                target_position = sortvalue + offset
                break
            end
        end
        table.insert(filter.recipes, target_position, a)
    end
end

local function SortBefore(a, b, filter_name)  -- a before b
    SortRecipe(a, b, filter_name, 0)
end

local function SortAfter(a, b, filter_name)  -- a after b
    SortRecipe(a, b, filter_name, 1)
end

local function rebuild_techtree(name)
    TECH.NONE = TechTree.Create()

    for k, v in pairs(AllRecipes) do
        v.level = TechTree.Create(v.level)
    end

    for k, v in pairs(TUNING.PROTOTYPER_TREES) do
        v = TechTree.Create(v)
        TUNING.PROTOTYPER_TREES[k] = TUNING.PROTOTYPER_TREES[k] or {}
        TUNING.PROTOTYPER_TREES[k][name] = TUNING.PROTOTYPER_TREES[k][name] or 0
    end
end

-- Taken from GlassicAPI
-- custom tech allows you to build custom prototyper or allows muliti prototypers to bonus a tech simultaneously.
-- e.g. GlassicAPI.AddTech("FRIENDSHIPRING")
---@param name string
local function AddTech(name, bonus_available)
    table.insert(TechTree.AVAILABLE_TECH, name)
    if bonus_available then
       table.insert(TechTree.BONUS_TECH, name)
    end
    rebuild_techtree(name)
end

local function AquaticRecipe(name, data)
    if AllRecipes[name] then
        -- data = {distance=, shore_distance=, platform_distance=, shore_buffer_max=, shore_buffer_min=, platform_buffer_max=, platform_buffer_min=, aquatic_buffer_min=, noshore=}
        data = data or {}
        data.platform_buffer_max = data.platform_buffer_max or
                                       (data.platform_distance and math.sqrt(data.platform_distance)) or
                                       (data.distance and math.sqrt(data.distance)) or nil
        data.shore_buffer_max = data.shore_buffer_max or (data.shore_distance and ((data.shore_distance + 1) / 2)) or
                                    nil
        AllRecipes[name].aquatic = data
        AllRecipes[name].build_mode = BUILDMODE.WATER
    end
end

--AddTech("CITY", true)
AddTech("HOME", true)

-- home filter
AddRecipeFilter({
    name =  "HOME_MISC", -- "reno_tab_homekits",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_homekits.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_COLUMN",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_columns.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_RUG",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_rugs.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_HANGINGLAMP",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_hanginglamps.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_LAMP",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_lamps.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_PLANTHOLDER",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_plantholders.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_FURNITURE",  -- shelves, chairs, tables
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_shelves.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_WALL_DECORATION",  -- ornaments
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_windows.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_WALLPAPER",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_wallpaper.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_FLOOR",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_floors.tex",
    home_prototyper = true,
}, 1)

AddRecipeFilter({
    name = "HOME_DOOR",
    atlas = "images/hud/pl_inventoryimages.xml",
    image = "reno_tab_doors.tex",
    home_prototyper = true,
}, 1)

--禁止房子在一些地块上建造，比如码头，以免出现水上房子和房子堆叠、悬空房子废墟的现象
-- 禁止建造的地块编号列表
local FORBIDDEN_TILE_IDS = {
    260,--洞穴探险桥
    263,-- 码头地块
    262,-- 玫瑰桥
    201, --水上
    --还有什么临时地块后续会补充
}

--[[ 在游戏中打开控制台，输入以下命令来查看当前位置的地块编号：（要整段复制过去！！！）然后在游戏日志中查看

local _x, _y, _z = ThePlayer:GetPosition():Get();
local x, y = TheWorld.Map:GetTileCoordsAtPoint(_x, _y, _z);
local tile = TheWorld.Map:GetTile(x, y);
print("当前地块编号: " .. tile)
]]

-- 检查地块是否被禁止
local function IsForbiddenTile(pt)
    local ground_tile = TheWorld.Map:GetTileAtPoint(pt.x, pt.y, pt.z)
    if ground_tile then
        for _, forbidden_tile_id in ipairs(FORBIDDEN_TILE_IDS) do
            if ground_tile == forbidden_tile_id then
                return true
            end
        end
    end
    return false
end
--并不想让房子能在船上放置
local function IsOnBoat(pt)
    local x, y, z = pt.x, pt.y, pt.z
    local boats = TheSim:FindEntities(x, y, z, 4, {"walkableplatform"})
    for _, ent in ipairs(boats) do
        if ent:HasTag("boat") then
            return true
        end
    end
    return false
end

local function NotInInterior(pt)
    if IsForbiddenTile(pt) then
        return false
    end
    -- 检查是否在船上
    if IsOnBoat(pt) then
        return false
    end
    -- 检查是否在室内
    return not TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z)
end

local function NotInInterior_canbuild(inst, builder, pt)
    return NotInInterior(pt)
end

-- 只能在室内放置的家具配方列表，因为一些可放置的灯是显然不适合在室外放置的
local INTERIOR_ONLY_RECIPES = {
    -- 这里填写所有室内家具的配方名
    "deco_chair_classic",
    "deco_chair_corner",
    "deco_chair_bench",
    "deco_chair_horned",
    "deco_chair_footrest",
    "deco_chair_lounge",
    "deco_chair_massager",
    "deco_chair_stuffed",
    "deco_chair_rocking",
    "deco_chair_ottoman",
    "deco_chaise",
    "shelf_wood",
    "shelf_basic",
    "shelf_cinderblocks",
    "shelf_marble",
    "shelf_glass",
    "shelf_ladder",
    "shelf_hutch",
    "shelf_industrial",
    "shelf_adjustable",
    "shelf_midcentury",
    "shelf_wallmount",
    "shelf_aframe",
    "shelf_crates",
    "shelf_fridge",
    "shelf_floating",
    "shelf_pipe",
    "shelf_hattree",
    "shelf_pallet",
    "rug_round",
    "rug_square",
    "rug_oval",
    "rug_rectangle",
    "rug_fur",
    "rug_hedgehog",
    "rug_porcupuss",
    "rug_hoofprint",
    "rug_octagon",
    "rug_swirl",
    "rug_catcoon",
    "rug_rubbermat",
    "rug_web",
    "rug_metal",
    "rug_wormhole",
    "rug_braid",
    "rug_beard",
    "rug_nailbed",
    "rug_crime",
    "rug_tiles",
    "deco_lamp_fringe",
    "deco_lamp_stainglass",
    "deco_lamp_downbridge",
    "deco_lamp_2embroidered",
    "deco_lamp_ceramic",
    "deco_lamp_glass",
    "deco_lamp_2fringes",
    "deco_lamp_candelabra",
    "deco_lamp_elizabethan",
    "deco_lamp_gothic",
    "deco_lamp_orb",
    "deco_lamp_bellshade",
    "deco_lamp_crystals",
    "deco_lamp_upturn",
    "deco_lamp_2upturns",
    "deco_lamp_spool",
    "deco_lamp_edison",
    "deco_lamp_adjustable",
    "deco_lamp_rightangles",
    "deco_lamp_hoofspa",
    "deco_plantholder_basic",
    -- 如有遗漏可继续补充
}

-- 只能在室内放置的检测函数
local function OnlyInInterior(pt)
    return TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z)
end

for _, recipe_name in ipairs(INTERIOR_ONLY_RECIPES) do
    AddRecipePostInit(recipe_name, function(recipe)
        recipe.testfn = OnlyInInterior
    end)
end

--- HOME ---
CONSTRUCTION_PLANS["playerhouse_scaffold"] = { Ingredient("cutstone", 10), Ingredient("boards", 20)}
CONSTRUCTION_PLANS["playerhouse_reconstruction"] = { Ingredient("cutstone", 5), Ingredient("boards", 10)}

AddRecipe2("playerhouse_scaffold",{Ingredient("cutstone", 5), Ingredient("boards", 5)},TECH.SCIENCE_ONE,{placer="playerhouse_city_placer",image = "playerhouse_city.tex", testfn = NotInInterior},{"STRUCTURES"})

AddRecipe2("player_house_cottage_craft", {Ingredient("cutstone", 10),Ingredient("marble", 5)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_tudor_craft",   {Ingredient("boards", 10),Ingredient("cutstone", 3)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_gothic_craft",  {Ingredient("marble", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_brick_craft",   {Ingredient("cutstone", 10),Ingredient("boards", 4)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_turret_craft",  {Ingredient("cutstone", 7),Ingredient("moonrocknugget", 7)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_villa_craft",   {Ingredient("cutstone", 15),Ingredient("goldnugget", 15),Ingredient("palmcone_scale", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})
AddRecipe2("player_house_manor_craft",   {Ingredient("cutstone", 10),Ingredient("marble", 10),Ingredient("boards", 10)}, TECH.HOME, {nounlock = true}, {"HOME_MISC"})

AddRecipe2("deco_chair_classic",  {Ingredient("cutstone", 2),Ingredient("beefalowool", 2)},  TECH.HOME, {nounlock = true, placer = "chair_classic_placer", min_spacing=2,  image = "reno_chair_classic.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_corner",   {Ingredient("boards", 2),Ingredient("beefalowool", 2)},  TECH.HOME, {nounlock = true, placer = "chair_corner_placer", min_spacing=2,   image = "reno_chair_corner.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_bench",    {Ingredient("boards", 3),Ingredient("silk", 3)},  TECH.HOME, {nounlock = true, placer = "chair_bench_placer", min_spacing=2,    image = "reno_chair_bench.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_chair_horned",   {Ingredient("boards", 2),Ingredient("silk", 2)},  TECH.HOME, {nounlock = true, placer = "chair_horned_placer", min_spacing=2,   image = "reno_chair_horned.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_footrest", {Ingredient("boards", 2)},  TECH.HOME, {nounlock = true, placer = "chair_footrest_placer", min_spacing=2, image = "reno_chair_footrest.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_chair_lounge",   {Ingredient("boards", 2),Ingredient("beefalowool", 2)},  TECH.HOME, {nounlock = true, placer = "chair_lounge_placer", min_spacing=2,   image = "reno_chair_lounge.tex"},   {"HOME_FURNITURE"})
AddRecipe2("deco_chair_massager", {Ingredient("boards", 1),	Ingredient("trinket_6", 1)},  TECH.HOME, {nounlock = true, placer = "chair_massager_placer", min_spacing=2, image = "reno_chair_massager.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_chair_stuffed",  {Ingredient("silk", 2),Ingredient("beefalowool", 2)},  TECH.HOME, {nounlock = true, placer = "chair_stuffed_placer", min_spacing=2,  image = "reno_chair_stuffed.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_rocking",  {Ingredient("boards", 2),Ingredient("twigs", 2)},  TECH.HOME, {nounlock = true, placer = "chair_rocking_placer", min_spacing=2,  image = "reno_chair_rocking.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chair_ottoman",  {Ingredient("twigs", 4),Ingredient("silk", 2)},  TECH.HOME, {nounlock = true, placer = "chair_ottoman_placer", min_spacing=2,  image = "reno_chair_ottoman.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_chaise",         {Ingredient("marble", 1),Ingredient("beefalowool", 4),Ingredient("feather_robin", 1)}, TECH.HOME, {nounlock = true, placer = "deco_chaise_placer", min_spacing=3,    image = "reno_chair_chaise.tex"},   {"HOME_FURNITURE"})

AddRecipe2("shelf_wood",         {Ingredient("boards", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_wood_placer",         image = "reno_shelves_wood.tex"},         {"HOME_FURNITURE"})
AddRecipe2("shelf_basic",        {Ingredient("boards", 2),Ingredient("twigs", 4)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_basic_placer",        image = "reno_shelves_basic.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_cinderblocks", {Ingredient("boards", 1),Ingredient("cutstone", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_cinderblocks_placer", image = "reno_shelves_cinderblocks.tex"}, {"HOME_FURNITURE"})
AddRecipe2("shelf_marble",       {Ingredient("marble", 2),Ingredient("rope", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_marble_placer",       image = "reno_shelves_marble.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_glass",        {Ingredient("moonglass", 1),Ingredient("twigs", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_glass_placer",        image = "reno_shelves_glass.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_ladder",       {Ingredient("boards", 2),Ingredient("log", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_ladder_placer",       image = "reno_shelves_ladder.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_hutch",        {Ingredient("driftwood_log", 3),Ingredient("cutgrass", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_hutch_placer",        image = "reno_shelves_hutch.tex"},        {"HOME_FURNITURE"})
AddRecipe2("shelf_industrial",   {Ingredient("cutstone", 3),Ingredient("twigs", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_industrial_placer",   image = "reno_shelves_industrial.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_adjustable",   {Ingredient("cutstone", 3),Ingredient("twigs", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_adjustable_placer",   image = "reno_shelves_adjustable.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_midcentury",   {Ingredient("driftwood_log", 3),Ingredient("moonglass", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_midcentury_placer",   image = "reno_shelves_midcentury.tex"},   {"HOME_FURNITURE"})
AddRecipe2("shelf_wallmount",    {Ingredient("boards", 1),Ingredient("log", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_wallmount_placer",    image = "reno_shelves_wallmount.tex"},    {"HOME_FURNITURE"})
AddRecipe2("shelf_aframe",       {Ingredient("driftwood_log", 3),Ingredient("rope", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_aframe_placer",       image = "reno_shelves_aframe.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_crates",       {Ingredient("boards", 3)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_crates_placer",       image = "reno_shelves_crates.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_fridge",       {Ingredient("cutstone", 2),Ingredient("moonglass", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_fridge_placer",       image = "reno_shelves_fridge.tex"},       {"HOME_FURNITURE"})
AddRecipe2("shelf_floating",     {Ingredient("log", 6),Ingredient("rope", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_floating_placer",     image = "reno_shelves_floating.tex"},     {"HOME_FURNITURE"})
AddRecipe2("shelf_pipe",         {Ingredient("rocks", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_pipe_placer",         image = "reno_shelves_pipe.tex"},         {"HOME_FURNITURE"})
AddRecipe2("shelf_hattree",      {Ingredient("driftwood_log", 2),Ingredient("twigs", 6)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_hattree_placer",      image = "reno_shelves_hattree.tex"},      {"HOME_FURNITURE"})
AddRecipe2("shelf_pallet",       {Ingredient("boards", 2),Ingredient("twigs", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "shelf_pallet_placer",       image = "reno_shelves_pallet.tex"},       {"HOME_FURNITURE"})

AddRecipe2("rug_round",     {Ingredient("beefalowool", 2),Ingredient("silk", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_round_placer",     image = "reno_rug_round.tex"},      {"HOME_RUG"})
AddRecipe2("rug_square",    {Ingredient("beefalowool", 1),Ingredient("silk", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_square_placer",    image = "reno_rug_square.tex"},     {"HOME_RUG"})
AddRecipe2("rug_oval",      {Ingredient("petals", 2),Ingredient("beefalowool", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_oval_placer",      image = "reno_rug_oval.tex"},       {"HOME_RUG"})
AddRecipe2("rug_rectangle", {Ingredient("petals", 3),Ingredient("beefalowool", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_rectangle_placer", image = "reno_rug_rectangle.tex"},  {"HOME_RUG"})
AddRecipe2("rug_fur",       {Ingredient("beefalowool", 4)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_fur_placer",       image = "reno_rug_fur.tex"},        {"HOME_RUG"})
AddRecipe2("rug_hedgehog",  {Ingredient("beefalowool", 2),Ingredient("stinger", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_hedgehog_placer",  image = "reno_rug_hedgehog.tex"},   {"HOME_RUG"})
AddRecipe2("rug_porcupuss", {Ingredient("beefalowool", 2),Ingredient("pinecone", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_porcupuss_placer", image = "reno_rug_porcupuss.tex"},  {"HOME_RUG"})
AddRecipe2("rug_hoofprint", {Ingredient("beefalowool", 2),Ingredient("log", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_hoofprint_placer", image = "reno_rug_hoofprint.tex"},  {"HOME_RUG"})
AddRecipe2("rug_octagon",   {Ingredient("beefalowool",2),Ingredient("goldnugget", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_octagon_placer",   image = "reno_rug_octagon.tex"},    {"HOME_RUG"})
AddRecipe2("rug_swirl",     {Ingredient("silk", 2),Ingredient("beardhair", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_swirl_placer",     image = "reno_rug_swirl.tex"},      {"HOME_RUG"})
AddRecipe2("rug_catcoon",   {Ingredient("beefalowool", 3),Ingredient("coontail", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_catcoon_placer",   image = "reno_rug_catcoon.tex"},    {"HOME_RUG"})
AddRecipe2("rug_rubbermat", {Ingredient("glommerfuel", 1),Ingredient("ash", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_rubbermat_placer", image = "reno_rug_rubbermat.tex"},  {"HOME_RUG"})
AddRecipe2("rug_web",       {Ingredient("silk", 4)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_web_placer",       image = "reno_rug_web.tex"},        {"HOME_RUG"})
AddRecipe2("rug_metal",     {Ingredient("flint", 2),Ingredient("rocks", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_metal_placer",     image = "reno_rug_metal.tex"},      {"HOME_RUG"})
AddRecipe2("rug_wormhole",  {Ingredient("spoiled_food", 2),Ingredient("cutgrass", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_wormhole_placer",  image = "reno_rug_wormhole.tex"},   {"HOME_RUG"})
AddRecipe2("rug_braid",     {Ingredient("rope", 4)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_braid_placer",     image = "reno_rug_braid.tex"},      {"HOME_RUG"})
AddRecipe2("rug_beard",     {Ingredient("beardhair", 4)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_beard_placer",     image = "reno_rug_beard.tex"},      {"HOME_RUG"})
AddRecipe2("rug_nailbed",   {Ingredient("boards", 1),Ingredient("houndstooth", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_nailbed_placer",   image = "reno_rug_nailbed.tex"},    {"HOME_RUG"})
AddRecipe2("rug_crime",     {Ingredient("beefalowool", 1),Ingredient("goldnugget", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_crime_placer",     image = "reno_rug_crime.tex"},      {"HOME_RUG"})
AddRecipe2("rug_tiles",     {Ingredient("silk", 3),Ingredient("charcoal", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "rug_tiles_placer",     image = "reno_rug_tiles.tex"},      {"HOME_RUG"})

AddRecipe2("deco_lamp_fringe",       {Ingredient("lightbulb", 2),Ingredient("driftwood_log", 1),Ingredient("beefalowool", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_fringe_placer", min_spacing=2,       image = "reno_lamp_fringe.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_stainglass",   {Ingredient("lightbulb", 2),Ingredient("moonglass", 1),Ingredient("log", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_stainglass_placer", min_spacing=2,   image = "reno_lamp_stainglass.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_downbridge",   {Ingredient("lightbulb", 2),Ingredient("twigs", 1),Ingredient("flint", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_downbridge_placer", min_spacing=2,   image = "reno_lamp_downbridge.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_2embroidered", {Ingredient("lightbulb", 2),Ingredient("petals", 1),Ingredient("twigs", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2embroidered_placer", min_spacing=2, image = "reno_lamp_2embroidered.tex"}, {"HOME_LAMP"})
AddRecipe2("deco_lamp_ceramic",      {Ingredient("lightbulb", 2),Ingredient("rocks", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_ceramic_placer", min_spacing=2,      image = "reno_lamp_ceramic.tex"},      {"HOME_LAMP"})
AddRecipe2("deco_lamp_glass",        {Ingredient("lightbulb", 2),Ingredient("moonglass", 1),Ingredient("twigs", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_glass_placer", min_spacing=2,        image = "reno_lamp_glass.tex"},        {"HOME_LAMP"})
AddRecipe2("deco_lamp_2fringes",     {Ingredient("lightbulb", 2),Ingredient("twigs", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2fringes_placer", min_spacing=2,     image = "reno_lamp_2fringes.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_candelabra",   {Ingredient("lightbulb", 3),Ingredient("charcoal", 3),Ingredient("log", 3)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_candelabra_placer", min_spacing=2,   image = "reno_lamp_candelabra.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_elizabethan",  {Ingredient("lightbulb", 6),Ingredient("goldnugget", 2),Ingredient("twigs", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_elizabethan_placer", min_spacing=2,  image = "reno_lamp_elizabethan.tex"},  {"HOME_LAMP"})
AddRecipe2("deco_lamp_gothic",       {Ingredient("lightbulb", 6),Ingredient("goldnugget", 2),Ingredient("charcoal", 4)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_gothic_placer", min_spacing=2,       image = "reno_lamp_gothic.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_orb",          {Ingredient("lightbulb", 6),Ingredient("charcoal", 8)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_orb_placer", min_spacing=2,          image = "reno_lamp_orb.tex"},          {"HOME_LAMP"})
AddRecipe2("deco_lamp_bellshade",    {Ingredient("lightbulb", 2),Ingredient("log", 4),}, TECH.HOME, {nounlock = true, placer = "deco_lamp_bellshade_placer", min_spacing=2,    image = "reno_lamp_bellshade.tex"},    {"HOME_LAMP"})--钟罩灯
AddRecipe2("deco_lamp_crystals",     {Ingredient("lightbulb", 2),Ingredient("twigs", 4),}, TECH.HOME, {nounlock = true, placer = "deco_lamp_crystals_placer", min_spacing=2,     image = "reno_lamp_crystals.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_upturn",       {Ingredient("lightbulb", 2),Ingredient("cutstone", 1),Ingredient("twigs", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_upturn_placer", min_spacing=2,       image = "reno_lamp_upturn.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_2upturns",     {Ingredient("lightbulb", 2),Ingredient("cutstone", 1),Ingredient("goldnugget", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_2upturns_placer", min_spacing=2,     image = "reno_lamp_2upturns.tex"},     {"HOME_LAMP"})
AddRecipe2("deco_lamp_spool",        {Ingredient("lightbulb", 2),Ingredient("silk", 2),Ingredient("goldnugget", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_spool_placer", min_spacing=2,        image = "reno_lamp_spool.tex"},        {"HOME_LAMP"})
AddRecipe2("deco_lamp_edison",       {Ingredient("lightbulb", 2),Ingredient("transistor", 1),Ingredient("goldnugget", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_edison_placer", min_spacing=2,       image = "reno_lamp_edison.tex"},       {"HOME_LAMP"})
AddRecipe2("deco_lamp_adjustable",   {Ingredient("lightbulb", 2),Ingredient("goldnugget", 2),Ingredient("cutstone", 1)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_adjustable_placer", min_spacing=2,   image = "reno_lamp_adjustable.tex"},   {"HOME_LAMP"})
AddRecipe2("deco_lamp_rightangles",  {Ingredient("lightbulb", 2),Ingredient("goldnugget", 4),}, TECH.HOME, {nounlock = true, placer = "deco_lamp_rightangles_placer", min_spacing=2,  image = "reno_lamp_rightangles.tex"},  {"HOME_LAMP"})
AddRecipe2("deco_lamp_hoofspa",      {Ingredient("lightbulb", 2),Ingredient("goldnugget", 2),Ingredient("beefalowool", 2)}, TECH.HOME, {nounlock = true, placer = "deco_lamp_hoofspa_placer", min_spacing=2,      image = "reno_lamp_hoofspa.tex"},      {"HOME_LAMP"})

-- AddRecipe2("deco_plantholder_fancy",        {Ingredient("goldnugget", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fancy_placer", min_spacing=2, image = "reno_plantholder_fancy.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_basic",        {Ingredient("cutgrass", 1),Ingredient("rocks", 2),Ingredient("twigs", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_basic_placer", min_spacing=2,        image = "reno_plantholder_basic.tex"},        {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_wip",          {Ingredient("cutgrass", 3),Ingredient("rocks", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_wip_placer", min_spacing=2,          image = "reno_plantholder_wip.tex"},          {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_marble",       {Ingredient("marble", 2),Ingredient("feather_crow", 1),Ingredient("petals", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_marble_placer", min_spacing=2,       image = "reno_plantholder_marble.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_bonsai",       {Ingredient("cutstone", 1),Ingredient("twigs", 2),Ingredient("petals", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_bonsai_placer", min_spacing=2,       image = "reno_plantholder_bonsai.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_dishgarden",   {Ingredient("cutstone", 1),Ingredient("cutgrass", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_dishgarden_placer", min_spacing=2,   image = "reno_plantholder_dishgarden.tex"},   {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_philodendron", {Ingredient("cutstone", 1),Ingredient("cutgrass", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_philodendron_placer", min_spacing=2, image = "reno_plantholder_philodendron.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_orchid",       {Ingredient("cutstone", 1),Ingredient("twigs", 2),Ingredient("petals", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_orchid_placer", min_spacing=2,       image = "reno_plantholder_orchid.tex"},       {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_draceana",     {Ingredient("cutstone", 1),Ingredient("twigs", 2),Ingredient("cutgrass", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_draceana_placer", min_spacing=2,     image = "reno_plantholder_draceana.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_xerographica", {Ingredient("rope", 2),Ingredient("petals", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_xerographica_placer", min_spacing=2, image = "reno_plantholder_xerographica.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_birdcage",     {Ingredient("goldnugget", 4),Ingredient("cutstone", 1),Ingredient("petals", 4)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_birdcage_placer", min_spacing=2,     image = "reno_plantholder_birdcage.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_palm",         {Ingredient("rope", 3),Ingredient("palmcone_seed", 1)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_palm_placer", min_spacing=2,         image = "reno_plantholder_palm.tex"},         {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_zz",           {Ingredient("twigs", 4),Ingredient("boards", 1),Ingredient("pinecone", 1)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_zz_placer", min_spacing=2,           image = "reno_plantholder_zz.tex"},           {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_fernstand",    {Ingredient("goldnugget", 4),Ingredient("foliage", 3)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fernstand_placer", min_spacing=2,    image = "reno_plantholder_fernstand.tex"},    {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_fern",         {Ingredient("goldnugget", 2),Ingredient("foliage", 2),Ingredient("rope", 2)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_fern_placer", min_spacing=2,         image = "reno_plantholder_fern.tex"},         {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_terrarium",    {Ingredient("moonglass", 1),Ingredient("cutstone", 2),Ingredient("petals", 5)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_terrarium_placer", min_spacing=2,    image = "reno_plantholder_terrarium.tex"},    {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_plantpet",     {Ingredient("cutstone", 1),Ingredient("poop", 2),Ingredient("seeds", 1)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_plantpet_placer", min_spacing=2,     image = "reno_plantholder_plantpet.tex"},     {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_traps",        {Ingredient("cutstone", 1),Ingredient("poop", 2),Ingredient("lureplantbulb", 1)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_traps_placer", min_spacing=2,        image = "reno_plantholder_traps.tex"},        {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_pitchers",     {Ingredient("boards", 1),Ingredient("twigs", 2),Ingredient("cutgrass", 6)}, TECH.HOME, {nounlock = true, placer = "deco_plantholder_pitchers_placer", min_spacing=2,     image = "reno_plantholder_pitchers.tex"},     {"HOME_PLANTHOLDER"})

AddRecipe2("deco_plantholder_winterfeasttreeofsadness", {Ingredient("goldnugget", 2), Ingredient("twigs", 1)}, TECH.HOME, {onunlock = true, placer = "deco_plantholder_winterfeasttreeofsadness_placer", min_spacing=2, image = "reno_plantholder_winterfeasttreeofsadness.tex"}, {"HOME_PLANTHOLDER"})
AddRecipe2("deco_plantholder_winterfeasttree",          {Ingredient("lightbulb", 9),Ingredient("goldnugget", 5),Ingredient("pinecone", 5)},                        TECH.HOME, {onunlock = true, placer = "deco_plantholder_winterfeasttree_placer", min_spacing=2,          image = "reno_lamp_festivetree.tex"},                     {"HOME_PLANTHOLDER"})

AddRecipe2("deco_table_round",  {Ingredient("log", 6)}, TECH.HOME, {nounlock= true, placer = "deco_table_round_placer", min_spacing=2,  image = "reno_table_round.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_table_banker", {Ingredient("boards", 2),Ingredient("rope", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_banker_placer", min_spacing=2, image = "reno_table_banker.tex"}, {"HOME_FURNITURE"})
AddRecipe2("deco_table_diy",    {Ingredient("boards", 1),Ingredient("twigs", 4)}, TECH.HOME, {nounlock= true, placer = "deco_table_diy_placer", min_spacing=2,    image = "reno_table_diy.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_table_raw",    {Ingredient("cutstone", 1),Ingredient("boards", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_raw_placer", min_spacing=2,    image = "reno_table_raw.tex"},    {"HOME_FURNITURE"})
AddRecipe2("deco_table_crate",  {Ingredient("boards", 2)}, TECH.HOME, {nounlock= true, placer = "deco_table_crate_placer", min_spacing=2,  image = "reno_table_crate.tex"},  {"HOME_FURNITURE"})
AddRecipe2("deco_table_chess",  {Ingredient("boards", 1),Ingredient("marble", 1)}, TECH.HOME, {nounlock= true, placer = "deco_table_chess_placer", min_spacing=2,  image = "reno_table_chess.tex"},  {"HOME_FURNITURE"})

-- AddRecipe2("deco_wallornament_fulllength_mirror", {Ingredient("goldnugget", 10)},                         TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_fulllength_mirror_placer",   image = "reno_wallornament_fulllength_mirror"}, {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_photo",             {Ingredient("boards", 1),Ingredient("papyrus", 1)},            TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_photo_placer",               image = "reno_wallornament_photo.tex"},             {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_embroidery_hoop",   {Ingredient("silk",2),Ingredient("beefalowool",2)},            TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_embroidery_hoop_placer",     image = "reno_wallornament_embroidery_hoop.tex"},   {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_mosaic",            {Ingredient("beefalowool", 2),Ingredient("rocks",2)},    TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_mosaic_placer",              image = "reno_wallornament_mosaic.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_wreath",            {Ingredient("rope", 1),Ingredient("petals", 4)},               TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_wreath_placer",              image = "reno_wallornament_wreath.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_axe",               {Ingredient("boards", 1),  Ingredient("axe", 1)},              TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_axe_placer",                 image = "reno_wallornament_axe.tex"},               {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_hunt",              {Ingredient("boards", 2),  Ingredient("spear", 2)},            TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_hunt_placer",                image = "reno_wallornament_hunt.tex"},              {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_periodic_table",    {Ingredient("papyrus", 1),Ingredient("charcoal", 1)},          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_periodic_table_placer",      image = "reno_wallornament_periodic_table.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_gears_art",         {Ingredient("gears", 1)},                                      TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_gears_art_placer",           image = "reno_wallornament_gears_art.tex"},         {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_cape",              {Ingredient("silk", 2),Ingredient("goldnugget", 1)},           TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_cape_placer",                image = "reno_wallornament_cape.tex"},              {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_no_smoking",        {Ingredient("papyrus", 1),Ingredient("ash", 1)},               TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_no_smoking_placer",          image = "reno_wallornament_no_smoking.tex"},        {"HOME_WALL_DECORATION"})
AddRecipe2("deco_wallornament_black_cat",         {Ingredient("papyrus", 1),Ingredient("charcoal", 1)},          TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wallornament_black_cat_placer",           image = "reno_wallornament_black_cat.tex"},         {"HOME_WALL_DECORATION"})
AddRecipe2("deco_antiquities_wallfish",           {Ingredient("boards", 1),  Ingredient("charcoal", 1)},         TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_antiquities_wallfish_placer",             image = "reno_antiquities_wallfish.tex"},           {"HOME_WALL_DECORATION"})
AddRecipe2("deco_antiquities_beefalo",            {Ingredient("boards", 3), Ingredient("horn", 2)},              TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_antiquities_beefalo_placer",              image = "reno_antiquities_beefalo.tex"},            {"HOME_WALL_DECORATION"})

--AddRecipe2("window_round_curtains_nails",         {Ingredient("boards", 2)},                                     RENO_RECIPETABS.HOME, TECH.HOME, RECIPE_GAME_TYPE.PORKLAND, "window_round_curtains_nails_placer", nil, true, nil, nil, nil, true)
AddRecipe2("window_small_peaked_curtain", {Ingredient("boards", 2),Ingredient("silk", 3)},                                        TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_small_peaked_curtain_placer",  image = "reno_window_small_peaked_curtain.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("window_round_burlap",         {Ingredient("boards", 2),Ingredient("beefalowool", 3)},                                 TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_round_burlap_placer",          image = "reno_window_round_burlap.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_small_peaked",         {Ingredient("boards", 3)},                                                              TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_small_peaked_placer",          image = "reno_window_small_peaked.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_large_square",         {Ingredient("cutstone", 1),Ingredient("twigs", 2),Ingredient("moonglass", 1)},                                     TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_large_square_placer",          image = "reno_window_large_square.tex"},            {"HOME_WALL_DECORATION"})
AddRecipe2("window_tall",                 {Ingredient("boards", 2),Ingredient("twigs", 2),Ingredient("moonglass", 1)},       TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_tall_placer",                  image = "reno_window_tall.tex"},                    {"HOME_WALL_DECORATION"})
AddRecipe2("window_large_square_curtain", {Ingredient("silk", 3),Ingredient("twigs", 2),Ingredient("moonglass", 1)},         TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_large_square_curtain_placer",  image = "reno_window_large_square_curtain.tex"},    {"HOME_WALL_DECORATION"})
AddRecipe2("window_tall_curtain",         {Ingredient("beefalowool", 3),Ingredient("twigs", 2),Ingredient("moonglass", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_tall_curtain_placer",          image = "reno_window_tall_curtain.tex"},            {"HOME_WALL_DECORATION"})

AddRecipe2("window_greenhouse",           {Ingredient("boards",4),Ingredient("cutgrass", 2),Ingredient("moonglass", 2)},     TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "window_greenhouse_placer",            image = "reno_window_greenhouse.tex"},              {"HOME_WALL_DECORATION"})

--cassielu: why change them?
AddRecipe2("deco_wood_beam",      {Ingredient("log", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_wood_cornerbeam_placer",      image = "reno_cornerbeam_wood.tex",      nameoverride = "deco_wood",      description = "deco_wood"},      {"HOME_COLUMN"})
AddRecipe2("deco_millinery_beam", {Ingredient("boards", 1),Ingredient("silk", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_millinery_cornerbeam_placer", image = "reno_cornerbeam_millinery.tex", nameoverride = "deco_millinery", description = "deco_millinery"}, {"HOME_COLUMN"})
AddRecipe2("deco_round_beam",     {Ingredient("cutstone", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_round_cornerbeam_placer",     image = "reno_cornerbeam_round.tex",     nameoverride = "deco_round",     description = "deco_round"},     {"HOME_COLUMN"})
AddRecipe2("deco_marble_beam",    {Ingredient("marble", 2),Ingredient("lightbulb", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "deco_marble_cornerbeam_placer",    image = "reno_cornerbeam_marble.tex",    nameoverride = "deco_marble",    description = "deco_marble"},    {"HOME_COLUMN"})

AddRecipe2("interior_floor_wood",        {Ingredient("log", 12)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_marble",      {Ingredient("marble", 5)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_check",       {Ingredient("marble", 5),Ingredient("charcoal", 5)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_plaid_tile",  {Ingredient("cutstone", 7)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_sheet_metal", {Ingredient("transistor", 3)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})

AddRecipe2("interior_floor_gardenstone",    {Ingredient("rocks", 10),Ingredient("cutgrass", 10)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_geometrictiles", {Ingredient("marble", 5),Ingredient("moonrocknugget", 3)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_shag_carpet",    {Ingredient("beefalowool", 10)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_transitional",   {Ingredient("log", 8),Ingredient("rocks", 8)},  TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_woodpanels",     {Ingredient("boards", 5)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_herringbone",    {Ingredient("cutstone", 5)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_hexagon",        {Ingredient("cutstone", 4),Ingredient("charcoal", 4)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_hoof_curvy",     {Ingredient("marble", 4),Ingredient("pigskin", 1)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})
AddRecipe2("interior_floor_octagon",        {Ingredient("marble", 5),Ingredient("charcoal", 3)}, TECH.HOME, {nounlock = true}, {"HOME_FLOOR"})

AddRecipe2("interior_wall_wood",      {Ingredient("boards", 3)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_checkered", {Ingredient("papyrus", 2),Ingredient("boards", 2)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_floral",    {Ingredient("papyrus", 2),Ingredient("petals", 8)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_sunflower", {Ingredient("papyrus", 1),Ingredient("boards", 2),Ingredient("petals", 4)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_harlequin", {Ingredient("papyrus", 3),Ingredient("boards", 1)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})

AddRecipe2("interior_wall_peagawk",           {Ingredient("papyrus", 2),Ingredient("feather_crow", 1)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_plain_ds",          {Ingredient("papyrus", 2),Ingredient("feather_robin", 1)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_plain_rog",         {Ingredient("papyrus", 2),Ingredient("charcoal", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_rope",              {Ingredient("papyrus", 2),Ingredient("rope", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_circles",           {Ingredient("marble", 2),Ingredient("cutstone", 1)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_marble",            {Ingredient("marble", 3)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_mayorsoffice",      {Ingredient("boards", 2),Ingredient("papyrus", 1),Ingredient("petals", 3)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_fullwall_moulding", {Ingredient("cutstone", 5)}, TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})
AddRecipe2("interior_wall_upholstered",       {Ingredient("beefalowool", 6),Ingredient("silk", 6)},  TECH.HOME, {nounlock = true}, {"HOME_WALLPAPER"})

AddRecipe2("swinging_light_basic_bulb",         {Ingredient("lightbulb", 2),Ingredient("transistor", 1)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_basic_bulb_placer",         image = "reno_light_basic_bulb.tex"},         {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_basic_metal",        {Ingredient("lightbulb", 2),Ingredient("goldnugget", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_basic_metal_placer",        image = "reno_light_basic_metal.tex"},        {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_chandalier_candles", {Ingredient("lightbulb", 8),Ingredient("goldnugget", 6),Ingredient("transistor", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_chandalier_candles_placer", image = "reno_light_chandalier_candles.tex"}, {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_rope_1",             {Ingredient("lightbulb", 2),Ingredient("rope", 2)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_rope_1_placer",             image = "reno_light_rope_1.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_rope_2",             {Ingredient("lightbulb", 2),Ingredient("rope", 3)},  TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_rope_2_placer",             image = "reno_light_rope_2.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_bulb",        {Ingredient("lightbulb", 2),Ingredient("moonglass", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_bulb_placer",        image = "reno_light_floral_bulb.tex"},        {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_pendant_cherries",   {Ingredient("lightbulb", 2),Ingredient("cutstone", 2)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_pendant_cherries_placer",   image = "reno_light_pendant_cherries.tex"},   {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_scallop",     {Ingredient("lightbulb", 2),Ingredient("petals", 4),Ingredient("goldnugget", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_scallop_placer",     image = "reno_light_floral_scallop.tex"},     {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_floral_bloomer",     {Ingredient("lightbulb", 2),Ingredient("petals", 4),Ingredient("rope", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_floral_bloomer_placer",     image = "reno_light_floral_bloomer.tex"},     {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_tophat",             {Ingredient("lightbulb", 2),Ingredient("tophat", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_tophat_placer",             image = "reno_light_tophat.tex"},             {"HOME_HANGINGLAMP"})
AddRecipe2("swinging_light_derby",              {Ingredient("lightbulb", 2),Ingredient("tophat", 1)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, placer = "swinging_light_derby_placer",              image = "reno_light_derby.tex"},              {"HOME_HANGINGLAMP"})

-- DOORS
local function GetDoorDirection(pt)
    local center = TheWorld.components.interiorspawner:GetInteriorCenter(pt)
    local origin = center:GetPosition()
    local delta = pt - origin
    if math.abs(delta.x) > math.abs(delta.z) then
        -- north or south
        if delta.x > 0 then
            return "south"
        else
            return "north"
        end
    else
        -- east or west
        if delta.z < 0 then
            return "west"
        else
            return "east"
        end
    end
end

-- Check if the door is facing the initial room's exit
local function CanBuildHouseDoor(recipe, builder, pt)
    local interior_spawner = TheWorld.components.interiorspawner
    if not interior_spawner:IsInInteriorRegion(pt.x, pt.z) then
        return false
    end
    -- Just test if it's pointing north and that room is the origin room for now
    if GetDoorDirection(pt) == "north" then
        local current_room = interior_spawner:GetInteriorCenter(pt)
        local target_room = interior_spawner:GetRoomInDirection(current_room, interior_spawner:GetNorth())
        if target_room then
            local x, y = target_room:GetCoordinates()
            return not (x == 0 and y == 0)
        end
    end
    return true
end

AddRecipe2("wood_door",     {Ingredient("boards", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "wood_door_placer",    image = "wood_door.tex"},    {"HOME_DOOR"})
AddRecipe2("stone_door",    {Ingredient("cutstone", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "stone_door_placer",   image = "stone_door.tex"},   {"HOME_DOOR"})
AddRecipe2("organic_door",  {Ingredient("log", 15), Ingredient("pinecone", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "organic_door_placer", image = "organic_door.tex"}, {"HOME_DOOR"})
AddRecipe2("iron_door",     {Ingredient("flint", 7)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "iron_door_placer",    image = "iron_door.tex"},    {"HOME_DOOR"})
AddRecipe2("curtain_door",  {Ingredient("boards", 4),Ingredient("beefalowool", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "curtain_door_placer", image = "curtain_door.tex"}, {"HOME_DOOR"})
AddRecipe2("plate_door",    {Ingredient("goldnugget", 10)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "plate_door_placer",   image = "plate_door.tex"},   {"HOME_DOOR"})
AddRecipe2("round_door",    {Ingredient("boards", 4),Ingredient("silk", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "round_door_placer",   image = "round_door.tex"},   {"HOME_DOOR"})
AddRecipe2("pillar_door",   {Ingredient("marble", 5)}, TECH.HOME, {nounlock = true, build_mode = BUILDMODE.HOME_DECOR, canbuild = CanBuildHouseDoor, placer = "pillar_door_placer",  image = "pillar_door.tex"},  {"HOME_DOOR"})

AddRecipe2("construction_permit", {Ingredient("boards", 8),Ingredient("cutstone", 10),Ingredient("papyrus", 2)}, TECH.HOME, {nounlock = true}, {"HOME_DOOR"})
AddRecipe2("construction_permit_kitchen", {Ingredient("construction_permit", 1), Ingredient("thulecite", 3),Ingredient("transistor", 3),Ingredient("bluegem", 2)}, TECH.HOME, {nounlock = true, image="construction_permit_kitchen.tex"}, {"HOME_DOOR"})
AddRecipe2("construction_permit_lab", {Ingredient("construction_permit", 1), Ingredient("thulecite", 5),Ingredient("purplegem", 2),Ingredient("minotaurhorn", 1)}, TECH.HOME, {nounlock = true, image="construction_permit_lab.tex"}, {"HOME_DOOR"})

AddRecipe2("demolition_permit",   {Ingredient("hammer", 2),Ingredient("papyrus", 2)}, TECH.HOME, {nounlock = true}, {"HOME_DOOR"})



-- 室内禁止放置的物品列表，一些建筑是不太适合在室内放置的
local INTERIOR_BANNED_ITEMS = {
    "pighouse",                -- 猪人房
    "rabbithouse",--兔人房
    "support_pillar_scaffold", --大柱子
    "support_pillar_dreadstone_scaffold" --绝望石大柱子
}

-- 只禁止在室内放置的简单检测函数
local function NotInInterior_Simple(pt)
    return not (TheWorld.components.interiorspawner and TheWorld.components.interiorspawner:IsInInterior(pt.x, pt.z))
end

for _, item_name in ipairs(INTERIOR_BANNED_ITEMS) do
    AddRecipePostInit(item_name, function(recipe)
        if recipe then
            recipe.testfn = NotInInterior_Simple
            recipe.canbuild = nil -- 恢复原版
            print("已为 " .. item_name .. " 添加室内禁止放置功能")
        else
            print("配方 " .. item_name .. " 不存在，跳过处理")
        end
    end)
end
