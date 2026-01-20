---@param en string
---@param zh string
---@return string
local function en_zh(en, zh) -- Other languages don't work
    return (locale == "zh" or locale == "zhr" or locale == "zht") and zh or en
end

name = "Hamlet‘s Homesteads - 哈姆雷特的温馨小屋"
author = "不起风"
description = "哈姆雷特的温馨小屋 v1.1.5 - 作者：不起风"

version = "1.1.5"
forumthread = ""
api_version = 10
api_version_dst = 10

priority = -1

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = { "housing", "building","hamlet", "房子", "建筑","哈姆雷特" }

folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
    name = name .. "-[" .. folder_name .."]"
end

local function Breaker(title_en, title_zh) -- hover does not work, as this item cannot be hovered
    return { name = en_zh(title_en, title_zh), options = { {description = "", data = false} }, default = false }
end


