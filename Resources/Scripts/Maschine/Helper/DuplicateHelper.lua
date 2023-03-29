
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------
-- DuplicateHelper
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicateHelper = class( 'DuplicateHelper' )

------------------------------------------------------------------------------------------------------------------------
-- Consts & Members
------------------------------------------------------------------------------------------------------------------------

DuplicateHelper.SOUND           = 1
DuplicateHelper.GROUP           = 2
DuplicateHelper.SCENE           = 3
DuplicateHelper.SECTION         = 4
DuplicateHelper.PATTERN         = 5
DuplicateHelper.CLIP            = 6
DuplicateHelper.GROUP_SELECT    = 7 -- Used by Mikro when a sound is selected for duplicate, and the pads are needed to
                                    -- select a different group.

-- counter variables used to show a flashing led to show that something is copied
DuplicateHelper.BlinkCtr = 0
DuplicateHelper.BlinkTime = 4 -- arbitrary number for blink time


------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.setMode(DuplPage, DupMode)

    if DupMode ~= DuplPage.Mode
        and DupMode ~= DuplicateHelper.GROUP_SELECT
        and DuplPage.Mode ~= DuplicateHelper.GROUP_SELECT then

        -- reset duplicate source vars
        DuplPage.SourceIndex = -1
        DuplPage.SourceGroupIndex = -1
        DuplicateHelper.BlinkCtr = 0
    end

    DuplPage.Mode = DupMode

    if DupMode == DuplicateHelper.SOUND or DupMode == DuplicateHelper.GROUP then
        DuplPage.BaseMode = DupMode
    end

    DuplPage:updateScreens(true)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.updateSceneSectionMode(DuplPage, ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if ForceUpdate or (Song and Song:getArrangerState():isViewChanged()) then

        if DuplPage.Mode == DuplicateHelper.SCENE and not ArrangerHelper.isIdeaSpaceFocused() then
            DuplicateHelper.setMode(DuplPage, DuplicateHelper.SECTION)
        elseif DuplPage.Mode == DuplicateHelper.SECTION and ArrangerHelper.isIdeaSpaceFocused() then
            DuplicateHelper.setMode(DuplPage, DuplicateHelper.SCENE)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getDuplicateWithOption(DupMode)

    if DupMode == DuplicateHelper.SECTION then
        return App:getWorkspace():getLinkSceneOnDuplicateParameter():getValue()
    elseif DupMode == DuplicateHelper.SOUND or DupMode == DuplicateHelper.GROUP then
        return App:getWorkspace():getDuplicateGroupWithPatternsParameter():getValue()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.setDuplicateWithOption(DupMode, Value)

    local DuplWithParam = nil

    if DupMode == DuplicateHelper.SECTION then
        DuplWithParam = App:getWorkspace():getLinkSceneOnDuplicateParameter()
    elseif DupMode == DuplicateHelper.SOUND or DupMode == DuplicateHelper.GROUP then
        DuplWithParam = App:getWorkspace():getDuplicateGroupWithPatternsParameter()
    end

    if DuplWithParam ~= nil then
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, DuplWithParam, Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getLinkSceneString(DupMode)

    if DupMode == DuplicateHelper.SECTION then
        return App:getWorkspace():getLinkSceneOnDuplicateParameter():getValueString()
    else
        return "-"
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.setLinkScene(DupMode, Value)

    if DupMode == DuplicateHelper.SECTION then
        local LinkSceneParameter = App:getWorkspace():getLinkSceneOnDuplicateParameter()
        NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, LinkSceneParameter, Value)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.isSourceValid(Mode, SourceIndex, GroupIndex)

    -- no source, no problem.
    if SourceIndex == -1 and GroupIndex == -1 then
        return true
    end

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)

    if Mode == DuplicateHelper.GROUP or Mode == DuplicateHelper.SOUND then
        return Groups and Groups:at(Mode == DuplicateHelper.GROUP and SourceIndex or GroupIndex)

    elseif Mode == DuplicateHelper.SCENE then
        return Song and Song:getScenes():at(SourceIndex)

    elseif Mode == DuplicateHelper.SECTION then
        return Song and Song:getSections():find(SourceIndex)

    elseif Mode == DuplicateHelper.PATTERN then
        return FocusGroup and FocusGroup:getPatterns():find(SourceIndex)

    elseif Mode == DuplicateHelper.CLIP then
        return FocusGroup and NI.DATA.GroupAlgorithms.getClipEventByIndex(FocusGroup, SourceIndex)

    end

    return true
end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getLEDBlinkState()

    DuplicateHelper.BlinkCtr = math.wrap(DuplicateHelper.BlinkCtr + 1, -DuplicateHelper.BlinkTime, DuplicateHelper.BlinkTime)

    return (DuplicateHelper.BlinkCtr < 0) and LEDHelper.LS_DIM or LEDHelper.LS_BRIGHT

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getLeftRightButtonsEnabled(DuplPage)

    if DuplPage.Mode == DuplicateHelper.SCENE then

        return ArrangerHelper.hasPrevNextSceneBanks()

    elseif DuplPage.Mode == DuplicateHelper.SECTION then

        local Left, Right = ArrangerHelper.hasPrevNextSectionBanks()

        if Right == false then
            Right = ArrangerHelper.canAddSectionBank()
        end

        return Left, Right

    elseif DuplPage.Mode == DuplicateHelper.PATTERN then

        local Left, Right = PatternHelper.hasPrevNextPatternBanks()

        if Right == false then
            Right = PatternHelper.canAddPatternBank()
        end

        return Left, Right

    elseif DuplPage.Mode == DuplicateHelper.CLIP then

        return ClipHelper.hasPrevNextBank()

    elseif DuplPage.Mode == DuplicateHelper.GROUP or DuplPage.Mode == DuplicateHelper.GROUP_SELECT then

        local CanPaste = DuplPage.SourceIndex >= 0
        local CanLeft  = DuplPage.Screen.GroupBank > 0
        local CanRight = DuplPage.Screen.GroupBank+1 < MaschineHelper.getNumFocusSongGroupBanks(CanPaste)

        return CanLeft, CanRight

    else

        return false, false

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.onPageButton(Button, Pressed, DuplPage)

    local PrevMode = DuplPage.Mode
    local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

    if Button == NI.HW.BUTTON_SCENE or Button == NI.HW.BUTTON_PATTERN then

        if Pressed then

            if DuplPage.Mode == DuplicateHelper.SOUND or DuplPage.Mode == DuplicateHelper.GROUP then
                DuplPage.BaseMode = DuplPage.Mode
            end

            local NewMode = Button == NI.HW.BUTTON_SCENE and
                (IdeaSpaceVisible and DuplicateHelper.SCENE or DuplicateHelper.SECTION) or
                (SongClipView and DuplicateHelper.CLIP or DuplicateHelper.PATTERN)

            DuplicateHelper.setMode(DuplPage, NewMode)

        else

            if (Button==NI.HW.BUTTON_SCENE and IdeaSpaceVisible and DuplPage.Mode == DuplicateHelper.SCENE) or
               (Button==NI.HW.BUTTON_SCENE and not IdeaSpaceVisible and DuplPage.Mode == DuplicateHelper.SECTION) or
               (Button==NI.HW.BUTTON_PATTERN and SongClipView and DuplPage.Mode == DuplicateHelper.CLIP) or
               (Button==NI.HW.BUTTON_PATTERN and not SongClipView and DuplPage.Mode == DuplicateHelper.PATTERN) then

                DuplicateHelper.setMode(DuplPage, DuplPage.BaseMode)
            end

        end

        if PrevMode ~= DuplPage.Mode then
            DuplPage:updatePageLEDs(LEDHelper.LS_BRIGHT)
            DuplPage:updateScreens(true)
            return Pressed -- If the Scene or Pattern button is released, and the corresponding page is on the page-stack,
                           -- allow HardwareControllerBase:onPageButton() to remove the page from the stack.
        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.onPadEvent(DuplPage, PadIndex)

    if DuplPage.Mode == DuplicateHelper.GROUP and DuplPage.SourceIndex >= 0 then
        -- was in Group-copy mode, but now exit that mode
        DuplicateHelper.setMode(DuplPage, DuplicateHelper.SOUND)
    end

    if DuplPage.SourceIndex < 0 then -- select source object

        if DuplPage.Mode == DuplicateHelper.SCENE then
            local SceneIndex = ArrangerHelper.getSceneIndexFromPadIndex(PadIndex)
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Scene = Song and Song:getScenes():at(SceneIndex)
            if Scene then
                -- focus scene and select it as source for duplication
                DuplPage.SourceIndex = SceneIndex
                ArrangerHelper.focusScene(Scene, true)
            end

        elseif DuplPage.Mode == DuplicateHelper.SECTION then
            local SectionIndex = ArrangerHelper.getSectionIndexFromPadIndex(PadIndex)
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Section = Song and Song:getSections():find(SectionIndex) or nil
            if Section then
                -- focus section and select it as source for duplication
                DuplPage.SourceIndex = SectionIndex
                ArrangerHelper.focusSectionByIndex(SectionIndex, false, true)
            end

        elseif DuplPage.Mode == DuplicateHelper.PATTERN then
            local PatternIndex = PatternHelper.getPatternIndexFromPadIndex(PadIndex)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local Pattern = Group and Group:getPatterns():find(PatternIndex) or nil
            if Pattern then
                -- focus pattern and select it as source for duplication
                DuplPage.SourceIndex = PatternIndex
                PatternHelper.focusPatternByIndex(PatternIndex, false)
            end

        elseif DuplPage.Mode == DuplicateHelper.CLIP then

            local ClipIndex = ClipHelper.getClipIndex(PadIndex)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local ClipEvent = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, ClipIndex) or nil
            if ClipEvent then
                DuplPage.SourceIndex = ClipIndex
                NI.DATA.GroupAccess.setFocusClipEvent(App, Group, ClipEvent)
            end


        else
            -- focus sound and select it for duplication
            MaschineHelper.setFocusSound(PadIndex)

            DuplicateHelper.setMode(DuplPage, DuplicateHelper.SOUND)
            DuplPage.SourceIndex = PadIndex - 1
            DuplPage.SourceGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)
        end

    else -- duplicate object

        local Success = false
        local DstIndex = -1

        if DuplPage.Mode == DuplicateHelper.SCENE then

            DstIndex = ArrangerHelper.getSceneIndexFromPadIndex(PadIndex)

            if DstIndex ~= DuplPage.SourceIndex then
                Success = ArrangerHelper.duplicateScene(DuplPage.SourceIndex, DstIndex)
            end

        elseif DuplPage.Mode == DuplicateHelper.SECTION then

            DstIndex = ArrangerHelper.getSectionIndexFromPadIndex(PadIndex)

            if DstIndex ~= DuplPage.SourceIndex then
                Success = ArrangerHelper.duplicateSection(DuplPage.SourceIndex, DstIndex)
            end

        elseif DuplPage.Mode == DuplicateHelper.PATTERN then

            DstIndex = PatternHelper.getPatternIndexFromPadIndex(PadIndex)
            if DstIndex ~= DuplPage.SourceIndex then
                Success = PatternHelper.duplicatePattern(DuplPage.SourceIndex, DstIndex)
            end

        elseif DuplPage.Mode == DuplicateHelper.CLIP then
            DstIndex = ClipHelper.getClipIndex(PadIndex)
            if DstIndex ~= DuplPage.SourceIndex then
                ClipHelper.duplicateClip(DuplPage.SourceIndex, DstIndex)
                Success = true
            end

        elseif DuplPage.Mode == DuplicateHelper.SOUND then

            local StateCache = App:getStateCache()
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local SrcGroup = Song and Song:getGroups():at(DuplPage.SourceGroupIndex) or nil
            local SrcSound = SrcGroup and SrcGroup:getSounds():at(DuplPage.SourceIndex) or nil
            local DstGroup = NI.DATA.StateHelper.getFocusGroup(App)
            local DstGroupIdx = Song and DstGroup and Song:getGroups():calcIndex(DstGroup) or -1
            DstIndex = PadIndex - 1

            if SrcSound and DstGroup and ((DstGroupIdx ~= DuplPage.SourceGroupIndex) or (DuplPage.SourceIndex ~= DstIndex)) then

                local WithEvent = App:getWorkspace():getDuplicateSoundWithEventsParameter():getValue()
                Success = NI.DATA.GroupAccess.duplicateSound(App, SrcGroup, DstGroup, SrcSound, DstIndex, WithEvent)

                DuplPage.SourceGroupIndex = Success and DstGroupIdx or -1

            end

        end

        -- set the source index to the newly duplicated object index
        DuplPage.SourceIndex = Success and DstIndex or -1

    end

end

------------------------------------------------------------------------------------------------------------------------
-- onGroupButton: GroupIndex is the actual (0-indexed) Group index, not a button index.
------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.onGroupButton(DuplPage, GroupIndex)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    if not Groups or not Song then
        error("Error: Can not access Song or Groups")
        return
    end

    local CanPasteGroup = DuplPage.Mode == DuplicateHelper.GROUP and DuplPage.SourceIndex >= 0
    local CanPasteSound = DuplPage.Mode == DuplicateHelper.SOUND and DuplPage.SourceIndex >= 0

    local SceneOrPatternMode = DuplPage.Mode == DuplicateHelper.SCENE or
                               DuplPage.Mode == DuplicateHelper.SECTION or
                               DuplPage.Mode == DuplicateHelper.PATTERN or
                               DuplPage.Mode == DuplicateHelper.CLIP


    if SceneOrPatternMode and DuplPage.SourceIndex >= 0 then

        return -- don't handle Group button when a scene/section/pattern/clip is ready to paste

    elseif not CanPasteGroup or SceneOrPatternMode then -- focus Group

        local Group = Groups:at(GroupIndex)
        if Group then
            NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)

            -- set Group mode only if another mode isn't yet set
            if DuplPage.SourceIndex < 0 and not SceneOrPatternMode then
                DuplicateHelper.setMode(DuplPage, DuplicateHelper.GROUP)
                DuplPage.SourceIndex = GroupIndex
            end
        elseif DuplPage.SourceIndex >= 0 and GroupIndex == Groups:size() then

            NI.DATA.SongAccess.createGroup(App, Song, false)

        end

    else -- duplicate Group

        local SrcGroup = Groups:at(DuplPage.SourceIndex)
        local bSuccess

        if SrcGroup and DuplPage.SourceIndex ~= GroupIndex then
            local WithPatterns = App:getWorkspace():getDuplicateGroupWithPatternsParameter():getValue()
            bSuccess = NI.DATA.SongAccess.duplicateGroup(App, Song, SrcGroup, GroupIndex, WithPatterns)
        end

        DuplPage.SourceIndex = bSuccess and GroupIndex or -1
        DuplPage.SourceGroupIndex = bSuccess and GroupIndex or -1

    end

end

-----------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getPadLEDState(Index, Mode, DoBlink)

    local Focused, Enabled

    if Mode == DuplicateHelper.SOUND or Mode == DuplicateHelper.GROUP then

        Focused, Enabled = MaschineHelper.getLEDStatesSoundFocusByIndex(Index, true)

    elseif Mode == DuplicateHelper.SCENE then

        Focused, Enabled = MaschineHelper.isSceneFocusByIndex(Index, DoBlink)

    elseif Mode == DuplicateHelper.SECTION then

        Focused, Enabled = MaschineHelper.isSectionFocusByIndex(Index)

    elseif Mode == DuplicateHelper.PATTERN then

        Focused, Enabled = MaschineHelper.isPatternFocusByIndex(Index)

    elseif Mode == DuplicateHelper.CLIP then

        Focused, Enabled = MaschineHelper.isClipFocusByIndex(Index, DoBlink)

    end

    if Focused and DoBlink then
        if DuplicateHelper.getLEDBlinkState() == LEDHelper.LS_DIM then
            Focused = false
            Enabled = true
        end
    end

    return Focused, Enabled

end

-----------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.updatePageLEDs(LEDState, DuplMode, Controller)

    if NHLController:getPageStack():getTopPage() == NI.HW.PAGE_DUPLICATE then
        local SongView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)

        LEDHelper.setLEDState(NI.HW.LED_SCENE,
            (DuplMode == DuplicateHelper.SCENE or DuplMode == DuplicateHelper.SECTION
            or (Controller:isButtonPressed(NI.HW.BUTTON_SCENE) and Controller:getShiftPressed()))
            and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
        LEDHelper.setLEDState(NI.HW.LED_PATTERN,
            SongView and (DuplMode == DuplicateHelper.CLIP and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM)
            or (DuplMode == DuplicateHelper.PATTERN and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM))
    else
        LEDHelper.setLEDState(NI.HW.LED_SCENE, LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_PATTERN, LEDHelper.LS_OFF)
    end

end

-----------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.updatePadLEDs(DuplPage, LEDs, CanPaste)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ColorFunctor = MaschineHelper.getSoundColorByIndex
    local BaseIndex = 0

    if DuplPage.Mode == DuplicateHelper.SOUND then
        CanPaste = CanPaste and DuplPage.SourceGroupIndex == NI.DATA.StateHelper.getFocusGroupIndex(App)

    elseif DuplPage.Mode == DuplicateHelper.SCENE then
        ColorFunctor = function (Index) return MaschineHelper.getIdeaSpaceSceneColorByIndex(Index, CanPaste) end
        BaseIndex = Song and Song:getFocusSceneBankIndexParameter():getValue() * 16 or 0

    elseif DuplPage.Mode == DuplicateHelper.SECTION then
        ColorFunctor = MaschineHelper.getSectionSceneColorByIndex
        BaseIndex = Song and Song:getFocusSectionBankIndexParameter():getValue() * 16 or 0

    elseif DuplPage.Mode == DuplicateHelper.PATTERN then
        ColorFunctor = MaschineHelper.getPatternColorByIndex
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        BaseIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() * 16 or 0

    elseif DuplPage.Mode == DuplicateHelper.CLIP then
        ColorFunctor = function (Index) return MaschineHelper.getClipColorByIndex(Index, CanPaste) end
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        BaseIndex = Group and Group:getClipEventBankParameter():getValue() * 16 or 0
    end

    LEDHelper.updateLEDsWithFunctor(LEDs, BaseIndex,
        function(Index) return DuplicateHelper.getPadLEDState(Index, DuplPage.Mode, CanPaste) end,
        ColorFunctor)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.updateGroupLEDs(DuplPage, CanPasteGroup, CanPasteSound)

    local CanPaste = CanPasteGroup or CanPasteSound

    local GroupLEDStateFunctor =
        function(Index)
            return MaschineHelper.getLEDStatesGroupFocusByIndex(Index, CanPaste)
        end

    local GroupLEDColorFunctor =
        function(Index)
            return MaschineHelper.getGroupColorByIndex(Index, CanPaste)
        end

    LEDHelper.updateLEDsWithFunctor(DuplPage.Controller.GROUP_LEDS,
                                                DuplPage.Screen.GroupBank * 8,
                                                GroupLEDStateFunctor,
                                                GroupLEDColorFunctor)

    if CanPasteGroup then
        DuplicateHelper:blinkGroupLed(DuplPage)
   end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper:blinkGroupLed(DuplPage)

    -- If a group is ready for pasting, flash the copied group's led
    local NumBanks = MaschineHelper.getNumFocusSongGroupBanks(true)

    if DuplPage.Screen.GroupBank == math.floor(DuplPage.SourceIndex / 8) then
        local ButtonLEDIdx = (DuplPage.SourceIndex % 8) + 1
        local Color = MaschineHelper.getGroupColorByIndex(DuplPage.SourceIndex+1)

        LEDHelper.setLEDState(DuplPage.Controller.GROUP_LEDS[ButtonLEDIdx], DuplicateHelper.getLEDBlinkState(), Color)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- getGroupGridButtonStates:
-- Functor: Visible, Enabled, Selected, Focused, Text
------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.getGroupGridButtonStates(ButtonIndex, GroupBank, GroupCanPaste)

    local Index = (ButtonIndex-1) + GroupBank * 8
    local FocusGroupIndex = NI.DATA.StateHelper.getFocusGroupIndex(App)

    local StateCache= App:getStateCache()
    local Song      = NI.DATA.StateHelper.getFocusSong(App)
    local Groups    = Song and Song:getGroups() or nil
    local Group     = Groups and Groups:at(Index) or nil
    local Size      = Groups and Groups:size() or 0

    local InsertAddGroup = (Index == Size) and GroupCanPaste

    local Name

    if Group then
        Name = Group:getDisplayName()
        if Name == "" then
            Name = Group:getPlaceholderName(GroupBank*8 + ButtonIndex-1)
        end
    else
        Name = InsertAddGroup and "+" or ""
    end

    local Enabled   = Group ~= nil or false
    local Focused = Group and Group == NI.DATA.StateHelper.getFocusGroup(App) or false

    return true, Enabled, false, Focused, Name

end

------------------------------------------------------------------------------------------------------------------------

function DuplicateHelper.onLeftRightButton(DuplPage, Right)

    if DuplPage.Mode == DuplicateHelper.GROUP or DuplPage.Mode == DuplicateHelper.GROUP_SELECT then

        local NumBanks = MaschineHelper.getNumFocusSongGroupBanks(true)

        if (not Right and DuplPage.Screen.GroupBank > 0) or (Right and DuplPage.Screen.GroupBank+1 < NumBanks) then
            DuplPage.Screen.GroupBank = DuplPage.Screen.GroupBank + (not Right and -1 or 1)
            DuplPage:updateScreens()
        end

    elseif DuplPage.Mode == DuplicateHelper.SCENE then

        ArrangerHelper.setPrevNextSceneBank(Right)

    elseif DuplPage.Mode == DuplicateHelper.SECTION then

        ArrangerHelper.setPrevNextSectionBank(Right)

    elseif DuplPage.Mode == DuplicateHelper.PATTERN then

        PatternHelper.setPrevNextPatternBank(Right)

    elseif DuplPage.Mode == DuplicateHelper.CLIP then

        ClipHelper.shiftBank(Right)
    end

end

------------------------------------------------------------------------------------------------------------------------
