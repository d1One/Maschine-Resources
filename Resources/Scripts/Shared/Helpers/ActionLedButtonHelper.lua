local LedButtonState = require("Scripts/Shared/Helpers/LedButtonState")
local LedButtonStateHelper = require("Scripts/Shared/Helpers/LedButtonStateHelper")

------------------------------------------------------------------------------------------------------------------------

local State = LedButtonState

local StateNames = {
    [State.Unavailable] = "Unavailable",
    [State.Available] = "Available",
    [State.Pressed] = "Pressed",
}

------------------------------------------------------------------------------------------------------------------------

local ActionLedButtonHelper = {
    State = State
}

------------------------------------------------------------------------------------------------------------------------

function ActionLedButtonHelper.getStateText(StateValue)

    return StateNames[StateValue] and StateNames[StateValue] or "nil"

end

------------------------------------------------------------------------------------------------------------------------

function ActionLedButtonHelper.createButton(IsAvailablePredicate,
                                            LedLightingFunction,
                                            PressAction,
                                            OptionalReleaseAction,
                                            OptionalAccessibleAltTextFunc)

    if not IsAvailablePredicate then
        error ("No predicate supplied")
    end

    if not LedLightingFunction then
        error ("No Led lighting function supplied")
    end

    if not PressAction then
        error ("No press function supplied")
    end

    local Button = {}

    Button.LedButtonStateHandler = LedButtonStateHelper(
        State,
        IsAvailablePredicate
    )

    Button.onPressed = function (self, Pressed)

        if Pressed then
            if IsAvailablePredicate() then
                self.LedButtonStateHandler:onSwitchEvent(Pressed)
                PressAction()
                LedLightingFunction(self.LedButtonStateHandler:updateLedState())
                self.WasPressActionInvoked = true
            elseif OptionalAccessibleAltTextFunc then
                OptionalAccessibleAltTextFunc()
            else
                self.WasPressActionInvoked = false
            end
        else
            self.LedButtonStateHandler:onSwitchEvent(Pressed)
            if self.WasPressActionInvoked then
                LedLightingFunction(self.LedButtonStateHandler:updateLedState())
                if OptionalReleaseAction then
                    OptionalReleaseAction()
                end
            end
        end

    end

    Button.updateLed = function (self)

        LedLightingFunction(self.LedButtonStateHandler:updateLedState())

    end

    return Button

end

------------------------------------------------------------------------------------------------------------------------

return ActionLedButtonHelper
