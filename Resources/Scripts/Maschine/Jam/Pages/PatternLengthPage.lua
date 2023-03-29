------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Jam/Pages/PageJam"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternLengthPage = class( 'PatternLengthPage', PageJam )

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:__init(Controller)

    PageJam.__init(self, "PatternLengthPage", Controller)

    self.PageLEDs = {NI.HW.LED_SOLO}

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onPadButton(Column, Row, Pressed)

    if not Pressed then
        return
    end

    PatternHelper.setPatternLengthInBars((Row - 1) * JamControllerBase.NUM_PAD_ROWS + (Column - 1) + 1)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onShow(Show)

    if Show then
        -- Create a pattern when entering the page if there is none, in order to avoid an empty matrix
        NI.DATA.WORKSPACE.createPatternIfNeeded(App)
    end

    -- call base
    PageJam.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:updatePadLEDs()

    local LEDFunctor = function(Row, Column)

        local Selected, Enabled, Flashing = false, false, false

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        local Color = Pattern and Pattern:getColorParameter():getValue() or nil

        local PatternLengthInBars = (Row - 1) * JamControllerBase.NUM_PAD_ROWS + (Column - 1) + 1
        local CurrentPatternLength = PatternHelper.getCurrentPatternLengthInBars()

        Enabled = PatternLengthInBars < CurrentPatternLength
        Selected = PatternLengthInBars == CurrentPatternLength

        return Selected, Enabled, Color, Flashing

    end

    LEDHelper.updateMatrixLedsWithFunctor(self.Controller.PAD_LEDS,
                                          JamControllerBase.NUM_PAD_COLUMNS,
                                          JamControllerBase.NUM_PAD_ROWS,
                                          LEDFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:updateDPadLEDs()

    PageJam.updateDPadLEDs(self)

    -- Disable up/down buttons
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, false)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, false)

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onDPadButton(Button, Pressed)

    -- Handle only group navigation buttons (Left/Right)
    if Button == NI.HW.BUTTON_DPAD_LEFT or Button == NI.HW.BUTTON_DPAD_RIGHT then
        PageJam.onDPadButton(self, Button, Pressed)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternLengthPage:onWheelEvent(Inc)

    if not JamHelper.isJamOSOVisible() then
        local NewPatternLength = math.bound(PatternHelper.getCurrentPatternLengthInBars() + Inc,
            0, JamControllerBase.NUM_PAD_ROWS * JamControllerBase.NUM_PAD_COLUMNS)

        PatternHelper.setPatternLengthInBars(NewPatternLength)
    end

end

------------------------------------------------------------------------------------------------------------------------
