------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ChordsModePageMK3 = class( 'ChordsModePageMK3', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:__init(Controller)

    PageMaschine.__init(self, "ChordsModePageMK3", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:setPinned(PinState)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:setupScreen()

    self.Screen = ScreenWithGridStudio(self, { "CHORDS", "PADS ON", "", "" },
        { "OCTAVE-", "OCTAVE+", "SEMITONE-", "SEMITONE+" })

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)
    self.Screen.ScreenButton[1]:setSelected(true)

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:onShow(Show)

    if Show then
        self.Screen.ScreenLeft.InfoBar:setMode("PadScreenMode")
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:updateScreens(ForceUpdate)

    -- update on-screen pad colors
    PadModeHelper.updatePadColorsStudio(self.Screen)
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return PadModeHelper.getScreenPadButtonState(Index, NI.HW.PAD_MODE_KEYBOARD)
        end)

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:updateParameters(ForceUpdate)

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

    local Names = {}
    local Parameters = {}
    local Sections = {}
    local Values = {}

    local ScaleEngine = NI.DATA.getScaleEngine(App)

    if self.ParameterHandler.PageIndex == 1 then

        local IsChordSetActive = ScaleEngine and ScaleEngine:getChordModeIsChordSet()

        if not IsChordSetActive then

            Sections[1] = "Scale"
            Parameters[1] = ScaleEngine and ScaleEngine:getScaleBankParameter()
            Parameters[2] = ScaleEngine and ScaleEngine:getScaleParameter()

        end

        Sections[3] = "Chord"
        Parameters[3] = ScaleEngine and ScaleEngine:getChordScreenChordModeParameter()
        Parameters[4] = ScaleEngine and ScaleEngine:getCurrentChordTypeParameter()

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections[1] = "Chord"
        Parameters[1] = ScaleEngine and ScaleEngine:getChordPositionParameter()

        Sections[2] = "Fixed Velocity"
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Parameters[2] = Song and Song:getFixedVelocityParameter()

    end

    self.ParameterHandler:setParameters(Parameters)
    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignParametersToCaps(self.ParameterHandler.Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:updateScreenButtons(ForceUpdate)

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

function ChordsModePageMK3:onScreenButton(Index, Pressed)

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

function ChordsModePageMK3:updatePadLEDs()

    if PadModeHelper.isChordModeChordSet() and PadModeHelper.isTouchstripModeNotes() then

        local FlashStateFunctor = function(Index)
            return NHLController:getContext():isPadStrummed(Index - 1)
        end

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local ColorIndex = Sound and Sound:getColorParameter():getValue() or LEDColors.WHITE
        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
                                        PadModeHelper.getKeyboardModePadStates,
                                        function() return ColorIndex end,
                                        FlashStateFunctor)
    else

        PageMaschine.updatePadLEDs(self)

    end

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:getAccessiblePageInfo()

    return "Chords Mode Page"

end

------------------------------------------------------------------------------------------------------------------------

function ChordsModePageMK3:getAccessibleTextByButtonIndex(ButtonIdx)

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
