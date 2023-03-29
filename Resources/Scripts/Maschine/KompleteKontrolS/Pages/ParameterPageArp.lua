------------------------------------------------------------------------------------------------------------------------
-- Page that displays Arpeggiator parameters.
------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/KompleteKontrolS/Pages/ParameterPageBase"

local class = require 'Scripts/Shared/Helpers/classy'
ParameterPageArp = class( 'ParameterPageArp', ParameterPageBase )

local SECTION_PRESET = 1
local SECTION_TYPE = 2
local SECTION_RATE = 3
local SECTION_UNIT = 4
local SECTION_GATE_OR_HOLD = 8

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function ParameterPageArp:__init(Controller)

    ParameterPageBase.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageArp:updateScreen()

    local Arpeggiator = NI.DATA.getArpeggiator(App)
    if not Arpeggiator then
        return
    end

    self.NumPages = Arpeggiator:getNumPages(0)
    self:setFocusPage(Arpeggiator:getFocusPageParameter():getValue() + 1)

    self.PageField = "Arp "..tostring(self.FocusPage).."/"..tostring(self.NumPages)

    HELPERS.setCachedParameter(App, 0, self.FocusPage == 1 and NI.DATA.getArpeggiatorPresetParameter(App) or nil)
    HELPERS.setCachedParameter(App, 1, self.FocusPage == 1 and Arpeggiator:getTypeParameter() or nil)
    HELPERS.setCachedParameter(App, 2, self.FocusPage == 1 and NI.DATA.getArpeggiatorRateParameter(App) or nil)
    HELPERS.setCachedParameter(App, 3, self.FocusPage == 1 and NI.DATA.getArpeggiatorRateUnitParameter(App) or nil)
    HELPERS.setCachedParameter(App, 4, self.FocusPage == 1 and Arpeggiator:getSequenceParameter() or nil)
    HELPERS.setCachedParameter(App, 5, self.FocusPage == 1 and Arpeggiator:getOctavesParameter() or nil)
    HELPERS.setCachedParameter(App, 6, self.FocusPage == 1 and Arpeggiator:getDynamicParameter() or nil)
    HELPERS.setCachedParameter(App, 7, self.FocusPage == 1 and Arpeggiator:getGateParameter() or Arpeggiator:getHoldParameter())

    ParameterPageBase.updateScreen(self)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageArp:onEncoderEvent(EncoderID, Value)

    -- perform Value setting from script when autowriting
    local isAutoWriting = NI.DATA.WORKSPACE.isAutoWriteEnabledFromKompleteKontrol(App) and
        MaschineHelper.isPlaying()

    if isAutoWriting then
        local Parameter = HELPERS.getCachedParameter(App, EncoderID)
        if Parameter then
            NI.DATA.ParameterAccess.addParameterEncoderDelta(App, Parameter, Value, false, false)
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
-- Initialize the textual part of the display.
------------------------------------------------------------------------------------------------------------------------

function ParameterPageArp:updateParameterText(Section)

    ParameterPageBase.updateParameterText(self, Section)

    local Screen = NHLController:getScreen()

    if (self.FocusPage == 1 and (Section == SECTION_TYPE or Section == SECTION_RATE or Section == SECTION_UNIT)) or
        (self.FocusPage == 2 and Section == SECTION_GATE_OR_HOLD) then

        Screen:setTextAlignment(Section, SCREEN.DISPLAY_FIRST_ROW, SCREEN.ALIGN_LEFT)

        local Parameter = HELPERS.getCachedParameter(App, Section - 1)
        if not Parameter then return end

        if Parameter:getTag() == NI.DATA.MaschineParameter.TAG_ENUM then
            Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, Parameter:getAsShortString(Parameter:getValue()))
        else
            Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, Parameter:getParameterInterface():getValueString())
        end

        if Section == SECTION_RATE then
            Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW, "RHYTHM")
        end

    end

    if self.FocusPage == 1 and Section == SECTION_PRESET then

        local PresetName = "PRESET " .. NI.DATA.getArpeggiatorPresetParameter(App):getValue()
        Screen:setText(Section, SCREEN.DISPLAY_FIRST_ROW, PresetName)
        Screen:setText(Section, SCREEN.DISPLAY_SECOND_ROW, "MAIN")
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterPageArp:onPageButton(Pressed, Next)

    ParameterPageBase.onPageButton(self, Pressed, Next)

    if Pressed and not self.Controller:isShiftPressed() then

        local Arpeggiator = NI.DATA.getArpeggiator(App)
        local FocusPageParameter = Arpeggiator and Arpeggiator:getFocusPageParameter()

        if FocusPageParameter then
            local NewFocus = math.bound(FocusPageParameter:getValue() + (Next and 1 or -1), 0, Arpeggiator:getNumPages(0) - 1)
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, FocusPageParameter, NewFocus)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

