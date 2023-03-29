------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepHelper = class( 'StepHelper' )

------------------------------------------------------------------------------------------------------------------------
-- Consts and class vars
------------------------------------------------------------------------------------------------------------------------

StepHelper.TICKS_PER_16TH = NI.UTILS.TICKS_PER_QUARTER / 4
StepHelper.MOD_STEP_HOLD_TIME = 8

StepHelper.HoldingPads = {}
StepHelper.PadVelocities = {}
StepHelper.PadHoldTime = -1
StepHelper.PatternSegment = 0
StepHelper.FollowModeOn = false

------------------------------------------------------------------------------------------------------------------------
-- update LEDs
------------------------------------------------------------------------------------------------------------------------

function StepHelper.updatePadLEDs(PatternSegment)

    if PatternSegment == nil then -- set default arg
        PatternSegment = StepHelper.PatternSegment
    end

    local StateCache = App:getStateCache()
    local Pattern    = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Group      = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound		 = NI.DATA.StateHelper.getFocusSound(App)

    if Group and Pattern and Sound then

        -- Turn on LED that represents current position in playing pattern
        local PlayPos = StateCache:playPositionStepEditor() - (PatternSegment * 16)
        local PlayPosIdx = (PlayPos >= 0 and PlayPos <= 15) and (PlayPos + 1) or nil

        local Color = Sound:getColorParameter():getValue()
        local StepRangeWidth = StepHelper.getStepRangeWidth()

        for Index = 1, 16 do
            local LEDState = LEDHelper.LS_OFF
            local IsAudioLoop = NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
            local IsAudioLoopEnabled = NI.DATA.EventPatternAlgorithms.isAudioLoopEnabled(Pattern, Sound)

            if Index == PlayPosIdx then
                LEDState = LEDHelper.LS_FLASH
            elseif IsAudioLoop and IsAudioLoopEnabled then
                if StepHelper.getStepTime(PatternSegment, Index) < StepRangeWidth then
                    LEDState = LEDHelper.LS_BRIGHT
                end
            elseif not IsAudioLoop then
                local StepTime = StepHelper.getStepTime(PatternSegment, Index)
                local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
                local Length = StepHelper.getPatternEditorSnapInTicks()
                local Events = NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, Length,
                                                                             CONST_INVALID_NOTE)
                if not Events:empty() and StepTime < StepRangeWidth then
                    LEDState = LEDHelper.LS_BRIGHT
                end
            end

            LEDHelper.setLEDState(NI.HW.LED_PAD_1 + Index - 1, LEDState, Color)

        end

    else
        LEDHelper.turnOffLEDs(ControllerScriptInterface.PAD_LEDS)
    end

end

------------------------------------------------------------------------------------------------------------------------

local function toggleStep(PadIndex, Trigger, StepTime)

    -- only ok if pad was first pressed in step mode
    if StepHelper.PadVelocities[PadIndex] then
        local FixedVelocity = StepHelper.isFixedVelocity() and StepHelper.getFixedVelocityValue() or nil
        local Velocity = FixedVelocity or math.bound(math.floor(StepHelper.PadVelocities[PadIndex] * 128), 0, 127)
        StepHelper.toggleSoundEvent(Velocity, StepTime, Trigger)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.onPadEvent(PadIndex, Trigger, PadValue)

    if not NI.DATA.StateHelper.getFocusEventPattern(App) then
        NI.DATA.WORKSPACE.createPatternIfNeeded(App)
    end

    local StepTime = StepHelper.getStepTime(StepHelper.PatternSegment, PadIndex)
    local StepRangeWidth = StepHelper.getStepRangeWidth()

    if StepTime >= StepRangeWidth then
        return
    end


    if Trigger then

        if StepHelper.getHoldPadSize() == 0 then
            StepHelper.resetStepModulationHoldTime(true)
        end

        StepHelper.HoldingPads[PadIndex] = StepTime
        StepHelper.PadVelocities[PadIndex] = PadValue

    else

        StepHelper.HoldingPads[PadIndex] = nil

        -- toggle note on pad-release
        if StepHelper.isPadHoldTimerActive() then

            toggleStep(PadIndex, Trigger, StepTime)

        elseif NHLController:getPageStack():getTopPage() == NI.HW.PAGE_STEP_MOD then

            if StepHelper.getHoldPadSize() == 0 then
                NHLController:getPageStack():popPage() -- page goes back to Step page
            end
        end

    end


end

------------------------------------------------------------------------------------------------------------------------
-- toggleSoundEvent: Inserts or removes a note event depending on variables Trigger and RemoveNote.
-- Returns true if inserted a new note event to the sequence.
-- If there is no focused Pattern, a new Pattern will be created in EventPatternAccess.insertSoundEventStepMode()
------------------------------------------------------------------------------------------------------------------------

function StepHelper.toggleSoundEvent(Velocity, StepTime, Trigger, Group, Sound, Pitch, Accent)

    if StepTime < 0 then
        return false
    end

    if not Group then
        Group = NI.DATA.StateHelper.getFocusGroup(App)
    end

    if not Sound then
        Sound = NI.DATA.StateHelper.getFocusSound(App)
    end

    if not Sound or not Group then
        return false
    end

    NI.DATA.WORKSPACE.createPatternIfNeeded(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

        local AudioModule = Sound:getAudioModule()
        if AudioModule and Pattern then
            AudioLoopLength = NI.DATA.AudioModuleAlgorithms.getAudioLoopLength(AudioModule, Pattern)
            if StepTime < AudioLoopLength then
                NI.DATA.EventPatternAccess.toggleAudioLoop(App, Pattern, Group, Sound)
                return true
            end
        end

    else

        local Length = StepHelper.getPatternEditorSnapInTicks()
        local Note = Pitch or CONST_INVALID_NOTE
        local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
        local Events = Pattern and NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, Length, Note)
        local InsertEvent = Events == nil or Events:empty()

        if InsertEvent then

            local NotePitch = (Pitch and Pitch >= 0) and Pitch or Sound:getBaseKeyParameter():getValue()
            NI.DATA.EventPatternAccess.insertSoundEventStepMode(App, Pattern, Sound, EventTime, NotePitch, Velocity, Length)
            return true

        elseif Accent then

            local EventLength = Length - 1
            local AllEventsAccented = not NI.DATA.EventPatternTools.anyNoteEventHasLessVelocity(Pattern, Sound, EventTime,
                EventLength, Note, Velocity)

            if AllEventsAccented then
                NI.DATA.EventPatternAccess.removeSoundEventsStepMode(App, Pattern, Sound, Events)
            else
                NI.DATA.EventPatternTools.setNoteEventsVelocity(App, Pattern, Sound, EventTime, EventLength, Note, Velocity)
            end


        elseif not Trigger then
            -- remove notes
            NI.DATA.EventPatternAccess.removeSoundEventsStepMode(App, Pattern, Sound, Events)
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.isFixedVelocity()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getStepModeFixedVelocityEnabledParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.toggleFixedVelocity()

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if not Song then
        return
    end

    local Param = Song:getStepModeFixedVelocityEnabledParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getFixedVelocityValue()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getFixedVelocityParameter():getValue() or 127

end

------------------------------------------------------------------------------------------------------------------------
-- getPatternEditorSnapInTicks: Returns Pattern's step length set by the grid setting.
-- If UseSnapEnabledParameter is true and snapping is disabled, returns length as 16th notes.
------------------------------------------------------------------------------------------------------------------------

function StepHelper.getPatternEditorSnapInTicks(UseSnapEnabledParameter)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and (not UseSnapEnabledParameter or Song:getPatternEditorSnapEnabledParameter():getValue()) then
        return Song:getPatternEditorSnapInTicks(false)
    end

    -- 16ths
    return NI.UTILS.TICKS_PER_QUARTER / 4

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.resetStepModulationHoldData()

    StepHelper.HoldingPads = {}
    StepHelper.PadVelocities = {}

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getHoldPadSize()

    local Count = 0
    for _, Time in pairs(StepHelper.HoldingPads) do
        if Time ~= nil then
            Count = Count + 1
        end
    end

    return Count

end

------------------------------------------------------------------------------------------------------------------------
-- Returns a time based on the given pad and segment. To get the true pattern time, must be added to the PatternStart.
-- Note the step editor never shows steps outside of the pattern, i.e. before its start or after its end.
------------------------------------------------------------------------------------------------------------------------

function StepHelper.getStepTime(PatternSegment, PadIndex)

    return math.ceil(PadIndex - 1 + 16 * PatternSegment) * StepHelper.getPatternEditorSnapInTicks()

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getFirstStepTimeInSequence()

    local Grid = StepHelper.getPatternEditorSnapInTicks()
    return math.ceil(NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App) / Grid) * Grid

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getStepRangeWidth()

    local LengthCorrection = StepHelper.getFirstStepTimeInSequence() - NI.DATA.StateHelper.getFocusPatternActiveRangeBegin(App)
    return NI.DATA.StateHelper.getFocusPatternLength(App) - LengthCorrection

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getEventTimeFromStepTime(StepTime)

    return StepHelper.getFirstStepTimeInSequence() + StepTime

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getNumPatternSegments()

    local ViewRange = NI.DATA.StateHelper.getFocusPatternLength(App)
    return math.ceil((ViewRange / StepHelper.getPatternEditorSnapInTicks()) / 16)

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.increasePatternSegment(Delta, PatternGUI, Controller)

    local NumSegments = PatternGUI:getNumSegments()
    local CurSegment  = PatternGUI:getFocusedSegment()
    local NewSegment  = math.bound(CurSegment + Delta, 0, math.max(NumSegments-1, 0))

    PatternGUI:setFocusedSegment(NewSegment)

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getSnapParameterChanged()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        return Song:getPatternEditorSnapEnabledParameter():isChanged()
            or Song:getPatternEditorSnapParameter():isChanged()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.selectHoldingNotes(PatternSegment)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    if Song and Sound then
        local PadVector = VectorInt()

        for PadIdx, Time in pairs(StepHelper.HoldingPads) do
            local Index = PadIdx-1 + (PatternSegment * 16)
            PadVector:push_back(Index)
        end

        NI.DATA.EventPatternAccess.selectNoteEventsByHWPadIndexes(App, Song, Sound, PadVector)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getWheelModeText(Short)

    local WheelMode = NHLController:getJogWheelMode()

    if WheelMode == NI.HW.JOGWHEEL_MODE_VOLUME then
        return Short and "VEL" or "VELOCITY"
    elseif WheelMode == NI.HW.JOGWHEEL_MODE_SWING then
        return Short and "POS" or "POSITION"
    elseif WheelMode == NI.HW.JOGWHEEL_MODE_TEMPO then
        return "PITCH"
    else
        return ""
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.isRootNote(Note)

    if Note == nil or Note > 127 or Note < 0 then
        return false
    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local RootNote = Group and Group:getRootNoteParameter():getValue() or 0

    return (Note % 12) == (RootNote % 12)

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.setupStepModParameters(ParameterHandler)

    local ParamCache = App:getStateCache():getParameterCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local Parameters = {}
    local Values = {}
    local Names = {}
    local Sections = {}

    for Index = 1, 8 do
        local Parameter = Song and Song:getLevelTab() ~= NI.DATA.LEVEL_TAB_SONG and ParamCache:getGenericParameter(Index - 1, false)
        Sections[Index] = Parameter and Parameter:getSectionName()
        Parameter = (Parameter and Parameter:isAutomatable()) and Parameter or nil
        Parameters[Index] = Parameter

        Values[Index] = StepHelper.getModulationString(Parameter)
        if Values[Index] then
            Names[Index] = Parameter and string.upper(Parameter:getName())
        end
    end

    ParameterHandler:setParameters(Parameters)
    ParameterHandler:setCustomSections(Sections)
    ParameterHandler:setCustomNames(Names)
    ParameterHandler:setCustomValues(Values)

    ParameterHandler.NumPages = NI.DATA.ParameterCache.getNumPages(App)
    ParameterHandler.PageIndex = NI.DATA.ParameterCache.getFocusPage(App) + 1

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getModulationString(Parameter)

    -- set parameter event values if they are found
    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Song and Pattern then

        local Sequence = nil

        if Song:getLevelTab() == NI.DATA.LEVEL_TAB_SOUND then
            local Sound = NI.DATA.StateHelper.getFocusSound(App)
            Sequence = Sound and Pattern:getSoundSequence(Sound) or nil
        else
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            Sequence = Group and Pattern:getGroupSequence() or nil
        end

        if Sequence == nil then
            return
        end

        local ModEventTime = 0
        local LastStepPadIdx = 0

        for PadIdx, StepTime in pairs(StepHelper.HoldingPads) do
            if PadIdx > LastStepPadIdx then
                LastStepPadIdx = PadIdx
                ModEventTime = StepHelper.getEventTimeFromStepTime(StepTime)
            end
        end

        local ParamEvent = Parameter
            and NI.DATA.ModulationEditingAccess.getModulationParamEvent(Sequence, ModEventTime, Parameter)
            or nil

        if ParamEvent then
            return MaschineHelper.getModulationString(Parameter, ParamEvent:getModulationDelta())
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.setPatternSegment(Segment)

    StepHelper.PatternSegment = math.bound(Segment, 0, StepHelper.getNumPatternSegments() - 1)

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.updateFollowOffset()

    if StepHelper.FollowModeOn and App:getWorkspace():getPlayingParameter():getValue() then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        local PatternPos = NI.DATA.TransportAccess.calcPatternPosition(App)

        if Pattern and PatternPos ~= NPOS then
            local SegmentSize = StepHelper.getPatternEditorSnapInTicks() * 16
            StepHelper.setPatternSegment(math.floor((PatternPos - Pattern:getStartParameter():getValue()) / SegmentSize))
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.onControllerTimer(Controller)

    StepHelper.updateFollowOffset()

    -- Count holding pad time if a pad is being held, and eventually go into step modulation page
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)

    if not AudioLoop and StepHelper.isPadHoldTimerActive() then

        StepHelper.incrementPadHoldTime()

        if StepHelper.PadHoldTime >= StepHelper.MOD_STEP_HOLD_TIME then
            StepHelper.pushStepModPage(Controller)
            return true
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.incrementPadHoldTime()

    if StepHelper.getHoldPadSize() > 0 then
        StepHelper.PadHoldTime = StepHelper.PadHoldTime + 1
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.isPadHoldTimerActive()

    return StepHelper.PadHoldTime >= 0 and StepHelper.PadHoldTime < StepHelper.MOD_STEP_HOLD_TIME

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.resetStepModulationHoldTime(Activate)

    StepHelper.PadHoldTime = Activate and 0 or -1

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.pushStepModPage(Controller)

    local StepPageMod = Controller:getPage(NI.HW.PAGE_STEP_MOD)
    if StepPageMod then

        StepPageMod:setPatternSegment(StepHelper.PatternSegment)
        StepHelper.selectHoldingNotes(StepHelper.PatternSegment)
        NHLController:getPageStack():pushPage(NI.HW.PAGE_STEP_MOD)
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.canDecrementFocusSegment()

    return StepHelper.PatternSegment > 0

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.canIncrementFocusSegment()

    return StepHelper.PatternSegment+1 < StepHelper.getNumPatternSegments()

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.syncPatternSegmentToModel()

    if App:getStateCache():isFocusPatternChanged() then
        -- reset current step segment if pattern changes
        StepHelper.PatternSegment = 0
    else
        -- otherwise just make sure the segment is in bounds
        StepHelper.setPatternSegment(StepHelper.PatternSegment)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepHelper.getAccessibleStepAnnouncementByPadIndex(PadIdx)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if not Sound then
        return ""
    end

    local StepTime = StepHelper.getStepTime(StepHelper.PatternSegment, PadIdx)
    if StepTime >= StepHelper.getStepRangeWidth() then
        return ""
    end

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

        local IsAudioLoopEnabled = Pattern and NI.DATA.EventPatternAlgorithms.isAudioLoopEnabled(Pattern, Sound) or false
        return IsAudioLoopEnabled and "Remove Audio Loop" or "Set Audio Loop"

    else

        local Length = StepHelper.getPatternEditorSnapInTicks()
        local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
        local Events = Pattern
            and NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, Length, CONST_INVALID_NOTE)
        local InsertEvent = Events == nil or Events:empty()
        return InsertEvent and "Insert Event" or "Remove Event"
    
    end

end
