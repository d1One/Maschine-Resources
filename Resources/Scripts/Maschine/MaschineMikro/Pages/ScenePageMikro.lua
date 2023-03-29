------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePageMikro = class( 'ScenePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "ScenePage", Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    self.ParameterIndex = 1
    ArrangerHelper.setAppendMode(self, false)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SCENE }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- title
    ScreenHelper.setWidgetText(self.Screen.Title, {"SCENE"})

    -- info bar
    self.Screen.InfoBar:setMode("FocusedScene")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateScreens(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if Song and Song:getArrangerState():isViewChanged() then
        ArrangerHelper.setAppendMode(self, false)
    end

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

    ScreenHelper.setWidgetText(self.Screen.Title, { IdeaSpaceVisible and "SCENE" or "SECTION" })

    if IdeaSpaceVisible then
        local Scene = NI.DATA.StateHelper.getFocusScene(App)

        if self.Controller:getShiftPressed() or self.AppendMode then
            self.Screen:styleScreenButtons({"", "", "APPEND"}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[3]:setSelected(self.AppendMode)
        else
            self.Screen:styleScreenButtons({"UNIQUE", "DUPL", "DELETE"}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[3]:setEnabled(Scene ~= nil)
        end

        self.Screen.ScreenButton[1]:setEnabled(Scene ~= nil and Song ~= nil
                                               and not NI.DATA.IdeaSpaceAlgorithms.isSceneUnique(Song, Scene))
        self.Screen.ScreenButton[2]:setEnabled(Scene ~= nil)
    else
        local Section = NI.DATA.StateHelper.getFocusSection(App)

        if self.Controller:getShiftPressed() then
            self.Screen:styleScreenButtons({"", "", "AUT LEN"}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[3]:setEnabled(Section ~= nil and not Section:getAutoLengthParameter():getValue())
        else
            local Button3Text = ArrangerHelper.deleteSectionButtonText()
            self.Screen:styleScreenButtons({"UNIQUE", "DUPL", Button3Text}, "HeadButtonRow", "HeadButton")
            self.Screen.ScreenButton[3]:setText(Button3Text)
            self.Screen.ScreenButton[3]:setEnabled(Section ~= nil)
        end

        self.Screen.ScreenButton[1]:setEnabled(Section ~= nil and Song ~= nil
                                               and not NI.DATA.SongAlgorithms.isSectionUnique(Song, Section))
        self.Screen.ScreenButton[2]:setEnabled(Section ~= nil)
    end

    self.Screen.ScreenButton[1]:setVisible(not self.Controller:getShiftPressed() and not self.AppendMode)
    self.Screen.ScreenButton[2]:setVisible(not self.Controller:getShiftPressed() and not self.AppendMode)

    NHLController:setPadMode(IdeaSpaceVisible
                             and (self.AppendMode and NI.HW.PAD_MODE_NONE or NI.HW.PAD_MODE_SCENE)
                             or NI.HW.PAD_MODE_SECTION)

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateParameters(ForceUpdate)

    if self.Controller:getShiftPressed() then
        -- show banks instead of parameters in parameter bar
        self:updateBankParameters()
    else
        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
        if IdeaSpaceVisible then
            self:updateSceneParameters()
        else
            self:updateSectionParameters()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateSceneParameters()

    self.Screen.ParameterLabel[2]:setText("RETRIGGER")
    self.Screen.ParameterLabel[4]:setText(ArrangerHelper.getSectionRetrigValueString())

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateSectionParameters()

    local ParameterNames = {"POSITION", "SCENE", "LENGTH", "RETRIGGER" }

    local Name = self.ParameterIndex .. "/" .. #ParameterNames .. ": " .. ParameterNames[self.ParameterIndex]
    local Value = "-"

    if self.ParameterIndex == 1 then
        -- display position of selected section
        Value = ArrangerHelper.getFocusedSectionSongPosAsString()

    elseif self.ParameterIndex == 2 then

        -- display referenced scene of selected section
        Value = ArrangerHelper.getSceneReferenceParameterValue()

    elseif self.ParameterIndex == 3 then

        -- display length of selected section
        Value = ArrangerHelper.getFocusSectionLengthString()

    elseif self.ParameterIndex == 4 then

        Value = ArrangerHelper.getSectionRetrigValueString()

    end

    self.Screen.ParameterLabel[2]:setText(Name)
    self.Screen.ParameterLabel[4]:setText(Value)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateBankParameters()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Name = ""

    if Song then
        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

        local BankIdx = IdeaSpaceVisible and
            Song:getFocusSceneBankIndexParameter():getValue() or
            Song:getFocusSectionBankIndexParameter():getValue()
        local NumBanks = IdeaSpaceVisible and
            (math.floor(Song:getScenes():size() / 16) + 1) or
            Song:getNumSectionBanksParameter():getValue()

        Name = "BANK: " .. tostring(BankIdx + 1) .. "/" .. tostring(NumBanks)
    end

    self.Screen.ParameterLabel[2]:setText(Name)
    self.Screen.ParameterLabel[4]:setText("")

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updateLeftRightLEDs(ForceUpdate)

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

    if self.Controller:getShiftPressed() then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            local BankIdx = IdeaSpaceVisible and
                Song:getFocusSceneBankIndexParameter():getValue() or
                Song:getFocusSectionBankIndexParameter():getValue()
            local NumBanks = IdeaSpaceVisible and
                (math.floor(Song:getScenes():size() / 16) + 1) or
                Song:getNumSectionBanksParameter():getValue()

            -- once these labels' visibility are set correctly, the base implementation will do the rest
            self.Screen.ParameterLabel[1]:setVisible(BankIdx > 0)
            self.Screen.ParameterLabel[3]:setVisible(
                BankIdx + 1 < NumBanks or (not IdeaSpaceVisible and ArrangerHelper.canAddSectionBank()))
        end

    else
        self.Screen.ParameterLabel[1]:setVisible(not IdeaSpaceVisible and self.ParameterIndex > 1)
        self.Screen.ParameterLabel[3]:setVisible(not IdeaSpaceVisible and self.ParameterIndex < 4)
    end

    PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:updatePadLEDs()

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
    if IdeaSpaceVisible then
        ArrangerHelper.updatePadLEDsIdeaSpace(self.Controller, self.AppendMode)
    else
        ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)
    end

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onShow(Show)

    if Show then
        self.TransactionSequenceMarker:reset()

        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
        NHLController:setPadMode(IdeaSpaceVisible and NI.HW.PAD_MODE_SCENE or NI.HW.PAD_MODE_SECTION)
    else
        ArrangerHelper.setAppendMode(self, false)
        ArrangerHelper.resetHoldingPads()
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    PageMikro.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onPadEvent(PadIndex, Pressed, PadValue)

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()
    if IdeaSpaceVisible then
        ArrangerHelper.onPadEventIdeas(
            PadIndex, Pressed, self.Controller:getErasePressed(), not self.AppendMode, self.AppendMode)
    else
        ArrangerHelper.onPadEventSections(PadIndex, Pressed, self.Controller:getErasePressed(), true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onWheel(Inc)

    if self.Controller:getShiftPressed() then
        return false
    end

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

    if IdeaSpaceVisible or self.ParameterIndex == 4 then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            RetrigParam = Song:getPerformRetrigParameter()
            NI.DATA.ParameterAccess.addParameterWheelDelta(App, RetrigParam, Inc, false, true)
        end

    elseif self.ParameterIndex == 1 then

        self.TransactionSequenceMarker:set()
        NI.DATA.SongAccess.swapFocusedSection(App, Inc > 0)

    elseif self.ParameterIndex == 2 then

        ArrangerHelper.shiftSceneOfFocusSection(Inc)

    elseif self.ParameterIndex == 3 then

        ArrangerHelper.incrementFocusSectionLength(Inc, self.Controller:getWheelButtonPressed())

    end

    return true

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onScreenButton(ButtonIdx, Pressed)

    if Pressed then
        local ShiftPressed = self.Controller:getShiftPressed()
        local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

        if IdeaSpaceVisible then
            self:onScreenButtonPressedIdeas(ButtonIdx, ShiftPressed)
        else
            self:onScreenButtonPressedSections(ButtonIdx, ShiftPressed)
        end
    end

    -- call base class for update
    PageMikro.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onScreenButtonPressedIdeas(ButtonIdx, ShiftPressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = NI.DATA.StateHelper.getFocusScene(App)

    if ButtonIdx == 1 and Song and Scene and not ShiftPressed then
        NI.DATA.IdeaSpaceAccess.makeSceneUnique(App, Song, Scene)

    elseif ButtonIdx == 2 and Song and Scene and not ShiftPressed then
        NI.DATA.IdeaSpaceAccess.duplicateScene(App, Song, Scene)

    elseif ButtonIdx == 3 then
        if ShiftPressed or self.AppendMode then
            ArrangerHelper.setAppendMode(self, not self.AppendMode)
        else
            ArrangerHelper.removeFocusedSceneOrBank(false)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onScreenButtonPressedSections(ButtonIdx, ShiftPressed)

    if ButtonIdx == 1 and not ShiftPressed then
        ArrangerHelper.makeSectionSceneUnique()

    elseif ButtonIdx == 2 and not ShiftPressed then
        ArrangerHelper.duplicateSection()

    elseif ButtonIdx == 3 then
        if not ShiftPressed then
            ArrangerHelper.removeFocusedSectionOrBank(false)
        else
            ArrangerHelper.setFocusSectionAutoLength()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onLeftRightButton(Right, Pressed)

    if not Pressed then
        return
    end

    local IdeaSpaceVisible = ArrangerHelper.isIdeaSpaceFocused()

    if self.Controller:getShiftPressed() then
        -- increment bank when shift button is pressed
        if IdeaSpaceVisible then
            ArrangerHelper.setPrevNextSceneBank(Right)
        else
            ArrangerHelper.setPrevNextSectionBank(Right)
        end
    elseif not IdeaSpaceVisible then
        local Inc = Right and 1 or -1
        self.ParameterIndex = math.bound(self.ParameterIndex + Inc, 1, 4)
        self:updateParameters()
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageMikro:onShiftButton(Pressed)

    PageMikro.onShiftButton(self, Pressed)
    self:updateScreens(false)

end

------------------------------------------------------------------------------------------------------------------------

