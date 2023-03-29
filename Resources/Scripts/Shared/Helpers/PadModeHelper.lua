------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/StepHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModeHelper = class( 'PadModeHelper' )

------------------------------------------------------------------------------------------------------------------------

PadModeHelper.multiSelectionCheckers = {
    function (MaschineInstance) return NI.DATA.StateHelper.getIsChokeGroupMultiSelection(MaschineInstance) end,
    function (MaschineInstance) return NI.DATA.StateHelper.getIsChokeModeMultiSelection(MaschineInstance) end,
    function (MaschineInstance) return NI.DATA.StateHelper.getIsLinkGroupMultiSelection(MaschineInstance) end,
    function (MaschineInstance) return NI.DATA.StateHelper.getIsLinkModeMultiSelection(MaschineInstance) end,
    function (MaschineInstance) return NI.DATA.StateHelper.getIsBaseKeyMultiSelection(MaschineInstance) end
}

------------------------------------------------------------------------------------------------------------------------

PadModeHelper.BaseKeyOffset = 0

PadModeHelper.IsomorphicKeyboardLayout = 1
PadModeHelper.IsomorphicTypeChromatic = 1

-- When playing pads quickly, setting the sound focus is much slower than playing, but we want to show the brightness
-- of the upcoming focused pad immediately, therefore we use this member to set what sound will be focused,
-- as well as what eventually gets focus from the app's side.  It is 1-indexed so 0 or less is invalid.
PadModeHelper.FocusedSoundIndex = -1 -- 1-indexed

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.toggleKeyboardMode()

    NI.DATA.GroupAccess.toggleKeyboardMode(App)

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.setKeyboardMode(KeyboardMode)

    NI.DATA.GroupAccess.setKeyboardMode(App, KeyboardMode, false)

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isSoundMode()

    return NHLController:getPadMode() == NI.HW.PAD_MODE_SOUND

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getKeyboardMode()

    -- keyboard view on the HW is always on for keyboard products
    if NI.HW.FEATURE.KEYBOARD then return true end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getKeyboardModeEnabledParameter():getValue() or false

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isKeyboardModeChanged()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getKeyboardModeEnabledParameter():isChanged()

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.canSetStepModeEnabled()

    local PadMode = NHLController:getPadMode()
    return PadMode == NI.HW.PAD_MODE_SOUND and NHLController:getPageStack():getTopPage() ~= NI.HW.PAGE_SAMPLING

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.setStepModeEnabled(Enable)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Group:getStepModeEnabledParameter(), Enable)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isStepModeEnabled()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getStepModeEnabledParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getPadVelocityMode()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getPadVelocityModeParameter():getValue() or NI.HW.PAD_VELOCITY_NORMAL

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.is16VelocityMode()

    return PadModeHelper.getPadVelocityMode() == NI.HW.PAD_VELOCITY_16_LEVELS

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isFixedVelocity()

    return PadModeHelper.getPadVelocityMode() == NI.HW.PAD_VELOCITY_FIXED

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.togglePadVelocityMode(VelocityMode)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song and Group then

        local CurVelMode = Song:getPadVelocityModeParameter():getValue()
        if (VelocityMode == NI.HW.PAD_VELOCITY_FIXED and CurVelMode == NI.HW.PAD_VELOCITY_FIXED) or
           (VelocityMode == NI.HW.PAD_VELOCITY_16_LEVELS and CurVelMode == NI.HW.PAD_VELOCITY_16_LEVELS) then

            VelocityMode = NI.HW.PAD_VELOCITY_NORMAL
        end

        NI.DATA.SongAccess.setPadVelocityMode(App, Song, Group, VelocityMode)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getFixedVelocityValue()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getFixedVelocityParameter():getValue() or 127

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.canTransposeRootNote(Inc)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        return NI.DATA.GroupAlgorithms.canTransposeRootNote(Group, Inc);
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.transposeRootNoteOrBaseKey(Inc, Controller)

    local KeyboardModeOn = PadModeHelper.getKeyboardMode()
    if KeyboardModeOn then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            NI.DATA.GroupAccess.transposeRootNote(App, Group, Inc, false);
        end
    else
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        if Sound then
            local BaseKeyParam = Sound:getBaseKeyParameter()
            local BaseKey = math.bound(BaseKeyParam:getValue() + Inc, BaseKeyParam:getMin(), BaseKeyParam:getMax())

            NI.DATA.ParameterAccess.setSizeTParameter(App, BaseKeyParam, BaseKey)
        end
    end

    if Controller and NI.DATA.StateHelper.getIsBaseKeyMultiSelection(App) then

        PadModeHelper.setBaseKeyOffsetTempMode(Controller, Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.setBaseKeyOffsetTempMode(Controller, Inc)

    local InfoBar = Controller:getInfoBar()

    if InfoBar then

        if InfoBar.Mode ~= "BaseKeyOffsetTempMode" then
            PadModeHelper.BaseKeyOffset = 0
        end

        PadModeHelper.BaseKeyOffset = PadModeHelper.BaseKeyOffset + Inc

        InfoBar:setTempMode("BaseKeyOffsetTempMode")

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getKeyboardModePadStates(PadIndex, IsJam)

    if IsJam == nil then
        IsJam = false -- default value
    end

    local Selected = false
    local Enabled = false
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if FocusGroup then

        local Key = PadModeHelper.getNoteForPad(PadIndex, IsJam)
        if Key < 128 then

            -- Selected is true if the pad is the root note
            if PadModeHelper.isChordModeChordSet() then
                Selected = PadIndex == 1
            else
                Selected = PadModeHelper.isRootNote(PadIndex, IsJam)
            end

            -- when isomorphic keyboard is turned on and the type is chromatic we
            -- show also non-scale notes but with LED turned off
            if IsJam then
                local Workspace = App:getWorkspace()
                local IsIsomorphic =
                    Workspace:getKeyboardLayoutParameter():getValue() == PadModeHelper.IsomorphicKeyboardLayout
                local IsTypeChromatic = IsIsomorphic and
                    Workspace:getIsomorphicTypeParameter():getValue() == PadModeHelper.IsomorphicTypeChromatic
                Enabled = not IsIsomorphic or not IsTypeChromatic or
                    NI.UTILS.ScaleHelper.getBankScaleOffsetForNote( PadModeHelper.getRootNote(),
                        PadModeHelper.getCurrentBank(), PadModeHelper.getCurrentScale(), Key) == 0 or
                    MaschineHelper.getFlashStatePianoRollNoteOn(PadIndex, true)
            else
                Enabled = true
            end
        end

    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getKeyboardModePadColor(PadIndex, IsJam)

    if not IsJam then
        return NI.DATA.StateHelper.getFocusSound(App):getColorParameter():getValue()
    end

    local IsRootNote = PadModeHelper.isRootNote(PadIndex, IsJam)
    local Flash      = MaschineHelper.getFlashStatePianoRollNoteOn(PadIndex, true)

    return (IsRootNote and not Flash)
        and LEDColors.WHITE
        or  NI.DATA.StateHelper.getFocusSound(App):getColorParameter():getValue()
end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getCurrentBank()

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    return ScaleEngine and ScaleEngine:getScaleBankParameter():getValue() or 0

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getCurrentScale()

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    return ScaleEngine and ScaleEngine:getScaleParameter():getValue() or 0

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getNoteForPad(PadIndex, IsJam)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getNoteForPad(PadIndex - 1, IsJam or false) or 128

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isRootNote(PadIndex, IsJam)

    local Key = PadModeHelper.getNoteForPad(PadIndex, IsJam or false)
    local RootNote = PadModeHelper.getRootNote()
    return (Key % 12) == (RootNote % 12)

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getRootNote()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getRootNoteParameter():getValue() or 0

end

------------------------------------------------------------------------------------------------------------------------

local function getScreenPadButtonStateKeyboardMode(Index)

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local ChordSetActive = ScaleEngine and ScaleEngine:getChordModeIsChordSet() or false
    local RootNote = PadModeHelper.getRootNote()

    local Enabled, Focused, Text
    local Key = PadModeHelper.getNoteForPad(Index)

    if ChordSetActive then
        Enabled = Index < 13 and Key < 128
        Focused = Index == 1
        local UseShortNames = NI.HW.FEATURE.SCREEN_TYPE_CLASSIC == true
        Text = Enabled and ScaleEngine:getChordSetChordName(RootNote, Index-1, UseShortNames) or ""
    else
        Enabled = Key < 128
        local Sound = NI.DATA.StateHelper.getFocusSound(App)

        Text = Enabled and ((Sound and Sound:isKeySwitch(Key) and NI.UTILS.ScaleHelper.getNoteNameChromatic(Key))
                or ScaleEngine:getNoteName(RootNote, Key)) or ""
        Focused = not PadModeHelper.isChordModeChordSet() and PadModeHelper.isRootNote(Index)
    end

    return true, Enabled, false, Focused, Text

end

------------------------------------------------------------------------------------------------------------------------

local function getScreenPadButtonState16Velocity(Index)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    return true, Sound ~= nil, false, false, Sound and tostring(math.floor(128 / 16 * Index - 1)) or ""

end

------------------------------------------------------------------------------------------------------------------------

local function getScreenPadButtonStateDefault(Index)

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil
    local FocusSound =  Sounds and Sounds:getFocusObject() or nil

    local Sound    = Sounds and Sounds:at(Index-1)
    local Enabled  = Sound and StateCache:getObjectCache():isSoundEnabled(Sound) or false
    local Focused = (Sound and Enabled) and Sound == FocusSound or false
    local Text     = Enabled and Sound:getDisplayName() or ""

    return true, Enabled, false, Focused, Text

end

------------------------------------------------------------------------------------------------------------------------
-- Functor: Visible, Enabled, Selected, Focused, Text
function PadModeHelper.getScreenPadButtonState(Index, PadMode)

    -- SELECT_NOTE_EVENTS pad mode should not change the view on Mk1/Mk2
    if PadMode == NI.HW.PAD_MODE_SELECT_NOTE_EVENTS then
        if PadModeHelper.getKeyboardMode() then
            PadMode = NI.HW.PAD_MODE_KEYBOARD
        elseif PadModeHelper.is16VelocityMode() then
            PadMode = NI.HW.PAD_MODE_16_VELOCITY
        end
    end

    if PadMode == NI.HW.PAD_MODE_KEYBOARD then
        return getScreenPadButtonStateKeyboardMode(Index)
    elseif PadMode == NI.HW.PAD_MODE_16_VELOCITY then
        return getScreenPadButtonState16Velocity(Index)
    else
        return getScreenPadButtonStateDefault(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isChordModeChordSet()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getChordModeParameter():getValue() == 2

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isChordModeEnabled()

    if PadModeHelper.getKeyboardMode() then
        local ScaleEngine = NI.DATA.getScaleEngine(App)
        return ScaleEngine and ScaleEngine:getChordModeParameter():getValue() ~= 0
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- MAS2-8249 font hack
function PadModeHelper.isChordTypeMin7b5()

    local ScaleEngine = NI.DATA.getScaleEngine(App)

    return ScaleEngine ~= nil
        and ScaleEngine:getScaleParameter():getValue() == 0
        and ScaleEngine:getChordModeParameter():getValue() == 1
        and ScaleEngine:getCurrentChordTypeParameter():getValue() == 10

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.updatePadColorsStudio(Screen)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    local KeyboardModeOn = PadModeHelper.getKeyboardMode()
    local VelocityMode = PadModeHelper.getPadVelocityMode()

    if KeyboardModeOn or VelocityMode == NI.HW.PAD_VELOCITY_16_LEVELS then

        local SoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App)

        -- iterate over pad Widgets
        for _, Button in ipairs (Screen.PadButtons) do
            ColorPaletteHelper.setSoundColor(Button, SoundIndex + 1, GroupIndex + 1)
            ColorPaletteHelper.setSoundColor(Button.Label, SoundIndex + 1, GroupIndex + 1)
            Button:setInvalid(0)
        end

    else

        Screen:refreshPadColors()

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.updatePadLEDs(Controller)

    local PadMode = NHLController:getPadMode()

    if PadMode == NI.HW.PAD_MODE_STEP then

        StepHelper.updatePadLEDs()

    elseif PadMode == NI.HW.PAD_MODE_KEYBOARD then

        local Sound = NI.DATA.StateHelper.getFocusSound(App)

        LEDHelper.updateLEDsWithFunctor(Controller.PAD_LEDS, 0,
            PadModeHelper.getKeyboardModePadStates,
            function() return Sound and Sound:getColorParameter():getValue() or 16 end,
            function(Index) return PadModeHelper.getFlashStateKeyboardMode(Index, Controller) end)

    elseif PadMode == NI.HW.PAD_MODE_16_VELOCITY then

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        LEDHelper.updateLEDsWithFunctor(Controller.PAD_LEDS, 0,
            function() return false, true end,
            function() return Sound and Sound:getColorParameter():getValue() or 16 end,
            MaschineHelper.getFlashState16LevelsNoteOn)

    else

        LEDHelper.updateLEDsWithFunctor(Controller.PAD_LEDS, 0,
                function(Index) return PadModeHelper.getPadLEDStatesSound(Index, PadModeHelper.FocusedSoundIndex) end,
                MaschineHelper.getSoundColorByIndex,
                MaschineHelper.getFlashStateSoundsNoteOn)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getFlashStateKeyboardMode(Index, Controller)

    if PadModeHelper.isChordModeChordSet() then

        local Flash = PadModeHelper.isTouchstripModeNotes()
            and NHLController:getContext():isPadStrummed(Index - 1)
            or  Controller:getAndResetCachedPadState(Index)

        return Flash

    end

    return MaschineHelper.getFlashStatePianoRollNoteOn(Index)

end


------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.isTouchstripModeNotes()

    return NHLController:getContext():getTouchstripModeParameter():getValue() == NI.HW.TS_MODE_NOTES

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.getPadLEDStatesSound(Index, FocusedSoundIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds()

    if not Sounds or Index <= 0 or Index > Sounds:size() then
        return false, false
    end

    local Sound = Sounds:at(Index - 1)

    local Selected = Index == FocusedSoundIndex
    local Enabled

    if Sound and Sound:getMuteParameter():getValue() then
        Enabled = false
    else
        Enabled = App:getStateCache():getObjectCache():isSoundEnabled(Sound)
    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.onPadEvent(PadIndex, Trigger, _)

    if Trigger and PadModeHelper.canFocusSoundOnPadTrigger() then

        PadModeHelper.FocusedSoundIndex = PadIndex
        MaschineHelper.setFocusSound(PadIndex, false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModeHelper.canFocusSoundOnPadTrigger()

    local Recording = MaschineHelper.isRecording() and MaschineHelper.isPlaying()
    local PadMode = NHLController:getPadMode()

    return not Recording
            and PadMode ~= NI.HW.PAD_MODE_KEYBOARD
            and PadMode ~= NI.HW.PAD_MODE_16_VELOCITY
            and PadMode ~= NI.HW.PAD_MODE_STEP
            and PadMode ~= NI.HW.PAD_MODE_NONE

end

------------------------------------------------------------------------------------------------------------------------
