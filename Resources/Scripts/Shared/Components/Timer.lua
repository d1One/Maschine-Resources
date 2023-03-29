------------------------------------------------------------------------------------------------------------------------
-- Timer Class
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Timer = class( 'Timer' )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function Timer:__init()

	self.Timers = {}

end

------------------------------------------------------------------------------------------------------------------------
-- Timer
------------------------------------------------------------------------------------------------------------------------

function Timer:onControllerTimer()

    for Object in pairs(self.Timers) do

        -- update counter
        self.Timers[Object].Time = self.Timers[Object].Time - 1

        -- call onTimer
        if self.Timers[Object].Time == 0 then
            Object:onTimer(self.Timers[Object].Parameter)
        end

        -- remove Timer
        if self.Timers[Object] and self.Timers[Object].Time < 1 then
            self.Timers[Object] = nil
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Resets timer without calling callback function
------------------------------------------------------------------------------------------------------------------------

function Timer:resetTimer(Object)

    self.Timers[Object] = nil

end

------------------------------------------------------------------------------------------------------------------------

function Timer:isRunning(Object)

    return self.Timers[Object] ~= nil

end

------------------------------------------------------------------------------------------------------------------------

function Timer:setTimer(Object, CountDown, Param)

    if Object then

        if CountDown > 0  then
            self.Timers[Object] = {Time = CountDown, Parameter = Param}

        elseif CountDown == 0 then
            self.Timers[Object] = nil
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
