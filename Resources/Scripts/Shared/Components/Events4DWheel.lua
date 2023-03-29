
local class = require 'Scripts/Shared/Helpers/classy'
Events4DWheel = class( 'Events4DWheel' )

-- Repeat actions when buttons are held
local Countdown = 0

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.updateLEDs(Controller, FocusSoundOnly)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local HasEvents = (not FocusSoundOnly) and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents()

    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_LEFT, NI.HW.BUTTON_WHEEL_LEFT, HasEvents, LEDColors.WHITE)
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_RIGHT, NI.HW.BUTTON_WHEEL_RIGHT, HasEvents, LEDColors.WHITE)

    local Color = LEDColors.WHITE
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_UP, NI.HW.BUTTON_WHEEL_UP, (not FocusSoundOnly) or HasEvents, Color)
    LEDHelper.updateButtonLED(Controller, NI.HW.LED_WHEEL_BUTTON_DOWN, NI.HW.BUTTON_WHEEL_DOWN, (not FocusSoundOnly) or HasEvents, Color)

end

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.onWheel(Controller, Inc)

    if not Controller:getShiftPressed() then

        if not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_UP]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_DOWN]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_LEFT]
            and not Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_RIGHT] then

            if Controller.SwitchPressed[NI.HW.BUTTON_WHEEL] then

                EventsHelper.modifySelectedNoteEvents(Inc, 0, 0, false)
            else
                EventsHelper.selectPrevNextEvent(Inc > 0)
            end

            Events4DWheel.updateAccessibilityEventPosition()

            return true
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

local function onWheelDirection(Controller, FocusSoundOnly)

    local Up = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_UP]
    local Down = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_DOWN]
    local Left = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_LEFT]
    local Right = Controller.SwitchPressed[NI.HW.BUTTON_WHEEL_RIGHT]

    if Left or Right then

        NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, Right and 1 or -1, Controller:getShiftPressed(), false)

    elseif Up or Down then

        if FocusSoundOnly then

            local Semitones = Controller:getShiftPressed() and 12 or 1
            NI.DATA.EventPatternTools.transposeNoteEvents(App, Up and Semitones or -Semitones)
        else
            MaschineHelper.selectPrevNextSound(Up and -1 or 1)
        end
        Events4DWheel.updateAccessibilityPatternState(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.onWheelDirection(Controller, Pressed, FocusSoundOnly)

    Countdown = Pressed and 20 or 0

    if Pressed then
        onWheelDirection(Controller, FocusSoundOnly)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.onControllerTimer(Controller, FocusSoundOnly)

    if Countdown > 0 then
        Countdown = Countdown - 1

        if Countdown == 0 then
            onWheelDirection(Controller, FocusSoundOnly)
            Countdown = 4
        end
    end

    Events4DWheel.updateLEDs(Controller, FocusSoundOnly)

end

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.updateAccessibilityPatternState(TriggerSpeech)

    if not NHLController:isExternalAccessibilityRunning() then
        return
    end
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    local FocusSoundName = FocusSound and FocusSound:getDisplayName() or "No sound selected"

    local FocusEvent = EventsHelper.getSelectedEventIndexDisplayValue()

    NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, 0, 0, 0, FocusSoundName)
    if TriggerSpeech then
        NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Events4DWheel.updateAccessibilityEventPosition()

    local FocusEvent = EventsHelper.getSelectedEventIndexDisplayValue()

    NHLController:addAccessibilityControlData(NI.HW.ZONE_SCREENINFO, 0, 0, 0, 0, FocusEvent)
    NHLController:triggerAccessibilitySpeech(NI.HW.ZONE_SCREENINFO, 0)

end