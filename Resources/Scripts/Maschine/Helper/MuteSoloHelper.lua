------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MuteSoloHelper = class( 'MuteSoloHelper' )

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.setMuteForAllSounds(Mute)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group then
        NI.DATA.GroupAccess.setMuteAllSounds(App, Group, Mute)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.setMuteForAllGroups(Mute)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        NI.DATA.SongAccess.setMuteAllGroups(App, Song, Mute)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.toggleMuteState(ObjectVector, Index)

    -- mute / unmute sound by pad index
    local MuteFunction =
    function(Objects, Object)
        local MuteParameter = Object:getMuteParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
    end

    MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(ObjectVector, Index, MuteFunction)

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.toggleSoundMuteState(SoundIndex)

    local MuteSoundFunction =
    function(_, Sound)
        local MuteParameter = Sound:getMuteParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Sounds, SoundIndex, MuteSoundFunction)

end

------------------------------------------------------------------------------------------------------------------------
-- getSoundMuteByIndexLEDStates
------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.getSoundMuteByIndexLEDStates(SoundIndex, AudioModeOn) -- index >= 1

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    local Enabled = Sounds and StateCache:getObjectCache():isSoundEnabled(Sounds:at(SoundIndex - 1)) or false
    local Selected = false


    if Enabled and Sounds and SoundIndex > 0 and SoundIndex <= Sounds:size() then

        if AudioModeOn then
            Selected = Sounds:at(SoundIndex - 1):getMuteAudioParameter():getValue()
        else
            Selected = not Sounds:at(SoundIndex - 1):getMuteParameter():getValue()
        end

    end

	return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function MuteSoloHelper.getMuteButtonStateSounds(Sounds, Index, AudioMode)

    local StateCache        = App:getStateCache()
    local Sound             = Sounds and Sounds:at(Index-1)
    local Enabled           = Sound and StateCache:getObjectCache():isSoundEnabled(Sound) or false


    local Name   = Sound and Sound:getDisplayName() or ""

    if Enabled and Sound then
        if AudioMode then
            return true, Enabled, false, Sound:getMuteAudioParameter():getValue(), Name
        else
            return true, Enabled, false, not Sound:getMuteParameter():getValue(), Name
        end
    end

    return true, false, false, false, ""

end


------------------------------------------------------------------------------------------------------------------------
-- getGroupMuteByIndexLEDStates
------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.getGroupMuteByIndexLEDStates(GroupIndex) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local Selected   = false
    local Enabled    = false
    local ColorIndex = 0

    if Groups and GroupIndex > 0 and GroupIndex <= Groups:size() then
        local Group = Groups:at(GroupIndex - 1)
        Enabled = Group and true or false
        Selected = Group and not Group:getMuteParameter():getValue()
        ColorIndex = Group and Group:getColorParameter():getValue()
    end

    return Selected, Enabled, ColorIndex

end

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text
function MuteSoloHelper.getMuteButtonStateGroups(ObjectVector, Index)

    local StateCache    = App:getStateCache()
    local Object        = ObjectVector and ObjectVector:at(Index-1) or nil
    local Name          = Object and Object:getDisplayName() or ""

    if Object then
        return true, true, false, not Object:getMuteParameter():getValue(), Name
    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------
-- ex-SoloHelper starts here
------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.setSoloForAllGroups(Solo)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        NI.DATA.SongAccess.setMuteAllGroups(App, Song, not Solo)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MuteSoloHelper.setSoloForAllSounds(Solo)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        NI.DATA.GroupAccess.setMuteAllSounds(App, Group, not Solo)
    end

end


------------------------------------------------------------------------------------------------------------------------
-- 1 based
function MuteSoloHelper.toggleGroupSoloState(GroupIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at(GroupIndex - 1) or nil

    if Group then
        NI.DATA.SongAccess.setMuteExclusive(App, Song, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- 1 based
function MuteSoloHelper.toggleSoundSoloState(SoundIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = Group and Group:getSounds():at(SoundIndex - 1) or nil

    if Sound then
        NI.DATA.GroupAccess.setMuteExclusive(App, Group, Sound)
    end

end

------------------------------------------------------------------------------------------------------------------------
