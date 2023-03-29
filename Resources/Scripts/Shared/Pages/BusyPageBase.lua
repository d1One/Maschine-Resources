------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Components/ScreenMaschine"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
BusyPageBase = class( 'BusyPageBase', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:__init(Controller, Page)

    PageMaschine.__init(self, Page, Controller)

    self.RightLabels = {}
    self.LeftLabels = {}

    -- setup screen
    self:setupScreen()

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:setupScreen()

    self.Screen = ScreenMaschine(self)

    ScreenHelper.createBarWithLabels(self.Screen.ScreenLeft, self.LeftLabels, {"Busy ... "}, "HalfPage", "BusyLabel")
    ScreenHelper.createBarWithLabels(self.Screen.ScreenRight, self.RightLabels, {"See Software"}, "HalfPage", "BusyLabel")

end


------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:setMessage(LeftMessage, RightMessage)

    self.LeftText = LeftMessage
    self.RightText = RightMessage
    self.LeftLabels[1]:setText(LeftMessage)
    self.RightLabels[1]:setText(RightMessage)

end


------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:onShow(Show)

    -- call base class
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
-- event handling
------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:onPadEvent(PadIndex, Trigger, PadValue)
end


------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:onScreenEncoder(KnobIdx, EncoderInc)
end


------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:onWheel(Value)
end


------------------------------------------------------------------------------------------------------------------------

function BusyPageBase:onScreenButton(Idx, Pressed)
end


------------------------------------------------------------------------------------------------------------------------
