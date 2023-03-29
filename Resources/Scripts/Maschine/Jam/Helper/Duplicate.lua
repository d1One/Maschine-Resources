
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Maschine/Helper/LedBlinker"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Maschine/Jam/Helper/JamArrangerHelper"
require "Scripts/Maschine/Jam/Helper/JamHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
Duplicate = class( 'Duplicate' )

------------------------------------------------------------------------------------------------------------------------
Duplicate.MODE_SOUND    = 1
Duplicate.MODE_GROUP    = 2
Duplicate.MODE_PATTERN  = 3
Duplicate.MODE_SCENE_SECTION = 4

-- The states of the duplicate functionality is shared across all pages. Therefore, these variables are static
Duplicate.SoundSource   = -1
Duplicate.GroupSource   = -1
Duplicate.PatternSource = -1
Duplicate.SceneSectionSource = -1  -- Is used for Sections when duplicating in non-idea-space mode

-- in Pinned state, we need to remember the state of duplicate (on/off) to be able to toggle
Duplicate.PinToggleState = false
Duplicate.Pinned = false


------------------------------------------------------------------------------------------------------------------------

function Duplicate:__init(Controller)

    self.Controller = Controller
    self.LEDBlinker = LEDBlinker(JamControllerBase.DEFAULT_LED_BLINK_TIME)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:canDuplicate()

    return self.Controller.ActivePage and self.Controller.ActivePage:hasDuplicateMode()

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:setEnabled(On)

    if On and not Duplicate:canDuplicate() then
        return
    end

    NHLController:setDuplicateMode(On)
    Duplicate.PinToggleState = On

    if not On then
        self:reset()
    end

    LEDHelper.setLEDState(NI.HW.LED_DUPLICATE, self:isEnabled() and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:isEnabled()

    return NHLController:getDuplicateMode() and self:canDuplicate()

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:getActiveSectionSize()

    -- If we can duplicate (CanPaste=true) then we are able to create a new section and we have one more active button.
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return 0
    end

    local CanPaste    = Duplicate.SceneSectionSource >= 0



    return Song:getSections():size() + (CanPaste and 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:getActiveScenesSize()

    -- If we can duplicate (CanPaste=true) then we are able to create a new scene and we have one more active button.
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return 0
    end

    local CanPaste    = Duplicate.SceneSectionSource >= 0

    return Song:getScenes():size() + (CanPaste and 1 or 0)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:reset(Mode)

    if not Mode then

        Duplicate.SoundSource   = -1
        Duplicate.GroupSource   = -1
        Duplicate.PatternSource = -1
        Duplicate.SceneSectionSource = -1

        self.LEDBlinker:reset()

    elseif Mode == Duplicate.MODE_SOUND then

        Duplicate.GroupSource = -1
        Duplicate.SoundSource = -1

    elseif Mode == Duplicate.MODE_GROUP then

        Duplicate.GroupSource = -1

    elseif Mode == Duplicate.MODE_PATTERN then

        Duplicate.GroupSource   = -1
        Duplicate.PatternSource = -1

    elseif Mode == Duplicate.MODE_SCENE_SECTION then

        Duplicate.SceneSectionSource = -1

    end

end

------------------------------------------------------------------------------------------------------------------------
-- Resets member variables that are not related to the requested duplication mode
function Duplicate:enterMode(Mode)

    if Mode == Duplicate.MODE_SOUND then

        Duplicate.PatternSource = -1
        Duplicate.SceneSectionSource = -1

    elseif Mode == Duplicate.MODE_GROUP then

        if self:hasSource(Duplicate.MODE_PATTERN) then
            Duplicate.GroupSource = -1
        end

        Duplicate.SoundSource   = -1
        Duplicate.PatternSource = -1
        Duplicate.SceneSectionSource = -1

    elseif Mode == Duplicate.MODE_PATTERN then

        Duplicate.SoundSource = -1
        Duplicate.SceneSectionSource = -1

    elseif Mode == Duplicate.MODE_SCENE_SECTION then

        Duplicate.SoundSource = -1
        Duplicate.GroupSource = -1
        Duplicate.PatternSource = -1

    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:hasSource(Mode)

    if Mode == Duplicate.MODE_SOUND then
        return Duplicate.SoundSource >= 0
    elseif Mode == Duplicate.MODE_GROUP then
        return Duplicate.GroupSource >= 0
    elseif Mode == Duplicate.MODE_PATTERN then
        return Duplicate.PatternSource >= 0
    elseif Mode == Duplicate.MODE_SCENE_SECTION then
        return Duplicate.SceneSectionSource >= 0
    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onDuplicateButton(Pressed)

    if not self:canDuplicate() then
        LEDHelper.setLEDState(NI.HW.LED_DUPLICATE, LEDHelper.LS_OFF)
        return
    end

    local Enable = Pressed or (Duplicate.Pinned and not Duplicate.PinToggleState)
    NHLController:setDuplicateMode(Enable)

    if not Pressed then
        Duplicate.PinToggleState = Enable
    end

    if not Enable then
        self:reset()
    end

    LEDHelper.setLEDState(NI.HW.LED_DUPLICATE, (self:isEnabled() or Pressed) and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onPinButton(Pressed)

    if Pressed and self.Controller:isButtonPressed(NI.HW.BUTTON_DUPLICATE) and self:canDuplicate() then

        Duplicate.Pinned = not Duplicate.Pinned
        self.Controller:setPinButtonLed(Pressed)
        return true

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------
-- main duplicate functions
------------------------------------------------------------------------------------------------------------------------

function Duplicate:onSoundDuplicate(Index)

    self:enterMode(Duplicate.MODE_SOUND)

    if not self:hasSource(Duplicate.MODE_SOUND) then -- set source sound

        local FocusGroup = NI.DATA.StateHelper.getFocusGroupIndex(App)
        if FocusGroup ~= NPOS then
            MaschineHelper.setFocusSound(Index)
            Duplicate.GroupSource = FocusGroup
            Duplicate.SoundSource = Index
        end

    elseif Duplicate.SoundSource == Index and Duplicate.GroupSource == NI.DATA.StateHelper.getFocusGroupIndex(App) then

        self:reset(Duplicate.MODE_SOUND)

    else -- execute duplicate

        local Song   = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil
        local SrcGroup = Groups and Groups:at(Duplicate.GroupSource) or nil
        local SrcSound = SrcGroup and SrcGroup:getSounds():at(Duplicate.SoundSource-1) or nil
        local DstGroup = NI.DATA.StateHelper.getFocusGroup(App)

        local Success = DstGroup
            and NI.DATA.GroupAccess.duplicateSound(App, SrcGroup, DstGroup, SrcSound, Index-1, true)

        if Success then
            Duplicate.SoundSource = Index
            Duplicate.GroupSource = NI.DATA.StateHelper.getFocusGroupIndex(App)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:canDuplicateGroup()

    return self:isEnabled() and not self:hasSource(Duplicate.MODE_SOUND)

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onGroupDuplicate(Index)

    self:enterMode(Duplicate.MODE_GROUP)

    local Song       = NI.DATA.StateHelper.getFocusSong(App)
    local Groups     = Song and Song:getGroups() or nil
    local GroupIndex = JamHelper.getGroupOffset() + Index

    if not self:hasSource(Duplicate.MODE_GROUP) then -- set source group

        local Group = Groups and Groups:at(GroupIndex) or nil
        if Group then
            NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)
            Duplicate.GroupSource = GroupIndex
        end

    elseif Duplicate.GroupSource == GroupIndex then -- reset source

        self:reset(Duplicate.MODE_GROUP)

    else -- execute duplicate

        local Group = Groups and Groups:at(Duplicate.GroupSource) or nil
        if NI.DATA.SongAccess.duplicateGroup(App, Song, Group, GroupIndex, true) then
            Duplicate.GroupSource = GroupIndex
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onPatternDuplicate(GroupColumn, PatternRow)

    self:enterMode(Duplicate.MODE_PATTERN)

    local PatternIndex = JamHelper.getPatternOffset() + PatternRow - 1
    local GroupIndex   = JamHelper.getGroupOffset() + GroupColumn - 1

    if PatternIndex == Duplicate.PatternSource and Duplicate.GroupSource == GroupIndex then -- reset source pattern

        self:reset(Duplicate.MODE_PATTERN)

    elseif not self:hasSource(Duplicate.MODE_PATTERN) then -- set source pattern

        local Song    = NI.DATA.StateHelper.getFocusSong(App)
        local Group   = Song and Song:getGroups():at(GroupIndex) or nil
        local Pattern = Group and Group:getPatterns():find(PatternIndex)

        if Pattern then
            NI.DATA.GroupAccess.insertPatternAndFocus(App, Group, Pattern)
            local CanCopy = Duplicate.GroupSource == GroupIndex or Duplicate.PatternSource < 0

            Duplicate.GroupSource   = CanCopy and GroupIndex   or -1
            Duplicate.PatternSource = CanCopy and PatternIndex or -1
        end

    else -- execute duplicate

        if PatternHelper.duplicatePatternToGroup(Duplicate.PatternSource, Duplicate.GroupSource, PatternIndex, GroupIndex) then
            Duplicate.PatternSource = PatternIndex
            Duplicate.GroupSource   = GroupIndex
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onSceneDuplicate(Index) -- 1 based index

    self:enterMode(Duplicate.MODE_SCENE_SECTION)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song or Index - 1 > Song:getScenes():size() then
        return
    end

    local SceneIndex = JamArrangerHelper.getPositionBySceneButton(Index)

    if not self:hasSource(Duplicate.MODE_SCENE_SECTION) and SceneIndex ~= NPOS then -- set source scene

        Duplicate.SceneSectionSource = SceneIndex
        local Scene = Song:getScenes():at(SceneIndex)
        ArrangerHelper.focusScene(Scene, true)

    elseif Duplicate.SceneSectionSource == SceneIndex then -- reset source

        self:reset(Duplicate.MODE_SCENE_SECTION)

    else -- execute duplicate

        local SourceScene = Song:getScenes():at(Duplicate.SceneSectionSource)

        if SourceScene and SceneIndex ~= NPOS and
            NI.DATA.IdeaSpaceAccess.duplicateSceneReplace(App, Song, SourceScene, SceneIndex) then
            Duplicate.SceneSectionSource = SceneIndex
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:onSectionDuplicate(Index)

    Duplicate.SoundSource = -1
    Duplicate.GroupSource = -1
    Duplicate.PatternSource = -1

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song or Index > Duplicate.getActiveSectionSize() then
        return
    end

    local SongPos = JamArrangerHelper.getPositionBySceneButton(Index)
    local SectionKey = NI.DATA.SongAlgorithms.getSectionKeyFromSectionPosition(Song, SongPos)

    if not self:hasSource(Duplicate.MODE_SCENE_SECTION) and SectionKey ~= NPOS then -- Select the source Section

        Duplicate.SceneSectionSource = SongPos
        ArrangerHelper.focusSectionByIndex(SectionKey, false, true)

    elseif Duplicate.SceneSectionSource == SongPos then -- Deselect source

        self:reset(Duplicate.MODE_SCENE_SECTION)

    else -- execute duplicate

        local NumSections = Song:getSections():size()
        if SongPos <= NumSections then
            if JamArrangerHelper.duplicateSection(Duplicate.SceneSectionSource, SongPos) then
                Duplicate.SceneSectionSource = SongPos
            end
        end
    end

end

-----------------------------------------------------------------------------------------------------------------------

function Duplicate:blinkLED(DoBlink, Focused, Enabled)

    if Focused and DoBlink and self.LEDBlinker:getBlinkStateTick() == LEDHelper.LS_DIM then
        Focused = false
        Enabled = true
    end

    return Focused, Enabled

end

-----------------------------------------------------------------------------------------------------------------------

function Duplicate:updateSoundLEDs()

    local CanPaste = Duplicate.SoundSource >= 0
        and Duplicate.GroupSource == NI.DATA.StateHelper.getFocusGroupIndex(App)

    local getSoundLEDState = function(Index)
        local Focused, Enabled = MaschineHelper.getLEDStatesSoundFocusByIndex(Index, true)
        return self:blinkLED(CanPaste, Focused, Enabled)
    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_SOUND_LEDS, 0,
        function(Index) return getSoundLEDState(Index) end,
        MaschineHelper.getSoundColorByIndex)

end

-----------------------------------------------------------------------------------------------------------------------

function Duplicate:updateSceneLEDs()

    local CanPaste   = Duplicate.SceneSectionSource >= 0
    local ActiveLEDs

    if ArrangerHelper.isIdeaSpaceFocused() then
        ActiveLEDs = Duplicate.getActiveScenesSize()
    else
        ActiveLEDs = Duplicate.getActiveSectionSize()
    end

    local getSceneLEDState = function(Index)
        local Focused = false
        local Enabled = false
        if Index <= ActiveLEDs then
            Focused, Enabled = JamArrangerHelper.getSceneLEDState(Index, false, CanPaste, true)
        end
        return self:blinkLED(CanPaste, Focused, Enabled)
    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0,
        function(Index) return getSceneLEDState(Index) end,
        function(Index) return JamArrangerHelper.getSceneLEDColorByIndex(Index) end)

end

-----------------------------------------------------------------------------------------------------------------------

function Duplicate:updatePatternLEDs()

    local CanPaste    = Duplicate.PatternSource >= 0
    local BaseIndex   = JamHelper.getPatternOffset()
    local PadRowIndex = 1 + NI.DATA.StateHelper.getFocusGroupIndex(App) - JamHelper.getGroupOffset()

    local getPatternLEDState = function(Index)
        local Focused, Enabled = MaschineHelper.isPatternFocusByIndex(Index)
        if NI.HW.getBrightProjectView() then
            if Focused then
                return self:blinkLED(CanPaste, Focused, Enabled)
            else
                return Enabled, Enabled
            end
        else
            return self:blinkLED(CanPaste, Focused, Enabled)
        end
    end


    local getPatternLEDColor = function(Index)
        local Focused = MaschineHelper.isPatternFocusByIndex(Index)
        return (NI.HW.getBrightProjectView() and Focused)
            and LEDColors.WHITE
            or MaschineHelper.getPatternColorByIndex(Index)
    end

    if PadRowIndex > 0 and PadRowIndex <= 8 then
        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS[PadRowIndex], BaseIndex,
                                        function(Index) return getPatternLEDState(Index) end,
                                        function(Index) return getPatternLEDColor(Index) end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function Duplicate:updateGroupLEDs()

    local DoBlink   = Duplicate.GroupSource >= 0 and Duplicate.SoundSource < 0 and Duplicate.PatternSource < 0
    local CanPaste  = (Duplicate.GroupSource >= 0 and Duplicate.PatternSource < 0) or Duplicate.SoundSource >= 0
    local BaseIndex = JamHelper.getGroupOffset()

    local getGroupLEDState = function(Index)
        local Focused, Enabled = MaschineHelper.getLEDStatesGroupFocusByIndex(Index, CanPaste)
        return self:blinkLED(DoBlink, Focused, Enabled)
    end

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS, BaseIndex,
                                    function(Index) return getGroupLEDState(Index) end,
                                    function(Index) return MaschineHelper.getGroupColorByIndex(Index, CanPaste) end,
                                    MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------
