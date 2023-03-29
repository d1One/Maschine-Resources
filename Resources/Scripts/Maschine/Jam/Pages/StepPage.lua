------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Maschine/Jam/Pages/PadModePage"
require "Scripts/Maschine/Jam/Helper/JamStepHelper"
require "Scripts/Maschine/Jam/Helper/StepEdit"
require "Scripts/Maschine/Jam/Helper/Jam16VelocityMode"
require "Scripts/Shared/Helpers/StepHelper"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/GridHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
StepPage = class( 'StepPage', PageJam )

------------------------------------------------------------------------------------------------------------------------

StepPage.MAX_NUM_SOUNDS = 16
StepPage.MAX_NOTE_VALUE = 128
StepPage.ROWS_PER_SOUND_PIANO_ROLL = 1 -- just like 8 sound mode
StepPage.ACCENTED_VELOCITY = 127
StepPage.PAD_HOLD_TIME = 12

------------------------------------------------------------------------------------------------------------------------

function StepPage:__init(Controller)

    PageJam.__init(self, "StepPage", Controller)

     -- LEDs related to this page
    self.PageLEDs = { NI.HW.LED_STEP }

    -- OSO type
    self.GetOSOTypeFn = function() return PadModeHelper.getKeyboardMode() and NI.HW.OSO_SCALE or NI.HW.OSO_NONE end

    self.Is16VelocityModeEnabled =
        function()
            return not PadModeHelper.getKeyboardMode() and not JamHelper.isAccentEnabled() and self:isStepPageSingleSound()
        end

    self.RootNote = PadModeHelper.getRootNote()
    self.CurrentBank = PadModeHelper.getCurrentBank()
    self.CurrentScale = PadModeHelper.getCurrentScale()
    self.CurrentGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
    self.NoteArray = JamStepHelper.calcNoteArray()

    -- The number of accessible sounds on the matrix. Default is 1 sounds; other modes are 4 and 8 sounds.
    -- It's basically the number of sounds per page
    self.SoundMode = 1

    -- The sound that is mapped to the first row of the matrix. 0-indexed
    self.SoundOffset = 0

    self.RowOffsets = {}

    self.ModTimeDeltaMap = TickFloatMap()

    -- Needed for telling base class not to handle page button release,
    -- i.e. don't leave step page when step button & wheel are used together.
    self.HandleStepButtonRelease = false

    -- Step sequencer page data. 1-indexed
    self.NumPages = 1
    self.FocusedPage = 1
    self.PageDataOnStepButton = {}
    self.PendingRemoveEvents = {}

    self.PrevAccentState = false

    -- Used for Step Modulation and Quick Edit
    self.PadHoldCount = 0

    -- Step Modulation and QuickEdit object
    self.StepEdit = StepEdit(self.Controller)
    self.CanDoQuickEdit = false

    self.LEDBlinker = LEDBlinker(JamControllerBase.DEFAULT_LED_BLINK_TIME * 2)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:hasDuplicateMode()

    return self:isStepPageSingleSound()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onShow(Show)

    if not Show then
        self:resetPendingRemoveEvents()
        self:resetStepModulationAndQuickEdit()
    end

    self:updateControllerPadMode(Show==false and NI.HW.PAD_MODE_DEFAULT)

    -- call base
    PageJam.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:resetHoldTimer()

    self.PadHoldCount = 0

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onTimer()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    if AudioLoop then
        return
    end

    -- Count holding pad time if a pad is being held, and eventually go into step modulation mode
    if self.StepEdit:getHoldingPadsSize() > 0 then

        self.PadHoldCount = self.PadHoldCount + 1

        if self.PadHoldCount > StepPage.PAD_HOLD_TIME then

            if not JamHelper.isStepModulationModeEnabled() then
                self.StepEdit:setStepModulationMode(true)
                self.LEDBlinker:reset()
            end
            self:resetHoldTimer()
            self:selectHoldingNotes()
            return

        end

        self.Controller.Timer:setTimer(self, 1)

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onShiftAButton()

    JamHelper.toggleStepModeFollowPlayhead()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:resetPendingRemoveEvents()

    self.PendingRemoveEvents = {}

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getNumNotesPerOctave()

    return #self.NoteArray + 1

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:numNotesOnCurrentScale()

    local NumberPerOctave = self:getNumNotesPerOctave()

    return JamStepHelper.NUM_OCTAVES * NumberPerOctave + JamStepHelper.getNumNotesOnLastOctave()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getNearestRow(Note)

    local NoteCount = self:numNotesOnCurrentScale() - 1

    for Row = 0, NoteCount do

        local CurrentNote = self:getNote(Row)

        if CurrentNote == Note then

            return Row

        elseif CurrentNote > Note then

            local PreviousNote = Row > 0 and self:getNote(Row - 1) or 0
            return math.abs(Note - PreviousNote) < math.abs(Note - CurrentNote) and Row - 1 or Row

        end

    end

    return NoteCount

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:handleGlideStepLEDs(Pattern, Time)

    local Parameter = self:findGlideParameter()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Sequence = Sound and Pattern:getSoundSequence(Sound) or nil

    if not Parameter or not Sequence then
        return false, false, 0, false, false
    end

    local ColorIndex = (Sound:getColorParameter():getValue() + 3) % 16
    local ParamEvent = Parameter and NI.DATA.ModulationEditingAccess.getModulationParamEvent(Sequence, Time, Parameter) or nil
    return false, ParamEvent and ParamEvent:getModulationDelta() > 0, ColorIndex, false, false

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updatePadLEDs()

    self:updateSoundOffset()

    local KeyboardMode = PadModeHelper.getKeyboardMode()
    local QuickEditMode = JamHelper.getQuickEditMode()

    if KeyboardMode then
        -- Need to show root notes even when there is no pattern
        self:updateScale()
    end

    self.LEDBlinker:tick()

    LEDHelper.updateMatrixLedsWithFunctor(self.Controller.PAD_LEDS,
        JamControllerBase.NUM_PAD_COLUMNS,
        JamControllerBase.NUM_PAD_ROWS,
        function(Row, Column)

            if QuickEditMode == NI.HW.QUICK_EDIT_LENGTH then
                return self:getMatrixLEDStateQuickEditLength(Row, Column)
            elseif KeyboardMode then
                return self:getMatrixLEDStateKeyboard(Row, Column)
            else
                return self:getMatrixLEDStateStep(Row, Column)
            end
        end)

    -- Display the 16 Sounds in the bottom right if only 1 Sound is showing
    if self:isStepPageSingleSound() then
        JamHelper.updatePadLEDsSounds(self.Controller, false)
    end

    -- call base
    PageJam.updatePadLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getMatrixLEDStateKeyboard(Row, Column)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)

    local Selected, Enabled, Flashing = false, false, false
    local Color = Sound and Sound:getColorParameter():getValue()

    if Sound then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local StepTime = self:getStepTime(Row, Column)
        local Note = self:getNoteFromRow(Row)
        local IsRootNote = StepHelper.isRootNote(Note)
        local IsPlayHeadAbove = self:getPlayHeadPosition(Row) == Column

        if NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound) then

            local AudioModule = Sound:getAudioModule()
            local AudioLoopEnabled =
                Pattern and NI.DATA.EventPatternAlgorithms.isAudioLoopEnabled(Pattern, Sound) or false
            local AudioLoopLength =
                (Pattern and AudioModule) and NI.DATA.AudioModuleAlgorithms.getAudioLoopLength(AudioModule, Pattern) or 0

            Enabled = AudioLoopEnabled and StepTime < AudioLoopLength
            Selected = IsPlayHeadAbove
            Flashing = IsPlayHeadAbove

        elseif Song and Pattern and Note and Note >= 0 then

            local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)

            if self:glideLaneActive() and Row == 1 then
                return self:handleGlideStepLEDs(Pattern, EventTime)
            end

            local EventLength = StepHelper.getPatternEditorSnapInTicks() - 1

            local Events = NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, EventLength, Note)

            local EventInPattern = StepTime < Pattern:getLengthParameter():getValue()

            local AccentVelocity = Song:getAccentVelocityJamParameter():getValue()
            local AllEventsAccented =
                not NI.DATA.EventPatternTools.anyNoteEventHasLessVelocity(Pattern, Sound, EventTime, EventLength, Note, AccentVelocity)
            local EventsAvailable = not Events:empty()

            Selected = EventsAvailable and AllEventsAccented
            Flashing = IsPlayHeadAbove
            Enabled = EventsAvailable or Flashing

            if IsRootNote and not IsPlayHeadAbove and not EventsAvailable then
                Color = LEDColors.WHITE
                Enabled = EventInPattern
                Selected = EventInPattern
            end

        else

            Color = IsRootNote and LEDColors.WHITE or Color
            Enabled = IsRootNote
            Selected = IsRootNote

        end

        if JamHelper.isStepModulationModeEnabled() and self.StepEdit:isPadHeldAndInPattern(Row, Column) then
            Selected = self.LEDBlinker:getBlinkStateNoTick() == LEDHelper.LS_BRIGHT
            Color = Sound and Sound:getColorParameter():getValue()
        end

    end

    return Selected, Enabled, Color, Flashing, true -- DisableFlashTimer

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getMatrixLEDStateStep(Row, Column)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = self:isRowHandled(Row) and NI.DATA.StateHelper.getFocusEventPattern(App)
    local Group = Pattern and NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds()
    local Sound = Sounds and Sounds:at(self:getSoundIndexFromRowIndex(Row))

    local Selected, Enabled, Flashing = false, false, false
    local Color = Sound and Sound:getColorParameter():getValue() or nil

    if Song and Pattern and Sound then

        local StepTime = self:getStepTime(Row, Column)
        local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
        local EventLength = StepHelper.getPatternEditorSnapInTicks() - 1
        local Events = NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, EventLength, CONST_INVALID_NOTE)
        local IsPlayHeadAbove = self:getPlayHeadPosition(Row) == Column
        local AccentVelocity = Song:getAccentVelocityJamParameter():getValue()
        local AllEventsAccented =
            not NI.DATA.EventPatternTools.anyNoteEventHasLessVelocity(Pattern, Sound, EventTime, EventLength, -1, AccentVelocity)

        local AudioModule = Sound:getAudioModule()
        if AudioModule and AudioModule:isLoopMode() then
                AudioLoopEnabled = NI.DATA.EventPatternAlgorithms.isAudioLoopEnabled(Pattern, Sound)
                AudioLoopLength = NI.DATA.AudioModuleAlgorithms.getAudioLoopLength(AudioModule, Pattern)
                Enabled = AudioLoopEnabled and StepTime < AudioLoopLength
                Selected = IsPlayHeadAbove
        else
            Enabled = Events and not Events:empty()
            Selected = (Enabled and AllEventsAccented) or IsPlayHeadAbove
        end

        Flashing = IsPlayHeadAbove

        if JamHelper.isStepModulationModeEnabled() and self.StepEdit:isPadHeldAndInPattern(Row, Column) then
            Selected = self.LEDBlinker:getBlinkStateNoTick() == LEDHelper.LS_BRIGHT
        end

    end

    return Selected, Enabled, Color, Flashing, true -- disable flash timer

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getMatrixLEDStateQuickEditLength(Row, Column)

    local KeyboardMode = PadModeHelper.getKeyboardMode()
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Sequence = Sound and NI.DATA.StateHelper.getFocusSoundSequence(App)
    local IsHandled = self:isRowHandled(Row)

    if not KeyboardMode then
        IsHandled = IsHandled and NI.DATA.StateHelper.getFocusSoundIndex(App) == self:getSoundIndexFromRowIndex(Row)
    end

    if not Sequence or not IsHandled then
        return
    end

    local Note = KeyboardMode and self:getNoteFromRow(Row) or CONST_INVALID_NOTE
    local StepTime = self:getStepTime(Row, Column)
    local EventTime = StepHelper.getEventTimeFromStepTime(StepTime)
    local EventLength = StepHelper.getPatternEditorSnapInTicks() - 1
    local Events = NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, EventLength, Note)

    local Color = LEDColors.WHITE
    local Enabled, Selected, Flashing = false, false, false

    Enabled = NI.DATA.SequenceAlgorithms.hasSelectedNoteAtRangeEnd(Sequence, -1, EventTime + EventLength, EventTime, Note)

    if Events and not Events:empty() then

        Enabled = true
        Color = Sound:getColorParameter():getValue()

        for PadId, PadInfo in pairs(self.StepEdit.HoldingPads) do

            if PadInfo[1] == Row and PadInfo[2] == Column and PadInfo[3] >= StepTime then
                Selected = self.LEDBlinker:getBlinkStateNoTick() == LEDHelper.LS_BRIGHT
            elseif PadInfo[3] < StepTime and PadInfo[4] > StepTime then
                if not KeyboardMode or PadInfo[1] == Row then
                    Color = LEDColors.WHITE
                end
            end

        end

    end

    return Selected, Enabled, Color, Flashing, true -- disable flash timer

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:handleGlideStep(Row, Column)

    local Parameter = self:findGlideParameter()
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if not Parameter or not Pattern then
        return
    end

    local EventTime = StepHelper.getEventTimeFromStepTime(self:getStepTime(Row, Column))
    local Value = 1.0
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Sequence = Sound and Pattern:getSoundSequence(Sound) or nil

    local ParamEvent = Parameter and Sequence and NI.DATA.ModulationEditingAccess.getModulationParamEvent(Sequence, EventTime, Parameter)
    if ParamEvent and ParamEvent:getModulationDelta() > 0 then
        Value = -ParamEvent:getModulationDelta()
    end

    self.ModTimeDeltaMap:clear()
    STLHelper.setKeyValue(self.ModTimeDeltaMap, EventTime, Value)
    NI.DATA.ModulationEditingAccess.setSoundModulationStep(App, self.ModTimeDeltaMap, Parameter, false)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onDPadButton(Button, Pressed)

    if not Pressed then
        return
    end

    -- disable dpad in step-mod / quick-edit mode
    if JamHelper.isStepModulationModeEnabled() then
        return
    end

    if Button == NI.HW.BUTTON_DPAD_DOWN or Button == NI.HW.BUTTON_DPAD_UP then

        if PadModeHelper.getKeyboardMode() then
            self:incrementRowOffset(Button == NI.HW.BUTTON_DPAD_DOWN)
        else
            self:incrementSoundOffset(Button == NI.HW.BUTTON_DPAD_DOWN)
        end

    elseif Button == NI.HW.BUTTON_DPAD_LEFT or Button == NI.HW.BUTTON_DPAD_RIGHT then

        local Inc = Button == NI.HW.BUTTON_DPAD_LEFT and -1 or 1
        if self.Controller:isShiftPressed() then
            Inc = Inc * self.NumPages -- Shift modifier jumps to first or last page
        end

        self:setFocusedPage(self.FocusedPage + Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:incrementRowOffset(Upward)

    local TotalNumberOfNotes = self:numNotesOnCurrentScale()
    local Offset = self.Controller:isShiftPressed() and 1 or self:getNumNotesPerOctave()
    local RowOffset = self:getRowOffset()
    local Value

    local OffsetCorrectionGlide = self:glideLaneActive() and 1 or 0

    if Upward then
        Value = RowOffset - Offset > self:getNumberOfRows()
            and RowOffset - Offset
            or  self:getNumberOfRows() + OffsetCorrectionGlide
    else
        Value = RowOffset + Offset < TotalNumberOfNotes
            and RowOffset + Offset
            or  TotalNumberOfNotes + OffsetCorrectionGlide
    end

    self:setRowOffset(Value)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateDPadLEDs()

    local OffsetCorrectionGlide = self:glideLaneActive() and 1 or 0
    local UpEnabled, DownEnabled, LeftEnabled, RightEnabled = false, false, false, false

    if not JamHelper.isStepModulationModeEnabled() then -- disable dpad in step-mod / quick-edit mode

        if PadModeHelper.getKeyboardMode() then
            UpEnabled = self:getRowOffset() < self:numNotesOnCurrentScale() + OffsetCorrectionGlide
            DownEnabled = self:getRowOffset() > JamControllerBase.NUM_PAD_COLUMNS + OffsetCorrectionGlide
        else
            UpEnabled = self.SoundOffset > 0
            DownEnabled = self.SoundOffset < self:getMaxSoundOffset()
        end

        LeftEnabled = self.FocusedPage > 1
        RightEnabled = self.FocusedPage < self.NumPages

    end

    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_UP, NI.HW.BUTTON_DPAD_UP, UpEnabled)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_DOWN, NI.HW.BUTTON_DPAD_DOWN, DownEnabled)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_LEFT, NI.HW.BUTTON_DPAD_LEFT, LeftEnabled)
    LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_DPAD_RIGHT, NI.HW.BUTTON_DPAD_RIGHT, RightEnabled)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getLowerRootNoteRow()

    local LowerRow = JamControllerBase.NUM_PAD_ROWS

    for Row = 1, JamControllerBase.NUM_PAD_ROWS do
        local Note = self:getNoteFromRow(Row)
        if StepHelper.isRootNote(Note) then
            LowerRow = Row
        end
    end

    return LowerRow

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateScale()

    local NewRootNote   = PadModeHelper.getRootNote()
    local NewBank       = PadModeHelper.getCurrentBank()
    local NewScale      = PadModeHelper.getCurrentScale()
    local NewGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    -- We keep our own state because checking if RootNoteParam:isChanged would be true for too long
    -- and this functions is called from updatePadLeds

    if self.CurrentScale ~= NewScale or self.RootNote ~= NewRootNote or self.CurrentBank ~= NewBank then

        -- When the Root note changes, then we follow with the row offset.
        local RootNoteRow = self:getLowerRootNoteRow()
        local RootNoteDelta = NewRootNote - self.RootNote
        local NoteFromRow   = self:getNoteFromRow(RootNoteRow)
        local NewNoteOffset = NoteFromRow and NoteFromRow + RootNoteDelta or 0
        NewNoteOffset = math.bound(NewNoteOffset, 0, StepPage.MAX_NOTE_VALUE)

        self.NoteArray = JamStepHelper.calcNoteArray()

        -- If the scale or the root note changed in the same group, we need to re-map the previous note
        -- If the group changed, we need to use the one we stored for the current group
        if self.CurrentGroupIndex == NewGroupIndex then

            local NewRowOffset = self:getNearestRow(NewNoteOffset) + RootNoteRow
            self:setRowOffset(math.bound(NewRowOffset, 0, self:numNotesOnCurrentScale()))

        end

        -- Update state
        self.RootNote          = NewRootNote
        self.CurrentBank       = NewBank
        self.CurrentScale      = NewScale
        self.CurrentGroupIndex = NewGroupIndex

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onPageButton(Button, PageID, Pressed)

    if PageID == NI.HW.PAGE_STEP and not PadModeHelper.getKeyboardMode() then

        if Pressed and self.Controller:isShiftPressed() then -- Toggle keyboard mode on
            PadModeHelper.setKeyboardMode(true)
            self.Controller.CloseOnPageButtonRelease[NI.HW.PAGE_STEP] = false -- avoid Controller handling the release
            self.Controller.ParameterHandler:showOSO(NI.HW.OSO_SCALE) -- Show Scale OSO
        end

        if Pressed then

            -- Save some page data
            self.PageDataOnStepButton = {self.SoundMode, self.FocusedPage}
            return false

        elseif self.Controller:isButtonPressed(NI.HW.BUTTON_CLEAR) and self.SoundMode == 1 then

            -- handle delete under playhead case
            self.Controller.CloseOnPageButtonRelease[NI.HW.PAGE_STEP] = false

        elseif self.HandleStepButtonRelease then

            -- Reset flags so we don't ignore the next release
            self.HandleStepButtonRelease = false
            self.Controller.CloseOnPageButtonRelease[PageID] = true

            -- Preserve focused page if sound mode changed (changing focused page) and came back to original mode.
            if self.SoundMode == self.PageDataOnStepButton[1] and self.FocusedPage ~= self.PageDataOnStepButton[2] then
                self:setFocusedPage(self.PageDataOnStepButton[2])
            end

            return true

        end

    end

    if not Pressed and JamHelper.isJamOSOVisible() then
        -- Start OSO timeout when button is released
        self.Controller.ParameterHandler:startOSOTimeout()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- Accessors
------------------------------------------------------------------------------------------------------------------------

function StepPage:getNumberOfRows()

    return self:glideLaneActive() and JamControllerBase.NUM_PAD_ROWS - 1 or JamControllerBase.NUM_PAD_ROWS

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getRowOffset()

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    if not self.RowOffsets[GroupIndex] then

        return self:getNearestRow(PadModeHelper.getRootNote()) + self:getNumberOfRows()

    end

    return self.RowOffsets[GroupIndex]

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:setRowOffset(Value)

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    if not self.RowOffsets[GroupIndex] then
        self.RowOffsets[GroupIndex] = {}
    end

    if self.RowOffsets[GroupIndex] ~= Value then
        self:resetPendingRemoveEvents()
    end

    self.RowOffsets[GroupIndex] = Value

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:isStepPageSingleSound()

    return self.SoundMode == 1 and not PadModeHelper.getKeyboardMode()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getMaxSoundOffset()

    return StepPage.MAX_NUM_SOUNDS - self.SoundMode

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getSoundOffsetByIndex(Index)

    return math.floor(Index / self.SoundMode) * self.SoundMode

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getRowsPerSound()

    -- When in single-sound mode the step grid is shared with the 16 sound triggers on the bottom right of the matrix.
    -- That means the top 4 rows are for step editing and the bottom 4 rows are for Sound triggers.

    return PadModeHelper.getKeyboardMode()
        and StepPage.ROWS_PER_SOUND_PIANO_ROLL
        or  math.min(math.floor(JamControllerBase.NUM_PAD_ROWS / self.SoundMode), 4)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getNumPageBanks()

    return math.ceil(self.NumPages / 8)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getFocusedPageBank()

    return math.ceil(self.FocusedPage / 8)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getPlayHeadPosition(RowIndex)

    local RowsPerSnd = self:getRowsPerSound()
    local VertOffset = (RowIndex-1) % RowsPerSnd
    local PageOffset = (RowsPerSnd * JamControllerBase.NUM_PAD_COLUMNS) * (self.FocusedPage-1)

    return App:getStateCache():playPositionStepEditor() + 1 - (VertOffset * JamControllerBase.NUM_PAD_COLUMNS) - PageOffset

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:findGlideParameter()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local Slot = Sound and Sound:getChain():getSlots():at(0)
    local Module = Slot and Slot:getModule()
    local ModuleID = Module and Module:getInfo():getId()

    -- Glide parameter is the first parameter on page 2
    return ModuleID == NI.DATA.ModuleInfo.ID_BASSSYNTH and Module:getParameter(0, 1, 0) or nil

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:glideLaneActive()

    local GlideParam = self:findGlideParameter()
    return PadModeHelper.getKeyboardMode() and GlideParam

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getGlideRowIndex(Row)

    if self:glideLaneActive() then
        local HalfRowIndex = math.floor(Row / 2)
        return Row % 2 ~= 0 and HalfRowIndex + 1 or HalfRowIndex
    end

    return Row

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getStepTime(Row, Column)

    local PatternPos = self:getPatternPositionFromPadIndex(Row, Column)

    if PatternPos >= 0 then
        return PatternPos * StepHelper.getPatternEditorSnapInTicks()
    end

    return -1

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getPatternPositionFromPadIndex(Row, Column)

    local PatternPos = -1

    if self:isRowHandled(Row) then

        local CurrentRow = self:getGlideRowIndex(Row)

        local RowsPerSnd = self:getRowsPerSound()
        local Pos = (Column-1) + ((CurrentRow-1) % RowsPerSnd) * JamControllerBase.NUM_PAD_COLUMNS        -- flatten rows
        local PageOffset = (RowsPerSnd * JamControllerBase.NUM_PAD_COLUMNS) * (self.FocusedPage-1) -- num pad positions before current page

        PatternPos = PageOffset + Pos
    end

    return PatternPos

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getEventsFromPadIndex(Row, Col)

    local Sound = self:getSoundFromRow(Row)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Sound and Pattern then
        local EventTime = StepHelper.getEventTimeFromStepTime(self:getStepTime(Row, Col))
        local Note = self:getNoteFromRow(Row)
        local Length = StepHelper.getPatternEditorSnapInTicks()

        if not PadModeHelper.getKeyboardMode() or (Note and Note >= 0) then
            return NI.DATA.EventPatternAccess.getSoundNoteEvents(Pattern, Sound, EventTime, Length, Note)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getSoundFromRow(Row)

    if PadModeHelper.getKeyboardMode() then

        return NI.DATA.StateHelper.getFocusSound(App)

    elseif self:isRowHandled(Row) then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sounds = Group and Group:getSounds()
        return Sounds and Sounds:at(self:getSoundIndexFromRowIndex(Row)) or nil

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getNoteFromRow(Row)

    if not PadModeHelper.getKeyboardMode() or not self:isRowHandled(Row) then

        return -1

    else

        local Index = self:getRowOffset() - Row
        if Index >= 0 and Index < self:numNotesOnCurrentScale() then
            return self:getNote(Index)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getNote(Index)

    local NumNotesPerOctave = self:getNumNotesPerOctave()
    local Octave = math.floor(Index / NumNotesPerOctave)
    local Offset = Octave * JamStepHelper.NUM_NOTES_PER_OCTAVE

    return Offset + self.NoteArray[Index % NumNotesPerOctave]

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:isRowHandled(Row)

    local MaxRow = self:isStepPageSingleSound() and 4 or 8
    return Row > 0 and Row <= MaxRow

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getSoundIndexFromRowIndex(RowIndex)

    return math.floor((RowIndex - 1) / self:getRowsPerSound()) + self.SoundOffset

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getVelocityValue(Sound)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song and Sound then
        if JamHelper.isAccentEnabled() then
            return Song:getAccentVelocityJamParameter():getValue()
        else
            local Velocity = Sound:getVelocityJamParameter():getValue()
            return Velocity > 0 and Velocity or Song:getDefaultVelocityJamParameter():getValue()
        end
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:getPlayingPageIndex()

    local TicksPerPage = self:getRowsPerSound() * 8 * StepHelper.getPatternEditorSnapInTicks()
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local PatternStart = Pattern and Pattern:getStartParameter():getValue() or 0
    local PatternPos = NI.DATA.TransportAccess.calcPatternPosition(App) - PatternStart

    return math.floor(PatternPos / TicksPerPage) + 1

end

------------------------------------------------------------------------------------------------------------------------
-- Updaters
------------------------------------------------------------------------------------------------------------------------

function StepPage:onCustomProcess(ForceUpdate)

    self:updateScale()

    -- should be done first as many things depend on self.SoundOffset
    self:updateSoundOffset()

    -- If the keyboard mode or group or sound changed, reset events to be removed on pad release
    local StateCache = App:getStateCache()
    if StateCache:isFocusGroupChanged()
        or PadModeHelper.isKeyboardModeChanged()
        or (PadModeHelper.getKeyboardMode() and StateCache:isFocusSoundChanged()) then

        self:resetPendingRemoveEvents()
    end

    -- update pad mode
    self:updateControllerPadMode()

    -- call base
    PageJam.onCustomProcess(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateControllerPadMode(PadMode)

    if not PadMode then -- Set default if argument not given
        PadMode = self:isStepPageSingleSound() and NI.HW.PAD_MODE_SOUND or NI.HW.PAD_MODE_DEFAULT
    end

    NHLController:setPadMode(PadMode)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateSoundOffset()

    local Index = NI.DATA.StateHelper.getFocusSoundIndex(App)

    self:setSoundOffset(self:getSoundOffsetByIndex(Index))

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateFocusedPage()

    local FirstStepTime  = StepHelper.getFirstStepTimeInSequence()
    local LastStepTime   = FirstStepTime + StepHelper.getStepRangeWidth() - 1
    local TicksPerStep   = StepHelper.getPatternEditorSnapInTicks()
    local TicksPerPage   = TicksPerStep * self:getRowsPerSound() * JamControllerBase.NUM_PAD_COLUMNS

    local NewNumPages = math.ceil(StepHelper.getStepRangeWidth() / TicksPerPage)
    local FocusPage = self.FocusedPage

    if JamHelper.isStepModeFollowPlayhead() and self.StepEdit:getHoldingPadsSize() == 0 then

        FocusPage = self:getPlayingPageIndex()

    elseif JamHelper.getQuickEditMode() == NI.HW.QUICK_EDIT_LENGTH then

        local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)

        if Sequence then
            local NoteStart = NI.DATA.SequenceAlgorithms.getFirstSelectedNoteEventInRangeTime(Sequence, FirstStepTime, LastStepTime)
            local NoteLength = NI.DATA.SequenceAlgorithms.getFirstSelectedNoteEventInRangeLength(Sequence, FirstStepTime, LastStepTime)
            local InvalidTick = NI.DATA.SequenceAlgorithms.invalidTick()

            if NoteStart ~= InvalidTick then
                FocusPage = math.floor((NoteStart + NoteLength - TicksPerStep) / TicksPerPage) + 1
            end
        end

    elseif JamHelper.isStepModulationModeEnabled() then

        local Sequence = NI.DATA.StateHelper.getFocusSoundSequence(App)

        if Sequence then
            local NoteStart = NI.DATA.SequenceAlgorithms.getFirstSelectedNoteEventInRangeTime(Sequence, FirstStepTime, LastStepTime)
            local InvalidTick = NI.DATA.SequenceAlgorithms.invalidTick()

            if NoteStart ~= InvalidTick then
                FocusPage = math.floor(NoteStart / TicksPerPage) + 1
            end
        end

    elseif NewNumPages ~= self.NumPages and self.PatternTicksOffset then

        FocusPage = math.floor(self.PatternTicksOffset / TicksPerPage) + 1

    end

    self.NumPages = NewNumPages
    self:setFocusedPage(math.bound(FocusPage, 1, self.NumPages))
    self.PatternTicksOffset = (self.FocusedPage-1) * TicksPerPage

end

------------------------------------------------------------------------------------------------------------------------

-- Show the 1/4/8 sound mode selector when holding the step button
function StepPage:showModeSelector()

    return not PadModeHelper.getKeyboardMode() and self.Controller:isButtonPressed(NI.HW.BUTTON_STEP)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateSceneButtonLEDs()

    self:updateFocusedPage()

    local LedFunctor = nil
    local ColorFunctor = function(Index) return LEDColors.WHITE end
    local FlashFunctor = function(Index) return false end

    if self:showModeSelector() then

        -- Sound-mode Selection: Bright leds on 1, 4, 8 buttons
        LedFunctor = function(Index)
            return Index == self.SoundMode, (Index == 1 or Index == 4 or Index == 8)
        end

    elseif self.Controller:isButtonPressed(NI.HW.BUTTON_SELECT) or self.Controller:isButtonPressed(NI.HW.BUTTON_GRID) then

        -- Scene Selection: Bright leds for focused Scene, dim for available Scenes, both in Scene's color
        -- This is handled by the SELECT page
        -- Also ignore GRID here, handled by GridQuickEdit
        return

    elseif self.Controller:isShiftPressed() then

        -- Page Bank Selection: Bright led for current bank, dim leds for available banks
        LedFunctor = function(Index)
            return Index == self:getFocusedPageBank(), Index <= self:getNumPageBanks()
        end

    else

        -- Page Selection (default mode): Bright led for current page, dim leds for available pages, in current pattern color
        LedFunctor = function(Index)
            local ScaledIndex = Index + ((self:getFocusedPageBank() - 1) * 8)
            return self.NumPages > 0 and ScaledIndex == self.FocusedPage, ScaledIndex <= self.NumPages
        end

        ColorFunctor = function()
            local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
            local ColorIdx = Pattern and Pattern:getColorParameter():getValue() or nil
            return ColorIdx
        end

        FlashFunctor = function(Index)
            local ScaledIndex = Index + ((self:getFocusedPageBank() - 1) * 8)
            return self:getPlayingPageIndex() == ScaledIndex and self.FocusedPage ~= ScaledIndex, true
        end

    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0, LedFunctor, ColorFunctor, FlashFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updateAccentLED()

    if self.Controller:isSwitchModifierPairPressed(NI.HW.BUTTON_SHIFT, NI.HW.BUTTON_SELECT) then
        LEDHelper.setLEDState(NI.HW.LED_SELECT, LEDHelper.LS_BRIGHT)
    else
        LEDHelper.setLEDState(NI.HW.LED_SELECT, JamHelper.isAccentEnabled() and LEDHelper.LS_DIM or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:updatePageLEDs(LEDState)

    PageJam.updatePageLEDs(self, LEDState)

    if LEDState == LEDHelper.LS_OFF then
        LEDHelper.setLEDState(NI.HW.LED_SELECT, LEDHelper.LS_OFF)
    else
        self:updateAccentLED()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Event handling
------------------------------------------------------------------------------------------------------------------------

function StepPage:toggleStep(Sound, Column, Row, Note)

    local StepTime = self:getStepTime(Row, Column)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    StepHelper.toggleSoundEvent(self:getVelocityValue(Sound), StepTime, false, Group, Sound, Note,
                                JamHelper.isAccentEnabled())

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onPadButton(Column, Row, Pressed)

    PageJam.onPadButton(self, Column, Row, Pressed)

    local Sound = self:getSoundFromRow(Row)
    local Note = self:getNoteFromRow(Row)

    local KeyboardMode = PadModeHelper.getKeyboardMode()
    local IsGlideLane = KeyboardMode and Row == 1

    if self:isRowHandled(Row) and self:glideLaneActive() and Pressed and IsGlideLane then
        self:handleGlideStep(Row, Column)
        return
    end

    if not Note then
        return
    end

    local IsStepModulationActive = JamHelper.isStepModulationModeEnabled()

    if Pressed then

        -- If in single sound mode, handle the sound pad if one was pressed
        if self:isStepPageSingleSound() then
            local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)
            if SoundIndex then
                if self.Duplicate:isEnabled() then
                    return self.Duplicate:onSoundDuplicate(SoundIndex)
                elseif self.Controller:isClearActive() then
                    MaschineHelper.removeSound(SoundIndex)
                end

                return JamHelper.focusSoundByIndex(SoundIndex, self.Controller)
            end
        end

        -- Remember note event to toggle on release
        table.insert(self.PendingRemoveEvents, {Column, Row})

    else -- Release

        for i, PadIndexPair in pairs(self.PendingRemoveEvents) do
            if PadIndexPair[1] == Column and PadIndexPair[2] == Row then
                self.PendingRemoveEvents[i] = {}

                if not IsStepModulationActive then
                    self:toggleStep(Sound, Column, Row, Note)
                end

            end
        end

    end

    local SoundIndex = self:getSoundIndexFromRowIndex(Row)
    local HoldingPadsSize = self.StepEdit:getHoldingPadsSize()
    local StepModRow = self.StepEdit:getRowFromHoldingPads()
    local HoldingPadsSoundIndex = StepModRow > 0 and self:getSoundIndexFromRowIndex(StepModRow)

    -- Set step modulation held pads (only for held pads from the same sound)
    if self:isRowHandled(Row)
        and (HoldingPadsSize == 0 or HoldingPadsSoundIndex == SoundIndex
        or  PadModeHelper.getKeyboardMode()) then

        local StepTime = self:getStepTime(Row, Column)
        self.StepEdit:updateHoldingPads(Row, Column, StepTime, Pressed)
        HoldingPadsSize = self.StepEdit:getHoldingPadsSize()

        if Pressed and not PadModeHelper.getKeyboardMode() then
            JamHelper.focusSoundByIndex(SoundIndex + 1, self.Controller)
        end
    end

    -- Start timer if at least one pad is held down
    if HoldingPadsSize > 0 then
        self.Controller.Timer:setTimer(self, 1)
    elseif HoldingPadsSize == 0 then
        self:resetStepModulationAndQuickEdit()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:incrementSoundOffset(Next)

    local NewOffset = Next
        and math.min(self:getMaxSoundOffset(), self.SoundOffset + self.SoundMode)
        or  math.max(0, self.SoundOffset - self.SoundMode)

    self:setSoundOffset(NewOffset)
    MaschineHelper.setFocusSound(self.SoundOffset + 1, true)

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:setSoundOffset(SoundOffset)

    SoundOffset = math.bound(SoundOffset, 0, self:getMaxSoundOffset())

    if SoundOffset ~= self.SoundOffset then
        self.SoundOffset = SoundOffset
        self:resetPendingRemoveEvents()
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onWheelButton(Pressed)

    if JamHelper.isStepModulationModeEnabled() then
        self.StepEdit:enableQuickEditMode(true, Pressed and NI.HW.QUICK_EDIT_LENGTH or nil)
    end

    return JamHelper.isQuickEditModeEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onWheelTouch(Touched)

    if (Touched and self.CanDoQuickEdit) or (not Touched) then
        self.StepEdit:enableQuickEditMode(Touched)
    end

    -- Return 'handled' if in step-mod / quick-edit mode in order to avoid oso
    return JamHelper.isStepModulationModeEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onWheelEvent(Inc)

    if JamHelper.isJamOSOVisible() then

        return false -- OSO takes precedence

    elseif self.StepEdit:onWheelEvent(Inc) then

        return true

    elseif PadModeHelper.getKeyboardMode() then

        return false -- not handled in keyboard mode

    elseif self.Controller.SwitchPressed[NI.HW.BUTTON_STEP] then

        -- increment sound mode
        local SoundMode = self.SoundMode
        local Next = Inc > 0
        if     self.SoundMode == 1 then SoundMode = (Next == true and 4 or 1)
        elseif self.SoundMode == 4 then SoundMode = (Next == true and 8 or 1)
        elseif self.SoundMode == 8 then SoundMode = (Next == true and 8 or 4)
        end

        self:setSoundMode(SoundMode)
        self.HandleStepButtonRelease = true
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onTouchEvent(TouchID, TouchType, Value)

    if JamHelper.isStepModulationModeEnabled() then

        return self.StepEdit:onTouchEvent(TouchID, TouchType, Value)

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:setSoundMode(NewSoundMode)

    if self.SoundMode ~= NewSoundMode then
        self:resetPendingRemoveEvents()
        self.SoundMode = NewSoundMode
    end

    self:updateControllerPadMode()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:setFocusedPage(NewFocusPage)

    if self.FocusedPage ~= NewFocusPage then

        self:resetPendingRemoveEvents()
        self.FocusedPage = NewFocusPage

        local Follow = JamHelper.isStepModeFollowPlayhead() and self.FocusedPage == self:getPlayingPageIndex()
        JamHelper.setStepModeFollowPlayhead(Follow)

    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onGroupButton(Index, Pressed)

    -- call base
    PageJam.onGroupButton(self, Index, Pressed)

    self:updateSoundOffset()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onSceneButton(Index, Pressed)

    if not Pressed then
        return
    end

    if self.Controller:isButtonPressed(NI.HW.BUTTON_STEP) then

        if Index == 1 or Index == 4 or Index == 8 then
            self:setSoundMode(Index)
            self.HandleStepButtonRelease = true
            self:updateSoundOffset()
        end

    else

        local NewFocusPage = nil
        if self.Controller:isShiftPressed() then

            if Index <= self:getNumPageBanks() then
                NewFocusPage = ((Index-1) * 8) + 1
            end

        else

            local ScaledIndex = Index + ((self:getFocusedPageBank()-1) * 8)
            if ScaledIndex <= self.NumPages then
                NewFocusPage = ScaledIndex
            end

        end

        if NewFocusPage then
            self:setFocusedPage(NewFocusPage)
        end

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onAccentButton(Pressed)

    -- activate on press, deactivate on release
    if Pressed and not self.PrevAccentState then

        self:toggleAccent()

    elseif not Pressed then

        if self.PrevAccentState then
            self:toggleAccent()
        end

        self.PrevAccentState = JamHelper.isAccentEnabled()
    end

    self:updateAccentLED()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:toggleAccent()

    JamHelper.setAccentEnabled(not JamHelper.isAccentEnabled())
    self:updateAccentLED()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:selectHoldingNotes()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if not Pattern or not Group then
        return
    end

    local StepModRow = self.StepEdit:getRowFromHoldingPads()
    local Sound = self:getSoundFromRow(StepModRow)

    local StepRangeWidth = StepHelper.getStepRangeWidth()

    local EventSet = NI.DATA.EventSet()
    for PadId, PadInfo in pairs(self.StepEdit.HoldingPads) do
        local Row = PadInfo[1]
        local Column = PadInfo[2]
        local StepTime = PadInfo[3]

        if StepTime < StepRangeWidth then
            local Events = self:getEventsFromPadIndex(Row, Column)
            STLHelper.insertSet(EventSet, Events)
        end
    end

    if EventSet:empty() then
        NI.DATA.SelectionAccess.deselectAllEvents(App, Pattern, Group)
    elseif Sound then
        NI.DATA.SelectionAccess.selectEvents(App, Pattern, Group, Sound, EventSet)
    end

    self.CanDoQuickEdit = EventSet:size() > 0
    if JamHelper.isQuickEditModeEnabled() and not self.CanDoQuickEdit then
        self.StepEdit:enableQuickEditMode(false)
    end

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:onLevelSourceButton(Button, Pressed)

    -- if step modulation or quick edit is enabled we return true to sigal that we handled the event
    return JamHelper.isQuickEditModeEnabled() or JamHelper.isStepModulationModeEnabled()

end

------------------------------------------------------------------------------------------------------------------------

function StepPage:resetStepModulationAndQuickEdit()

    self:resetHoldTimer()
    self.CanDoQuickEdit = false
    self.StepEdit:setStepModulationMode(false)

end

------------------------------------------------------------------------------------------------------------------------
