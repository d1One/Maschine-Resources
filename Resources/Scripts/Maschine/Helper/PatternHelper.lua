------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternHelper = class( 'PatternHelper' )

------------------------------------------------------------------------------------------------------------------------
--Functor: Visible, Enabled, Selected, Focused, Text

function PatternHelper.PatternStateFunctor(ButtonIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group then

        local BankIndex = Group:getFocusPatternBankIndexParameter():getValue()
        local Index = BankIndex * 16 + ButtonIndex - 1
        local Pattern = Group:getPatterns():find(Index)

        if Pattern then
            local HasFocus = (Pattern == NI.DATA.StateHelper.getFocusEventPattern(App))
            local Name  = Pattern:getNameParameter():getValue()

            return true, true, false, HasFocus, Name
        end
    end

    return true, false, false, false, ""

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getPatternIndexFromPadIndex(PadIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then
        return Group:getFocusPatternBankIndexParameter():getValue() * 16 + PadIndex - 1  -- make 0-indexed
    end

    return -1

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getPatternFromPadIndex(PadIndex)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if not Group then
        return nil
    end

    local PatternIndexOnPad = PatternHelper.getPatternIndexFromPadIndex(PadIndex)
    return Group:getPatterns():find(PatternIndexOnPad)

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getFocusPatternIndexNoGaps()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group == nil then
        return nil
    end

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then

        for Index = 1, Group:getClipSequence():size() do
            local Clip = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index - 1)
            if Clip and Clip:isEventEqual(Group:getClipSequence():getFocusEvent()) then
                return Index
            end
        end

    else

        local Index = 1
        local Pattern = Group:getFirstPattern()

        while Pattern ~= nil do
            if Pattern == NI.DATA.StateHelper.getFocusEventPattern(App) then
                return Index
            end
            Pattern = Group:getPatterns():getNext(Pattern)
            Index = Index + 1
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.focusPatternByIndex(Index, CreateIfEmpty)

    if Index == nil or Index < 0 then
        return
    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Pattern = Group and Group:getPatterns():find(Index) or nil

    if Pattern then
        NI.DATA.GroupAccess.insertPatternAndFocus(App, Group, Pattern)
    elseif CreateIfEmpty and NI.DATA.StateHelper.getFocusGroup(App) then
        -- note: can't create empty AudioPatterns
        PatternHelper.insertNewPattern(Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getNumPatternsInFocusedGroup()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    return Group and Group:getPatterns():size() or 0

end

------------------------------------------------------------------------------------------------------------------------
-- returns sequential Pattern list (without gaps), focus pattern
function PatternHelper.getFocusedGroupPatternList()

    local Data = {}

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group == nil then
        return Data, nil
    end

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then

        for Index = 1, Group:getClipSequence():size() do
            local Clip = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index - 1)
            Data[Index] = Clip and Clip:getEventPattern() or nil
        end

    else

        local Pattern = Group:getFirstPattern()

        local Index = 1
        while Pattern ~= nil do
            Data[Index] = Pattern

            Pattern = Group:getPatterns():getNext(Pattern)
            Index = Index + 1
        end

    end

    return Data, NI.DATA.StateHelper.getFocusEventPattern(App)

end

------------------------------------------------------------------------------------------------------------------------
-- returns true if scene has no referenced pattern
function PatternHelper.isFocusSceneEmpty()

    local FocusScene = NI.DATA.StateHelper.getFocusScene(App)
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups()

    if FocusScene and Groups then

        for Index = 0, Groups:size() do
            local Group = Groups:at(Index)
            if Group and NI.DATA.SceneAccess.getPattern(FocusScene, Group) then
                return false
            end
        end
    end

    return true
end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.focusPatternByGroupAndByIndex(GroupIndex, PatternIndex, CreateIfEmpty)

    if PatternIndex == nil or PatternIndex < 0 or GroupIndex == nil or GroupIndex < 0 then
        return
    end

    local Group = MaschineHelper.getGroupAtIndex(GroupIndex)

    if Group then

        local Pattern = Group:getPatterns():find(PatternIndex)

        if Pattern then

            local FocusSection = NI.DATA.StateHelper.getFocusSection(App)
            local FocusScene = NI.DATA.StateHelper.getFocusScene(App)
            local FocusScenePattern = FocusScene and NI.DATA.SceneAccess.getPattern(FocusScene, Group)
            local HasFocus = Pattern == FocusScenePattern

            if HasFocus then
                if FocusSection then
                    NI.DATA.SectionAccess.removePattern(App, FocusSection, Group)
                else -- In Idea Space we work on Scenes directly.
                    NI.DATA.SceneAccess.removePattern(App, FocusScene, Group)
                end
            else
                NI.DATA.GroupAccess.insertPatternAndFocus(App, Group, Pattern)
            end

        elseif CreateIfEmpty == true then
            -- note: AudioPatterns can't currently be empty, so CreateIfEmpty is n/a
            PatternHelper.insertNewPattern(PatternIndex, Group)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.insertNewPattern(Index, Group)

    if not Group then
        Group = NI.DATA.StateHelper.getFocusGroup(App)
    end

    if Group then
        NI.DATA.GroupAccess.createPattern(App, Group, Index)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.createRandomSoundSequence()

    local Group   = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound   = NI.DATA.StateHelper.getFocusSound(App)

    if Group and Sound then

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if not Pattern then
            -- If there is not pattern yet, create one on slot zero
            PatternHelper.focusPatternByIndex(0, true)
            Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        end

        NI.DATA.EventPatternAccess.createRandomSoundSequence(App, Group, Pattern, Sound)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.removeFocusPattern()

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local Section    = NI.DATA.StateHelper.getFocusSection(App)
    local Scene      = NI.DATA.StateHelper.getFocusScene(App)
    local Group      = NI.DATA.StateHelper.getFocusGroup(App)

    if not Song or not Group then
       return
    end
    if Section then
        NI.DATA.SectionAccess.removePattern(App, Section, Group)
    elseif Scene then -- In Idea Space we work on Scenes directly.
        NI.DATA.SceneAccess.removePattern(App, Scene, Group)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.duplicatePattern(SrcIndex, DestIndex)

    local GroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    return PatternHelper.duplicatePatternToGroup(SrcIndex, GroupIndex, DestIndex, GroupIndex)

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.duplicatePatternToGroup(SrcPatternIdx, SrcGroupIdx, DestPatternIdx, DestGroupIdx)

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local SrcGroup   = Song and Song:getGroups():at(SrcGroupIdx) or nil
    local DestGroup  = Song and Song:getGroups():at(DestGroupIdx) or nil
    local SrcPattern = SrcPatternIdx and SrcGroup:getPatterns():find(SrcPatternIdx) or
                       NI.DATA.StateHelper.getFocusEventPattern(App)

    if SrcGroup and DestGroup and SrcPattern then

        if DestPatternIdx then
            return NI.DATA.GroupAccess.duplicatePatternReplace(App, SrcGroup, SrcPattern, DestGroup, DestPatternIdx)
        else
            return NI.DATA.GroupAccess.duplicatePattern(App, SrcGroup, SrcPattern)
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.setPatternOrClipEventLength(PatternLengthInBars)

   local Song = NI.DATA.StateHelper.getFocusSong(App)

    if not Song then
        return
    end

    local PatternLengthInTicks = PatternLengthInBars * Song:getTicksPerBar()

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local SongClip = NI.DATA.StateHelper.getFocusClipEvent(App)

        if Group and SongClip then
            NI.DATA.ClipEventAccess.setClipEventLength(App, Group, SongClip, PatternLengthInTicks, 1, false)
            App:getTransactionManager():finishTransactionSequence()
        end

    else

        local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
        if Pattern then
            NI.DATA.EventPatternAccess.setExplicitLength(App, Pattern, PatternLengthInTicks, false)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getCurrentPatternLengthInBars()

    local Song    = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local SceneView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN)
    local HasPattern = Song and Pattern and SceneView

    return HasPattern and math.ceil((Pattern:getLengthParameter():getValue() - 1) / Song:getTicksPerBar()) or 0

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.setPatternLengthInBars(PatternLengthInBars)

    local Song    = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local SceneView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_PATTERN)

    if Song and Group and SceneView then

        if Pattern then
            NI.DATA.EventPatternAccess.setLengthInBars(App, Pattern, Song, PatternLengthInBars)
        else
            NI.DATA.ArrangerAccess.insertPatternAndFocus(App, Group, PatternLengthInBars * Song:getTicksPerBar())
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.deletePatternOrBank(ShiftPressed)

    if ShiftPressed then
        PatternHelper.deletePatternBank()
    else
        NI.DATA.GroupAccess.deleteFocusPattern(App)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.deletePatternBank()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group then
        NI.DATA.SongAccess.deletePatternBank(App, Group, Group:getFocusPatternBankIndexParameter():getValue())
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.removeEventsByPadIndex(PadIndex, UseKeyboardMode)

    NI.DATA.EventPatternAccess.removeEventsByPadIndex(App, PadIndex - 1, UseKeyboardMode)

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.getFocusPatternBankEmpty() -- Bank is 0-indexed

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Patterns = Group and Group:getPatterns()

    if Group then
        local Bank = Group:getFocusPatternBankIndexParameter():getValue()
        local IndexStart = Bank * 16

        for Index = 0, 15 do
            if Patterns:find(IndexStart + Index) then
                return false
            end
        end
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.onPatternPagePadEvent(PadIndex, Trigger, DeletePattern)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Group and Trigger then

        local PatternIndex = PatternHelper.getPatternIndexFromPadIndex(PadIndex)

        if DeletePattern then
            NI.DATA.GroupAccess.deletePattern(App, Group, PatternIndex)
        else
           PatternHelper.focusOrRemovePattern(PadIndex, PatternIndex)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.focusOrRemovePattern(PadIndex, PatternIndex)

    local FocusPattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local PatternOnPad = PatternHelper.getPatternFromPadIndex(PadIndex)

    if FocusPattern and PatternOnPad == FocusPattern then
        PatternHelper.removeFocusPattern()
    else
        PatternHelper.focusPatternByIndex(PatternIndex, true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.updatePadLEDs(LEDs)

    -- update sound leds with focus state
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    LEDHelper.updateLEDsWithFunctor(LEDs,
                                    Group and Group:getFocusPatternBankIndexParameter():getValue() * 16 or 0,
                                    MaschineHelper.isPatternFocusByIndex,
                                    MaschineHelper.getPatternColorByIndex)

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.setPrevNextPatternBank(Next)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if Song and Group then
        local BankParam = Group:getFocusPatternBankIndexParameter()
        local BankIndex = BankParam:getValue()
        local NumBanks = Song:getNumPatternBanksParameter():getValue()

        if BankIndex == NumBanks-1 and Next and PatternHelper.canAddPatternBank() then
            NI.DATA.SongAccess.addPatternBank(App, Group)
        else
            -- select next or previous bank
            BankIndex = BankIndex + (Next and 1 or -1)

            if BankIndex >= 0 and BankIndex < NumBanks then
                NI.DATA.ParameterAccess.setSizeTParameter(App, BankParam, BankIndex)
            end
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.hasPrevNextPatternBanks()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    local NumBanks = Song and Song:getNumPatternBanksParameter():getValue() or 0
    local BankIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() or 0

    return BankIndex > 0, BankIndex < NumBanks-1

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.canAddPatternBank()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local NumBanks = Song and Song:getNumPatternBanksParameter():getValue() or 0
    local BankIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() or 0

    return (BankIndex == NumBanks-1)
        and (not NI.DATA.SongAccess.isPatternBankEmptyInAllGroups(App, BankIndex))

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.hasPrevNextPattern(Next, FirstItemDeselects)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if FirstItemDeselects and Group and Pattern == nil and Next then
        return true
    end

    if Group and Pattern then
        local Patterns = Group:getPatterns()

        if Next then
            local Next = Patterns:getNext(Pattern)
            return Next ~= nil, Next
        else
            local Prev = Patterns:getPrev(Pattern)
            return Prev ~= nil or FirstItemDeselects, Prev
        end
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.focusPrevNextPattern(Next, FirstItemDeselects)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if Group then

        local HasPrev = PatternHelper.hasPrevNextPattern(false, false)

        if FirstItemDeselects and not Next and not HasPrev then
            PatternHelper.removeFocusPattern()
        else
            local CreateIfNoPattern = false
            NI.DATA.GroupAccess.shiftPatternFocus(App, Group, Next, CreateIfNoPattern)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.startString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Pattern = Song and NI.DATA.StateHelper.getFocusEventPattern(App)
    return Pattern and Song:getTickPositionToString(Pattern:getStartParameter():getValue()) or "-"

end

------------------------------------------------------------------------------------------------------------------------

local function hasFocusedPatternAutomaticLength(Song)

    return Song and NI.DATA.EventPatternAccess.hasFocusedPatternAutomaticLength(Song) or false

end

------------------------------------------------------------------------------------------------------------------------

local function numericPatternLength(Song)

    local Pattern = Song and NI.DATA.StateHelper.getFocusEventPattern(App)
    return Pattern and Song:getTickToString(Pattern:getLengthParameter():getValue()) or "-"

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.lengthString()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    return hasFocusedPatternAutomaticLength(Song) and "Auto" or numericPatternLength(Song)

end

------------------------------------------------------------------------------------------------------------------------

function PatternHelper.incrementPatternLength(Inc, Fine)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    if Pattern then
        local Quick = false
        NI.DATA.EventPatternAccess.incrementExplicitLength(App, Pattern, Inc, Fine, Quick);
    end

end

------------------------------------------------------------------------------------------------------------------------

