if not NI.APP.FEATURE.ARRANGER then
    return
end


require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
EventsHelper = class( 'EventsHelper' )

------------------------------------------------------------------------------------------------------------------------

Condition =
{
    GREATER		  = NI.DATA.EventPatternTools.COND_GREATER,
    GREATER_EQUAL = NI.DATA.EventPatternTools.COND_GREATER_EQUAL,
    EQUAL		  = NI.DATA.EventPatternTools.COND_EQUAL,
    LESS_EQUAL	  = NI.DATA.EventPatternTools.COND_LESS_EQUAL,
    LESS		  = NI.DATA.EventPatternTools.COND_LESS
}

------------------------------------------------------------------------------------------------------------------------
-- Globals
------------------------------------------------------------------------------------------------------------------------

EventsHelper.SelectionStart = 0
EventsHelper.SelectionEnd   = 0

EventsHelper.NoteMin        = 0
EventsHelper.NoteMax        = 127

------------------------------------------------------------------------------------------------------------------------
-- Event Handling
------------------------------------------------------------------------------------------------------------------------

function EventsHelper.onPadEventQuiet(PadIndex, Trigger, Erase)

    if Erase then
        PatternHelper.removeEventsByPadIndex(PadIndex, false)
    else
        MaschineHelper.selectSoundByPadIndex(PadIndex, Trigger)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.onPadEventEvents(PadIndex, Erase)

    if Erase then
        PatternHelper.removeEventsByPadIndex(PadIndex, true)
    else
        EventsHelper.selectEventsByPad(PadIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.onSelectionTimeChanged(Delta, StartTimeChanged)

    local PatternStart = NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)
    local PatternEnd = NI.DATA.StateHelper.getFocusPatternActiveRangeEnd(App)
    local TimeSnap	= StepHelper.getPatternEditorSnapInTicks()

    EventsHelper.updateSelectionRange(false)

    local NewValue = (StartTimeChanged and EventsHelper.SelectionStart or EventsHelper.SelectionEnd)
        + (Delta > 0 and TimeSnap or -TimeSnap)

    if StartTimeChanged then
        EventsHelper.SelectionStart = math.bound(NewValue, PatternStart, math.min(EventsHelper.SelectionEnd, PatternEnd))
    else
        EventsHelper.SelectionEnd = math.bound(NewValue, math.max(EventsHelper.SelectionStart, PatternStart), PatternEnd)
    end

    EventsHelper.selectEvents()

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.onSelectionNotesPitchChanged(Delta, MinNoteChanged)

    local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    if Sequence then

        local Note = MinNoteChanged and EventsHelper.NoteMin or EventsHelper.NoteMax
        local Cond = Delta > 0 and Condition.GREATER or Condition.LESS

        local PatternStart = NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)
        local PatternEnd = NI.DATA.StateHelper.getFocusPatternActiveRangeEnd(App)
        local NoteEvent = NI.DATA.EventPatternTools.getNoteEventByNote(Sequence, PatternStart, PatternEnd, Note, false, Cond)

        if NoteEvent then
            if MinNoteChanged then
                EventsHelper.NoteMin = math.bound(NoteEvent:getNote(), 0, EventsHelper.NoteMax)
            else
                EventsHelper.NoteMax = math.bound(NoteEvent:getNote(), EventsHelper.NoteMin, 127)
            end
        end

        EventsHelper.selectEvents()
    end

end


------------------------------------------------------------------------------------------------------------------------

function EventsHelper.updateLeftRightLEDs(Controller)

	local CanNext = NI.DATA.EventPatternTools.canSelectPrevNextEvent(App, true, false)
	local CanPrev = NI.DATA.EventPatternTools.canSelectPrevNextEvent(App, false, false)

	LEDHelper.updateButtonLED(Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, CanNext)
	LEDHelper.updateButtonLED(Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, CanPrev)

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.selectPrevNextEvent(Next)

    if NI.DATA.EventPatternTools.canSelectPrevNextEvent(App, Next, false) then

        NI.DATA.EventPatternTools.selectPrevNextEvent(App, Next, false)
        EventsHelper.updateSelectionRange(true)

    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.selectEvents()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)

    if not Sound or not Sequence then

        -- NOP

    elseif NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

        NI.DATA.EventPatternTools.selectAudioEvents(App, Sequence,
            EventsHelper.SelectionStart, EventsHelper.SelectionEnd)

    elseif PadModeHelper.getKeyboardMode() then

        NI.DATA.EventPatternTools.selectNoteEvents(App, Sequence,
            EventsHelper.SelectionStart, EventsHelper.SelectionEnd, EventsHelper.NoteMin, EventsHelper.NoteMax)
    else

        NI.DATA.EventPatternTools.selectNoteEventsInTime(App, Sequence,
            EventsHelper.SelectionStart, EventsHelper.SelectionEnd)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.updateSelectionRange(Sync)

    local PatternStart = NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)
    local PatternEnd = NI.DATA.StateHelper.getFocusPatternActiveRangeEnd(App)
    local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local IsAudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    if Sequence then
        local InvalidTick = NI.DATA.SequenceAlgorithms.invalidTick()
        local SelectionStart = InvalidTick
        local SelectionEnd = InvalidTick

        if IsAudioLoop then
            if NI.DATA.SequenceAlgorithms.getNumSelectedAudioEventsInRange(Sequence, PatternStart, PatternEnd) > 0 then
                -- currently we see all audio events as one event from PatternStart, PatternEnd
                SelectionStart = 0
                SelectionEnd = 0
            end
        else
            SelectionStart = NI.DATA.SequenceAlgorithms.getFirstSelectedNoteEventInRangeTime(Sequence, PatternStart, PatternEnd)
            SelectionEnd = NI.DATA.SequenceAlgorithms.getLastSelectedNoteEventInRangeTime(Sequence, PatternStart, PatternEnd)
        end

        if Sync then
            -- Hard sync
            if SelectionStart == InvalidTick or SelectionEnd == InvalidTick then
                EventsHelper.SelectionStart = PatternStart
                EventsHelper.SelectionEnd = PatternEnd
            else
                EventsHelper.SelectionStart = SelectionStart
                EventsHelper.SelectionEnd = SelectionEnd
            end

            -- update pitch range
            if not IsAudioLoop then
                local NoteMin = 0
                local NoteMax = 127

                local NoteEventMin = NI.DATA.EventPatternTools.getNoteEventByNote(
                    Sequence, PatternStart, PatternEnd, NoteMin, true, Condition.GREATER_EQUAL)
                if NoteEventMin then
                    NoteMin = NoteEventMin:getNote()
                end

                local NoteEventMax = NI.DATA.EventPatternTools.getNoteEventByNote(
                    Sequence, PatternStart, PatternEnd, NoteMax, true, Condition.LESS_EQUAL)
                if NoteEventMax then
                    NoteMax = NoteEventMax:getNote()
                end

                EventsHelper.NoteMin = NoteMin
                EventsHelper.NoteMax = NoteMax
            end

        else
            -- Soft sync
            if SelectionStart ~= InvalidTick and SelectionStart < EventsHelper.SelectionStart then
                EventsHelper.SelectionStart = SelectionStart
            end

            if SelectionEnd ~= InvalidTick and SelectionEnd > EventsHelper.SelectionEnd then
                EventsHelper.SelectionEnd = SelectionEnd
            end
        end
    else
        if Sync then
            EventsHelper.SelectionStart = PatternStart
            EventsHelper.SelectionEnd = PatternEnd
        end
    end

    EventsHelper.SelectionStart = math.bound(EventsHelper.SelectionStart, PatternStart, PatternEnd)
    EventsHelper.SelectionEnd = math.bound(EventsHelper.SelectionEnd, PatternStart, PatternEnd)

end

-----------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
-----------------------------------------------------------------------------------------------------------------------

function EventsHelper.getSelectButtonStates(Index, IsGroup)

    Index = Index - 1 -- make 0-indexed

    local StateCache   = App:getStateCache()
    local Song         = NI.DATA.StateHelper.getFocusSong(App)
    local Group        = NI.DATA.StateHelper.getFocusGroup(App)
    local ObjectVector = IsGroup and (Song and Song:getGroups() or nil) or (Group and Group:getSounds() or nil)
    local Object       = ObjectVector and ObjectVector:at(Index) or nil

    if Object then

        local MultiSelect   = App:getWorkspace():getSelectMultiParameter():getValue()
        local Name          = Object:getDisplayName() or ""
        local HasSelection  = false
        local HasFocus		= false

        if IsGroup then
            HasFocus = Object == Group
        else
            HasFocus = Object == NI.DATA.StateHelper.getFocusSound(App)
        end

        if not HasFocus then
            HasSelection = ObjectVector:isInSelection(Object)
        end

        return true, true, HasSelection, HasFocus, Name

    elseif ObjectVector and IsGroup and Index == ObjectVector:size() then

        return true, true, false, false, "+"

    end

    return false, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.getSelectedNoteEventsDisplayValue(ValueName)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    local Value = "-"

    if Song and Group then

        local NumEvents = NI.DATA.EventPatternTools.getNumSelectedNoteEventsInPatternRange(App)

        if ValueName == "EventPositions" then

            if NumEvents > 0 then
                local EventsPosition = NI.DATA.EventPatternTools.getSelectedNoteEventPosition(Song, Group, false)
                Value = EventsPosition == -1 and "*" or Song:getTickPositionToString(EventsPosition)
            end

        elseif ValueName == "EventLengths" then

            if NumEvents > 0 then
                local EventsLength = NI.DATA.EventPatternTools.getSelectedNoteEventsLength(Song, Group, false)
                Value = EventsLength == -1 and "*" or EventsLength
            end

        elseif ValueName == "EventPitches" then

            if NumEvents > 0 then
                local EventsPitch = NI.DATA.EventPatternTools.getSelectedNoteEventsPitch(Song, Group, false)
                Value = EventsPitch >= 0 and EventsPitch < 128 and Song:getNoteToString(EventsPitch) or "*"
            end

        elseif ValueName == "EventVelocities" then

            if NumEvents > 0 then
                local EventsVelocity = NI.DATA.EventPatternTools.getSelectedNoteEventsVelocity(Song, Group, false)
                Value = EventsVelocity >= 0 and EventsVelocity < 128 and tostring(EventsVelocity) or "*"
            end

        end
    end

    return Value

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.getSelectedEventIndexDisplayValue()

    local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if not Sound or not Sequence or Sequence:empty() then
        return "-"
    end

    local PatternStart = NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)
    local PatternEnd = NI.DATA.StateHelper.getFocusPatternActiveRangeEnd(App)

    if NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

        local NumEvents = NI.DATA.SequenceAlgorithms.getNumSelectedAudioEventsInRange(Sequence, PatternStart, PatternEnd)
        -- regardless of how many audio events are selected we want to show only 1 (for now)
        if NumEvents > 0 then
            return "1"
        end

    else

        local NumEvents = NI.DATA.SequenceAlgorithms.getNumSelectedNoteEventsInRange(Sequence, PatternStart, PatternEnd)

        if NumEvents == 1 then
            local Index = NI.DATA.SequenceAlgorithms.getSelectedNoteEventIndexInRange(Sequence, PatternStart, PatternEnd)
            return tostring(Index + 1)
        elseif NumEvents > 1 then
            return "*"
        end

    end

    return "-"

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.getSelectionTimeStartDisplayValue()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    return (Song and Pattern) and Song:getTickPositionToString(EventsHelper.SelectionStart) or "-"

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.getSelectionTimeEndDisplayValue()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    return (Song and Pattern) and Song:getTickPositionToString(EventsHelper.SelectionEnd) or "-"

end

------------------------------------------------------------------------------------------------------------------------
-- Helper for moving the selected NoteEvents TimeOffsets, Notes or Velocities
------------------------------------------------------------------------------------------------------------------------

function EventsHelper.modifySelectedNoteEvents(DeltaLen, DeltaPitch, DeltaVel, ShiftPressed)

    if DeltaLen and DeltaLen ~= 0 then
        -- MAS2-4745: Don't use StepHelper.getPatternEditorSnapInTicks(), because it returns 1/16th value when grid
        -- is off. According to spec: when grid is off, then MIN_SNAP should be used.
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local StepSize = Song and Song:getPatternEditorSnapInTicks(true) or NI.UTILS.CONST_MIN_SNAP
        local Step = ShiftPressed and NI.UTILS.CONST_MIN_SNAP or StepSize

        NI.DATA.EventPatternTools.modifySelectedNoteEventsLength(App, DeltaLen * Step)

    elseif DeltaPitch and DeltaPitch ~= 0 then
        NI.DATA.EventPatternTools.modifySelectedNoteEventsPitch(App, DeltaPitch)

    elseif DeltaVel and DeltaVel ~= 0 then
        NI.DATA.EventPatternTools.modifySelectedNoteEventsVelocity(App, DeltaVel)
    end

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.selectEventsByPad(PadIndex)

    if PadModeHelper.getKeyboardMode() then

        local NoteIndex = PadModeHelper.getNoteForPad(PadIndex)

        if NoteIndex >= 0 and NoteIndex < 128 then
            NI.DATA.EventPatternTools.toggleEventSelectionByNote(App, NoteIndex)
        end

    else

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = Group and Group:getSounds():at(PadIndex - 1)
        if not Sound then
            return
        end

        NI.DATA.EventPatternTools.toggleEventSelectionBySound(App, Group, Sound)

        if NI.DATA.EventPatternTools.allEventsSelectedForSound(App, Sound) then
            EventsHelper.updateSelectionRange(true)
        end

    end
end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.updatePadLEDsEvents(LEDs, ErasePressed)

    local GetPadState, GetPadColor

    if PadModeHelper.getKeyboardMode() then

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        if not Sound then
            return
        end

        GetPadState = function(PadIndex)
            return MaschineHelper.getLEDStatesNoteEventsByIndex(PadIndex, ErasePressed)
        end
        GetPadColor = function() return Sound:getColorParameter():getValue() end

    else

        GetPadState = function(SoundIndex)
            return MaschineHelper.getLEDStatesSoundEventsByIndex(SoundIndex, ErasePressed)
        end
        GetPadColor = MaschineHelper.getSoundColorByIndex

    end

    LEDHelper.updateLEDsWithFunctor(LEDs, 0, GetPadState, GetPadColor)

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.addSelectionEncoders(Encoders, ParameterWidgets)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song == nil or Group == nil then
        return
    end

    local KeyboardMode = Group and Group:getKeyboardModeEnabledParameter():getValue() or false
    local FnIsAudioLoop = function()
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        return Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    end

    Encoders:addEncoder(
        1, "START", ParameterWidgets[1], 0.05,
        function() return EventsHelper.getSelectionTimeStartDisplayValue() end,
        function(Delta) EventsHelper.onSelectionTimeChanged(Delta, true) end,
        nil
    )

    Encoders:addEncoder(
        2, "END", ParameterWidgets[2], 0.05,
        function() return EventsHelper.getSelectionTimeEndDisplayValue() end,
        function(Delta) EventsHelper.onSelectionTimeChanged(Delta, false) end,
        nil
    )

    Encoders:addEncoder(
        3, KeyboardMode and "LOW" or "", ParameterWidgets[3], 0.1,
        KeyboardMode
            and function() return Song:getNoteToString(EventsHelper.NoteMin) end
            or  function() return "" end,
        KeyboardMode
            and function(Delta) EventsHelper.onSelectionNotesPitchChanged(Delta, true) end
            or  function() end,
        KeyboardMode and FnIsAudioLoop or nil
    )

    Encoders:addEncoder(
        4, KeyboardMode and "HIGH" or "EVENT", ParameterWidgets[4], 0.1,
        KeyboardMode
            and function() return Song:getNoteToString(EventsHelper.NoteMax) end
            or  function() return EventsHelper.getSelectedEventIndexDisplayValue() end,
        KeyboardMode
            and function(Delta) EventsHelper.onSelectionNotesPitchChanged(Delta, false) end
            or  function(Delta) EventsHelper.selectPrevNextEvent(Delta > 0) end,
        KeyboardMode and FnIsAudioLoop or nil
    )

end

------------------------------------------------------------------------------------------------------------------------

function EventsHelper.addEditingEncoders(Encoders, ParameterWidgets, ShiftPressedFunc)

    local FnDisable = function() return false end

    Encoders:addEncoder(
        1, "POSITION", ParameterWidgets[1], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventPositions") end,
        function(Delta) NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, Delta > 0 and 1 or -1,
                                                                            ShiftPressedFunc(), true) end,
        FnDisable
    )

    Encoders:addEncoder(
        2, "PITCH", ParameterWidgets[2], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventPitches") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(0, Delta > 0 and 1 or -1, 0) end,
        FnDisable
    )

    Encoders:addEncoder(
        3, "VELOCITY", ParameterWidgets[3], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventVelocities") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(0, 0, Delta) end,
        FnDisable
    )

    Encoders:addEncoder(
        4, "LENGTH", ParameterWidgets[4], 0.05,
        function() return EventsHelper.getSelectedNoteEventsDisplayValue("EventLengths") end,
        function(Delta) EventsHelper.modifySelectedNoteEvents(Delta > 0 and 1 or -1, 0, 0,
                                                              ShiftPressedFunc()) end,
        FnDisable
    )

end

------------------------------------------------------------------------------------------------------------------------
