require "Scripts/Shared/Helpers/ActionHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

local class = require 'Scripts/Shared/Helpers/classy'
IdeaSpaceModel = class( 'IdeaSpaceModel' )

function IdeaSpaceModel:__init()
end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:getFocusSceneName()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scenes = Song and Song:getScenes()
    local Scene = Scenes and Scenes:getFocusObject()
    return Scene and Scene:getNameParameter():getValue() or "No Scene"

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:getFocusPatternName()

    local ClipsInFocus = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local NoPattern = ClipsInFocus and "No Clip" or "No Pattern"
    return Pattern and Pattern:getNameParameter():getValue() or NoPattern

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:getFocusPatternLengthString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getTickToString(NI.DATA.StateHelper.getFocusPatternLength(App)) or "-"

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:isOnLastScene()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return false
    end
    local Scenes = Song:getScenes()
    local NumScenes = Scenes:size()
    local FocusScene = Scenes:getFocusObject()
    local FocusSceneIndexOneBased = Scenes:calcIndex(FocusScene) + 1
    return FocusSceneIndexOneBased == NumScenes

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:isOnLastPattern()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if not Group then
        return false
    end
    return NI.DATA.GroupAlgorithms.isNextFocusedPatternSlotNeedingNewPattern(Group)

end

------------------------------------------------------------------------------------------------------------------------

function IdeaSpaceModel:isAnythingToClearInFocusPattern()

    return MaschineHelper.isDrumkitMode() and ActionHelper.hasGroupEvents() or ActionHelper.hasSoundEvents()

end
