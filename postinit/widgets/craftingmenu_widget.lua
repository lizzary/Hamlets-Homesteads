local PLENV = env
GLOBAL.setfenv(1, GLOBAL)
local Grid = require("widgets/grid")
local CraftingMenuWidget = require("widgets/redux/craftingmenu_widget") -- 导入制作菜单组件

--闭包函数，用于创建查找特定纹理组件的回调函数
local function FindImageChild(texture, fn)
    return function(child)
        return child.texture == texture
    end
end

--重写MakeFrame，扩展原始框架创建方法，保存框架各部分的引用，以便后续调整
local _MakeFrame = CraftingMenuWidget.MakeFrame
function CraftingMenuWidget:MakeFrame(width, height)
    local w = _MakeFrame(self, width, height) -- 调用原始方法创建框架

    self.frame_width = width -- 框架宽度
    self.frame_height = height -- 框架高度
    self.frame_fill = w:FindChild(FindImageChild("backing.tex"))  -- 查找背景填充部分
    self.frame_left = w:FindChild(function(child) -- 查找左边框
        local pos = child:GetPosition()
        return child.texture == "side.tex" and pos.x < 0 -- 纹理为side.tex且x坐标小于0
    end)
    self.frame_right =  w:FindChild(function(child) -- 查找右边框（类似左边框）
        local pos = child:GetPosition()
        return child.texture == "side.tex" and pos.x > 0
    end)
    self.frame_top = w:FindChild(FindImageChild("top.tex")) -- 查找上边框
    self.frame_bottom = w:FindChild(FindImageChild("bottom.tex")) -- 查找下边框

    self:UpdateFrame(true) -- 更新框架布局，true表示强制更新

    return w
end

--添加原型过滤器网格到过滤器面板，动态调整面板高度
local _MakeFilterPanel = CraftingMenuWidget.MakeFilterPanel
function CraftingMenuWidget:MakeFilterPanel(...)
    local _FillGrid = Grid.FillGrid -- 保存原始FillGrid方法
    Grid.FillGrid = function(grid, num_columns, coffset, roffset, items, ...)
        self.grid_buttons_wide = num_columns -- 保存网格按钮宽度
        self:SetFilter(items) -- 设置过滤器分类
        local valid_filters = self:GetValidFilter() -- 获取有效过滤器
        return _FillGrid(grid, num_columns, coffset, roffset, valid_filters, ...) -- 调用原始方法
    end

    local filter_panel = _MakeFilterPanel(self, ...) -- 创建原始过滤器面板
    Grid.FillGrid = _FillGrid -- 恢复原始FillGrid方法

    -- 添加原型过滤器网格
    self.filter_line = filter_panel:FindChild(FindImageChild("line_horizontal_white.tex")) -- 找到分隔线
    self.filter_line_pt = self.filter_line:GetPosition() -- 保存分隔线位置
    self.filter_grid_pt = filter_panel.filter_grid:GetPosition() -- 保存过滤器网格位置

    local prototyper_filter_grid = filter_panel:AddChild(Grid()) -- 创建原型过滤器网格
    prototyper_filter_grid:SetLooping(false, false) -- 设置网格不循环
    prototyper_filter_grid:FillGrid(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, self.prototyper_filters) -- 填充网格
    prototyper_filter_grid:SetPosition(self.filter_grid_pt.x, - self.grid_button_space) -- 设置位置
    filter_panel.prototyper_filter_grid = prototyper_filter_grid -- 将网格添加到面板

    filter_panel.panel_height = filter_panel.panel_height + self.grid_button_space * prototyper_filter_grid.num_rows -- 调整面板高度

    return filter_panel
end

--在更新过滤器按钮时同时更新框架布局
local _UpdateFilterButtons = CraftingMenuWidget.UpdateFilterButtons
function CraftingMenuWidget:UpdateFilterButtons(...)
    self:UpdateFrame() -- 更新框架布局
    return _UpdateFilterButtons(self, ...) -- 调用原始方法
end

--将过滤器分成普通过滤器和原型过滤器两类
function CraftingMenuWidget:SetFilter(filters)
    self.filters = {} -- 普通过滤器列表
    self.prototyper_filters = {} -- 原型过滤器列表

    for i, filter in ipairs(filters) do
        if filter.filter_def.home_prototyper then -- 如果是原型过滤器
            table.insert(self.prototyper_filters, filter)
        else -- 普通过滤器
            table.insert(self.filters, filter)
        end
    end
end

--根据游戏状态（自由建造模式、世界标签）筛选出应该显示的普通过滤器
function CraftingMenuWidget:GetValidFilter()
    local builder = self.owner ~= nil and self.owner.replica.builder or nil -- 获取玩家的builder副本

    local valid_filters = {}
    for i, filter in ipairs(self.filters) do
        if (builder and builder:IsFreeBuildMode())
            or not (filter.filter_def.disabled_worlds and TheWorld:HasTags(filter.filter_def.disabled_worlds))
            then
            filter:Show() -- 显示过滤器
            table.insert(valid_filters, filter)
        else
            filter:Hide() -- 隐藏过滤器
        end
    end

    return valid_filters
end

function CraftingMenuWidget:GetPrototyperFilter()
    if self.owner.replica.builder then
        local tech_bonus = self.owner.replica.builder:GetTechBonuses() -- 获取科技加成
        if tech_bonus.HOME >= 2 then
            return self.prototyper_filters
        end
    end
    return {}
end

--核心方法，根据过滤器数量和类型动态调整整个UI的布局
function CraftingMenuWidget:UpdateFrame(force)
    -- 保存原始行数
    local _filter_grid_num_rows = self.filter_panel.filter_grid.num_rows
    local _prototyper_filter_grid_num_rows = self.filter_panel.prototyper_filter_grid.num_rows

    -- 更新原型过滤器网格
    local valid_prototyper_filters = self:GetPrototyperFilter()
    self.filter_panel.prototyper_filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, valid_prototyper_filters)
    if #valid_prototyper_filters > 0 then
        self.filter_panel.prototyper_filter_grid:Show()
    else
        self.filter_panel.prototyper_filter_grid:Hide()
    end

    -- 调整原型过滤器网格位置
    local delta = _prototyper_filter_grid_num_rows - self.filter_panel.prototyper_filter_grid.num_rows
    if delta ~= 0 or force then
        local prototyper_filter_grid_height = self.filter_panel.prototyper_filter_grid.num_rows * self.grid_button_space
        self.filter_line:SetPosition(self.filter_line_pt.x, self.filter_line_pt.y - prototyper_filter_grid_height)
        self.filter_panel.filter_grid:SetPosition(self.grid_left, self.filter_grid_pt.y - prototyper_filter_grid_height)
    end

    -- 更新普通过滤器网格
    local valid_filters = self:GetValidFilter()
    self.filter_panel.filter_grid:RebuildLayout(self.grid_buttons_wide, self.grid_button_space, self.grid_button_space, valid_filters)

    delta = delta + _filter_grid_num_rows - self.filter_panel.filter_grid.num_rows
    if delta == 0 and not force then
        return
    end

    -- 计算新高度
    local filters_height = self.filter_panel.panel_height - self.grid_button_space * delta
    self.filter_panel.panel_height = filters_height

    -- 计算框架新尺寸
    local width = self.frame_width
    local height = self.frame_height + math.max(filters_height - 147, 0)

    -- 调整框架各部分
    self.frame_fill:ScaleToSize(width + 10, height + 18)
    self.frame_left:ScaleToSize(-26, -(height - 20))
    self.frame_right:ScaleToSize(26, height - 20)
    self.frame_top:SetPosition(0, height / 2 + 10)
    self.frame_bottom:SetPosition(0, -height / 2 - 8)

    -- 调整过滤器面板位置
    self.filter_panel:SetPosition(0, height / 2 - 20)

    -- 调整配方网格位置
    local grid_w, grid_h = self.recipe_grid:GetScrollRegionSize() -- 231
    self.recipe_grid:SetPosition(-2, height / 2 - filters_height - grid_h / 2)

    -- 调整其他UI元素位置
    self.no_recipes_msg:SetPosition(-2, height / 2 - filters_height - grid_h / 2)
    self.itemlist_split:SetPosition(0, height / 2 - filters_height)
    self.itemlist_split2:SetPosition(0, height / 2 - filters_height - grid_h - 2)

    -- 调整详情面板
    self.details_root.panel_height = height - 20 * 2
    self.details_root:SetPosition(0, height / 2 - filters_height - grid_h - 10)

    -- 调整导航提示位置
    self.nav_hint:SetPosition(0, -height / 2 - 30)
end

--热重载时恢复原始方法，防止重复修改
PLENV.OnHotReload = function()
    CraftingMenuWidget.MakeFrame = _MakeFrame
    CraftingMenuWidget.MakeFilterPanel = _MakeFilterPanel
    CraftingMenuWidget.UpdateFilterButtons = _UpdateFilterButtons
end
