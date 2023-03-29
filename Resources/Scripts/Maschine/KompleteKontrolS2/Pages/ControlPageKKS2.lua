------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/AccessibilityTextHelper"
require "Scripts/Shared/Pages/AccessibleControlPage"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageKKS2 = class( 'ControlPageKKS2', AccessibleControlPage )

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:__init(Controller)

    AccessibleControlPage.__init(self, Controller, "ControlPageStudio")

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:updateWheelButtonLEDs()

    local CanLeft = ControlHelper.hasPrevNextSlotOrPageGroup(false, false)
    local CanRight = ControlHelper.hasPrevNextSlotOrPageGroup(true, false)
    local IsPresetListState = self.PresetListState == ControlPageStudio.PRESETS_ON
    local CanUp = IsPresetListState and BrowseHelper.hasPreviousPreset() or false
    local CanDown = IsPresetListState and BrowseHelper.hasNextPreset() or false

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, CanUp)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, CanDown)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:onWheelDirection(Pressed, Button)

    if Pressed then

        if Button == NI.HW.BUTTON_WHEEL_UP or Button == NI.HW.BUTTON_WHEEL_DOWN then
            if self.PresetListState == ControlPageStudio.PRESETS_ON then
                if BrowseHelper.offsetResultListFocusBy(Button == NI.HW.BUTTON_WHEEL_DOWN and 1 or -1) then
                    BrowseHelper.loadFocusItem()
                end
            end

        elseif Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            ControlHelper.onPrevNextSlot(Button == NI.HW.BUTTON_WHEEL_RIGHT, false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:onWheel(Inc)

    if self.PresetListState == ControlPageStudio.PRESETS_ON then
        BrowseHelper.offsetResultListFocusBy(Inc, true)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:getScreenButtonInfo(Index)

    local Info = AccessibleControlPage.getScreenButtonInfo(self, Index)
    if not Info then
        return
    end

    if self.Controller:getShiftPressed() and Index == 3 then
        Info.SpeechName = "Insert Plug-in"
        Info.SpeechValue = ""
    elseif not self.Controller:getShiftPressed() and Index == 8 then
        Info.SpeechName = "Quick Browse"
        local QuickBrowseVisible = (self.PresetListState == ControlPageStudio.PRESETS_PENDING or
                                    self.PresetListState == ControlPageStudio.PRESETS_ON)
        Info.SpeechValue = "Quick Browse" .. (QuickBrowseVisible and " On" or " Off")
        Info.SpeakValueInTrainingMode = false
        Info.SpeakNameInNormalMode = false
    end
    return Info

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:updateLEDs()

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_CLEAR, NI.HW.BUTTON_CLEAR, FocusSlot)
end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:setupScreenButton4()

    self.Screen.ScreenButton[4]:setVisible(false)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:onClear(Pressed)

    if Pressed then

        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
        local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)

        if Slots and FocusSlot then
            NI.DATA.ChainAccess.removeSlot(App, Slots, FocusSlot)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:getWheelDirectionInfo(Direction)

    local DirectionNames = {
        [NI.HW.BUTTON_WHEEL_UP] = nil,
        [NI.HW.BUTTON_WHEEL_DOWN] = nil,
        [NI.HW.BUTTON_WHEEL_LEFT] = "Previous Slot",
        [NI.HW.BUTTON_WHEEL_RIGHT] = "Next Slot"
    }
    local Msg = DirectionNames[Direction]

    local Info = {}
    Info.TrainingMode = Msg
    Info.NormalMode = MaschineHelper.getFocusChannelSlotName()

    return Info

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageKKS2:getWheelParameterValueString()

    if self.PresetList:isVisible() and NI.DATA.WORKSPACE.getAccessibilitySpeakPreset(App) then
        local ResultList = App:getDatabaseFrontend():getBrowserModel():getResultListModel()
        local FocusItem = ResultList:getFocusItem()
        return ResultList:getItemName(FocusItem)
    end
    return ""

end
