
require "Scripts/Shared/Pages/BrowsePageKKS1/Units/BrowsePageUnitBase"
require "Scripts/Shared/Helpers/BrowseHelper"

------------------------------------------------------------------------------------------------------------------------
-- Prehear Volume (8th knob on shift)
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BPU_PrehearVolume = class( 'BPU_PrehearVolume', BrowsePageUnitBase )

function BPU_PrehearVolume:__init(Index, Page)

    BrowsePageUnitBase.__init(self, Index, Page)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearVolume:isEnabled()

    return NI.DATA.SamplePrehearAccess.shouldShowPrehearWidget(App)

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearVolume:draw()

    if not self:isEnabled() then
        self.DisplayPage:setMeterActive(self.Index, false)
        return
    end

    -- text

    self.DisplayPage:setText(self.Index, SCREEN.DISPLAY_FIRST_ROW, "VOLUME")

    -- meter

    self.DisplayPage:setMeterActive(self.Index, true)
    self.DisplayPage:setMeterAlignment(self.Index, SCREEN.ALIGN_LEFT)
    self.DisplayPage:setMeterValue(self.Index, App:getWorkspace():getPrehearLevelParameter():getValue())

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearVolume:onEncoderChanged(Value)

    BrowseHelper.changePrehearVolume(Value)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearVolume:getParameterName()

    return "Prehear Volume"

end

------------------------------------------------------------------------------------------------------------------------

function BPU_PrehearVolume:getParameterValue()

    local floatValue = App:getWorkspace():getPrehearLevelParameter():getValue()
    return string.format("%0.1f", floatValue)

end
