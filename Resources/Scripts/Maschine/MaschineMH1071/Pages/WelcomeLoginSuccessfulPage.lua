------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeLoginSuccessfulPage = class( 'WelcomeLoginSuccessfulPage', PageMaschine )

local PAGE_COUNT_DOWN = 200

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeLoginSuccessfulPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.ButtonBarLeft:setActive(false)
    self.ButtonBarRight:setActive(false)

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)

    self.Icon = NI.GUI.insertBar(self.Screen.ScreenRight, "Icon")
    self.Icon:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Label = NI.GUI.insertMultilineLabel(self.Screen.ScreenRight, "Label")
    self.Label:style("")

    self.Screen.ScreenRight:setFlex(self.Label)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:onShow(Show)

    if Show then

        self.PageCountdown = PAGE_COUNT_DOWN

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:onControllerTimer()

    if self.PageCountdown > 0 then

        self.PageCountdown = self.PageCountdown - 1

        if self.PageCountdown == 0 then

            NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_WELCOME_CONFIRM_ACTIVATION)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeLoginSuccessfulPage:updateScreens(ForceUpdate)

    if ForceUpdate then

        local Username = App:getActivationManager():getLoggedUsername()
        if Username ~= "" then

            self.Label:setText("Successfully logged in as\n"..Username)

        else

            self.Label:setText("Successfully logged in")

        end

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
