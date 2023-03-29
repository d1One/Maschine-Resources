require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicatePage = class( 'DuplicatePage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:__init(Controller)

    PageMaschine.__init(self, "DuplicatePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_DUPLICATE }

    -- BaseMode is used to preserve last mode (Sound or Group) before going into Pattern or Scene mode, so that when
    -- user leaves Pattern or Scene mode, he ends up on last used mode.
    self.BaseMode = DuplicateHelper.SOUND
    self.Mode = self.BaseMode

    -- index of object to duplicate (e.g. sound, Group, scene, pattern).
    -- when this is >0, the next pad event down will duplicate object from this index.
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:setupScreen()

    self.Screen = ScreenWithGrid(self)

    -- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPLICATE", "", "", "", "", "", "", ""})
    self.Screen.ScreenButton[1]:style("DUPLICATE", "HeadPin");

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(true)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onShow(Show)

    if Show then
        -- sync Group bank with that in SW
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
    else
        self.Mode = self.BaseMode
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:updateScreens(ForceUpdate)

    DuplicateHelper.updateSceneSectionMode(self, ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    -- Check Source Validity! (Group or pattern could be deleted before pasting)
    if not DuplicateHelper.isSourceValid(self.Mode, self.SourceIndex, self.SourceGroupIndex) then
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    -- update on-screen Group button grid (left screen)
    local ShowGroupButtons =
        self.Mode ~= DuplicateHelper.SCENE and
        self.Mode ~= DuplicateHelper.SECTION and
        self.Mode ~= DuplicateHelper.PATTERN and
        self.Mode ~= DuplicateHelper.CLIP

    if ForceUpdate then
        for Idx, Button in ipairs(self.Screen.GroupButtons) do
            Button:setActive(ShowGroupButtons)
        end
    end

    if ShowGroupButtons then
        local GroupCanPaste = self.SourceIndex >= 0
            and (self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.SOUND)

        local GroupStateFunctor =
            function(Index)
                return DuplicateHelper.getGroupGridButtonStates(Index, self.Screen.GroupBank, GroupCanPaste)
            end

        self.Screen:updateGroupButtonsWithFunctor(GroupStateFunctor)
    end


    --  update on-screen pad grid (right screen)
    if self.Mode == DuplicateHelper.SCENE then
        ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
            function (Index) return ArrangerHelper.SceneStateFunctor(Index, self.SourceIndex >= 0) end)
    elseif self.Mode == DuplicateHelper.SECTION then
        ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
            function (Index) return ArrangerHelper.SectionStateFunctor(Index, false) end)
    elseif self.Mode == DuplicateHelper.PATTERN then
        ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad, PatternHelper.PatternStateFunctor)
    elseif self.Mode == DuplicateHelper.CLIP then
        ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
            function (Index) return ClipHelper.ClipStateFunctor(Index, self.SourceIndex >= 0) end)
    else
        ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad, MaschineHelper.SoundStateFunctor)
    end


    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updatePageLEDs(LEDHelper.LS_BRIGHT)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:updateScreenButtons(ForceUpdate)

    if self.Mode == DuplicateHelper.SCENE then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL SCN", "", "", "", "", "", "<", ">"})
        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSceneBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    elseif self.Mode == DuplicateHelper.SECTION then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL SCT", "LINK", "", "", "", "", "<", ">"})
        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSectionBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    elseif self.Mode == DuplicateHelper.PATTERN then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL PAT", "", "", "", "", "", "<", ">"})
        local HasPrev, HasNext = PatternHelper.hasPrevNextPatternBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    elseif self.Mode == DuplicateHelper.CLIP then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL CLP", "", "", "", "", "", "<", ">"})
        local HasPrev, HasNext = PatternHelper.hasPrevNextPatternBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(false)
        self.Screen.ScreenButton[8]:setEnabled(false)

    else

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPLICATE", "+PAT", "PREV", "NEXT", "+EVENTS", "",
                                                              "", ""})

        local NumGroupBanks = MaschineHelper.getNumFocusSongGroupBanks(self.SourceIndex >= 0)

        self.Screen.ScreenButton[1]:setEnabled(true)
        self.Screen.ScreenButton[3]:setEnabled(self.Screen.GroupBank > 0)
        self.Screen.ScreenButton[4]:setEnabled(self.Screen.GroupBank < NumGroupBanks-1)

        -- disable +PATTERNS and +EVENTS buttons in songview
        local SongClipView = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
        if SongClipView then
            self.Screen.ScreenButton[2]:setEnabled(false)
            self.Screen.ScreenButton[2]:setVisible(false)
        end

        local isGroupFocused = NI.DATA.StateHelper.getFocusGroup(App) and true or false
        self.Screen.ScreenButton[5]:setEnabled(isGroupFocused and not SongClipView)
        self.Screen.ScreenButton[5]:setVisible(isGroupFocused and not SongClipView)

    end

    self.Screen.ScreenButton[2]:setSelected(DuplicateHelper.getDuplicateWithOption(self.Mode) == true)
    self.Screen.ScreenButton[5]:setSelected(App:getWorkspace():getDuplicateSoundWithEventsParameter():getValue())

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:updatePageLEDs(LEDState)

    DuplicateHelper.updatePageLEDs(LEDState, self.Mode, self.Controller)
    PageMaschine.updatePageLEDs(self, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, self.Mode ~= DuplicateHelper.GROUP and self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:updateGroupLEDs()

    local CanPasteGroup = self.Mode == DuplicateHelper.GROUP and self.SourceIndex >= 0
    local CanPasteSound = self.Mode == DuplicateHelper.SOUND and self.SourceIndex >= 0

    DuplicateHelper.updateGroupLEDs(self, CanPasteGroup, CanPasteSound)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onPageButton(Button, PageID, Pressed)

    if self.Controller:getShiftPressed() then
        return false
    end

    return DuplicateHelper.onPageButton(Button, Pressed, self)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        if ButtonIdx == 2 and self.Screen.ScreenButton[2]:isVisible() then
            -- toggle selected state
            DuplicateHelper.setDuplicateWithOption(self.Mode, not DuplicateHelper.getDuplicateWithOption(self.Mode))

        elseif (ButtonIdx == 3 and self.Screen.ScreenButton[3]:isVisible()) or
               (ButtonIdx == 4 and self.Screen.ScreenButton[4]:isVisible()) then

            self.Screen:incrementGroupBank(ButtonIdx == 3 and -1 or 1)

        elseif ButtonIdx == 5 and self.Screen.ScreenButton[5]:isVisible() then

            local Param = App:getWorkspace():getDuplicateSoundWithEventsParameter()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())

        elseif (ButtonIdx == 7 and self.Screen.ScreenButton[7]:isVisible()) or
               (ButtonIdx == 8 and self.Screen.ScreenButton[8]:isVisible()) then

            if self.Mode == DuplicateHelper.SCENE then
                ArrangerHelper.setPrevNextSceneBank(ButtonIdx == 8)

            elseif self.Mode == DuplicateHelper.SECTION then
                ArrangerHelper.setPrevNextSectionBank(ButtonIdx == 8)

            elseif self.Mode == DuplicateHelper.PATTERN then
                PatternHelper.setPrevNextPatternBank(ButtonIdx == 8)
            end
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onGroupButton(Index, Pressed)

    if Pressed then
        local GroupIndex = Index-1 + self.Screen.GroupBank * 8
        DuplicateHelper.onGroupButton(self, GroupIndex)
        self:updateScreens()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        DuplicateHelper.onPadEvent(self, PadIndex)
        self:updateScreens()
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onWheel()

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        self.Controller.QuickEdit.NumPadPressed > 0 or self.Controller.QuickEdit.NumGroupPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 or self.Controller.QuickEdit.NumGroupPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 or self.Controller.QuickEdit.NumGroupPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePage:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 or self.Controller.QuickEdit.NumGroupPressed > 0 then
        return true
    end

end


------------------------------------------------------------------------------------------------------------------------
