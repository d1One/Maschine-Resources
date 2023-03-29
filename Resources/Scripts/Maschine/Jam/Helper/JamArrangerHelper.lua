------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/MiscHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
JamArrangerHelper = class( 'JamArrangerHelper' )

------------------------------------------------------------------------------------------------------------------------

JamArrangerHelper.PressedSectionKeys = {}
JamArrangerHelper.MoveLoopPointEnd = true

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.resetPressedSceneButtons()

    MiscHelper.resetTable(JamArrangerHelper.PressedSectionKeys)

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.updatePressedSceneButtons(SceneButtonIndex, SongPos, Add)

    JamArrangerHelper.PressedSectionKeys[SceneButtonIndex] = Add and SongPos or nil

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getPressedSceneButtonsSize()

    return MiscHelper.getTableSize(JamArrangerHelper.PressedSectionKeys)

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.isActiveSceneButtonPressed()

    -- Check if there is at least one scene button pressed, which represents a existing scene
    local Song        = NI.DATA.StateHelper.getFocusSong(App)
    local LastSongPos = Song and Song:getSections():size() or 0
    local Min = JamArrangerHelper.getMinMaxSceneIndexFromPressedSceneButtons()
    return Min and Min < LastSongPos

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getMinMaxSceneIndexFromPressedSceneButtons()

    return MiscHelper.getMinMaxFromTable(JamArrangerHelper.PressedSectionKeys)

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getFocusSectionBank()

    return NHLController:getContext():getSectionBankParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getFocusSceneBank()

    return NHLController:getContext():getSceneBankParameter():getValue()

end

------------------------------------------------------------------------------------------------------------------------
-- Returns an absolute 0-indexed position for the Section/Scene

function JamArrangerHelper.getPositionBySceneButton(Index, Arranging)

    local Bank = (ArrangerHelper.isIdeaSpaceFocused() or Arranging) and JamArrangerHelper.getFocusSceneBank()
                                                               or JamArrangerHelper.getFocusSectionBank()
    return Bank * 8 + Index - 1

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getNumSectionBanks(IncludeNextEmptyBank)

    local NumBanks = 0
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local NumSections = Song:getSections():size()
        NumBanks = math.ceil(NumSections / 8) + (IncludeNextEmptyBank and (NumSections % 8 == 0) and 1 or 0)
    end

    return NumBanks

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getNumSceneBanks(IncludeNextEmptyBank)

    local NumBanks = 0
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song then
        local NumScenes = Song:getScenes():size()
        NumBanks = math.ceil(NumScenes / 8) + (IncludeNextEmptyBank and (NumScenes % 8 == 0) and 1 or 0)
    end

    return NumBanks

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.duplicateSection(SrcIndex, DstIndex) -- 0-indexed, 0-indexed

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return false
    end

    local Section = SrcIndex == nil
        and NI.DATA.StateHelper.getFocusSection(App) -- Default source is focused Section
        or  NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SrcIndex)

    if Section then
        local DstKey = DstIndex and NI.DATA.SongAlgorithms.getSectionKeyFromSectionPosition(Song, DstIndex)

        if DstKey == NPOS then
            DstKey = NI.DATA.findFirstUnusedSectionKeyAfterLast(Song:getSections())
        end
        NI.DATA.SongAccess.duplicateSectionReplace(App, Song, Section, DstKey, true)
        return true
    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getSceneLEDState(LedIndex, ShowBanks, IncludeNew, Duplicating, Arranging) -- 1-indexed

    local SongPos = JamArrangerHelper.getPositionBySceneButton(LedIndex, Arranging)

    if ArrangerHelper.isIdeaSpaceFocused() or Arranging then
        return JamArrangerHelper.getSceneLEDStateIdeaSpace(LedIndex, ShowBanks, IncludeNew, SongPos, Arranging)
    else
        return JamArrangerHelper.getSceneLEDStateTimeline(LedIndex, ShowBanks, IncludeNew, SongPos, Duplicating)
    end

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getSceneLEDStateIdeaSpace(LedIndex, ShowBanks, IncludeNew, SongPos, Arranging)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return false, false
    end

    local Selected, Enabled = false

    if ShowBanks then

        local NumBanks = JamArrangerHelper.getNumSceneBanks(IncludeNew)

        Selected = LedIndex - 1 == JamArrangerHelper.getFocusSceneBank()
        Enabled = LedIndex <= NumBanks

    else

        local FocusScene = NI.DATA.StateHelper.getFocusScene(App)
        local Scene = Song:getScenes():at(SongPos)

        local IsNextEmptyScene = SongPos == Song:getScenes():size()

        Selected = not Arranging and FocusScene and FocusScene == Scene
        Enabled = Scene ~= nil or (IsNextEmptyScene and IncludeNew and not Arranging)

    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getSceneLEDStateTimeline(LedIndex, ShowBanks, IncludeNew, SongPos, Duplicating)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return false, false
    end

    local Selected, Enabled = false

    if ShowBanks then

        local NumBanks = JamArrangerHelper.getNumSectionBanks(IncludeNew)

        Selected = LedIndex-1 == JamArrangerHelper.getFocusSectionBank()
        Enabled = LedIndex <= NumBanks

    else

        local FocusSection = NI.DATA.StateHelper.getFocusSection(App)
        local Section = NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos)
        local IsNextEmptySection = SongPos == Song:getSections():size()
        local IsSectionPartOfLoop = Section and NI.DATA.SongAlgorithms.isSectionPartOfLoop(Song, Section)
        local IdeaSpaceFocused = NI.DATA.SongAlgorithms.isIdeaSpaceFocused(Song)

        Selected = not IdeaSpaceFocused and
            ((IsSectionPartOfLoop and not Duplicating) or (FocusSection and FocusSection == Section))
        Enabled = Section ~= nil or (IsNextEmptySection and IncludeNew)

    end

    return Selected, Enabled

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.getSceneLEDColorByIndex(LedIndex, ShowBanks, Arranging)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Color = LEDColors.WHITE  -- white is used for the next empty scene, and banks

    if Song and not ShowBanks then

        local SongPos = JamArrangerHelper.getPositionBySceneButton(LedIndex, Arranging)

        if ArrangerHelper.isIdeaSpaceFocused() or Arranging then

            local Scene = Song:getScenes():at(SongPos)
            if Scene then
                Color = Scene:getColorParameter():getValue()
            end

        else

            local Section = NI.DATA.SongAlgorithms.getSectionFromSectionPosition(Song, SongPos)
            local Scene = Section and Section:getScene()

            if Scene then
                Color = Scene:getColorParameter():getValue()
            end

        end

    end

    return Color

end

------------------------------------------------------------------------------------------------------------------------

function JamArrangerHelper.moveSectionLoopPoint(Inc)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return
    end

    local LoopBegin = NI.DATA.LoopAlgorithms.getSectionSongPosLoopBegin(Song)
    local LoopEnd = NI.DATA.LoopAlgorithms.getSectionSongPosLoopEnd(Song)
    local LoopLength = (LoopEnd - LoopBegin) + 1
    local MaxLoopEnd = Song:getSections():size() - 1

    if LoopBegin == NPOS or LoopEnd == NPOS then
        return
    end

    if JamArrangerHelper.getPressedSceneButtonsSize() >= 2 then -- move whole loop

        Inc = math.min(Inc, MaxLoopEnd - LoopEnd)
        LoopBegin = math.max(0, LoopBegin + Inc)
        LoopEnd = math.max(LoopEnd + Inc, LoopLength - 1)

    elseif JamArrangerHelper.MoveLoopPointEnd then -- move loop end point

        if Inc < 0 and math.abs(Inc) >= LoopLength then -- swap loop point to move
            JamArrangerHelper.MoveLoopPointEnd = false
            LoopEnd = LoopBegin
            LoopBegin = math.max(0, LoopEnd + Inc)
        else
            LoopEnd = math.max(LoopBegin, LoopEnd + Inc)
        end

    else -- move loop start point

        if Inc >= LoopLength then -- swap loop point to move
            JamArrangerHelper.MoveLoopPointEnd = true
            LoopBegin = LoopEnd
            LoopEnd = LoopBegin + math.abs(LoopLength - Inc) + 1
        else
            LoopBegin = math.max(0, LoopBegin + Inc)
        end

    end

    LoopEnd = math.min(MaxLoopEnd, LoopEnd)
    NI.DATA.TransportAccess.setLoopBySectionSongPosition(App, LoopBegin, LoopEnd, true)

end

------------------------------------------------------------------------------------------------------------------------
-- Can Scene Loop selection change, normally by wheel

function JamArrangerHelper.canSectionLoopChange(Controller)

    return Controller
           and Controller:isWheelPressed()
           and not ArrangerHelper.isIdeaSpaceFocused()
           and NI.DATA.TransportAccess.isSectionLoopActive(App)
           and JamArrangerHelper.getPressedSceneButtonsSize() > 0

end

------------------------------------------------------------------------------------------------------------------------
-- Can change scene of section, normally by wheel

function JamArrangerHelper.canShiftSceneOfSection(Controller)

    return Controller
           and not Controller:isWheelPressed()
           and not ArrangerHelper.isIdeaSpaceFocused()
           and JamArrangerHelper.getPressedSceneButtonsSize() == 1

end

------------------------------------------------------------------------------------------------------------------------
