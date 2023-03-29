local class = require 'Scripts/Shared/Helpers/classy'
TimerHelper = class( 'TimerHelper' )

------------------------------------------------------------------------------------------------------------------------

function TimerHelper.convertSecondsToTimerTicks(Seconds)

    -- despite setMasterTimerTimeout requesting a higher rate in the C++, the timer rate seems to be limited
    -- by the OS event loop
    local ThrottledTimerRate = 25

    return math.floor(Seconds * ThrottledTimerRate)

end

