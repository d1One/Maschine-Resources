------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LedController = class( 'LedController' )

------------------------------------------------------------------------------------------------------------------------

function LedController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function LedController:resetAllLEDs()

    NHLController:resetAllLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function LedController:turnOffLEDs(Leds)

    LEDHelper.turnOffLEDs(Leds)

end

------------------------------------------------------------------------------------------------------------------------

function LedController:turnOffLEDs(Leds)

    LEDHelper.turnOffLEDs(Leds)

end

------------------------------------------------------------------------------------------------------------------------

function LedController:setLEDState(LedID, LedState, ColorIndex)

    LEDHelper.setLEDState(LedID, LedState, ColorIndex)

end
