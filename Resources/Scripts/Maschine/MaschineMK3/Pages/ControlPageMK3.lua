------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/ControlPageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ControlPageMK3 = class( 'ControlPageMK3', ControlPageStudio )

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:__init(Controller)

    ControlPageStudio.__init(self, Controller, "ControlPageMK3")

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:setupScreen()

    ControlPageStudio.setupScreen(self)

    -- Screen Button Definition
    self.ScreenButtonText = {
        {"MASTER", "GROUP", "SOUND", "", "<<", ">>"}, -- Normal
        {"", "EDIT", "INSERT", "SAVE", "<<", ">>", "BYPASS", "REMOVE"} } -- with shift button held down

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:showPresets()

    self.OldJogWheelMode = NHLController:getJogWheelMode()
    NHLController:setJogWheelMode(NI.HW.JOGWHEEL_MODE_CUSTOM)
    ControlPageStudio.showPresets(self)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:hidePresets()

    if self.OldJogWheelMode then
        NHLController:setJogWheelMode(self.OldJogWheelMode)
        self.OldJogWheelMode = nil
    end

    ControlPageStudio.hidePresets(self)

end

------------------------------------------------------------------------------------------------------------------------

local function hidePresetListAndUpdateScreenButtons(self, Pressed)

    if Pressed then
        ControlPageStudio.hidePresets(self)
        self:updateScreenButtons(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:updateScreens(ForceUpdate)

    ControlPageStudio.updateScreens(self, ForceUpdate)

    if App:getWorkspace():getModulesVisibleParameter():isChanged() then
        self:sendAccessibilityInfoForPage()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:onVolumeButton(Pressed)

    hidePresetListAndUpdateScreenButtons(self, Pressed)
    PageMaschine.onVolumeButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:onTempoButton(Pressed)

    hidePresetListAndUpdateScreenButtons(self, Pressed)
    PageMaschine.onTempoButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:onSwingButton(Pressed)

    hidePresetListAndUpdateScreenButtons(self, Pressed)
    PageMaschine.onSwingButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:onWheelDirection(Pressed, Button)

    if Pressed then
        if Button == NI.HW.BUTTON_WHEEL_LEFT or Button == NI.HW.BUTTON_WHEEL_RIGHT then
            ControlHelper.onPrevNextSlot(Button == NI.HW.BUTTON_WHEEL_RIGHT, false)
        end
    else
        local SoftButtonEquivalent = Button == NI.HW.BUTTON_WHEEL_LEFT and 5 or 6
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SOFTBUTTONS, SoftButtonEquivalent - 1)
    end

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:updateWheelButtonLEDs()

    local CanLeft = ControlHelper.hasPrevNextSlotOrPageGroup(false, false)
    local CanRight = ControlHelper.hasPrevNextSlotOrPageGroup(true, false)
    local Color = LEDColors.WHITE

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, false, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, false, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanLeft, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanRight, Color)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:onScreenButton4ShiftPluginMode()

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    if MaschineHelper:isShowingPlugins() and FocusSlot then
        NI.GUI.ChainFileCommands.saveSlotAs(App, FocusSlot, false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:setupScreenButton4()

    self.Screen.ScreenButton[4]:style("SAVE", "HeadButton")

    local ShiftPressed = self.Controller:getShiftPressed()
    self.Screen.ScreenButton[4]:setVisible(ShiftPressed and MaschineHelper:isShowingPlugins())

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    local CanSave = FocusSlot and NI.GUI.ChainFileCommands.canSave(FocusSlot) or false
    self.Screen.ScreenButton[4]:setEnabled(ShiftPressed and CanSave)

    self.Screen.ScreenButton[4]:setSelected(false)

end

------------------------------------------------------------------------------------------------------------------------

function ControlPageMK3:getAccessiblePageInfo()

    return MaschineHelper:isShowingPlugins() and "Plugin" or "Channel"

end

------------------------------------------------------------------------------------------------------------------------
