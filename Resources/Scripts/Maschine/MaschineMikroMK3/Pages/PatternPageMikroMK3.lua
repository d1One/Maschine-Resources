------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/ClipHelper"
require "Scripts/Maschine/Helper/PatternHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PatternPageMikroMK3 = class( 'PatternPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "PatternPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:updateScreen()

    self:updateScreenPatternName()
    self:updateScreenParameterText()

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:updateScreenPatternName()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)

    if Pattern then
        self.Screen:setTopRowText(Pattern:getNameParameter():getValue())
    else
        self.Screen:setTopRowText(NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) and "No Clip" or "No Pattern")
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:updateScreenParameterText()

    local FocusedParameter = NHLController:focusedParameter()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local NoFocus = function()
        if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
            return NI.DATA.StateHelper.getFocusClipEvent(App) == nil
        else
            return NI.DATA.StateHelper.getFocusEventPattern(App) == nil
        end
    end

    if Song == nil or FocusedParameter:maschineParameter() == nil or NoFocus() then
        self.Screen:setParameterName("")
        self.Screen:setParameterValue("")
    elseif FocusedParameter:name() == "Pattern Length" then
        self.Screen:setParameterName("Length")
        self.Screen:setParameterValue(PatternHelper.lengthString())
    elseif FocusedParameter:name() == "Pattern Position" then
        self.Screen:setParameterName("Position")
        self.Screen:setParameterValue(PatternHelper.startString())
    elseif FocusedParameter:name() == "Pattern Start" then
        self.Screen:setParameterName("Start")
        self.Screen:setParameterValue(PatternHelper.startString())
    elseif FocusedParameter:name() == "Pattern Bank" then
        self.Screen:setPatternBankParameter(FocusedParameter:maschineParameter():getValue(),
                                            Song:getNumPatternBanksParameter():getValue())
    elseif FocusedParameter:name() == "Clip Length" then

        self.Screen:setParameterName("Length")
        self.Screen:setParameterValue(ClipHelper.getFocusClipLengthString())

    elseif FocusedParameter:name() == "Clip Position" then

        self.Screen:setParameterName("Position")
        self.Screen:setParameterValue(ClipHelper.getFocusClipStartString())

    elseif FocusedParameter:name() == "Clip Start" then

        self.Screen:setParameterName("Start")
        self.Screen:setParameterValue(ClipHelper.getFocusClipStartString())

    elseif FocusedParameter:name() == "Clip Bank" then

        self.Screen:setParameterName("Bank")
        local Current, Max = ClipHelper.getCurrentBank()
        self.Screen:setPatternBankParameter(Current, Max + 1)        -- for Clips, max is 0-based unlike for Patterns

    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:onPadEvent(PadIndex, Trigger, _)

    local DeletePattern = self.Controller:isErasePressed()
    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        ClipHelper.onClipPagePadEvent(PadIndex, Trigger, DeletePattern)
    else
        PatternHelper.onPatternPagePadEvent(PadIndex, Trigger, DeletePattern)
    end

end

------------------------------------------------------------------------------------------------------------------------

function PatternPageMikroMK3:updatePadLEDs()

    if NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP) then
        ClipHelper.updatePadLEDs(self.Controller.PAD_LEDS)
    else
        PatternHelper.updatePadLEDs(self.Controller.PAD_LEDS)
    end

end

------------------------------------------------------------------------------------------------------------------------
