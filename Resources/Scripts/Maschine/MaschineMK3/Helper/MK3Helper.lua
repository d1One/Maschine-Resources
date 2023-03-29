------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MK3Helper = class( 'MK3Helper' )

------------------------------------------------------------------------------------------------------------------------

function MK3Helper.isPadModePageButton(Button)

    return Button == NI.HW.BUTTON_PAD_MODE
        or Button == NI.HW.BUTTON_KEYBOARD
        or Button == NI.HW.BUTTON_CHORDS

end

------------------------------------------------------------------------------------------------------------------------

function MK3Helper.isPadModePage(Page)

    return Page == NI.HW.PAGE_PAD
        or Page == NI.HW.PAGE_KEYBOARD
        or Page == NI.HW.PAGE_CHORD
        or Page == NI.HW.PAGE_SIXTEEN_VEL
        or Page == NI.HW.PAGE_STEP_STUDIO

end

------------------------------------------------------------------------------------------------------------------------

function MK3Helper.getPageForPadModeButton(Button)

    if Button == NI.HW.BUTTON_PAD_MODE then
        return NI.HW.PAGE_PAD
    elseif Button == NI.HW.BUTTON_KEYBOARD then
        return NI.HW.PAGE_KEYBOARD
    elseif Button == NI.HW.BUTTON_CHORDS then
        return NI.HW.PAGE_CHORD
    elseif Button == NI.HW.BUTTON_FIX_VELOCITY then
        return NI.HW.PAGE_SIXTEEN_VEL
    elseif Button == NI.HW.BUTTON_STEP then
        return NI.HW.PAGE_STEP_STUDIO
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MK3Helper.setPadModeParametersByButton(Button)

    if PadModeHelper.is16VelocityMode() then

        PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_16_LEVELS)

    end

    PadModeHelper.setStepModeEnabled(Button == NI.HW.BUTTON_STEP)

    if Button == NI.HW.BUTTON_STEP then
        return
    end

    local ScaleEngine = NI.DATA.getScaleEngine(App)
    local ChordModeParameter = ScaleEngine and ScaleEngine:getChordModeParameter()
    local ChordModeValue = 0

    PadModeHelper.setKeyboardMode(Button == NI.HW.BUTTON_KEYBOARD or Button == NI.HW.BUTTON_CHORDS)


    if Button == NI.HW.BUTTON_CHORDS then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local LastChordMode = Group and Group:getLastActiveChordModeParameter():getValue() or 1
        ChordModeValue = (LastChordMode == 0) and 1 or LastChordMode

    end

    if ChordModeParameter then
        NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, ChordModeParameter, ChordModeValue)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MK3Helper.togglePlayPadsInNotesModeParameter()

    local PlayPadsInNotesModeParameter = App:getWorkspace():getPlayPadsInNotesModeEnabledParameter()
    NI.DATA.ParameterAccess.toggleBoolParameterNoUndo(App, PlayPadsInNotesModeParameter)

end

------------------------------------------------------------------------------------------------------------------------
