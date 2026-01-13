local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

local post_init_functions = {}

function AddPrefabRegisterPostInit(prefab, post_init)
    if Prefabs[prefab] then
        post_init(Prefabs[prefab])
        return
    end
    if not post_init_functions[prefab] then
        post_init_functions[prefab] = {}
    end
    table.insert(post_init_functions[prefab], post_init)
end

local register_prefabs_impl = RegisterPrefabsImpl
RegisterPrefabsImpl = function(prefab, ...)
    local ret = { register_prefabs_impl(prefab, ...) }
    local prefab_name = prefab.name
    if post_init_functions[prefab_name] then
        for _, post_init in ipairs(post_init_functions[prefab_name]) do
            post_init(prefab)
        end
    end
    return unpack(ret)
end


local behaviour_posts = {
}

local camera_posts = {
    "followcamera", --锁定室内的镜头跟孙
}

local component_posts = {
    "acidinfusible", -- 室内生物酸雨效果禁用
    "acidlevel", -- 室内酸雨保护
    "antlion_sinkhole", --蚁狮地震保护
    "ambientlighting",
    "ambientsound", -- 禁用室内海浪声
    "areaaware",
    "birdspawner", -- 禁用室内月亮冰雹鸟
    "brightmarespawner", --禁用室内生成虚影
    "builder_replica",
    "builder",
    "deployable", --可展示
    "dest", --拿去架子高处的物品
    "dryingrack", -- 室内晾肉架雨水免疫优化
    "frograin", -- 禁用室内青蛙雨
    "hauntable", --可作祟
    "interiortemperature", -- 室内温度控制
    "inventoryitem_replica", --同下，客户端
    "inventoryitem", --一些物品相关函数
    "inventoryitemmoisture", --室内物品湿度
    "kramped", --室内坎普斯不会生成
    "lunarhailbuildup", -- 禁用室内月亮碎片附着
    "lunarhailmanager", -- 禁用室内月亮冰雹掉落物
    "maprecorder", --室内地图的记录
    "moisture", --湿度
    "playercontroller", --住房家具交互
    "playervision", --室内视觉
    "positionalwarp",
    "roomsys_stewer", --房间系统，烹饪锅组件
    "sanity", --室内精神值恢复
    "weather", -- 禁用室内落雷
    "wildfires", -- 禁用室内野火
    "wisecracker", 
    "witherable",

}

local prefab_posts = {
    "mushtree", -- 室内蘑菇树酸雨效果禁用（虽然室内不会有蘑菇树）
    "player",
    "player_classified",
    "pond", -- 室内池塘酸雨效果禁用（虽然室内不会有池塘）
    "rocky", -- 室内石虾酸雨收缩效果禁用
    "interior_quake_blocker", -- 室内地震保护，不会落下石头
    "telebase",
    "waterballoon", -- 室内水球功能优化
    "world", --室内的鸟生成的禁用补丁，还有禁止在室内放蜘蛛卵等的函数
    "spoiledfood",
    "telestaff",
    "roomsys_cookpot",--房间系统里的锅
}

local multipleprefab_posts = {
    "health", --为所有有生命值的生物添加保持在室内的组件。（之前这里犯了一个错误，把防止生物落到室外空间的功能删除了）
}

local scenario_posts = {
}

local screens_posts = {
    "mapscreen",
    "playerhud",
}

local stategraph_posts = {
    "wilson",
    "wilson_client",
    "wilsonghost",
    "wilsonghost_client",
}

local brain_posts = {
}

local widget_posts = {
    "containerwidget",
    "craftingmenu_widget", --家具制作栏在室内才会出现
    "grid", 
    "mapwidget",--室内小地图相关
    "targetindicator", 
    "widget", 
}

local module_posts = {
    ["components/map"] = "map", --一些地块相关配置，最头疼的一集
}

--local _require = require
-----@param module_name string
--function require(module_name, ...)
--    local no_loaded = package.loaded[module_name] == nil
--    local ret = { _require(module_name, ...) }
--    if module_posts[module_name] and no_loaded then -- only load when first
--        modimport("postinit/modules/" .. module_posts[module_name])
--    end
--    return unpack(ret)
--end
--改为手动加载
modimport("postinit/modules/map")

modimport("postinit/minimapentity") --与室内小地图有关，可能待简化
modimport("postinit/entityscript") --很重要，其中有室内系统检测函数
modimport("postinit/stategraphs/commonstates")
modimport("postinit/input") --待简化
modimport("postinit/vector3")
modimport("postinit/emittermanager") --禁用室内雨雪效果
modimport("postinit/sim")
modimport("postinit/pathfinder")  --有室内寻路系统
modimport("postinit/lightwatcher") --室内的光照系统
modimport("postinit/othermods") --一些对其他mod的兼容

for _, file_name in ipairs(behaviour_posts) do
    modimport("postinit/behaviours/" .. file_name)
end

for _, file_name in ipairs(camera_posts) do
    modimport("postinit/cameras/" .. file_name)
end

for _, file_name in ipairs(component_posts) do
    modimport("postinit/components/" .. file_name)
end

for _, file_name in ipairs(prefab_posts) do
    modimport("postinit/prefabs/" .. file_name)
end

for _, file_name in ipairs(multipleprefab_posts) do
    modimport("postinit/multipleprefabs/" .. file_name)
end

for _, file_name in ipairs(scenario_posts) do
    modimport("postinit/scenarios/" .. file_name)
end

for _, file_name in ipairs(screens_posts) do
    modimport("postinit/screens/" .. file_name)
end

for _, file_name in ipairs(stategraph_posts) do
    modimport("postinit/stategraphs/SG" .. file_name)
end

for _, file_name in ipairs(brain_posts) do
    modimport("postinit/brains/" .. file_name)
end

for _, file_name in ipairs(widget_posts) do
    modimport("postinit/widgets/" .. file_name)
end

