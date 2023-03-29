------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/DuplicateHelper"

local ATTR_DISABLED_PADS = NI.UTILS.Symbol("DisabledPads")
local ATTR_SHOW_GROUP_BUTTONS = NI.UTILS.Symbol("ShowGroupButtons")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicatePageStudio = class( 'DuplicatePageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:__init(Controller)

    PageMaschine.__init(self, "DuplicatePageStudio", Controller)

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

function DuplicatePageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"DUPLICATE", "+ CONTENT", "<<", ">>"}, {"", "", "<<", ">>"})
    self.Screen.ScreenButton[1]:style("DUPLICATE", "HeadPin");

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(true)

    self.ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    self.ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:onShow(Show)

    if Show then
        -- sync Group bank with current focus Group
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
    else
        self.Mode = DuplicateHelper.SOUND
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updateScreens(ForceUpdate)

    DuplicateHelper.updateSceneSectionMode(self, ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    -- Check Source Validity! (Group or pattern could be deleted before pasting)
    if not DuplicateHelper.isSourceValid(self.Mode, self.SourceIndex, self.SourceGroupIndex) then
        self.SourceIndex = -1
        self.SourceGroupIndex = -1
    end

    self:updateGroupButtons()

    -- set style attribute, if duplicate mode mode is SCENE or Group
    for i, Button in ipairs(self.Screen.PadButtons) do
        Button:setAttribute(ATTR_DISABLED_PADS, (self.Mode == DuplicateHelper.SCENE or
                                      ((self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.SOUND) and
                                        not NI.DATA.StateHelper.getFocusGroup(App))) and "true" or "false")
    end

    --  update on-screen pad grid (right screen)
    if self.Mode == DuplicateHelper.SCENE then
        self.Screen:updatePadButtonsWithFunctor(
            function (Index) return ArrangerHelper.SceneStateFunctor(Index, self.SourceIndex >= 0) end)
    elseif self.Mode == DuplicateHelper.SECTION then
        self.Screen:updatePadButtonsWithFunctor(function (Index) return ArrangerHelper.SectionStateFunctor(Index, false) end)
    elseif self.Mode == DuplicateHelper.PATTERN then
        self.Screen:updatePadButtonsWithFunctor(PatternHelper.PatternStateFunctor)
    elseif self.Mode == DuplicateHelper.CLIP then
        self.Screen:updatePadButtonsWithFunctor(
            function (Index) return ClipHelper.ClipStateFunctor(Index, self.SourceIndex >= 0) end)
    else
        self.Screen:updatePadButtonsWithFunctor(MaschineHelper.SoundStateFunctor)
    end

    self.Screen:enableLevelMeters(self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.SOUND)


    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updatePadColors()
    self:updatePageLEDs(LEDHelper.LS_BRIGHT)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updateGroupButtons()

    -- update on-screen Group button grid (left screen)
    local ShowGroupButtons =
        self.Mode ~= DuplicateHelper.SCENE and
        self.Mode ~= DuplicateHelper.SECTION and
        self.Mode ~= DuplicateHelper.PATTERN and
        self.Mode ~= DuplicateHelper.CLIP

    for Idx, Button in ipairs(self.Screen.GroupButtons) do
        Button:setActive(ShowGroupButtons)
    end

    self.ParamBar:setActive(not ShowGroupButtons)
    self.Screen.ScreenLeft.DisplayBar:setAttribute(ATTR_SHOW_GROUP_BUTTONS, ShowGroupButtons and "true" or "false")

    if ShowGroupButtons then
        local GroupCanPaste = self.SourceIndex >= 0
            and (self.Mode == DuplicateHelper.GROUP or self.Mode == DuplicateHelper.SOUND)

        local GroupStateFunctor =
            function(Index)
                return DuplicateHelper.getGroupGridButtonStates(Index, self.Screen.GroupBank, GroupCanPaste)
            end

        self.Screen:updateGroupButtonsWithFunctor(GroupStateFunctor)
    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updatePadColors()

    if self.Mode == DuplicateHelper.SCENE then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local BankIndex = Song and Song:getFocusSceneBankIndexParameter():getValue() or 0

        for Index, Button in ipairs (self.Screen.PadButtons) do
            ColorPaletteHelper.setSceneColor(Button, 16 * BankIndex + Index, self.SourceIndex >= 0)
            ColorPaletteHelper.setSceneColor(Button.Label, 16 * BankIndex + Index, self.SourceIndex >= 0)
            Button:setInvalid(0)
        end

    elseif self.Mode == DuplicateHelper.SECTION then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local BankIndex = Song and Song:getFocusSectionBankIndexParameter():getValue() or 0

        for Index, Button in ipairs (self.Screen.PadButtons) do
            ColorPaletteHelper.setSectionColor(Button, 16 * BankIndex + Index)
            ColorPaletteHelper.setSectionColor(Button.Label, 16 * BankIndex + Index)
            Button:setInvalid(0)
        end

    elseif self.Mode == DuplicateHelper.PATTERN then

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local BankIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() or 0

        for Index, Button in ipairs (self.Screen.PadButtons) do
            ColorPaletteHelper.setPatternColor(Button, 16 * BankIndex + Index)
            ColorPaletteHelper.setPatternColor(Button.Label, 16 * BankIndex + Index)
            Button:setInvalid(0)
        end

    elseif self.Mode == DuplicateHelper.CLIP then

        for Index, Button in ipairs (self.Screen.PadButtons) do

            local ClipIndex = ClipHelper.getClipIndex(Index)

            ColorPaletteHelper.setClipColor(Button, ClipIndex, self.SourceIndex >= 0)
            ColorPaletteHelper.setClipColor(Button.Label, ClipIndex, self.SourceIndex >= 0)

            Button:setInvalid(0)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updateScreenButtons(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    if not Song or not Group then
        PageMaschine.updateScreenButtons(self, ForceUpdate)
        return
    end

    if self.Mode == DuplicateHelper.SCENE then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL SCN", "", "", "", "", "", "<<", ">>"})
        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSceneBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

        self.Screen:unsetArrowText(1)
        self.Screen:setArrowText(2, "BANK "..Song:getFocusSceneBankIndexParameter():getValue() + 1)

    elseif self.Mode == DuplicateHelper.SECTION then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL SCT", "LINK", "", "", "", "", "<<", ">>"})
        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSectionBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

        self.Screen:unsetArrowText(1)
        self.Screen:setArrowText(2, "BANK "..Song:getFocusSectionBankIndexParameter():getValue() + 1)

    elseif self.Mode == DuplicateHelper.PATTERN then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL PAT", "", "", "", "", "", "<<", ">>"})
        local HasPrev, HasNext = PatternHelper.hasPrevNextPatternBanks()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

        self.Screen:unsetArrowText(1)
        self.Screen:setArrowText(2, "BANK "..Group:getFocusPatternBankIndexParameter():getValue() + 1)

    elseif self.Mode == DuplicateHelper.CLIP then

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPL CLP", "", "", "", "", "", "<", ">"})
        local HasPrev, HasNext = ClipHelper.hasPrevNextBank()

        self.Screen.ScreenButton[1]:setEnabled(false)
        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

        self.Screen:unsetArrowText(1)
        self.Screen:setArrowText(2, "BANK "..Group:getClipEventBankParameter():getValue() + 1)

    else

        ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"DUPLICATE", "+ CONTENT", "<<", ">>", "+ EVENTS", "", "", ""})

        local NumGroupBanks = MaschineHelper.getNumFocusSongGroupBanks(self.SourceIndex >= 0)

        local BankIndex = MaschineHelper.getFocusGroupBank(self)

        self.Screen.ScreenButton[1]:setEnabled(true)
        self.Screen.ScreenButton[3]:setEnabled(BankIndex > 0)
        self.Screen.ScreenButton[4]:setEnabled(BankIndex < NumGroupBanks-1)

        local isGroupFocused = NI.DATA.StateHelper.getFocusGroup(App) and true or false
        self.Screen.ScreenButton[5]:setEnabled(isGroupFocused)
        self.Screen.ScreenButton[5]:setVisible(isGroupFocused)

        self.Screen:unsetArrowText(2)
    end

    self.Screen.ScreenButton[2]:setSelected(DuplicateHelper.getDuplicateWithOption(self.Mode) == true)
    self.Screen.ScreenButton[5]:setSelected(App:getWorkspace():getDuplicateSoundWithEventsParameter():getValue())

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updatePageLEDs(LEDState)

    DuplicateHelper.updatePageLEDs(LEDState, self.Mode, self.Controller)
    PageMaschine.updatePageLEDs(self, LEDState)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS,
        self.Mode ~= DuplicateHelper.GROUP and self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:updateGroupLEDs()

    local CanPasteGroup = self.Mode == DuplicateHelper.GROUP and self.SourceIndex >= 0
    local CanPasteSound = self.Mode == DuplicateHelper.SOUND and self.SourceIndex >= 0

    DuplicateHelper.updateGroupLEDs(self, CanPasteGroup, CanPasteSound)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:onPageButton(Button, PageID, Pressed)

    if self.Controller:getShiftPressed() then
        return false
    end

    return DuplicateHelper.onPageButton(Button, Pressed, self)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:onScreenButton(ButtonIdx, Pressed)

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

            elseif self.Mode == DuplicateHelper.CLIP then
                ClipHelper.shiftBank(ButtonIdx == 8)
            end
        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:onGroupButton(Index, Pressed)

    if Pressed then
        local GroupIndex = Index-1 + self.Screen.GroupBank * 8
        DuplicateHelper.onGroupButton(self, GroupIndex)

        self:updateScreens()
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger then
        DuplicateHelper.onPadEvent(self, PadIndex)
        self:updateScreens()
    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:isGroupQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePageStudio:getAccessiblePageInfo()

    return "Duplicate"

end

------------------------------------------------------------------------------------------------------------------------
