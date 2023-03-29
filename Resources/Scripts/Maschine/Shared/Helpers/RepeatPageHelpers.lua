require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
RepeatPageHelpers = class( 'RepeatPageHelpers' )

------------------------------------------------------------------------------------------------------------------------

RepeatPageHelpers.PARAM_BANK_BASIC = 1
RepeatPageHelpers.PARAM_BANK_ADVANCED = 2

------------------------------------------------------------------------------------------------------------------------

function RepeatPageHelpers.updateLeftRightLEDs(Page)

    if PadModeHelper.getKeyboardMode() then
        LEDHelper.updateButtonLED(Page.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT,
                                    Page.ParameterHandler.PageIndex == RepeatPageHelpers.PARAM_BANK_ADVANCED)
        LEDHelper.updateButtonLED(Page.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT,
                                    Page.ParameterHandler.PageIndex == RepeatPageHelpers.PARAM_BANK_BASIC)
    else
        LEDHelper.updateButtonLED(Page.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, false)
        LEDHelper.updateButtonLED(Page.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, false)
    end

end

------------------------------------------------------------------------------------------------------------------------
