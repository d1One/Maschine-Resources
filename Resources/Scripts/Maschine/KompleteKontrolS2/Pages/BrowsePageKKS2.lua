------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/AccessibilityTextHelper"
require "Scripts/Shared/Pages/BrowsePageColorDisplayBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BrowsePageKKS2 = class( 'BrowsePageKKS2', BrowsePageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:__init(Controller, SamplingPage)

    BrowsePageColorDisplayBase.__init(self, "BrowsePageStudio", Controller, SamplingPage)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:updateWheelButtonLEDs()

    local CanPrev, CanNext = self:getPrevNextButtonStates()
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanPrev)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanNext)
    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_UP, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_WHEEL_BUTTON_DOWN, LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:updateLEDs()

    LEDHelper.setLEDState(NI.HW.LED_CLEAR, LEDHelper.LS_OFF)
end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:onWheelButton(Pressed)

    if Pressed then
        self:loadFocusItem()
        self.Controller:changePage(NI.HW.PAGE_CONTROL)
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:getWheelParameterName()

    return self:getEncoderParameterSpeechName(self.FocusParam)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:getWheelParameterValueString()

    local SpeakPreset = NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App)

    if SpeakPreset or not BrowseHelper.canPrehear() then
        return self:getEncoderParameterSpeechValue(self.FocusParam)
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:updateScreenButtons(ForceUpdate)

    if not self.Controller:getShiftPressed() then
        self:updateScreenButtonPrevNextFileType()
        self:updateScreenButtonPrevNextPreset()
    else
        self:updateScreenButtonPrevNextSlot()
    end

    BrowsePageColorDisplayBase.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:onScreenButton(ButtonIdx, Pressed)

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

function BrowsePageKKS2:onWheelDirection(Pressed, DirectionButton)

    if DirectionButton == NI.HW.BUTTON_WHEEL_LEFT or DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT then
        self:onPrevNextButton(Pressed, DirectionButton == NI.HW.BUTTON_WHEEL_RIGHT)
    elseif DirectionButton == NI.HW.BUTTON_WHEEL_UP or DirectionButton == NI.HW.BUTTON_WHEEL_DOWN then
        self:onLeftRightButton(DirectionButton == NI.HW.BUTTON_WHEEL_DOWN, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function BrowsePageKKS2:getScreenButtonInfo(ButtonIndex)

    local Info = BrowsePageColorDisplayBase.getScreenButtonInfo(self, ButtonIndex)
    if not Info then
        return
    end

    if ButtonIndex == 5 or ButtonIndex == 6 then

        local PresetMessage = function()
            if not BrowseHelper.canPrehear() or NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
                return self:getEncoderParameterSpeechValue(8)
            end
            return ""
        end

        Info.SpeakValueInTrainingMode = false
        Info.SpeakNameInNormalMode = false
        local ModeSlots = self.Controller:getShiftPressed()
        local ModeSuffix = ModeSlots and " Slot" or " Preset"
        Info.SpeechName = (ButtonIndex == 5 and "Previous" or "Next") .. ModeSuffix
        Info.SpeechValue = ModeSlots and AccessibilityTextHelper.getFocusPluginMessage() or PresetMessage()

    end
    return Info

end

------------------------------------------------------------------------------------------------------------------------
