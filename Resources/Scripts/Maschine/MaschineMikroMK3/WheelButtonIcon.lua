------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
WheelButtonIcon = class( 'WheelButtonIcon' )

------------------------------------------------------------------------------------------------------------------------

function WheelButtonIcon:__init(Page)

    self.Page = Page

end

------------------------------------------------------------------------------------------------------------------------

function WheelButtonIcon:onControllerTimer()

    local isWheelPressed = self.Page.Controller:isButtonPressed(NI.HW.BUTTON_WHEEL)
    self.Page.Screen:setBottomRowIcon(isWheelPressed and "button_pressed" or "button_unpressed")

end

------------------------------------------------------------------------------------------------------------------------
