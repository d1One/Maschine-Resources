require "Scripts/Maschine/Helper/ObjectColorsHelper"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Shared/Helpers/ColorPaletteHelper"

local ATTR_IDEAS = NI.UTILS.Symbol("Ideas")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageStudioPattern = class( 'PatternPageStudioPattern', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- const
------------------------------------------------------------------------------------------------------------------------

PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN = 1
PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:__init(ParentPage, Controller)

    PageMaschine.__init(self, "PatternPageStudioPattern", Controller)

    -- setup screen
    self:setupScreen()

    self.TransactionSequenceMarker = TransactionSequenceMarker()
    self.ParentPage = ParentPage

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    self.ShowRename = NI.APP.isHeadless()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"PATTERN", "CLIP", "DOUBLE", "DUPLICATE"},
        {"CREATE", "DELETE", "<<", ">>"})

    -- Parameter bar
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.ArrangerOV = self.Controller.SharedObjects.PatternEditorOverview

    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN]:style("PATTERN", "HeadPinTabLeft")
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP]:style("CLIP", "HeadTabRight")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:onShow(Show)

    if Show then
        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.ArrangerOV:setOverview()

        self.TransactionSequenceMarker:reset()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updateScreens(ForceUpdate)

    -- update InfoBar
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    self.ArrangerOV:update(ForceUpdate)

    self.Screen.ScreenLeft.DisplayBar:setAttribute(ATTR_IDEAS, ArrangerHelper.isIdeaSpaceFocused() and "true" or "false")

    -- update pad buttons
    self.Screen:updatePadButtonsWithFunctor(PatternHelper.PatternStateFunctor)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

    self:updatePadColors()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updateScreenButtons(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local HasPattern = Pattern ~= nil
    local HasGroup = Group ~= nil

    -- Pin Button
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN]:setSelected(self.ParentPage.IsPinned)
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN]:setVisible(true)
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN]:setEnabled(true)

    -- Button 2 -- Pin Button (to Clip Page)
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP]:setSelected(false)
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP]:setEnabled(true)
    self.Screen.ScreenButton[PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP]:setVisible(true)

    -- Button 3 -- Double
    self.Screen.ScreenButton[3]:setEnabled(HasPattern and NI.DATA.EventPatternAccess.canDoublePattern(App, Pattern))
    self.Screen.ScreenButton[3]:setVisible(not ShiftPressed and HasGroup)

    -- Button 4 -- Duplicate
    self.Screen.ScreenButton[4]:setEnabled(HasPattern)
    self.Screen.ScreenButton[4]:setVisible(not ShiftPressed and HasGroup)

    -- Button 5 -- Create / Rename
    if ShiftPressed then

        self.Screen.ScreenButton[5]:setText("RENAME")
        self.Screen.ScreenButton[5]:setEnabled(self.ShowRename and HasPattern)
        self.Screen.ScreenButton[5]:setVisible(self.ShowRename)

    else

        self.Screen.ScreenButton[5]:setText("CREATE")
        self.Screen.ScreenButton[5]:setEnabled(HasGroup)
        self.Screen.ScreenButton[5]:setVisible(true)

    end

    -- Button 6 -- Delete / Delete Bank
    if ShiftPressed then

        self.Screen.ScreenButton[6]:setText("DEL BANK")
        self.Screen.ScreenButton[6]:setEnabled(Group and (not Group:getPatterns():empty()) or false)

    else

        self.Screen.ScreenButton[6]:setText("DELETE")
        self.Screen.ScreenButton[6]:setEnabled(HasPattern)

    end

    if ShiftPressed then

        local HasPrev = HasGroup and NI.DATA.GroupAccess.canShiftFocusedPattern(Group, false) or false
        local HasNext = HasGroup and NI.DATA.GroupAccess.canShiftFocusedPattern(Group, true) or false
        self.Screen:setArrowText(1, "MOVE")

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    else

        local HasPrev, HasNext = PatternHelper.hasPrevNextPatternBanks()
        local CanAdd = PatternHelper.canAddPatternBank()

        local PatternBankIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() or 0
        if Group then
            self.Screen:setArrowText(1, "BANK "..tostring(PatternBankIndex + 1))
        else
            self.Screen:unsetArrowText(1)
        end

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext or CanAdd)

        self.Screen.ScreenButton[8]:setText(CanAdd and "+" or ">>")

    end

    self.Screen.ScreenButton[7]:setVisible(true)
    self.Screen.ScreenButton[8]:setVisible(true)

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

    -- update left/right LEDs
    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updateParameters(ForceUpdate)

    local Values = {}
    local ListValues = {}
    local ListColors = {}
    local Sections = {}
    local Names = {}

    self.ParameterHandler.NumParamsPerPage = 4
    self.ParameterHandler.NumPages = 2

    if self.ParameterHandler.PageIndex == 1 then

        Sections = { "Pattern" }
        Names = { "POSITION", "", "START", "LENGTH" }
        Values = { PatternHelper.startString(), nil, PatternHelper.startString(), PatternHelper.lengthString() }

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections = { "Color" }
        Names = { "PATTERN" }

        ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusEventPattern(App), 1, Values, ListValues, ListColors)

    end

    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updatePadLEDs()

    PatternHelper.updatePadLEDs(self.Controller.PAD_LEDS)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updatePadColors()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local BankIndex = Group and Group:getFocusPatternBankIndexParameter():getValue() or 0

    -- iterate over pad Widgets
    for Index, Button in ipairs (self.Screen.PadButtons) do

        ColorPaletteHelper.setPatternColor(Button, 16 * BankIndex + Index)
        ColorPaletteHelper.setPatternColor(Button.Label, 16 * BankIndex + Index)
        Button:setInvalid(0) -- This is needed for MAS2-4712

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:updateLeftRightLEDs()

    LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
        self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:onPadEvent(PadIndex, Trigger)

    PatternHelper.onPatternPagePadEvent(PadIndex, Trigger, self.Controller:getErasePressed())
    self:updateLeftRightLEDs()

    return true --handled

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:onScreenButton(Index, Pressed)

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local ShiftPressed = self.Controller:getShiftPressed()
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_PATTERN then

        self.ParentPage:togglePinState()

    elseif ShouldHandle and Index == PatternPageStudioPattern.SCREEN_PIN_TAB_BUTTON_CLIP then

        -- switch to the Clip Page (needs a song focus entity toggle and maybe a switch to Song View as well)
        NI.DATA.ArrangerAccess.toggleSongFocusEntity(App)
        if ArrangerHelper.isIdeaSpaceFocused() then
            ArrangerHelper.toggleIdeasView()
        end
        -- update the parent page so the screen change takes in effect immediately
        self.ParentPage:updateScreens()

    elseif ShouldHandle and Index == 3 and not ShiftPressed and Pattern then

        NI.DATA.EventPatternAccess.doublePattern(App, Pattern)

    elseif ShouldHandle and Index == 4 and not ShiftPressed then

        PatternHelper.duplicatePattern()

    elseif ShouldHandle and Index == 5 and Group then

        if ShiftPressed and self.ShowRename and Pattern then

            local NameParam = Pattern:getNameParameter()
            MaschineHelper.openRenameDialog(NameParam:getValue(), Pattern:getNameParameter())

        elseif not ShiftPressed then

            NI.DATA.GroupAccess.insertPattern(App, Group, NI.DATA.StateHelper.getFocusEventPattern(App))

        end

    elseif ShouldHandle and Index == 6 then

        PatternHelper.deletePatternOrBank(ShiftPressed)

    elseif ShouldHandle and (Index == 7 or Index == 8) then

        if ShiftPressed and Group then

            self.TransactionSequenceMarker:set()
            NI.DATA.GroupAccess.shiftFocusedPattern(App, Group, Index == 8)

        else

            PatternHelper.setPrevNextPatternBank(Index == 8)

        end

    end

    self:updateLeftRightLEDs()

    -- call base class for update
    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:onScreenEncoder(Index, Value)

    local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1)
    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local ShiftPressed = self.Controller:getShiftPressed()

    if EncoderSmoothed == 0 then
        return
    end

    local Next = Value > 0

    if self.ParameterHandler.PageIndex == 1 and Pattern then

        local Increment = Next and 1 or -1

        if Index == 1 then

            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementPosition(App, Pattern, Increment, ShiftPressed)

        elseif Index == 3 then

            self.TransactionSequenceMarker:set()
            NI.DATA.EventPatternAccess.incrementStart(App, Pattern, Increment, ShiftPressed)

        elseif Index == 4 then

            self.TransactionSequenceMarker:set()

            local Quick = GridHelper.isQuickEnabled()
            NI.DATA.EventPatternAccess.incrementExplicitLength(App, Pattern, Increment, ShiftPressed, Quick)
        end

    end

    if self.ParameterHandler.PageIndex == 2 then


        if Index == 1 then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusEventPattern(App), Next,
                NI.DATA.EventPatternAccess.setColor)

        end

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:getAccessiblePageInfo()

    return "Pattern"

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageStudioPattern:getAccessibleTextByPadIndex(PadIdx)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if not Group then
        return ""
    end

    local BankIndex = Group:getFocusPatternBankIndexParameter():getValue()
    local Index = BankIndex * 16 + PadIdx - 1
    local Pattern = Group:getPatterns():find(Index)
    
    if Pattern then
        local PatternName = Pattern:getNameParameter():getValue()
        local HasFocus = (Pattern == NI.DATA.StateHelper.getFocusEventPattern(App))
        return HasFocus and ("Unselect "..PatternName) or PatternName
    else
        return "New Pattern"
    end

end

------------------------------------------------------------------------------------------------------------------------
