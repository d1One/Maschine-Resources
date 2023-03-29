local LedButtonState = require("Scripts/Shared/Helpers/LedButtonState")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ToggleLedButton = class( 'ToggleLedButton' )

function ToggleLedButton:__init(GetStateFn, SetStateFn, LedLightingFunction, OptionalIsAvailableFn)

    self.GetStateFn = GetStateFn
    self.SetStateFn = SetStateFn
    self.LedLightingFunction = LedLightingFunction
    self.IsAvailableFn = OptionalIsAvailableFn or function() return true end

end

------------------------------------------------------------------------------------------------------------------------

function ToggleLedButton:getLedState()

    return self.IsAvailableFn()
            and (self.GetStateFn() and LedButtonState.Pressed or LedButtonState.Available)
            or LedButtonState.Unavailable

end

------------------------------------------------------------------------------------------------------------------------

function ToggleLedButton:onToggleButton()

    if self.IsAvailableFn() then
        self.SetStateFn(not self.GetStateFn())
        self:updateLed()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ToggleLedButton:updateLed()

    self.LedLightingFunction(self:getLedState())

end
