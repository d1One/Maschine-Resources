------------------------------------------------------------------------------------------------------------------------

local function updateLedState(LedButtonStateTypes, CurrentState, isButtonOperationAvailable)

    local AvailableState = isButtonOperationAvailable() and LedButtonStateTypes.Available or LedButtonStateTypes.Unavailable
    return {
        LedState = CurrentState.ButtonPressed and CurrentState.LedState or AvailableState,
        ButtonPressed = CurrentState.ButtonPressed
    }
end

------------------------------------------------------------------------------------------------------------------------

local function onSwitchEvent(LedButtonStateTypes, IsPressed, isButtonOperationAvailable)

    local PressedState = IsPressed and LedButtonStateTypes.Pressed or LedButtonStateTypes.Available
    return {
        LedState = isButtonOperationAvailable() and PressedState or LedButtonStateTypes.Unavailable,
        ButtonPressed = IsPressed
    }

end

------------------------------------------------------------------------------------------------------------------------

local function createLedButtonStateHandler(LedButtonStateTypes, isButtonOperationAvailable)

    local State = {
        LedState = LedButtonStateTypes.Unavailable,
        ButtonPressed = false
    }
    return {
        updateLedState = function ()
            State = updateLedState(
                LedButtonStateTypes,
                State,
                isButtonOperationAvailable
            )
            return State.LedState
        end,
        onSwitchEvent = function (self, IsPressed)
            State = onSwitchEvent(LedButtonStateTypes, IsPressed, isButtonOperationAvailable)
        end
    }

end

------------------------------------------------------------------------------------------------------------------------

return createLedButtonStateHandler