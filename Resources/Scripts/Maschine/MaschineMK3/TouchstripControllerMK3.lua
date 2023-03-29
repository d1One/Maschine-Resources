------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/TouchstripLEDs"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TouchstripControllerMK3 = class( 'TouchstripControllerMK3' )


TouchstripControllerMK3.TOUCHSTRIP_LEDS =
    {NI.HW.LED_TS_01, NI.HW.LED_TS_02, NI.HW.LED_TS_03, NI.HW.LED_TS_04, NI.HW.LED_TS_05,
     NI.HW.LED_TS_06, NI.HW.LED_TS_07, NI.HW.LED_TS_08, NI.HW.LED_TS_09, NI.HW.LED_TS_10,
     NI.HW.LED_TS_11, NI.HW.LED_TS_12, NI.HW.LED_TS_13, NI.HW.LED_TS_14, NI.HW.LED_TS_15,
     NI.HW.LED_TS_16, NI.HW.LED_TS_17, NI.HW.LED_TS_18, NI.HW.LED_TS_19, NI.HW.LED_TS_20,
     NI.HW.LED_TS_21, NI.HW.LED_TS_22, NI.HW.LED_TS_23, NI.HW.LED_TS_24, NI.HW.LED_TS_25}

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:__init()

    self.TouchstripStates = {
        Touched = {}, Value = {}, Delta = {}, OldTouched = {}, OldValue = {}, OldDelta = {}
    }

end

------------------------------------------------------------------------------------------------------------------------
-- update LEDs
------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:updateLEDs()

    local Context = NHLController:getContext()
    local TouchstripMode = Context:getTouchstripModeParameter():getValue()

    if TouchstripMode == NI.HW.TS_MODE_PERFORM then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        TouchstripLEDs.updateLEDsPerformMode(TouchstripControllerMK3.TOUCHSTRIP_LEDS, Group)

    elseif TouchstripMode == NI.HW.TS_MODE_PITCH or TouchstripMode == NI.HW.TS_MODE_MOD then

        local TouchstripTouched = self.TouchstripStates.Touched[1]
        local TouchstripPos = self.TouchstripStates.Value[1]
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local SoundColor = Sound and Sound:getColorParameter():getValue() or nil

        if TouchstripMode == NI.HW.TS_MODE_PITCH then
            self:updateLEDsPitchMode(self.TOUCHSTRIP_LEDS, TouchstripTouched, TouchstripPos, SoundColor)
        else
            if not TouchstripTouched and Sound then
                TouchstripPos = Context:getLastTouchstripValueForSound(Sound);
            end

            self:updateLEDsModMode(self.TOUCHSTRIP_LEDS, TouchstripTouched, TouchstripPos, SoundColor)
        end

    elseif TouchstripMode == NI.HW.TS_MODE_NOTES then

        self:updateLEDsNotesMode(self.TOUCHSTRIP_LEDS)

    else

        self:updateLEDsPlayPositionMode(self.TOUCHSTRIP_LEDS)

    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:updateLEDsPitchMode(LEDs, Touched, Pos, SoundColor)

    if not SoundColor then
        TouchstripLEDs.clearLEDs(LEDs)
        return
    end

    if not Pos or Touched == false then
        Pos = 0.5
    end

    local TouchstripPos = TouchstripLEDs.value2Led(LEDs, Pos)

    local WhiteLedIdFunctor = function(LedId)
        local LedIndex = Touched and TouchstripPos or TouchstripLEDs.getCenterLed(LEDs)
        return LedId == LEDs[LedIndex]
    end

    local LedStateFunctor = function(LedIndex)
        return TouchstripLEDs.isLedOn(LEDs, TouchstripPos, nil, LedIndex, true, false, false, false)
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedIdFunctor, SoundColor, LedStateFunctor)

end

-----------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:onTouchEvent(TouchID, TouchType, Value)

    -- make index 1-based in order to make table.contains work properly
    local LuaTouchID = TouchID + 1
    self.updateTouchstripState(self.TouchstripStates, LuaTouchID, TouchType, Value)

end

------------------------------------------------------------------------------------------------------------------------

-- StateTable is a table with 6 members: Touched, Value, Delta, OldTouched, OldValue, OldDelta
-- TouchID is 1-based
function TouchstripControllerMK3.updateTouchstripState(StateTable, TouchID, TouchType, Value)

    -- store last value
    StateTable.OldTouched[TouchID] = StateTable.Touched[TouchID]
    StateTable.OldValue[TouchID] = StateTable.Value[TouchID]
    StateTable.OldDelta[TouchID] = StateTable.Delta[TouchID]

    local Touched = TouchType == 0 or TouchType == 1
    local Delta = nil

    if TouchType == 1 and Value and StateTable.Value[TouchID] then
        Delta = Value - StateTable.Value[TouchID]
    end

    StateTable.Touched[TouchID] = Touched
    StateTable.Value[TouchID] = Value
    StateTable.Delta[TouchID] = Delta

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:updateLEDsModMode(LEDs, Touched, Pos, SoundColor)

    if not SoundColor then
        TouchstripLEDs.clearLEDs(LEDs)
        return
    end

    if not Pos then
        Pos = 0.0
    end

    local TouchstripPos = TouchstripLEDs.value2Led(LEDs, Pos)

    local WhiteLedIdFunctor = function(LedId)
        return LedId == LEDs[TouchstripPos]
    end

    local LedStateFunctor = function(LedIndex)
        return TouchstripLEDs.isLedOn(LEDs, TouchstripPos, nil, LedIndex, false, false, false, false)
    end

    TouchstripLEDs.updateTouchstripLEDs(LEDs, WhiteLedIdFunctor, SoundColor, LedStateFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:updateLEDsNotesMode(LEDs)

    local Touched = self.TouchstripStates.Touched[1]
    local Value = self.TouchstripStates.Value[1]

    local Color
    if PadModeHelper.getKeyboardMode() or PadModeHelper.is16VelocityMode() then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Color = Sound and Sound:getColorParameter():getValue() or nil
    else
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        Color = Group and Group:getColorParameter():getValue() or nil
    end

    TouchstripLEDs.updateLEDsNotesMode(LEDs, Touched, Value, Color)

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:updateLEDsPlayPositionMode(LEDs)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Mode = NI.HW.getMaschinePreferences():getShowPlayPositionOnTouchstrip()
    local Enabled = Mode == NI.DATA.PLAYPOSITION_TOUCHSTRIP_ON or
        MaschineHelper.isRecording() and Mode == NI.DATA.PLAYPOSITION_TOUCHSTRIP_REC_ONLY

    if not Song or not Enabled then
        TouchstripLEDs.clearLEDs(LEDs)
        return
    end

    local Pos, Color = nil
    local PlayPos = NI.DATA.TransportAccess.getPlayPosition(App)

    if NI.DATA.SongAlgorithms.isIdeaSpacePlaying(Song) then
        Pos, Color = self:getPositionAndColorIdeaSpaceFocused(Song, PlayPos)
    else
        Pos, Color = self:getPositionAndColorTimelineFocused(Song, PlayPos)
    end

    if Pos then
        local TouchstripPos = TouchstripLEDs.value2Led(LEDs, Pos) + 1
        local LedStateFunctor = function(LedIndex)
            return TouchstripLEDs.isLedOn(LEDs, TouchstripPos, nil, LedIndex, false, false, false, false)
        end

        TouchstripLEDs.updateTouchstripLEDs(LEDs, nil, Color, LedStateFunctor)
    else
        TouchstripLEDs.clearLEDs(TouchstripControllerMK3.TOUCHSTRIP_LEDS)
    end

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:getPositionAndColorIdeaSpaceFocused(Song, PlayPos)

    local Pos = nil
    local Color = LEDColors.WHITE
    local InvalidTick = NI.DATA.SequenceAlgorithms.invalidTick()

    if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_SCENE then

        local Scene = Song:getIdeaSpacePlayingScene()
        if not Scene then
            return
        end

        local ScenePos = NI.DATA.SongAlgorithms.scenePlayPositionInIdeaSpace(Song, PlayPos)
        if ScenePos == InvalidTick then
            return
        end

        local SceneLength = Scene:getLongestPatternLength()
        Pos = SceneLength > 0 and ScenePos / SceneLength or nil
        Color = Scene:getColorParameter():getValue()

    else

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Pattern = Group and NI.DATA.IdeaSpaceAlgorithms.getPlayingPattern(Song, Group)
        if not Pattern then
            return
        end

        local PatternPos = NI.DATA.IdeaSpaceAlgorithms.patternCurrentPlayPosition(Song, Pattern, PlayPos)
        local PatternStart = Pattern:getStartParameter():getValue()
        local PatternLength = Pattern:getLengthParameter():getValue()
        Pos = (PatternPos - PatternStart) / PatternLength
        Color = Pattern:getColorParameter():getValue()

    end

    return Pos, Color

end

------------------------------------------------------------------------------------------------------------------------

function TouchstripControllerMK3:getPositionAndColorTimelineFocused(Song, PlayPos, LEDs)

    local Pos = nil

    local LoopBegin = Song:getLoopParameter():getLoopBeginInTicks()
    local LoopLength = Song:getLoopParameter():getLoopLengthInTicks()
    local IsPlayPosInLoopRange = PlayPos < LoopBegin + LoopLength and PlayPos >= LoopBegin

    if NI.DATA.TransportAccess.isLoopActive(App) and IsPlayPosInLoopRange then
        local LoopPos = PlayPos - LoopBegin
        Pos = LoopPos / LoopLength
    else
        local SectionLength = NI.DATA.SongAlgorithms.getLastSectionEnd(Song)
        Pos = PlayPos < SectionLength  and PlayPos / SectionLength or nil
    end

    return Pos, LEDColors.WHITE

end

------------------------------------------------------------------------------------------------------------------------
