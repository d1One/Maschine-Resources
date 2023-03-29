------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WelcomeSplashPage = class( 'WelcomeSplashPage', PageMaschine )

local BUTTON_INDEX_NEXT = 8

------------------------------------------------------------------------------------------------------------------------

function WelcomeSplashPage:__init(Controller)

    PageMaschine.__init(self, "WelcomeSplashPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeSplashPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeSplashPage:setupScreen()

    self.Screen = ScreenMaschineStudio(self)

    self.ButtonBarLeft = self.Screen:addScreenButtonBar(self.Screen.ScreenLeft, {"", "", "", ""}, "HeadButton")
    self.ButtonBarRight = self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"", "", "", ""}, "HeadButton")

    self.Screen.ScreenLeft.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "StudioDisplayBar")
    self.Screen.ScreenRight.DisplayBar = NI.GUI.insertBar(self.Screen.ScreenRight, "StudioDisplayBar")

    self.Screen.ScreenLeft.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")
    self.Screen.ScreenRight.DisplayBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "")

    self.Screen.ScreenLeft:setFlex(self.Screen.ScreenLeft.DisplayBar)
    self.Screen.ScreenRight:setFlex(self.Screen.ScreenRight.DisplayBar)

    self.ButtonBarLeft:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeSplashPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setEnabled(true)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setVisible(true)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setSelected(false)
    self.Screen.ScreenButton[BUTTON_INDEX_NEXT]:setText("NEXT")

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function WelcomeSplashPage:onScreenButton(Index, Pressed)

    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == BUTTON_INDEX_NEXT then

        NHLController:getPageStack():replaceBottomPage(NI.HW.PAGE_WELCOME_CONNECT_TO_WIFI)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
