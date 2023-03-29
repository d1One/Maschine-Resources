local LedButtonState = require("Scripts/Shared/Helpers/LedButtonState")

require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local ButtonHelper = {}

function ButtonHelper.getLedStateFromActiveState(ActiveState)

    local LedButtonStateTypes = {
        [LedButtonState.Pressed] = LEDHelper.LS_BRIGHT,
        [LedButtonState.Available] = LEDHelper.LS_DIM,
        [LedButtonState.Unavailable] = LEDHelper.LS_OFF
    }
    return LedButtonStateTypes[ActiveState]

end

return ButtonHelper
