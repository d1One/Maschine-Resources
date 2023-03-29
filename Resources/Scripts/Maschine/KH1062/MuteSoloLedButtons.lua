local ButtonHelper = require("Scripts/Shared/KH1062/ButtonHelper")
require "Scripts/Shared/Helpers/ToggleLedButton"

------------------------------------------------------------------------------------------------------------------------

local function attachSwitchHandler(SwitchEventTable, MuteLedButton, SoloLedButton)

    SwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_LEFT, Pressed = true },
                                function (_) MuteLedButton:onToggleButton() end)
    SwitchEventTable:setHandler({ Shift = true, Switch = NI.HW.BUTTON_RIGHT, Pressed = true },
                                function (_) SoloLedButton:onToggleButton() end)

end

------------------------------------------------------------------------------------------------------------------------

local function createMuteSoloSoundLedButtonsFunc(Environment, SwitchEventTable)

    local DataModel = Environment.DataModel
    local DataController = Environment.DataController

    local MuteLedButton = ToggleLedButton(

        function()
            return Environment.DataModel:isFocusSoundMuted()
        end,
        function(_)
            local SoundIndex = DataModel:getOneBasedFocusSoundIndex()
            if SoundIndex ~= NPOS then
                DataController:toggleFocusSoundMuteState(SoundIndex)
            end
        end,
        function (ActiveState)
            Environment.LedController:setLEDState(NI.HW.LED_LEFT,
                                                  ButtonHelper.getLedStateFromActiveState(ActiveState))
        end

    )

    local SoloLedButton = ToggleLedButton(

        function()
            return Environment.DataModel:isFocusSoundSoloed()
        end,
        function(_)
            local SoundIndex = DataModel:getOneBasedFocusSoundIndex()
            if SoundIndex ~= NPOS then
                DataController:toggleFocusSoundSoloState(SoundIndex)
            end
        end,
        function (ActiveState)
            Environment.LedController:setLEDState(NI.HW.LED_RIGHT,
                                                  ButtonHelper.getLedStateFromActiveState(ActiveState))
        end

    )

    attachSwitchHandler(SwitchEventTable, MuteLedButton, SoloLedButton)
    return MuteLedButton, SoloLedButton

end

------------------------------------------------------------------------------------------------------------------------

local function createMuteSoloGroupLedButtonsFunc(Environment, SwitchEventTable)

    local DataModel = Environment.DataModel
    local DataController = Environment.DataController

    local MuteLedButton = ToggleLedButton(

        function()
            return Environment.DataModel:isFocusGroupMuted()
        end,
        function(_)
            DataController:toggleFocusGroupMuteState()
        end,
        function (ActiveState)
            Environment.LedController:setLEDState(NI.HW.LED_LEFT,
                                                  ButtonHelper.getLedStateFromActiveState(ActiveState))
        end

    )

    local SoloLedButton = ToggleLedButton(

        function()
            return Environment.DataModel:isFocusGroupSoloed()
        end,
        function(_)
            DataController:toggleFocusGroupSoloState()
        end,
        function (ActiveState)
            Environment.LedController:setLEDState(NI.HW.LED_RIGHT,
                                                  ButtonHelper.getLedStateFromActiveState(ActiveState))
        end,
        function()
            return Environment.DataModel:getFocusSongGroupCount() > 1
        end

    )

    attachSwitchHandler(SwitchEventTable, MuteLedButton, SoloLedButton)
    return MuteLedButton, SoloLedButton

end

------------------------------------------------------------------------------------------------------------------------

return {

    createMuteSoloSoundLedButtons = createMuteSoloSoundLedButtonsFunc,
    createMuteSoloGroupLedButtons = createMuteSoloGroupLedButtonsFunc

}
