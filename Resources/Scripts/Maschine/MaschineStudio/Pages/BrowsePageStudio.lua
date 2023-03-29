------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/BrowsePageColorDisplayBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageStudio = class( 'BrowsePageStudio', BrowsePageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:__init(Controller, SamplingPage)

    BrowsePageColorDisplayBase.__init(self, "BrowsePageStudio", Controller, SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        return BrowsePageColorDisplayBase.onWheel(self, Inc)
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:onWheelButton(Pressed)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        BrowsePageColorDisplayBase.onWheelButton(self, Pressed)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:updateJogwheel()

    local CanPrev, CanNext = self:getPrevNextButtonStates()
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_PREV, NI.HW.BUTTON_TRANSPORT_PREV, CanPrev)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_TRANSPORT_NEXT, NI.HW.BUTTON_TRANSPORT_NEXT, CanNext)

    if BrowseHelper.getParamCount(self.FocusParam) > 0 then
        JogwheelLEDHelper.updateAllOn(MaschineStudioController.JOGWHEEL_RING_LEDS)
    else
        JogwheelLEDHelper.updateAllOff(MaschineStudioController.JOGWHEEL_RING_LEDS)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:updateScreenButtons(ForceUpdate)

    if not self.Controller:getShiftPressed() then
        self:updateScreenButtonPrevNextFileType()
        self:updateScreenButtonPrevNextPreset()
    else
        self:updateScreenButtonPrevNextSlot()
    end

    BrowsePageColorDisplayBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageStudio:onScreenButton(ButtonIdx, Pressed)

    if BrowseHelper.isBusy() then
        return
    end

    if Pressed then
        if not self.Controller:getShiftPressed() then
            self:onScreenButtonPrevNextFileType(ButtonIdx)
            self:onScreenButtonPrevNextPreset(ButtonIdx)
        else
            if not self.SamplingPage and (ButtonIdx == 5 or ButtonIdx == 6) then
                BrowseHelper.onPrevNextPluginSlot(ButtonIdx == 6)
            end
        end
    end

    BrowsePageColorDisplayBase.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
