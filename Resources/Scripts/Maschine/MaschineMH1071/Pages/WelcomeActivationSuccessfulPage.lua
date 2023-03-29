------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeActivationSuccessfulPage = class( 'WelcomeActivationSuccessfulPage', PageMaschine )

local PAGE_COUNT_DOWN = 200

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivationSuccessfulPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeActivationSuccessfulPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivationSuccessfulPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivationSuccessfulPage:setupScreen()

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

function WelcomeActivationSuccessfulPage:onShow(Show)

    if Show then

        self.PageCountdown = PAGE_COUNT_DOWN

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivationSuccessfulPage:onControllerTimer()

    if self.PageCountdown > 0 then

        self.PageCountdown = self.PageCountdown - 1

        if self.PageCountdown == 0 then

            NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_CONTROL)
            NI.GUI.DialogAccess.openLearnMaschineDialog(App)
            NI.DATA.FileAccess.load(App, NI.UTILS.NativeOSHelpers.welcomeProjectPath())
            self.Controller:onPadModeButton(NI.HW.BUTTON_PAD_MODE, true)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeActivationSuccessfulPage:updateScreens(ForceUpdate)

    if ForceUpdate then

        self.Label:setText("Your MASCHINE+ has been registered\nsuccessfully")

    end

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------
