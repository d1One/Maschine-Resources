------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/LedColors"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ControlHelper"
require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Maschine/Jam/ParameterHandlerJam"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JamHelper = class( 'JamHelper' )

------------------------------------------------------------------------------------------------------------------------

function JamHelper.updatePadLEDsSounds(Controller, DeactivateNonSoundPads)

    -- Use DeactivateNonSoundPads with default set to true
    if DeactivateNonSoundPads or DeactivateNonSoundPads == nil then
        JamHelper.turnOffNonSoundPads(Controller.PAD_LEDS)
    end

    LEDHelper.updateLEDsWithFunctor(Controller.PAD_SOUND_LEDS, 0,
        function(Index) return PadModeHelper.getPadLEDStatesSound(Index, PadModeHelper.FocusedSoundIndex) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.updatePadLEDsKeyboard(Controller)

    for ColumnIndex = 1, 8 do
        LEDHelper.updateLEDsWithFunctor(Controller.PAD_LEDS[ColumnIndex], 0,
            function(RowIndex) return PadModeHelper.getKeyboardModePadStates((RowIndex - 1) * 8 + ColumnIndex, true) end,
            function(RowIndex) return PadModeHelper.getKeyboardModePadColor((RowIndex - 1) * 8 + ColumnIndex, true) end,
            function(RowIndex) return MaschineHelper.getFlashStatePianoRollNoteOn((RowIndex - 1) * 8 + ColumnIndex, true) end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.focusSoundByIndex(SoundIndex, Controller)

    PadModeHelper.FocusedSoundIndex = SoundIndex
    MaschineHelper.setFocusSound(SoundIndex, false)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getPatternLEDState(GroupIndex, PatternIndex) -- index >= 1

    if PatternIndex > 0 then

        local Scene   = NI.DATA.StateHelper.getFocusScene(App)
        local Group   = MaschineHelper.getGroupAtIndex(GroupIndex - 1)
        local Pattern = Group and Group:getPatterns():find(PatternIndex - 1) or nil

        if Pattern then
            local HasFocus = Scene and Pattern == NI.DATA.SceneAccess.getPattern(Scene, Group)
            return HasFocus, true
        end

    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getPatternLEDColorByGroupAndByIndex(GroupIndex, PatternIndex) -- index >= 1

    if PatternIndex > 0 then

        local Group = MaschineHelper.getGroupAtIndex(GroupIndex - 1)

        local Pattern = Group and Group:getPatterns():find(PatternIndex - 1) or nil

        if Pattern then
            return Pattern:getColorParameter():getValue()
        end

    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.decreaseOffset(CurrentOffset, MinOffset, ShiftPressed, BlockSize)

    -- if BlockSize is omitted then set to 8
    if BlockSize == nil then
        BlockSize = JamControllerBase.NUM_PAD_ROWS
    end

    local Offset = 1

    if not ShiftPressed then
        Offset = CurrentOffset % BlockSize
        if Offset == 0 then
            Offset = BlockSize
        end
    end

    return math.max(MinOffset, CurrentOffset - Offset)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.increaseGroupOffset(CurrentOffset, MaxOffset, ShiftPressed, BlockSize)

    -- if BlockSize is omitted then set to 8
    if BlockSize == nil then
        BlockSize = JamControllerBase.NUM_PAD_ROWS
    end

    local Offset = not ShiftPressed and (BlockSize - CurrentOffset % BlockSize) or 1

    local NewOffset = CurrentOffset + Offset
    local MaxValue = math.floor(MaxOffset / BlockSize) * BlockSize

    if NewOffset <= MaxValue then
        return NewOffset
    else
        return CurrentOffset
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.increasePatternOffset(CurrentOffset, MaxOffset, ShiftPressed, BlockSize)

    -- if BlockSize is omitted then set to 8
    if BlockSize == nil then
        BlockSize = JamControllerBase.NUM_PAD_ROWS
    end

    local Offset = not ShiftPressed and (BlockSize - CurrentOffset % BlockSize) or 1

    local NewOffset = CurrentOffset + Offset
    local MaxValue = math.floor(MaxOffset / BlockSize) * BlockSize

    local Value = ShiftPressed and CurrentOffset + BlockSize or NewOffset

    if Value < MaxValue then
        return NewOffset
    else
        return CurrentOffset
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getSoundIndexByColumRow(Column, Row)

    if Row > 4 and Column > 4 then

        local ColumnOffset = Column - 1 - 4
        local RowOffset = 8 - Row

        return RowOffset * 4 + ColumnOffset + 1

    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.turnOffNonSoundPads(PadLeds)

    for Column = 1, 8 do
        for Row = 1, 8 do
            if Column <= 4 or Row <= 4 then
                LEDHelper.setLEDState(PadLeds[Column][Row], LEDHelper.LS_OFF)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.turnOffMatrixLEDs()

    for _, Column in ipairs(JamControllerBase.PAD_LEDS) do
        for _, Led in ipairs(Column) do
            LEDHelper.setLEDState(Led, LEDHelper.LS_OFF)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.invokeShiftFunction(Index)

    if Index == 1 then
        App:getTransactionManager():undoTransactionMarker()            -- Undo combined
    elseif Index == 2 then
        App:getTransactionManager():redoTransactionMarker()            -- Redo combined
    elseif Index == 3 then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, false)	-- Quantize Full
    elseif Index == 4 then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, true)	-- Quantize 50%
    elseif Index == 5 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, -1)     -- Semitone -
    elseif Index == 6 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, 1)      -- Semitone +
    elseif Index == 7 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, -12)    -- Octave -
    elseif Index == 8 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, 12)     -- Octave +
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getMaxNumPatterns()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local NumBanks = Song and Song:getNumPatternBanksParameter():getValue() or 1
    return NumBanks  * 16

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.canAddPatternBank()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local NumBanks = Song and Song:getNumPatternBanksParameter():getValue() or 1

    return (not NI.DATA.SongAccess.isPatternBankEmptyInAllGroups(App, NumBanks - 1))

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.addPatternBank()

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if FocusGroup then
        NI.DATA.SongAccess.addPatternBank(App, FocusGroup)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- @remarks: The OSOType argument is optional
function JamHelper.isJamOSOVisible(OSOType)

    local OSOTypeVisible = App:getWorkspace():getJamOSOTypeParameter():getValue()

    if OSOType ~= nil and OSOTypeVisible ~= NI.HW.OSO_NONE then
        return OSOType == OSOTypeVisible
    else
        return OSOTypeVisible ~= NI.HW.OSO_NONE
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isJamStaticOSOVisible()

    local OSOType = App:getWorkspace():getJamOSOTypeParameter():getValue()
    return OSOType ~= NI.HW.OSO_NONE and JamHelper.isOSOTypeStatic(OSOType)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isOSOTypeStatic(OSOType)

    return OSOType == NI.HW.OSO_GRID
        or OSOType == NI.HW.OSO_TEMPO
        or OSOType == NI.HW.OSO_REC_MODE
        or OSOType == NI.HW.OSO_RANDOMIZER
        or OSOType == NI.HW.OSO_PERFORM_FX
end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isJamNonStaticOSOVisible()

    local OSOType = App:getWorkspace():getJamOSOTypeParameter():getValue()
    return OSOType ~= NI.HW.OSO_NONE and not JamHelper.isOSOTypeStatic(OSOType)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isFocusSlotPerformFX()

    local Slot = NI.DATA.StateHelper.getFocusSlot(App)
    return Slot and Slot:hasPerformFX()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isOSOLocked(Controller)

    local CurPage = NHLController:getPageStack():getTopPage()
    local Button = Controller:getButtonFromPage(CurPage)
    local CurOSOType = App:getJamParameterOverlay():getOSOType()

    return JamHelper.isOSOTypeStatic(CurOSOType)
        or (not Button == NI.HW.BUTTON_LOCK and Controller:isButtonPressed(Button))
        or Controller:isButtonPressed(Button)
        or Controller:isButtonPressed(NI.HW.TOUCH_BROWSE)
        or App:getJamParameterOverlay():isMouseDragging()
        or App:getJamParameterOverlay():isInEditMode()
        or ((CurOSOType == NI.HW.OSO_TUNE or CurOSOType == NI.HW.OSO_SWING) and Controller:anyTouchstripTouched())

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getTouchstripMode()

    return NHLController:getContext():getTouchstripModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setTouchstripMode(Mode)

    local TouchstripModeParameter = NHLController:getContext():getTouchstripModeParameter()
    NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, TouchstripModeParameter, Mode)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getGroupOffset()

    return NHLController:getContext():getGroupOffsetParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setGroupOffset(Offset)

    local GroupOffsetParameter = NHLController:getContext():getGroupOffsetParameter()
    NI.DATA.ParameterAccess.setSizeTParameter(App, GroupOffsetParameter, Offset)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getSoundOffset()

    return NHLController:getContext():getSoundOffsetParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setSoundOffset(Offset)

    local SoundOffsetParameter = NHLController:getContext():getSoundOffsetParameter()
    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, SoundOffsetParameter, Offset)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getPatternOffset()

    return NHLController:getContext():getPatternOffsetParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setPatternOffset(Offset)

    local PatternOffsetParameter = NHLController:getContext():getPatternOffsetParameter()
    NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PatternOffsetParameter, Offset)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isStepModeFollowPlayhead()

    return NHLController:getContext():getStepModeFollowPlayheadParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.toggleStepModeFollowPlayhead()

    local Param = NHLController:getContext():getStepModeFollowPlayheadParameter()
    NI.DATA.ParameterAccess.toggleBoolParameterNoUndo(App, Param)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setStepModeFollowPlayhead(Follow)

    local Param = NHLController:getContext():getStepModeFollowPlayheadParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, Follow)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isAutoWriteEnabled()

    return NHLController:isAutoWriteEnabled() and MaschineHelper.isPlaying()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.hasFineResolutionOnTouchstrip(Parameter)

    local Tag = Parameter:getTag()

    return
        Tag ~= NI.DATA.MaschineParameter.TAG_ENUM and
        Tag ~= NI.DATA.MaschineParameter.TAG_BOOL and
        not MaschineHelper.isRoutingParam(Parameter)

end

------------------------------------------------------------------------------------------------------------------------
-- Checks the focused slot for something loaded that can be used to base a quick-browse from
function JamHelper.canQuickBrowse()

    local Slot = NI.DATA.StateHelper.getFocusSlot(App)
    return Slot and Slot:getModule() ~= nil

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isAccentEnabled()

    return NHLController:getContext():getAccentEnabledParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setAccentEnabled(Enabled)

    local AccentParameter = NHLController:getContext():getAccentEnabledParameter()
    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, AccentParameter, Enabled)

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isStepModulationModeEnabled()

    return NHLController:getContext():getStepModulationModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.setQuickEditMode(QEMode)

    if QEMode then
        local QEModeParameter = NHLController:getContext():getQuickEditModeParameter()
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, QEModeParameter, QEMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.isQuickEditModeEnabled()

    return NHLController:getContext():getQuickEditModeParameter():getValue() ~= NI.HW.QUICK_EDIT_NONE

end

------------------------------------------------------------------------------------------------------------------------

function JamHelper.getQuickEditMode()

    return NHLController:getContext():getQuickEditModeParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------
