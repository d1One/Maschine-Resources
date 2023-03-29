
require "Scripts/Shared/Helpers/ActionHelper"
require "Scripts/Shared/Helpers/EventsHelper"

------------------------------------------------------------------------------------------------------------------------

MaschineHelper = {}

KnobEncoderCounter = {0,0,0,0,0,0,0,0}

------------------------------------------------------------------------------------------------------------------------
-- Save Project
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.saveProject(InfoBar, TempInfoBarMode)

    local saveSucceded = NI.HW.ProjectFileCommands.saveProject(App)

    if InfoBar and saveSucceded then
        local Mode = TempInfoBarMode ~= nil and TempInfoBarMode or "ProjectSaved"
        InfoBar:setTempMode(Mode)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Screen Encoder Smoother
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.resetScreenEncoderSmoother()

    KnobEncoderCounter = {0,0,0,0,0,0,0,0}

end

------------------------------------------------------------------------------------------------------------------------
-- onScreenEncoderSmoother: Smoother that's used predominantly for non-float values that change with encoders that we
-- don't want to be so sensitive.
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.onScreenEncoderSmoother(KnobIdx, KnobValue, Threshold)

    local RetVal = 0

    if KnobValue * KnobEncoderCounter[KnobIdx] < 0 then

        -- reset the current delta if signs (knob direction) changes
        KnobEncoderCounter[KnobIdx] = 0

    else

        KnobEncoderCounter[KnobIdx] = KnobEncoderCounter[KnobIdx] + KnobValue

        if KnobValue >= 0 and KnobEncoderCounter[KnobIdx] >= Threshold then

            RetVal = math.floor(KnobEncoderCounter[KnobIdx] / Threshold)
            KnobEncoderCounter[KnobIdx] = KnobEncoderCounter[KnobIdx] - Threshold*RetVal

        elseif KnobValue <= 0 and KnobEncoderCounter[KnobIdx] <= -Threshold then

            RetVal = math.ceil(KnobEncoderCounter[KnobIdx] / Threshold)
            KnobEncoderCounter[KnobIdx] = KnobEncoderCounter[KnobIdx] - Threshold*RetVal

        end

    end

    return RetVal

end

------------------------------------------------------------------------------------------------------------------------
-- compare 2 lists containing Size parameters
function MaschineHelper.areParameterListsEqual(List1, List2, Size)

    if List1 == nil and List2 ~= nil or List1 ~= nil and List2 == nil then
        return false
    end

    for Index = 1, Size do

           if (List1[Index] == nil and List2[Index] ~= nil) or (List2[Index] == nil and List1[Index] ~= nil)
           or (List1[Index] and List2[Index] and not List1[Index]:isParameterEqual(List2[Index])) then
            return false
        end

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isArpRepeatActive()

    local Param = NI.HW.getArpeggiatorActiveParameter(App)
    return Param and Param:getValue()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isArpRepeatLocked()

    return NI.DATA.SongAccess.isArpRepeatLocked(App)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setArpRepeatLockState(App, Set)

    if MaschineHelper.isArpRepeatLocked() ~= Set then
        NI.DATA.SongAccess.setArpRepeatLockState(App, Set)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.toggleArpRepeatLockState()

    NI.DATA.SongAccess.setArpRepeatLockState(App, not MaschineHelper.isArpRepeatLocked())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.removeSound(SoundIndex)

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if FocusGroup then
        local RemoveSoundFunction = function(Sounds, Sound)
            NI.DATA.ObjectVectorAccess.resetSound(App, Sound)
        end

        MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(FocusGroup:getSounds(), SoundIndex, RemoveSoundFunction)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- Handler for pad events, when shift is pressed
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.onPadEventShift(PadIndex, Trigger, Erase, SuppressActionFunctions)

    if not Trigger then
        return false
    end

    local PadMode = NHLController:getPadMode()

    ---- LOOP PAGE MODE ----
    if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_LOOP then
        return false

    ---- SELECT MODE ----
    elseif PadMode == NI.HW.PAD_MODE_SELECT_NOTE_EVENTS then

        EventsHelper.selectEventsByPad(PadIndex)
        return true

    ---- ERASE MODE ----
    elseif Erase and PadMode == NI.HW.PAD_MODE_SOUND then

        MaschineHelper.removeSound(PadIndex)
        return true

    ---- ACTION FUNCTIONS ----
    elseif not Erase and not SuppressActionFunctions then

        ActionHelper.invokeActionFunction(PadIndex) -- Call Shift functions on pads
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- Sound state functor for the on-screen grid button states
-- Functor: Visible, Enabled, Selected, Focused, Text
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.SoundStateFunctor(ButtonIndex)

    local StateCache = App:getStateCache()
    local Group      = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound      = Group and Group:getSounds():at(ButtonIndex-1) or nil
    local Enabled    = Sound and StateCache:getObjectCache():isSoundEnabled(Sound) or false
    local Focused    = Sound == NI.DATA.StateHelper.getFocusSound(App)

    if Sound then
        return true, Enabled or Focused, false, Focused, Enabled and Sound:getDisplayName() or ""
    else
        return true, false, false, false, ""
    end

end

------------------------------------------------------------------------------------------------------------------------
-- getPatternNameByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getPatternNameByIndex(PatternIndex) -- index >= 1

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group and PatternIndex > 0 then
        local Pattern = Group:getPatterns():find(PatternIndex - 1)

        if Pattern then
            return Pattern:getNameParameter():getValue()
        end
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------
-- getPatternColorByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getPatternColorByIndex(PatternIndex) -- index >= 1

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if  Group and PatternIndex > 0 then
        local Pattern = Group:getPatterns():find(PatternIndex - 1)

        if  Pattern then
            return Pattern:getColorParameter():getValue()
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getClipColorByIndex(Index, CanAdd) -- index >= 1

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ClipEvent = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index - 1) or nil
    local Pattern = ClipEvent and ClipEvent:getEventPattern() or nil

    if Pattern then
        return Pattern:getColorParameter():getValue()
    elseif CanAdd and Group and Index - 1 == Group:getClipSequence():size() then
        return LEDColors.WHITE
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getIdeaSpaceSceneColorByIndex(SceneIndex, CanAdd) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and SceneIndex > 0 then
        local Scene = Song:getScenes():at(SceneIndex - 1)

        if Scene then
            return Scene:getColorParameter():getValue()
        elseif CanAdd and SceneIndex - 1 == Song:getScenes():size() then  -- "+" button
            return LEDColors.WHITE
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getSectionSceneColorByIndex(SectionIndex) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and SectionIndex > 0 then
        local Section = Song:getSections():find(SectionIndex - 1)

        if Section then
            return NI.DATA.SectionAlgorithms.getColor(Section)
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------
-- getSoundColorByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getSoundColorByIndex(SoundIndex, GroupIndex) -- indexes >= 1, GroupIndex can be nil

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    local Sounds = nil

    if GroupIndex then
        local Group = Song:getGroups():at(GroupIndex-1)

        if Group then
            Sounds = Group:getSounds()
        end
    else
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        Sounds = Group and Group:getSounds()
    end

    local Sound = Sounds and Sounds:at(SoundIndex - 1)
    return Sound and Sound:getColorParameter():getValue() or 0

end

------------------------------------------------------------------------------------------------------------------------
-- getGroupColorByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getGroupColorByIndex(GroupIndex, IncludeNewGroup) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = Song and Song:getGroups():at(GroupIndex - 1)

    if Group then

        return Group:getColorParameter():getValue()

    elseif Song and GroupIndex == Song:getGroups():size() + 1 and IncludeNewGroup then

        return LEDColors.WHITE
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusGroupColor()

    return MaschineHelper.getGroupColorByIndex(NI.DATA.StateHelper.getFocusGroupIndex(App) + 1)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusMixingLayerColor()
    local MixingLayer = NI.DATA.StateHelper.getFocusMixingLayer(App)
    local ColorParameter = MixingLayer and MixingLayer:getColorParameter()
    return ColorParameter and ColorParameter:getValue() + 1 or 0
end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.removeGroup(GroupIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups and Groups:at(GroupIndex - 1) -- 0 based indexing
    if Group then
        NI.DATA.ObjectVectorAccess.removeGroupResetLast(App, Groups, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.removeFocusGroup()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()
    local Group = Groups:getFocusObject()
    if Group then
        NI.DATA.ObjectVectorAccess.removeGroupResetLast(App, Groups, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- getObjectVectorIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getObjectVectorIndex(Vector, Object)

    if Vector then
        return Vector:calcIndex(Object) + 1
    end

    return 0

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesSoundFocusByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesSoundFocusByIndex(SoundIndex, CheckMuteState) -- index >= 1

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)

    if  Sounds and
        SoundIndex > 0 and
        SoundIndex <= Sounds:size() then

        local Sound = Sounds:at(SoundIndex - 1)

        if CheckMuteState and Sound and Sound:getMuteParameter():getValue() then
            return Sound == FocusSound, false
        end

        local Enabled = StateCache:getObjectCache():isSoundEnabled(Sound)
        return Sound == FocusSound, Enabled

    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesSoundSelectedByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesSoundSelectedByIndex(SoundIndex) -- index >= 1

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)

    if  Sounds and
        SoundIndex > 0 and
        SoundIndex <= Sounds:size() then

            local Sound = Sounds:at(SoundIndex-1)

            local Enabled = StateCache:getObjectCache():isSoundEnabled(Sound)

            local Selected = Sound and Sounds:isInSelection(Sound) or Sound == FocusSound

            return Selected, Enabled
    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesGroupFocusByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesGroupFocusByIndex(GroupIndex, IncludeNewGroup) -- index >= 1

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local Groups     = Song and Song:getGroups() or nil
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    local Size = Groups and (Groups:size() + (IncludeNewGroup and 1 or 0)) or 0
    local Enabled = Groups and (GroupIndex > 0 and GroupIndex <= Size) or false
    local Focused = (Groups and FocusGroup) and (Groups:at(GroupIndex - 1) == FocusGroup) or false

    return Focused, Enabled

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesGroupSelectedByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesGroupSelectedByIndex(GroupIndex, IncludeNewGroup, NewGroupSelected) -- index >= 1

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local Groups     = Song and Song:getGroups() or nil
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if IncludeNewGroup and Groups and GroupIndex == Groups:size() + 1 then
         return NewGroupSelected, true
    end

    if  Groups and
        GroupIndex > 0 and
        GroupIndex <= Groups:size() then

        local Group = Groups:at(GroupIndex - 1)
        local Selected = Group and Groups:isInSelection(Group)
        return Selected, true
    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesSoundEventsByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesSoundEventsByIndex(SoundIndex, ErasePressed) -- index >= 1

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = Group and Group:getSounds():at(SoundIndex - 1) or nil
    if not Sound then
        return false, false
    end

    local HasEvents = NI.DATA.EventPatternTools.hasEventsForSound(App, Sound)

    -- if erase is pressed, led should be full lit
    local Selected = ErasePressed and HasEvents
        or NI.DATA.EventPatternTools.allEventsSelectedForSound(App, Sound)

    return Selected, HasEvents

end

------------------------------------------------------------------------------------------------------------------------
-- getLEDStatesNoteEventsByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLEDStatesNoteEventsByIndex(PadIndex, ErasePressed) -- index >= 1

    local NoteIndex = PadModeHelper.getNoteForPad(PadIndex)

    if NoteIndex >= 0 and NoteIndex < 128 then

        local HasNoteEvents = NI.DATA.EventPatternTools.hasEventsForNote(App, NoteIndex)

        -- if erase is pressed, led should be full lit
        local Selected = HasNoteEvents and (ErasePressed
            or NI.DATA.EventPatternTools.allEventsSelectedForNote(App, NoteIndex))

        return Selected, HasNoteEvents

    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------
-- isPatternFocusByIndex
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isPatternFocusByIndex(PatternIndex) -- index >= 1

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if  Group and
        PatternIndex > 0 then

        local Pattern = Group:getPatterns():find(PatternIndex - 1)

        if  Pattern then
            return Pattern == FocusPattern, true
        end
    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isClipFocusByIndex(ClipIndex, CanAdd) -- index >= 1
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if  Group and
        ClipIndex > 0 then

        local ClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, ClipIndex - 1)
        if  ClipEvent then
            return ClipHelper.isClipEventInFocus(Group, ClipEvent), true
        elseif CanAdd and ClipIndex - 1 == Group:getClipSequence():size() then  -- "+" button
            return false, true
        end
    end

    return false, false
end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isSceneFocusByIndex(SceneIndex, CanAdd, AppendMode) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song and SceneIndex > 0 then

        local Scene = Song:getScenes():at(SceneIndex - 1)

        if Scene then
            return not AppendMode and Scene == NI.DATA.StateHelper.getFocusScene(App), true

        elseif CanAdd and SceneIndex - 1 == Song:getScenes():size() then  -- "+" button

            return false, true
        end

    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isSectionFocusByIndex(SectionIndex) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local FocusSection = NI.DATA.StateHelper.getFocusSection(App)

    if Song and SectionIndex > 0 then

        local Section = Song:getSections():find(SectionIndex - 1)

        if Section then
            return Section == FocusSection, true
        end

    end

    return false, false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isSectionSelectedByIndex(SectionIndex) -- index >= 1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local FocusSection = NI.DATA.StateHelper.getFocusSection(App)

    local Selected = false
    local Enabled = true

    if Song and SectionIndex > 0 then

        local Section = Song:getSections():find(SectionIndex - 1)

        if Section then
            local IsSectionPartOfLoop = NI.DATA.SongAlgorithms.isSectionPartOfLoop(Song, Section)
            local IsFocusSection = Section == FocusSection

            if not NI.DATA.SongAlgorithms.isIdeaSpaceFocused(Song) then
                Selected = IsSectionPartOfLoop or IsFocusSection
            end
        else
            Enabled = false
        end

    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------
-- getFocusSongGroupCount
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusSongGroupCount()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    return Groups and Groups:size() or 0

end

------------------------------------------------------------------------------------------------------------------------
-- getFocusGroupBank: returns 0-indexed group index.
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusGroupBank(Page)

    if Page and Page.Screen and Page.Screen.GroupBank and Page.Screen.GroupBank >= 0 then
        return Page.Screen.GroupBank -- The page manages the group bank which may be independent of the focused Group
    else
        local GroupIdx	= NI.DATA.StateHelper.getFocusGroupIndex(App)

        return GroupIdx ~= NPOS and math.floor(GroupIdx / 8) or 0
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getNumFocusSongGroupBanks(IncludeNewGroup)

    -- add 1, if a new bank should be considered, when the last bank is full
    return math.ceil((MaschineHelper.getFocusSongGroupCount() + (IncludeNewGroup and 1 or 0)) / 8)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setFocusGroupBankAndGroup(Page, BankIndex, DoFocusGroup, IncludeNewGroup)  -- BankIndex >= 0

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    if  Song
        and Groups
        and BankIndex >= 0
        and BankIndex < MaschineHelper.getNumFocusSongGroupBanks(IncludeNewGroup) then

        local Group = Groups:at(BankIndex * 8) -- get first group in bank

        if DoFocusGroup then
            MaschineHelper.setFocusGroup(BankIndex * 8 + 1, IncludeNewGroup)
        elseif Page.Screen.GroupBank then
            Page.Screen.GroupBank = BankIndex
        else
            error("Setting Group Bank in MaschineHelper.setFocusGroupBankAndGroup() failed")
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.incrementFocusGroupBank(Page, Delta, DoFocusGroup, IncludeNewGroup)

    if Delta ~= 0 then
        MaschineHelper.setFocusGroupBankAndGroup(Page, MaschineHelper.getFocusGroupBank(Page) + Delta, DoFocusGroup, IncludeNewGroup)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- setAllSoundsSelected
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setAllSoundsSelected(Select, SelectEvents)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group then
        NI.DATA.GroupAccess.setAllSoundsSelected(App, Group, Select, SelectEvents==true)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- setAllGroupsSelected
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setAllGroupsSelected(Select)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if Song then
        NI.DATA.SongAccess.setAllGroupsSelected(App, Song, Select)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- onSelectMulti
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.toggleMultiSelectParameter()

    local Workspace = App:getWorkspace();

    NI.DATA.ParameterAccess.setBoolParameter(App, Workspace:getSelectMultiParameter(),
        not Workspace:getSelectMultiParameter():getValue())

end

-----------------------------------------------------------------------------------------------------------------------
-- callFunctionWithObjectVectorAndItemByIndex
--
-- gets item by index from object vector and calls function with vector and item by index as parameters
--
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Vector, ItemIndex, Function) -- index >= 1

    if  Function and
        Vector and
        ItemIndex > 0 and
        ItemIndex <= Vector:size() then

            local Item = Vector:at(ItemIndex - 1)

            if Item then
                return Function(Vector, Item)
            end
    end

    return nil

end

-----------------------------------------------------------------------------------------------------------------------
-- callFunctionWithObjectMapAndItemByIndex
--
-- gets item by index from object map and calls function with vector and item by index as parameters
--
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.callFunctionWithObjectMapAndItemByIndex(Map, ItemIndex, Function) -- index >= 1

    if  Function and
        Map and
        ItemIndex > 0 then

            local Item = Map:find(ItemIndex - 1)

            if Item then
                return Function(Map, Item)
            end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------
-- set focus objects
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setFocusSound(Index, Instant) -- 1-indexed

    local Group  = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds()
    local Sound	 = Sounds and Sounds:at(Index - 1)

    if Sound then
        if Instant then
            NI.DATA.GroupAccess.setFocusSound(App, Group, Sound, false)
        else
            NI.DATA.GroupAccess.setFocusSoundNonRepeating(App, Group, Sound, false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setFocusGroup(Index, IncludeNewGroup)   -- is 1-Indexed

    local Song   = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil

    if Groups then
        if IncludeNewGroup and Index == Groups:size() + 1 then
            -- create new Group
            NI.DATA.SongAccess.createGroup(App, Song, false)
        else
            local Group = Groups:at(Index - 1)
            if Group then
                NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.removeObject(ObjectVector, Index)

    local RemoveFunction =
    function(Objects, Object)
        NI.DATA.ObjectVectorAccess.removeGroup(App, Objects, Object)
    end

    MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(ObjectVector, Index, RemoveFunction)

end

------------------------------------------------------------------------------------------------------------------------
-- selectPrevNextSound selects the previous (if Value <= 0) sound or next (Value > 0) sound
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.selectPrevNextSound(Value)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    if Sounds then

        local SoundIndex = NI.DATA.StateHelper.getFocusSoundIndex(App) + (Value <= 0 and -1 or 1)

        SoundIndex = SoundIndex >= Sounds:size() and 0 or SoundIndex
        SoundIndex = SoundIndex < 0 and Sounds:size() - 1 or SoundIndex

        local Sound = Sounds:at(SoundIndex)

        if Sound then
            NI.DATA.ObjectVectorAccess.setFocusSound(App, Sounds, Sound)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.selectSoundByPadIndex(PadIndex, Trigger)

    -- ON Event
    if Trigger then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sounds = Group and Group:getSounds() or nil

        if App:getWorkspace():getSelectMultiParameter():getValue() then

            -- select/deselect sound by pad index
            local SelectSoundFunction =
                function(Sounds, Sound)
                    if Sound then
                        local HasSelection = Sounds:isInSelection(Sound)
                        if HasSelection then
                            NI.DATA.ObjectVectorAccess.removeSoundFromSelection(App, Sounds, Sound)
                        else
                            NI.DATA.ObjectVectorAccess.addSoundToSelection(App, Sounds, Sound)
                        end
                    end
                end

            -- call solo function
            MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Sounds, PadIndex, SelectSoundFunction)

        else

            if Sounds and PadIndex <= Sounds:size() then
                local Sound = Sounds:at(PadIndex-1)

                if Sound then
                    NI.DATA.ObjectVectorAccess.setFocusSound(App, Sounds, Sound)
                end
            end
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.selectGroupByIndex(GroupIndex) -- GroupIndex is 0-indexed

    local Song   = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local Group  = Groups and Groups:at(GroupIndex) or nil

    if Song == nil or Groups == nil then
        error("SelectGroupByIndex: Song or Groups is nil.")
        return
    end

    if Group then

        -- set focus
        if App:getWorkspace():getSelectMultiParameter():getValue() then

            if Groups:isInSelection(Group) then
                NI.DATA.ObjectVectorAccess.removeGroupFromSelection(App, Groups, Group)
            else
                NI.DATA.ObjectVectorAccess.addGroupToSelection(App, Groups, Group)
            end

        else

            NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)

        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Led Flash States
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFlashStateSoundsNoteOn(Index)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sounds = Group and Group:getSounds() or nil

    if  Sounds and Index > 0 and Index <= Sounds:size() then

        return App:getStateCache():isNoteOn(Index - 1, 0)

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFlashStatePianoRollNoteOn(Index, IsJam)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Note = Song and Song:getNoteForPad(Index - 1, IsJam or false) or 0

    return Song and App:getStateCache():isNoteOn(Note, 1)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFlashState16LevelsNoteOn(Index)

    return App:getStateCache():isNoteOn(Index - 1, 2)

end

------------------------------------------------------------------------------------------------------------------------
-- returns (group at given 0-based index)
------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getGroupAtIndex(GroupIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getGroups():at(GroupIndex)
end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFlashStateGroupsNoteOn(Index) -- >= 1

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()

    if Groups and Index > 0 and Index <= Groups:size() then

        -- GroupIndex is >= 0
        local GroupIndex = Index - 1
        return StateCache:isNoteOn(GroupIndex, 3)

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getModulationString(Parameter, Delta)

    local ValueString = "?"

    if Parameter then
        local Tag = Parameter:getTag()

        if Tag == NI.DATA.MaschineParameter.TAG_ENUM or Tag == NI.DATA.MaschineParameter.TAG_INT or
           Tag == NI.DATA.MaschineParameter.TAG_BOOL or Tag == NI.DATA.MaschineParameter.TAG_FLOAT or
           Tag == NI.DATA.MaschineParameter.TAG_PLUGIN or Tag == NI.DATA.MaschineParameter.TAG_DOUBLE then
            ValueString = NI.DATA.ParameterAccess.getModulationString(Parameter, Delta)

        end
    end

    return ValueString

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getModulatedValueNormalized(Parameter)

    if Parameter then
        local Tag = Parameter:getTag()

        if Tag == NI.DATA.MaschineParameter.TAG_ENUM or Tag == NI.DATA.MaschineParameter.TAG_INT or
           Tag == NI.DATA.MaschineParameter.TAG_BOOL or Tag == NI.DATA.MaschineParameter.TAG_FLOAT or
           Tag == NI.DATA.MaschineParameter.TAG_PLUGIN or Tag == NI.DATA.MaschineParameter.TAG_DOUBLE then
            return NI.DATA.ParameterAccess.getModulatedValueNormalized(App, Parameter)

        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isRecording()

    return App:getWorkspace():getRecordingParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isRecordingSample()

    if not NI.APP.FEATURE.SAMPLER then
        return false
    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    return Recorder and Recorder:isRecording()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isRecordingSampleChanged()

    if not NI.APP.FEATURE.SAMPLER then
        return false
    end

    local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
    local Param = Recorder and Recorder:getRecordingFlag()

    return Param and Param:isChanged() or false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isPlaying()

    return App:getWorkspace():getPlayingParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isAutoWriting()

    return NI.DATA.WORKSPACE.isAutoWriteEnabledFromHWModel and
        NI.DATA.WORKSPACE.isAutoWriteEnabledFromHWModel(App, NHLController:getControllerModel()) and
        MaschineHelper.isPlaying() and
        NHLController:getEncoderMode() ~= NI.HW.ENC_MODE_NONE or false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusSlotNameWithNumber()

    local FocusNum = MaschineHelper.getFocusSlotNumber()
    local FocusSlotName = MaschineHelper.getFocusSlotName()

    return FocusSlotName and FocusNum..". "..FocusSlotName  or "(None)"     -- e.g.: 1. Reaktor

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusSlotName()

    local FocusSlot = NI.DATA.StateHelper.getFocusSlot(App)
    return FocusSlot and NI.DATA.SlotAlgorithms.getDisplayName(FocusSlot)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusSlotNumber()

    return NI.DATA.StateHelper.getFocusSlotIndex(App) + 1 -- 1-indexed

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getObjectIndexAsString(Song, LevelTab)

	local Group = NI.DATA.StateHelper.getFocusGroup(App)
	local Text = ""

    if LevelTab == nil then
		-- get Focused Mixing Layer's prefix
		LevelTab = Song and Song:getLevelTab() or NI.DATA.LEVEL_TAB_SONG
	end

	if LevelTab == NI.DATA.LEVEL_TAB_SONG then

		-- Song / Master has no index

	elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then

		Text = NI.DATA.Group.getLabel(NI.DATA.StateHelper.getFocusGroupIndex(App))

	elseif LevelTab == NI.DATA.LEVEL_TAB_SOUND and Group then

		Text = tostring(Group:getSounds():calcIndex(NI.DATA.StateHelper.getFocusSound(App)) + 1)

    end

	return Text

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getMixingObjectName(LevelTab, ShowPrefix)

	if LevelTab == NI.DATA.LEVEL_TAB_SONG then

		return App:getProject():getCurrentProjectDisplayName()

	elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP or LevelTab == NI.DATA.LEVEL_TAB_SOUND then

		local Object = LevelTab == NI.DATA.LEVEL_TAB_GROUP
			and NI.DATA.StateHelper.getFocusGroup(App)
			or  NI.DATA.StateHelper.getFocusSound(App)

		if Object then
			return (ShowPrefix and InfoBarBase.getObjectPrefix(NI.DATA.StateHelper.getFocusSong(App), LevelTab) or "")
				.. Object:getDisplayName()
		end

	end

	return ""

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusChannelSlotName()

    local ChannelMode = not MaschineHelper:isShowingPlugins()
    local Index = ChannelMode and App:getWorkspace():getPageGroupParameter():getValue() or
                  NI.DATA.StateHelper.getFocusSlotIndex(App)

    return MaschineHelper.getChannelSlotName(Index, false)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusPluginSlotName()

    local FocusSlotIndex = NI.DATA.StateHelper.getFocusSlotIndex(App)
    return MaschineHelper.getChannelSlotName(FocusSlotIndex, true)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getChannelSlotName(Index, ForcePluginMode)

    local ChannelMode = not MaschineHelper:isShowingPlugins()
    local Text = "EMPTY"

    if ChannelMode and not ForcePluginMode then
        Text = string.upper(App:getWorkspace():getPageGroupParameter():getAsString(Index))
    else
        local Slots = NI.DATA.StateHelper.getFocusChainSlots(App)
        if Slots and Index < Slots:size() and Index >= 0 then
            Text = string.upper(NI.DATA.SlotAlgorithms.getDisplayName(Slots:at(Index)))
        end
    end

    return Text

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isDrumkitMode()

    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    return FocusGroup and FocusGroup:getMidiInputKitMode():getValue() == NI.DATA.KitMode.DRUMKIT

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLevelTab()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getLevelTab()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getLevelTabAsString(LevelTab)

    String = ""

    if LevelTab == NI.DATA.LEVEL_TAB_SOUND then

        String = "Sound"

    elseif LevelTab == NI.DATA.LEVEL_TAB_GROUP then

        String = "Group"

    elseif LevelTab == NI.DATA.LEVEL_TAB_SONG then

        String = "Project"

    end

    return String

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.hasSoundFocus()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return Song and Song:getLevelTab() == NI.DATA.LEVEL_TAB_SOUND or false

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setFocusLevelTab(Level)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        NI.DATA.SongAccess.setLevelTab(App, Song, Level)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setSongFocus()

    MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_SONG)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setGroupFocus()

    MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_GROUP)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setSoundFocus()

    MaschineHelper.setFocusLevelTab(NI.DATA.LEVEL_TAB_SOUND)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.toggleMetronome()

    local MetronomeMode = App:getMetronome():getEnabledParameter()
    local NewValue      = not MetronomeMode:getValue()

    NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, MetronomeMode, NewValue)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.toggleLink()

    if NI.APP.isStandalone() then
        local Param = App:getWorkspace():getLinkEnabledParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, Param, not Param:getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusedSoundSlot()

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound then
        return Sound:getChain():getSlots():getFocusObject()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.offsetFocusedSoundSlotParameterPage(Next)

    local Page = 0

    local Slot = MaschineHelper.getFocusedSoundSlot()
    if Slot then
        local Module = Slot:getModule()
        if Module then
            local Plugin = Slot:getPluginHost()
            local PageParameter = Plugin and Plugin:getPageParameter() or App:getWorkspace():getModulePageParameter(Module)

            if PageParameter then
                local Page = math.bound(PageParameter:getValue() + (Next and 1 or -1), 0, Module:getNumPages(0) - 1)
                NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PageParameter, Page)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusedSoundSlotParameterPage()

    local Page = 0

    local Slot = MaschineHelper.getFocusedSoundSlot()
    if Slot then
        local Module = Slot:getModule()
        if Module then
            local Plugin = Slot:getPluginHost()
            local PageParameter = Plugin
                and Plugin:getPageParameter()
                or  App:getWorkspace():getModulePageParameter(Module)

            Page = PageParameter and PageParameter:getValue() or 0
        end
    end

    return Page

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusedSoundSlotParameter(Index)

    local Slot = MaschineHelper.getFocusedSoundSlot()
    if Slot then
        local Module = Slot:getModule()
        if Module then
            local PageGroup = 0
            local Page = MaschineHelper.getFocusedSoundSlotParameterPage()
            return Module:getParameter(PageGroup, Page, Index)
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getFocusedSoundSlotNumParameterPages()

    local NumPages = 0

    local Slot = MaschineHelper.getFocusedSoundSlot()
    if Slot then
        local Owner = Slot:getPluginHost()
        if not Owner then
            Owner = Slot:getModule()
        end
        if Owner then
            NumPages = Owner:getNumPages(0)
        end
    end

    return NumPages

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isOnScreenOverlayVisible()

    local OnScreenOverlay = App:getOnScreenOverlay()
    return OnScreenOverlay:getVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isRoutingParam(Param)

    if not NI.APP.FEATURE.EFFECTS_CHAIN then
        return false
    end

    local Tag = Param:getTag()

    return
        Tag == NI.DATA.MaschineParameter.TAG_AUDIO_INPUT or
        Tag == NI.DATA.MaschineParameter.TAG_AUDIO_OUTPUT or
        Tag == NI.DATA.MaschineParameter.TAG_EVENT_INPUT or
        Tag == NI.DATA.MaschineParameter.TAG_EVENT_OUTPUT or
        Tag == NI.DATA.MaschineParameter.TAG_SIDECHAIN_INPUT

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isShowingPlugins()

    return not NI.HW.FEATURE.CHANNEL and true or App:getWorkspace():getModulesVisibleParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.findFirstPageInStack(PageIDs)

    for i = NHLController:getPageStack():getNumPages()-1, 1, -1 do
        local PageID = NHLController:getPageStack():getPageAt(i)
        for _, PID in ipairs(PageIDs) do
            if PageID == PID then
                return PageID
            end
        end
    end

    return nil

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setAudioMIDISettingsChanged()

    local Param = App:getWorkspace():getAudioMidiSettingsChangedParameter()
    NI.DATA.ParameterAccess.setBoolParameter(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.setHardwareSettingsChanged()

    local Param = App:getWorkspace():getHardwareSettingsChangedParameter()
    NI.DATA.ParameterAccess.setBoolParameter(App, Param, not Param:getValue())

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.shouldHandlePageButton(PageID)

    -- Don't open macro assign page when macro page is visible
    return PageID ~= NI.HW.PAGE_MACRO_ASSIGN or not NI.DATA.ParameterPageAccess.isMacroPageActive(App)

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.openRenameDialog(DisplayName, NameParameter)

    local Descriptor = NI.GUI.TextInputDialogDescriptor()
    Descriptor.Title = "Rename "..DisplayName.." to ..."
    Descriptor.Prefill = DisplayName
    Descriptor.KeyboardType = NI.HW.TEXT_INPUT_KEYBOARD_REGULAR
    Descriptor.KeyboardMode = NI.HW.TEXT_INPUT_MODE_PLAINTEXT
    Descriptor.LeftScreenAttribute = "Empty"

    local NewName = NI.GUI.DialogAccess.openTextInput(App, Descriptor)
    local IsNewNameSet = false

    if NewName then

        if NewName == "" then
            NI.DATA.ParameterAccess.resetToDefault(App, NameParameter)
        else
            NI.DATA.ParameterAccess.setWStringParameter(App, NameParameter, NewName)
            IsNewNameSet = true
        end

    end

    return IsNewNameSet

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.isCPUTooHigh()

    return App:getCPULevel() > 90

end

------------------------------------------------------------------------------------------------------------------------

function MaschineHelper.getCPULevelString()

    return tostring(App:getCPULevel()).."%"

end

------------------------------------------------------------------------------------------------------------------------

return MaschineHelper

------------------------------------------------------------------------------------------------------------------------

