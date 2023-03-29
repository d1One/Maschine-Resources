------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ActionHelper = class( 'ActionHelper' )

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.invokeActionFunction(PadIndex)

    if PadIndex == 1 then
        App:getTransactionManager():undoTransactionMarker()			-- Undo combined
    elseif PadIndex == 2 then
        App:getTransactionManager():redoTransactionMarker()		    -- Redo combined
    elseif PadIndex == 3 then
        App:getTransactionManager():undoTransaction()					-- Undo single step
    elseif PadIndex == 4 then
        App:getTransactionManager():redoTransaction()					-- Redo single step
    elseif PadIndex == 5 then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, false)	-- Full
    elseif PadIndex == 6 then
        NI.DATA.EventPatternTools.quantizeNoteEvents(App, true)    -- 50%
    elseif PadIndex == 7 then
        NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, -1, false, false)-- Left
    elseif PadIndex == 8 then
        NI.DATA.EventPatternTools.nudgeEventsInPatternRange(App, 1, false, false) -- Right
    elseif PadIndex == 9 then
        NI.DATA.EventPatternTools.removeNoteAndAudioEvents(App)    -- Clear notes and audio events
    elseif PadIndex == 10 then
        NI.DATA.EventPatternTools.removeModulationEvents(App)      -- Clear modulation / automation
    elseif PadIndex == 11 then
        NI.DATA.NoteEventClipboardAccess.copySelectedNoteEvents(App)     -- Copy
    elseif PadIndex == 12 then
        NI.DATA.NoteEventClipboardAccess.pasteNoteEvents(App)            -- Paste
    elseif PadIndex == 13 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, -1)     -- Semitone -
    elseif PadIndex == 14 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, 1)      -- Semitone +
    elseif PadIndex == 15 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, -12)    -- Octave -
    elseif PadIndex == 16 then
        NI.DATA.EventPatternTools.transposeNoteEvents(App, 12)     -- Octave +
    end

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.hasSoundEvents()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local SoundSeq = Pattern and Pattern:getSoundSequence(Sound)
    return SoundSeq and not SoundSeq:empty() or false

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.hasGroupEvents()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    return Pattern and not Pattern:isEmpty() or false

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.hasEvents()

    if PadModeHelper.getKeyboardMode() or NHLController:getPageStack():getTopPage() == NI.HW.PAGE_STEP_STUDIO then
        return ActionHelper.hasSoundEvents()
    end

    return ActionHelper.hasGroupEvents()

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.canPaste()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    return Pattern and not NI.DATA.NoteEventClipboardAccess.isClipboardEmpty()

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.canUndo(Step)

    return Step and App:getTransactionManager():canUndo() or App:getTransactionManager():canUndoMarker()

end

------------------------------------------------------------------------------------------------------------------------

function ActionHelper.canRedo(Step)

    return Step and App:getTransactionManager():canRedo() or App:getTransactionManager():canRedoMarker()

end

------------------------------------------------------------------------------------------------------------------------
