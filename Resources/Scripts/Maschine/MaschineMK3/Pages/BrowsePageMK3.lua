------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/BrowsePageColorDisplayBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageMK3 = class( 'BrowsePageMK3', BrowsePageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:__init(Controller, SamplingPage)

    BrowsePageColorDisplayBase.__init(self, "BrowsePageStudio", Controller, SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onTimer()

    self:updateWheelButtonLEDs()

    local ErasePressed = self.Controller:getErasePressed()
    local ShiftPressed = self.Controller:getShiftPressed()

    LEDHelper.setLEDState(NI.HW.LED_TRANSPORT_ERASE,
        BrowseHelper:getUserMode() and not ShiftPressed and ErasePressed and LEDHelper.LS_BRIGHT or
        BrowseHelper:getUserMode() and not ShiftPressed and BrowseHelper:getUserMode() and LEDHelper.LS_DIM or
        LEDHelper.LS_OFF)

    BrowsePageColorDisplayBase.onTimer(self)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onShow(Show)

    BrowsePageColorDisplayBase.onShow(self, Show)

    if not Show and NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_DEFAULT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onWheel(Inc)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        return BrowsePageColorDisplayBase.onWheel(self, Inc)
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onWheelButton(Pressed)

    if NHLController:getJogWheelMode() == NI.HW.JOGWHEEL_MODE_CUSTOM then
        BrowsePageColorDisplayBase.onWheelButton(self, Pressed)
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onWheelDirection(Pressed, DirectionButton)

    if DirectionButton == NI.HW.BUTTON_WHEEL_LEFT or DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT then
        self:onPrevNextButton(Pressed, DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT)
    elseif DirectionButton == NI.HW.BUTTON_WHEEL_UP or DirectionButton == NI.HW.BUTTON_WHEEL_DOWN then
        self:onLeftRightButton(DirectionButton == NI.HW.BUTTON_WHEEL_DOWN, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:updateWheelButtonLEDs()

    local Color = LEDColors.WHITE

    local CanUp, CanDown = self:getLeftRightButtonStates()
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP,
                              CanUp or CanUp == nil, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN,
                              CanDown or CanDown == nil, Color)

    local CanLeft, CanRight = self:getPrevNextButtonStates()
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onVolumeButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_VOLUME)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onTempoButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_TEMPO)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onSwingButton(Pressed)

    if Pressed then
        BrowseHelper.toggleAndStoreJogWheelMode(self, NI.HW.JOGWHEEL_MODE_SWING)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:updateScreenButtons(ForceUpdate)

    if not self.Controller:getShiftPressed() then
        self:updateScreenButtonPrevNextFileType()
        self:updateScreenButtonPrevNextPreset()
    else
        self:updateScreenButtonPrevNextSlot()
    end

    BrowsePageColorDisplayBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:onScreenButton(ButtonIdx, Pressed)

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

function BrowsePageMK3:canDeleteFiles()

    return true

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageMK3:getAccessiblePageInfo()

    return "Browser"

end

------------------------------------------------------------------------------------------------------------------------
