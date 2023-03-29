------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Helper/SettingsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeConnectToWiFiPage = class( 'WelcomeConnectToWiFiPage', PageMaschine )

local BUTTON_INDEX_REFRESH = 7
local BUTTON_INDEX_CONNECT = 8

local ENCODER_INDEX_SCROLL = 8

------------------------------------------------------------------------------------------------------------------------

local function getWiFiStatus()
    return App:getWorkspace():getWiFiStatusParameter():getValue()
end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeConnectToWiFiPage", Controller)

    self.HasWiFiCapabilities = NI.DATA.NetworkAccess.hasWiFiDevice()
    self.WiFiStatus = getWiFiStatus()
    self.FirstTimeShown = true

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")
    self.ButtonBarLeft:setActive(false)

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_RIGHT, "")

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    local WiFiStatusContainer = NI.GUI.insertBar(self.Screen.ScreenRight.DisplayBar, "WiFiStatusContainer")
    WiFiStatusContainer:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.WiFiStatusLabel = NI.GUI.insertLabel(WiFiStatusContainer, "WiFiStatus")
    self.WiFiStatusLabel:style("", "")
    WiFiStatusContainer:setFlex(self.WiFiStatusLabel)

    local WiFiListContainer = NI.GUI.insertBar(self.Screen.ScreenRight.DisplayBar, "WiFiListContainer")
    WiFiListContainer:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.WiFiList = NI.GUI.insertWiFiList(WiFiListContainer, App, "WiFiList")
    WiFiListContainer:setFlex(self.WiFiList)

end
------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onShow(Show)

    if Show then
        self.Controller:setTimer(self, 1)
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onTimer()

    local CurrentWiFiStatus = getWiFiStatus()
    local WiFiStatusChanged = self.WiFiStatus ~= CurrentWiFiStatus

    self.WiFiStatus = CurrentWiFiStatus

    if (self.FirstTimeShown or WiFiStatusChanged)
            and self.WiFiStatus == NI.DATA.WIFI_STATUS_CONNECTED then
        self.FirstTimeShown = false
        NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_LOGIN)
    end

    if self.IsVisible then
        self.Controller:setTimer(self, 1)
    end
end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:updateScreens(ForceUpdate)

    -- due to the timer not updating at a fast enough pace, we need to query the status instead of checking
    -- the global self.WiFiStatus variable, otherwise we'll display "Not Connected" instead of "Connecting"
    local WiFiStatus = getWiFiStatus()

    if WiFiStatus == NI.DATA.WIFI_STATUS_CONNECTED then
        self.WiFiStatusLabel:setText("Connected")

    elseif WiFiStatus == NI.DATA.WIFI_STATUS_CONNECTING then
        self.WiFiStatusLabel:setText("Connecting")

    elseif WiFiStatus == NI.DATA.WIFI_STATUS_NOT_CONNECTED then
        self.WiFiStatusLabel:setText("Not Connected")

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:updateScreenButtons(ForceUpdate)

    -- due to the timer not updating at a fast enough pace, we need to query the status instead of checking
    -- the global self.WiFiStatus variable, otherwise REFRESH will still be active when it shouldn't be
    local WiFiStatus = getWiFiStatus()

    local IsShiftPressed = self.Controller:getShiftPressed()

    self.Screen.ScreenButton[BUTTON_INDEX_REFRESH]:setEnabled(not IsShiftPressed and self.HasWiFiCapabilities
        and WiFiStatus ~= NI.DATA.WIFI_STATUS_CONNECTING)
    self.Screen.ScreenButton[BUTTON_INDEX_REFRESH]:setVisible(not IsShiftPressed)
    self.Screen.ScreenButton[BUTTON_INDEX_REFRESH]:setText("REFRESH")

    if IsShiftPressed then
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setEnabled(true)
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setVisible(true)
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setText("SKIP")
    else
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setEnabled(self.HasWiFiCapabilities
            and NI.DATA.NetworkAccess.getNumberOfVisibleWiFiNetworks() > 0 and WiFiStatus ~= NI.DATA.WIFI_STATUS_CONNECTING)
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setVisible(true)
        self.Screen.ScreenButton[BUTTON_INDEX_CONNECT]:setText(SettingsHelper.isOverConnectedWiFi(self.WiFiList) and "DISCONNECT" or "CONNECT")
    end

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
    local Next = Value > 0

    if not EncoderSmoothed then

        return

    end

    if Index == ENCODER_INDEX_SCROLL then

        self.WiFiList:selectPrevNextItem(Next)

    end

    self:updateScreenButtons(false)

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onScreenButton(Index, Pressed)

    local IsEnabled = self.Screen.ScreenButton[Index]:isEnabled()
    local IsShiftPressed = self.Controller:getShiftPressed()

    if Pressed and Index == BUTTON_INDEX_REFRESH and IsEnabled then

        self.WiFiList:refreshWiFiNetworks()

    elseif Pressed and Index == BUTTON_INDEX_CONNECT and IsEnabled then

        if IsShiftPressed then

            NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_LOGIN)

        elseif SettingsHelper.isOverConnectedWiFi(self.WiFiList) then

            NI.DATA.NetworkAccess.disconnectWiFi()

        else

            self.WiFiList:connectToSelectedWiFi()

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onWheel(Inc)

    self.WiFiList:selectPrevNextItem(Inc > 0)
    self:updateScreenButtons(false)

    return true

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeConnectToWiFiPage:onWheelButton(Pressed)

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
