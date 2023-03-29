------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/ObjectColorsHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ScenePageStudio = class( 'ScenePageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:__init(ParentPage, Controller)

    PageMaschine.__init(self, "ScenePageStudio", Controller)

    self:setupScreen()

    self.AppendMode = false
    self.PageLEDs = { NI.HW.LED_SCENE }
    self.ParentPage = ParentPage

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    self.ShowRename = NI.APP.isHeadless()

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"SCENE", "UNIQUE", "APPEND", "DUPLICATE"},
        {"CREATE", "DELETE", "<<", ">>"}, "HeadButton", "HeadButton")

    self.ArrangerOV = self.Controller.SharedObjects.ArrangerOverview

    -- Parameter bar
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    self.Screen.ScreenButton[1]:style("SCENE", "HeadPin")
    self.Screen.ScreenButton[7]:style("<", "ScreenButton")
    self.Screen.ScreenButton[8]:style(">", "ScreenButton")

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:updateScreens(ForceUpdate)

    -- Show timeline if in append mode
    self.ArrangerOV:setVisible(self.AppendMode)
    self.ArrangerOV:update(ForceUpdate)

    -- Hide parameters in append mode
    self.ParameterHandler.SectionWidgets[1]:setVisible(not self.AppendMode)
    self.Screen.ParameterWidgets[1]:setVisible(not self.AppendMode)

    self.Screen:updatePadButtonsWithFunctor(
        function (Index) return ArrangerHelper.SceneStateFunctor(Index, not self.AppendMode, self.AppendMode) end)

    self:updatePadColors()

    -- call base
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:updateParameters(ForceUpdate)

    local Sections = {}
    local Names = {}
    local Values = {}
    local ListValues = {}
    local ListColors = {}

    self.ParameterHandler.NumParamsPerPage = 4

    if not self.AppendMode then

        Sections[1] = "Color"
        Names[1] = "SCENE"
        ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusScene(App), 1, Values, ListValues, ListColors)

        Sections[2] = "Perform"
        Names[2] = "RETRIGGER"
        Values[2] = ArrangerHelper.getSectionRetrigValueString()

    end

    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)
    self.Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:updateScreenButtons(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = NI.DATA.StateHelper.getFocusScene(App)
    local SceneBankIndex = Song and Song:getFocusSceneBankIndexParameter():getValue() or 0
    local HasSong = Song ~= nil
    local HasScene = Scene ~= nil
    local ShiftPressed = self.Controller:getShiftPressed()

    -- Pin Button
    self.Screen.ScreenButton[1]:setSelected(self.ParentPage.IsPinned)

    -- Button 2 -- Remove
    self.Screen.ScreenButton[2]:setEnabled(HasScene and not NI.DATA.IdeaSpaceAlgorithms.isSceneUnique(Song, Scene))
    self.Screen.ScreenButton[2]:setVisible(not ShiftPressed and not self.AppendMode)

    -- Button 3 -- Append
    self.Screen.ScreenButton[3]:setVisible(not ShiftPressed)
    self.Screen.ScreenButton[3]:setSelected(self.AppendMode)

    -- Button 4 -- Duplicate
    self.Screen.ScreenButton[4]:setEnabled(HasScene)
    self.Screen.ScreenButton[4]:setVisible(not ShiftPressed and not self.AppendMode and HasSong)

    -- Button 5 -- Create / Rename
    if ShiftPressed then

        self.Screen.ScreenButton[5]:setText("RENAME")
        self.Screen.ScreenButton[5]:setEnabled(self.ShowRename and HasScene)
        self.Screen.ScreenButton[5]:setVisible(self.ShowRename)

    else

        self.Screen.ScreenButton[5]:setText("CREATE")
        self.Screen.ScreenButton[5]:setEnabled(not self.AppendMode and HasSong)
        self.Screen.ScreenButton[5]:setVisible(true)

    end

    -- Button 6 -- Delete
    if ShiftPressed then

        self.Screen.ScreenButton[6]:setText("DEL BANK")

    else

        self.Screen.ScreenButton[6]:setText("DELETE")

    end

    self.Screen.ScreenButton[6]:setEnabled(HasScene)
    self.Screen.ScreenButton[6]:setVisible(not self.AppendMode)

    -- Button 7 & 8 -- Change bank / Move scene
    if ShiftPressed then

        local HasPrev, HasNext = ArrangerHelper.hasPrevNextScene()
        self.Screen:setArrowText(1, "MOVE")

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    else

        local HasPrev, HasNext = ArrangerHelper.hasPrevNextSceneBanks()
        local BankNumberText = Song and "BANK "..tostring(SceneBankIndex + 1) or ""

        self.Screen:setArrowText(1, BankNumberText)

        self.Screen.ScreenButton[7]:setEnabled(HasPrev)
        self.Screen.ScreenButton[8]:setEnabled(HasNext)

    end

    -- call base
    PageMaschine.updateScreenButtons(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:updatePadLEDs()

    ArrangerHelper.updatePadLEDsIdeaSpace(self.Controller, self.AppendMode)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:updatePadColors()

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local BankIndex = Song and Song:getFocusSceneBankIndexParameter():getValue() or 0

    -- iterate over pad Widgets
    for Index, Button in ipairs (self.Screen.PadButtons) do
        ColorPaletteHelper.setSceneColor(Button, 16 * BankIndex + Index, true)
        ColorPaletteHelper.setSceneColor(Button.Label, 16 * BankIndex + Index, true)
        Button:setInvalid(0) -- This is needed for MAS2-4712
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:onShow(Show)

    ArrangerHelper.setAppendMode(self, false)

    if Show then

        self.ArrangerOV:insertInto(self.Screen.ScreenLeft.DisplayBar, true)
        self.ArrangerOV.Arranger:resetViewport()
        NHLController:setPadMode(NI.HW.PAD_MODE_SCENE)

    else

        NHLController:setPadMode(NI.HW.PAD_MODE_PAGE_DEFAULT)

    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:onScreenEncoder(Index, Value)

    if Index == 1 and not self.AppendMode then

        local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
        local Next = Value > 0

        if EncoderSmoothed then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusScene(App), Next,
                NI.DATA.SceneAccess.setSceneColor)

        end

    elseif Index == 2 and not self.AppendMode then

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song then
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Song:getPerformRetrigParameter(), Value, false, false)
        end

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:isSoundQEAllowed()

    return false

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:onScreenButton(Index, Pressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Scene = NI.DATA.StateHelper.getFocusScene(App)
    local ShiftPressed = self.Controller:getShiftPressed()
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == 1 then

        self.ParentPage:togglePinState()

    elseif ShouldHandle and Index == 2 and not ShiftPressed and Song and Scene and not self.AppendMode then

        NI.DATA.IdeaSpaceAccess.makeSceneUnique(App, Song, Scene)

    elseif ShouldHandle and Index == 3 and not ShiftPressed then

        ArrangerHelper.setAppendMode(self, not self.AppendMode)

    elseif ShouldHandle and Index == 4 and not ShiftPressed and Song and Scene and not self.AppendMode then

        NI.DATA.IdeaSpaceAccess.duplicateScene(App, Song, Scene)

    elseif ShouldHandle and Index == 5 and Song and not self.AppendMode then

        if ShiftPressed and self.ShowRename and Scene then

            local NameParam = Scene:getNameParameter()
            MaschineHelper.openRenameDialog(NameParam:getValue(), NameParam)

        elseif not ShiftPressed then

            NI.DATA.IdeaSpaceAccess.insertSceneAfterFocusScene(App, Song)

        end

    elseif ShouldHandle and Index == 6 and not self.AppendMode then

        ArrangerHelper.removeFocusedSceneOrBank(ShiftPressed)

    elseif ShouldHandle and (Index == 7 or Index == 8) then

        local Forward = Index == 8

        if ShiftPressed and Song then

            NI.DATA.IdeaSpaceAccess.shiftFocusedScene(App, Song, Forward)

        else

            ArrangerHelper.setPrevNextSceneBank(Index == 8)

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:onPadEvent(PadIndex, Pressed, PadValue)

    ArrangerHelper.onPadEventIdeas(
        PadIndex, Pressed, self.Controller:getErasePressed(), not self.AppendMode, self.AppendMode)

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:onWheel()

    if NHLController:getJogWheelMode() ~= NI.HW.JOGWHEEL_MODE_DEFAULT and
        self.Controller.QuickEdit.NumPadPressed > 0 then
        return true
    end

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:getAccessiblePageInfo()

    return "Scene"

end

------------------------------------------------------------------------------------------------------------------------

function ScenePageStudio:getAccessibleTextByPadIndex(PadIdx)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    if not Song then
        return ""
    end

    local Index = ArrangerHelper.getSceneIndexFromPadIndex(PadIdx)
    local NewScene = Index == Song:getScenes():size()

    if NewScene then
        return "New Scene"
    else
        local Scene = Song:getScenes():at(Index)
        return Scene and Scene:getNameParameter():getValue() or ""
    end

end

------------------------------------------------------------------------------------------------------------------------
