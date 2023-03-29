------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/PatternHelper"
require "Scripts/Maschine/Jam/Helper/JamArrangerHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Shared/Components/Looper"
require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MainPage = class( 'MainPage', PageJam )

------------------------------------------------------------------------------------------------------------------------

function MainPage:__init(Controller)

    PageJam.__init(self, "MainPage", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function MainPage:hasDuplicateMode()

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MainPage:onPadButton(Column, Row, Pressed)

    if not Pressed then
        return
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local GroupIndex = JamHelper.getGroupOffset() + Column - 1
    local PatternIndex = JamHelper.getPatternOffset() + Row - 1

    if self.Controller.Looper:updateTargetOrStop(GroupIndex + 1, PatternIndex + 1, self.Controller:isClearActive()) then
        return
    end

    if self.Controller:isClearActive() then

        local Group = Song and Song:getGroups():at(GroupIndex)
        if Group then
            NI.DATA.GroupAccess.deletePattern(App, Group, PatternIndex)
        end

    elseif self.Duplicate:isEnabled() then

        self.Duplicate:onPatternDuplicate(Column, Row)

    else

        PatternHelper.focusPatternByGroupAndByIndex(GroupIndex, PatternIndex, true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function MainPage:updatePadLEDs()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local GroupOffset = JamHelper.getGroupOffset()
    local PatternOffset = JamHelper.getPatternOffset()

    if Song and Song:getGroups() then
        for Index = 1, 8 do

            if NI.HW.getBrightProjectView() then
                LEDHelper.updateLEDsWithFunctor(
                    self.Controller.PAD_LEDS[Index],
                    PatternOffset,
                    function (PatternIndex)
                        local _, IsPattern = JamHelper.getPatternLEDState(Index + GroupOffset, PatternIndex)
                        return IsPattern, IsPattern
                    end,
                    function (PatternIndex)
                        local Cur = JamHelper.getPatternLEDState(Index + GroupOffset, PatternIndex)
                        return not Cur and JamHelper.getPatternLEDColorByGroupAndByIndex(Index + GroupOffset, PatternIndex) or LEDColors.WHITE
                    end)
            else
                LEDHelper.updateLEDsWithFunctor(
                    self.Controller.PAD_LEDS[Index],
                    PatternOffset,
                    function (PatternIndex) return JamHelper.getPatternLEDState(Index + GroupOffset, PatternIndex) end,
                    function (PatternIndex) return JamHelper.getPatternLEDColorByGroupAndByIndex(Index + GroupOffset, PatternIndex) end)
            end

        end
    end

    if self.Duplicate:isEnabled() then
        self.Duplicate:updatePatternLEDs()
    end

    self.Controller.Looper:updateTargetLED(
        self.Controller.PAD_LEDS,
        JamHelper.getGroupOffset(),
        JamHelper.getPatternOffset())

end

------------------------------------------------------------------------------------------------------------------------

function MainPage:onDPadButton(Button, Pressed)

    if Pressed then

        if Button == NI.HW.BUTTON_DPAD_UP or Button == NI.HW.BUTTON_DPAD_DOWN then

            local ShiftPressed = self.Controller:isShiftPressed()
            local PatternOffset = JamHelper.getPatternOffset()
            local IsDown = Button == NI.HW.BUTTON_DPAD_DOWN

            local NewPatternOffset = IsDown
                and JamHelper.increasePatternOffset(PatternOffset, JamHelper.getMaxNumPatterns(), ShiftPressed)
                or  JamHelper.decreaseOffset(PatternOffset, 0, ShiftPressed)

            if NewPatternOffset == PatternOffset and IsDown and JamHelper.canAddPatternBank() then
                JamHelper.addPatternBank()
                NewPatternOffset = NewPatternOffset + (ShiftPressed and 1 or JamControllerBase.NUM_PAD_ROWS)
            end

            JamHelper.setPatternOffset(NewPatternOffset)

        end
    end

    PageJam.onDPadButton(self, Button, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function MainPage:updateDPadLEDs()

    local PatternOffset = JamHelper.getPatternOffset()
    local CanGoUp = PatternOffset > 0
    local CanGoDown = (PatternOffset + 8 < JamHelper.getMaxNumPatterns() or JamHelper.canAddPatternBank())

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, CanGoUp)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, CanGoDown)

    PageJam.updateDPadLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------
