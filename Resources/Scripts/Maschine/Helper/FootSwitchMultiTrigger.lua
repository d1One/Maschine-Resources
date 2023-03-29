------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
FootSwitchMultiTrigger = class( 'FootSwitchMultiTrigger' )

FootSwitchMultiTrigger.DEFAULT_DOUBLE_TIMEOUT = 15
FootSwitchMultiTrigger.DEFAULT_HOLD_TIMEOUT = 30

------------------------------------------------------------------------------------------------------------------------

function FootSwitchMultiTrigger:__init(SingleHandler, DoubleHandler, HoldHandler)

    self.SingleHandler = SingleHandler
    self.DoubleHandler = DoubleHandler
    self.HoldHandler = HoldHandler

    self.DoubleTimeout = FootSwitchMultiTrigger.DEFAULT_DOUBLE_TIMEOUT
    self.HoldTimeout = FootSwitchMultiTrigger.DEFAULT_HOLD_TIMEOUT

    self.Counter = nil
    self.Pressed = false

end

------------------------------------------------------------------------------------------------------------------------

function FootSwitchMultiTrigger:press()

    if self.Counter == nil then
        self.Counter = 0
    else
        if self.DoubleHandler ~= nil then
            self.DoubleHandler()
        end
        self:reset()
    end

    self.Pressed = true

end

------------------------------------------------------------------------------------------------------------------------

function FootSwitchMultiTrigger:release()

    if self.Counter ~= nil then
        self.Counter = 0
    end

    self.Pressed = false

end

------------------------------------------------------------------------------------------------------------------------

function FootSwitchMultiTrigger:reset()

    self.Counter = nil
    self.Pressed = false

end

------------------------------------------------------------------------------------------------------------------------

function FootSwitchMultiTrigger:tick()

    if self.Counter == nil then
        return
    end

    self.Counter = self.Counter + 1

    if self.Counter >= self.DoubleTimeout and not self.Pressed then
        self:reset()
        if self.SingleHandler ~= nil then
            self.SingleHandler()
        end
    elseif self.Counter >= self.HoldTimeout and self.Pressed then
        self:reset()
        if self.HoldHandler ~= nil then
            self.HoldHandler()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------
