------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/TransactionSequenceMarker"
require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/ArrangerHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SectionsPageStudio = class( 'SectionsPageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:__init(ParentPage, Controller)

    PageMaschine.__init(self, "SectionsPageStudio", Controller)

    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()

    self.ParentPage = ParentPage

    self.PageLEDs = { NI.HW.LED_SCENE }

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"SECTION", "UNIQUE", "AUTO LENGTH", "DUPLICATE"},
        {"CREATE", "DELETE", "<<", ">>"})
    self.Screen.ScreenButton[1]:style("SECTION", "HeadPin");

    self.ArrangerOV = self.Controller.SharedObjects.ArrangerOverview

    -- Setup Parameters

    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:updateScreens(ForceUpdate)

    -- update InfoBar
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    self.ArrangerOV:update(ForceUpdate)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updatePadColors()

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:updateParameters(ForceUpdate)

    local Sections = {}
    local Names = {}
    local Values = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections[1] = "Section"

        Names[1] = "POSITION"
        Values[1] = ArrangerHelper.getFocusedSectionSongPosAsString()

        Names[2] = "SCENE"
        Values[2] = ArrangerHelper.getSceneReferenceParameterValue()
        ArrangerHelper.updateSceneReferenceCapacitiveListAndFocus(self.Controller, 2)

        Names[4] = "LENGTH"
        Values[4] = ArrangerHelper.getFocusSectionLengthString()
    else

        Sections[1] = "Perform"
        Names[1] = "RETRIGGER"
        Values[1] = ArrangerHelper.getSectionRetrigValueString()
    end

    self.ParameterHandler:setCustomSections(Sections)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomValues(Values)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:updateScreenButtons(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local HasSong = Song ~= nil

    local Section = NI.DATA.StateHelper.getFocusSection(App)
    local HasSection = Section ~= nil

    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)
    self.Screen.ScreenButton[1]:setVisible(true)
    self.Screen.ScreenButton[1]:setEnabled(true)

    -- Button 2 -- UNIQUE
    self.Screen.ScreenButton[2]:setEnabled(HasSection and HasSong and not NI.DATA.SongAlgorithms.isSectionUnique(Song, Section))
    self.Screen.ScreenButton[2]:setVisible(not ShiftPressed)

    -- Button 3 -- Auto Length
    self.Screen.ScreenButton[3]:setEnabled(HasSection and not Section:getAutoLengthParameter():getValue())
    self.Screen.ScreenButton[3]:setVisible(not ShiftPressed)

    -- Button 4 -- Duplicate
    self.Screen.ScreenButton[4]:setEnabled(HasSection)
    self.Screen.ScreenButton[4]:setVisible(not ShiftPressed)

    -- Button 5 -- Insert
    self.Screen.ScreenButton[5]:setEnabled(HasSong)
    self.Screen.ScreenButton[5]:setVisible(not ShiftPressed)

    -- Button 6 -- Delete
    self.Screen.ScreenButton[6]:setText(ArrangerHelper.deleteSectionButtonText(ShiftPressed))
    self.Screen.ScreenButton[6]:setEnabled(HasSection)
    self.Screen.ScreenButton[6]:setVisible(not ShiftPressed)

    -- Button 7 & 8 -- Change bank / Move section
    if ShiftPressed then

        local HasPrev = HasSong and NI.DATA.SongAccess.canShiftFocusedSection(Song, false) or false
        local HasNext = HasSong and NI.DATA.SongAccess.canShiftFocusedSection(Song, true) or false
        self.Screen:setArrowText(1, "MOVE")

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    else

        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSectionBanks()
        local CanAdd = ArrangerHelper.canAddSectionBank()

        local SectionBankIndex = Song and Song:getFocusSectionBankIndexParameter():getValue() or 0
        if Song then
            self.Screen:setArrowText(1, "BANK "..tostring(SectionBankIndex + 1))
        else
            self.Screen:unsetArrowText(1)
        end

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext or CanAdd)

        self.Screen.ScreenButton[8]:setText(CanAdd and "+" or ">>")

    end


    -- Call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

    -- update pad buttons
    self.Screen:updatePadButtonsWithFunctor(function (Index) return ArrangerHelper.SectionStateFunctor(Index, true) end)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:updatePadColors()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local BankIndex = Song and Song:getFocusSectionBankIndexParameter():getValue() or 0

	-- iterate over pad Widgets
    for Index, Button in ipairs (self.Screen.PadButtons) do
        ColorPaletteHelper.setSectionColor(Button, 16 * BankIndex + Index)
        ColorPaletteHelper.setSectionColor(Button.Label, 16 * BankIndex + Index)
        Button:setInvalid(0) -- This is needed for MAS2-4712
    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:updatePadLEDs()

    ArrangerHelper.updatePadLEDsSections(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:onPadEvent(PadIndex, Trigger)

    ArrangerHelper.onPadEventSections(PadIndex, Trigger, self.Controller:getErasePressed(), true)
    return true

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:onScreenButton(Index, Pressed)

    local ShiftPressed = self.Controller:getShiftPressed()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == 1 then

        self.ParentPage:togglePinState()

    elseif ShouldHandle and Index == 2 and not ShiftPressed then

        ArrangerHelper.makeSectionSceneUnique()

    elseif ShouldHandle and Index == 3 and not ShiftPressed then

        ArrangerHelper.setFocusSectionAutoLength()

    elseif ShouldHandle and Index == 4 and not ShiftPressed then

        ArrangerHelper.duplicateSection()

    elseif ShouldHandle and Index == 5 and not ShiftPressed then

        ArrangerHelper.insertSectionAfterFocused()

    elseif ShouldHandle and Index == 6 and not ShiftPressed then

        ArrangerHelper.removeFocusedSectionOrBank(self.Controller:getShiftPressed())

    elseif ShouldHandle and (Index == 7 or Index == 8) then

        if ShiftPressed and Song then

            self.TransactionSequenceMarker:set()
            NI.DATA.SongAccess.shiftFocusedSection(App, Song, Index == 8)

        else

            ArrangerHelper.setPrevNextSectionBank(Index == 8)

        end

    end

    -- Call base
    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:onScreenEncoder(Idx, Inc)

    if self.ParameterHandler.PageIndex == 1 then

        if Idx == 1 then

            if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                self.TransactionSequenceMarker:set()
                NI.DATA.SongAccess.swapFocusedSection(App, Inc > 0)
            end

        elseif Idx == 2 then

            if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                ArrangerHelper.shiftSceneOfFocusSection(Inc)
            end

        elseif Idx == 4 then

            if MaschineHelper.onScreenEncoderSmoother(Idx, Inc, .1) ~= 0 then
                ArrangerHelper.incrementFocusSectionLength(Inc, self.Controller:getShiftPressed())
            end

        end

    else

        if Idx == 1 then

            local Song = NI.DATA.StateHelper.getFocusSong(App)
            if Song then
                NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Song:getPerformRetrigParameter(), Inc, false, false)
            end

        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:onShow(Show)


    if Show then
        self.TransactionSequenceMarker:reset()

    	self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
    	self.ArrangerOV.Arranger:resetViewport()
        self.ArrangerOV:setVisible(true)

        NHLController:setPadMode(NI.HW.PAD_MODE_SECTION)
    else
        ArrangerHelper.resetHoldingPads()
        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:onWheelButton(Pressed)
	-- handled: no QE
    return true
end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:getAccessiblePageInfo()

    return "Section"

end

------------------------------------------------------------------------------------------------------------------------

function SectionsPageStudio:getAccessibleTextByPadIndex(PadIdx)

    local AllowCreatingSections = true
    return ArrangerHelper.getAccessibleSectionNameByPadIndex(PadIdx, AllowCreatingSections)

end

------------------------------------------------------------------------------------------------------------------------
