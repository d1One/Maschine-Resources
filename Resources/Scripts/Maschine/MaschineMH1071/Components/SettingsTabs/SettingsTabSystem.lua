------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"
require "Scripts/Shared/Helpers/BrowseHelper"
require "Scripts/Shared/Helpers/ScreenHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabSystem = class( 'SettingsTabSystem', SettingsTab )

local BUTTON_INDEX_STORAGE = 3
local BUTTON_INDEX_CONTROLLER_MODE_AND_RESET = 4
local BUTTON_INDEX_RESET = 5
local BUTTON_INDEX_CANCEL = 7
local BUTTON_INDEX_ACTION = 8

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:__init(Screen, Categories)
    self.Screen = Screen
    self.Categories = Categories
    SettingsTab.__init(self, NI.HW.SETTINGS_SYSTEM, "SYSTEM", SettingsTab.NO_PARAMETER_BAR)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:addContextualBar(ContextualStack)
    local Container = NI.GUI.insertBar(ContextualStack, "SystemContainer")
    Container:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    if NI.APP.isNativeOS() then
        self.HWSettingsSystemUpdate = NI.GUI.insertHWSettingsSystemUpdate(Container,
            self.Screen.ScreenButton[BUTTON_INDEX_ACTION], self.Screen.ScreenButton[BUTTON_INDEX_CANCEL],
            "HWSettingsSystemUpdate")
        self.GuiController = NI.GUI.insertHWSettingsSystemUpdateController(App, self.HWSettingsSystemUpdate)
        Container:setFlex(self.HWSettingsSystemUpdate)

    else
        local TwoColumns = NI.GUI.insertBar(Container, "TwoColumns")
        TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

        local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
        FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
        local BigIconSystem = NI.GUI.insertBar(FirstColumn, "BigIconSystem")
        BigIconSystem:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")

        local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
        SecondColumn:style(NI.GUI.ALIGN_WIDGET_LEFT, "")
        Container:setFlex(TwoColumns)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:onShow(Show, ShiftPressed)
    if NI.APP.isNativeOS() then
        if Show then
            self.HWSettingsSystemUpdate:setShiftPressed(ShiftPressed)
            self.HWSettingsSystemUpdate:setVisible(true)
            self.GuiController:refreshProductList()

        else
            self.HWSettingsSystemUpdate:setVisible(false)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:updateScreenButton(Index, ScreenButton)
    local IsNativeOS = NI.APP.isNativeOS()
    local IsShiftPressed = NHLController:getShiftButtonPressed()

    local IsVisible = false
    local IsEnabled = false
    local IsSelected = false
    local IsFocused = false
    local ButtonText = ""
    local Style = "HeadButton"

    if Index == BUTTON_INDEX_STORAGE then
        IsVisible = IsNativeOS and not IsShiftPressed
        IsEnabled = IsNativeOS and not IsShiftPressed
        ButtonText = "STORAGE"

    elseif Index == BUTTON_INDEX_CONTROLLER_MODE_AND_RESET then
        IsVisible = true
        IsEnabled = NHLController:isDCInConnected() or IsNativeOS

        if IsNativeOS then
            ButtonText =  IsShiftPressed and "RESET" or "CONTROLLER"
        else
            ButtonText = "STANDALONE"

        end

    elseif IsNativeOS and (Index == BUTTON_INDEX_ACTION or Index == BUTTON_INDEX_CANCEL) then
        return              -- we handle this in c++

    end

    ScreenHelper.updateButton(ScreenButton, IsVisible, IsEnabled, IsSelected, IsFocused, ButtonText, Style)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:onScreenButton(Index, Pressed)
    if not Pressed then
        return

    end

    local IsNativeOS = NI.APP.isNativeOS()
    local IsShiftPressed = NHLController:getShiftButtonPressed()

    if Index == BUTTON_INDEX_CONTROLLER_MODE_AND_RESET then
        if IsNativeOS then
            if IsShiftPressed then
                NHLController:getPageStack():pushPage(NI.HW.PAGE_FACTORY_RESET)

            elseif App:checkSaveBeforeContinue() then
                NHLController:setDeviceMode(NI.HW.DEVICE_MODE_CONTROLLER)
                NI.UTILS.NativeOSHelpers.poweroff(App)

            end

        else
            NHLController:setDeviceMode(NI.HW.DEVICE_MODE_PLUS)

        end

    elseif IsNativeOS and Index == BUTTON_INDEX_STORAGE then
        NI.UTILS.NativeOSHelpers.enableUSBStorageMode(App)

    elseif IsNativeOS and Index == BUTTON_INDEX_ACTION then
        if IsShiftPressed and NI.GUI.DialogAccess.openWarningSystemUpdateReadyDialog(App) then
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,
                App:getDialogsRegistryState():getSystemUpdateDialogDismissedParameter(), true)
            NI.UTILS.NativeOSHelpers.scanAndUpdate(App)

        elseif self.HWSettingsSystemUpdate:isInErrorState() then
            self.GuiController:refreshProductList()

        elseif self.HWSettingsSystemUpdate:isNotLoggedIn() and IsNativeOS then
            NHLController:getPageStack():pushPage(NI.HW.PAGE_LOGIN)

        else
            self.GuiController:doAction()

        end

    elseif IsNativeOS and Index == BUTTON_INDEX_CANCEL then
        self.GuiController:cancel()

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:onWheel(Inc)
    -- we'll need this for scrolling the changelog
    return true

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:onShiftButton(Pressed)
    if NI.APP.isNativeOS() then
        self.HWSettingsSystemUpdate:setShiftPressed(Pressed)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:hasSystemUpdate()
    return NI.APP.isNativeOS() and self.HWSettingsSystemUpdate:hasUpdates() or false

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabSystem:updateScreens(ForceUpdate)
    if NI.APP.isNativeOS() and self.Categories then
        self.Categories:setSystemUpdateAvailable(self.HWSettingsSystemUpdate:hasUpdates())

    end

    SettingsTab.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
