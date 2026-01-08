
--用途：当实体被解构时移除 fixable 组件
--
--触发事件：ondeconstructstructure（使用解构手杖等工具）
--
--效果：阻止被解构的建筑还能被修复
local function OnDeconstructStructure(inst)
    inst:RemoveComponent("fixable")
end

--用途：处理实体被工具工作的情况
--
--参数：data 包含 workleft（剩余工作次数）和 worker（工作者）
--
--特殊逻辑：当使用带有 fixable_crusher 标签的工具（如毁灭法杖）完成工作时，移除可修复组件
--
--意义：某些特殊工具可以彻底破坏建筑的可修复性
local function OnWorked(inst, data)
    if data.workleft <= 0 then
        local worker = data.worker
        local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if tool and tool:HasTag("fixable_crusher") then
            inst:RemoveComponent("fixable")
        end
    end
end

--初始化：
--
--保存实体引用
--
--初始化空的重建阶段和动画表
--
--添加 fixable 标签（用于识别可修复实体）
--
--注册事件监听器
local Fixable = Class(function(self, inst)
    self.inst = inst
    self.reconstruction_stages = {}
    self.reconstruction_anims = {}

    self.inst:AddTag("fixable")

    self.inst:ListenForEvent("worked", OnWorked)
    self.inst:ListenForEvent("ondeconstructstructure", OnDeconstructStructure)
end)

--用途：当组件从实体中移除时的清理工作
--
--清理内容：
--
--移除 fixable 标签
--
--取消事件监听，防止内存泄漏
function Fixable:OnRemoveFromEntity()
    self.inst:RemoveTag("fixable")
    self.inst:RemoveEventCallback("worked", OnWorked)
    self.inst:RemoveEventCallback("ondeconstructstructure", OnDeconstructStructure)
end

--用途：当实体被完全移除（销毁）时，创建一个重建项目来保存重建状态
--
--关键特性：实现了"废墟系统" - 建筑被毁后留下可重建的废墟
--
--数据传递：
--
--重建阶段信息
--
--原始预制体信息
--
--内部空间ID（用于洞穴内建筑）
--
--购买状态（用于玩家房屋）
--
--生成器配置（用于会生成生物的房屋）
--
--结果：实体消失，但留下一个 reconstruction_project，玩家可以与其交互来重建建筑
function Fixable:OnRemoveEntity()
    local fixer = SpawnPrefab("playerhouse_reconstruction")
    -- 传递重建数据到新实体
    fixer.reconstruction_prefab = self.reconstruction_prefab or self.inst.prefab
    fixer.reconstruction_overridebuild = self.overridebuild
    fixer.interiorID = self.inst.interiorID
    fixer.exterior_pos = self.inst:GetPosition()

    fixer.bought = self.inst.bought

    -- 传递生成器数据（如猪屋生成的猪人）
    if self.inst.components.spawner then
        fixer.spawner_data = {
            childname = self.inst.components.spawner.childname,
            child = self.inst.components.spawner.child or nil,
            delay = self.inst.components.spawner.delay,
        }
    end

    -- 初始化重建项目
    fixer.Transform:SetPosition(self.inst.Transform:GetWorldPosition())

    -- 处理内部空间转移（如果适用）
    if fixer.interiorID then
        TheWorld.components.interiorspawner:TransferExterior(self.inst, fixer)
    end
end

return Fixable

