------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KeyboardModePageMK3 = class( 'KeyboardModePageMK3', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:__init(Controller)

    PageMaschine.__init(self, "KeyboardModePageMK3", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:setPinned(PinState)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:setupScreen()

    self.Screen = ScreenWithGridStudio(self, { "KEYBOARD", "PADS ON", "", "" },
        { "OCTAVE-", "OCTAVE+", "SEMITONE-", "SEMITONE+" })

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)
    self.Screen.ScreenButton[1]:setSelected(true)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:onShow(Show)

    if Show then
        self.Screen.ScreenLeft.InfoBar:setMode("PadScreenMode")
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:updateScreens(ForceUpdate)

    -- update on-screen pad colors
    PadModeHelper.updatePadColorsStudio(self.Screen)
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return PadModeHelper.getScreenPadButtonState(Index, NI.HW.PAD_MODE_KEYBOARD)
        end)

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:updateParameters(ForceUpdate)

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

    local Names = {}
    local Parameters = {}
    local Sections = {}
    local Values = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections[1] = "Scale"

        local ScaleEngine = NI.DATA.getScaleEngine(App)
        Parameters[1] = ScaleEngine and ScaleEngine:getScaleBankParameter()
        Parameters[2] = ScaleEngine and ScaleEngine:getScaleParameter()

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections[1] = "Fixed Velocity"

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Parameters[1] = Song and Song:getFixedVelocityParameter()

    end

    self.ParameterHandler:setParameters(Parameters)
    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignParametersToCaps(self.ParameterHandler.Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:updateScreenButtons(ForceUpdate)

    local IsNotesMode = PadModeHelper.isTouchstripModeNotes()
    local PadsEnabled = App:getWorkspace():getPlayPadsInNotesModeEnabledParameter():getValue()
    self.Screen.ScreenButton[2]:setEnabled(IsNotesMode)
    self.Screen.ScreenButton[2]:setVisible(IsNotesMode)
    self.Screen.ScreenButton[2]:setSelected(IsNotesMode and PadsEnabled)

    self.Screen.ScreenButton[5]:setEnabled(PadModeHelper.canTransposeRootNote(-12))
    self.Screen.ScreenButton[6]:setEnabled(PadModeHelper.canTransposeRootNote(12))
    self.Screen.ScreenButton[7]:setEnabled(PadModeHelper.canTransposeRootNote(-1))
    self.Screen.ScreenButton[8]:setEnabled(PadModeHelper.canTransposeRootNote(1))

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:onScreenButton(Index, Pressed)

    local IsNotesMode = PadModeHelper.isTouchstripModeNotes()
    local Transpose = 0

    if Pressed and Index == 2 and IsNotesMode then

        MK3Helper.togglePlayPadsInNotesModeParameter()

    elseif Pressed and Index == 5 then

        PadModeHelper.transposeRootNoteOrBaseKey(-12, self.Controller)

    elseif Pressed and Index == 6 then

        PadModeHelper.transposeRootNoteOrBaseKey(12, self.Controller)

    elseif Pressed and Index == 7 then

        PadModeHelper.transposeRootNoteOrBaseKey(-1, self.Controller)

    elseif Pressed and Index == 8 then

        PadModeHelper.transposeRootNoteOrBaseKey(1, self.Controller)

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:getAccessiblePageInfo()

    return "Keyboard Mode Page"

end

------------------------------------------------------------------------------------------------------------------------

function KeyboardModePageMK3:getAccessibleTextByButtonIndex(ButtonIdx)

    if ButtonIdx == 5 then
        return "Octave minus"
    elseif ButtonIdx == 6 then
        return "Octave plus"
    elseif ButtonIdx == 7 then
        return "Semitone minus"
    elseif ButtonIdx == 8 then
        return "Semitone plus"
    end
    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------
