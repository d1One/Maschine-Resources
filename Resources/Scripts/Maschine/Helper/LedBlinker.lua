------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LEDBlinker = class( 'LEDBlinker' )

LEDBlinker.DEFAULT_BLINK_TIME = 6 -- number of each time getBlinkStateTick() is called; normally on every timer tick

------------------------------------------------------------------------------------------------------------------------

function LEDBlinker:__init(BlinkTime)

    self.BlinkCtr  = 0
    self.BlinkTime = BlinkTime ~= nil and BlinkTime or LEDBlinker.DEFAULT_BLINK_TIME

end

-----------------------------------------------------------------------------------------------------------------------

function LEDBlinker:reset()

    self.BlinkCtr = 0

end

-----------------------------------------------------------------------------------------------------------------------
-- Should be called on every timer tick

function LEDBlinker:getBlinkStateTick()

    self.BlinkCtr = math.wrap(self.BlinkCtr + 1, -self.BlinkTime, self.BlinkTime)
    return (self.BlinkCtr < 0) and LEDHelper.LS_DIM or LEDHelper.LS_BRIGHT

end

-----------------------------------------------------------------------------------------------------------------------

function LEDBlinker:tick()

    self.BlinkCtr = math.wrap(self.BlinkCtr + 1, -self.BlinkTime, self.BlinkTime)

end

-----------------------------------------------------------------------------------------------------------------------

function LEDBlinker:getBlinkStateNoTick()

    return (self.BlinkCtr < 0) and LEDHelper.LS_DIM or LEDHelper.LS_BRIGHT

end

-----------------------------------------------------------------------------------------------------------------------
