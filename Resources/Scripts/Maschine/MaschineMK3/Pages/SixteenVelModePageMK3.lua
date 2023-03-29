------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Components/Pages/PadModePageBase"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SixteenVelModePageMK3 = class( 'SixteenVelModePageMK3', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:__init(Controller)

    PageMaschine.__init(self, "SixteenVelModePageMK3", Controller)

    self:setupScreen()
    self:setPinned()

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:setPinned(PinState)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:setupScreen()

    self.Screen = ScreenWithGridStudio(self, { "16 VEL", "PADS ON", "", "" },
        { "OCTAVE-", "OCTAVE+", "SEMITONE-", "SEMITONE+" })

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)
    self.Screen.ScreenButton[1]:setSelected(true)

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:onShow(Show)

    if Show then
        self.Screen.ScreenLeft.InfoBar:setMode("PadScreenMode")
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:updateScreens(ForceUpdate)

    -- update on-screen pad colors
    PadModeHelper.updatePadColorsStudio(self.Screen)
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return PadModeHelper.getScreenPadButtonState(Index, NI.HW.PAD_MODE_16_VELOCITY)
        end)

    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:updateParameters(ForceUpdate)

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

    local Names = {}
    local Parameters = {}
    local Sections = {}
    local Values = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections = { "Choke", "", "Link", "" }

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Parameters[1] = Sound and Sound:getChokeGroupParameter()
        Parameters[2] = Sound and Sound:getChokeModeParameter()
        Parameters[3] = Sound and Sound:getLinkGroupParameter()
        Parameters[4] = Sound and Sound:getLinkModeParameter()

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections[1] = "Fixed Velocity"
        Names[1] = "VELOCITY"

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Parameters[1] = Song and Song:getFixedVelocityParameter()

    end

    self.ParameterHandler:setParameters(Parameters)
    self.ParameterHandler:setCustomValues(Values)
    self.ParameterHandler:setCustomNames(Names)
    self.ParameterHandler:setCustomSections(Sections)

    self.Controller.CapacitiveList:assignParametersToCaps(Parameters)

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:updateScreenButtons(ForceUpdate)

    local IsNotesMode = PadModeHelper.isTouchstripModeNotes()
    local PadsEnabled = App:getWorkspace():getPlayPadsInNotesModeEnabledParameter():getValue()
    self.Screen.ScreenButton[2]:setEnabled(IsNotesMode)
    self.Screen.ScreenButton[2]:setVisible(IsNotesMode)
    self.Screen.ScreenButton[2]:setSelected(IsNotesMode and PadsEnabled)

    PageMaschine.updateScreenButtons(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SixteenVelModePageMK3:onScreenButton(Index, Pressed)

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

function SixteenVelModePageMK3:getAccessiblePageInfo()

    return "Sixteen Velocity Mode Page"

end

------------------------------------------------------------------------------------------------------------------------
