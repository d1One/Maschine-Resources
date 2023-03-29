------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabAbout = class( 'SettingsTabAbout', SettingsTab )

local SCROLLING_SPEED_FACTOR = 200
local BUTTON_INDEX_LICENSES = 7
local BUTTON_INDEX_CREDITS = 8
local ENCODER_TOGGLE_DATA_TRACKING = 1
local ENCODER_SCROLL_CREDITS = 8

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:__init(ControllerType)

    SettingsTab.__init(self, NI.HW.SETTINGS_ABOUT, "ABOUT", SettingsTab.NO_PARAMETER_BAR)
    self.ControllerType = ControllerType
    self.DisplayCredits = false

    self.ScreenButtonUpdateFunctor = self

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:addContextualBar(ContextualStack)

    local Container = NI.GUI.insertBar(ContextualStack, "AboutContainer")
    Container:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    local AboutTabRightInfoBar = NI.GUI.insertBar(Container, "AboutTabRightInfoBar")
    AboutTabRightInfoBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.Logo = NI.GUI.insertBar(Container, "AboutLogo")
    self.Logo:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")
    self.Copyright = NI.GUI.insertLabel(Container, "Copyright")
    self.Copyright:style("© 2020 NATIVE INSTRUMENTS GmbH. All rights reserved", "")
    self.MadeInBerlin = NI.GUI.insertLabel(Container, "MadeInBerlin")
    self.MadeInBerlin:style("Made in Berlin", "")
    self.VersionsDisplay = NI.GUI.insertVersionsDisplay(Container, App, self.ControllerType, "VersionsDisplay")
    self.Credits = NI.GUI.insertCredits(Container, "Credits")

    Container:setFlex(self.Credits)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:updateScreens(ForceUpdate)

    self.Copyright:setActive(self.DisplayCredits)
    self.MadeInBerlin:setActive(self.DisplayCredits)
    self.VersionsDisplay:setActive(not self.DisplayCredits)
    self.Credits:setActive(self.DisplayCredits)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 1

    local Sections = { "Usage Data" }
    local Names = { "TRACK" }

    local Values = {}
    Values[1] = NI.DATA.Mixpanel.isMixpanelEnabled() and "On" or "Off"

    ParameterHandler:setParameters({})
    ParameterHandler:setCustomNames(Names)
    ParameterHandler:setCustomValues(Values)
    ParameterHandler:setCustomSections(Sections)
    Controller.CapacitiveList:assignListsToCaps({}, {}, {})

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:updateScreenButton(Index, ScreenButton)

    local IsVisible = false
    local IsEnabled = false
    local IsSelected = false
    local IsFocused = false
    local ButtonText = ""
    local Style = "HeadButton"

    if Index == BUTTON_INDEX_LICENSES then

        IsVisible = true
        IsEnabled = true
        ButtonText = "LICENSES"

    elseif Index == BUTTON_INDEX_CREDITS then

        IsVisible = true
        IsEnabled = true
        IsSelected = self.DisplayCredits
        ButtonText = "CREDITS"

    end

    ScreenHelper.updateButton(ScreenButton, IsVisible, IsEnabled, IsSelected, IsFocused, ButtonText, Style)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:onShow(Show)

    if Show then

        self.DisplayCredits = false

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:onScreenButton(Index, Pressed)

    if Pressed and Index == BUTTON_INDEX_LICENSES then

        NI.GUI.DialogAccess.openLegalLicensesDialog(App)

    elseif Pressed and Index == BUTTON_INDEX_CREDITS then

        self.DisplayCredits = not self.DisplayCredits

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabAbout:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if Index == ENCODER_TOGGLE_DATA_TRACKING and EncoderSmoothed then

        NI.DATA.Mixpanel.setMixpanelEnabled(App, Next)

    elseif Index == ENCODER_SCROLL_CREDITS and self.DisplayCredits then

        self.Credits:getScrollbar():addValue(Value * SCROLLING_SPEED_FACTOR)

    end

    self:updateParameters(Controller, ParameterHandler)

end

------------------------------------------------------------------------------------------------------------------------
