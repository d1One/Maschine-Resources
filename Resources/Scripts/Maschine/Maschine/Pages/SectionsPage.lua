------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Maschine/Maschine/Screens/SceneBackground"
require "Scripts/Maschine/Maschine/Screens/SceneHeader"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/ScreenHelper"
require "Scripts/Shared/Pages/PageMaschine"

local ATTR_HAS_ARROW = NI.UTILS.Symbol("HasArrow")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SectionsPage = class( 'SectionsPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SectionsPage:__init(ParentPage, Controller)

    PageMaschine.__init(self, "SectionsPage", Controller)

    self.TransactionSequenceMarker = TransactionSequenceMarker()
    self.ArrangerMode = false
    self.ParamPageIdx = 1

    self:setupScreen()

    self.ParentPage = ParentPage

    self.PageLEDs = { NI.HW.LED_SCENE }

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:setupScreen()

    self.Screen = ScreenMaschine(self)

    self.Screen:styleScreenWithParameters(self.Screen.ScreenLeft, {"SECTION", "TIMELINE", "AUTO LEN", "DUPL"}, "HeadButton", true)

    self.Screen:addScreenButtonBar(self.Screen.ScreenRight, {"CREATE", "DELETE", "<", ">"}, "HeadButton")

    self.Screen.ScreenButton[1]:style("SECTION", "HeadPin")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

    self.Screen.InfoBarRight = InfoBar(self.Controller, self.Screen.ScreenRight, "FocusedSongMode")

    self.SceneHeader = SceneHeader()
    self.SceneHeader:setup(self.Screen.ScreenRight)

    self.SceneBackground = SceneBackground()
    self.SceneBackground:setup(self.Screen.ScreenRight)
    self.SceneHeader:setSceneBackgroundWidget(self.SceneBackground)

    self.PadButtons = {}
    self.Grid = ScreenHelper.createBarWith16Buttons(self.Screen.ScreenRight, self.PadButtons,
                {"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""}, "Pad")

    for i, Button in ipairs(self.PadButtons) do
            Button:style("", "Pad")
    end

    MaschineHelper.resetScreenEncoderSmoother()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:updateScreens(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    ForceUpdate = ForceUpdate or (Song and Song:getFocusSectionBankIndexParameter():isChanged())

    self.Screen.InfoBarRight:setActive(self.ArrangerMode)
    self.SceneHeader:setActive(self.ArrangerMode)
    self.SceneBackground:setActive(self.ArrangerMode)
    self.Grid:setActive(not self.ArrangerMode)

    self.Screen.InfoBarRight:update(ForceUpdate)
    self.SceneHeader:update(ForceUpdate)

    ScreenHelper.updateButtonsWithFunctor(self.PadButtons,
        function (Index) return ArrangerHelper.SectionStateFunctor(Index, true) end)

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:updateScreenButtons(ForceUpdate)

    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Section = NI.DATA.StateHelper.getFocusSection(App)
    local ShiftPressed = self.Controller:getShiftPressed()

    self.Screen.ScreenButton[2]:setEnabled(ShiftPressed
                                           or (Section ~= nil and Song ~= nil
                                               and not NI.DATA.SongAlgorithms.isSectionUnique(Song, Section)))
    self.Screen.ScreenButton[2]:setSelected(ShiftPressed and self.ArrangerMode)
    self.Screen.ScreenButton[2]:setText(ShiftPressed and "TIMELINE" or "UNIQUE")

    self.Screen.ScreenButton[3]:setEnabled(Section ~= nil and not Section:getAutoLengthParameter():getValue())
    self.Screen.ScreenButton[4]:setEnabled(Section ~= nil)
    self.Screen.ScreenButton[6]:setEnabled(Section ~= nil)
    self.Screen.ScreenButton[6]:setText(ArrangerHelper.deleteSectionButtonText(self.Controller:getShiftPressed()))

    local HasPrev, HasNext = ArrangerHelper.hasPrevNextSectionBanks()
    self.Screen.ScreenButton[7]:setEnabled(HasPrev)
    self.Screen.ScreenButton[8]:setEnabled(HasNext or ArrangerHelper.canAddSectionBank())
    self.Screen.ScreenButton[8]:setText(ArrangerHelper.canAddSectionBank() and "+" or ">")
    self.Screen.ScreenButton[8]:setAttribute(ATTR_HAS_ARROW, ArrangerHelper.canAddSectionBank() and "false" or "true")

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:updateParameters(ForceUpdate)

    self.ParameterHandler.Parameters = {}

    local Sections = {}
    local Names = {}
    local Values = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections[1] = "Section"

        Names[1] = "POSITION"
        Values[1] = ArrangerHelper.getFocusedSectionSongPosAsString()

        Names[2] = "SCENE"
        Values[2] = ArrangerHelper.getSceneReferenceParameterValue()

        Names[4] = "LENGTH"
        Values[4] = ArrangerHelper.getFocusSectionLengthString()

    else -- second page

        Sections[1] = "Perform"

        Names[1] = "RETRIGGER"
        Values[1] = ArrangerHelper.getSectionRetrigValueString()

    end

    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    PageMaschine.updateParameters(self, ForceUpdate)

    -- During Arrange Mode we hide the parameter page number
    if self.ArrangerMode then
        self.ParameterHandler.SectionWidgets[4]:setText("")
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onShow(Show)

    -- call base
    PageMaschine.onShow(self, Show)

    if Show then
        self.TransactionSequenceMarker:reset()
        self.SceneHeader:onShow()
        self.Controller:setTimer(self, 1)
        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    else
        ArrangerHelper.resetHoldingPads()
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onTimer()

    if self.ArrangerMode then
        self.SceneHeader:onTimer()
    end

    -- re-set timer while page is shown
    local ActivePageID = self.Controller.PageManager:getPageID(self.Controller.ActivePage)
    local OwnPageID = self.Controller.PageManager:getPageID(self.ParentPage)

    if ActivePageID == OwnPageID then
        self.Controller:setTimer(self, 1)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:updateLeftRightButtonLEDs()

    if self.ArrangerMode then
        local LEDStateRight = LEDHelper.LS_OFF
        local LEDStateLeft = LEDHelper.LS_OFF

        local HasNextEvent = ArrangerHelper.hasPrevNextSection(true)
        local HasPrevEvent = ArrangerHelper.hasPrevNextSection(false)

        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_LEFT, NI.HW.BUTTON_LEFT, HasPrevEvent)
        LEDHelper.updateButtonLED(self.Controller, NI.HW.LED_RIGHT, NI.HW.BUTTON_RIGHT, HasNextEvent)
    else
        LEDHelper.updateLeftRightLEDsWithParameters(self.Controller, 2, self.ParameterHandler.PageIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onScreenButton(Idx, Pressed)

    if Pressed then
        if Idx == 1 then
            self.ParentPage:togglePinState()

        elseif Idx == 2 then
            if self.Controller:getShiftPressed() then
                self.ArrangerMode = not self.ArrangerMode
                self.ParameterHandler.PageIndex = 1
            else
                ArrangerHelper.makeSectionSceneUnique()
            end

        elseif Idx == 3 then
            ArrangerHelper.setFocusSectionAutoLength()

        elseif Idx == 4 then
            ArrangerHelper.duplicateSection()

        elseif Idx == 5 then
            ArrangerHelper.insertSectionAfterFocused()

        elseif Idx == 6 then
            ArrangerHelper.removeFocusedSectionOrBank(self.Controller:getShiftPressed())

        elseif Idx == 7 or Idx == 8 then
            ArrangerHelper.setPrevNextSectionBank(Idx == 8)

        end
    end

    -- call base class for update
    PageMaschine.onScreenButton(self, Idx, Pressed)

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onScreenEncoder(Idx, Inc)

    if Idx == 1 then

        if self.ParameterHandler.PageIndex == 1 then
            if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                self.TransactionSequenceMarker:set()
                NI.DATA.SongAccess.swapFocusedSection(App, Inc > 0)
            end
        else
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            if Song then
                NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Song:getPerformRetrigParameter(), Inc, false, false)
            end
        end

    elseif Idx == 2 then

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            ArrangerHelper.shiftSceneOfFocusSection(Inc)
        end

    elseif Idx == 4 and self.ParameterHandler.PageIndex == 1 then

        if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
            self.TransactionSequenceMarker:set()
            ArrangerHelper.incrementFocusSectionLength(Inc, self.Controller:getShiftPressed())
        end

    elseif Idx == 5 and self.ArrangerMode then

        self.SceneHeader:onZoom(Inc)

    elseif Idx == 6 and self.ArrangerMode then

        self.SceneHeader:onScroll(Inc)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onPadEvent(PadIndex, Pressed, PadValue)

    ArrangerHelper.onPadEventSections(PadIndex, Pressed, self.Controller:getErasePressed(), true)

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onLeftRightButton(Right, Pressed)

    if Pressed then
        if self.ArrangerMode then
            ArrangerHelper.focusPrevNextSection(Right)
        else
            self.ParameterHandler:onPrevNextParameterPage(Right and 1 or -1)
            self:updateScreens(true)
        end
    end

    self:updateLeftRightButtonLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onVolumeEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onTempoEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onSwingEncoder(EncoderInc)

    -- disable sound QE
    if self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPage:onWheel()

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------
