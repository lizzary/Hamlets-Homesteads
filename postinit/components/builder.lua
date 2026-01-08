GLOBAL.setfenv(1, GLOBAL)

local Builder = require("components/builder")

function Builder:MakeRecipeAtPoint(recipe, pt, rot, skin)
    if not self.inst.components.inventory:IsOpenedBy(self.inst) then
        return
    end

    if recipe.placer
        and (self:KnowsRecipe(recipe) or self:CanLearn(recipe.name) and CanPrototypeRecipe(recipe.level, self.accessible_tech_trees))
        and self:IsBuildBuffered(recipe.name)
        and TheWorld.Map:CanDeployRecipeAtPoint(pt, recipe, rot, self.inst) then

        self:MakeRecipe(recipe, pt, rot, skin)
    end
end

local _EvaluateTechTrees = Builder.EvaluateTechTrees
function Builder:EvaluateTechTrees(...)
    local key = self.inst.components.inventory:FindItem(function(obj)
        return obj:HasTag("prototyper_ignore_inlimbo")
    end)
    
    if key then
        key:RemoveTag("INLIMBO")
    end
    
    local rets = {_EvaluateTechTrees(self, ...)}
    
    if key then
        key:AddTag("INLIMBO")
    end
    return unpack(rets)
end
