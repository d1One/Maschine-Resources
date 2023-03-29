
require "Scripts/Maschine/Components/Pages/ClipPageBase"

require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Shared/Helpers/ColorPaletteHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ClipPageStudio = class( 'ClipPageStudio', ClipPageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:__init(ParentPage, Controller)

    ClipPageBase.__init(self, Controller, "ClipPageStudio")

    self.ParentPage = ParentPage

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"PATTERN", "CLIP", "DOUBLE", "DUPLICATE"}, {"", "DELETE", "<<", ">>"})

    -- Parameter bar
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.PatternEditor = self.Controller.SharedObjects.PatternEditorOverview

    self.ParameterHandler.NumParamsPerPage = 4
    self.ParameterHandler.NumPages = 2

    ClipPageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:onShow(Show)

    if Show then
        self.PatternEditor:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.PatternEditor.Editor:setOverviewSource(nil)
    end

    ClipPageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:updateScreens(ForceUpdate)

    -- update InfoBar
    self.Screen.ScreenLeft.InfoBar:update(ForceUpdate)

    self:updatePadColors()

    -- call base class
    ClipPageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:updatePadColors()

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    -- iterate over pad Widgets
    for PadIndex, Button in ipairs (self.Screen.PadButtons) do

        local ClipIndex = ClipHelper.getClipIndex(PadIndex)
        local ClipEvent = Group and NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, ClipIndex) or nil
        local Pattern = ClipEvent and ClipEvent:getEventPattern() or nil
        local Color = Pattern and Pattern:getColorParameter():getValue() or nil

        Button:setPaletteColorIndex(Color and Color + 1 or 0)
        Button.Label:setPaletteColorIndex(Color and Color + 1 or 0)

        Button:setInvalid(0) -- This is needed for MAS2-4712
    end

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:updateScreenButtons(ForceUpdate)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    -- Banks
    local BankIndex, NumBanks = ClipHelper.getCurrentBank()
    if Group then
        self.Screen:setArrowText(1, "BANK "..tostring(BankIndex + 1))
    else
        self.Screen:unsetArrowText(1)
    end

    -- Base
    ClipPageBase.updateScreenButtons(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:updateParameters(ForceUpdate)

    local Values = {}
    local ListValues = {}
    local ListColors = {}
    local Sections = {}
    local Names = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections = { "Clip" }
        Names = {"POSITION", "", "START", "LENGTH"}
        Values = { ClipHelper.getFocusClipStartString(),
                    nil,
                    ClipHelper.getFocusClipStartString(),
                    ClipHelper.getFocusClipLengthString() }

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections = { "Color" }
        Names = { "CLIP" }

        ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusEventPattern(App), 1, Values, ListValues, ListColors)

    end

    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    PageMaschine.updateParameters(self, ForceUpdate)

end
------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:updateLeftRightLEDs()

    LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
        self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:onScreenEncoder(Index, Value)

    if self.ParameterHandler.PageIndex == 1 then
        local ShiftPressed = self.Controller:getShiftPressed()
        ClipHelper.onClipPageScreenEncoder(Index, Value, self.TransactionSequenceMarker, ShiftPressed)

    elseif self.ParameterHandler.PageIndex == 2 then
        if MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) == 0 then
            return
        end

        if Index == 1 then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusEventPattern(App), Value > 0,
                NI.DATA.EventPatternAccess.setColor)

        end
    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:getAccessiblePageInfo()

    return "Clip"

end

------------------------------------------------------------------------------------------------------------------------

function ClipPageStudio:getAccessibleTextByPadIndex(PadIdx)

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    if not Group then
        return ""
    end

    local Index = ClipHelper.getClipIndex(PadIdx)
    local NewClip = Index == Group:getClipSequence():size()

    if NewClip then
        return "New Clip"
    else
        local ClipEvent = NI.DATA.GroupAlgorithms.getClipEventByIndex(Group, Index)
        local Pattern = ClipEvent and ClipEvent:getEventPattern() or nil
        return Pattern and Pattern:getNameParameter():getValue() or ""
    end

end

------------------------------------------------------------------------------------------------------------------------
