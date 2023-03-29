require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/PatternHelper"

local class = require 'Scripts/Shared/Helpers/classy'
IdeaSpaceController = class( 'IdeaSpaceController' )

function IdeaSpaceController:__init()
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:selectPrevNextScene(Next)

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    if FocusSong then
        NI.DATA.IdeaSpaceAccess.shiftSceneFocus(App, FocusSong, Next)
    end

end
------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:focusPrevNextPattern(Next)

    local FirstItemDeselects = true
    PatternHelper.focusPrevNextPattern(Next, FirstItemDeselects)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:createScene()

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    if FocusSong then
        NI.DATA.IdeaSpaceAccess.createScene(App, FocusSong)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:createPattern()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.GroupAccess.insertPattern(App, Group, nil)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:incrementPatternLength(Delta, Fine)

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        NI.DATA.EventPatternAccess.changeFocusClipEventLength(App, Delta > 0 and 1 or -1, Fine)
    else
        PatternHelper.incrementPatternLength(Delta, Fine)
    end

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceController:clearFocusPattern()

    local Tools = NI.DATA.EventPatternTools
    local ClearSelectedNotesOnly = Tools.getNumSelectedNoteEventsInPatternRange(App) > 0

    local DrumkitModeClearPatternFunc = ClearSelectedNotesOnly and Tools.removeNoteAndAudioEvents or Tools.removeAllEventsFromGroup
    local SoundModeClearPatternFunc = ClearSelectedNotesOnly and Tools.removeNoteAndAudioEventsFromFocusedSound or Tools.removeAllEventsFromFocusedSound

    local ClearPatternFunc = MaschineHelper.isDrumkitMode() and DrumkitModeClearPatternFunc or SoundModeClearPatternFunc

    ClearPatternFunc(App)

end
