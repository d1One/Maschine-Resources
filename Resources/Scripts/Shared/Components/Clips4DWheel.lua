
local class = require 'Scripts/Shared/Helpers/classy'
Clips4DWheel = class( 'Clips4DWheel' )

------------------------------------------------------------------------------------------------------------------------

-- Repeat actions when buttons are held
local Countdown = 0

------------------------------------------------------------------------------------------------------------------------

function Clips4DWheel.updateLEDs(Controller)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ShowsClipLayer = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    if not Song or not Group or not ShowsClipLayer then
        return
    end

    local CanMoveLeft = NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App) > 0
    local ClipEvent = NI.DATA.StateHelper.getFocusClipEvent(App)
    local CanMoveRight = ClipEvent and true or false -- if a clip exists, it can always be moved to the right

    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, CanMoveLeft, LEDColors.WHITE)
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, CanMoveRight, LEDColors.WHITE)

    local HasPrevGroup = NI.DATA.SongAlgorithms.hasPrevNextGroup(Song, false)
    local HasNextGroup = NI.DATA.SongAlgorithms.hasPrevNextGroup(Song, true)

    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, HasPrevGroup, LEDColors.WHITE)
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, HasNextGroup, LEDColors.WHITE)

end

------------------------------------------------------------------------------------------------------------------------

function Clips4DWheel.onWheel(Controller, Inc)

    if not Controller:getShiftPressed() then

        if not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_UP]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_DOWN]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_LEFT]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_RIGHT] then


            if Controller.SwitchPressed[NI.HW.BUTTON_WHEEL] then
                local ShiftPressed = false;
                NI.DATA.EventPatternAccess.changeFocusClipEventLength(App, Inc > 0 and 1 or -1, ShiftPressed)
            else
                NI.DATA.GroupAccess.shiftClipEventFocus(App, Inc > 0)
            end

            return true
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

local function onWheelDirection(Controller)

    local Up = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_UP]
    local Down = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_DOWN]
    local Left = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_LEFT]
    local Right = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_RIGHT]

    if Left or Right then

        NI.DATA.EventPatternAccess.changeFocusClipEventPosition(App, Right and 1 or -1, Controller:getShiftPressed())

    elseif Up or Down then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            NI.DATA.SongAccess.shiftGroupFocus(App, Song, Down and 1 or -1, false)
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function Clips4DWheel.onWheelDirection(Controller, Pressed)

    -- holding a wheel direction should trigger the action regularly with a slightly longer initial trigger time
    Countdown = Pressed and 20 or 0

    if Pressed then
        onWheelDirection(Controller)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Clips4DWheel.onControllerTimer(Controller)

    if Countdown > 0 then
        Countdown = Countdown - 1

        if Countdown == 0 then
            onWheelDirection(Controller)
            -- holding a wheel direction should trigger the action in faster intervals after the initial trigger time
            Countdown = 4
        end
    end

    Clips4DWheel.updateLEDs(Controller)

end


