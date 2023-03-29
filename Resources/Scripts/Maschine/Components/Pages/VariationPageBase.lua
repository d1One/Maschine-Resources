require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
VariationPageBase = class( 'VariationPageBase', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:__init(Page, Controller)

    PageMaschine.__init(self, Page, Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PATTERN }

    self.ParameterHandler.PageIndex = 1

    self.RandomKeyParamSections1 = {"Probability","Note Range","","Velocity Range","","Chords","Note Length","Time Shift"}
    self.RandomKeyParamSections2 = {"Distribution","","","","","","",""}
    self.RandomPadParamSections  = {"Probability","Velocity Range","","Time Shift","Note Length","Distribution","",""}
    self.HumanParamSections      = {"Velocity Range","","Time Shift","","","","",""}

    --get names from parameter by default
    self.RandomKeyParamNames1 = {}
    self.RandomKeyParamNames2 = {}
    self.RandomPadParamNames  = {}
    self.HumanParamNames      = {}

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:updateParameters(ForceUpdate)

    VariationType = App:getWorkspace():getRandomizeTypeParameter():getValue()

    local Parameters = {}
    local VelocityRangeParam = App:getWorkspace():getRandomizeVelocityRangeParameter()
    local NoteRangeParam     = App:getWorkspace():getRandomizeNoteRangeParameter()

    if PadModeHelper.getKeyboardMode() and VariationType == NI.HW.RANDOMIZE
    and self.ParameterHandler.PageIndex == 1 then

        self.ParameterHandler.NumPages       = 2
        self.ParameterHandler.CustomSections = self.RandomKeyParamSections1
        self.ParameterHandler.CustomNames    = self.RandomKeyParamNames1

        Parameters = {
            App:getWorkspace():getRandomizeNoteProbabilityParameter(),
            NoteRangeParam:getMinParameter(),
            NoteRangeParam:getMaxParameter(),
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeNumNotesInStepParameter(),
            App:getWorkspace():getRandomizeNoteLengthParameter(),
            App:getWorkspace():getRandomizeTimingParameter(),
        }


    elseif PadModeHelper.getKeyboardMode() and VariationType == NI.HW.RANDOMIZE then

        self.ParameterHandler.NumPages       = 2
        self.ParameterHandler.CustomSections = self.RandomKeyParamSections2
        self.ParameterHandler.CustomNames    = self.RandomKeyParamNames2

        Parameters = {
            App:getWorkspace():getRandomizeNotesCountDistributionParameter(),
            App:getWorkspace():getRandomizeNoteDistributionParameter(),
            App:getWorkspace():getRandomizeNoteLengthDistributionParameter()
        }

    elseif VariationType == NI.HW.RANDOMIZE then

        self.ParameterHandler.NumPages       = 1
        self.ParameterHandler.CustomSections = self.RandomPadParamSections
        self.ParameterHandler.CustomNames     = self.RandomPadParamNames

        Parameters = {
            App:getWorkspace():getRandomizeNoteProbabilityParameter(),
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeTimingParameter(),
            App:getWorkspace():getRandomizeNoteLengthParameter(),
            App:getWorkspace():getRandomizeNoteLengthDistributionParameter()
        }

    else -- HUMANIZE)

        self.ParameterHandler.NumPages       = 1
        self.ParameterHandler.CustomSections = self.HumanParamSections
        self.ParameterHandler.CustomNames    = self.HumanParamNames

        self.ParameterHandler.SectionWidgets[2]:setText("")
        self.ParameterHandler.SectionWidgets[3]:setText("")
        self.ParameterHandler.SectionWidgets[4]:setText("Velocity Range")
        self.ParameterHandler.SectionWidgets[5]:setText("")
        self.ParameterHandler.SectionWidgets[6]:setText("Time Shift")
        self.ParameterHandler.SectionWidgets[7]:setText("")
        self.ParameterHandler.SectionWidgets[8]:setText("")

        Parameters = {
            VelocityRangeParam:getMinParameter(),
            VelocityRangeParam:getMaxParameter(),
            App:getWorkspace():getRandomizeTimingParameter()
        }

    end

    self.ParameterHandler:setParameters(Parameters, true)
    self:updateLeftRightLEDs()
    PageMaschine.updateParameters(self, ForceUpdate)

    return Parameters

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:updateScreens(ForceUpdate)

    Param = App:getWorkspace():getRandomizeTypeParameter()
    self.Screen.ScreenButton[2]:setSelected(Param:getValue() == NI.HW.HUMANIZE)
    self.Screen.ScreenButton[3]:setSelected(Param:getValue() == NI.HW.RANDOMIZE)

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local AudioLoop = Sound and NI.DATA.SoundAlgorithms.hasAudioModuleInLoopMode(Sound)
    self.Screen.ScreenButton[4]:setEnabled(not AudioLoop)

    PageMaschine.updateScreens(self, ForceUpdate)

end


------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 2 then
            Param = App:getWorkspace():getRandomizeTypeParameter()
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Param, NI.HW.HUMANIZE)
        elseif Idx == 3 then
            Param = App:getWorkspace():getRandomizeTypeParameter()
            NI.DATA.ParameterAccess.setEnumParameterNoUndo(App, Param, NI.HW.RANDOMIZE)
        elseif Idx == 4 then
            Param = App:getWorkspace():getRandomizeApplyParameter()
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, Param, not Param:getValue())
        end

    end

    PageMaschine.onScreenButton(self, Idx, Pressed)
    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:onLeftRightButton(Right, Pressed)

    self.ParameterHandler:onPrevNextParameterPage(Right and 1 or -1)
    self:updateScreens(true)
    self:updateLeftRightLEDs()

end

------------------------------------------------------------------------------------------------------------------------

function VariationPageBase:updateLeftRightLEDs()

    LEDHelper.updateLeftRightLEDsWithParameters(self.Controller,
        self.ParameterHandler.NumPages, self.ParameterHandler.PageIndex)

end

------------------------------------------------------------------------------------------------------------------------

