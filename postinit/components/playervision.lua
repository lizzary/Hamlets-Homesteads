local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("playervision", function(self)
    local NIGHTVISION_COLOURCUBES = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_COLOURCUBES")
    local GHOSTVISION_COLOURCUBES = ToolUtil.GetUpvalue(self.UpdateCCTable, "GHOSTVISION_COLOURCUBES")
    local NIGHTVISION_PHASEFN = ToolUtil.GetUpvalue(self.UpdateCCTable, "NIGHTVISION_PHASEFN")
    local NIGHTVISION_COLOURCUBES_INTERIOR = shallowcopy(NIGHTVISION_COLOURCUBES)
    NIGHTVISION_COLOURCUBES_INTERIOR.day = NIGHTVISION_COLOURCUBES_INTERIOR.night
    NIGHTVISION_COLOURCUBES_INTERIOR.dusk = NIGHTVISION_COLOURCUBES_INTERIOR.night
    NIGHTVISION_COLOURCUBES_INTERIOR.full_moon = NIGHTVISION_COLOURCUBES_INTERIOR.night

    self.inst:ListenForEvent("enterinterior_client", function() self:UpdateCCTable() end)
    self.inst:ListenForEvent("leaveinterior_client", function() self:UpdateCCTable() end)

    local _UpdateCCTable = self.UpdateCCTable
    function self:UpdateCCTable()
        _UpdateCCTable(self)
        if (self.overridecctable ~= nil) and (self.currentcctable == self.overridecctable) then
            return
        end
        
        -- 只保留室内视觉相关的代码
        if self.inst:HasTag("inside_interior")
            and (not self.currentcctable or
            not (self.currentcctable == NIGHTVISION_COLOURCUBES
            or self.currentcctable == GHOSTVISION_COLOURCUBES)) then

            local cc = self.inst.replica.interiorvisitor:GetCCTable()
            self.currentcctable = cc
            self.inst:PushEvent("ccoverrides", cc)
            self.inst:PushEvent("ccphasefn", nil)
        elseif self.currentcctable == NIGHTVISION_COLOURCUBES then
            if self.inst:HasTag("inside_interior") then
                local cc = NIGHTVISION_COLOURCUBES_INTERIOR
                self.currentcctable = cc
                self.inst:PushEvent("ccoverrides", cc)
                self.inst:PushEvent("ccphasefn", NIGHTVISION_PHASEFN)
            end
        end
    end
end)