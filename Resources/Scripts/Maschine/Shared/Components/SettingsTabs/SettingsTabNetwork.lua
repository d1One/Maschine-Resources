------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Shared/Components/SettingsTabs/SettingsTab"
require "Scripts/Maschine/Helper/SettingsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTabNetwork = class( 'SettingsTabNetwork', SettingsTab )

local BUTTON_INDEX_REFRESH = 7
local BUTTON_INDEX_CONNECT_DISCONNECT = 8

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:__init()

    SettingsTab.__init(self, NI.HW.SETTINGS_NETWORK, "NETWORK", SettingsTab.NO_PARAMETER_BAR)

    self.HasWiFiCapabilities = NI.DATA.NetworkAccess.hasWiFiDevice()

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:addContextualBar(ContextualStack)

    local TwoColumns = NI.GUI.insertBar(ContextualStack, "TwoColumns")
    TwoColumns:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    local FirstColumn = NI.GUI.insertBar(TwoColumns, "LeftContainer")
    FirstColumn:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    local BigIconNetwork = NI.GUI.insertBar(FirstColumn, "BigIconNetwork")
    BigIconNetwork:style(NI.GUI.ALIGN_WIDGET_DOWN, "SettingsBigIcon")
    self.WiFiStatusLabel = NI.GUI.insertLabel(FirstColumn, "WiFiStatus")
    self.WiFiStatusLabel:style("", "")

    local SecondColumn = NI.GUI.insertBar(TwoColumns, "RightContainer")
    SecondColumn:style(NI.GUI.ALIGN_WIDGET_LEFT, "")
    self.WiFiList = NI.GUI.insertWiFiList(SecondColumn, App, "WiFiList")
    local Space = NI.GUI.insertBar(SecondColumn, "Space")
    SecondColumn:setFlex(Space)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:updateScreens(ForceUpdate)

    local Workspace = App:getWorkspace()
    local AirplaneModeParameter = Workspace and Workspace:getAirplaneModeParameter()
    local WiFiStatusParameter = Workspace and Workspace:getWiFiStatusParameter()
    local AirplaneModeChanged = AirplaneModeParameter and AirplaneModeParameter:isChanged() or false
    local WiFiStatusChanged = WiFiStatusParameter and WiFiStatusParameter:isChanged() or false

    if ForceUpdate or WiFiStatusChanged or AirplaneModeChanged then

        if AirplaneModeParameter:getValue() then

            self.WiFiStatusLabel:setText("Airplane Mode")

        elseif WiFiStatusParameter:getValue() == NI.DATA.WIFI_STATUS_CONNECTED then

            self.WiFiStatusLabel:setText("Connected")

        elseif WiFiStatusParameter:getValue() == NI.DATA.WIFI_STATUS_CONNECTING then

            self.WiFiStatusLabel:setText("Connecting")

        elseif WiFiStatusParameter:getValue() == NI.DATA.WIFI_STATUS_NOT_CONNECTED then

            self.WiFiStatusLabel:setText("Not Connected")

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 1
    local Workspace = App:getWorkspace()
    local AirplaneModeParameter = Workspace and Workspace:getAirplaneModeParameter()

    local Params =
    {
        AirplaneModeParameter
    }

    ParameterHandler:setParameters(Params)
    ParameterHandler:setCustomSections({ "Airplane Mode" })
    Controller.CapacitiveList:assignParametersToCaps(Params)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:updateScreenButton(Index, ScreenButton)

    local IsVisible = false
    local IsEnabled = false
    local IsSelected = false
    local IsFocused = false
    local ButtonText = ""
    local Style = "HeadButton"

    local Workspace = App:getWorkspace()

    local AirplaneModeParameter = Workspace and Workspace:getAirplaneModeParameter()
    local AirplaneModeChanged = AirplaneModeParameter and AirplaneModeParameter:isChanged() or false
    local AirplaneMode = AirplaneModeParameter and AirplaneModeParameter:getValue() or false

    local WiFiStatusParameter = Workspace and Workspace:getWiFiStatusParameter()
    local WiFiStatusChanged = WiFiStatusParameter and WiFiStatusParameter:isChanged() or false
    local WiFiStatus = WiFiStatusParameter and WiFiStatusParameter:getValue() or NI.DATA.WIFI_STATUS_NOT_CONNECTED

    if Index == BUTTON_INDEX_REFRESH then

        IsVisible = true
        IsEnabled = self.HasWiFiCapabilities and not AirplaneMode and WiFiStatus ~= NI.DATA.WIFI_STATUS_CONNECTING
        ButtonText = "REFRESH"

    elseif Index == BUTTON_INDEX_CONNECT_DISCONNECT then

        IsVisible = true
        IsEnabled = self.HasWiFiCapabilities and not AirplaneMode
                    and NI.DATA.NetworkAccess.getNumberOfVisibleWiFiNetworks() > 0
                    and WiFiStatus ~= NI.DATA.WIFI_STATUS_CONNECTING
        ButtonText = SettingsHelper.isOverConnectedWiFi(self.WiFiList) and "DISCONNECT" or "CONNECT"

    end

    ScreenHelper.updateButton(ScreenButton, IsVisible, IsEnabled, IsSelected, IsFocused, ButtonText, Style)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:onScreenEncoder(Index, Value, Controller, ParameterHandler)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Page = ParameterHandler.PageIndex
    local Next = Value > 0

    if not EncoderSmoothed then

        return

    end

    if Index == 8 then

        self.WiFiList:selectPrevNextItem(Next)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:onScreenButton(Index, Pressed)

    if Pressed and Index == BUTTON_INDEX_REFRESH then

        self.WiFiList:refreshWiFiNetworks()

    elseif Pressed and Index == BUTTON_INDEX_CONNECT_DISCONNECT then

        if SettingsHelper.isOverConnectedWiFi(self.WiFiList) then

            NI.DATA.NetworkAccess.disconnectWiFi()

        else

            self.WiFiList:connectToSelectedWiFi()

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:onWheel(Inc)

    self.WiFiList:selectPrevNextItem(Inc > 0)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTabNetwork:onWheelButton(Pressed)

    if Pressed then

        if SettingsHelper.isOverConnectedWiFi(self.WiFiList) then

            NI.DATA.NetworkAccess.disconnectWiFi()

        else

            self.WiFiList:connectToSelectedWiFi()

        end
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
