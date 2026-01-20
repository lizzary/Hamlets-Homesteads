local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)
local cooking = require("cooking")

--local function roomsysHarvest(self,harvester)
--    if self.done then
--        if self.onharvest ~= nil then
--            self.onharvest(self.inst)
--        end
--
--        if self.product ~= nil then
--            local loot
--
--            --有标签，直接换生成物
--            if self.inst:HasTag("in_kitchen") then
--                --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
--                if self.inst:HasTag("spicer") then loot = SpawnPrefab(self.product) else loot = SpawnPrefab(self.product .. "_kitchen_buff") end
--
--                --如果是一些不可食用或者合成表没的料理就返回原料理
--                if not loot then loot = SpawnPrefab(self.product) end
--
--            else--没标签，判断一下当前这个锅的位置，如果还是没标签，走正常逻辑，如果有标签，就添加标签，换生成物
--                local x, y, z = self.inst.Transform:GetWorldPosition()
--                local roomtype = TheWorld.components.roomsystem:GetRoomTypeByWorldPos(x, z)
--
--                if roomtype == "kitchen" then
--                    --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
--                    if self.inst:HasTag("spicer") then loot = SpawnPrefab(self.product) else loot = SpawnPrefab(self.product .. "_kitchen_buff") end
--
--                    --如果是一些不可食用或者合成表没的料理就返回原料理
--                    if not loot then loot = SpawnPrefab(self.product) end
--                    self.inst:AddTag("in_kitchen")
--                else
--                    loot = SpawnPrefab(self.product)
--                end
--            end
--
--
--            if loot ~= nil then
--				local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
--
--				if harvester ~= nil and
--					self.chef_id == harvester.userid and
--					recipe ~= nil and
--					recipe.cookbook_category ~= nil and
--					cooking.cookbook_recipes[recipe.cookbook_category] ~= nil and
--					cooking.cookbook_recipes[recipe.cookbook_category][self.product] ~= nil then
--					harvester:PushEvent("learncookbookrecipe", {product = self.product, ingredients = self.ingredient_prefabs})
--				end
--
--				local stacksize = recipe and recipe.stacksize or 1
--				if stacksize > 1 then
--					loot.components.stackable:SetStackSize(stacksize)
--				end
--
--                if self.spoiltime ~= nil and loot.components.perishable ~= nil then
--                    local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
--                    loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
--                    loot.components.perishable:StartPerishing()
--                end
--                if harvester ~= nil and harvester.components.inventory ~= nil then
--                    harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
--                else
--                    LaunchAt(loot, self.inst, nil, 1, 1)
--                end
--            end
--            self.product = nil
--        end
--
--        if self.task ~= nil then
--            self.task:Cancel()
--            self.task = nil
--        end
--        self.targettime = nil
--        self.done = nil
--        self.spoiltime = nil
--        self.product_spoilage = nil
--
--        if self.inst.components.container ~= nil then
--            self.inst.components.container.canbeopened = true
--        end
--
--        return true
--    end
--end
--local function dump(o, indent)
--    indent = indent or 0
--    local prefix = string.rep("  ", indent)
--
--    if type(o) ~= "table" then
--        print(prefix .. tostring(o))
--        return
--    end
--
--    print(prefix .. "{")
--    for k, v in pairs(o) do
--        io.write(prefix .. "  [" .. tostring(k) .. "] = ")
--        if type(v) == "table" then
--            dump(v, indent + 1)
--        else
--            print(tostring(v))
--        end
--    end
--    print(prefix .. "}")
--end
--local function SpawnFood(Stewer)
--    --Stewer.inst：有stewer组件的那个实例，比如烹饪锅
--    local loot
--
--    --有厨房标签
--    if Stewer.inst:HasTag("in_kitchen") then
--        --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
--        if Stewer.inst:HasTag("spicer") then loot = SpawnPrefab(Stewer.product) else loot = SpawnPrefab(Stewer.product .. "_kitchen_buff") end
--
--        --如果是一些不可食用或者合成表没的料理就返回原料理
--        if not loot then loot = SpawnPrefab(Stewer.product) end
--
--    else--没厨房标签，判断一下当前这个锅的位置，如果还是没标签，走正常逻辑，如果有标签，就添加标签，换生成物
--
--        local x, y, z = Stewer.inst.Transform:GetWorldPosition()
--        local roomtype = TheWorld.components.roomsystem:GetRoomTypeByWorldPos(x, z)
--
--        if roomtype == "kitchen" then
--            --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
--            if Stewer.inst:HasTag("spicer") then loot = SpawnPrefab(Stewer.product) else loot = SpawnPrefab(Stewer.product .. "_kitchen_buff") end
--
--            --如果是一些不可食用或者合成表没的料理就返回原料理
--            if not loot then loot = SpawnPrefab(Stewer.product) end
--            Stewer.inst:AddTag("in_kitchen")
--        else
--            loot = SpawnPrefab(Stewer.product)
--        end
--    end
--
--    return loot
--end

local function SetProduct(Stewer)
    local kitchbuff_product = Stewer.product .. "_kitchen_buff"
    --有厨房标签
    if Stewer.inst:HasTag("in_kitchen") then
         --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
        if not Stewer.inst:HasTag("spicer") and PrefabExists(kitchbuff_product) then
            Stewer.product = kitchbuff_product
        end
    else --没厨房标签，判断一下当前这个锅的位置，如果还是没标签，走正常逻辑，如果有标签，就添加标签，换生成物
        local x, y, z = Stewer.inst.Transform:GetWorldPosition()
        local roomtype = TheWorld.components.roomsystem:GetRoomTypeByWorldPos(x, z)
        if roomtype == "kitchen" then
             --便携香料站不与厨房系统互动，但是带有厨房加成的料理加香料能产出带有厨房加成和香料的料理，具体参考kitchen_buff_foods.lua
            if not Stewer.inst:HasTag("spicer") and PrefabExists(kitchbuff_product) then
                Stewer.product = kitchbuff_product
            end
        end

    end
end


AddComponentPostInit("stewer",function(Stewer)
    local oldHarvest = Stewer.Harvest
    function Stewer:Harvest(harvester)
        if self.inst:HasTag("in_kitchen") then
            print("this cookpot in kitchen !")
        end
        SetProduct(Stewer)
        local result = oldHarvest(self,harvester)
        return result
    end

    local oldStartCooking = Stewer.StartCooking
    function Stewer:StartCooking(doer)

        --有标签，直接减cooktime
        if Stewer.inst:HasTag("in_kitchen") then
            local oldCalculateRecipe = cooking.CalculateRecipe
            local ingredient_prefabs = {}
            for k, v in pairs(Stewer.inst.components.container.slots) do
                table.insert(ingredient_prefabs, v.prefab)
            end
            local product, cooktime = oldCalculateRecipe(Stewer.inst.prefab, ingredient_prefabs)
            print("cal foods: ",product)
            --伪造一个Stewer:StartCooking里面的cooking.CalculateRecipe函数让他在oldStartCooking里面返回我想要的值
            cooking.CalculateRecipe = function(_, _)
                return product, cooktime * 0.1
            end
            oldStartCooking(self, doer)
            --还原cooking.CalculateRecipe无事发生
            cooking.CalculateRecipe = oldCalculateRecipe

        else--没标签，判断一下当前这个锅的位置，如果还是没标签，走正常逻辑，如果有标签，就添加标签，减cooktime
            local x, y, z = self.inst.Transform:GetWorldPosition()
            local roomtype = TheWorld.components.roomsystem:GetRoomTypeByWorldPos(x, z)
            if roomtype == "kitchen" then
                local oldCalculateRecipe = cooking.CalculateRecipe

                local ingredient_prefabs = {}

                for k, v in pairs(Stewer.inst.components.container.slots) do
                    table.insert(ingredient_prefabs, v.prefab)
                end
                local product, cooktime = oldCalculateRecipe(Stewer.inst.prefab, ingredient_prefabs)
                print("cal foods: ",product)
                --伪造一个Stewer:StartCooking里面的cooking.CalculateRecipe函数让他在oldStartCooking里面返回我想要的值
                cooking.CalculateRecipe = function(_, _)
                    return product, cooktime * 0.1
                end
                oldStartCooking(self, doer)
                --还原cooking.CalculateRecipe无事发生
                cooking.CalculateRecipe = oldCalculateRecipe
                self.inst:AddTag("in_kitchen")
            else
                --走正常逻辑
                oldStartCooking(self, doer)
            end
        end
    end
end)