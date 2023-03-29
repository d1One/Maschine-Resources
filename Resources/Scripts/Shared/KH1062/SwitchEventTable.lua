------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SwitchEventTable = class( 'SwitchEventTable' )

------------------------------------------------------------------------------------------------------------------------

function SwitchEventTable:__init()

    self.Handlers =
    {
        [false] = {},
        [true] = {}
    }

end

------------------------------------------------------------------------------------------------------------------------

-- Returns: whether the event has been handled

function SwitchEventTable:handleSwitchEvent(IsShiftPressed, SwitchID, Pressed)

    local ModifierHandler = self.Handlers[IsShiftPressed]
    local Handler = ModifierHandler[SwitchID]
    if Handler then
        if Pressed then
            if Handler.OnPressed then
                return Handler.OnPressed(Pressed)
            end
        else
            if Handler.OnReleased then
                return Handler.OnReleased(Pressed)
            end
        end
        if Handler.OnSwitch then
            return Handler.OnSwitch(Pressed)
        end
    end

    return false
end

------------------------------------------------------------------------------------------------------------------------

-- setHandler(SwitchParams, Func)
--
-- SwitchParams table may contain the following:
--
--      Switch - Switch ID (mandatory)
--      Shift - true - trigger event if Shift is active
--            - false - trigger event if Shift is not active
--            - nil (or not specified) - trigger event irrespective of Shift state
--
--      Pressed - true - trigger event only when Switch Pressed
--              - false - trigger event only when Switch released
--              - nil (or not specified) - trigger event on both press and release
--
-- Func - event to be triggered. The function will be passed a single parameter, a boolean representing whether the Switch is Pressed or released
--                              If the function returns true, no further event handlers (e.g. from the global switch table) will be called

function SwitchEventTable:setHandler(SwitchParams, Func)

    local CreateAndSetHandler = function (Switch, Shift, OptionalPressed, Func)

        local ModifierHandler = self.Handlers[Shift]
        if ModifierHandler == nil then
            self.Handlers[Shift] = {}
        end

        if self.Handlers[Shift][Switch] == nil then
            self.Handlers[Shift][Switch] = {}
        end

        local SwitchEvents = self.Handlers[Shift][Switch]
        if OptionalPressed == nil then
            SwitchEvents.OnSwitch = Func
        elseif OptionalPressed == true then
            SwitchEvents.OnPressed = Func
        else
            SwitchEvents.OnReleased = Func
        end

    end

    if SwitchParams.Switch == nil or type (SwitchParams.Switch) ~= "number" then
        error("Invalid Switch ID")
    end

    if SwitchParams.Shift ~= nil and type (SwitchParams.Shift) ~= "boolean" then
        error("Invalid Shift parameter")
    end

    if SwitchParams.Pressed ~= nil and type (SwitchParams.Pressed) ~= "boolean" then
        error("Invalid Pressed parameter")
    end

    local OptionalPressed = SwitchParams.Pressed or nil
    if SwitchParams.Shift ~= nil then
        CreateAndSetHandler(SwitchParams.Switch, SwitchParams.Shift, OptionalPressed, Func)
    else
        CreateAndSetHandler(SwitchParams.Switch, false, OptionalPressed, Func)
        CreateAndSetHandler(SwitchParams.Switch, true, OptionalPressed, Func)
    end

end

