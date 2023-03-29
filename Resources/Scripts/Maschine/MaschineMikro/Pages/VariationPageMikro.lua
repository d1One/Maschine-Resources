require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPageMikro = class( 'VariationPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function VariationPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "VariationPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function VariationPageMikro:setupScreen()

    self.Screen = ScreenMikro(self)
    ScreenHelper.setWidgetText(self.Screen.Title, {"Variation"})
    self.Screen:styleScreenButtons({"HUMAN", "RANDOM", "APPLY"}, "HeadTabRow", "HeadTab")
    self.Screen.ScreenButton[3]:style("APPLY", "HeadButton")

    self.Screen.InfoBar:setMode("None")

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function VariationPageMikro:updateParameters(ForceUpdate)

    VariationType = App:getWorkspace():getRandomizeTypeParameter():getValue()

    local Parameters = {}
    local VelocityRangeParam = App:getWorkspace():getRandomizeVelocityRangeParameter()
    local NoteRangeParam     = App:getWorkspace():getRandomizeNoteRangeParameter()

    if PadModeHelper.getKeyboardMode() and VariationType == NI.HW.RANDOMIZE then

        Parameters = {
            App:getWorkspace():getRandomizeNoteProbabilityParameter(),
            NoteRangeParam:getMinParameter(),
            NoteRangeParam:getMaxParameter(),
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeNumNotesInStepParameter(),
            App:getWorkspace():getRandomizeNoteLengthParameter(),
            App:getWorkspace():getRandomizeTimingParameter(),
            App:getWorkspace():getRandomizeNotesCountDistributionParameter(),
            App:getWorkspace():getRandomizeNoteDistributionParameter(),
            App:getWorkspace():getRandomizeNoteLengthDistributionParameter()
        }

    elseif VariationType == NI.HW.RANDOMIZE then

        Parameters = {
            App:getWorkspace():getRandomizeNoteProbabilityParameter(),
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeTimingParameter(),
            App:getWorkspace():getRandomizeNoteLengthParameter(),
            App:getWorkspace():getRandomizeNoteLengthDistributionParameter()
        }
    else -- HUMANIZE

        Parameters = {
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeTimingParameter()
        }

    end

    self.ParameterHandler:setParameters(Parameters, true)

    PageMikro.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikro:updateScreens(ForceUpdate)

    Param = App:getWorkspace():getRandomizeTypeParameter()
    self.Screen.ScreenButton[1]:setSelected(Param:getValue() == NI.HW.HUMANIZE)
    self.Screen.ScreenButton[2]:setSelected(Param:getValue() == NI.HW.RANDOMIZE)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.Screen.ScreenButton[3]:setEnabled(not AudioLoop)

    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageMikro:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 1 then
            Param = App:getWorkspace():getRandomizeTypeParameter()
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Param, NI.HW.HUMANIZE)
        elseif Idx == 2 then
            Param = App:getWorkspace():getRandomizeTypeParameter()
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Param, NI.HW.RANDOMIZE)
        elseif Idx == 3 then
            Param = App:getWorkspace():getRandomizeApplyParameter()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
        end

    end

    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

