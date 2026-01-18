local AddClassPostConstruct = AddClassPostConstruct
local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)
local moddir = KnownModIndex:GetModsToLoad(true)
local enablemods = {}

--[[
local moddir = KnownModIndex:GetModsToLoad(true);
for k, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir);
    local name = info and info.name or "unknow";
    print(info);
end
]]
for k, dir in pairs(moddir) do
    local info = KnownModIndex:GetModInfo(dir)
    local name = info and info.name or "unknow"
    print(name)
    enablemods[dir] = name
end
-- MOD是否开启
local function IsModEnable(name)
    for k, v in pairs(enablemods) do
        if v and (k:match(name) or v:match(name)) then return true end
    end
    return false
end
--永不妥协--



--
for i, mod in ipairs(ModManager.mods) do
    --永不妥协有关暴风雪的禁用--
    if mod.modname == "workshop-2039181790" then
        local targetMod = mod
        print("find mod: Uncompromising Mode")


        targetMod.AddComponentPostInit("snowstormwatcher",function(Snowstormwatcher)
            print("injection of Uncompromising-snowstormwatcher ok")
            local oldUpdateSnowstormWalkSpeed = Snowstormwatcher.UpdateSnowstormWalkSpeed --永不妥协在雪中行走时的移速更新函数，逐帧调用
            local oldSnowoverOnUpdate = nil
            if Snowstormwatcher.inst.HUD ~= nil and Snowstormwatcher.inst.HUD.snowover ~= nil then
                print("snowover found")
                oldSnowoverOnUpdate = Snowstormwatcher.inst.HUD.snowover.OnUpdate --在雪中更新暴风雪滤镜时的更新函数，逐帧调用
            end

            function Snowstormwatcher:UpdateSnowstormWalkSpeed(src, data)
                local x, _, z = self.inst.Transform:GetWorldPosition()
                if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
                    if self.inst.HUD ~= nil and self.inst.HUD.snowover ~= nil then
                        print("hiding snowover")
                        self.inst.HUD.snowover.OnUpdate = function(_) return end --把当前室内玩家的暴风雪滤镜整成一个空函数
                        self.inst.HUD.snowover:Hide()
                    end
                    return
                end
                if self.inst.HUD ~= nil and self.inst.HUD.snowover ~= nil then
                   self.inst.HUD.snowover.OnUpdate = oldSnowoverOnUpdate
                end
                oldUpdateSnowstormWalkSpeed(self,src, data)
            end

            --生成雪堆的逻辑
            local oldStartSnowPileTask = Snowstormwatcher.StartSnowPileTask
            function Snowstormwatcher:StartSnowPileTask()
                local x, _, z = self.inst.Transform:GetWorldPosition()
                if TheWorld.components.interiorspawner:IsInInteriorRegion(x, z) then
                    return
                end
                oldStartSnowPileTask(self)
            end
        end)

    end
end