------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MH1071LoadingPage = class( 'MH1071LoadingPage', PageMaschine )

local BUTTON_INDEX_NEXT = 8

------------------------------------------------------------------------------------------------------------------------

function MH1071LoadingPage:__init(Controller)

    PageMaschine.__init(self, "MH1071LoadingPage", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function MH1071LoadingPage:setPinned()

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function MH1071LoadingPage:setupScreen()

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
    self.ButtonBarRight:setActive(false)

end

------------------------------------------------------------------------------------------------------------------------

function MH1071LoadingPage:onShow(Show)

    PageMaschine.onShow(self, Show)

    if Show then

        if self.Controller.turnOffAllPageLEDs then
            self.Controller:turnOffAllPageLEDs()
            LEDHelper.turnOffLEDs(HardwareControllerBase.SCREEN_BUTTON_LEDS)
        else
            NHLController:resetAllLEDs()
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
