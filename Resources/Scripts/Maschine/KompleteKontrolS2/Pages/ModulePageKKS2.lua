------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineStudio/Pages/ModulePageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ModulePageKKS2 = class( 'ModulePageKKS2', ModulePageStudio )

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:__init(Controller)

    BrowsePageColorDisplayBase.__init(self, "ModulePageStudio", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:updateWheelButtonLEDs()

    local CanLeft = ControlHelper.hasPrevNextSlotOrPageGroup(false, false)
    local CanRight = ControlHelper.hasPrevNextSlotOrPageGroup(true, false)

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, false)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:onPrevNextButton(Pressed, Right)

    if Pressed then
        ControlHelper.onPrevNextSlot(Right, false)

        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:onScreenEncoder(Index, Inc)

    if not self.Controller.SpeechAssist:isTrainingMode() then
        ModulePageStudio.onScreenEncoder(self, Index, Inc)
    end

    self.Controller.SpeechAssist:onEncoderEvent(Index, true)

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:getScreenButtonInfo(Index)

    local Info = PageMaschine.getScreenButtonInfo(self, Index)
    if not Info then
        return
    end

    if Index == 5 then
        Info.SpeechName = "Previous Module"
        Info.SpeechValue = ModuleHelper.moduleNameAt(ModuleHelper.getCurrentModuleIndex())

    elseif Index == 6 then
        Info.SpeechName = "Next Module"
        Info.SpeechValue =  ModuleHelper.moduleNameAt(ModuleHelper.getCurrentModuleIndex())

    elseif Index == 7 then
        Info.SpeechName = "Cancel"
        Info.SpeechValue = ""

    elseif Index == 8 then
        Info.SpeechName = "Load"
        Info.SpeechValue = ""

    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:getScreenEncoderInfo(Index)

    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = ""
    Info.SpeechValue = ""

    if Index == 1 and self.Screen.ScreenButton[3]:isSelected() then
        local ModuleType = ModuleHelper.getCurrentType()
        Info.SpeechName = "Module Type"
        Info.SpeechValue = ModuleType == ModuleHelper.TYPE_INSTRUMENT and "Instrument" or "Effect"

    elseif Index == 2 then
        Info.SpeechName = "Format"
        Info.SpeechValue = ModuleHelper.getSelectedFormat()

    elseif Index == 3 then
        Info.SpeechName = "Vendor"
        Info.SpeechValue = ModuleHelper.getCurrentVendor()

    elseif Index == 8 then
        Info.SpeechName = "Module"
         Info.SpeechValue = ModuleHelper.moduleNameAt(ModuleHelper.getCurrentModuleIndex())
    end

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:getCurrentPageSpeechAssistanceMessage()
    return NI.ACCESSIBILITY.getCurrentPageSpeechAssistanceMessage(App)
end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:focusedItemInfo()
    local Info = {}
    Info.SpeechSectionName = ""
    Info.SpeechName = MaschineHelper.getFocusChannelSlotName()
    Info.SpeechValue = ""
    Info.SpeakNameInNormalMode = false
    Info.SpeakValueInNormalMode = true
    Info.SpeakNameInTrainingMode = true
    Info.SpeakValueInTrainingMode = true

    return Info
end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:getWheelPushInfoString()

    return "Module Browser"

end

------------------------------------------------------------------------------------------------------------------------

function ModulePageKKS2:getWheelParameterValueString()

    local Info = self:getScreenEncoderInfo(8)
    return Info.SpeechValue

end