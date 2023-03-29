------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/PadModePageBase"
require "Scripts/Maschine/Helper/ObjectColorsHelper"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageStudio = class( 'PadModePageStudio', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:__init(Controller)

    PadModePageBase.__init(self, Controller, "PadModePageStudio")

end

------------------------------------------------------------------------------------------------------------------------
-- Setup Screen
------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:setupScreen()

    -- create screen
    self.Screen = ScreenWithGridStudio(self, {"PAD", "KEYBOARD", "16 VELOCITIES", "FIXED VEL"},
        {"OCTAVE-", "OCTAVE+", "SEMITONE-", "SEMITONE+"}, "HeadButton", "HeadButton")

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)

    PadModePageBase.setupScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:onShow(Show)

    if Show then
        self.Screen.ScreenLeft.InfoBar:setMode("PadScreenMode")
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------
-- Update
------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:updateScreens(ForceUpdate)

    local KeyboardModeOn = PadModeHelper.getKeyboardMode()

    -- update on-screen pad colors
    PadModeHelper.updatePadColorsStudio(self.Screen)

    local showLevelMeter = not PadModeHelper.is16VelocityMode() and not KeyboardModeOn
    self.Screen:enableLevelMeters(showLevelMeter)

    if KeyboardModeOn then
        self.Screen.ScreenButton[5]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(-12))
        self.Screen.ScreenButton[6]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(12))
        self.Screen.ScreenButton[7]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(-1))
        self.Screen.ScreenButton[8]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(1))
    else
        self.Screen.ScreenButton[5]:setEnabled(true)
        self.Screen.ScreenButton[6]:setEnabled(true)
        self.Screen.ScreenButton[7]:setEnabled(true)
        self.Screen.ScreenButton[8]:setEnabled(true)
    end

    PadModePageBase.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:updateParameters(ForceUpdate)

    self.ParameterHandler.Parameters = {}

    local Values = {}
    local ListValues = {}
    local ListColors = {}

    if self.ParameterHandler.PageIndex == 2 then

        local Sections = {}
        local Names = {}
        local Song = NI.DATA.StateHelper.getFocusSong(App)

        local ScaleEngine = NI.DATA.getScaleEngine(App)
        local ChordModeActive = ScaleEngine and ScaleEngine:getChordModeParameter():getValue() ~= 0 or false

        if ChordModeActive then
            Sections = {"Chord", "Colors", "", "Fixed Velocity"}
            Names = {"POSITION", "GROUP", "SOUND", "VELOCITY"}

            self.ParameterHandler.Parameters[1] = ScaleEngine:getChordPositionParameter()

            ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusGroup(App), 2,
                                                        Values, ListValues, ListColors)
            ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusSound(App), 3,
                                                        Values, ListValues, ListColors)
            self.ParameterHandler.Parameters[4] = Song and Song:getFixedVelocityParameter() or nil

        else
            Sections = {"Colors", "", "Fixed Velocity", ""}
            Names = {"GROUP", "SOUND", "VELOCITY", ""}

            ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusGroup(App), 1,
                                            Values, ListValues, ListColors)
            ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusSound(App), 2,
                                            Values, ListValues, ListColors)
            self.ParameterHandler.Parameters[3] = Song and Song:getFixedVelocityParameter() or nil

        end

        self.ParameterHandler:setCustomValues(Values)
        self.ParameterHandler:setCustomNames(Names)
        self.ParameterHandler:setCustomSections(Sections)

    end

    self.Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    PadModePageBase.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageStudio:onScreenEncoder(Index, Value)

    local Page = self.ParameterHandler.PageIndex

    if Page == 2 then

        local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
        local Next = Value > 0

        local ScaleEngine = NI.DATA.getScaleEngine(App)
        local ChordModeActive = ScaleEngine and ScaleEngine:getChordModeParameter():getValue() ~= 0 or false

        local GroupColorIndex = ChordModeActive and 2 or 1
        local SoundColorIndex = ChordModeActive and 3 or 2

        if Index == GroupColorIndex and EncoderSmoothed then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusGroup(App), Next,
                NI.DATA.GroupAccess.setGroupColor)

        elseif Index == SoundColorIndex and EncoderSmoothed then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusSound(App), Next,
                NI.DATA.SoundAccess.setSoundColor)

        end

    end

    PadModePageBase.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------
