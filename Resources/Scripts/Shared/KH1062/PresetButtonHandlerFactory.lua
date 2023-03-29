local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")

local ActionLedButtonHelper = require("Scripts/Shared/Helpers/ActionLedButtonHelper")

------------------------------------------------------------------------------------------------------------------------

local PresetButtonHandlerFactory = {}

------------------------------------------------------------------------------------------------------------------------

function PresetButtonHandlerFactory.createHandler(LedID, PresetChangeFunc, PresetAvailableFunc, Environment)

    return ActionLedButtonHelper.createButton(

        PresetAvailableFunc,

        function (ActiveState)
            Environment.LedController:setLEDState(LedID, ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,

        function ()
            PresetChangeFunc()
        end
    )

end

------------------------------------------------------------------------------------------------------------------------

return PresetButtonHandlerFactory