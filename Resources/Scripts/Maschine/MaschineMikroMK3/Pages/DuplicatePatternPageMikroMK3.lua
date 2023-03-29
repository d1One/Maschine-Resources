------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikroMK3/Pages/PageMikroMK3"
require "Scripts/Maschine/Helper/DuplicateHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
DuplicatePatternPageMikroMK3 = class( 'DuplicatePatternPageMikroMK3', PageMikroMK3 )

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:__init(Controller)

    PageMikroMK3.__init(self, "DuplicatePatternPageMikroMK3", Controller)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:setupScreen()

    PageMikroMK3.setupScreen(self)
    self.Screen:showParameterInBottomRow()

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:onShow(Show)

    self:reset()
    PageMikroMK3.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:reset()

    self.Mode = NI.DATA.StateHelper.isSongEntityFocused(App, NI.DATA.FOCUS_ENTITY_CLIP)
        and DuplicateHelper.CLIP or DuplicateHelper.PATTERN
    self.SourceIndex = -1
    self.SourceGroupIndex = -1

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:updateScreen()

    local Pattern = NI.DATA.StateHelper.getFocusEventPattern(App)
    local NoPattern = self.Mode == DuplicateHelper.CLIP and "No Clip" or "No Pattern"
    self.Screen:setTopRowText(Pattern and "Dupl. "..Pattern:getNameParameter():getValue() or NoPattern)

    local FocusedParameter = NHLController:focusedParameter()
    if Pattern == nil or FocusedParameter == nil or FocusedParameter:maschineParameter() == nil then

        self.Screen:setParameterName(""):setParameterValue("")

    elseif FocusedParameter:name() == "Pattern Bank" then
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        if Song == nil then
            return
        end

        self.Screen:setPatternBankParameter(FocusedParameter:maschineParameter():getValue(),
                                            Song:getNumPatternBanksParameter():getValue())

    elseif FocusedParameter:name() == "Clip Bank" then

        self.Screen:setParameterName("Bank")
        local Current, Max = ClipHelper.getCurrentBank()
        self.Screen:setPatternBankParameter(Current, Max + 1) -- for Clips, max is 0-based unlike for Patterns

    end

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    DuplicateHelper.onPadEvent(self, PadIndex)

end

------------------------------------------------------------------------------------------------------------------------

function DuplicatePatternPageMikroMK3:updatePadLEDs()

    DuplicateHelper.updatePadLEDs(self, self.Controller.PAD_LEDS, self.SourceIndex >= 0)

end

------------------------------------------------------------------------------------------------------------------------
