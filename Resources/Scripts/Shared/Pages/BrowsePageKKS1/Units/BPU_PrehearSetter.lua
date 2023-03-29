
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------
-- Prehear Setter (7th knob on shift)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_PrehearSetter = class( 'BPU_PrehearSetter', BrowsePageUnitBase )

function BPU_PrehearSetter:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearSetter:isEnabled()

    return NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearSetter:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, BrowseHelper.isPrehearEnabled() and "ON" or "OFF")

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_SECOND_ROW, "PREHEAR")

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_CENTER)
    self.DisplayPage:setMeterValue(self.Index, BrowseHelper.isPrehearEnabled() and 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearSetter:onEncoderChanged(Value)

    local Delta = BrowsePageUnitBase.smoothEncoder(self, Value, .1)
    if Delta == 0 then
        return false
    end

    local PrehearEnabled = BrowseHelper.isPrehearEnabled() and 1 or -1
    local ShouldToggle = PrehearEnabled + Delta == 0

    if ShouldToggle then
        BrowseHelper.togglePrehear()
    end

    return ShouldToggle

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearSetter:getParameterName()

    return "Set Prehear"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearSetter:getParameterValue()

    return BrowseHelper.isPrehearEnabled() and "ON" or "OFF"

end
