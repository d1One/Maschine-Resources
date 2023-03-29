------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

local ATTR_FIRST_BOOT = NI.UTILS.Symbol("first-boot")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoginPage = class( 'LoginPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function LoginPage:__init(Controller)

    PageMaschine.__init(self, "LoginPage", Controller)

    self.HasWiFiCapabilities = NI.DATA.NetworkAccess.hasWiFiDevice()

    self.onLoginSuccessfulFunction =
        function()
            if NI.UTILS.NativeOSHelpers.isFirstBoot() then
                NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_WELCOME_LOGIN_SUCCESSFUL)
            else
                NHLController:getPageStack():popPage()
            end
        end

    self.onLoginCanceledFunction =
        function()
            if NI.UTILS.NativeOSHelpers.isFirstBoot() then
                NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_WELCOME_CONNECT_TO_WIFI)
            else
                NHLController:getPageStack():popPage()
            end
        end

    App:getActivationManager():setAuth0LoginSuccessfulCallback(self.onLoginSuccessfulFunction)
    App:getActivationManager():setLoginCanceledCallback(self.onLoginCanceledFunction)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", "ENTER ID"}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"CANCEL", "", "", "REFRESH"}, "HeadButton")

    self.ImageBarLeft = NI.GUI.insertBar(self.Screen.ScreenLeft, "LeftImage")
    self.ImageBarLeft:style(NI.GUI.ALIGN_WIDGET_DOWN, "LeftImage")

    self.IconBarRight = NI.GUI.insertBar(self.Screen.ScreenRight, "RightIcons")
    self.IconBarRight:style(NI.GUI.ALIGN_WIDGET_RIGHT, "RightIcons")
    self.QRCodeBar = NI.GUI.insertPictureBar(self.IconBarRight, "QRCodeIcon")
    self.QRCodeBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "QRCodeIcon")
    local ArrowIcon = NI.GUI.insertBar(self.IconBarRight, "ArrowIcon")
    ArrowIcon:style(NI.GUI.ALIGN_WIDGET_DOWN, "ArrowIcon")
    self.Auth0CodeFrameIcon = NI.GUI.insertBar(self.IconBarRight, "FrameIcon")
    self.Auth0CodeFrameIcon:style(NI.GUI.ALIGN_WIDGET_DOWN, "FrameIcon")
    self.Auth0CodeLabel = NI.GUI.insertLabel(self.IconBarRight, "Auth0Code")
    self.Auth0CodeLabel:style("", "Auth0Code")

    self.LoadingLabel = NI.GUI.insertLabel(self.Screen.ScreenRight, "LoadingLabel")
    self.LoadingLabel:style("", "LoadingLabel")

    self.LabelBarRight = NI.GUI.insertBar(self.Screen.ScreenRight, "RightLabels")
    self.LabelBarRight:style(NI.GUI.ALIGN_WIDGET_RIGHT, "RightLabels")
    self.Auth0URLLabel = NI.GUI.insertLabel(self.LabelBarRight, "Auth0URL")
    self.Auth0URLLabel:style("", "Auth0URL")
    self.CodeInputLabel = NI.GUI.insertLabel(self.LabelBarRight, "CodeInput")
    self.CodeInputLabel:style("", "CodeInput")

    self.LoadingLabel:setText("Loading...")

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:updateScreens(ForceUpdate)

    if App:getActivationManager():isAuth0UserCodeReceived() then

        local UserCodeURL = App:getActivationManager():getAuth0UserCodeURL()
        local UserCode = App:getActivationManager():getAuth0UserCode()

        self.QRCodeBar:setPicture(App:getActivationManager():getAuth0QrCodePicture())
        self.QRCodeBar:setAlign()

        self.Auth0CodeLabel:setText(UserCode)
        self.Auth0URLLabel:setText("Visit "..UserCodeURL)
        self.CodeInputLabel:setText("Enter and confirm your code")

        self.IconBarRight:setActive(true)
        self.LabelBarRight:setActive(true)
        self.LoadingLabel:setActive(false)

    else

        self.IconBarRight:setActive(false)
        self.LabelBarRight:setActive(false)
        self.LoadingLabel:setActive(true)

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[4]:setEnabled(true)
    self.Screen.ScreenButton[4]:setVisible(true)
    self.Screen.ScreenButton[4]:setText("ENTER ID")

    self.Screen.ScreenButton[5]:setEnabled(true)
    self.Screen.ScreenButton[5]:setVisible(true)
    self.Screen.ScreenButton[5]:setText("CANCEL")

    self.Screen.ScreenButton[8]:setEnabled(true)
    self.Screen.ScreenButton[8]:setVisible(true)
    self.Screen.ScreenButton[8]:setText("REFRESH")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:onShow(Show)

    if Show then

        self.ImageBarLeft:setAttribute(ATTR_FIRST_BOOT, tostring(NI.UTILS.NativeOSHelpers.isFirstBoot()))

        self.Auth0CodeLabel:setText("")
        self.Auth0URLLabel:setText("")
        self.CodeInputLabel:setText("")
        App:getActivationManager():startAuth0Login()

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function LoginPage:onScreenButton(Index, Pressed)

    if Pressed and Index == 4 then

        App:getActivationManager():cancelNtkTasks()

        if App:getActivationManager():loginWithCredentials() then

            self:onLoginSuccessfulFunction()

        end

    elseif Pressed and Index == 5 then

        App:getActivationManager():cancelNtkTasks()
        self:onLoginCanceledFunction()

    elseif Pressed and Index == 8 then

        App:getActivationManager():startAuth0Login()

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
