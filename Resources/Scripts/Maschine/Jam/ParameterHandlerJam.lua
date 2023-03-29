------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/QuickEditBase"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/QuickEditHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterHandlerJam = class( 'ParameterHandlerJam' )

-- OSO Timeout in timer ticks; about 2 seconds
local DEFAULT_OSO_TIMEOUT = 70

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:__init(Controller)

    -- Controller
    self.Controller = Controller

    -- timer for showing/hiding parameters in the Parameter OSO
    self.DisplayOSOTimer = 0

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onTimer()
    if NI.APP.isHeadless() then
        return

    end

    -- Update OSO timeout
    if self.DisplayOSOTimer > 0 then

        if App:getJamParameterOverlay():isMouseDragging() then
            self.DisplayOSOTimer = DEFAULT_OSO_TIMEOUT
        else
            self.DisplayOSOTimer = self.DisplayOSOTimer - 1
            if self.DisplayOSOTimer == 0 then
                self:onOSOTimeout()
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:startOSOTimeout()
    if NI.APP.isHeadless() then
        return

    end

    if JamHelper.isJamOSOVisible() then
        self:hideOSO(DEFAULT_OSO_TIMEOUT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onOSOTimeout()
    if NI.APP.isHeadless() then
        return

    end

    if JamHelper.isOSOLocked(self.Controller) then
        -- Do nothing, OSO will stay on until isOSOLocked returns true, or it's closed from a SW state change
        return
    else
        self:hideOSO()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Check if we should update any Parameter OSO
function ParameterHandlerJam:onCustomProcess(ForceUpdate)
    if NI.APP.isHeadless() then
        return

    end

    local OSOTypeChanged = App:getWorkspace():getJamOSOTypeParameter():isChanged()
    local OSOType = App:getWorkspace():getJamOSOTypeParameter():getValue()
    local UpdateParameters = false

    if OSOTypeChanged then
        -- Update static OSO button Leds (Grid/Rec Mode/Tempo OSO)
        self:updateStaticOSOButtonLeds()
    elseif OSOType == NI.HW.OSO_NONE then
        return
    end

    -- Focus Sound changed
    local SoundChanged = App:getStateCache():isFocusSoundChanged()
    local UpdateSoundParameters = SoundChanged and (OSOType == NI.HW.OSO_TUNE or OSOType == NI.HW.OSO_SWING)

    -- Focus Group changed
    local GroupChanged = App:getStateCache():isFocusGroupChanged()
    UpdateParameters = UpdateSoundParameters or GroupChanged or PadModeHelper.isKeyboardModeChanged()

    if (UpdateSoundParameters or GroupChanged) and not JamHelper.isOSOTypeStatic(OSOType) then
        App:getJamParameterOverlay():requestEditMode(false)
        self:startOSOTimeout() -- restart the timeout when switching groups
    end

    -- Check if we should update the Scale OSO parameters
    if not UpdateParameters then
        if (OSOType == NI.HW.OSO_SCALE or OSOType == NI.HW.OSO_ARP_REPEAT or OSOType == NI.HW.OSO_NOTES) then

            local ScaleEngine = NI.DATA.getScaleEngine(App)

            if ScaleEngine then
                UpdateParameters = ScaleEngine:getChordModeParameter():isChanged()
                    or ScaleEngine:getCurrentChordTypeParameter():isChanged()
                    or ScaleEngine:getScaleBankParameter():isChanged()
                    or ScaleEngine:getScaleParameter():isChanged() -- ScaleParameter determines what params are visible
                    or App:getWorkspace():getKeyboardLayoutParameter():isChanged()
            end

        elseif OSOType == NI.HW.OSO_LOOP_RECORD then

            local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)

            if Recorder then
                UpdateParameters = Recorder:getRecordingModeParameter():isChanged()
                                   or Recorder:getRecordingSourceParameter():isChanged()
            end

        end
    elseif not UpdateParameters and OSOType == NI.HW.OSO_SNAPSHOTS then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local SnapshotsManager = Song and Song:getParameterSnapshotsManager()

        if SnapshotsManager then
            local MorphParam = SnapshotsManager:getSnapshotMorphParameter()
            local MorphModeParam = SnapshotsManager:getSnapshotMorphModeParameter()
            UpdateParameters = MorphParam:isChanged() or MorphModeParam:isChanged()
        end

    end

    -- The Randomizer Mode can change the visibility of some oso parameters.
    UpdateParameters = UpdateParameters or App:getWorkspace():getRandomizeTypeParameter():isChanged()
    UpdateParameters = UpdateParameters or App:getWorkspace():getRandomizeNoteRangeParameter():isChanged()

    if UpdateParameters then
        self:updateOSOParameters(OSOType)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:updateStaticOSOButtonLeds()
    if NI.APP.isHeadless() then
        return

    end

    -- Update OSO button Leds that are independent of pages
    local GridButtonOn = JamHelper.isJamOSOVisible(NI.HW.OSO_GRID) or JamHelper.isJamOSOVisible(NI.HW.OSO_REC_MODE)
    local TempoButtonOn = JamHelper.isJamOSOVisible(NI.HW.OSO_TEMPO)

    LEDHelper.setLEDState(NI.HW.LED_GRID, GridButtonOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_TEMPO, TempoButtonOn and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onControllerPageChanged()
    if NI.APP.isHeadless() then
        return

    end

    -- hide static oso when page is changed except when we switch to the swing or tune touchstrip mode.
    --  In this case we don't hide the oso because which only switch the OSO type.
    local HideOSO = JamHelper.isJamStaticOSOVisible() and
        not self.Controller:isButtonPressed(NI.HW.BUTTON_SWING) and
        not self.Controller:isButtonPressed(NI.HW.BUTTON_TUNE)

    if HideOSO then
        self:hideOSO()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:showOSO(OSOType, IsWheelTouch)
    if NI.APP.isHeadless() then
        return

    end

    if not OSOType or OSOType == NI.HW.OSO_NONE then
        return
    end

    if not IsWheelTouch and self.Controller.LevelMeterControls:isEncoderActive() then
        -- Turn level meter off when OSO is shown
        self.Controller.LevelMeterControls:resetMode()
    end

    -- Conditions that block the OSO from appearing
    local BlockOSOMsg = ""
    if IsWheelTouch and self.Controller.LevelMeterControls:isEncoderActive() and OSOType ~= NI.HW.OSO_LOOP_RECORD then
        BlockOSOMsg = "Parameter OSO not shown because a Level Meter mode is set and the wheel is assigned to that."
    elseif App:getOnScreenOverlay():getVisibleParameter():getValue() then
        BlockOSOMsg = "Parameter OSO not shown because the Browser OSO is apparently open."
    elseif not OSOType then
        BlockOSOMsg = "Parameter OSO not shown because an OSO type was not given."
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        BlockOSOMsg = "Parameter OSO not shown because the OSO type is invalid or no valid Parameters found."
    end

    if BlockOSOMsg ~= "" then
        print(BlockOSOMsg)
        return
    end

    -- Set the OSO parameters, then OSO type, which will make the OSO appear
    self:updateOSOParameters(OSOType)
    App:getJamParameterOverlay():setOSOType(OSOType)

    if JamHelper.isOSOTypeStatic(OSOType) then
        self:updateStaticOSOButtonLeds() -- Ensure static OSO button Leds are updated
    elseif OSOType ~= NI.HW.OSO_NOTES then -- Don't start OSO timeout on NOTES button press
        self:startOSOTimeout()
    end

end

------------------------------------------------------------------------------------------------------------------------
-- @remarks: Argument 'When' is for setting the OSO timeout (in timer ticks) before the OSO disappears
function ParameterHandlerJam:hideOSO(When)
    if NI.APP.isHeadless() then
        return

    end

    if not When or When <= 0 then

        self.DisplayOSOTimer = 0
        App:getJamParameterOverlay():closeOSO()

    elseif JamHelper.isJamOSOVisible() then

        self.DisplayOSOTimer = When

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:updateOSOParameters(OSOType)
    if NI.APP.isHeadless() then
        return

    end

    -- Set parameters to the OSO
    local JamOSO = App:getJamParameterOverlay()
    local WasEditMode = JamOSO:isInEditMode()

    JamOSO:clearParameters()

    local OSOParameters = self:getOSOParameters(OSOType)
    if not OSOParameters then
        return
    end

    for i in pairs(OSOParameters) do
        local Undoable = OSOParameters[i][3] == nil or OSOParameters[i][3]
        JamOSO:setParameter(i-1, OSOParameters[i][1], OSOParameters[i][2], i == #OSOParameters, Undoable)
    end

    if JamHelper.isJamNonStaticOSOVisible() and WasEditMode and not JamOSO:isInEditMode() then
        -- Restart the OSO timeout when the oso was in edit mode, but not after setting the new parameters
        self:startOSOTimeout()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onWheelTouch(Touched)
    if NI.APP.isHeadless() then
        return false

    end

    local OSOVisible = JamHelper.isJamOSOVisible()
    if Touched and not JamHelper.isJamStaticOSOVisible() and not OSOVisible then

        local ShowOSOType = nil
        local CurPage = NHLController:getPageStack():getTopPage()

        -- Get OSO type according to current page
        if CurPage == NI.HW.PAGE_ARP_REPEAT then
            ShowOSOType = NI.HW.OSO_ARP_REPEAT
        elseif CurPage == NI.HW.PAGE_NOTES then
            ShowOSOType = NI.HW.OSO_NOTES
        elseif self.Controller.Looper and self.Controller.Looper.Enabled then
            ShowOSOType = NI.HW.OSO_LOOP_RECORD
        elseif PadModeHelper.getKeyboardMode() and (CurPage == NI.HW.PAGE_STEP or CurPage == NI.HW.PAGE_PAD_MODE) then
            ShowOSOType = NI.HW.OSO_SCALE
        elseif CurPage == NI.HW.PAGE_SNAPSHOTS then
            ShowOSOType = NI.HW.OSO_SNAPSHOTS
        end

        if ShowOSOType then
            self:showOSO(ShowOSOType, true)
            return true
        end

    elseif not Touched and OSOVisible then
        -- Start OSO timer when the OSO is visible and the wheel is released
        self.Controller.ParameterHandler:startOSOTimeout()
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onWheelEvent(Inc)
    if NI.APP.isHeadless() then
        return false

    end

    local JamOSO = App:getJamParameterOverlay()
    if JamOSO:isInEditMode() then

        local Parameter = JamOSO:getFocusedParameter()
        if Parameter then

            local ParamIdx = App:getJamParameterOverlay():getFocusedParameterIndex(false)
            local ShiftPressed = self.Controller:isShiftPressed()
            local AutoWriteEnabled = NHLController:isAutoWriteEnabled() and MaschineHelper.isPlaying()

            if JamHelper.isJamOSOVisible(NI.HW.OSO_TUNE) and ParamIdx == 1 and not AutoWriteEnabled then

                -- Special handling for Group Tune
                local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
                if FocusGroup then
                    Inc = Inc * FocusGroup:getTuneOffsetIncrementScaling(ShiftPressed);
                    NI.DATA.GroupAccess.offsetSoundsTuneParam(App, FocusGroup, Inc, ShiftPressed)
                end

            elseif JamHelper.isJamOSOVisible(NI.HW.OSO_NOTES) and not AutoWriteEnabled then

                if ParamIdx == 1 then -- Root note
                    local Group = NI.DATA.StateHelper.getFocusGroup(App)
                    local RootParam = Group and Group:getRootNoteParameter()
                    if RootParam then
                        local NewValue = RootParam:getValue() + Inc
                        NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, RootParam, NewValue)
                    end
                end
            end

        end

        return true

    elseif JamOSO:isRandomizeApplyFocused() and self.Controller:isWheelPressed() then
            return true -- do nothing

    elseif JamOSO:getOSOType() ~= NI.HW.OSO_NONE then
        JamOSO:incrementFocusParameter(Inc)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:onWheelButton(Pressed)
    if NI.APP.isHeadless() then
        return false

    end

    if JamHelper.isJamOSOVisible() then

        local JamOSO = App:getJamParameterOverlay()

        if JamHelper.isJamOSOVisible(NI.HW.OSO_RANDOMIZER)
            and JamOSO:isRandomizeApplyFocused() or self.Controller:isShiftPressed() then

            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App,
                App:getWorkspace():getRandomizeApplyParameter(), Pressed == true)

        elseif Pressed then
            if JamHelper.isJamOSOVisible(NI.HW.OSO_PERFORM_FX) then
                JamOSO:closeOSO()
            else
                JamOSO:toggleEditMode()
            end
        end

        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:getOSOParameters(OSOType)
    if NI.APP.isHeadless() then
        return {}

    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then return {} end

    if OSOType == NI.HW.OSO_ARP_REPEAT then

        local Arp = NI.DATA.getArpeggiator(App)
        if not Arp then return {} end

        local KybdMode = PadModeHelper.getKeyboardMode()
        local ArpParameters =
        {
            KybdMode and {Arp:getTypeParameter(), "MAIN"}               or {NI.DATA.getArpeggiatorRateParameter(App), "RHYTHM"},
            KybdMode and {NI.DATA.getArpeggiatorRateParameter(App), "RHYTHM"} or {NI.DATA.getArpeggiatorRateUnitParameter(App), ""},
            KybdMode and {NI.DATA.getArpeggiatorRateUnitParameter(App), ""}   or {Arp:getGateParameter(), "OTHER"},
            KybdMode and {Arp:getSequenceParameter(), ""}               or {Song:getHWNoteRepeatLockedParameter(), ""},
            KybdMode and {Arp:getOctavesParameter(), ""}                or {Arp:getHoldParameter(), ""},
            KybdMode and {Arp:getDynamicParameter(), "OTHER"}           or {nil, ""},
            KybdMode and {Arp:getGateParameter(), ""}                   or {nil, ""},
            KybdMode and {Song:getHWNoteRepeatLockedParameter(), ""}    or {nil, ""},
            KybdMode and {Arp:getHoldParameter(), ""}                   or {nil, ""}
        }

        if KybdMode then
            local ScaleParameters = self:getScaleOSOParameters()
            for _, Param in ipairs(ScaleParameters) do
                table.insert(ArpParameters, Param)
            end
        end

        return ArpParameters

    elseif OSOType == NI.HW.OSO_SCALE then

        return self:getScaleOSOParameters()

    elseif OSOType == NI.HW.OSO_GRID then

        return
        {
            {Song:getPatternEditorSnapParameter(), "STEP", false},
            {Song:getPatternEditorNudgeSnapParameter(), "NUDGE", false},
            {Song:getArrangeGridParameter(), "ARRANGE", false},
            {Song:getPerformGridParameter(), "PERFORM", false}
        }

    elseif OSOType == NI.HW.OSO_TEMPO then

        return
        {
            {Song:getTempoParameter(), ""}
        }

    elseif OSOType == NI.HW.OSO_REC_MODE then

        return
        {
            {App:getMetronome():getVolumeParameter(), "METRONOME", false},
            {App:getMetronome():getTimeSignatureParameter(Song:getDenominatorParameter():getValue()), "", false},
            {App:getMetronome():getAutoEnableParameter(), "", false},
            {App:getMetronome():getCountInLengthParameter(), "COUNT-IN", false},
            {App:getWorkspace():getQuantizeModeParameter(), "QUANTIZE", false},
            {Song:getDefaultVelocityJamParameter(), "INPUT VELOCITY", false},
            {Song:getAccentVelocityJamParameter(), "", false},
            {NHLController:getContext():getStepModeFollowPlayheadParameter(), "PAT FOLLOW", false}
        }

    elseif OSOType == NI.HW.OSO_SWING then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = NI.DATA.StateHelper.getFocusSound(App)

        return
        {
            {Song:getSwingAmountParameter(), "MASTER"},
            {Group and Group:getSwingAmountParameter(), "GROUP"},
            {Sound and Sound:getSwingAmountParameter(), "SOUND"}
        }

    elseif OSOType == NI.HW.OSO_TUNE then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local SoundTuneParameter = QuickEditHelper.getSoundTuneParam(Sound)

        return
        {
            {SoundTuneParameter, "SOUND"},
            {Group and Group:getTuneOffsetParameter(), "GROUP"}
        }

    elseif OSOType == NI.HW.OSO_RANDOMIZER then

        local Workspace          = App:getWorkspace()
        local NoteRangeParam     = Workspace:getRandomizeNoteRangeParameter()
        local VelocityRangeParam = Workspace:getRandomizeVelocityRangeParameter()

        local Mode = Workspace:getRandomizeTypeParameter():getValue()

        if PadModeHelper.getKeyboardMode() and Mode == NI.HW.RANDOMIZE then
            return
            {
                {Workspace:getRandomizeTypeParameter(), ""},
                {Workspace:getRandomizeApplyParameter(), ""},
                {Workspace:getRandomizeNoteProbabilityParameter(), "PROBABILITY"},
                {NoteRangeParam:getMinParameter(), "NOTE RANGE"},
                {NoteRangeParam:getMaxParameter(), ""},
                {VelocityRangeParam:getMinParameter(), "VELOCITY RANGE"},
                {VelocityRangeParam:getMaxParameter(), ""},
                {Workspace:getRandomizeNumNotesInStepParameter(), "CHORDS"},
                {Workspace:getRandomizeNoteLengthParameter(), "NOTE LENGTH"},
                {Workspace:getRandomizeTimingParameter(), "TIME SHIFT"},
                {Workspace:getRandomizeNotesCountDistributionParameter(), "DISTRIBUTIONS"},
                {Workspace:getRandomizeNoteDistributionParameter(), ""},
                {Workspace:getRandomizeNoteLengthDistributionParameter(), ""}
            }
        elseif Mode == NI.HW.RANDOMIZE then
            return
            {
                {Workspace:getRandomizeTypeParameter(), ""},
                {Workspace:getRandomizeApplyParameter(), ""},
                {Workspace:getRandomizeNoteProbabilityParameter(), "PROBABILITY"},
                {VelocityRangeParam:getMinParameter(), "VELOCITY RANGE"},
                {VelocityRangeParam:getMaxParameter(), ""},
                {Workspace:getRandomizeTimingParameter(), "TIME SHIFT"},
                {Workspace:getRandomizeNoteLengthParameter(), "NOTE LENGTH"},
                {Workspace:getRandomizeNoteLengthDistributionParameter(), "DISTRIBUTION"}
            }
        else -- HUMANIZER
            return
            {
                {Workspace:getRandomizeTypeParameter(), ""},
                {Workspace:getRandomizeApplyParameter(), ""},
                {VelocityRangeParam:getMinParameter(), "VELOCITY RANGE"},
                {VelocityRangeParam:getMaxParameter(), ""},
                {Workspace:getRandomizeTimingParameter(), "TIME SHIFT"}
            }
        end

    elseif OSOType == NI.HW.OSO_NOTES then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local ScaleEngine = NI.DATA.getScaleEngine(App)
        if not ScaleEngine or not Group then
            return {}
        end

        local ChordMode = ScaleEngine:getChordModeParameter():getValue() > 0

        local NotesParameters =
        {
            {Group:getStrummingModeParameter(), ""},
            {Group:getRootNoteParameter(), "SCALE"},
            {ScaleEngine:getScaleParameter(), ""}
        }

        return NotesParameters

    elseif OSOType == NI.HW.OSO_SNAPSHOTS then

        local SnapshotsManager = Song:getParameterSnapshotsManager()
        local MorphParam = SnapshotsManager:getSnapshotMorphParameter()
        local MorphEnabled = MorphParam:getValue()
        local MorphModeParam = SnapshotsManager:getSnapshotMorphModeParameter()
        local IsModeTarget = MorphModeParam:getValue() == 1
        local MorphTimeParam = IsModeTarget and
            SnapshotsManager:getSnapshotMorphDestTimeParameter() or
            SnapshotsManager:getSnapshotMorphTimeParameter()

        return
        {
            {MorphParam, "MORPHING"},
            {MorphEnabled and MorphModeParam or nil, ""},
            {MorphEnabled and MorphTimeParam or nil, ""}
        }

    elseif OSOType == NI.HW.OSO_LOOP_RECORD then

        local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
        local Params = {}

        if Recorder then

            local ModeParam = Recorder:getRecordingModeParameter()
            local SourceParam = Recorder:getRecordingSourceParameter()

            local InputLookup = {
                [NI.DATA.SOURCE_EXTERNAL_STEREO] = Recorder:getExtStereoInputsParameter(),
                [NI.DATA.SOURCE_EXTERNAL_MONO] = Recorder:getExtMonoInputsParameter(),
                [NI.DATA.SOURCE_INTERNAL] = Recorder:getInternalInputsParameter()
            }

            Params = {
                {SourceParam, "INPUT"},
                {InputLookup[SourceParam:getValue()], ""},
                {ModeParam, "RECORDING"},
            }

            if ModeParam:getValue() == NI.DATA.MODE_DETECT then
                table.insert(Params, {Recorder:getDetectThresholdParameter(), ""})
            elseif ModeParam:getValue() == NI.DATA.MODE_SYNC then
                table.insert(Params, {Recorder:getSyncLengthParameter(), ""})
            elseif ModeParam:getValue() == NI.DATA.MODE_LOOP then
                table.insert(Params, {Recorder:getSyncLengthParameter(), ""})
                table.insert(Params, {Recorder:getLoopTargetParameter(), ""})
            end

            if SourceParam:getValue() ~= NI.DATA.SOURCE_INTERNAL then
                table.insert(Params, {Recorder:getDirectMonitoringParameter(), "MONITOR"})
            end

        end

        return Params

    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerJam:getScaleOSOParameters()
    if NI.APP.isHeadless() then
        return {}

    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local Workspace = App:getWorkspace()

    if not ScaleEngine or not Group then
        return {}
    end

    local CurPage       = NHLController:getPageStack():getTopPage()
    local IsPianoRoll   = PadModeHelper.getKeyboardMode() and CurPage == NI.HW.PAGE_STEP
    local ShowScale     = IsPianoRoll or not ScaleEngine:getChordModeIsChordSet()
    local ShowChordMode = not IsPianoRoll
    local ShowChordType = ScaleEngine:getChordModeParameter():getValue() > 0 and not IsPianoRoll
    local ShowIsomorphic = not IsPianoRoll
    local IsIsomorphic  = Workspace:getKeyboardLayoutParameter():getValue() == PadModeHelper.IsomorphicKeyboardLayout

    local Fallback = {nil, ""}

    return
    {
        {Group:getRootNoteParameter(), "SCALE"},
        ShowScale     and {ScaleEngine:getScaleBankParameter(), ""}        or Fallback,
        ShowScale     and {ScaleEngine:getScaleParameter(), ""}            or Fallback,
        ShowChordMode and {ScaleEngine:getChordModeParameter(), "CHORD"}   or Fallback,
        ShowChordType and {ScaleEngine:getCurrentChordTypeParameter(), ""} or Fallback,
        ShowIsomorphic and {Workspace:getKeyboardLayoutParameter(), "PAD LAYOUT", false} or Fallback,
        (ShowIsomorphic and IsIsomorphic) and {Workspace:getIsomorphicKeyboardLayoutParameter(), "", false} or Fallback,
        (ShowIsomorphic and IsIsomorphic) and {Workspace:getIsomorphicTypeParameter(), "", false} or Fallback,
        (ShowIsomorphic and IsIsomorphic) and {Workspace:getIsomorphicDirectionParameter(), "", false} or Fallback
    }

end

------------------------------------------------------------------------------------------------------------------------
