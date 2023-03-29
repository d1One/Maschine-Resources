require "Scripts/Maschine/Components/Pages/LoopPageColorDisplayBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LoopPageMK3 = class( 'LoopPageMK3', LoopPageColorDisplayBase )

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:__init(Controller)

    LoopPageColorDisplayBase.__init(self, "LoopPageMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:updateWheelButtonLEDs()

    LEDHelper.resetButtonLEDs({ NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.LED_WHEEL_BUTTON_DOWN })

    local Color = LEDColors.WHITE
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, true, Color)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, true, Color)

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:onWheelDirection(Pressed, DirectionButton)

    LoopPageColorDisplayBase.onWheelDirection(Pressed, DirectionButton)

    self:updateWheelButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:onWheel(Inc)

    if self.Controller.SwitchPressed[NI.HW.BUTTON_WHEEL] then
        NI.DATA.TransportAccess.moveLoopEndFromHW(App, Inc)
        return true -- handled
    end

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:getAccessiblePageInfo()

    return "Loop Page"

end

------------------------------------------------------------------------------------------------------------------------

function LoopPageMK3:getAccessibleTextByPadIndex(PadIdx)

    local AllowCreatingSections = false
    return ArrangerHelper.getAccessibleSectionNameByPadIndex(PadIdx, AllowCreatingSections)

end

------------------------------------------------------------------------------------------------------------------------
