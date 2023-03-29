------------------------------------------------------------------------------------------------------------------------
-- Controls when to show games
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GamesHelper = class( 'GamesHelper' )

------------------------------------------------------------------------------------------------------------------------

GamesHelper.SNAKE_CODE = {
    NI.HW.LED_DPAD_UP,
    NI.HW.LED_DPAD_UP,
    NI.HW.LED_DPAD_DOWN,
    NI.HW.LED_DPAD_DOWN,
    NI.HW.BUTTON_DPAD_LEFT,
    NI.HW.BUTTON_DPAD_RIGHT,
    NI.HW.BUTTON_DPAD_LEFT,
    NI.HW.BUTTON_DPAD_RIGHT,
    NI.HW.LED_GROUP_B,
    NI.HW.LED_GROUP_A,
    NI.HW.BUTTON_PLAY
}

------------------------------------------------------------------------------------------------------------------------

function GamesHelper:__init()

    -- table with a history of pressed switches, reset every PreviouslyPressedDelay ticks
    self.PreviouslyPressedSwitches = {}
    self.PreviouslyPressedDelay = 400
    self.PreviouslyPressedCounter = self.PreviouslyPressedDelay

end

------------------------------------------------------------------------------------------------------------------------

function GamesHelper:onTimer()

    if self.PreviouslyPressedCounter <= 0 then
        self.PreviouslyPressedSwitches = {}
        self.PreviouslyPressedCounter = self.PreviouslyPressedDelay
    else
        self.PreviouslyPressedCounter = self.PreviouslyPressedCounter - 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function GamesHelper:checkForSecretCodes(SwitchID, Pressed)

    local Handler = nil

    if Pressed then

        self.PreviouslyPressedSwitches[#self.PreviouslyPressedSwitches + 1] = SwitchID

        for i, v1 in ipairs(self.PreviouslyPressedSwitches) do

            local v2 = self.SNAKE_CODE[i]

            if v2 ~= v1 then
                self.PreviouslyPressedSwitches = {}
                self.PreviouslyPressedCounter = self.PreviouslyPressedDelay
                break
            elseif i == #self.SNAKE_CODE and v2 == v1 then
                self.PreviouslyPressedSwitches = {}
                self.PreviouslyPressedCounter = self.PreviouslyPressedDelay
                Handler = NHLController:getPageStack():pushPage(NI.HW.PAGE_SNAKE)
            end

        end

    end

    return Handler

end
