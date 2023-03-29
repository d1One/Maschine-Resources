------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/PadModeHelper"
require "Scripts/Shared/Helpers/MiscHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JamStepHelper = class( 'JamStepHelper' )

JamStepHelper.NUM_OCTAVES = 10
JamStepHelper.NUM_NOTES_PER_OCTAVE = 12

------------------------------------------------------------------------------------------------------------------------

function JamStepHelper.isNoteOnScale(Note)

    return NI.UTILS.ScaleHelper.getBankScaleOffsetForNote(PadModeHelper.getRootNote(),
        PadModeHelper.getCurrentBank(), PadModeHelper.getCurrentScale(), Note) == 0

end

------------------------------------------------------------------------------------------------------------------------

function JamStepHelper.getNumNotesOnLastOctave()

    local Count = 0
    local StartingNote = JamStepHelper.NUM_OCTAVES * JamStepHelper.NUM_NOTES_PER_OCTAVE

    for Note = StartingNote, StepPage.MAX_NOTE_VALUE - 1 do -- 120 to 127 is not a full octave

        if JamStepHelper.isNoteOnScale(Note) then
            Count = Count + 1
        end

    end

    return Count

end

------------------------------------------------------------------------------------------------------------------------

function JamStepHelper.calcNoteArray()

    local Index = 0;
    local Notes = {}

    for Note = 0, JamStepHelper.NUM_NOTES_PER_OCTAVE - 1 do

        if JamStepHelper.isNoteOnScale(Note) then
            Notes[Index] = Note
            Index = Index + 1
        end

    end

    return Notes

end

------------------------------------------------------------------------------------------------------------------------

function JamStepHelper.getRowColumnFromPadId(PadId)

    local Row, Col
    for R, RowIds in ipairs(JamControllerBase.PAD_BUTTONS) do

        for C, ButtonId in ipairs(RowIds) do
            if ButtonId == PadId then
                Row = R
                Col = C
                return Row, Col
            end
        end

    end

    return Row, Col

end

------------------------------------------------------------------------------------------------------------------------

function JamStepHelper.QuickEditModeToJogwheelMode(QEMode)

    if QEMode == NI.HW.QUICK_EDIT_VELOCITY then
        return NI.HW.JOGWHEEL_MODE_VOLUME
    elseif QEMode == NI.HW.QUICK_EDIT_PITCH then
        return NI.HW.JOGWHEEL_MODE_TEMPO
    elseif QEMode == NI.HW.QUICK_EDIT_POSITION then
        return NI.HW.JOGWHEEL_MODE_SWING
    elseif QEMode == NI.HW.QUICK_EDIT_LENGTH then
        return NI.HW.JOGWHEEL_MODE_LENGTH
    end

    return NI.HW.JOGWHEEL_MODE_OFF

end

------------------------------------------------------------------------------------------------------------------------
